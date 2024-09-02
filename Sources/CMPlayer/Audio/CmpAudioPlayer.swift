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
    //private var mp3Player: Mp3AudioPlayer? = nil // libmpg123 mp3 audio player
    //private var m4aPlayer: M4aAudioPlayer? = nil // ffmpeg m4a audio player
    private var audioPlayer: CmpAudioPlayerProtocol? = nil
    ///
    /// get properties
    ///
    var isPlaying: Bool {
        get {
            return self.audioPlayer?.isPlaying ?? false            
        }
    }
    var isPaused: Bool {
        get {
            return self.audioPlayer?.isPaused ?? false            
        }
    }    
    var hasPlayed: Bool {
        get {
            return self.audioPlayer?.hasPlayed ?? false
        }
    }    
    var timeElapsed: UInt64 {
        get {
            return self.audioPlayer?.timeElapsed ?? 0
        }
    }
    var duration: UInt64 {
        get {
            return self.audioPlayer?.duration ?? 0
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
            self.audioPlayer = Mp3AudioPlayer(path: path);            
            // return
            return
        }
        // else if path an m4a?
        else if path.path.lowercased().hasSuffix(".m4a") {
            // yes, set self.mp3Player to a new instance of M4aAudioPlayer
            self.audioPlayer = M4aAudioPlayer(path: path);            
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
        try self.audioPlayer?.play()
    }
    ///
    /// stops playback if we are playing.
    /// 
    func stop() {
        self.audioPlayer?.stop()
    }
    ///
    /// pauses playback if we are playing
    /// 
    func pause() {
        self.audioPlayer?.pause()
    }
    ///
    /// resumes playback if we are playing.
    ///
    func resume() {
        self.audioPlayer?.resume()
    }
    /// 
    /// seeks playback from start to position (ms)
    /// 
    /// - Parameter position: ms from start
    func seekToPos(position: UInt64)
    {
        self.audioPlayer?.seekToPos(position: position)        
    }
    /// 
    /// Sets how the volume is done with crossfading enabled.
    /// - Parameters:
    ///   - volume: target volume. usually 0.
    ///   - duration: time from end of song, fading should be done.
    func setCrossfadeVolume(volume: Float, fadeDuration: UInt64) {
        self.audioPlayer?.setCrossfadeVolume(volume: volume, fadeDuration: fadeDuration)        
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
