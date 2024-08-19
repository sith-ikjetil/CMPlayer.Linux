//
//  AudioPlayer.swift
//  ConsoleMusicPlayer-macOS
//
//  Created by Kjetil Kr Solberg on 21/09/2019.
//  Copyright © 2019 Kjetil Kr Solberg. All rights reserved.
//

//
// import.
//
import Foundation
import Cffmpeg
import Cao

internal struct AacAudioState {
    var formatCtx: UnsafeMutablePointer<AVFormatContext>?
    var codecCtx: UnsafeMutablePointer<AVCodecContext>?
    var codec: UnsafeMutablePointer<AVCodec>?
    var packet = AVPacket()
    var frame: UnsafeMutablePointer<AVFrame>?
    var swrCtx: OpaquePointer? //UnsafeMutablePointer<SwrContext>?
    var audioStreamIndex: Int32 = -1
    var device: OpaquePointer?//UnsafeMutablePointer<ao_device>?
    var aoFormat = ao_sample_format()
}

//
// Represents CMPlayer AudioPlayer.
//
internal class AacAudioPlayer {
    private let filePath: URL    
    private var m_length: off_t = 0
    private var m_rate: CLong = 0
    private let audioQueue = DispatchQueue(label: "audioQueue", qos: .background)
    private var m_stopFlag: Bool = false
    private var m_isPlaying = false
    private var m_isPaused = false
    private var m_timeElapsed: UInt64 = 0
    private var m_duration: UInt64 = 0
    private var m_channels: Int32 = 2
    private var m_audioState: AacAudioState = AacAudioState()
    var isPlaying: Bool {
        get {
            return self.m_isPlaying
        }
    }
    var isPaused: Bool {
        get {
            return self.m_isPaused
        }
    }    
    var timeElapsed: UInt64 {
        get {
            return self.m_timeElapsed
        }
    }
    var duration: UInt64 {
        get {
            return self.m_duration
        }
    }

    //
    // Only initializer
    //
    init(path: URL) {
        self.filePath = path        
    }

