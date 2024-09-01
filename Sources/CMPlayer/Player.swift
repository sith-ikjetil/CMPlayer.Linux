//
//  Player.swift
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import.
//
import Foundation
import Cmpg123
import Glibc
//
// Represents CMPlayer Player.
//
internal class Player {
    //
    // internal varables
    //
    var audio1: CmpAudioPlayer? = nil       // audio player 1
    var audio2: CmpAudioPlayer? = nil       // audio player 2
    var audioPlayerActive: Int = -1         // audio player active
    var durationAudioPlayer1: UInt64 = 0    // duration song player 1
    var durationAudioPlayer2: UInt64 = 0    // duration song player 2
    var isPrev: Bool = false                // flag if we should skip previous or next    
    ///
    /// property
    /// 
    var isPaused: Bool {
        get {            
            if self.audioPlayerActive == 1 {
                return audio1?.isPaused ?? false
            }
            else if self.audioPlayerActive == 2 {
                return audio2?.isPaused ?? false
            }

            return false
        }
    }
    ///
    /// Initializes the application.
    ///
    func initialize() throws -> Void {                        
        /// ensure directores exist        
        PlayerDirectories.ensureDirectoriesExistence()
        // ensure preferences exist and is loaded if it does
        PlayerPreferences.ensureLoadPreferences()        
        // set player log
        PlayerLog.ApplicationLog = PlayerLog(autoSave: true)        
        // ensure command history exist and is loaded if it does        
        try PlayerCommandHistory.default.ensureLoadCommandHistory()
        // if log file exist delete it.
        let pathLogFile: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.filename, isDirectory: false)
        if FileManager.default.fileExists(atPath: pathLogFile.path) {
            try FileManager.default.removeItem(at: pathLogFile)     
        }           
        // log we have started
        PlayerLog.ApplicationLog?.logInformation(title: "CMPlayer", text: "Application Started.")
        // initialize console
        Console.initialize()
        // make sure we show the setup window if we have no musicRootPaths
        if PlayerPreferences.musicRootPath.count == 0 {
            let wnd: SetupWindow = SetupWindow()
            wnd.showWindow()
        }
        // try load library
        try g_library.load()
        // initialize CMPlayer, builds a brand new g_songs
        let wnd = InitializeWindow()
        wnd.showWindow()        
        // rebuild g_library and all other structures
        // - from g_songs which is populated after InitializeWindow
        g_library.rebuild()
        // save library      
        g_library.save()
        // if autoplay on startup, start playing
        if PlayerPreferences.autoplayOnStartup && g_playlist.count > 0 {
            self.play(player: 1, playlistIndex: 0)            
        }
        // clear screen with current theme color
        Console.clearScreenCurrentTheme()           
    }        
    ///
    /// Plays audio.
    ///
    /// parameter player: Player number. 1 or 2.
    /// parameter playlistIndex: Index of playlist array to play.
    ///
    func play(player: Int, playlistIndex: Int) -> Void {
        // make sure we have any songs and with it a playlist with at least 1 item
        guard g_songs.count > 0 && g_playlist.count > playlistIndex else {        
            // no then return, we can't play nothing.    
            return
        }
        // log playing
        PlayerLog.ApplicationLog?.logInformation(title: "[Player].play(player,playlistIndex)", text: "Playing player: \(player), index \(playlistIndex), file \(g_playlist[playlistIndex].fileURL?.path ?? "--unknown--")")
        // set which player is active
        self.audioPlayerActive = player
        do {
            // if player 1 is active
            if player == 1 {
                // if player 1 has not been set
                if self.audio1 == nil {                      
                    self.audio1 = try CmpAudioPlayer(path:g_playlist[playlistIndex].fileURL!)                    
                    self.durationAudioPlayer1 = g_playlist[playlistIndex].duration
                    try self.audio1?.play()                    
                }
                // if player 1 is active
                else {
                    self.audio1?.stop()
                    self.audio1 = try CmpAudioPlayer(path: g_playlist[playlistIndex].fileURL!)
                    self.durationAudioPlayer1 = g_playlist[playlistIndex].duration
                    try self.audio1?.play()
                }                
            }
            // if player 2 is active
            else if player == 2 {              
                // if player 2 has not been set  
                if self.audio2 == nil {
                    self.audio2 = try CmpAudioPlayer(path:g_playlist[playlistIndex].fileURL!)
                    self.durationAudioPlayer2 = g_playlist[playlistIndex].duration
                    try self.audio2?.play()
                }
                // if player 2 is active
                else {
                    self.audio2?.stop()
                    self.audio2 = try CmpAudioPlayer(path: g_playlist[playlistIndex].fileURL!)
                    self.durationAudioPlayer2 = g_playlist[playlistIndex].duration
                    try self.audio2?.play()
                }            
            }
        }
        catch let error as CmpError {
            // ensure g_quit is true to let all async code to exit
            g_quit = true
            // let all players async code stop playing and clean up
            Thread.sleep(forTimeInterval: TimeInterval(g_asyncCompletionDelay))
            // create error message
            let msg = "CMPlayer ABEND.\n[Player].play(player,playlistIndex).\nError playing player \(player) on index \(playlistIndex).\nMessage: \(error.message)"            
            // clear screen
            Console.clearScreen()
            // goto 1,1
            Console.gotoXY(1, 1)
            // reset console colors
            Console.resetConsoleColors()
            // clear terminal
            system("clear")            
            // write error message
            print(msg) 
            // log error message
            PlayerLog.ApplicationLog?.logError(title: "[Player].play(player,playlistIndex)", text: msg)
            // exit with exit code
            exit(ExitCodes.ERROR_PLAYING_FILE.rawValue)
        }
        catch {
            // ensure g_quit is true to let all async code to exit
            g_quit = true
            // let all players async code stop playing and clean up
            Thread.sleep(forTimeInterval: TimeInterval(g_asyncCompletionDelay))
            // create error message
            let msg = "CMPlayer ABEND.\n[Player].play(player,playlistIndex).\nUnknown error playing player \(player) on index \(playlistIndex).\nMessage: \(error)"            
            // clear screen
            Console.clearScreen()
            // goto 1,1
            Console.gotoXY(1, 1) 
            // reset console colors
            Console.resetConsoleColors()           
            // clear terminal
            system("clear")            
            // write error message
            print(msg) 
            // log error message
            PlayerLog.ApplicationLog?.logError(title: "[Player].play(player,playlistIndex)", text: msg)
            // exit with exit code
            exit(ExitCodes.ERROR_PLAYING_FILE.rawValue)
        }
    }    
    ///
    /// Pauses audio playback.
    ///
    func pause() -> Void {
        // if we have not songs we have nothing to pause
        guard g_songs.count > 0 else {
            return
        }
        // if there is no player active we have nothing to pause
        guard self.audioPlayerActive != -1 else {
            return
        }
        // lock 
        g_lock.lock()
        // if player 1 is active then pause it        
        if self.audioPlayerActive == 1 {
            audio1?.pause()            
        }
        // if player 2 is active then pause it
        else if self.audioPlayerActive == 2 {
            audio2?.pause()
        }
        // unlock
        g_lock.unlock()
    }    
    ///
    /// Resumes audio playback.
    ///
    func resume() -> Void {
        // if we have not songs we have nothing to resume
        guard g_songs.count > 0 else {
            return
        }
        // if there is no player active we have nothing to resume
        guard self.audioPlayerActive != -1 else {
            return
        }
        // lock
        g_lock.lock()
        // if player 1 is active then resume it        
        if self.audioPlayerActive == 1 {
            audio1?.resume()
        }
        // if player 2 is active then resume it        
        else if self.audioPlayerActive == 2 {
            audio2?.resume()
        }
        // unlock
        g_lock.unlock()
    }    
    ///
    /// Plays previous song
    ///
    func prev() {
        // if we have not songs we have nothing got previous to
        guard g_playedSongs.count > 0 else {
            return
        }
        // set flag that we are skipping to previous
        self.isPrev = true
        // skip song
        self.skip(play: true, crossfade: false)
        // unset flag that we are skiping to previous
        self.isPrev = false
    }    
    ///
    /// Skips audio playback to next item in playlist.
    ///
    /// parameter crossfade: True if skip should crossfade. False otherwise.
    ///
    func skip(play: Bool = true, crossfade: Bool = true) -> Void {
        // if we have not songs we have nothing skip
        guard g_songs.count > 0 && g_playlist.count >= 1 else {
            return
        }
        // if we have self.isPrev flag set, and we have played at least one song, goto previous song
        if self.isPrev && g_playedSongs.count > 0 {
            g_playlist.insert( g_playedSongs.last!, at: 0)
            g_playedSongs.removeLast()
        }
        // else skip to next song
        else {
            let pse = g_playlist.removeFirst()
            g_playedSongs.append(pse)
            while g_playedSongs.count > 100 {
                g_playedSongs.remove(at: 0)
            }
        }
        // if g_playlist has less than 2 items in it, add a random item
        if g_playlist.count < 2 {
            // if we are in a mode, add from g_searchResult
            if g_modeSearch.count > 0 && g_searchResult.count > 0 {
                let s = g_searchResult.randomElement()!
                g_playlist.append(s)
            }
            // else add from g_songs
            else {
                let s = g_songs.randomElement()!
                g_playlist.append(s)
            }
        }
        // if self.audioPlayerActive is not set or it is set to 2
        if self.audioPlayerActive == -1 || self.audioPlayerActive == 2 {
            // if player 2 is not set
            if self.audio2 != nil {
                // if player 2 is playing
                if self.audio2!.isPlaying {
                    // if we are not to do crossfade
                    if !PlayerPreferences.crossfadeSongs || !crossfade {
                        self.audio2!.stop()
                    }
                    // else then crossfade
                    else {
                        self.audio2!.setCrossfadeVolume(volume: 0.0, fadeDuration: UInt64(PlayerPreferences.crossfadeTimeInSeconds*1000) )
                    }
                }                
            }
            // if flag play is set, then start playing
            if play {
                self.play(player: 1, playlistIndex: 0)
            }
        }
        // if self.audioPlayerActive is set to 1
        else if self.audioPlayerActive == 1 {
            // if player 1 is not set
            if self.audio1 != nil {
                // if player 1 is playing
                if self.audio1!.isPlaying {
                    // if we are not to do crossfade
                    if !PlayerPreferences.crossfadeSongs || !crossfade {
                        self.audio1!.stop()
                    }
                    // else then crossfade
                    else {
                        self.audio1!.setCrossfadeVolume(volume: 0.0, fadeDuration: UInt64(PlayerPreferences.crossfadeTimeInSeconds*1000) )
                    }
                }                
            }
            // if flag play is set, then start playing
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
    func run() throws {
        // create MainWindow
        g_mainWindow = MainWindow()        
        // show MainWindow and run it
        g_mainWindow?.showWindow()        
    }
}// Player
