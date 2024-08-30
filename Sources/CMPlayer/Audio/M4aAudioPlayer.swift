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
    private let audioQueue = DispatchQueue(label: "dqueue.cmp.linux.m4a-audio-player", qos: .background)
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
            // return
            return;
        }        
        // if we have paused playback, then resume on play again
        if (self.m_isPaused) {
            // resume
            self.resume()
            // return
            return;
        }
        // reset m_hasPlayer to false
        self.m_hasPlayed = false
        // reset m_stopFlag to false
        self.m_stopFlag = false
        // open input stream and read header
        var err = avformat_open_input(&self.m_audioState.formatCtx, self.filePath.path, nil, nil)
        // if error
        if err != 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). avformat_open_input failed with value \(err) = '\(renderFfmpegError(error: err))'. Could not open file \(self.filePath.path)."
            // throw error
            throw CmpError(message: msg)
        }
        // if formatCtx pointer is invalid
        if self.m_audioState.formatCtx == nil {
            // create error message
            let msg = "[M4aAudioPlayer].play(). m_audioState.formatCtx is nil."
            // throw error
            throw CmpError(message: msg)
        }        
        // get stream information
        err = avformat_find_stream_info(self.m_audioState.formatCtx, nil)
        // if error
        if err < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). avformat_find_stream_info failed with value: \(err) = '\(renderFfmpegError(error: err))'. Could not find stream information."
            // close opened input
            avformat_close_input(&m_audioState.formatCtx)
            // throw error
            throw CmpError(message: msg)
        }                
        // find the audio stream
        for i in 0..<Int32(self.m_audioState.formatCtx!.pointee.nb_streams) {
            if self.m_audioState.formatCtx!.pointee.streams![Int(i)]!.pointee.codecpar.pointee.codec_type == AVMEDIA_TYPE_AUDIO {
                // set audio stream index to index
                self.m_audioState.audioStreamIndex = i
                // found stream, exit loop
                break
            }
        }
        // if not find audio stream then error
        if self.m_audioState.audioStreamIndex < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). m_audioState.audioStreamIndex invalid with value: \(self.m_audioState.audioStreamIndex)."
            // close opened input
            avformat_close_input(&m_audioState.formatCtx)
            // throw error
            throw CmpError(message: msg)
        }
        // if audioState is valid, calculate duration in seconds
        if let formatCtx = self.m_audioState.formatCtx, formatCtx.pointee.duration != 0x00 { 
            // get duration
            let durationInSeconds = Double(formatCtx.pointee.duration) / Double(AV_TIME_BASE)                
            // if invalid duration
            if durationInSeconds <= 0 {                    
                // create error message
                let msg = "[M4aAudioPlayer].play(). duration <= 0. \(durationInSeconds) seconds"
                // close opened input
                avformat_close_input(&self.m_audioState.formatCtx)
                // throw error
                throw CmpError(message: msg)
            }
            // set m_duration to duration in ms
            self.m_duration = UInt64(durationInSeconds * 1000)
        }
        // audioState invalid
        else {
            // create error message
            let msg = "[M4aAudioPlayer].play(). Cannot find duration."
            // close opened input
            avformat_close_input(&self.m_audioState.formatCtx)
            // throw error
            throw CmpError(message: msg)
        }              
        // get codec parameters
        let codecpar = self.m_audioState.formatCtx!.pointee.streams![Int(self.m_audioState.audioStreamIndex)]!.pointee.codecpar
        // find the decoder for the audio stream 
#if CMP_FFMPEG_V6 || CMP_FFMPEG_V7
        self.m_audioState.codec = avcodec_find_decoder(codecpar!.pointee.codec_id)
#elseif CMP_FFMPEG_V4
        self.m_audioState.codec = UnsafeMutablePointer(mutating: avcodec_find_decoder(codecpar!.pointee.codec_id))
