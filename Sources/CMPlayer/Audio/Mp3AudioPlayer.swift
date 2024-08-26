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
/// Audio state variables.
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
        // if we are already playing, return
        if (self.m_isPlaying) {
            return;
        }
        
        // if we have paused playback, then resume on play again
        if (self.m_isPaused) {
            self.resume()
            return;
        }

        // set flags
        self.m_hasPlayed = false
        self.m_stopFlag = false

        // make sure mpg123Handle is not already set
        guard mpg123Handle == nil else {            
            let msg = "[Mp3AudioPlayer].play(). Already playing a file."            
            throw CmpError(message: msg)
        }        

        // Initialize mpg123 handle
        var err: Int32 = 0
        self.mpg123Handle = mpg123_new(nil, &err)
        guard err == 0 else { // MPG123_OK
            let msg = "[Mp3AudioPlayer].play(). mpg123_new failed with value: \(err) = '\(renderMpg123Error(error: err))'. Failed to create mpg123 handle"
            throw CmpError(message: msg)
        }

        // Open the file
        err = mpg123_open(self.mpg123Handle, self.filePath.path)
        if err != 0 { // MPG123_OK
            let msg = "[Mp3AudioPlayer].play(). mpg123_open failed with value: \(err) = '\(renderMpg123Error(error: err))'. Failed to open MP3 file: \(self.filePath.lastPathComponent)"

            mpg123_delete(self.mpg123Handle)
            self.mpg123Handle = nil

            throw CmpError(message: msg)
        }

        //
        // find duration
        //                      
        err = mpg123_scan(self.mpg123Handle)
        if err != 0 {                
            let msg = "[Mp3AudioPlayer].play(). mpg123_scan failed with value: \(err) = '\(renderMpg123Error(error: err))'. File: \(self.filePath.path.lastPathComponent)"
            mpg123_close(self.mpg123Handle)
            mpg123_delete(self.mpg123Handle)            
            throw CmpError(message: msg)                
        }

        self.m_length = mpg123_length(self.mpg123Handle)
        if self.m_length <= 0 {
            let msg = "[Mp3AudioPlayer].play(). mpg123_length failed with value: \(self.m_length)"
            mpg123_close(self.mpg123Handle)
            mpg123_delete(self.mpg123Handle)
            throw CmpError(message: msg)
        }

        // Get the rate and channels to calculate duration
        var rate: CLong = 0
        var channels: Int32 = 0
        var encoding: Int32 = 0

        err = mpg123_getformat(mpg123Handle, &rate, &channels, &encoding)
        if err != 0 { // MPG123_OK
            let msg = "[Mp3AudioPlayer].play(). mpg123_getformat failed with value: \(err) = '\(renderMpg123Error(error: err))'. Failed to get MP3 format."

            mpg123_close(self.mpg123Handle)
            mpg123_delete(self.mpg123Handle)
            self.mpg123Handle = nil
            
            throw CmpError(message: msg)
        }        

        self.m_rate = rate
        self.m_channels = channels

        // Calculate duration in seconds
        let duration = Double(self.m_length) / Double(self.m_rate)
        self.m_duration = UInt64(duration * 1000)
        
        guard self.m_duration > 0 else {
            let msg = "[Mp3AudioPlayer].play(). Duration was invalid with value: \(self.m_duration)"                        
            throw CmpError(message: msg)
        }


        // Ensure the output format doesn't change
        mpg123_format_none(mpg123Handle)
        mpg123_format(mpg123Handle, rate, channels, encoding)

        // get default libao playback driver
        let defaultDriver = ao_default_driver_id()

        // Set up libao format        
        self.m_audioState.aoFormat.bits = 16
        self.m_audioState.aoFormat.channels = channels
        self.m_audioState.aoFormat.rate = Int32(rate)
        self.m_audioState.aoFormat.byte_format = AO_FMT_NATIVE
        self.m_audioState.aoFormat.matrix = nil
        // Set up libasound format        
        self.m_audioState.alsaState.channels = 2
        self.m_audioState.alsaState.sampleRate = 44100 
        self.m_audioState.alsaState.bufferSize = 1024 

        // open for playing
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
        else {
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
                mpg123_close(self.mpg123Handle)
                mpg123_delete(self.mpg123Handle)
                snd_pcm_close(self.m_audioState.alsaState.pcmHandle)
                self.mpg123Handle = nil
                self.m_isPlaying = false                
                
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
    /// - Parameter device: mpg123 handle
    private func playAsync() {
        // set flags
        self.m_isPlaying = true

        // log we have started to play
        PlayerLog.ApplicationLog?.logInformation(title: "[Mp3AudioPlayer].playAsync()", text: "Started playing file: \(self.filePath.lastPathComponent)")
        
        // make sure we clean up
        defer {                  
            if PlayerPreferences.outputSoundLibrary == .ao {                 
                ao_close(self.m_audioState.aoDevice)            
            }
            else if PlayerPreferences.outputSoundLibrary == .alsa {
                snd_pcm_drain(self.m_audioState.alsaState.pcmHandle)
                snd_pcm_close(self.m_audioState.alsaState.pcmHandle)
            }
            mpg123_close(self.mpg123Handle)
            mpg123_delete(self.mpg123Handle)
            self.m_timeElapsed = self.duration
            self.mpg123Handle = nil
            self.m_hasPlayed = true
            self.m_isPlaying = false
            self.m_isPaused = false   
            self.m_stopFlag = true                 
        }

        // Buffer for audio output
        let bufferSize = mpg123_outblock(mpg123Handle)
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var done: Int = 0
        var timeToStartCrossfade: Bool = false
        var currentVolume: Float = 1

        self.m_timeElapsed = 0

        // Decode and play the file        
        while !self.m_stopFlag && !g_quit {
            if (self.m_doSeekToPos) {
                self.m_doSeekToPos = false
                
                let seconds: UInt64 = (self.duration - self.m_seekPos) / 1000
                let newPos: off_t = off_t(seconds) * self.m_rate
                let offset: off_t = mpg123_seek(self.mpg123Handle, newPos, SEEK_SET)
                if offset >= 0 {
                    let offsetSeconds: Double = Double(offset) / Double(self.m_rate)
                    let offsetMs: UInt64 = UInt64(offsetSeconds) * 1000
                    self.m_timeElapsed = offsetMs
                }
            }
            let err = mpg123_read(self.mpg123Handle, &buffer, bufferSize, &done)
            if err == -12 { // MPG123_DONE
                return
            }
            if (err != 0) { // MPG123_OK
                PlayerLog.ApplicationLog?.logError(title: "[Mp3AudioPlayer].playAsync()", text: "mpg123_read failed with value: \(err) = '\(renderMpg123Error(error: err))'. File: \(self.filePath.lastPathComponent)")
                return
            }
            if done <= 0 {                 
                return;
            }

            // Update time elapsed                
            let totalPerChannel = done / Int(self.m_channels)
            let currentDuration = Double(totalPerChannel) / Double(self.m_rate)
            self.m_timeElapsed += UInt64(currentDuration * Double(1000/self.m_channels))

            // set crossfade volume
            let timeLeft: UInt64 = (self.duration >= self.m_timeElapsed) ? self.duration - self.m_timeElapsed : self.duration
            if timeLeft > 0 && timeLeft <= self.m_targetFadeDuration {
                timeToStartCrossfade = true

                currentVolume = Float(Float(timeLeft)/Float(self.m_targetFadeDuration))                    
            }            

            // check buffer
            guard !buffer.isEmpty else {
                let msg = "Buffer is empty"
                PlayerLog.ApplicationLog?.logError(title: "[Mp3AudioPlayer].playAsync()", text: msg)
                return
            }

            // play samples
            buffer.withUnsafeMutableBytes { bufferPointer in
                let pointer = bufferPointer.baseAddress!.assumingMemoryBound(to: Int8.self)

                // adjust crossfade volume
                if self.m_enableCrossfade && timeToStartCrossfade {
                    adjustVolume(buffer: pointer, size: Int(done), volume: currentVolume)                        
                }

                // play audio samples
                if PlayerPreferences.outputSoundLibrary == .ao {
                    ao_play(self.m_audioState.aoDevice, pointer, UInt32(done))
                }
                else if PlayerPreferences.outputSoundLibrary == .alsa {
                    let frames = Int(done) / 2 / Int(self.m_audioState.alsaState.channels)
                    snd_pcm_writei(self.m_audioState.alsaState.pcmHandle, pointer, snd_pcm_uframes_t(frames))
                }
            }            

            while (self.m_isPaused && !self.m_stopFlag && !g_quit) {
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

            let renderMpg123Error: (Int32) -> String = { error in
                if let errorMessage = mpg123_plain_strerror(error) {        
                    return "\(String(cString: errorMessage))"
                }
                return ""
            }                


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
                let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_open failed with value: \(err) = '\(renderMpg123Error(err))'. File: \(path.lastPathComponent)"
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
                let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_scan failed with value: \(err) = '\(renderMpg123Error(err))'. File: \(path.lastPathComponent)"
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
                let msg = "[Mp3AudioPlayer].gatherMetadata(path:). mpg123_getformat failed with value: \(err) = '\(renderMpg123Error(err))'. File: \(path.lastPathComponent)"
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
                                metadata.trackNo = Int(text) ?? -1
                            }                                                                               
                            if id == "TYER" || id == "TORY" {
                                if metadata.recordingYear == 0 {
                                    metadata.recordingYear = extractMetadataYear(text: text)
                                    bFoundYear = true
                                }
                            }
                        }                                                
                    } 

                    if let id3v1 = id3v1Pointer?.pointee?.pointee {
                        // ID3v1 fallback                        
                        if !bFoundTitle {
                            let title = String(cString: withUnsafePointer(to: id3v1.title) {
                                UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                            })
                            metadata.title = title                            
                        }
                        if !bFoundArtist {
                            let artist = String(cString: withUnsafePointer(to: id3v1.artist) {
                                UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                            })
                            metadata.artist = artist
                        }
                        if !bFoundAlbumName {
                            let album = String(cString: withUnsafePointer(to: id3v1.album) {
                                UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                            })
                            metadata.albumName = album
                        }
                        if !bFoundYear {
                            let year = String(cString: withUnsafePointer(to: id3v1.year)  {
                                UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                            })                            
                            metadata.recordingYear = extractMetadataYear(text: year)
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
    /// 
    /// - Parameter error: 
    /// - Returns: 
    func renderMpg123Error(error: Int32) -> String {
        if let errorMessage = mpg123_plain_strerror(error) {        
            return "\(String(cString: errorMessage))"
        }        
        return ""
    }
    /// 
    /// Renders ALSA error.
    /// - Parameter error: 
    /// - Returns: 
    func renderAlsaError(error: Int32) -> String {
        if let errorMessage = snd_strerror(error) {        
            return "\(String(cString: errorMessage))"
        }
        return ""
    }
}// AudioPlayer