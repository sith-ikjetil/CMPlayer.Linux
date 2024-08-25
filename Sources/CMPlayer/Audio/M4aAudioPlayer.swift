//
//  AudioPlayer.swift
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//

//
// import.
//
import Foundation
import Cffmpeg
import Cao
import Casound

let g_fver: Int32 = getFFmpegMajorVersion()

///
/// Audio state variables.
///
internal struct M4aAudioState {
    var formatCtx: UnsafeMutablePointer<AVFormatContext>?
    var codecCtx: UnsafeMutablePointer<AVCodecContext>?   
#if CMP_FFMPEG_V6 || CMP_FFMPEG_V7
    var codec: UnsafePointer<AVCodec>?          // ffmpeg version 6    
    var chLayoutIn: AVChannelLayout = AVChannelLayout()
    var chLayoutOut: AVChannelLayout = AVChannelLayout()
#elseif CMP_FFMPEG_V4
    var codec: UnsafeMutablePointer<AVCodec>?   // ffmpeg version 4
#endif
    var packet = AVPacket()
    var frame: UnsafeMutablePointer<AVFrame>?
    var swrCtx: OpaquePointer? //UnsafeMutablePointer<SwrContext>?
    var audioStreamIndex: Int32 = -1
    var device: OpaquePointer?//UnsafeMutablePointer<ao_device>?
    var aoFormat = ao_sample_format()
    var alsaState: AlsaState = AlsaState()
}



//
// av_ch_layout_stereo
//
let av_ch_layout_stereo: Int32 = 1|2