    func play() throws {
        // if we are already playing, return
        if (self.m_isPlaying) {
            return;
        }
        
        // if we have paused playback, then resume on play again
        if (self.m_isPaused) {
            self.resume()
            return;
        }

        self.m_stopFlag = false

        // Open audio file
        if avformat_open_input(&self.m_audioState.formatCtx, self.filePath.path, nil, nil) != 0 {
            print("Could not open file \(self.filePath.path)")
            return
        }
        
        // Retrieve stream information
        if avformat_find_stream_info(self.m_audioState.formatCtx, nil) < 0 {
            print("Could not find stream information")
            avformat_close_input(&m_audioState.formatCtx)
            return
        }
        
        // Find the audio stream
        for i in 0..<Int32(self.m_audioState.formatCtx!.pointee.nb_streams) {
            if self.m_audioState.formatCtx!.pointee.streams![Int(i)]!.pointee.codecpar.pointee.codec_type == AVMEDIA_TYPE_AUDIO {
                self.m_audioState.audioStreamIndex = i
                break
            }
        }
        
        if self.m_audioState.audioStreamIndex == -1 {
            print("Could not find an audio stream")
            avformat_close_input(&self.m_audioState.formatCtx)
            return
        }
        
        // Get codec parameters
        let codecpar = self.m_audioState.formatCtx!.pointee.streams![Int(self.m_audioState.audioStreamIndex)]!.pointee.codecpar
        
        // Find the decoder for the audio stream
        self.m_audioState.codec = avcodec_find_decoder(codecpar!.pointee.codec_id)
        if self.m_audioState.codec == nil {
            print("Unsupported codec!")
            avformat_close_input(&self.m_audioState.formatCtx)
            return
        }
        
        // Allocate codec context
        self.m_audioState.codecCtx = avcodec_alloc_context3(self.m_audioState.codec)
        if self.m_audioState.codecCtx == nil {
            print("Could not allocate codec context")
            avformat_close_input(&self.m_audioState.formatCtx)
            return
        }
        
        if avcodec_parameters_to_context(self.m_audioState.codecCtx, codecpar) < 0 {
            print("Could not copy codec context")
            avcodec_free_context(&self.m_audioState.codecCtx)
            avformat_close_input(&self.m_audioState.formatCtx)
            return
        }
        
        // Open codec
        if avcodec_open2(self.m_audioState.codecCtx, self.m_audioState.codec, nil) < 0 {
            print("Could not open codec")
            avcodec_free_context(&self.m_audioState.codecCtx)
            avformat_close_input(&self.m_audioState.formatCtx)
            return
        }
        
        // Allocate frame
        self.m_audioState.frame = av_frame_alloc()
        if self.m_audioState.frame == nil {
            print("Could not allocate audio frame")
            avcodec_free_context(&self.m_audioState.codecCtx)
            avformat_close_input(&self.m_audioState.formatCtx)
            return
        }
        
        // Set up resampling context
        self.m_audioState.swrCtx = swr_alloc()
        let rawSwrCtxPtr: UnsafeMutableRawPointer? = UnsafeMutableRawPointer(self.m_audioState.swrCtx)
        av_opt_set_int(rawSwrCtxPtr, "in_channel_layout", Int64(self.m_audioState.codecCtx!.pointee.channel_layout), 0)
        av_opt_set_int(rawSwrCtxPtr, "out_channel_layout", Int64(AV_CH_LAYOUT_STEREO), 0)
        av_opt_set_int(rawSwrCtxPtr, "in_sample_rate", Int64(self.m_audioState.codecCtx!.pointee.sample_rate), 0)
        av_opt_set_int(rawSwrCtxPtr, "out_sample_rate", 44100, 0)
        av_opt_set_sample_fmt(rawSwrCtxPtr, "in_sample_fmt", self.m_audioState.codecCtx!.pointee.sample_fmt, 0)
        av_opt_set_sample_fmt(rawSwrCtxPtr, "out_sample_fmt", AV_SAMPLE_FMT_S16, 0)
        swr_init(self.m_audioState.swrCtx)
        
        // Set up libao format
        self.m_audioState.aoFormat.bits = 16
        self.m_audioState.aoFormat.channels = 2
        self.m_audioState.aoFormat.rate = 44100
        self.m_audioState.aoFormat.byte_format = AO_FMT_NATIVE
        self.m_audioState.aoFormat.matrix = nil
        
        // Open libao device
        self.m_audioState.device = ao_open_live(ao_default_driver_id(), &self.m_audioState.aoFormat, nil)
        if self.m_audioState.device == nil {
            print("Error opening audio device")
            avcodec_free_context(&self.m_audioState.codecCtx)
            avformat_close_input(&self.m_audioState.formatCtx)
            return
        }

        self.audioQueue.async { [weak self] in
            self?.playAsync()
        }
    }

