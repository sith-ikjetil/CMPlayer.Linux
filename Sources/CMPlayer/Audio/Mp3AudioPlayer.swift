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
    var timeElapsed: UInt64 {
        get {
            return self.m_timeElapsed
        }
    }
    var duration: UInt64 {
        get {
            return self.m_timeElapsed
        }
    }
    init(path: URL) {
        self.filePath = path        
    }

    func play() throws {
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
}// AudioPlayer