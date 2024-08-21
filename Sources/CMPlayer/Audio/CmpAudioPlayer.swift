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
internal class CmpAudioPlayer {
    ///
    /// private constants
    /// 
    private let filePath: URL    
    ///
    /// private variables
    /// 
    private var mp3Player: Mp3AudioPlayer? = nil
    private var aacPlayer: AacAudioPlayer? = nil
    ///
    /// get properties
    ///
    var isPlaying: Bool {
        get {
            if mp3Player != nil {
                return mp3Player!.isPlaying
            }
            else if aacPlayer != nil {
                return aacPlayer!.isPlaying
            }
            return false
        }
    }
    var isPaused: Bool {
        if mp3Player != nil {
            return mp3Player!.isPaused
        }
        else if aacPlayer != nil {
            return aacPlayer!.isPaused
        }
        return false
    }    
    var timeElapsed: UInt64 {
        get {
            if mp3Player != nil {
                return mp3Player!.timeElapsed
            }
            else if aacPlayer != nil {
                return aacPlayer!.timeElapsed
            }
            return 0
        }
    }
    var duration: UInt64 {
        get {
            if mp3Player != nil {
                return mp3Player!.duration
            }
            else if aacPlayer != nil {
                return aacPlayer!.duration
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
            self.aacPlayer = AacAudioPlayer(path: path);            
        }
    }
    ///
    /// initiates playback of the audio file from init(path)
    /// 
    func play() throws {
        if mp3Player != nil {
            return try mp3Player!.play()
        }
        else if aacPlayer != nil {
            return try aacPlayer!.play()
        }        
    }
    ///
    /// stops playback if we are playing.
    /// 
    func stop() {
        if mp3Player != nil {
            return mp3Player!.stop()
        }
        else if aacPlayer != nil {
            return aacPlayer!.stop()
        }
    }
    ///
    /// pauses playback if we are playing
    /// 
    func pause() {
        if mp3Player != nil {
            return mp3Player!.pause()
        }
        else if aacPlayer != nil {
            return aacPlayer!.pause()
        }
    }
    ///
    /// resumes playback if we are playing.
    ///
    func resume() {
        if mp3Player != nil {
            return mp3Player!.resume()
        }
        else if aacPlayer != nil {
            return aacPlayer!.resume()
        }
    }
    /// 
    /// Sets how the volume is done with crossfading enabled.
    /// - Parameters:
    ///   - volume: target volume. usually 0.
    ///   - duration: time from end of song, fading should be done.
    func setCrossfadeVolume(volume: Float, fadeDuration: UInt64) {
        if mp3Player != nil {
            return mp3Player!.setCrossfadeVolume(volume: volume, fadeDuration: fadeDuration)
        }
        else if aacPlayer != nil {
            return aacPlayer!.setCrossfadeVolume(volume: volume, fadeDuration: fadeDuration)
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
            return try AacAudioPlayer.gatherMetadata(path: path);            
        }

        throw CmpError(message: "Error trying to gather metadata on unknown file format. File: \(path.path)")
    }
}// AudioPlayer