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
import Cmpg123
import Cao
import Casound

///
/// Mp3 Audio state.
///
internal struct Mp3AudioState {    
    var aoDevice: OpaquePointer? = nil
    var aoFormat = ao_sample_format()
    var alsaState: AlsaState = AlsaState()
}

//
// Represents CMPlayer AudioPlayer.
//
internal class Mp3AudioPlayer {
    ///
    /// private constants
    /// 
    private let filePath: URL    
    ///
    /// private variables
    /// 
    private var mpg123Handle: OpaquePointer?
    private var m_length: off_t = 0
    private var m_rate: CLong = 0
    private let audioQueue = DispatchQueue(label: "dqueue.cmp.linux.mp3-audio-player", qos: .background)
    private var m_stopFlag: Bool = false
    private var m_isPlaying: Bool = false    
    private var m_isPaused: Bool = false
    private var m_hasPlayed: Bool = false
    private var m_timeElapsed: UInt64 = 0
    private var m_duration: UInt64 = 0
    private var m_channels: Int32 = 2
    private var m_targetFadeVolume: Float = 1
    private var m_targetFadeDuration: UInt64 = 0
    private var m_enableCrossfade: Bool = false
    private var m_seekPos: UInt64 = 0
    private var m_doSeekToPos: Bool = false
    private var m_audioState: Mp3AudioState = Mp3AudioState()
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
            let msg = "[Mp3AudioPlayer].play(). Already playing a file."            
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
        self.m_length = mpg123_length(self.mpg123Handle)
        // guard length is > 0
        guard self.m_length > 0 else {
            // else error
            let msg = "[Mp3AudioPlayer].play(). mpg123_length failed with value: \(self.m_length)"
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
        self.m_rate = rate
        // set self.m_channels to channels
        self.m_channels = channels
        // calculate duration in seconds
        let duration = Double(self.m_length) / Double(self.m_rate)
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
        mpg123_format_none(mpg123Handle)
        // set audio format 
        mpg123_format(mpg123Handle, 44100, 2, encoding);//rate, channels, encoding)
        // get default libao playback driver id
        let defaultDriver = ao_default_driver_id()
        // Set up libao format        
        // set bits per sample
        self.m_audioState.aoFormat.bits = 16
        // set channels, 2 = stereo
        self.m_audioState.aoFormat.channels = 2
        // set sample rate
        self.m_audioState.aoFormat.rate = 44100
        // set byte format
        self.m_audioState.aoFormat.byte_format = AO_FMT_NATIVE
        // set matrix
        self.m_audioState.aoFormat.matrix = nil
        // Set up libasound format        
        // set channels, 2 = stereo
        self.m_audioState.alsaState.channels = 2
        // set sample rate
        self.m_audioState.alsaState.sampleRate = 44100 
        // set buffer size
        self.m_audioState.alsaState.bufferSize = 1024 
        // if output sound library is .ao
        if PlayerPreferences.outputSoundLibrary == .ao {
            self.m_audioState.aoDevice = ao_open_live(defaultDriver, &self.m_audioState.aoFormat, nil)
            if self.m_audioState.aoDevice == nil {
                let msg = "[Mp3AudioPlayer].play(). ao_open_live failed. Couldn't open audio device"            

                mpg123_close(self.mpg123Handle)
                mpg123_delete(self.mpg123Handle)
                self.mpg123Handle = nil
                self.m_isPlaying = false                

                throw CmpError(message:msg)
            }
        }
        // else if output sound library is .alsa
        else if PlayerPreferences.outputSoundLibrary == .alsa {
            var err = snd_pcm_open(&self.m_audioState.alsaState.pcmHandle, self.m_audioState.alsaState.pcmDeviceName, SND_PCM_STREAM_PLAYBACK, 0)
            guard err >= 0 else {
                let msg = "[Mp3AudioPlayer].play(). alsa. snd_pcm_open failed with value: \(err) = '\(renderAlsaError(error: err))'. Failed to open ALSA PCM device."
                mpg123_close(self.mpg123Handle)
                mpg123_delete(self.mpg123Handle)
                self.mpg123Handle = nil
                self.m_isPlaying = false                
                
                throw CmpError(message: msg)
            }  
            err = snd_pcm_set_params(self.m_audioState.alsaState.pcmHandle, SND_PCM_FORMAT_S16_LE, SND_PCM_ACCESS_RW_INTERLEAVED, self.m_audioState.alsaState.channels, self.m_audioState.alsaState.sampleRate, 1, 500000)
            guard err >= 0 else {
                let msg = "[Mp3AudioPlayer].play(). alsa. snd_pcm_set_params failed with value: \(err) = '\(renderAlsaError(error: err))'"
                snd_pcm_close(self.m_audioState.alsaState.pcmHandle)
                mpg123_close(self.mpg123Handle)
                mpg123_delete(self.mpg123Handle)                
                self.mpg123Handle = nil
                self.m_isPlaying = false                
                
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
                ao_close(self.m_audioState.aoDevice)            
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
        // buffer size for audio output
        let bufferSize = mpg123_outblock(mpg123Handle)
        // buffer of bufferSize
        var buffer = [UInt8](repeating: 0, count: bufferSize)
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
                let newPos: off_t = off_t(seconds) * self.m_rate
                // seek to desired sample offset
                let offset: off_t = mpg123_seek(self.mpg123Handle, newPos, SEEK_SET)
                // check for success
                if offset >= 0 {
                    // success, calculate seconds
                    let offsetSeconds: Double = Double(offset) / Double(self.m_rate)
                    // calculate ms
                    let offsetMs: UInt64 = UInt64(offsetSeconds) * 1000
                    // set m_timeElapsed
                    self.m_timeElapsed = offsetMs
                }
            }
            // read from stream and decode
            let err = mpg123_read(self.mpg123Handle, &buffer, bufferSize, &bytesRead)
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
            let totalCurrentBytesPerChannel = bytesRead / Int(self.m_channels)
            // calculate current duration of read samples
            let currentDuration = Double(totalCurrentBytesPerChannel) / Double(self.m_rate)
            // update time elapsed
            self.m_timeElapsed += UInt64(currentDuration * Double(1000/self.m_channels))
            // calculate time left
            let timeLeft: UInt64 = (self.duration >= self.m_timeElapsed) ? self.duration - self.m_timeElapsed : self.duration
            // if time left is inside fade duration
            if timeLeft > 0 && timeLeft <= self.m_targetFadeDuration {
                // set timeToStartCrossfade flag to true
                timeToStartCrossfade = true
                // calculate current volume
                currentVolume = Float(Float(timeLeft)/Float(self.m_targetFadeDuration))                    
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
                    // play audio through ao
                    ao_play(self.m_audioState.aoDevice, pointer, UInt32(bytesRead))
                }
                // else if .alsa
                else if PlayerPreferences.outputSoundLibrary == .alsa {
                    // calculate frames
                    let frames = Int(bytesRead) / 2 / Int(self.m_audioState.alsaState.channels)
                    // play audio through alsa
                    snd_pcm_writei(self.m_audioState.alsaState.pcmHandle, pointer, snd_pcm_uframes_t(frames))
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
        if path.path.lowercased().hasSuffix(".mp3") {
            let metadata = CmpMetadata()
           
            //print("URL: \(self.fileURL!.path)")
            guard let handle = mpg123_new(nil, nil) else {
                let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_new failed. File: \(path.lastPathComponent)"
                throw CmpError(message: msg)
            }

            defer {
                // deleted the handle
                mpg123_delete(handle)                
            }

            var err = mpg123_open(handle, path.path)
            guard err == 0 else {                
                let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_open failed with value: \(err) = '\(renderMpg123Error(error: err))'. File: \(path.lastPathComponent)"
                throw CmpError(message: msg)
            }      

            defer {
                // closed the source after open
                mpg123_close(handle)
            }

            //
            // find duration
            //       
            err = mpg123_scan(handle)
            if  err != 0 {                                                
                let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_scan failed with value: \(err) = '\(renderMpg123Error(error: err))'. File: \(path.lastPathComponent)"
                throw CmpError(message: msg)                
            }

            let length  = mpg123_length(handle)
            if length  <= 0 {                
                let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_length failed with length: \(length). File: \(path.lastPathComponent)"                
                throw CmpError(message: msg)
            }
            
            // Get the rate and channels to calculate duration
            var rate: CLong = 0
            var channels: Int32 = 0
            var encoding: Int32 = 0
            err = mpg123_getformat(handle, &rate, &channels, &encoding)            
            if err != 0 {
                let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_getformat failed with value: \(err) = '\(renderMpg123Error(error: err))'. File: \(path.lastPathComponent)"
                throw CmpError(message: msg)
            }

            // Calculate duration
            // Scan the file to build an accurate index of frames
            
            let duration = Double(length) / Double(rate)
            metadata.duration = UInt64(duration * 1000)            

            // Ensure positive duration
            guard duration > 0 else {            
                let msg = "[Mp3AudioPlayer].gatherMetadata(path:). Duration was 0. File: \(path.lastPathComponent)"
                throw CmpError(message: msg)
            }
            
            let metaCheck = mpg123_meta_check(handle)
            if metaCheck & MPG123_ID3 != 0 {
                let id3v1Pointer: UnsafeMutablePointer<UnsafeMutablePointer<mpg123_id3v1>?>? = UnsafeMutablePointer.allocate(capacity: 1)
                id3v1Pointer?.initialize(to: nil)
                
                let id3v2Pointer: UnsafeMutablePointer<UnsafeMutablePointer<mpg123_id3v2>?>? = UnsafeMutablePointer.allocate(capacity: 1)
                id3v2Pointer?.initialize(to: nil)
                
                defer {
                    id3v1Pointer?.deallocate()
                    id3v2Pointer?.deallocate()
                }

                // Call the mpg123_id3 function to fill in the pointers
                let err = mpg123_id3(handle, id3v1Pointer, id3v2Pointer)
                if err == 0 {
                    var bFoundTitle: Bool = false
                    var bFoundArtist: Bool = false
                    var bFoundAlbumName: Bool = false
                    var bFoundYear: Bool = false
                    var bFoundGenre: Bool = false
                    if let id3v2 = id3v2Pointer?.pointee?.pointee {
                        // Access ID3v2 metadata fields safely
                        if id3v2.title?.pointee.p != nil {
                            let title = String(cString: id3v2.title.pointee.p)
                            if title.count > 0 {
                                metadata.title = title
                                bFoundTitle = true
                            }
                        }                        
                        
                        if id3v2.artist?.pointee.p != nil {
                            let artist = String(cString: id3v2.artist.pointee.p)                            
                            if artist.count > 0 {
                                metadata.artist = artist
                                bFoundArtist = true
                            }
                        }
                                                
                        if id3v2.album?.pointee.p != nil {
                            let album = String(cString: id3v2.album.pointee.p)
                            if album.count > 0 {
                                metadata.albumName = album
                                bFoundAlbumName = true
                            }
                        }                        

                        if id3v2.year?.pointee.p != nil {
                            let year = String(cString: id3v2.year.pointee.p)
                            if year.count > 0 {
                                metadata.recordingYear = Int(year) ?? 0
                                if metadata.recordingYear != 0 {
                                    bFoundYear = true
                                }
                            }
                        }                        

                        if id3v2.genre?.pointee.p != nil {
                            let genre = String(cString: id3v2.genre.pointee.p)
                            if genre.count > 0 {
                                metadata.genre = extractMetadataGenre(text: genre)                                
                                bFoundGenre = true
                            }
                        }                                                                   

                        // Loop through the text fields to find the track number
                        for i in 0..<id3v2.texts {                            
                            let textItem = id3v2.text[i]
                            let text = String(cString: textItem.text.p)
                            let id = "\(Character(UnicodeScalar(UInt32(textItem.id.0))!))\(Character(UnicodeScalar(UInt32(textItem.id.1))!))\(Character(UnicodeScalar(UInt32(textItem.id.2))!))\(Character(UnicodeScalar(UInt32(textItem.id.3))!))"
                            if id == "TRCK" {
                                metadata.trackNo = Int(text) ?? 0
                            }  
                            if !bFoundYear {                                                                             
                                if id == "TYER" || id == "TORY" {                                    
                                    metadata.recordingYear = extractMetadataYear(text: text)
                                    if metadata.recordingYear != 0 {                                   
                                        bFoundYear = true               
                                    }                     
                                }
                            }
                        }                                                
                    } 

                    if let id3v1 = id3v1Pointer?.pointee?.pointee {
                        // ID3v1 fallback                        
                        if !bFoundArtist {
                            let artist = withUnsafePointer(to: id3v1.artist) { ptr in
                                return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self), encoding: .isoLatin1)         
                            }
                            metadata.artist = artist ?? g_metadataNotFoundName
                        }                         
                        if !bFoundTitle {
                            let title = withUnsafePointer(to: id3v1.title) { ptr in
                                return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self), encoding: .isoLatin1)         
                            }
                            metadata.title = title ?? g_metadataNotFoundName                            
                        }
                        if !bFoundAlbumName {
                            let album = withUnsafePointer(to: id3v1.album) { ptr in
                                return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self), encoding: .isoLatin1)         
                            }
                            metadata.albumName = album ?? g_metadataNotFoundName                            
                        }
                        if !bFoundYear {
                            let year = withUnsafePointer(to: id3v1.year) { ptr in
                                return String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self), encoding: .isoLatin1)         
                            }                                                
                            if year != nil {    
                                metadata.recordingYear = extractMetadataYear(text: year!)
                            }
                        }                        
                        if !bFoundGenre {
                            metadata.genre = convertId3V1GenreIndexToName(index: id3v1.genre)
                        }
                    }

                    //
                    // ensure valid values
                    //
                    if metadata.trackNo < 0 {
                        metadata.trackNo = 0
                    }

                    // Log we found metadatda
                    // this is a preformance issue
                    //PlayerLog.ApplicationLog?.logInformation(title: "[Mp3AudioPlayer].gatherMetadata()", text: "Found metadata for: \(path.path)")
                    
                    //
                    // return metadata
                    //
                    return metadata
                } 
                else {
                    let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_id3 failed with value \(err). File: \(path.lastPathComponent)"
                    throw CmpError(message: msg)
                }                
            }// mpg123_meta_check            
            let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_meta_check failed with value: \(metaCheck). File: \(path.lastPathComponent)"
            throw CmpError(message: msg)
        }// is .mp3
        
        let msg = "[Mp3AudioPlayer].gatherMetadata(path:). Unknown file type. File: \(path.lastPathComponent)"
        throw CmpError(message: msg)
    }    
}// AudioPlayer