//
//  Player.swift
//  test
//
//  Created by Kjetil Kr Solberg on 17/09/2019.
//  Copyright © 2019 Kjetil Kr Solberg. All rights reserved.
//

//
// import.
//
import Foundation
import Cmpg123

//
// Represents CMPlayer Player.
//
internal class Player {
    //
    // Internal properties/constants.
    //
    var audio1: CmpAudioPlayer? = nil
    var audio2: CmpAudioPlayer? = nil
    var audioPlayerActive: Int = -1
    var durationAudioPlayer1: UInt64 = 0
    var durationAudioPlayer2: UInt64 = 0
    var isPaused: Bool = false
    var isPrev: Bool = false
    
    //
    // Private properties/constants.
    //
    private var currentCommandReady: Bool = false
    
    ///
    /// Initializes the application.
    ///
    func initialize() throws -> Void {        
        PlayerDirectories.ensureDirectoriesExistence()
        PlayerPreferences.ensureLoadPreferences()        
        
        PlayerLog.ApplicationLog?.logInformation(title: "CMPlayer", text: "Application Started.")
        
        Console.initialize()
        
        if PlayerPreferences.musicRootPath.count == 0 {
            let wnd: SetupWindow = SetupWindow()
            wnd.showWindow()
        }
        
        g_library.load()
        
        let wnd = InitializeWindow()
        wnd.showWindow()
        
        g_library.library = g_songs
        g_library.save()
        
        if PlayerPreferences.autoplayOnStartup && g_playlist.count > 0 {
            self.play(player: 1, playlistIndex: 0)            
        }
        
        Console.clearScreenCurrentTheme()           
    }    
    
    ///
    /// Plays audio.
    ///
    /// parameter player: Player number. 1 or 2.
    /// parameter playlistIndex: Index of playlist array to play.
    ///
    func play(player: Int, playlistIndex: Int) -> Void {
        guard g_songs.count > 0 && g_playlist.count > playlistIndex else {            
            return
        }
        
        PlayerLog.ApplicationLog?.logInformation(title: "[Player].play", text: "Playing index \(playlistIndex), file \(g_playlist[playlistIndex].fileURL?.path ?? "--unknown")")
        
        self.audioPlayerActive = player
        do {
            if player == -1 || player == 1 {
                if self.audio1 == nil {                      
                    self.audio1 = CmpAudioPlayer(path:g_playlist[playlistIndex].fileURL!)                    
                    self.durationAudioPlayer1 = g_playlist[playlistIndex].duration
                    try self.audio1?.play()                    
                    self.isPaused = false                            
                }
                else {
                    self.audio1?.stop()
                    self.audio1 = CmpAudioPlayer(path: g_playlist[playlistIndex].fileURL!)
                    self.durationAudioPlayer1 = g_playlist[playlistIndex].duration
                    try self.audio1?.play()
                    self.isPaused = false
                }                
            }
            else if player == 2 {
                if self.audio2 == nil {
                    self.audio2 = CmpAudioPlayer(path:g_playlist[playlistIndex].fileURL!)
                    self.durationAudioPlayer2 = g_playlist[playlistIndex].duration
                    try self.audio2?.play()
                    self.isPaused = false
                }
                else {
                    self.audio2?.stop()
                    self.audio2 = CmpAudioPlayer(path: g_playlist[playlistIndex].fileURL!)
                    self.durationAudioPlayer2 = g_playlist[playlistIndex].duration
                    try self.audio2?.play()
                    self.isPaused = false
                }            
            }
        }
        catch let error as CmpError {
            let msg = "Error playing player \(player) on index \(playlistIndex).\n Message: \(error.message)"
            PlayerLog.ApplicationLog?.logError(title: "[Player].play(player,playlistIndex)", text: msg.trimmingCharacters(in: .newlines))

            let wnd: ErrorWindow = ErrorWindow()
            wnd.message = msg
            wnd.showWindow()
            exit(ExitCodes.ERROR_PLAYING_FILE.rawValue)
        }
        catch {
            let msg = "Unknown Error.\n Error playing player \(player) on index \(playlistIndex).\n\(error)"
            PlayerLog.ApplicationLog?.logError(title: "[Player].play(player,playlistIndex)", text: msg)
            
            let wnd: ErrorWindow = ErrorWindow()
            wnd.message = msg
            wnd.showWindow()
            exit(ExitCodes.ERROR_PLAYING_FILE.rawValue)
        }
    }
    
