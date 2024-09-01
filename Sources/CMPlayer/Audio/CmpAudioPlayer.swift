//
//  AudioPlayer.swift
//
//  (i): Audio player wrapper class. Abstracts away the real 
//       audio players by containment. Forward to the underlying
//       real audio player based on type of media to play.
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
    private let filePath: URL    // path to audio file
    ///
    /// private variables
    /// 
    private var mp3Player: Mp3AudioPlayer? = nil // libmpg123 mp3 audio player
    private var m4aPlayer: M4aAudioPlayer? = nil // ffmpeg m4a audio player
    ///
    /// get properties
    ///
    var isPlaying: Bool {
        get {
            // if we are holding an mp3 player
            if self.mp3Player != nil {
                // forward to mp3 player
                return self.mp3Player!.isPlaying
            }
            // else if we are holding an m4a player
            else if self.m4aPlayer != nil {
                // forward to m4a player
                return self.m4aPlayer!.isPlaying
            }
            // should not get here
            // return false
            return false
        }
    }
    var isPaused: Bool {
        // if we are holding an mp3 player
        if self.mp3Player != nil {
            // forward to mp3 player
            return self.mp3Player!.isPaused
        }
        // else if we are holding an m4a player
        else if self.m4aPlayer != nil {
            // forward to m4a player
            return self.m4aPlayer!.isPaused
        }
        // should not get here
        // return false
        return false
    }    
    var hasPlayed: Bool {
        // if we are holding an mp3 player
        if self.mp3Player != nil {
            // forward to mp3 player
            return self.mp3Player!.hasPlayed            
        }
        // else if we are holding an m4a player
        else if self.m4aPlayer != nil {
            // forward to m4a player
            return self.m4aPlayer!.hasPlayed
        }
        // should not get here
        // return false
        return false
    }    
    var timeElapsed: UInt64 {
        get {
            // if we are holding an mp3 player
            if mp3Player != nil {
                // forward to mp3 player
                return mp3Player!.timeElapsed
            }
            // else if we are holding an m4a player
            else if self.m4aPlayer != nil {
                // forward to m4a player
                return self.m4aPlayer!.timeElapsed
            }
            // should not get here
            // return 0
            return 0
        }
    }
    var duration: UInt64 {
        get {
            // if we are holding an mp3 player
            if self.mp3Player != nil {
                // forward to mp3 player
                return self.mp3Player!.duration
            }
            // else if we are holding an m4a player
            else if self.m4aPlayer != nil {
                // forward to m4a player
                return self.m4aPlayer!.duration
            }
            // should not get here
            // return 0
            return 0
        }
    }
    ///
    /// initializer
    ///
    init(path: URL) throws {
        // check if file exists
        if !FileManager.default.fileExists(atPath: path.path) {
            // no, create error message
            let msg: String = "[CmpAudioPlayer].init. File not found: \(path.path)"
            // throw error
            throw CmpError(message: msg)
        }

        // save path
        self.filePath = path       
        // is path an mp3?
        if path.path.lowercased().hasSuffix(".mp3") {
            // yes, set self.mp3Player to a new instance of Mp3AudioPlayer
            self.mp3Player = Mp3AudioPlayer(path: path);            
            // return
            return
        }
        // else if path an m4a?
        else if path.path.lowercased().hasSuffix(".m4a") {
            // yes, set self.mp3Player to a new instance of M4aAudioPlayer
            self.m4aPlayer = M4aAudioPlayer(path: path);            
            // return
            return
        }

        let msg: String = "[CmpAudioPlayer].init. Invalid media type. Not supported. File: \(path.path)"
        throw CmpError(message: msg)
    }
    ///
    /// initiates playback of the audio file from init(path)
    /// 
    func play() throws {
        // if we are holding an mp3 player
        if self.mp3Player != nil {
            // forward to mp3 player
            try self.mp3Player!.play()
        }
        // else if we are holding an m4a player
        else if self.m4aPlayer != nil {
            // forward to m4a player
            try self.m4aPlayer!.play()
        }        
    }
    ///
    /// stops playback if we are playing.
    /// 
    func stop() {
        // if we are holding an mp3 player
        if self.mp3Player != nil {
            // forward to mp3 player
            self.mp3Player!.stop()
        }
        // else if we are holding an m4a player
        else if self.m4aPlayer != nil {
            // forward to m4a player
            self.m4aPlayer!.stop()
        }
    }
    ///
    /// pauses playback if we are playing
    /// 
    func pause() {
        // if we are holding an mp3 player
        if self.mp3Player != nil {
            // forward to mp3 player
            self.mp3Player!.pause()
        }
        // else if we are holding an m4a player
        else if self.m4aPlayer != nil {
            // forward to m4a player
            self.m4aPlayer!.pause()
        }
    }
    ///
    /// resumes playback if we are playing.
    ///
    func resume() {
        // if we are holding an mp3 player
        if self.mp3Player != nil {
            // forward to mp3 player
            self.mp3Player!.resume()
        }
        // else if we are holding an m4a player
        else if self.m4aPlayer != nil {
            // forward to m4a player
            self.m4aPlayer!.resume()
        }
    }
    /// 
    /// seeks playback from start to position (ms)
    /// 
    /// - Parameter position: ms from start
    func seekToPos(position: UInt64)
    {
        // if we are holding an mp3 player
        if self.mp3Player != nil {
            // forward to mp3 player
            self.mp3Player!.seekToPos(position: position)
        }
        // else if we are holding an m4a player
        else if self.m4aPlayer != nil {
            // forward to m4a player
            self.m4aPlayer!.seekToPos(position: position)
        }
    }
    /// 
    /// Sets how the volume is done with crossfading enabled.
    /// - Parameters:
    ///   - volume: target volume. usually 0.
    ///   - duration: time from end of song, fading should be done.
    func setCrossfadeVolume(volume: Float, fadeDuration: UInt64) {
        // if we are holding an mp3 player
        if self.mp3Player != nil {
            // forward to mp3 player
            self.mp3Player!.setCrossfadeVolume(volume: volume, fadeDuration: fadeDuration)
        }
        // else if we are holding an m4a player
        else if self.m4aPlayer != nil {
            // forward to m4a player
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
        // is file an mp3?
        if path.path.lowercased().hasSuffix(".mp3") {
            // yes, try and gather metadata
            return try Mp3AudioPlayer.gatherMetadata(path: path);
        }
        // else is file an m4a?
        else if path.path.lowercased().hasSuffix(".m4a") {            
            // yes, try and gather metadata
            return try M4aAudioPlayer.gatherMetadata(path: path);            
        }
        // unsupported or unknown file type
        // throw error
        throw CmpError(message: "Error trying to gather metadata on unknown file format. File: \(path.path)")
    }
}// AudioPlayer