#endif
        // if audio codec is invalid
        if self.m_audioState.codec == nil {
            // create error message
            let msg = "[M4aAudioPlayer].play(). avcodec_find_decoder failed with value: nil. Unsupported codec: \(codecpar!.pointee.codec_id)."
            // close opened input
            avformat_close_input(&self.m_audioState.formatCtx)            
            // throw error
            throw CmpError(message: msg)
        }            
        // allocate codec context and set fields to default values
        self.m_audioState.codecCtx = avcodec_alloc_context3(self.m_audioState.codec)
        // if codec context is invalid
        if self.m_audioState.codecCtx == nil {
            // create error message
            let msg = "[M4aAudioPlayer].play(). avcodec_alloc_context3 failed with value: nil. Could not allocate codec context."
            // close opened input
            avformat_close_input(&self.m_audioState.formatCtx)            
            // throw error
            throw CmpError(message: msg)
        }
        // fill codec context based on codec parameters
        err = avcodec_parameters_to_context(self.m_audioState.codecCtx, codecpar)
        if err < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). avcodec_parameters_to_context failed with value: \(err) = '\(renderFfmpegError(error: err))'. Could not copy codec context."
            // free codec context
            avcodec_free_context(&self.m_audioState.codecCtx)
            // close opened input
            avformat_close_input(&self.m_audioState.formatCtx)            
            // throw error
            throw CmpError(message: msg)
        }
        // initialize codec context by given codec
        err = avcodec_open2(self.m_audioState.codecCtx, self.m_audioState.codec, nil)
        // if error
        if err < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). avcodec_open2 failed with value: \(err) = '\(renderFfmpegError(error: err))'. Could not open codec."
            // free codec context
            avcodec_free_context(&self.m_audioState.codecCtx)
            // close opened input
            avformat_close_input(&self.m_audioState.formatCtx)
            // throw error
            throw CmpError(message: msg)
        }        
        // allocate frame and set default values
        self.m_audioState.frame = av_frame_alloc()
        // if frame invalid
        if self.m_audioState.frame == nil {
            // create error message
            let msg = "[M4aAudioPlayer].play(). av_frame_alloc failed with value: nil. Could not allocate audio frame."
            // free codec context
            avcodec_free_context(&self.m_audioState.codecCtx)
            // free opened input
            avformat_close_input(&self.m_audioState.formatCtx)            
            // throw error
            throw CmpError(message: msg)
        }        
        // allocate SwrContext
        self.m_audioState.swrCtx = swr_alloc()
        // create a mutable raw pointer
        let rawSwrCtxPtr: UnsafeMutableRawPointer? = UnsafeMutableRawPointer(self.m_audioState.swrCtx)
#if CMP_FFMPEG_V6 || CMP_FFMPEG_V7     
        // copy channel layout from ch_layout to chLayoutIn
        err = av_channel_layout_copy(&self.m_audioState.chLayoutIn, &self.m_audioState.codecCtx!.pointee.ch_layout)        
        // if error
        if err < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). av_channel_layout_copy failed with value: \(err) = '\(renderFfmpegError(error: err))'."
            // free swrCtx
            swr_free(&self.m_audioState.swrCtx)
            // free frame
            av_frame_free(&self.m_audioState.frame)
            // free codec context
            avcodec_free_context(&self.m_audioState.codecCtx)
            // free opened input
            avformat_close_input(&self.m_audioState.formatCtx)  
            // throw error
            throw CmpError(message: msg)
        }
        // set channel layout to swrCtx
        err = av_opt_set_chlayout(rawSwrCtxPtr, "in_chlayout", &self.m_audioState.chLayoutIn, 0)        
        // if error
        if err < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). av_opt_set_chlayout IN failed with value: \(err) = '\(renderFfmpegError(error: err))'."
            // free swrCtx
            swr_free(&self.m_audioState.swrCtx)
            // free frame
            av_frame_free(&self.m_audioState.frame)
            // free codec context
            avcodec_free_context(&self.m_audioState.codecCtx)
            // close opened input
            avformat_close_input(&self.m_audioState.formatCtx)  
            // throw error
            throw CmpError(message: msg)
        }
        // set default values to chLayoutOut
        av_channel_layout_default(&self.m_audioState.chLayoutOut, 2);
        // set channel layout to SwrCtx
        err = av_opt_set_chlayout(rawSwrCtxPtr, "out_chlayout", &self.m_audioState.chLayoutOut, 0)
        if ret < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). av_opt_set_chlayout OUT failed with value: \(err) = '\(renderFfmpegError(error: err))'."
            // free swrCtx
            swr_free(&self.m_audioState.swrCtx)
            // free frame
            av_frame_free(&self.m_audioState.frame)
            // free codec context
            avcodec_free_context(&self.m_audioState.codecCtx)
            // close opened input
            avformat_close_input(&self.m_audioState.formatCtx)  
            // throw error
            throw CmpError(message: msg)
        }        
