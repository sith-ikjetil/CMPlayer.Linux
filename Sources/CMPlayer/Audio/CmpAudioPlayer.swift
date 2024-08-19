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
    private let filePath: URL    
    private var mp3Player: Mp3AudioPlayer? = nil
    private var aacPlayer: AacAudioPlayer? = nil
    
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
    init(path: URL) {
        self.filePath = path       
        if path.path.lowercased().hasSuffix(".mp3") {
            self.mp3Player = Mp3AudioPlayer(path: path);            
        }
        else if path.path.lowercased().hasSuffix(".m4a") {
            self.aacPlayer = AacAudioPlayer(path: path);            
        }
    }

    func play() throws {
        if mp3Player != nil {
            return try mp3Player!.play()
        }
        else if aacPlayer != nil {
            return try aacPlayer!.play()
        }
    }

    func stop() {
        if mp3Player != nil {
            return mp3Player!.stop()
        }
        else if aacPlayer != nil {
            return aacPlayer!.stop()
        }
    }

    func pause() {
        if mp3Player != nil {
            return mp3Player!.pause()
        }
        else if aacPlayer != nil {
            return aacPlayer!.pause()
        }
    }

    func resume() {
        if mp3Player != nil {
            return mp3Player!.resume()
        }
        else if aacPlayer != nil {
            return aacPlayer!.resume()
        }
    }

    static func gatherMetadata(path: URL) throws -> CmpMetadata {
        if path.path.lowercased().hasSuffix(".mp3") {
            return try Mp3AudioPlayer.gatherMetadata(path: path);
        }
        else if path.path.lowercased().hasSuffix(".m4a") {            
            return try AacAudioPlayer.gatherMetadata(path: path);            
        }

        let metadata = CmpMetadata()
        metadata.duration = 25000
        metadata.artist = "?"
        metadata.title = "?"
        metadata.genre = "?"
        metadata.albumName = "?"
        return metadata
    }
}// AudioPlayer