    private func playAsync() {
        // Set flags
        self.m_isPlaying = true

        // Log that we have started to play
        PlayerLog.ApplicationLog?.logInformation(title: "[AacAudioPlayer].playAsync()", text: "Started playing \(self.filePath.lastPathComponent)")        

        // Clean up using defer
        defer {
            ao_close(self.m_audioState.device)
            swr_free(&self.m_audioState.swrCtx)
            av_frame_free(&self.m_audioState.frame)
            avcodec_free_context(&self.m_audioState.codecCtx)
            avformat_close_input(&self.m_audioState.formatCtx)
        }

        // total amount of sampels
        var total: UInt64 = 0

        // Main decoding and playback loop
        while !self.m_stopFlag {
            if av_read_frame(self.m_audioState.formatCtx, &self.m_audioState.packet) >= 0 {            
                if self.m_audioState.packet.stream_index == self.m_audioState.audioStreamIndex {
                    if avcodec_send_packet(self.m_audioState.codecCtx, &self.m_audioState.packet) < 0 {
                        print("Error sending packet to decoder")
                        break
                    }
                    
                    while avcodec_receive_frame(self.m_audioState.codecCtx, self.m_audioState.frame) >= 0 {
                        // Allocate buffer for resampled audio
                        var outputBuffer: UnsafeMutablePointer<UInt8>? = nil
                        let bufferSize = av_samples_alloc(&outputBuffer, nil, 2, self.m_audioState.frame!.pointee.nb_samples, AV_SAMPLE_FMT_S16, 0)
                        
                        // Ensure the buffer is allocated properly
                        guard bufferSize >= 0 else {
                            print("Error allocating buffer for resampled audio")
                            break
                        }

                        // Cast frame data pointers
                        // Manually create an array from the tuple
                        let inputData: [UnsafePointer<UInt8>?] = [
                            UnsafePointer(self.m_audioState.frame!.pointee.data.0),
                            UnsafePointer(self.m_audioState.frame!.pointee.data.1),
                            UnsafePointer(self.m_audioState.frame!.pointee.data.2),
                            UnsafePointer(self.m_audioState.frame!.pointee.data.3),
                            UnsafePointer(self.m_audioState.frame!.pointee.data.4),
                            UnsafePointer(self.m_audioState.frame!.pointee.data.5),
                            UnsafePointer(self.m_audioState.frame!.pointee.data.6),
                            UnsafePointer(self.m_audioState.frame!.pointee.data.7)
                        ]
                        
                        // Use withUnsafeBufferPointer to pass the array as a pointer
                        inputData.withUnsafeBufferPointer { bufferPointer in
                            let samples = swr_convert(self.m_audioState.swrCtx, &outputBuffer, self.m_audioState.frame!.pointee.nb_samples, UnsafeMutablePointer(mutating: bufferPointer.baseAddress), self.m_audioState.frame!.pointee.nb_samples)                            
                            
                            // Ensure resampling was successful
                            guard samples >= 0 else {
                                print("Error resampling audio")
                                return
                            }

                            // Update time elapsed
                            total += UInt64(bufferSize)
                            let totalPerChannel = total / UInt64(self.m_audioState.aoFormat.channels)
                            let currentDuration = Double(totalPerChannel) / Double(self.m_audioState.aoFormat.rate)
                            self.m_timeElapsed = UInt64(currentDuration * Double(1000/self.m_audioState.aoFormat.channels))
                            
                            // Write audio data to device
                            ao_play(self.m_audioState.device, UnsafeMutableRawPointer(outputBuffer!).assumingMemoryBound(to: CChar.self), UInt32(UInt32(samples) * UInt32(2) * UInt32(MemoryLayout<Int16>.size)))                            
                        }
                                                    
                        // Free the output buffer
                        av_freep(&outputBuffer)

                        guard self.m_stopFlag == false else {
                            return
                        }

                        while self.m_isPaused {
                            usleep(100_000)
                        }
                    }
                }                
                av_packet_unref(&self.m_audioState.packet)                
            }// if av_read_frame
            
            while self.m_isPaused {
                usleep(100_000)
            }
        }
    }// private func playAsync(info: AudioState) {

    func stop() {
        self.m_stopFlag = true
    }

    func pause() {
        self.m_isPaused = true
    }

    func resume() {
        self.m_isPaused = false
    }

    static func gatherMetadata(path: URL) throws -> CmpMetadata {
        let metadata = CmpMetadata()      

        if path.path.lowercased().hasSuffix(".m4a") {
            let filename = path.path
            var formatContext: UnsafeMutablePointer<AVFormatContext>? = nil            
            
            // Open the file
            if avformat_open_input(&formatContext, filename, nil, nil) != 0 {
                print("Could not open file")
                exit(1)
            }

            // Retrieve stream information
            if avformat_find_stream_info(formatContext, nil) < 0 {
                print("Could not find stream information")
                avformat_close_input(&formatContext)
                exit(1)
            }

            // Calculate duration in seconds
            if let formatCtx = formatContext, formatCtx.pointee.duration != 0x00 { // AV_NOPTS_VALUE {
                let durationInSeconds = Double(formatCtx.pointee.duration) / Double(AV_TIME_BASE)                
                metadata.duration = UInt64(durationInSeconds * 1000)
            }            

            // Print metadata
            var tag: UnsafeMutablePointer<AVDictionaryEntry>? = nil
            while let nextTag = av_dict_get(formatContext?.pointee.metadata, "", tag, AV_DICT_IGNORE_SUFFIX) {
                if let key = nextTag.pointee.key, let value = nextTag.pointee.value {
                    let checkKey = String(cString: key)
                    switch checkKey {
                        case "artist":
                            metadata.artist = String(cString: value)
                        case "title":
                            metadata.title = String(cString: value)
                        case "album":
                            metadata.albumName = String(cString: value)
                        case "genre":
                            metadata.genre = String(cString: value)
                        case "track":
                            metadata.trackNo = Int(String(cString: value)) ?? 0     
                        default:
                            tag = nextTag
                            continue;
                    }                    
                }
                tag = nextTag
            }            
            
            // Clean up
            avformat_close_input(&formatContext)
            
            return metadata         
        }

        throw AudioPlayerError.UnknownFileType
    }
}// AudioPlayer