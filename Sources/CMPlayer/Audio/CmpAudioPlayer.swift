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

//
// Represents CMPlayer AudioPlayer.
//
internal class CmpAudioPlayer {
    ///
    /// private constants
    /// 
    private let filePath: URL    
    ///
    /// private variables
    /// 
    private var mp3Player: Mp3AudioPlayer? = nil
    private var m4aPlayer: M4aAudioPlayer? = nil
    ///
    /// get properties
    ///
    var isPlaying: Bool {
        get {
            if self.mp3Player != nil {
                return self.mp3Player!.isPlaying
            }
            else if self.m4aPlayer != nil {
                return self.m4aPlayer!.isPlaying
            }
            return false
        }
    }
    var isPaused: Bool {
        if self.mp3Player != nil {
            return self.mp3Player!.isPaused
        }
        else if self.m4aPlayer != nil {
            return self.m4aPlayer!.isPaused
        }
        return false
    }    
    var hasPlayed: Bool {
        if self.mp3Player != nil {
            return self.mp3Player!.hasPlayed
        }
        else if self.m4aPlayer != nil {
            return self.m4aPlayer!.hasPlayed
        }
        return false
    }    
    var timeElapsed: UInt64 {
        get {
            if mp3Player != nil {
                return mp3Player!.timeElapsed
            }
            else if self.m4aPlayer != nil {
                return self.m4aPlayer!.timeElapsed
            }
            return 0
        }
    }
    var duration: UInt64 {
        get {
            if self.mp3Player != nil {
                return self.mp3Player!.duration
            }
            else if self.m4aPlayer != nil {
                return self.m4aPlayer!.duration
            }
            return 0
        }
    }
    ///
    /// Only initializer
    ///
    init(path: URL) {
        self.filePath = path       
        if path.path.lowercased().hasSuffix(".mp3") {
            self.mp3Player = Mp3AudioPlayer(path: path);            
        }
        else if path.path.lowercased().hasSuffix(".m4a") {
            self.m4aPlayer = M4aAudioPlayer(path: path);            
        }
    }
    ///
    /// initiates playback of the audio file from init(path)
    /// 
    func play() throws {
        if self.mp3Player != nil {
            try self.mp3Player!.play()
        }
        else if self.m4aPlayer != nil {
            try self.m4aPlayer!.play()
        }        
    }
    ///
    /// stops playback if we are playing.
    /// 
    func stop() {
        if self.mp3Player != nil {
            self.mp3Player!.stop()
        }
        else if self.m4aPlayer != nil {
            self.m4aPlayer!.stop()
        }
    }
    ///
    /// pauses playback if we are playing
    /// 
    func pause() {
        if self.mp3Player != nil {
            self.mp3Player!.pause()
        }
        else if self.m4aPlayer != nil {
            self.m4aPlayer!.pause()
        }
    }
    ///
    /// resumes playback if we are playing.
    ///
    func resume() {
        if self.mp3Player != nil {
            self.mp3Player!.resume()
        }
        else if self.m4aPlayer != nil {
            self.m4aPlayer!.resume()
        }
    }
    /// 
    /// seeks playback from start to position (ms)
    /// 
    /// - Parameter position: ms from start
    func seekToPos(position: UInt64)
    {
        if self.mp3Player != nil {
            self.mp3Player!.seekToPos(position: position)
        }
        else if self.m4aPlayer != nil {
            self.m4aPlayer!.seekToPos(position: position)
        }
    }
    /// 
    /// Sets how the volume is done with crossfading enabled.
    /// - Parameters:
    ///   - volume: target volume. usually 0.
    ///   - duration: time from end of song, fading should be done.
    func setCrossfadeVolume(volume: Float, fadeDuration: UInt64) {
        if self.mp3Player != nil {
            self.mp3Player!.setCrossfadeVolume(volume: volume, fadeDuration: fadeDuration)
        }
        else if self.m4aPlayer != nil {
            self.m4aPlayer!.setCrossfadeVolume(volume: volume, fadeDuration: fadeDuration)
        }
    }
    ///
    /// Gathers metadata.
    /// - Parameter path: file to gather metadata from.
    /// - Throws: CmpError
    /// - Returns: CmpMetadata
    /// 
    static func gatherMetadata(path: URL) throws -> CmpMetadata {
        if path.path.lowercased().hasSuffix(".mp3") {
            return try Mp3AudioPlayer.gatherMetadata(path: path);
        }
        else if path.path.lowercased().hasSuffix(".m4a") {            
            return try M4aAudioPlayer.gatherMetadata(path: path);            
        }

        throw CmpError(message: "Error trying to gather metadata on unknown file format. File: \(path.path)")
    }
}// AudioPlayer