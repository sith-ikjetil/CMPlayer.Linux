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
import Cmpg123
import Cao

//
// Represents CMPlayer AudioPlayer.
//
internal class Mp3AudioPlayer {
    private let filePath: URL    
    private var mpg123Handle: OpaquePointer?
    private var m_length: off_t = 0
    private var m_rate: CLong = 0
    private let audioQueue = DispatchQueue(label: "audioQueue", qos: .background)
    private var m_stopFlag: Bool = false
    private var m_isPlaying = false
    private var m_isPaused = false
    private var m_timeElapsed: UInt64 = 0
    private var m_duration: UInt64 = 0
    private var m_channels: Int32 = 2
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

        // set flags
        self.m_stopFlag = false

        // make sure mpg123Handle is not already set
        guard mpg123Handle == nil else {            
            PlayerLog.ApplicationLog?.logWarning(title: "[Mp3AudioPlayer].play()", text: "Already playing a file")                
            throw AudioPlayerError.AlreadyPlaying
        }        

        // Initialize mpg123 handle
        var err: Int32 = 0
        self.mpg123Handle = mpg123_new(nil, &err)
        guard err == 0 else { // MPG123_OK
            PlayerLog.ApplicationLog?.logWarning(title: "[Mp3AudioPlayer].play()", text: "Failed to create mpg123 handle")    
            throw AudioPlayerError.MpgSoundLibrary
        }

        // Open the file
        if mpg123_open(self.mpg123Handle, self.filePath.path) != 0 { // MPG123_OK
            PlayerLog.ApplicationLog?.logWarning(title: "[Mp3AudioPlayer].play()", text: "Failed to open MP3 file")

            mpg123_delete(self.mpg123Handle)
            self.mpg123Handle = nil
            
            throw AudioPlayerError.MpgSoundLibrary
        }

        //
        // find duration
        //                      
        self.m_length = mpg123_length(self.mpg123Handle)
        if self.m_length <= 0 {
            PlayerLog.ApplicationLog?.logWarning(title: "[SongEntry].init(path:songNo:)", text: "mpg123_length invalid with value: \(self.m_length)")
            throw AudioPlayerError.MpgSoundLibrary
        }

        // Set the output format (PCM)
        var rate: CLong = 0
        var channels: Int32 = 0
        var encoding: Int32 = 0

        if mpg123_getformat(mpg123Handle, &rate, &channels, &encoding) != 0 { // MPG123_OK
            PlayerLog.ApplicationLog?.logWarning(title: "[Mp3AudioPlayer].play()", text: "Failed to get MP3 format")

            mpg123_close(self.mpg123Handle)
            mpg123_delete(self.mpg123Handle)
            self.mpg123Handle = nil
            
            throw AudioPlayerError.MpgSoundLibrary
        }        

        self.m_rate = rate
        self.m_channels = channels

        // Calculate duration in seconds
        let duration = Double(self.m_length) / Double(self.m_rate)
        self.m_duration = UInt64(duration * 1000)
        
        guard self.m_duration > 0 else {
            PlayerLog.ApplicationLog?.logWarning(title: "[SongEntry].init(path:songNo:)", text: "Duration was invalid with value: \(self.m_duration)")
            throw SongEntryError.DurationIsZero
        }


        // Ensure the output format doesn't change
        mpg123_format_none(mpg123Handle)
        mpg123_format(mpg123Handle, rate, channels, encoding)

        // get default libao playback driver
        let defaultDriver = ao_default_driver_id()

        // Set the output format
        var format = ao_sample_format()
        format.bits = 16
        format.channels = channels
        format.rate = Int32(rate)
        format.byte_format = AO_FMT_NATIVE
        format.matrix = nil

        // open for playing
        guard let device = ao_open_live(defaultDriver, &format, nil) else {
            PlayerLog.ApplicationLog?.logWarning(title: "[Mp3AudioPlayer].play()", text: "Couldn't open audio device")

            mpg123_close(self.mpg123Handle)
            mpg123_delete(self.mpg123Handle)
            self.mpg123Handle = nil
            
            throw AudioPlayerError.AoSoundLibrary
        }