    ///
    /// Pauses audio playback.
    ///
    func pause() -> Void {
        guard g_songs.count > 0 else {
            return
        }
        
        g_lock.lock()
        
        if self.audio1 != nil {
            if self.audio1?.isPlaying ?? false {
                audio1?.pause()
                self.isPaused = true
            }
        }
        
        if self.audio2 != nil {
            if self.audio2?.isPlaying ?? false {
                audio2?.pause()
                self.isPaused = true
            }
        }
        
        g_lock.unlock()
    }
    
    ///
    /// Resumes audio playback.
    ///
    func resume() -> Void {
        guard g_songs.count > 0 else {
            return
        }
        
        g_lock.lock()
        
        if self.audio1 != nil && self.audioPlayerActive == 1 {
            //if self.audio1?.currentTime.magnitude ?? 0 > 0 {
            //    audio1?.play()
            //    self.isPaused = false
            //}
            audio1?.resume()
        }
        
        if self.audio2 != nil && self.audioPlayerActive == 2 {
            //if self.audio2?.currentTime.magnitude ?? 0 > 0 {
            //    audio2?.play()
            //    self.isPaused = false
            //}
            audio2?.resume()
        }
        
        g_lock.unlock()
    }
    
    ///
    /// Plays previous song
    ///
    func prev() {
        guard g_playedSongs.count > 0 else {
            return
        }
        
        self.isPrev = true
    
        self.skip(play: true, crossfade: false)
        
        self.isPrev = false
    }
    
    ///
    /// Skips audio playback to next item in playlist.
    ///
    /// parameter crossfade: True if skip should crossfade. False otherwise.
    ///
    func skip(play: Bool = true, crossfade: Bool = true) -> Void {
        guard g_songs.count > 0 && g_playlist.count >= 1 else {
            return
        }
        
        if self.isPrev && g_playedSongs.count > 0 {
            g_playlist.insert( g_playedSongs.last!, at: 0)
            g_playedSongs.removeLast()
        }
        else {
            let pse = g_playlist.removeFirst()
            g_playedSongs.append(pse)
            while g_playedSongs.count > 100 {
                g_playedSongs.remove(at: 0)
            }
        }
        
        if g_playlist.count < 2 {
            if g_modeSearch.count > 0 && g_searchResult.count > 0 {
                let s = g_searchResult.randomElement()!
                g_playlist.append(s)
            }
            else {
                let s = g_songs.randomElement()!
                g_playlist.append(s)
            }
        }
        
        if self.audioPlayerActive == -1 || self.audioPlayerActive == 2 {
            if self.audio2 != nil {
                if self.audio2!.isPlaying {
                    if !PlayerPreferences.crossfadeSongs || !crossfade {
                        self.audio2!.stop()
                    }
                    else {
                        //self.audio2!.setVolume(0.0, fadeDuration: Double(PlayerPreferences.crossfadeTimeInSeconds) )
                    }
                }
            }
            if play {
                self.play(player: 1, playlistIndex: 0)
            }
        }
        else if self.audioPlayerActive == 1 {
            if self.audio1 != nil {
                if self.audio1!.isPlaying {
                    if !PlayerPreferences.crossfadeSongs || !crossfade {
                        self.audio1!.stop()
                    }
                    else {
                        //self.audio1!.setVolume(0.0, fadeDuration: Double(PlayerPreferences.crossfadeTimeInSeconds) )
                    }
                }
            }
            if play {
                self.play(player: 2, playlistIndex: 0)
            }
        }
    }
    
    ///
    /// Runs the application.
    ///
    /// returnes: Int32. Exit code.
    ///
    func run() throws -> Int32 {
        g_mainWindow = MainWindow()        
        g_mainWindow?.showWindow()
        PlayerLog.ApplicationLog?.logInformation(title: "CMPlayer", text: "Application Exited Normally.")
        return g_mainWindow?.exitValue ?? 0
    }
}// Player
