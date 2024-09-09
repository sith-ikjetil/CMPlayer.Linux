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
        // set audioPlayer to AnyAudioPlayer
        self.audioPlayer = AnyAudioPlayer(path: path);
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
        return try AnyAudioPlayer.gatherMetadata(path: path)
    }
}// AudioPlayer
