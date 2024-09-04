//
//  Mp3AudioPlayer.swift
//
//  (i): Audio player for mp3 files.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import.
//
import Foundation
import Cmpg123
import Cao
import Casound
///
/// Mp3 Audio state.
///
internal struct Mp3AudioState {    
    var aoState: AoState = AoState()          // ao state
    var alsaState: AlsaState = AlsaState()    // alsa state
    var length: off_t = 0                     // mp3 length
    var rate: CLong = 0                       // mp3 sample rate    
    var channels: Int32 = 2                   // output audio channels count (2 = stereo)
}
//
// Represents CMPlayer Mp3AudioPlayer.
// using libmpg123
//
internal final class Mp3AudioPlayer : CmpAudioPlayerProtocol {
    ///
    /// private constants
    /// 
    private let filePath: URL   // URL path to file to play
    ///
    /// private variables
    /// 
    private var mpg123Handle: OpaquePointer?    // libmpg123 handle    
    private var m_stopFlag: Bool = false        // should we stop playing
    private var m_isPlaying: Bool = false       // are we currently playing
    private var m_isPaused: Bool = false        // are we currently paused
    private var m_hasPlayed: Bool = false       // have we played our song
    private var m_timeElapsed: UInt64 = 0       // duration of song played
    private var m_duration: UInt64 = 0          // duration of song     
    private var m_targetFadeVolume: Float = 1   // what should fade volume be at end of crossfade
    private var m_targetFadeDuration: UInt64 = 0    // how long should we fade
    private var m_enableCrossfade: Bool = false     // should we perform crossfade
    private var m_seekPos: UInt64 = 0               // position to seek to
    private var m_doSeekToPos: Bool = false         // should we do a seek to
    private var m_audioState: Mp3AudioState = Mp3AudioState()    // mp3 audio state
    // return if we are currently playing
    var isPlaying: Bool {
        get {
            return self.m_isPlaying
        }
    }
    // return if we are paused
    var isPaused: Bool {
        get {
            return self.m_isPaused
        }
    }    
    // return if we have played
    var hasPlayed: Bool {
        get {
            return self.m_hasPlayed
        }
    }
    // return elapsed playing time of file
    var timeElapsed: UInt64 {
        get {
            return self.m_timeElapsed
        }
    }
    // return duration of file
    var duration: UInt64 {
        get {
            return self.m_duration
        }
    }
    ///
    /// initializer
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
        // if we are already playing
        if (self.m_isPlaying) {
            // return
            return;
        }        
        // if we have paused playback
        if (self.m_isPaused) {
            // resume
            self.resume()
            // return
            return;
        }
        // set m_hasPlayed flag to false
        self.m_hasPlayed = false
        // set m_stopFlag to false
        self.m_stopFlag = false
        // make sure mpg123Handle is not already set
        guard mpg123Handle == nil else {
            // else error
            // create error message            
            let msg = "[Mp3AudioPlayer].play(). mpg123Handle != nil. Already playing a file."            
            // throw error
            throw CmpError(message: msg)
        }        
        // create return value variable
        var err: Int32 = 0
        // create a handle with mpg123_new
        self.mpg123Handle = mpg123_new(nil, &err)
        // guard err is 0
        guard err == 0, self.mpg123Handle != nil else { 
            // else error
            // create error message
            let msg = "[Mp3AudioPlayer].play(). mpg123_new failed with value: \(err) = '\(renderMpg123Error(error: err))'. Failed to create mpg123 handle"
            // throw error
            throw CmpError(message: msg)
        }
        // open and prepare to decode path file
        err = mpg123_open(self.mpg123Handle, self.filePath.path)
        // guard err is 0
        guard err == 0 else { 
            // else error
            // create error message
            let msg = "[Mp3AudioPlayer].play(). mpg123_open failed with value: \(err) = '\(renderMpg123Error(error: err))'. Failed to open MP3 file: \(self.filePath.lastPathComponent)"
            // delete handle
            mpg123_delete(self.mpg123Handle)
            // set handle to nil
            self.mpg123Handle = nil
            // throw error
            throw CmpError(message: msg)
        }
        // scan through file so we can get proper length
        err = mpg123_scan(self.mpg123Handle)
        // guard err is 0
        guard err == 0 else {                
            // else error
            // create error message
            let msg = "[Mp3AudioPlayer].play(). mpg123_scan failed with value: \(err) = '\(renderMpg123Error(error: err))'. File: \(self.filePath.path.lastPathComponent)"
            // close handle
            mpg123_close(self.mpg123Handle)
            // delete handle
            mpg123_delete(self.mpg123Handle)            
            // throw error
            throw CmpError(message: msg)                
        }
        // get full length of file in frames
        self.m_audioState.length = mpg123_length(self.mpg123Handle)
        // guard length is > 0
        guard self.m_audioState.length > 0 else {
            // else error
            let msg = "[Mp3AudioPlayer].play(). mpg123_length failed with value: \(self.m_audioState.length)"
            // close handle
            mpg123_close(self.mpg123Handle)
            // delete handle
            mpg123_delete(self.mpg123Handle)
            // throw error
            throw CmpError(message: msg)
        }
        // create rate variable
        var rate: CLong = 0
        // create channels variable
        var channels: Int32 = 0
        // create encoding variable
        var encoding: Int32 = 0
        // get current output format
        err = mpg123_getformat(mpg123Handle, &rate, &channels, &encoding)
        // guard err is 0
        guard err == 0 else {
            // else error
            // create error message
            let msg = "[Mp3AudioPlayer].play(). mpg123_getformat failed with value: \(err) = '\(renderMpg123Error(error: err))'. Failed to get MP3 format."
            // close handle
            mpg123_close(self.mpg123Handle)
            // delete handle
            mpg123_delete(self.mpg123Handle)
            // set handle variable to nil
            self.mpg123Handle = nil
            // throw error
            throw CmpError(message: msg)
        }        
        // set self.m_rate to rate
        self.m_audioState.rate = rate
        // set self.m_channels to channels
        self.m_audioState.channels = channels
        // calculate duration in seconds
        let duration = Double(self.m_audioState.length) / Double(self.m_audioState.rate)
        // calculate and set m_duration (ms)
        self.m_duration = UInt64(duration * 1000)
        // guard duration > 0
        guard self.m_duration > 0 else {
            // else error
            // create error message
            let msg = "[Mp3AudioPlayer].play(). Duration was invalid with value: \(self.m_duration)"                        
            // close handle
            mpg123_close(self.mpg123Handle)
            // delete handle
            mpg123_delete(self.mpg123Handle)
            // set handle variable to nil
            self.mpg123Handle = nil
            // throw error
            throw CmpError(message: msg)
        }
        // configure to set no format
        err = mpg123_format_none(mpg123Handle)
        guard err == 0 else {
            // else error
            // create error message
            let msg = "[Mp3AudioPlayer].play(). mpg123_format_none failed value: \(err) = '\(renderMpg123Error(error: err))'."                        
            // close handle
            mpg123_close(self.mpg123Handle)
            // delete handle
            mpg123_delete(self.mpg123Handle)
            // set handle variable to nil
            self.mpg123Handle = nil
            // throw error
            throw CmpError(message: msg)
        }        
        // set audio format 
        err = mpg123_format(mpg123Handle, 44100, channels, encoding);
        guard err == 0 else {
            // else error
            // create error message
            let msg = "[Mp3AudioPlayer].play(). mpg123_format failed value: \(err) = '\(renderMpg123Error(error: err))'."                        
            // close handle
            mpg123_close(self.mpg123Handle)
            // delete handle
            mpg123_delete(self.mpg123Handle)
            // set handle variable to nil
            self.mpg123Handle = nil
            // throw error
            throw CmpError(message: msg)
        }
        // get default libao playback driver id
        let defaultDriver = ao_default_driver_id()
        // Set up libao format        
        // set bits per sample
        self.m_audioState.aoState.aoFormat.bits = 16
        // set channels, 2 = stereo
        self.m_audioState.aoState.aoFormat.channels = 2
        // set sample rate
        self.m_audioState.aoState.aoFormat.rate = 44100
        // set byte format
        self.m_audioState.aoState.aoFormat.byte_format = AO_FMT_NATIVE
        // set matrix
        self.m_audioState.aoState.aoFormat.matrix = nil
        // Set up libasound format        
        // set channels, 2 = stereo
        self.m_audioState.alsaState.channels = 2
        // set sample rate
        self.m_audioState.alsaState.sampleRate = 44100 
        // set buffer size
        self.m_audioState.alsaState.bufferSize = 1024 
        // if output sound library is .ao
        if PlayerPreferences.outputSoundLibrary == .ao {
            // open ao for playback
            self.m_audioState.aoState.aoDevice = ao_open_live(defaultDriver, &self.m_audioState.aoState.aoFormat, nil)
            // if we have a valid device
            guard self.m_audioState.aoState.aoDevice != nil else {
                // else error, not valid device
                // create error message
                let msg = "[Mp3AudioPlayer].play(). ao_open_live failed. Couldn't open audio device"            
                // close handle
                mpg123_close(self.mpg123Handle)
                // delete handle
                mpg123_delete(self.mpg123Handle)
                // set handle variable to nil
                self.mpg123Handle = nil
                // set m_isPlaying flag to false
                self.m_isPlaying = false                
                // throw error
                throw CmpError(message:msg)
            }
        }
        // else if output sound library is .alsa
        else if PlayerPreferences.outputSoundLibrary == .alsa {
            // open alsa for playback
            var err = snd_pcm_open(&self.m_audioState.alsaState.pcmHandle, self.m_audioState.alsaState.pcmDeviceName, SND_PCM_STREAM_PLAYBACK, 0)
            // check snd_pcm_open for success
            guard err >= 0 else {
                // else we have an error
                // create error message
                let msg = "[Mp3AudioPlayer].play(). alsa. snd_pcm_open failed with value: \(err) = '\(renderAlsaError(error: err))'. Failed to open ALSA PCM device."
                // close handle
                mpg123_close(self.mpg123Handle)
                // delete handle
                mpg123_delete(self.mpg123Handle)
                // set handle variable to nil
                self.mpg123Handle = nil
                // set m_isPlaying flag to false
                self.m_isPlaying = false                
                // throw error
                throw CmpError(message:msg)
            }  
            // set alsa output audio parameters
            err = snd_pcm_set_params(self.m_audioState.alsaState.pcmHandle, SND_PCM_FORMAT_S16_LE, SND_PCM_ACCESS_RW_INTERLEAVED, self.m_audioState.alsaState.channels, self.m_audioState.alsaState.sampleRate, 1, 500000)
            // guard snd_pcm_set_params for success
            guard err >= 0 else {
                // else we have an error
                // create error message
                let msg = "[Mp3AudioPlayer].play(). alsa. snd_pcm_set_params failed with value: \(err) = '\(renderAlsaError(error: err))'"
                // close alsa handle
                snd_pcm_close(self.m_audioState.alsaState.pcmHandle)
                // close handle
                mpg123_close(self.mpg123Handle)
                // delete handle
                mpg123_delete(self.mpg123Handle)                
                // set handle variable to nil
                self.mpg123Handle = nil
                // set m_isPlaying flag to false
                self.m_isPlaying = false                
                // throw error
                throw CmpError(message: msg)
            }
            // prepare for audio playback
            err = snd_pcm_prepare(self.m_audioState.alsaState.pcmHandle)
            // guard snd_pcm_prepare for success
            guard err == 0 else {
                // else we have an error
                // create error message
                let msg = "[Mp3AudioPlayer].play(). alsa. snd_pcm_prepare failed with value: \(err) = '\(renderAlsaError(error: err))'"
                // close alsa handle
                snd_pcm_close(self.m_audioState.alsaState.pcmHandle)
                // close handle
                mpg123_close(self.mpg123Handle)
                // delete handle
                mpg123_delete(self.mpg123Handle)                
                // set handle variable to nil
                self.mpg123Handle = nil
                // set m_isPlaying flag to false
                self.m_isPlaying = false                
                // throw error
                throw CmpError(message: msg)
            }
        }
        // run code async
        DispatchQueue.global(qos: . userInitiated).async {
            // play audio
            self.playAsync()
        }
    }
    ///
    /// Performs the actual playback from play().
    /// Runs in the background.        
    /// - Parameter device: mpg123 handle
    private func playAsync() {
        // set flags
        self.m_isPlaying = true
        // log we have started to play
        PlayerLog.ApplicationLog?.logInformation(title: "[Mp3AudioPlayer].playAsync()", text: "Started playing file: \(self.filePath.lastPathComponent)")
        // make sure we clean up
        defer {                              
            // close mpg123 handle
            mpg123_close(self.mpg123Handle)
            // delete mpg123 handle
            mpg123_delete(self.mpg123Handle)
            // if we use ao
            if PlayerPreferences.outputSoundLibrary == .ao {                 
                // close ao
                ao_close(self.m_audioState.aoState.aoDevice)            
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
            // set mpg123 handle to nil
            self.mpg123Handle = nil
            // set m_hasPlayed to true
            self.m_hasPlayed = true
            // set m_isPlaying to false
            self.m_isPlaying = false
            // set m_isPaused to false
            self.m_isPaused = false
            // set m_stopFlag to true
            self.m_stopFlag = true
            // log debug
            PlayerLog.ApplicationLog?.logDebug(title: "[Mp3AudioPlayer].playAsync()@defer", text: self.filePath.path)      
        }
        // set minimum buffer size for audio output 
        // mpg123_outblock = maximum decoded data size in bytes, minimum buffer size
        let bufferSize: Int = max(mpg123_outblock(self.mpg123Handle), 2048*2*2)
        // buffer of bufferSize
        var buffer: [UInt8] = [UInt8](repeating: 0, count: bufferSize)
        // bytes read from mpg123_read
        var bytesRead: Int = 0
        // flag for when it is time for a crossfade
        var timeToStartCrossfade: Bool = false
        // current volume for crossfade
        var currentVolume: Float = 1
        // reset m_timeElapsed
        self.m_timeElapsed = 0
        // Decode and play the file        
        while !self.m_stopFlag && !g_quit {
            // are we supposed to do a seek
            if (self.m_doSeekToPos) {
                // set m_doSeekToPos flag to false
                self.m_doSeekToPos = false
                // calculate sekk pos seconds
                let seconds: UInt64 = (self.duration - self.m_seekPos) / 1000
                // calculate new position
                let newPos: off_t = off_t(seconds) * self.m_audioState.rate
                // seek to desired sample offset
                let offset: off_t = mpg123_seek(self.mpg123Handle, newPos, SEEK_SET)
                // check for success
                if offset >= 0 {
                    // success, calculate seconds
                    let offsetSeconds: Double = Double(offset) / Double(self.m_audioState.rate)
                    // calculate ms
                    let offsetMs: UInt64 = UInt64(offsetSeconds) * 1000
                    // set m_timeElapsed
                    self.m_timeElapsed = offsetMs
                }
            }
            // read from stream and decode
            let err: Int32 = mpg123_read(self.mpg123Handle, &buffer, bufferSize, &bytesRead)
            // if we are done
            if err == -12 { // MPG123_DONE
                // return, we are finished                
                return
            }
            // check for error
            if (err != 0) { // MPG123_OK
                // create error message
                let msg = "mpg123_read failed with value: \(err) = '\(renderMpg123Error(error: err))'. File: \(self.filePath.lastPathComponent)"
                // log message
                PlayerLog.ApplicationLog?.logError(title: "[Mp3AudioPlayer].playAsync()", text: msg)
                // return
                return
            }
            // if bytes read is 0 or negative
            if bytesRead <= 0 {              
                // invalid read, return   
                return;
            }
            // calculate total current number of bytes per channel
            let totalCurrentBytesPerChannel = bytesRead / Int(self.m_audioState.channels)
            // calculate current duration of read samples
            let currentDuration = Double(totalCurrentBytesPerChannel) / Double(MemoryLayout<Int16>.size * self.m_audioState.rate)
            // update time elapsed
            self.m_timeElapsed += UInt64(currentDuration * 1000.0)
            // calculate time left
            let timeLeft: UInt64 = (self.duration >= self.m_timeElapsed) ? self.duration - self.m_timeElapsed : self.duration
            // if time left is inside fade duration
            if timeLeft > 0 && timeLeft <= self.m_targetFadeDuration {
                // set timeToStartCrossfade flag to true
                timeToStartCrossfade = true
                // calculate current volume
                currentVolume = max(0.0, min(1.0, Float(timeLeft) / Float(self.m_targetFadeDuration)))
            }
            // time left not inside fade duration
            else {
                // set timeToStartCrossfade flag to false
                timeToStartCrossfade = false
            }
            // guard buffer is not empty
            guard !buffer.isEmpty else {
                // else create an error message
                let msg = "Buffer is empty"
                // log error
                PlayerLog.ApplicationLog?.logError(title: "[Mp3AudioPlayer].playAsync()", text: msg)
                // return
                return
            }
            // get read/write pointer
            buffer.withUnsafeMutableBytes { bufferPointer in
                // set pointer to buffer
                let pointer = bufferPointer.baseAddress!.assumingMemoryBound(to: Int8.self)
                // if we are to crossfade
                if self.m_enableCrossfade && timeToStartCrossfade {
                    // adjust volume
                    adjustVolume(buffer: pointer, size: Int(bytesRead), volume: currentVolume)                        
                }
                // if .ao
                if PlayerPreferences.outputSoundLibrary == .ao {
                    if self.m_audioState.channels == 1 {
                        // Allocate a stereo buffer if necessary
                        let stereoBuffer = UnsafeMutablePointer<Int16>.allocate(capacity: Int(bytesRead) * 2)
                        let monoBuffer = bufferPointer.baseAddress!.assumingMemoryBound(to: Int16.self)
                        
                        defer {
                            stereoBuffer.deallocate()
                        }

                        for i in 0..<(bytesRead / 2) {
                            stereoBuffer[i * 2] = monoBuffer[i]
                            stereoBuffer[i * 2 + 1] = monoBuffer[i]
                        }                        
                        ao_play(self.m_audioState.aoState.aoDevice, stereoBuffer, UInt32(bytesRead * 2))                        
                    }
                    else {
                        // play audio through ao
                        let err: Int32 = ao_play(self.m_audioState.aoState.aoDevice, pointer, UInt32(bytesRead))
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
                            PlayerLog.ApplicationLog?.logError(title: "[Mp3AudioPlayer].playAsync()", text: msg)                        
                            // return
                            return
                        }
                    }
                }
                // else if .alsa
                else if PlayerPreferences.outputSoundLibrary == .alsa {
                    // calculate frames
                    let frames: snd_pcm_uframes_t = UInt(bytesRead) / 2 / UInt(self.m_audioState.alsaState.channels)                    
                    var writtenFrames: snd_pcm_sframes_t = 0
                    var totalFrames = frames
                    // while we still have frames to play
                    while totalFrames > 0 {
                        // play audio through alsa
                        writtenFrames = snd_pcm_writei(self.m_audioState.alsaState.pcmHandle, pointer, totalFrames)
                        // err return value error
                        if writtenFrames == -EPIPE {// EPIPE means an underrun occurred
                            // prepare pcm device for use
                            snd_pcm_prepare(self.m_audioState.alsaState.pcmHandle)
                        } 
                        // else error code instead of number of frames written
                        else if writtenFrames < 0 {
                            // create error message
                            let msg = "snd_pcm_writei failed with value: \(writtenFrames) = '\(renderAlsaError(error: Int32(writtenFrames)))'."
                            // log error
                            PlayerLog.ApplicationLog?.logError(title: "[Mp3AudioPlayer].playAsync()", text: msg)                        
                            // return
                            return                            
                        } 
                        else {
                            // decrease total frames to play with frames just written
                            totalFrames -= snd_pcm_uframes_t(writtenFrames)
                        }
                    }
                }
            }            
            // if we are !paused! and not stopping and not quitting
            while (self.m_isPaused && !self.m_stopFlag && !g_quit) {
                // sleep for 100 ms
                usleep(100_000)
            }
        }
    }
    /// 
    /// seeks playback from start to position (ms)
    /// 
    /// - Parameter position: ms from start
    func seekToPos(position: UInt64)
    {
        // guard valid position
        guard position <= self.duration else {
            // else error
            // ignore and return
            return
        }
        // set seek position
        self.m_seekPos = position
        // set m_doSeekToPos flag to true
        self.m_doSeekToPos = true
    }
    /// 
    /// Adjusts volume in the sample buffer to a factor 0.0-1.0
    ///     
    func adjustVolume(buffer: UnsafeMutablePointer<Int8>, size: Int, volume: Float) {
        // get sample count for 16 bit samples
        let sampleCount = size / MemoryLayout<Int16>.size
        // reinterpret buffer pointer to samples Int16 pointer from Int8 pointer
        let samples = buffer.withMemoryRebound(to: Int16.self, capacity: sampleCount) { $0 }
        // for each sample in buffer
        for i in 0..<sampleCount {
            // adjust sample
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
        // guard valid volume
        guard volume >= 0 && volume <= 1 else {
            // else error
            // ignore and return
            return
        }
        // guard valid crossfade time
        guard isCrossfadeTimeValid(seconds: Int(fadeDuration / 1000)) else {
            // else error
            // ignore and return
            return
        }
        // set crossfade volume target
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
        // set m_stopFlag flag to true
        self.m_stopFlag = true        
    }
    ///
    /// pauses playback if we are playing
    /// 
    func pause() {
        // set m_isPaused flag to true
        self.m_isPaused = true
    }
    ///
    /// resumes playback if we are playing.
    ///
    func resume() {
        // set m_isPaused flag to false
        self.m_isPaused = false
    }
    ///
    /// Gathers metadata.
    /// - Parameter path: file to gather metadata from.
    /// - Throws: CmpError
    /// - Returns: CmpMetadata
    /// 
    static func gatherMetadata(path: URL) throws -> CmpMetadata {
        // guard file type is expected .mp3
        guard path.path.lowercased().hasSuffix(".mp3") else {
            // else we have an error
            // create error message
            let msg = "[Mp3AudioPlayer].gatherMetadata(path:). Unknown file type. File: \(path.lastPathComponent)"
            // throw error
            throw CmpError(message: msg)
        }
        // create metadata, default values
        let metadata = CmpMetadata()
        // if create a handle with mpg123_new returnes valid handle
        guard let handle: OpaquePointer = mpg123_new(nil, nil) else {
            // else we have an invalid handle
            // create error message
            let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_new failed. File: \(path.lastPathComponent)"
            // throw error
            throw CmpError(message: msg)
        }
        // defer newly created handle
        // - by deleting it
        defer {
            // deleted the handle
            mpg123_delete(handle)                
        }
        // open and prepare to decode path file
        var err = mpg123_open(handle, path.path)
        // guard for no error
        guard err == 0 else {             
            // else we have an error
            // create error message
            let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_open failed with value: \(err) = '\(renderMpg123Error(error: err))'. File: \(path.lastPathComponent)"
            // throw error
            throw CmpError(message: msg)
        }      
        // defer newly opened file
        // - by closing handle
        defer {
            // closed the source after open
            mpg123_close(handle)
        }
        // scan through file so we can get proper length (duration)           
        err = mpg123_scan(handle)
        // guard for no error
        guard err == 0 else {                                                
            // else we have an error
            // create error message
            let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_scan failed with value: \(err) = '\(renderMpg123Error(error: err))'. File: \(path.lastPathComponent)"
            // throw error
            throw CmpError(message: msg)                
        }
        // get full length of file in frames
        let length  = mpg123_length(handle)
        // guard for positive length
        guard length > 0 else {
            // else we have an error
            // create error message
            let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_length failed with length: \(length). File: \(path.lastPathComponent)"                
            // throw error
            throw CmpError(message: msg)
        }
        // create rate variable
        var rate: CLong = 0
        // create channels variable
        var channels: Int32 = 0
        // create encoding variable
        var encoding: Int32 = 0
        // get current output format
        err = mpg123_getformat(handle, &rate, &channels, &encoding)            
        // guard for no error
        guard err == 0 else {
            // else we have an error
            // create error message
            let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_getformat failed with value: \(err) = '\(renderMpg123Error(error: err))'. File: \(path.lastPathComponent)"
            // throw error
            throw CmpError(message: msg)
        }
        // calculate duration in seconds
        let duration = Double(length) / Double(rate)
        // calculate and set duration (ms)
        metadata.duration = UInt64(duration * 1000)            
        // guard duration > 0
        guard duration > 0 else {            
            // else we have an error
            // create error message
            let msg = "[Mp3AudioPlayer].gatherMetadata(path:). Duration was 0. File: \(path.lastPathComponent)"
            // throw error
            throw CmpError(message: msg)
        }
        // query if there is metadata info
        let metaCheck = mpg123_meta_check(handle)
        guard metaCheck & MPG123_ID3 != 0 else {
            // else we have an error
            // create error message
            let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_meta_check failed with value: \(metaCheck). File: \(path.lastPathComponent)"
            // throw error
            throw CmpError(message: msg)
        }
        // create pointer to id3v1 metadata
        let id3v1Pointer: UnsafeMutablePointer<UnsafeMutablePointer<mpg123_id3v1>?>? = UnsafeMutablePointer.allocate(capacity: 1)
        // initialize pointer
        id3v1Pointer?.initialize(to: nil)
        // create pointer to id3v2 metadata
        let id3v2Pointer: UnsafeMutablePointer<UnsafeMutablePointer<mpg123_id3v2>?>? = UnsafeMutablePointer.allocate(capacity: 1)
        // initialize pointer
        id3v2Pointer?.initialize(to: nil)
        // defer id3v1 and id3v2 pointers
        defer {
            // deallocate pointer
            id3v1Pointer?.deallocate()
            // deallocate pointer
            id3v2Pointer?.deallocate()
        }
        // call the mpg123_id3 function to fill in the pointers
        err = mpg123_id3(handle, id3v1Pointer, id3v2Pointer)
        // guard mpg123_id3 return value success
        guard err == 0 else {                
            // else we have an error
            // create error message
            let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_id3 failed with value \(err). File: \(path.lastPathComponent)"
            // throw error
            throw CmpError(message: msg)
        }     
        // set bFoundTitle flag to false
        var bFoundTitle: Bool = false
        // set bFoundArtist flag to false
        var bFoundArtist: Bool = false
        // set bFoundAlbumName flag to false
        var bFoundAlbumName: Bool = false
        // set bFoundYear flag to false
        var bFoundYear: Bool = false
        // set bFoundGenre flag to false
        var bFoundGenre: Bool = false
        // if idrv2 pointer is valid
        if let id3v2 = id3v2Pointer?.pointee?.pointee {
            // access ID3v2 metadata fields safely
            // is id3v2 title pointer ok
            if id3v2.title?.pointee.p != nil {
                // yes get title
                let title = String(cString: id3v2.title.pointee.p)
                // if title has characters
                if title.count > 0 {
                    // set metadata title
                    metadata.title = title
                    // set bFoundTitle flag to true
                    bFoundTitle = true
                }
            }                        
            // is id3v2 artist pointer ok
            if id3v2.artist?.pointee.p != nil {
                // yes get artist
                let artist = String(cString: id3v2.artist.pointee.p)                            
                // if artist has characters
                if artist.count > 0 {
                    // set metadata artist
                    metadata.artist = artist
                    // set bFoundArtist flag to true
                    bFoundArtist = true
                }
            }
            // is id3v2 album pointer ok
            if id3v2.album?.pointee.p != nil {
                // yes get album
                let album = String(cString: id3v2.album.pointee.p)
                // if album has characters
                if album.count > 0 {
                    // set metadata albumName
                    metadata.albumName = album
                    // set bFoundAlbumName flag to true
                    bFoundAlbumName = true
                }
            }                        
            // is id3v2 year pointer ok
            if id3v2.year?.pointee.p != nil {
                // yes get year
                let year = String(cString: id3v2.year.pointee.p)
                // if year has characters
                if year.count > 0 {
                    // set metadata recordingYear
                    metadata.recordingYear = Int(year) ?? 0
                    // check year is valid
                    if metadata.recordingYear > 0 {
                        // set bFoundYear flag to true
                        bFoundYear = true
                    }
                }
            }                        
            // is id3v2 genre pointer ok
            if id3v2.genre?.pointee.p != nil {
                // yes get genre
                let genre = String(cString: id3v2.genre.pointee.p)
                // if genre has characters
                if genre.count > 0 {
                    // set metadata genre
                    metadata.genre = extractMetadataGenre(text: genre)                                
                    // set bFoundGenre flag to true
                    bFoundGenre = true
                }
            }                                                                   
            // Loop through the text fields to find the track number
            for i in 0..<id3v2.texts {
                // get current text item
                let textItem = id3v2.text[i]
                // get item value
                let text = String(cString: textItem.text.p)
                // get item id
                let id = "\(Character(UnicodeScalar(UInt32(textItem.id.0))!))\(Character(UnicodeScalar(UInt32(textItem.id.1))!))\(Character(UnicodeScalar(UInt32(textItem.id.2))!))\(Character(UnicodeScalar(UInt32(textItem.id.3))!))"
                // check id = track no
                if id == "TRCK" {
                    // set metadata track no
                    let trackNo = Int(text) ?? 0
                    // check for valid track no
                    if trackNo > 0 {
                        metadata.trackNo = trackNo
                    }
                }  
                // if we have not found year
                if !bFoundYear {            
                    // check for year                                                                 
                    if id == "TYER" || id == "TORY" {                        
                        // get year
                        let recordingYear = extractMetadataYear(text: text)
                        // is year valid
                        if recordingYear > 0 {
                            metadata.recordingYear = recordingYear
                            bFoundYear = true               
                        }                     
                    }
                }
            }                                                
        } 
        // if id3v1 pointer is valid
        if let id3v1 = id3v1Pointer?.pointee?.pointee {
            // ID3v1 fallback
            // if we have not found artist                 
            if !bFoundArtist {
                // get artist
                let artist = withUnsafePointer(to: id3v1.artist) { ptr in
                    return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self), encoding: .isoLatin1)         
                }
                // set artist to metadata
                metadata.artist = artist ?? g_metadataNotFoundName
            }                         
            // if we have not found title
            if !bFoundTitle {
                // get title
                let title = withUnsafePointer(to: id3v1.title) { ptr in
                    return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self), encoding: .isoLatin1)         
                }
                // set title to metadata
                metadata.title = title ?? g_metadataNotFoundName                            
            }
            // if we have not found album name
            if !bFoundAlbumName {
                // get album
                let album = withUnsafePointer(to: id3v1.album) { ptr in
                    return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self), encoding: .isoLatin1)         
                }
                // set albumName to metadata
                metadata.albumName = album ?? g_metadataNotFoundName                            
            }
            // if we have not found year
            if !bFoundYear {
                // get year
                let year = withUnsafePointer(to: id3v1.year) { ptr in
                    return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self), encoding: .isoLatin1)         
                }
                // if year is valid
                if year != nil {    
                    // set recordingYear to metadata
                    metadata.recordingYear = extractMetadataYear(text: year!)
                }
            }                        
            // if we have not found genre
            if !bFoundGenre {
                // set genre to metadata
                metadata.genre = convertId3V1GenreIndexToName(index: id3v1.genre)
            }                        
        }                    
        // return metadata
        return metadata                                               
    }
}// AudioPlayer