//
// Represents CMPlayer AudioPlayer.
//
internal class M4aAudioPlayer {
    ///
    /// constants
    ///
    private let filePath: URL    
    private let audioQueue = DispatchQueue(label: "dqueue.cmp.linux.aac-audio-player", qos: .background)
    ///
    /// variables
    ///
    private var m_length: off_t = 0
    private var m_rate: CLong = 0    
    private var m_stopFlag: Bool = false
    private var m_isPlaying: Bool = false
    private var m_isPaused: Bool = false
    private var m_hasPlayed: Bool = false
    private var m_timeElapsed: UInt64 = 0
    private var m_duration: UInt64 = 0
    private var m_channels: Int32 = 2
    private var m_audioState: M4aAudioState = M4aAudioState()
    private var m_targetFadeVolume: Float = 1
    private var m_targetFadeDuration: UInt64 = 0
    private var m_enableCrossfade: Bool = false
    private var m_seekPos: UInt64 = 0
    private var m_doSeekToPos: Bool = false
    ///
    /// get properties
    ///
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
    var hasPlayed: Bool {
        get {
            return self.m_hasPlayed
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
    ///
    /// Only initializer
    ///
    init(path: URL) {
        self.filePath = path        
    }
    ///
    /// initiates playback of the audio file from init(path)
    /// 
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

        self.m_hasPlayed = false
        self.m_stopFlag = false

        // Open audio file
        var err = avformat_open_input(&self.m_audioState.formatCtx, self.filePath.path, nil, nil)
        if err != 0 {
            let msg = "[M4aAudioPlayer].play(). avformat_open_input failed with value \(err) = '\(errorToString(error: err))'. Could not open file \(self.filePath.path)."
            throw CmpError(message: msg)
        }
        
        if self.m_audioState.formatCtx == nil {
            // Handle the nil case appropriately
            let msg = "[M4aAudioPlayer].play(). m_audioState.formatCtx is nil."
            throw CmpError(message: msg)
        }
        
        // Retrieve stream information
        err = avformat_find_stream_info(self.m_audioState.formatCtx, nil)
        if err < 0 {            
            let msg = "[M4aAudioPlayer].play(). avformat_find_stream_info failed with value: \(err) = '\(errorToString(error: err))'. Could not find stream information."
            avformat_close_input(&m_audioState.formatCtx)
            throw CmpError(message: msg)
        }                
        
        // Find the audio stream
        for i in 0..<Int32(self.m_audioState.formatCtx!.pointee.nb_streams) {
            if self.m_audioState.formatCtx!.pointee.streams![Int(i)]!.pointee.codecpar.pointee.codec_type == AVMEDIA_TYPE_AUDIO {
                self.m_audioState.audioStreamIndex = i
                break
            }
        }
        
        if self.m_audioState.audioStreamIndex < 0 {
            let msg = "[M4aAudioPlayer].play(). m_audioState.audioStreamIndex invalid with value: \(self.m_audioState.audioStreamIndex)."
            avformat_close_input(&m_audioState.formatCtx)
            throw CmpError(message: msg)
        }

        // Calculate duration in seconds
        if let formatCtx = self.m_audioState.formatCtx, formatCtx.pointee.duration != 0x00 { // AV_NOPTS_VALUE {
            let durationInSeconds = Double(formatCtx.pointee.duration) / Double(AV_TIME_BASE)                
            if durationInSeconds <= 0 {                    
                let msg = "[M4aAudioPlayer].play(). duration <= 0. \(durationInSeconds) seconds"
                throw CmpError(message: msg)
            }
            self.m_duration = UInt64(durationInSeconds * 1000)
        }
        else {
            let msg = "[M4aAudioPlayer].play(). Cannot find duration."
            avformat_close_input(&self.m_audioState.formatCtx)
            throw CmpError(message: msg)
        }              
        
        // Get codec parameters
        let codecpar = self.m_audioState.formatCtx!.pointee.streams![Int(self.m_audioState.audioStreamIndex)]!.pointee.codecpar
        
        // Find the decoder for the audio stream 
#if CMP_FFMPEG_V6 || CMP_FFMPEG_V7
        self.m_audioState.codec = avcodec_find_decoder(codecpar!.pointee.codec_id)
#elseif CMP_FFMPEG_V4
        self.m_audioState.codec = UnsafeMutablePointer(mutating: avcodec_find_decoder(codecpar!.pointee.codec_id))
#endif
        if self.m_audioState.codec == nil {
            let msg = "[M4aAudioPlayer].play(). avcodec_find_decoder failed with value: nil. Unsupported codec: \(codecpar!.pointee.codec_id)."
            avformat_close_input(&self.m_audioState.formatCtx)            
            throw CmpError(message: msg)
        }    
        
        // Allocate codec context
        self.m_audioState.codecCtx = avcodec_alloc_context3(self.m_audioState.codec)
        if self.m_audioState.codecCtx == nil {
            let msg = "[M4aAudioPlayer].play(). avcodec_alloc_context3 failed with value: nil. Could not allocate codec context."
            avformat_close_input(&self.m_audioState.formatCtx)            
            throw CmpError(message: msg)
        }
        
        err = avcodec_parameters_to_context(self.m_audioState.codecCtx, codecpar)
        if err < 0 {
            let msg = "[M4aAudioPlayer].play(). avcodec_parameters_to_context failed with value: \(err) = '\(errorToString(error: err))'. Could not copy codec context."
            avcodec_free_context(&self.m_audioState.codecCtx)
            avformat_close_input(&self.m_audioState.formatCtx)            
            throw CmpError(message: msg)
        }
        
        // Open codec
        err = avcodec_open2(self.m_audioState.codecCtx, self.m_audioState.codec, nil)
        if err < 0 {
            let msg = "[M4aAudioPlayer].play(). avcodec_open2 failed with value: \(err) = '\(errorToString(error: err))'. Could not open codec."
            avcodec_free_context(&self.m_audioState.codecCtx)
            avformat_close_input(&self.m_audioState.formatCtx)
            throw CmpError(message: msg)
        }
        
        // Allocate frame
        self.m_audioState.frame = av_frame_alloc()
        if self.m_audioState.frame == nil {
            let msg = "[M4aAudioPlayer].play(). av_frame_alloc failed with value: nil. Could not allocate audio frame."
            avcodec_free_context(&self.m_audioState.codecCtx)
            avformat_close_input(&self.m_audioState.formatCtx)            
            throw CmpError(message: msg)
        }
        
        // Set up resampling context
        self.m_audioState.swrCtx = swr_alloc()
        let rawSwrCtxPtr: UnsafeMutableRawPointer? = UnsafeMutableRawPointer(self.m_audioState.swrCtx)
#if CMP_FFMPEG_V6 || CMP_FFMPEG_V7        
        var ret = av_channel_layout_copy(&self.m_audioState.chLayoutIn, &self.m_audioState.codecCtx!.pointee.ch_layout)        
        if ret < 0 {
            let msg = "[M4aAudioPlayer].play(). av_channel_layout_copy failed with value: \(ret) = '\(errorToString(error: err))'."
            avcodec_free_context(&self.m_audioState.codecCtx)
            avformat_close_input(&self.m_audioState.formatCtx)  
            throw CmpError(message: msg)
        }
        ret = av_opt_set_chlayout(rawSwrCtxPtr, "in_chlayout", &self.m_audioState.chLayoutIn, 0)        
        if ret < 0 {
            let msg = "[M4aAudioPlayer].play(). av_opt_set_chlayout IN failed with value: \(ret) = '\(errorToString(error: err))'."
            avcodec_free_context(&self.m_audioState.codecCtx)
            avformat_close_input(&self.m_audioState.formatCtx)  
            throw CmpError(message: msg)
        }
        av_channel_layout_default(&self.m_audioState.chLayoutOut, 2);
        ret = av_opt_set_chlayout(rawSwrCtxPtr, "out_chlayout", &self.m_audioState.chLayoutOut, 0)
        if ret < 0 {
            let msg = "[M4aAudioPlayer].play(). av_opt_set_chlayout OUT failed with value: \(ret) = '\(errorToString(error: err))'."
            avcodec_free_context(&self.m_audioState.codecCtx)
            avformat_close_input(&self.m_audioState.formatCtx)  
            throw CmpError(message: msg)
        }        
#elseif CMP_FFMPEG_V4
        av_opt_set_int(rawSwrCtxPtr, "in_channel_layout", Int64(self.m_audioState.codecCtx!.pointee.channel_layout), 0)
        av_opt_set_int(rawSwrCtxPtr, "out_channel_layout", Int64(av_ch_layout_stereo), 0)
#endif        
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
        // Set up libasound format        
        self.m_audioState.alsaState.channels = 2
        self.m_audioState.alsaState.sampleRate = 44100 
        self.m_audioState.alsaState.bufferSize = 1024 
        
        // Open libao device
        if PlayerPreferences.outputSoundLibrary == .ao {
            self.m_audioState.device = ao_open_live(ao_default_driver_id(), &self.m_audioState.aoFormat, nil)
            if self.m_audioState.device == nil {
                let msg = "[M4aAudioPlayer].play(). ao_open_live failed with value: nil. Error opening audio device."
    #if CMP_FFMPEG_V6 || CMP_FFMPEG_V7
                av_channel_layout_uninit(&self.m_audioState.chLayoutIn)
                av_channel_layout_uninit(&self.m_audioState.chLayoutOut)
    #endif
                avcodec_free_context(&self.m_audioState.codecCtx)
                avformat_close_input(&self.m_audioState.formatCtx)
                throw CmpError(message: msg)
            }
        }
        else if PlayerPreferences.outputSoundLibrary == .alsa {
            let err = snd_pcm_open(&self.m_audioState.alsaState.pcmHandle, self.m_audioState.alsaState.pcmDeviceName, SND_PCM_STREAM_PLAYBACK, 0)
            guard err >= 0 else {
                let msg = "[M4aAudioPlayer].play(). alsa. snd_pcm_open failed with value: \(err)"
    #if CMP_FFMPEG_V6 || CMP_FFMPEG_V7
                av_channel_layout_uninit(&self.m_audioState.chLayoutIn)
                av_channel_layout_uninit(&self.m_audioState.chLayoutOut)
    #endif
                avcodec_free_context(&self.m_audioState.codecCtx)
                avformat_close_input(&self.m_audioState.formatCtx)
                throw CmpError(message: msg)
            }
        }

        self.audioQueue.async { [weak self] in            
            self?.playAsync()
        }
    }
    ///
    /// Performs the actual playback from play().
    /// Runs in the background.
    /// 
    private func playAsync() {
        // Set flags
        self.m_isPlaying = true

        // Log that we have started to play
        PlayerLog.ApplicationLog?.logInformation(title: "[M4aAudioPlayer].playAsync()", text: "Started playing: \(self.filePath.lastPathComponent)")

        // Clean up using defer
        defer {            
#if CMP_FFMPEG_V6 || CMP_FFMPEG_V7
            av_channel_layout_uninit(&self.m_audioState.chLayoutIn)
            av_channel_layout_uninit(&self.m_audioState.chLayoutOut)
#endif
            if PlayerPreferences.outputSoundLibrary == .ao {
                ao_close(self.m_audioState.device)
            }
            else if PlayerPreferences.outputSoundLibrary == .alsa {
                snd_pcm_drain(self.m_audioState.alsaState.pcmHandle)
                snd_pcm_close(self.m_audioState.alsaState.pcmHandle)
            }
            swr_free(&self.m_audioState.swrCtx)
            av_frame_free(&self.m_audioState.frame)
            avcodec_free_context(&self.m_audioState.codecCtx)
            avformat_close_input(&self.m_audioState.formatCtx)
            self.m_timeElapsed = self.duration
            self.m_hasPlayed = true
            self.m_isPlaying = false
            self.m_isPaused = false
            self.m_stopFlag = true        
        }

        var timeToStartCrossfade: Bool = false
        var currentVolume: Float = 1

        self.m_timeElapsed = 0

        // Main decoding and playback loop
        while !self.m_stopFlag && !g_quit {    
           if (self.m_doSeekToPos) {
                self.m_doSeekToPos = false

                // Access the stream and its time_base
                let audioStream = self.m_audioState.formatCtx!.pointee.streams[Int(self.m_audioState.audioStreamIndex)]!
                let timeBase = audioStream.pointee.time_base

                // Convert the time_base to a human-readable format
                let timeBaseNum = timeBase.num
                let timeBaseDen = timeBase.den

                let seconds: UInt64 = (self.duration - self.m_seekPos) / 1000                                
                let newPos: Int64 = Int64(seconds) * Int64(timeBaseDen/timeBaseNum)
                if av_seek_frame(self.m_audioState.formatCtx, self.m_audioState.audioStreamIndex, newPos, AVSEEK_FLAG_ANY) == 0 {                
                    self.m_timeElapsed = (seconds * 1000)
                }            
            }

            var retVal: Int32 = av_read_frame(self.m_audioState.formatCtx, &self.m_audioState.packet)
            if retVal < 0 { // ERROR OR EOF < 0
                return
            }

            guard let _ = self.m_audioState.codecCtx, let _ = self.m_audioState.frame else {
                let msg = "Codec context or frame is nil."
                PlayerLog.ApplicationLog?.logError(title: "[M4aPlayer].playAsync()", text: msg)
                return
            }
            
            if self.m_audioState.packet.stream_index == self.m_audioState.audioStreamIndex {
                retVal = avcodec_send_packet(self.m_audioState.codecCtx, &self.m_audioState.packet)
                if retVal < 0 {
                    let msg = "[M4aAudioPlayer].playAsync(). avcodec_send_packet failed with value: \(retVal) = '\(errorToString(error: retVal))'."
                    PlayerLog.ApplicationLog?.logError(title: "[M4aAudioPlayer].playAsync()", text: msg)
                    return
                }
                                    
                while !g_quit && !m_stopFlag && avcodec_receive_frame(self.m_audioState.codecCtx, self.m_audioState.frame) >= 0 {                        
                    // Allocate buffer for resampled audio
                    var outputBuffer: UnsafeMutablePointer<UInt8>? = nil
                    let bufferSize = av_samples_alloc(&outputBuffer, nil, 2, self.m_audioState.frame!.pointee.nb_samples, AV_SAMPLE_FMT_S16, 0)
                    
                    // Ensure the buffer is allocated properly
                    guard bufferSize >= 0 else {
                        let msg = "Error allocating buffer for resampled audio."
                        PlayerLog.ApplicationLog?.logError(title: "[M4aAudioPlayer].playAsync()", text: msg)
                        return
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
                            let msg = "swr_convert filed with value: \(samples) = '\(errorToString(error: samples))'."
                            PlayerLog.ApplicationLog?.logError(title: "[M4aAudioPlayer].playAsync()", text: msg)
                            return
                        }

                        // Update time elapsed                            
                        let totalPerChannel = UInt64(bufferSize) / UInt64(self.m_audioState.aoFormat.channels)
                        let currentDuration = Double(totalPerChannel) / Double(self.m_audioState.aoFormat.rate)
                        self.m_timeElapsed += UInt64(currentDuration * Double(1000/self.m_audioState.aoFormat.channels))
                        
                        // set crossfade volume
                        let timeLeft: UInt64 = (self.duration >= self.m_timeElapsed) ? self.duration - self.m_timeElapsed : self.duration
                        if timeLeft > 0 && timeLeft <= self.m_targetFadeDuration {
                            timeToStartCrossfade = true

                            currentVolume = Float(Float(timeLeft)/Float(self.m_targetFadeDuration))                    
                        }

                        // adjust crossfade volume
                        if self.m_enableCrossfade && timeToStartCrossfade {
                            adjustVolume(buffer: UnsafeMutableRawPointer(outputBuffer!).assumingMemoryBound(to: CChar.self), size: Int(bufferSize), volume: currentVolume)                        
                        }

                        // Write audio data to device
                        if PlayerPreferences.outputSoundLibrary == .ao {
                            ao_play(self.m_audioState.device, UnsafeMutableRawPointer(outputBuffer!).assumingMemoryBound(to: CChar.self), UInt32(UInt32(samples) * UInt32(2) * UInt32(MemoryLayout<Int16>.size)))                            
                        }
                        else {
                            let frames = Int(bufferSize) / 2 / Int(self.m_audioState.alsaState.channels)
                            snd_pcm_writei(self.m_audioState.alsaState.pcmHandle, UnsafeMutableRawPointer(outputBuffer!).assumingMemoryBound(to: CChar.self), snd_pcm_uframes_t(frames))
                        }
                    }
                                                
                    // Free the output buffer
                    av_freep(&outputBuffer)                    

                    while (self.m_isPaused && !self.m_stopFlag && !g_quit) {
                        usleep(100_000)
                    }                                      
                }// while    
                av_packet_unref(&self.m_audioState.packet)                
            }// if av_read_frame
            
            while (self.m_isPaused && !self.m_stopFlag && !g_quit) {
                usleep(100_000)
            }
        }// while !self.m_stopFlag
    }// private func playAsync()
    /// 
    /// seeks playback from start to position (ms)
    /// 
    /// - Parameter position: ms from start
    func seekToPos(position: UInt64)
    {
        guard position <= self.duration else {
            return
        }

        self.m_seekPos = position
        self.m_doSeekToPos = true
    }
    /// 
    /// Adjusts volume in the sample buffer to a factor 0.0-1.0
    ///     
    func adjustVolume(buffer: UnsafeMutablePointer<Int8>, size: Int, volume: Float) {
        let sampleCount = size / MemoryLayout<Int16>.size
        let samples = buffer.withMemoryRebound(to: Int16.self, capacity: sampleCount) { $0 }

        for i in 0..<sampleCount {
            let adjustedSample = Float(samples[i]) * volume
            // Ensure the value is within the Int16 range
            samples[i] = Int16(max(min(adjustedSample, Float(Int16.max)), Float(Int16.min)))
        }
    }
    /// 
    /// Sets how the volume is done with crossfading enabled.
    /// - Parameters:
    ///   - volume: target volume. usually 0.
    ///   - duration: time from end of song, fading should be done.
    func setCrossfadeVolume(volume: Float, fadeDuration: UInt64) {
        guard volume >= 0 && volume <= 1 else {
            return
        }
        
        guard isCrossfadeTimeValid(seconds: Int(fadeDuration / 1000)) else {
            return
        }

        self.m_targetFadeVolume = volume
        self.m_targetFadeDuration = fadeDuration
        self.m_enableCrossfade = true
    }
    ///
    /// stops playback if we are playing.
    /// 
    func stop() {
        self.m_stopFlag = true
    }
    ///
    /// pauses playback if we are playing
    /// 
    func pause() {
        self.m_isPaused = true
    }
    ///
    /// resumes playback if we are playing.
    ///
    func resume() {
        self.m_isPaused = false
    }
    ///
    /// Gathers metadata.
    /// - Parameter path: file to gather metadata from.
    /// - Throws: CmpError
    /// - Returns: CmpMetadata
    /// 
    static func gatherMetadata(path: URL) throws -> CmpMetadata {
        let metadata = CmpMetadata()      
        let errorToString: (Int32) -> String = { error in
            var errBuf = [CChar](repeating: 0, count: 128)
            av_strerror(error, &errBuf, errBuf.count)
            return String(cString: errBuf)
        }

        if path.path.lowercased().hasSuffix(".m4a") {
            let filename = path.path
            var formatContext: UnsafeMutablePointer<AVFormatContext>? = nil            
            
            // Open the file
            var err = avformat_open_input(&formatContext, filename, nil, nil)
            if err != 0 {
                let msg = "[M4aAudioPlayer].gatherMetadata(). avformat_open_input failed with value: \(err) = '\(errorToString(err))'."
                throw CmpError(message: msg)
            }

            // Retrieve stream information
            err = avformat_find_stream_info(formatContext, nil)
            if err < 0 {
                avformat_close_input(&formatContext)
                let msg = "[M4aAudioPlayer].gatherMetadata(). avformat_find_stream_info failed with value: \(err) = '\(errorToString(err))'."
                throw CmpError(message: msg)
            }

            // Calculate duration in seconds
            if let formatCtx = formatContext, formatCtx.pointee.duration != 0x00 { // AV_NOPTS_VALUE {
                let durationInSeconds = Double(formatCtx.pointee.duration) / Double(AV_TIME_BASE)                
                if durationInSeconds <= 0 {                    
                    let msg = "[M4aAudioPlayer].gatherMetadata(). duration <= 0. \(durationInSeconds) seconds"
                    throw CmpError(message: msg)
                }
                metadata.duration = UInt64(durationInSeconds * 1000)
            }
            else {
                let msg = "[M4aAudioPlayer].gatherMetadata(). Cannot find duration."
                throw CmpError(message: msg)
            }      

            if formatContext == nil || formatContext?.pointee.metadata == nil {
                // Handle the nil case appropriately
                let msg = "[M4aAudioPlayer].gatherMetadata(). formatContext/metadata is nil."
                throw CmpError(message: msg)
            }

            // Print metadata
            var tag: UnsafeMutablePointer<AVDictionaryEntry>? = nil
            while let nextTag = av_dict_get(formatContext?.pointee.metadata, "", tag, AV_DICT_IGNORE_SUFFIX) {
                if let key = nextTag.pointee.key, let value = nextTag.pointee.value {
                    let checkKey = String(cString: key).lowercased()
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
                            metadata.trackNo =  extractMetadataTrackNo(text: String(cString: value))
                        case "year", "date", "time":
                            if metadata.recordingYear == 0 {
                                metadata.recordingYear = extractMetadataYear(text: String(cString: value))
                            }                
                        default:
                            tag = nextTag                            
                    }                    
                }
                tag = nextTag
            }            
            
            // Clean up
            avformat_close_input(&formatContext)
            
            // Log we found metadatda
            // this is a preformance issue
            //PlayerLog.ApplicationLog?.logInformation(title: "[M4aAudioPlayer].gatherMetadata()", text: "Found metadata for: \(path.path)")

            return metadata         
        }

        let msg = "[M4aAudioPlayer].gatherMetadata(). Unknown file type from file: \(path.path)"
        throw CmpError(message: msg)
    }
    ///
    /// errorToString
    /// 
    /// converts an av error code to string.
    ///
    func errorToString(error: Int32) -> String {
        var errBuf = [CChar](repeating: 0, count: 128)
        av_strerror(error, &errBuf, errBuf.count)
        return "\(String(cString: errBuf))"
    }
}// AudioPlayer