#elseif CMP_FFMPEG_V4
        // set in channel layout to swrCtx
        av_opt_set_int(rawSwrCtxPtr, "in_channel_layout", Int64(self.m_audioState.codecCtx!.pointee.channel_layout), 0)
        // set out channel layout to swrCtx
        av_opt_set_int(rawSwrCtxPtr, "out_channel_layout", Int64(av_ch_layout_stereo), 0)
#endif        
        // set input sample rate to swrCtx
        av_opt_set_int(rawSwrCtxPtr, "in_sample_rate", Int64(self.m_audioState.codecCtx!.pointee.sample_rate), 0)
        // set out sample rate to swrCtx
        av_opt_set_int(rawSwrCtxPtr, "out_sample_rate", 44100, 0)
        // set in sample format to swrCtx
        av_opt_set_sample_fmt(rawSwrCtxPtr, "in_sample_fmt", self.m_audioState.codecCtx!.pointee.sample_fmt, 0)
        // set out sample format to swrCtx
        av_opt_set_sample_fmt(rawSwrCtxPtr, "out_sample_fmt", AV_SAMPLE_FMT_S16, 0)
        // initialize context
        err = swr_init(self.m_audioState.swrCtx)
        // if error
        if err < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). swr_init failed with value: \(err) = '\(renderFfmpegError(error: err))'."
            // free swrCtx
            swr_free(&self.m_audioState.swrCtx)
            // free frame
            av_frame_free(&self.m_audioState.frame)
            // free codec context
            avcodec_free_context(&self.m_audioState.codecCtx)
            // close opened input
            avformat_close_input(&self.m_audioState.formatCtx)  
            // throw error
            throw CmpError(message: msg)
        }
        // Set up libao format
        // bits per sample
        self.m_audioState.aoFormat.bits = 16
        // number of channels, 2 = stereo
        self.m_audioState.aoFormat.channels = 2
        // sample rate
        self.m_audioState.aoFormat.rate = 44100
        // byte format
        self.m_audioState.aoFormat.byte_format = AO_FMT_NATIVE
        // matrix
        self.m_audioState.aoFormat.matrix = nil
        // Set up libasound (alsa) format        
        // number of channels, 2 = stereo
        self.m_audioState.alsaState.channels = 2
        // sample rate
        self.m_audioState.alsaState.sampleRate = 44100 
        // buffer size
        self.m_audioState.alsaState.bufferSize = 1024         
        // if .ao, open libao device
        if PlayerPreferences.outputSoundLibrary == .ao {
            // open ao with default driver id and set ao format
            self.m_audioState.device = ao_open_live(ao_default_driver_id(), &self.m_audioState.aoFormat, nil)
            // if device returned is invalid
            if self.m_audioState.device == nil {
                // create error message
                let msg = "[M4aAudioPlayer].play(). ao_open_live failed with value: nil. Error opening audio device."
    #if CMP_FFMPEG_V6 || CMP_FFMPEG_V7
                // uninitialize ch layout in
                av_channel_layout_uninit(&self.m_audioState.chLayoutIn)
                // uninitialize ch layout out
                av_channel_layout_uninit(&self.m_audioState.chLayoutOut)
    #endif
                // free swrCtx
                swr_free(&self.m_audioState.swrCtx)
                // free frame
                av_frame_free(&self.m_audioState.frame)
                // free codec context
                avcodec_free_context(&self.m_audioState.codecCtx)
                // close opened input
                avformat_close_input(&self.m_audioState.formatCtx)
                // throw error
                throw CmpError(message: msg)
            }
        }
        // else if .alsa, open alsa device
        else if PlayerPreferences.outputSoundLibrary == .alsa {
            // open alsa with device name = pcmDeviceName
            var err = snd_pcm_open(&self.m_audioState.alsaState.pcmHandle, self.m_audioState.alsaState.pcmDeviceName, SND_PCM_STREAM_PLAYBACK, 0)
            // if error
            guard err >= 0 else {
                // create error message
                let msg = "[M4aAudioPlayer].play(). alsa. snd_pcm_open failed with value: \(err) = '\(renderAlsaError(error: err))'"
    #if CMP_FFMPEG_V6 || CMP_FFMPEG_V7
                // uninitialize ch layout in
                av_channel_layout_uninit(&self.m_audioState.chLayoutIn)
                // uninitialize ch layout out
                av_channel_layout_uninit(&self.m_audioState.chLayoutOut)
    #endif
                // free swrCtx
                swr_free(&self.m_audioState.swrCtx)
                // free frame
                av_frame_free(&self.m_audioState.frame)
                // free codec context
                avcodec_free_context(&self.m_audioState.codecCtx)
                // close opened input
                avformat_close_input(&self.m_audioState.formatCtx)
                // throw error
                throw CmpError(message: msg)
            }
            // set alsa pcm parameters
            err = snd_pcm_set_params(self.m_audioState.alsaState.pcmHandle, SND_PCM_FORMAT_S16_LE, SND_PCM_ACCESS_RW_INTERLEAVED, self.m_audioState.alsaState.channels, self.m_audioState.alsaState.sampleRate, 1, 500000)
            // if error
            guard err >= 0 else {
                // create error message
                let msg = "[M4aAudioPlayer].play(). alsa. snd_pcm_set_params failed with value: \(err) = '\(renderAlsaError(error: err))'"
    #if CMP_FFMPEG_V6 || CMP_FFMPEG_V7
                // uninitialize ch layout in
                av_channel_layout_uninit(&self.m_audioState.chLayoutIn)
                // uninitialize ch layout out
                av_channel_layout_uninit(&self.m_audioState.chLayoutOut)
    #endif
                // free swrCtx
                swr_free(&self.m_audioState.swrCtx)
                // free frame
                av_frame_free(&self.m_audioState.frame)
                // free codec context
                avcodec_free_context(&self.m_audioState.codecCtx)
                // close opened input
                avformat_close_input(&self.m_audioState.formatCtx)
                // throw error                     
                throw CmpError(message: msg)
            }
        }
        // run code async
        self.audioQueue.async { [weak self] in            
            // play audio
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
            // uninit chLayoutIn
            av_channel_layout_uninit(&self.m_audioState.chLayoutIn)
            // uninit chLayoutOut
            av_channel_layout_uninit(&self.m_audioState.chLayoutOut)
#endif            
            // free context allocated with swr_alloc
            swr_free(&self.m_audioState.swrCtx)
            // free frame allocated with av_frame_alloc
            av_frame_free(&self.m_audioState.frame)
            // free codec context
            avcodec_free_context(&self.m_audioState.codecCtx)
            // close an opened input AVFormatContext.
            avformat_close_input(&self.m_audioState.formatCtx)
            // if we use ao
            if PlayerPreferences.outputSoundLibrary == .ao {
                // close ao device
                ao_close(self.m_audioState.device)
            }
            // else if we use alsa
            else if PlayerPreferences.outputSoundLibrary == .alsa {
                // drain alsa
                snd_pcm_drain(self.m_audioState.alsaState.pcmHandle)
                // close alsa
                snd_pcm_close(self.m_audioState.alsaState.pcmHandle)
            }
            // set m_timeElapsed to duration, nothing more to play
            self.m_timeElapsed = self.duration
            // set m_hasPlayed to true
            self.m_hasPlayed = true
            // set m_isPlaying to false
            self.m_isPlaying = false
            // set m_isPaused to false
            self.m_isPaused = false
            // set m_stopFlag to true
            self.m_stopFlag = true      
            // log debug
            PlayerLog.ApplicationLog?.logDebug(title: "[M4aAudioPlayer].playAsync()@defer", text: self.filePath.path)      
        }
        // should we do crossfade now or not
        var timeToStartCrossfade: Bool = false
        // set current volume to 100%
        var currentVolume: Float = 1
        // reset m_timeElapsed to 0
        self.m_timeElapsed = 0
        // Main decoding and playback loop
        while !self.m_stopFlag && !g_quit {
            // we are to seek to position   
            if (self.m_doSeekToPos) {
                // do not seek at next loop
                self.m_doSeekToPos = false
                // Access the stream and its time_base
                let audioStream = self.m_audioState.formatCtx!.pointee.streams[Int(self.m_audioState.audioStreamIndex)]!
                // get num seconds of frame timestamps
                let timeBase = audioStream.pointee.time_base
                // Convert the time_base to a human-readable format
                let timeBaseNum = timeBase.num
                let timeBaseDen = timeBase.den
                // calculate seconds at where to seek to
                let seconds: UInt64 = (self.duration - self.m_seekPos) / 1000                                
                // calculate frame seconds to where to seek
                let newPos: Int64 = Int64(seconds) * Int64(timeBaseDen/timeBaseNum)
                // seek to timeframe at newPos 
                if av_seek_frame(self.m_audioState.formatCtx, self.m_audioState.audioStreamIndex, newPos, AVSEEK_FLAG_ANY) == 0 {                
                    // update m_timeElapsed to new value
                    self.m_timeElapsed = (seconds * 1000)
                }            
            }
            // return next frame of stream
            var retVal: Int32 = av_read_frame(self.m_audioState.formatCtx, &self.m_audioState.packet)
            // if error or EOF
            if retVal < 0 {
                // return 
                return
            }
            // if codecCtx and frame are invalid pointers
            guard let _ = self.m_audioState.codecCtx, let _ = self.m_audioState.frame else {
                // create log messsge
                let msg = "Codec context or frame is nil."
                // log message
                PlayerLog.ApplicationLog?.logError(title: "[M4aPlayer].playAsync()", text: msg)
                // return
                return
            }
            // if stream is audio
            if self.m_audioState.packet.stream_index == self.m_audioState.audioStreamIndex {
                // supply raw packet data as input to a decoder.
                retVal = avcodec_send_packet(self.m_audioState.codecCtx, &self.m_audioState.packet)
                // if error
                if retVal < 0 {
                    // create log message
                    let msg = "[M4aAudioPlayer].playAsync(). avcodec_send_packet failed with value: \(retVal) = '\(renderFfmpegError(error: retVal))'."
                    // log error
                    PlayerLog.ApplicationLog?.logError(title: "[M4aAudioPlayer].playAsync()", text: msg)
                    // return
                    return
                }
                // ensure cleanup by defer
                defer {
                    av_packet_unref(&self.m_audioState.packet)
                }
                // while we are not quitting, stopping or 
                while !g_quit && !m_stopFlag && (avcodec_receive_frame(self.m_audioState.codecCtx, self.m_audioState.frame) == 0) {
                    // create a read/write pointer to outputBuffer
                    var outputBuffer: UnsafeMutablePointer<UInt8>? = nil
                    // allocate a samples buffer for nb_samples samples
                    retVal = av_samples_alloc(&outputBuffer, nil, 2, self.m_audioState.frame!.pointee.nb_samples, AV_SAMPLE_FMT_S16, 0)                    
                    // Ensure the buffer is allocated properly
                    guard retVal >= 0 else {
                        let msg = "Error allocating buffer for resampled audio."
                        PlayerLog.ApplicationLog?.logError(title: "[M4aAudioPlayer].playAsync()", text: msg)
                        return
                    }
                    // ensure cleanup by defer
                    defer {
                        // free the output buffer
                        av_freep(&outputBuffer)  
                    }                    
                    // create a read only pointer
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
                        // convert audio, return number of samples per channel
                        let samples = swr_convert(self.m_audioState.swrCtx, &outputBuffer, self.m_audioState.frame!.pointee.nb_samples, UnsafeMutablePointer(mutating: bufferPointer.baseAddress), self.m_audioState.frame!.pointee.nb_samples)                                                    
                        // Ensure resampling was successful
                        guard samples >= 0 else {
                            let msg = "swr_convert returned with value: \(samples) = '\(renderFfmpegError(error: samples))'."
                            PlayerLog.ApplicationLog?.logError(title: "[M4aAudioPlayer].playAsync()", text: msg)
                            return
                        }
                        // total bytes of samples: samples * channels * 2 (16 bit)
                        let totalBytes: UInt32 = UInt32(samples * self.m_audioState.aoFormat.channels * (self.m_audioState.aoFormat.bits/8))
                        // total samples per channel
                        let totalBytesPerChannel: UInt64 = UInt64(totalBytes) / UInt64(self.m_audioState.aoFormat.channels)
                        // duration of samples
                        let currentDuration: Double = Double(totalBytesPerChannel) / Double(self.m_audioState.aoFormat.rate)
                        // time elapsed when these bytes are played
                        self.m_timeElapsed += UInt64(currentDuration * Double(1000/self.m_audioState.aoFormat.channels))                        
                        // set crossfade volume
                        let timeLeft: UInt64 = (self.duration >= self.m_timeElapsed) ? self.duration - self.m_timeElapsed : self.duration
                        // if we should crossfade
                        if timeLeft > 0 && timeLeft <= self.m_targetFadeDuration {
                            // set timeToStartCrossfade flag to true
                            timeToStartCrossfade = true
                            // calculate volume 100%-0% volume over m_targetFadeDuration
                            currentVolume = Float(Float(timeLeft)/Float(self.m_targetFadeDuration))                    
                        }
                        // adjust crossfade volume
                        if self.m_enableCrossfade && timeToStartCrossfade {
                            adjustVolume(buffer: UnsafeMutableRawPointer(outputBuffer!).assumingMemoryBound(to: CChar.self), size: Int(totalBytes), volume: currentVolume)
                        }
                        // if ao
                        if PlayerPreferences.outputSoundLibrary == .ao {
                            // send samples to ao for playback
                            ao_play(self.m_audioState.device, UnsafeMutableRawPointer(outputBuffer!).assumingMemoryBound(to: CChar.self), totalBytes)                            
                        }
                        // if alsa
                        else {                            
                            // send samples to alsa for playback
                            snd_pcm_writei(self.m_audioState.alsaState.pcmHandle, UnsafeMutableRawPointer(outputBuffer!).assumingMemoryBound(to: CChar.self), snd_pcm_uframes_t(samples))
                        }
                    }                                                                                      
                    // if we are !paused! and not stopping and not quitting
                    while (self.m_isPaused && !self.m_stopFlag && !g_quit) {
                        // sleep for 100 ms
                        usleep(100_000)
                    }                                      
                }// while                    
            }// if av_read_frame
            // if we are !paused! and not stopping and not quitting
            while (self.m_isPaused && !self.m_stopFlag && !g_quit) {
                // sleep for 100 ms
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
        if path.path.lowercased().hasSuffix(".m4a") {
            let filename = path.path
            var formatContext: UnsafeMutablePointer<AVFormatContext>? = nil            
            
            // Open the file
            var err = avformat_open_input(&formatContext, filename, nil, nil)
            if err != 0 {
                let msg = "[M4aAudioPlayer].gatherMetadata(). avformat_open_input failed with value: \(err) = '\(renderFfmpegError(error: err))'."
                throw CmpError(message: msg)
            }

            defer {
                // close opened input
                avformat_close_input(&formatContext)
            }

            // Retrieve stream information
            err = avformat_find_stream_info(formatContext, nil)
            if err < 0 {
                avformat_close_input(&formatContext)
                let msg = "[M4aAudioPlayer].gatherMetadata(). avformat_find_stream_info failed with value: \(err) = '\(renderFfmpegError(error: err))'."
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
                            metadata.genre = extractMetadataGenre(text: String(cString: value))
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
            return metadata         
        }

        let msg = "[M4aAudioPlayer].gatherMetadata(). Unknown file type from file: \(path.path)"
        throw CmpError(message: msg)
    }
}// AudioPlayer
