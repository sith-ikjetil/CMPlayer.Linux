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
#if CMP_FFMPEG_V5 || CMP_FFMPEG_V6 || CMP_FFMPEG_V7
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
let av_ch_layout_stereo: Int32 = 1|2    // constant stereo layout
//
// Represents CMPlayer AudioPlayer.
//
internal final class M4aAudioPlayer : CmpAudioPlayerProtocol {
    ///
    /// constants
    ///
    private let filePath: URL    // file path to song we are playing
    private let audioQueue = DispatchQueue(label: "dqueue.cmp.linux.m4a-audio-player", qos: .background)
    ///
    /// variables
    ///
    private var m_stopFlag: Bool = false        // true == we must stop playing
    private var m_isPlaying: Bool = false       // true == we are currently in playing process
    private var m_isPaused: Bool = false        // true == we are currently playing, but are paused
    private var m_hasPlayed: Bool = false       // true == we have played
    private var m_timeElapsed: UInt64 = 0       // amount (milliseconds) of time we have played
    private var m_duration: UInt64 = 0          // amount (milliseconds) of time in song we are playing
    private var m_audioState: M4aAudioState = M4aAudioState()   // ao/alsa/ffmpeg audio state
    private var m_targetFadeVolume: Float = 1       // target fade volume. 1 = 100%, 0 = 0% (muted) 
    private var m_targetFadeDuration: UInt64 = 0    // duration (milliseconds) the crossfade should take
    private var m_enableCrossfade: Bool = false     // true == we are doing a crossfade
    private var m_seekPos: UInt64 = 0               // position (milliseconds) of time left in the song we shoudl jump/seek to
    private var m_doSeekToPos: Bool = false         // true == we are doing a seek
    ///
    /// get properties
    ///
    // return if we are currently playing
    var isPlaying: Bool {
        get {
            return self.m_isPlaying
        }
    }
    // return if we are playing but are paused
    var isPaused: Bool {
        get {
            return self.m_isPaused
        }
    }
    // return if we have played and have finished
    var hasPlayed: Bool {
        get {
            return self.m_hasPlayed
        }
    }    
    // return time elapsed in currently playing song
    var timeElapsed: UInt64 {
        get {
            return self.m_timeElapsed
        }
    }
    // return duration of currently playing song
    var duration: UInt64 {
        get {
            return self.m_duration
        }
    }    
    ///
    /// Only initializer
    ///
    init(path: URL) {
        // set filePath to path
        self.filePath = path        
    }
    //
    // deinit
    //
    deinit {
        
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
#if CMP_FFMPEG_V5 || CMP_FFMPEG_V6 || CMP_FFMPEG_V7
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
#if CMP_FFMPEG_V5 || CMP_FFMPEG_V6 || CMP_FFMPEG_V7     
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
        av_channel_layout_default(&self.m_audioState.chLayoutOut, 2)                
        // set channel layout to SwrCtx
        err = av_opt_set_chlayout(rawSwrCtxPtr, "out_chlayout", &self.m_audioState.chLayoutOut, 0)
        if err < 0 {
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
        err = av_opt_set_int(rawSwrCtxPtr, "in_channel_layout", Int64(self.m_audioState.codecCtx!.pointee.channel_layout), 0)
        // if error
        if err < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). av_opt_set_int for 'in_channel_layout' failed with value: \(err) = '\(renderFfmpegError(error: err))'."
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
        // set out channel layout to swrCtx
        err = av_opt_set_int(rawSwrCtxPtr, "out_channel_layout", Int64(av_ch_layout_stereo), 0)
        // if error
        if err < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). av_opt_set_int for 'out_channel_layout' failed with value: \(err) = '\(renderFfmpegError(error: err))'."
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
#endif        
        // set input sample rate to swrCtx
        err = av_opt_set_int(rawSwrCtxPtr, "in_sample_rate", Int64(self.m_audioState.codecCtx!.pointee.sample_rate), 0)
        // if error
        if err < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). av_opt_set_int for 'in_sample_rate' failed with value: \(err) = '\(renderFfmpegError(error: err))'."
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
        // set out sample rate to swrCtx
        err = av_opt_set_int(rawSwrCtxPtr, "out_sample_rate", 44100, 0)
        // if error
        if err < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). av_opt_set_int for 'out_sample_rate' failed with value: \(err) = '\(renderFfmpegError(error: err))'."
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
        // set in sample format to swrCtx
        err = av_opt_set_sample_fmt(rawSwrCtxPtr, "in_sample_fmt", self.m_audioState.codecCtx!.pointee.sample_fmt, 0)
        // if error
        if err < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). av_opt_set_int for 'in_sample_fmt' failed with value: \(err) = '\(renderFfmpegError(error: err))'."
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
        // set out sample format to swrCtx
        err = av_opt_set_sample_fmt(rawSwrCtxPtr, "out_sample_fmt", AV_SAMPLE_FMT_S16, 0)
        // if error
        if err < 0 {
            // create error message
            let msg = "[M4aAudioPlayer].play(). av_opt_set_int for 'out_sample_fmt' failed with value: \(err) = '\(renderFfmpegError(error: err))'."
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
    #if CMP_FFMPEG_V5 || CMP_FFMPEG_V6 || CMP_FFMPEG_V7
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
    #if CMP_FFMPEG_V5 || CMP_FFMPEG_V6 || CMP_FFMPEG_V7
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
    #if CMP_FFMPEG_V5 || CMP_FFMPEG_V6 || CMP_FFMPEG_V7
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
#if CMP_FFMPEG_V5 || CMP_FFMPEG_V6 || CMP_FFMPEG_V7
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
            // check for EOF
            guard retVal != 0xEDE2 else { // AVERROR_EOF
                // else we have end of file
                // return
                return
            }
            // guard for success
            guard retVal >= 0 else {
                // else we have an error
                // create log messsge
                let msg = "av_read_frame failed with value: \(retVal) = '\(renderFfmpegError(error: retVal))'."
                // log message
                PlayerLog.ApplicationLog?.logError(title: "[M4aPlayer].playAsync()", text: msg)
                // return
                return
            }
            // ensure cleanup by defer
            defer {
                av_packet_unref(&self.m_audioState.packet)
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
                // if success
                guard retVal >= 0 else {
                    // else we have an error
                    // create error message
                    let msg = "avcodec_send_packet failed with value: \(retVal) = '\(renderFfmpegError(error: retVal))'."
                    // log error
                    PlayerLog.ApplicationLog?.logError(title: "[M4aAudioPlayer].playAsync()", text: msg)
                    // return
                    return
                }                                
                // while we are not quitting, stopping or 
                while !g_quit && !m_stopFlag {
                    // return decoded output
                    retVal = avcodec_receive_frame(self.m_audioState.codecCtx, self.m_audioState.frame)
                    // if retval indicates we needs to try again
                    if retVal == -EAGAIN { 
                        // AVERROR(EAGAIN) = -11
                        // break current loop
                        break
                    }
                    // guard retVal success
                    guard retVal == 0 else {
                        // else we have an error
                        // create error message
                        let msg = "avcodec_receive_frame failed with value: \(retVal) = '\(renderFfmpegError(error: retVal))'."
                        // log error
                        PlayerLog.ApplicationLog?.logDebug(title: "[M4aAudioPlayer].playAsync()", text: msg)
                        // return
                        return
                    }
                    // ensure cleanup by defer                    
                    defer {
                        // release all resources associated with this AVFrame.
                        av_frame_unref(self.m_audioState.frame)
                    }
                    // create a read/write pointer to outputBuffer
                    var outputBuffer: UnsafeMutablePointer<UInt8>? = nil
                    // allocate a samples buffer for nb_samples samples
                    retVal = av_samples_alloc(&outputBuffer, nil, 2, self.m_audioState.frame!.pointee.nb_samples, AV_SAMPLE_FMT_S16, 0)                    
                    // Ensure the buffer is allocated properly
                    guard retVal >= 0 else {
                        let msg = "av_samples_alloc failed with value: \(retVal) = '\(renderFfmpegError(error: retVal))'."
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
                            // else error occured
                            // create error message
                            let msg = "swr_convert returned with value: \(samples) = '\(renderFfmpegError(error: samples))'."
                            // log message
                            PlayerLog.ApplicationLog?.logError(title: "[M4aAudioPlayer].playAsync()", text: msg)
                            // return
                            return
                        }
                        // total bytes of samples: samples * channels * 2 (16 bit)
                        let totalBytes: UInt32 = UInt32(samples * self.m_audioState.aoFormat.channels * (self.m_audioState.aoFormat.bits/8))
                        // total samples per channel
                        let totalBytesPerChannel: UInt64 = UInt64(totalBytes) / UInt64(self.m_audioState.aoFormat.channels)
                        // duration of samples
                        let currentDuration: Double = Double(totalBytesPerChannel) / Double(MemoryLayout<Int16>.size * Int(self.m_audioState.aoFormat.rate))
                        // time elapsed when these bytes are played
                        self.m_timeElapsed += UInt64(currentDuration * 1000.0)                        
                        // set crossfade volume
                        let timeLeft: UInt64 = (self.duration >= self.m_timeElapsed) ? self.duration - self.m_timeElapsed : self.duration
                        // if time is inside fade duration
                        if timeLeft > 0 && timeLeft <= self.m_targetFadeDuration {
                            // set timeToStartCrossfade flag to true
                            timeToStartCrossfade = true
                            // calculate volume 100%-0% volume over m_targetFadeDuration                            
                            currentVolume = max(0.0, min(1.0, Float(timeLeft) / Float(self.m_targetFadeDuration)))                 
                        }
                        // else time is not inside fade duration
                        else {
                            // set timeToStartCrossfade flag to false
                            timeToStartCrossfade = false
                        }
                        // adjust crossfade volume
                        if self.m_enableCrossfade && timeToStartCrossfade {
                            adjustVolume(buffer: UnsafeMutableRawPointer(outputBuffer!).assumingMemoryBound(to: CChar.self), size: Int(totalBytes), volume: currentVolume)
                        }
                        // if ao
                        if PlayerPreferences.outputSoundLibrary == .ao {
                            // send samples to ao for playback
                            let err: Int32 = ao_play(self.m_audioState.device, UnsafeMutableRawPointer(outputBuffer!).assumingMemoryBound(to: CChar.self), totalBytes)                            
                            // guard for success
                            guard err != 0 else {                                
                                // else we have an error
                                // get errno from system
                                let errorNumber: Int32 = errno
                                // convert errorNumber to string
                                let errorDescription: String? = String(validatingUTF8: strerror(errorNumber))                                
                                // create an error message                                
                                let msg = "ao_player failed with value: \(err). System errno had value: \(errno) = '\(errorDescription ?? "?")'."
                                // log error
                                PlayerLog.ApplicationLog?.logError(title: "[M4aAudioPlayer].playAsync()", text: msg)                        
                                // return
                                return
                            }
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
        // check position is valid
        guard position <= self.duration else {
            // else return
            return
        }
        // set m_seekPos to position
        self.m_seekPos = position
        // set m_doSeekToPos flag to true
        self.m_doSeekToPos = true
    }
    /// 
    /// Adjusts volume in the sample buffer to a factor 0.0-1.0
    ///     
    func adjustVolume(buffer: UnsafeMutablePointer<Int8>, size: Int, volume: Float) {
        // number of samples
        let sampleCount = size / MemoryLayout<Int16>.size
        // pointer to samples
        let samples = buffer.withMemoryRebound(to: Int16.self, capacity: sampleCount) { $0 }
        // for each sample
        for i in 0..<sampleCount {
            // adjusted sample
            let adjustedSample = Float(samples[i]) * volume
            // ensure the value is within the Int16 range
            samples[i] = Int16(max(min(adjustedSample, Float(Int16.max)), Float(Int16.min)))
        }
    }
    /// 
    /// Sets how the volume is done with crossfading enabled.
    /// - Parameters:
    ///   - volume: target volume. usually 0.
    ///   - duration: time from end of song, fading should be done.
    func setCrossfadeVolume(volume: Float, fadeDuration: UInt64) {
        // if volume is valid
        guard volume >= 0 && volume <= 1 else {
            // else return
            return
        }
        // if crossfade time is valid
        guard isCrossfadeTimeValid(seconds: Int(fadeDuration / 1000)) else {
            // else return
            return
        }
        // set target volume
        self.m_targetFadeVolume = volume
        // set crossfade duration
        self.m_targetFadeDuration = fadeDuration
        // set m_enableCrossfade flag to true
        self.m_enableCrossfade = true
    }
    ///
    /// stops playback if we are playing.
    /// 
    func stop() {
        // we are stopping so set the m_stopFlag to true
        self.m_stopFlag = true
    }
    ///
    /// pauses playback if we are playing
    /// 
    func pause() {
        // we are pausing so set the m_isPaused to true
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
        // create a metadata instance
        let metadata = CmpMetadata()              
        // if path points to a m4a file
        if path.path.lowercased().hasSuffix(".m4a") {
            // set filename
            let filename = path.path
            // create a pointer read/write variable
            var formatContext: UnsafeMutablePointer<AVFormatContext>? = nil                        
            // open input stream
            var err = avformat_open_input(&formatContext, filename, nil, nil)
            // if error
            if err != 0 {
                // create error message
                let msg = "[M4aAudioPlayer].gatherMetadata(). avformat_open_input failed with value: \(err) = '\(renderFfmpegError(error: err))'."
                // throw error
                throw CmpError(message: msg)
            }
            // ensure cleanup by defer
            defer {
                // close opened input
                avformat_close_input(&formatContext)
            }
            // Retrieve stream information
            err = avformat_find_stream_info(formatContext, nil)
            // if error
            if err < 0 {
                // create error message
                let msg = "[M4aAudioPlayer].gatherMetadata(). avformat_find_stream_info failed with value: \(err) = '\(renderFfmpegError(error: err))'."
                // close opened input
                avformat_close_input(&formatContext)
                // throw error                
                throw CmpError(message: msg)
            }
            // if formatCtx is valid and it has a duration
            if let formatCtx = formatContext, formatCtx.pointee.duration != 0x00 { // AV_NOPTS_VALUE {
                // set duration in seconds
                let durationInSeconds = Double(formatCtx.pointee.duration) / Double(AV_TIME_BASE)                
                // if duration in seconds is negative or 0
                if durationInSeconds <= 0 {               
                    // create error message     
                    let msg = "[M4aAudioPlayer].gatherMetadata(). duration <= 0. \(durationInSeconds) seconds"
                    // close opened input
                    avformat_close_input(&formatContext)
                    // throw error
                    throw CmpError(message: msg)
                }
                metadata.duration = UInt64(durationInSeconds * 1000)
            }
            // else formatCtx is invalid or duration is 0
            else {
                // create error message
                let msg = "[M4aAudioPlayer].gatherMetadata(). Cannot find duration."
                // close opened input
                avformat_close_input(&formatContext)
                // throw error
                throw CmpError(message: msg)
            }      
            // if formatContext is invalid or formatContext metadata is invalid
            if formatContext == nil || formatContext?.pointee.metadata == nil {
                // create error message
                let msg = "[M4aAudioPlayer].gatherMetadata(). formatContext/metadata is nil."
                // close opened input
                avformat_close_input(&formatContext)
                // throw error
                throw CmpError(message: msg)
            }
            // create a read/write pointer
            var tag: UnsafeMutablePointer<AVDictionaryEntry>? = nil
            // loop so long as av_dict_get returns a valid nextTag pointer
            while let nextTag = av_dict_get(formatContext?.pointee.metadata, "", tag, AV_DICT_IGNORE_SUFFIX) {
                // if key and value are valid pointers
                if let key = nextTag.pointee.key, let value = nextTag.pointee.value {
                    // set checkKey to key
                    let checkKey = String(cString: key).lowercased()
                    // switch checkKey
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
                            // set tag to next tag
                            tag = nextTag                            
                    }                    
                }
                // set tag to next tag
                tag = nextTag
            }         
            // return metadata                                       
            return metadata         
        }
        // create error message
        let msg = "[M4aAudioPlayer].gatherMetadata(). Unknown file type from file: \(path.path)"
        // throw error
        throw CmpError(message: msg)
    }
}// M4aAudioPlayer