        self.audioQueue.async { [weak self] in
            self?.playAsync(device: device)
        }
    }

    private func playAsync(device: OpaquePointer?) {
        // set flags
        self.m_isPlaying = true

        // log we have started to play
        PlayerLog.ApplicationLog?.logInformation(title: "[Mp3AudioPlayer].playAsync()", text: "Started playing \(self.filePath.lastPathComponent)")        
        
        // make sure we clean up
        defer {            
            ao_close(device)
            mpg123_close(self.mpg123Handle)
            mpg123_delete(self.mpg123Handle)
            self.mpg123Handle = nil
            self.m_isPlaying = false
            self.m_isPaused = false            
        }

        // Buffer for audio output
        let bufferSize = mpg123_outblock(mpg123Handle)
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var done: Int = 0
        var total: off_t = 0

        // Decode and play the file        
        while !self.m_stopFlag {
            let err = mpg123_read(self.mpg123Handle, &buffer, bufferSize, &done)
            if err == -12 { // MPG123_DONE
                break;
            }
            if (err != 0) { // MPG123_OK
                PlayerLog.ApplicationLog?.logWarning(title: "[Mp3AudioPlayer].playInBackground()", text: "mpg123_read return failure code: \(err)")
                break;
            }
            if (done > 0) {
                // Update time elapsed
                total += done
                let totalPerChannel = total / Int(self.m_channels)
                let currentDuration = Double(totalPerChannel) / Double(self.m_rate)
                self.m_timeElapsed = UInt64(currentDuration * Double(1000/self.m_channels))

                // play samples
                buffer.withUnsafeMutableBytes { bufferPointer in
                    let pointer = bufferPointer.baseAddress!.assumingMemoryBound(to: Int8.self)
                    ao_play(device, pointer, UInt32(done))
                }
            }
            while (self.m_isPaused && !self.m_stopFlag) {
                usleep(100_000)
            }
        }
    }

    func stop() {
        self.m_stopFlag = true
    }

    func pause() {
        self.m_isPaused = true
    }

    func resume() {
        self.m_isPaused = false
    }

    static func gatherMetadata(path: URL?) throws -> CmpMetadata {
        if path!.path.lowercased().hasSuffix(".mp3") {
            let metadata = CmpMetadata()

            //print("URL: \(self.fileURL!.path)")
            guard let handle = mpg123_new(nil, nil) else {
                PlayerLog.ApplicationLog?.logWarning(title: "[Mp3AudioPlayer].gatherMetadata(path:)", text: "mpg123_new failed")
                throw AudioPlayerError.MpgSoundLibrary
            }

            defer {                
                mpg123_close(handle);
            }
            
            guard mpg123_open(handle, path!.path) == 0 else {
                PlayerLog.ApplicationLog?.logWarning(title: "[Mp3AudioPlayer].gatherMetadata(path:)", text: "mpg123_open failed for URL: \(path!.path)")
                throw AudioPlayerError.MpgSoundLibrary
            }      

            //
            // find duration
            //              
            var length: off_t = 0
            length = mpg123_length(handle)
            if length <= 0 {
                PlayerLog.ApplicationLog?.logWarning(title: "[Mp3AudioPlayer].gatherMetadata(path:)", text: "mpg123_length failed with value: \(length)")
                throw AudioPlayerError.MpgSoundLibrary
            }
            
            // Get the rate and channels to calculate duration
            var rate: CLong = 0
            var channels: Int32 = 0
            var encoding: Int32 = 0
            mpg123_getformat(handle, &rate, &channels, &encoding)
            
            // Calculate duration in seconds
            let duration = Double(length) / Double(rate)
            metadata.duration = UInt64(duration * 1000)
            
            // Ensure positive duration
            guard duration > 0 else {
                PlayerLog.ApplicationLog?.logWarning(title: "[Mp3AudioPlayer].gatherMetadata(path:)", text: "Duration was 0. File: \(path!.path)")
                throw SongEntryError.DurationIsZero
            }

            //print("mpg123_metacheck")
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
                if mpg123_id3(handle, id3v1Pointer, id3v2Pointer) == 0 {                    
                    if let id3v2 = id3v2Pointer?.pointee?.pointee {
                        // Access ID3v2 metadata fields safely
                        if id3v2.title?.pointee.p != nil {
                            let title = String(cString: id3v2.title.pointee.p)
                            metadata.title = title
                        }
                        
                        if id3v2.artist?.pointee.p != nil {
                            let artist = String(cString: id3v2.artist.pointee.p)
                            metadata.artist = artist
                        }
                        
                        if id3v2.album?.pointee.p != nil {
                            let album = String(cString: id3v2.album.pointee.p)
                            metadata.albumName = album
                        }

                        if id3v2.year?.pointee.p != nil {
                            let year = String(cString: id3v2.year.pointee.p)
                            metadata.recordingYear = Int(year) ?? -1
                        }

                        if id3v2.genre?.pointee.p != nil {
                            let genre = String(cString: id3v2.genre.pointee.p)
                            metadata.genre = genre
                            if genre.count > 2 && genre.first == Character("(") && genre.last == Character(")")  {
                                let snum = genre.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                                let num = UInt8(snum)
                                if num != nil {
                                    metadata.genre = convertId3V1GenreIndexToName(index: num!)  
                                }                                
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
                        }                                                
                    } 
                    else if let id3v1 = id3v1Pointer?.pointee?.pointee {
                        // ID3v1 fallback                        
                        let title = String(cString: withUnsafePointer(to: id3v1.title) {
                            UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                        })
                        let artist = String(cString: withUnsafePointer(to: id3v1.artist) {
                            UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                        })
                        let album = String(cString: withUnsafePointer(to: id3v1.album) {
                            UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                        })
                        let year = String(cString: withUnsafePointer(to: id3v1.year) {
                            UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                        })
                        //let comment = String(cString: withUnsafePointer(to: id3v1.comment) {
                        //    UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                        //})
                        let genre = id3v1.genre
                        
                        metadata.title = title
                        metadata.artist = artist
                        metadata.albumName = album
                        metadata.recordingYear = Int(year) ?? -1
                        metadata.genre = convertId3V1GenreIndexToName(index: genre)                        
                    } 
                    else {
                        throw AudioPlayerError.MetadataNotFound
                    }
                    //
                    // return metadata
                    //
                    return metadata
                } 
                else {
                    throw AudioPlayerError.MpgSoundLibrary
                }                
            }// mpg123_meta_check            
            throw AudioPlayerError.MetadataNotFound            
        }// is .mp3
        
        throw AudioPlayerError.UnknownFileType                              
    }
}// AudioPlayer