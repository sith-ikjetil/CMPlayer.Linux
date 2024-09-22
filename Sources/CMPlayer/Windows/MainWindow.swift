//
//  MainWindow.swift
//
//  (i): Main window. Shows playlist and currently playing items
//       with time remaining. Can enter commands into command line
//       at bottom of screen ">:" Type "help" for information on what 
//       commands can be entered.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import
//
import Foundation
import Cao
///
/// Represents CMPlayer MainWindow.
///
internal class MainWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    ///
    /// static private variables
    /// 
    static private var timeElapsedMs: UInt64 = 0  // up time in ms counter 
    //
    // private variables
    //        
    private var currentCommand: String = ""       // current command typing in
    private var commands: [PlayerCommand] = []    // array of PlayerCommandObjects set in run()
    private var isShowingTopWindow = false  // true == window on top of this window, false == this is top window
    private var addendumText: String = ""         // text added to screen over command line if info needs to be outputted    
    private var isTooSmall: Bool = false          // true == screen size is invalid too small, false == supported and valid size
    private var showCursor: Bool = false          // true == should cursor be visible, false == should not be visible
    private var cursorTimeout: UInt64 = 0         // cursor time in ms counted from 0 to target. used to set showCursor
    ///
    /// priate constants
    /// 
    private let concurrentQueue1 = DispatchQueue(label: "dqueue.cmp.linux.main-window.1", attributes: .concurrent)
    private let concurrentQueue2 = DispatchQueue(label: "dqueue.cmp.linux.main-window.2", attributes: .concurrent)         
    ///
    /// Shows this MainWindow on screen.
    ///
    /// returns: ExitCode,  Int32
    ///
    func showWindow() -> Void {
        // ensure terminal size change event gets directed here
        g_tscpStack.append(self)
        // run this window
        self.run()
        // ensure terminal size change event goes back to previous protocol implementation
        g_tscpStack.removeLast()
    }    
    ///
    /// Handler for TerminalSizeHasChangedProtocol
    ///
    func terminalSizeHasChanged() -> Void {
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // if we have valid size
        if g_rows >= g_minRows && g_cols >= g_minCols {
            // set flag isTooSmall to false
            self.isTooSmall = false
            // render header
            MainWindow.renderHeader(showTime: true)
            // render rest of the window
            self.renderWindow()
        }
        // we have invalid size
        else {
            // set isTooSmall flag to true
            self.isTooSmall = true            
        }
    }
    ///
    /// Renders header on screen
    ///
    /// parameter showTime: True if time string is to be shown in header. False otherwise.
    ///
    static func renderHeader(showTime: Bool) -> Void {        
        // create message
        var msg: String = "CMPlayer | v\(g_versionString)"
        // if showTime flag is true
        if showTime {
            // append time to message
            msg += " | \(itsRenderMsToFullString(MainWindow.timeElapsedMs, false))"
        }
        // if player is paused
        if g_player.isPaused {
            // append paused to message
            msg += " | [paused]"
        }
        // render header with message        
        Console.printXY(1, 1, msg, g_cols, .center, " ", getThemeBgHeaderColor(), getThemeBgHeaderModifier(), getThemeFgHeaderColor(), getThemeFgHeaderModifier())        
    }    
    ///
    /// Renders main window frame on screen
    ///
    func renderTitle() -> Void {
        // render header
        MainWindow.renderHeader(showTime: true)        
        // render blank line y = 2
        Console.printXY(1,2," ", g_cols, .center, " ", getThemeBgEmptySpaceColor(), getThemeBgEmptySpaceModifier(), getThemeFgEmptySpaceColor(), getThemeFgEmptySpaceModifier())
        // render default view
        if PlayerPreferences.viewType == ViewType.Default {  
            // get layout info
            let layout: MainWindowLayout = MainWindowLayout.get()    
            // render song no header
            Console.printXY(layout.songNoX,3,"Song No.", layout.songNoCols, .left, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())
            // render artist header
            Console.printXY(layout.artistX,3,"Artist", layout.artistCols, .left, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())
            // render title header
            Console.printXY(layout.titleX,3,"Title", layout.titleCols, .left, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())
            // render time header
            Console.printXY(layout.durationX,3,"Time", layout.durationCols, .left, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())
            // render separator line
            Console.printXY(1,4,String(getSeparatorChar().first!), g_cols, .left, getSeparatorChar().first!, getThemeBgSeparatorColor(), getThemeBgSeparatorModifier(), getThemeFgSeparatorColor(), getThemeFgSeparatorModifier())
        }
        // else render details view
        else if PlayerPreferences.viewType == ViewType.Details {
            // get layout info
            let layout: MainWindowLayout = MainWindowLayout.get()    
            // render song no and empty header
            Console.printXY(1,3,"Song No.", layout.songNoCols, .left, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())
            Console.printXY(1,4," ", layout.songNoCols, .left, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())                        
            // render artist and album name header
            Console.printXY(layout.artistX,3,"Artist", layout.artistCols, .left, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())
            Console.printXY(layout.artistX,4,"Album", layout.artistCols, .left, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())
            // render title and genre header
            Console.printXY(layout.titleX,3,"Title", layout.titleCols, .left, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())
            Console.printXY(layout.titleX,4,"Genre", layout.titleCols, .left, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())
            // render time and empty header
            Console.printXY(layout.durationX,3,"Time", layout.durationCols, .left, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())
            Console.printXY(layout.durationX,4," ", layout.durationCols, .left, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())
            // render separator line
            Console.printXY(1,5,String(getSeparatorChar().first!), g_cols, .left, getSeparatorChar().first!, getThemeBgSeparatorColor(), getThemeBgSeparatorModifier(), getThemeFgSeparatorColor(), getThemeFgSeparatorModifier())
        }
    }
    ///
    /// Renders a song on screen
    ///
    /// parameter y: Line where song is to be rendered.
    /// parameter song: SongEntry to render
    /// parameter time: duration.    
    ///
    func renderSong(_ y: Int, _ song: SongEntry, _ time: UInt64) -> Void
    {        
        // if viewtype is set to default
        if PlayerPreferences.viewType == ViewType.Default {
            // get layout info
            let layout: MainWindowLayout = MainWindowLayout.get() 
            // render song no
            Console.printXY(layout.songNoX, y, "\(song.songNo) ", layout.songNoCols, .right, " ", getThemeBgQueueSongNoColor(), getThemeBgQueueSongNoModifier(), getThemeFgQueueSongNoColor(), getThemeFgQueueSongNoModifier())
            // render artist
            Console.printXY(layout.artistX, y, song.getArtist(), layout.artistCols, .left, " ", getThemeBgQueueColor(), getThemeBgQueueModifier(), getThemeFgQueueColor(), getThemeFgQueueModifier())
            // render title
            Console.printXY(layout.titleX, y, song.getTitle(), layout.titleCols, .left, " ", getThemeBgQueueColor(), getThemeBgQueueModifier(), getThemeFgQueueColor(), getThemeFgQueueModifier())
            // set time string
            let timeString: String = itsRenderMsToFullString(time, false)
            let endTimePart: String = String(timeString[timeString.index(timeString.endIndex, offsetBy: -5)..<timeString.endIndex])
            // render duration left
            Console.printXY(layout.durationX, y, endTimePart, layout.durationCols, .ignore, " ", getThemeBgQueueColor(), getThemeBgQueueModifier(), getThemeFgQueueColor(), getThemeFgQueueModifier())
        }
        // if viewtype is set to details
        else if PlayerPreferences.viewType == ViewType.Details {
            // get layout info
            let layout: MainWindowLayout = MainWindowLayout.get() 
            // render song no and empty field
            Console.printXY(layout.songNoX, y, "\(song.songNo) ", layout.songNoCols, .right, " ", getThemeBgQueueSongNoColor(), getThemeBgQueueSongNoModifier(), getThemeFgQueueSongNoColor(), getThemeFgQueueSongNoModifier())
            Console.printXY(layout.songNoX, y+1, " ", layout.songNoCols, .right, " ", getThemeBgQueueSongNoColor(), getThemeBgQueueSongNoModifier(), getThemeFgQueueSongNoColor(), getThemeFgQueueSongNoModifier())
            // render artist and album name
            Console.printXY(layout.artistX, y, song.getArtist(), layout.artistCols, .left, " ", getThemeBgQueueColor(), getThemeBgQueueModifier(), getThemeFgQueueColor(), getThemeFgQueueModifier())
            Console.printXY(layout.artistX, y+1, song.getAlbumName(), layout.artistCols, .left, " ", getThemeBgQueueColor(), getThemeBgQueueModifier(), getThemeFgQueueColor(), getThemeFgQueueModifier())
            // render title and genre
            Console.printXY(layout.titleX, y, song.getTitle(), layout.titleCols, .left, " ", getThemeBgQueueColor(), getThemeBgQueueModifier(), getThemeFgQueueColor(), getThemeFgQueueModifier())
            Console.printXY(layout.titleX, y+1, song.getGenre(), layout.titleCols, .left, " ", getThemeBgQueueColor(), getThemeBgQueueModifier(), getThemeFgQueueColor(), getThemeFgQueueModifier())
            // set time string
            let timeString: String = itsRenderMsToFullString(time, false)
            let endTimePart: String = String(timeString[timeString.index(timeString.endIndex, offsetBy: -5)..<timeString.endIndex])
            // render duration and empty field
            Console.printXY(layout.durationX, y, endTimePart, layout.durationCols, .ignore, " ", getThemeBgQueueColor(), getThemeBgQueueModifier(), getThemeFgQueueColor(), getThemeFgQueueModifier())
            Console.printXY(layout.durationX, y+1, " ", layout.durationCols, .left, " ", getThemeBgQueueColor(), getThemeBgQueueModifier(), getThemeFgQueueColor(), getThemeFgQueueModifier())
        }
    }
    /// 
    /// renders addendum text at g_rows-2
    ///     
    func renderAddendumText() -> Void {
        // render addendum text from self.addendumText
        Console.printXY(1,g_rows-2, (self.addendumText.count > 0) ? self.addendumText : " ", g_cols, .left, " ", getThemeBgAddendumColor(), getThemeBgAddendumModifier(), getThemeFgAddendumColor(), getThemeFgAddendumModifier())
    }    
    ///
    /// Renders the command line on screen
    ///
    func renderCommandLine() -> Void
    {
        // set text = self.currentCommand
        var text = self.currentCommand
        // if text.count is greater than width on screen
        if text.count > (g_cols-4) {
            // get subtext visible area
            text = String(text[text.index(text.endIndex, offsetBy: -1*(g_cols-4))..<text.endIndex])
        }
        // set cursor to empty string
        var cursor = ""
        // if showCursor flag is set, set cursor to cursor to be shown
        if self.showCursor {
            cursor = "_"
        }
        // render command line
        Console.printXY(1,g_rows-1,">: \(text)\(cursor)", g_cols, .left, " ", getThemeBgCommandLineColor(), getThemeBgCommandLineModifier(), getThemeFgCommandLineColor(), getThemeFgCommandLineModifier())
    }    
    ///
    /// Renders the status line on screen
    ///
    func renderStatusLine() -> Void
    {
        // set initial status line text
        var text: String = "\(g_songs.count.itsToString()) Songs"
        // get mode status
        let modeInfo = getModeStatus()
        // if we are in mode
        if modeInfo.isInMode {
            // append mode text
            text.append( " | Mode: ")
            // set flag for adding , or not
            var b: Bool = false
            // for each mode
            for mn in modeInfo.modeName {
                // if we should add ,
                if b {
                    // add ,
                    text.append(", ")
                }
                // add mode name
                text.append(mn)
                // now we will always need to add ,
                b = true
            }
            // append rest of mode information and colsxrows and songs in queue
            text.append(" with \(modeInfo.numberOfSongsInMode.itsToString()) Songs | \(g_cols)x\(g_rows) | \(g_playlist.count) Songs in Queue")
        }
        else {
            // append mod info, colsxrows and songs in queue
            text.append( " | Mode: off | \(g_cols)x\(g_rows) | \(g_playlist.count) Songs in Queue" )
        }
        // render status line
        Console.printXY(1,g_rows, text, g_cols, .center, " ", getThemeBgStatusLineColor(), getThemeBgStatusLineModifier(), getThemeFgStatusLineColor(), getThemeFgStatusLineModifier())
    }    
    ///
    /// Traverses all songs and ask the screen renderer to render them on screen
    ///
    func renderSongs() -> Void {
        // set start y coordinate
        var idx: Int = (PlayerPreferences.viewType == ViewType.Default) ? 5 : 6
        // set row of current moving time = playback item 0
        let timeRow: Int = (PlayerPreferences.viewType == ViewType.Default) ? 5 : 6
        // index into g_playlist
        var index: Int = 0
        // max y
        let max: Int = (PlayerPreferences.viewType == ViewType.Default) ? g_rows-7+5 : g_rows-8+6//? 22 : 21
        // get background color from theme
        let bgColor = getThemeBgColor()
        // while y coordinate is less than max y coordiante
        while idx < max {
            // if index is less than g_playlist.count
            if index < g_playlist.count {
                // get SongEntry from g_playlist[index]
                let s = g_playlist[index]
                // if current y coordinate == timeRow (where current moving time is)
                if idx == timeRow {
                    // if audio player active is -1 
                    if g_player.audioPlayerActive == -1 && g_playlist.count > 0{
                        // render song g_playlist[0]
                        renderSong(idx, s, g_playlist[0].duration)
                    }
                    // else if audio player active is 1
                    else if g_player.audioPlayerActive == 1 {
                        // render song
                        renderSong(idx, s, g_player.durationAudioPlayer1)
                    }
                    // else if audio player active is 2
                    else if g_player.audioPlayerActive == 2 {
                        // render song
                        renderSong(idx, s, g_player.durationAudioPlayer2)
                    }
                }
                // we are rendering items 1 to n, that does not have current playback
                else {
                    // render song
                    renderSong(idx, s, s.duration)
                }
            }
            // we are rendering empty space
            else {
                // if view type == default
                if PlayerPreferences.viewType == ViewType.Default {
                    // render empty line
                    Console.printXY(1, idx, " ", g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                }
                // else view type == details
                else if PlayerPreferences.viewType == ViewType.Details {
                    // render two empty lines
                    Console.printXY(1, idx, " ", g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    Console.printXY(1, idx+1, " ", g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                }
            }
            // if view type == default
            if PlayerPreferences.viewType == ViewType.Default {
                // add y coordinate 
                idx += 1
            }
            else if PlayerPreferences.viewType == ViewType.Details {
                // add y coordinate
                idx += 2
            }
            // next song in playlist, add 1
            index += 1
        }
    }    
    ///
    /// Renders screen output. Does not clear screen first.
    ///
    func renderWindow() -> Void {
        // if size is invalid
        guard isWindowSizeValid() else {        
            // render terminal too small message
            renderTerminalTooSmallMessage()
            // return
            return
        }        
        // render title        
        renderTitle()
        // render songs
        renderSongs()
        // render addendum text
        renderAddendumText()
        // render command line
        renderCommandLine()
        // render status line
        renderStatusLine()
        // goto g_cols, g_rows-3
        Console.gotoXY(g_cols, g_rows-3)
        // print empty string
        print("")
    }    
    ///
    /// Runs this window keyboard input and feedback.
    /// Delegation to other windows and command processing.
    ///
    func run() -> Void {
        // clear screen with current theme backgorund color
        Console.clearScreenCurrentTheme()        
        // render window
        self.renderWindow()                
        // Setup command processing        
        self.commands = [PlayerCommand(commands: [["exit"], ["quit"], ["q"]], closure: self.onCommandExit),
                         PlayerCommand(commands: [["update"], ["cmplayer"]], closure: self.onCommandUpdate),
                         PlayerCommand(commands: [["set", "viewtype"]], closure: self.onCommandSetViewType),
                         PlayerCommand(commands: [["set", "theme"]], closure: self.onCommandSetColorTheme),
                         PlayerCommand(commands: [["next"], ["skip"], ["n"], ["s"]], closure: self.onCommandNextSong),
                         PlayerCommand(commands: [["help"], ["?"]], closure: self.onCommandHelp),
                         PlayerCommand(commands: [["replay"]], closure: self.onCommandReplay),
                         PlayerCommand(commands: [["play"]], closure: self.onCommandPlay),
                         PlayerCommand(commands: [["pause"]], closure: self.onCommandPause),
                         PlayerCommand(commands: [["resume"]], closure: self.onCommandResume),
                         PlayerCommand(commands: [["search", "artist"]], closure: self.onCommandSearchArtist),
                         PlayerCommand(commands: [["search", "title"]], closure: self.onCommandSearchTitle),
                         PlayerCommand(commands: [["search", "album"]], closure: self.onCommandSearchAlbum),
                         PlayerCommand(commands: [["search", "genre"]], closure: self.onCommandSearchGenre),
                         PlayerCommand(commands: [["search", "year"]], closure: self.onCommandSearchYear),
                         PlayerCommand(commands: [["search"]], closure: self.onCommandSearch),
                         PlayerCommand(commands: [["mode", "off"], ["clear", "mode"], ["mo"], ["cm"]], closure: self.onCommandClearMode),
                         PlayerCommand(commands: [["about"]], closure: self.onCommandAbout),
                         PlayerCommand(commands: [["year"]], closure: self.onCommandYear),
                         PlayerCommand(commands: [["goto"]], closure: self.onCommandGoTo),
                         PlayerCommand(commands: [["mode"]], closure: self.onCommandMode),
                         PlayerCommand(commands: [["info"]], closure: self.onCommandInfo),
                         PlayerCommand(commands: [["repaint","redraw"]], closure: self.onCommandRepaint),
                         PlayerCommand(commands: [["add", "mrp"]], closure: self.onCommandAddMusicRootPath),
                         PlayerCommand(commands: [["remove", "mrp"]], closure: self.onCommandRemoveMusicRootPath),
                         PlayerCommand(commands: [["clear", "mrp"]], closure: self.onCommandClearMusicRootPath),
                         PlayerCommand(commands: [["add", "exp"]], closure: self.onCommandAddExclusionPath),
                         PlayerCommand(commands: [["remove", "exp"]], closure: self.onCommandRemoveExclusionPath),
                         PlayerCommand(commands: [["clear", "exp"]], closure: self.onCommandClearExclusionPath),
                         PlayerCommand(commands: [["set", "cft"]], closure: self.onCommandSetCrossfadeTimeInSeconds),
                         PlayerCommand(commands: [["set", "mf"]], closure: self.onCommandSetMusicFormats),
                         PlayerCommand(commands: [["enable", "crossfade"]], closure: self.onCommandEnableCrossfade),
                         PlayerCommand(commands: [["disable", "crossfade"]], closure: self.onCommandDisableCrossfade),
                         PlayerCommand(commands: [["enable", "aos"]], closure: self.onCommandEnableAutoPlayOnStartup),
                         PlayerCommand(commands: [["disable", "aos"]], closure: self.onCommandDisableAutoPlayOnStartup),
                         PlayerCommand(commands: [["reinitialize"]], closure: self.onCommandReinitialize),
                         PlayerCommand(commands: [["rebuild", "songno"]], closure: self.onCommandRebuildSongNo),
                         PlayerCommand(commands: [["genre"]], closure: self.onCommandGenre),
                         PlayerCommand(commands: [["artist"]], closure: self.onCommandArtist),
                         PlayerCommand(commands: [["pref"], ["preferences"]], closure: self.onCommandPreferences),
                         PlayerCommand(commands: [["restart"]], closure: self.onCommandRestart),
                         PlayerCommand(commands: [["p"]], closure: self.onCommandPlayOrPause),
                         PlayerCommand(commands: [["prev"]], closure: self.onCommandPrev),
                         PlayerCommand(commands: [["#"]], closure: self.onCommandAddSongToPlaylist),                         
                         PlayerCommand(commands: [["clear", "history"]], closure: self.onCommandClearHistory),
                         PlayerCommand(commands: [["set", "custom-theme"]], closure: self.onSetColor),
                         PlayerCommand(commands: [["save", "script"]], closure: self.onSaveScript),
                         PlayerCommand(commands: [["load", "script"]], closure: self.onLoadScript),]
    
        // Count down and render songs        
        concurrentQueue1.async {
            // while g_quit flag is false
            while !g_quit {
                // if no windows on top of this window
                if !self.isShowingTopWindow {
                    // if this window is not too small
                    if !self.isTooSmall {
                        // if we are not in terminal change size and not g_doNotPain flag is set
                        if !g_termSizeIsChanging && !g_doNotPaint {
                            // render header
                            MainWindow.renderHeader(showTime: true)
                            // render window
                            self.renderWindow()
                        }
                    }  
                    // window is too small
                    else {
                        // render terminal too small message
                        renderTerminalTooSmallMessage()
                    }                  
                }
                // lock
                g_lock.lock()
                // if g_playlist count is greater than 0
                if g_playlist.count > 0 {
                    // if audio player active == 1
                    if g_player.audioPlayerActive == 1 {
                        // setup a time variable
                        var time: UInt64 = 0
                        // a is audio player 1
                        if let a = g_player.audio1 {
                            // set time to elapsed time from audio player 1
                            time = a.timeElapsed
                        }
                        // if duration of current playing item is greater than or equal to time variable
                        if g_playlist[0].duration >= time {
                            // set current time left for audio player 1 to
                            g_player.durationAudioPlayer1 = (g_playlist[0].duration - time)
                        }
                        // something should not happen
                        else {
                            // set duration audio player 1 to 0
                            g_player.durationAudioPlayer1 = 0
                        }
                    }
                    // else if audio player active is 2
                    else if g_player.audioPlayerActive == 2 {
                        // setup a time variable
                        var time: UInt64 = 0
                        // a is audio player 2
                        if let a = g_player.audio2 {
                            // set time to elapsed time from audio player 2
                            time = a.timeElapsed
                        }
                        // if duration of current playing item is greater than or equal to time variable
                        if g_playlist[0].duration >= time {
                            // set current time left for audio player 2 to
                            g_player.durationAudioPlayer2 = (g_playlist[0].duration - time)
                        }
                        // something should not happen
                        else {
                            // set duration audio player 2 to 0
                            g_player.durationAudioPlayer2 = 0
                        }
                    }
                    // if audio player 1 is active and not nil
                    if g_player.audioPlayerActive == 1 && g_player.audio1 != nil {
                        // if condition for skip to next song is met
                        if (PlayerPreferences.crossfadeSongs && g_player.durationAudioPlayer1 <= PlayerPreferences.crossfadeTimeInSeconds * 1000)
                            || g_player.durationAudioPlayer1 <= 1000                             
                            || g_player.audio1?.hasPlayed == true
                        {
                            // skip to next song
                            g_player.skip(crossfade: PlayerPreferences.crossfadeSongs)
                        }
                    }
                    // else if audio player 2 is active and not nil
                    else if g_player.audioPlayerActive == 2 && g_player.audio2 != nil {
                        // if condition for skip to next song is met
                        if (PlayerPreferences.crossfadeSongs && g_player.durationAudioPlayer2 <= PlayerPreferences.crossfadeTimeInSeconds * 1000)
                            || g_player.durationAudioPlayer2 <= 1000                             
                            || g_player.audio2?.hasPlayed == true
                        {
                            // skip to next song
                            g_player.skip(crossfade: PlayerPreferences.crossfadeSongs)
                        }
                    }                    
                }
                // unlock
                g_lock.unlock()
                // sleep 50 ms
                usleep(useconds_t(50_000))
            }
        }                
        // Keep up-time in header and blink the cursor.        
        concurrentQueue2.async {
            // while g_quit flag is not set
            while !g_quit {              
                // sleep for 150 ms  
                usleep(useconds_t(150_000))
                // add elapsed time
                MainWindow.timeElapsedMs += 150
                // add cursor timeout with 150 ms
                self.cursorTimeout += 150
                // if cursor timeout is greater than 600 ms
                if self.cursorTimeout >= 600 {
                    // set cursor timeout to 0
                    self.cursorTimeout = 0
                    // set showCursor flag to true
                    self.showCursor = true
                }
                // else cursor timeout has not yet reached 600 ms
                else {
                    // set showCursor flag to false
                    self.showCursor = false
                }
            }
        }
        // set keyHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        // add key handler for key down
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            // if command history pop returnes a command
            if let cmd = PlayerCommandHistory.default.pop() {
                // set currentCommand to pop'd command
                self.currentCommand = cmd
                // render command line
                self.renderCommandLine()
            }  
            // do not return from run()      
            return false
        })
        // add key handler for key up
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            // if command history push returnes a command
            if let cmd = PlayerCommandHistory.default.push() {
                // set currentCommand to push'd command
                self.currentCommand = cmd
                // render command line
                self.renderCommandLine()
            }        
            // do not return from run()
            return false
        })
        // add key handler for key left
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            // do not return from run()
            return false
        })
        // add key handler for key right
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in
            // do not return from run()
            return false
        })
        // add key handler for horizontal tab
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_HTAB.rawValue, closure: { () -> Bool in
            // tab means skip, execute command skip
            self.processCommand(command: "skip")
            // do not return from run()
            return false
        })
        // add key handler for shift horizontal tab
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_SHIFT_HTAB.rawValue, closure: { () -> Bool in
            // shift tab means prev, execute command prev
            self.processCommand(command: "prev")
            // do not return from run()
            return false
        })
        // add key handler for enter
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_ENTER.rawValue, closure: { () -> Bool in            
            // if we have a command
            if self.currentCommand.count > 0 {
                // add command to command history
                PlayerCommandHistory.default.add(command: self.currentCommand)
                // process command
                self.processCommand(command: self.currentCommand)                
            }
            // remove current command
            self.currentCommand.removeAll()
            // render command line
            self.renderCommandLine()
            // return status line
            self.renderStatusLine()
            // return g_quit to allow run() to exit if a command exits the application
            return g_quit
        })
        // add key handler for backspace
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_BACKSPACE.rawValue, closure: { () -> Bool in
            // if we have a command
            if self.currentCommand.count > 0 {
                // remove last character
                self.currentCommand.removeLast()
            }
            // do not return from run()
            return false
        })
        // add keyhandler for misc characters typed.
        keyHandler.addCharacterKeyHandler(closure: { (ch: Character) -> Bool in
            // if do not have a command and character is whitespace
            if self.currentCommand.count == 0 && ch.isWhitespace {
                // do not return from run()
                return false
            }
            // add character to currentCommand
            self.currentCommand.append(ch)
            // render comamnd line
            self.renderCommandLine()
            // render status line
            self.renderStatusLine()            
            // do not return from run()
            return false
        })
        // run key handler, do not return from this function until one 
        // - of the key handlers return true
        keyHandler.run()
    }       
    ///
    /// Processes commands
    ///
    /// parameter command: Command string to process
    ///
    /// returns: Bool true if application should exit. False otherwise.
    ///
    func processCommand(command: String) -> Void {
        // log process command
        PlayerLog.ApplicationLog?.logInformation(title: "[MainWindow].processCommand(command:)", text: "Command: \(command)")
        // split parts by space
        let parts = command.components(separatedBy: " ")
        // create and set a flag isHandled to false, true if we have a command handler for the command
        var isHandled = false
        // for each command handler setup
        for cmd in self.commands {
            // try execute command, returns true if current command has handler for the command
            if cmd.execute(command: parts) {
                // we have handled the command, set isHandled flag to true
                isHandled = true
                // discontinue further looping, we have handled the command
                break
            }
        }
        // if did not have any command handlers for the command
        if !isHandled {
            // log event
            PlayerLog.ApplicationLog?.logInformation(title: "[MainWindow].processCommand(command:)", text: "Command NOT Reckognized: \(command)")
        }           
    }    
    ///
    /// Exits the application
    ///
    /// parameter parts: command array.
    ///
    func onCommandExit(parts: [String]) -> Void {
        // set g_quit flag to true, we are exiting the application
        g_quit = true
    }    
    ///
    /// Restarts the application
    ///
    /// parameter parts: command array.
    ///
    func onCommandRestart(parts: [String]) -> Void {
        
    }    
    ///
    /// Sets main window song bg color
    ///
    func onCommandSetColorTheme(parts: [String]) -> Void {
        // if request for color theme change is color theme blue
        if ( parts[0] == "blue" ) {
            PlayerPreferences.colorTheme = ColorTheme.Blue
            PlayerPreferences.savePreferences()
        }
        // else if request for color theme change is color theme black
        else if parts[0] == "black" {
            PlayerPreferences.colorTheme = ColorTheme.Black
            PlayerPreferences.savePreferences()
        }
        // else if request for color theme change is color theme default
        else if parts[0] == "default" {
            PlayerPreferences.colorTheme = ColorTheme.Default
            PlayerPreferences.savePreferences()
        }
        // else if request for color theme change is color theme default
        else if parts[0] == "custom" {
            PlayerPreferences.colorTheme = ColorTheme.Custom
            PlayerPreferences.savePreferences()            
        }
        // render window
        self.renderWindow()
    }    
    /// 
    /// Plays previous song
    /// - Parameter parts:  command array.
    /// 
    func onCommandPrev(parts: [String]) {
        // lock
        g_lock.lock()
        // play previous song
        g_player.prev()
        // unlock
        g_lock.unlock()
    }    
    ///
    /// Sets ViewType on Main Window
    ///
    func onCommandSetViewType(parts: [String]) -> Void {
        // try to set preferences viewType to command argument, if not set it to default
        PlayerPreferences.viewType = ViewType(rawValue: parts[0].lowercased() ) ?? ViewType.Default
        // save preferences
        PlayerPreferences.savePreferences()
        // render frame
        self.renderTitle()
    }    
    ///
    /// Restarts current playing song.
    ///
    /// parameter parts: command array.
    ///
    func onCommandReplay(parts: [String]) -> Void {
        // lock
        g_lock.lock()
        // if player active is 1
        if g_player.audioPlayerActive == 1 {
            // if player 1 is not playing
            if ( !g_player.audio1!.isPlaying ) {
                // resume playing
                g_player.resume()
            }
            // seek to position start of file
            g_player.audio1?.seekToPos(position: g_player.audio1!.duration)
        }
        // else if player active is 2
        else if g_player.audioPlayerActive == 2 {
            // if player 2 is not playing
            if ( !g_player.audio2!.isPlaying ) {
                // resume playing
                g_player.resume()
            }
            // seek to position start of file
            g_player.audio2?.seekToPos(position: g_player.audio2!.duration)
        }
        // unlock
        g_lock.unlock()
    }    
    ///
    /// Play next song
    ///
    /// parameter parts: command array.
    ///
    func onCommandNextSong(parts: [String]) -> Void {
        // lock
        g_lock.lock()
        // skip to next song, do not crossfade
        g_player.skip(crossfade: false)
        // unlock
        g_lock.unlock()
    }    
    ///
    /// Play if not playing.
    ///
    /// parameter parts: command array.
    ///
    func onCommandPlay(parts: [String]) -> Void {
        // if audioPlayerActive == -1
        if g_player.audioPlayerActive == -1 {
            // start playing player 1
            g_player.play(player: 1, playlistIndex: 0)
        }
        // else if player active is 1
        else if g_player.audioPlayerActive == 1 {
            // resume playing
            g_player.resume()
        }
        // else if player active is 2
        else if g_player.audioPlayerActive == 2 {
            // resume playing
            g_player.resume()
        }
    }    
    ///
    /// Pause playback.
    ///
    /// parameter parts: command array.
    ///
    func onCommandPause(parts: [String]) -> Void {
        // pause playback
        g_player.pause()
    }    
    ///
    /// Play or pause playback
    ///
    /// parameter parts: command array.
    ///
    func onCommandPlayOrPause(parts: [String]) -> Void {
        // if audioPlayerActive == -1
        if g_player.audioPlayerActive == -1 {
            // run command play
            self.onCommandPlay(parts: parts)
        }
        // if we are paused
        if g_player.isPaused {
            // resume playback
            g_player.resume()
        }
        // else if we are playing
        else {
            // pause playback
            g_player.pause()
        }        
    }    
    ///
    /// Resume playback.
    ///
    /// parameter parts: command array.
    ///
    func onCommandResume(parts: [String]) -> Void {
        // resume playback
        g_player.resume()
    }    
    ///
    /// Repaint main window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandRepaint(parts: [String]) -> Void {
        // clear screen curren theme colors
        Console.clearScreenCurrentTheme()
        // render window
        self.renderWindow()
    }    
    ///
    /// Add song to playlist
    ///
    /// parameter parts: command array.
    /// parameter songNo: song number to add.
    ///
    func onCommandAddSongToPlaylist(parts: [String]) -> Void {
        // if song identified by number is a valid number
        if let songNo = Int(parts[0]) {
            // for each song in g_songs
            for se in g_songs {
                // if song is song we are looking for
                if se.songNo == songNo {
                    // append this song to playlist
                    g_playlist.append(se)
                    // discontinue loop
                    break
                }
            }
        }
    }    
    ///
    /// Enable crossfade
    ///
    /// parameter parts: command array.
    ///
    func onCommandEnableCrossfade(parts: [String]) -> Void {
        // set PlayerPreferences crossfadeSongs to true
        PlayerPreferences.crossfadeSongs = true
        // save PlayerPreferences
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Disable crossfade.
    ///
    /// parameter parts: command array.
    ///
    func onCommandDisableCrossfade(parts: [String]) -> Void {
        // set PlayerPreferences crossfadeSongs to false
        PlayerPreferences.crossfadeSongs = false
        // save PlayerPreferences
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Enable audoplay on startup and after reinitialize.
    ///
    /// parameter parts: command array.
    ///
    func onCommandEnableAutoPlayOnStartup(parts: [String]) -> Void {
        // set PlayerPreferences autoplayOnStartup to true
        PlayerPreferences.autoplayOnStartup = true
        // save PlayerPreferences
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Disable autoplay on startup and after reinitialize.
    ///
    /// parameter parts: command array.
    ///
    func onCommandDisableAutoPlayOnStartup(parts: [String]) -> Void {
        // set PlayerPreferences autoplayOnStartup to false
        PlayerPreferences.autoplayOnStartup = false
        // save PlayerPreferences
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Add path to root paths.
    ///
    /// parameter parts: command array.
    ///
    func onCommandAddMusicRootPath(parts: [String]) -> Void {
        // get arguments to command
        let nparts = reparseCurrentCommandArguments(parts)
        // create a variable for if argument is a directory
        var isDir: ObjCBool = false
        // check if path exists and is a directory
        // nparts[0] == path
        if FileManager.default.fileExists(atPath: nparts[0], isDirectory: &isDir) {
            // is path a diectory
            if isDir.boolValue  {
                // yes is a directory
                // add to PlayerPreferences musicRootPath
                PlayerPreferences.musicRootPath.append(nparts[0])
                // save PlayerPreferences
                PlayerPreferences.savePreferences()
            }
        }
    }    
    ///
    /// Add path to exclusion paths.
    ///
    /// parameter parts: command array.
    ///
    func onCommandAddExclusionPath(parts: [String]) -> Void {
        // get arguments to command
        let nparts = reparseCurrentCommandArguments(parts)
        // create a variable for if argument is a directory
        var isDir: ObjCBool = false
        // check if path exists and is a directory
        // nparts[0] == path
        if FileManager.default.fileExists(atPath: nparts[0], isDirectory: &isDir) {
            // is path a diectory
            if isDir.boolValue  {
                // yes is a directory
                // add to PlayerPreferences exclution paths
                PlayerPreferences.exclusionPaths.append(nparts[0])
                // save PlayerPreferences
                PlayerPreferences.savePreferences()
            }
        }
    }    
    ///
    /// Remove root path.
    ///
    /// parameter parts: command array.
    ///
    func onCommandRemoveMusicRootPath(parts: [String]) -> Void {
        // get arguments to command
        let nparts = reparseCurrentCommandArguments(parts)
        // create a variable i (index) into PlayerPreferenes.musicRootPath
        var i: Int = 0
        // loop through all PlayerPreferences.musicRootPath
        while i < PlayerPreferences.musicRootPath.count {
            // if we find nparts[0] = path
            if PlayerPreferences.musicRootPath[i] == nparts[0] {
                // remove path from PlayerPreferences.musicRootPath
                PlayerPreferences.musicRootPath.remove(at: i)
                // save PlayerPreferences
                PlayerPreferences.savePreferences()
                // discontinue loop
                break
            }
            // add one to index
            i += 1
        }
    }    
    ///
    /// Remove exclustion path.
    ///
    /// parameter parts: command array.
    ///
    func onCommandRemoveExclusionPath(parts: [String]) -> Void {
        // get arguments to command
        let nparts = reparseCurrentCommandArguments(parts)
        // create a variable i (index) into PlayerPreferenes.exclutionPaths
        var i: Int = 0
        // loop through all PlayerPreferences.exclutionPaths
        while i < PlayerPreferences.exclusionPaths.count {
            // if we find nparts[0] = path
            if PlayerPreferences.exclusionPaths[i] == nparts[0] {
                // remove path from PlayerPreferences.exclutionPaths
                PlayerPreferences.exclusionPaths.remove(at: i)
                // save PlayerPreferences
                PlayerPreferences.savePreferences()
                // discontinue loop
                break
            }
            // add one to index
            i += 1
        }
    }    
    ///
    /// Set crossfade time in seconds.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSetCrossfadeTimeInSeconds(parts: [String]) -> Void {
        // create and check ctis constand for a number argument
        if let ctis = Int(parts[0]) {
            // if ctis is a valid number of seconds for crossfade
            if isCrossfadeTimeValid(seconds: ctis) {
                // set PlayerPreferences.crossfadeTimeInSeconds
                PlayerPreferences.crossfadeTimeInSeconds = ctis
                // save PlayerPreferences
                PlayerPreferences.savePreferences()
            }
        }
    }    
    ///
    /// Set music formats.
    /// THIS COMMAND IS NO LONG AVAILABLE.
    /// MUSIC FORMATS SUPPORTED ARE HARD CODED INTO CMPLAYER.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSetMusicFormats(parts: [String]) -> Void {        
        //PlayerPreferences.musicFormats = parts[0]
        //PlayerPreferences.savePreferences()
    }    
    ///
    /// Goto playback point of current playing item.
    ///
    /// parameter parts: command array.
    ///
    func onCommandGoTo(parts: [String]) -> Void {
        // create a constant tp with time mm, ss
        let tp = parts[0].split(separator: ":" )
        // if count == 2, which we expect
        if tp.count == 2 {
            // if part 1 of tp is a number, as we expect
            if let time1 = Int(tp[0]) {
                // if part 2 of tp is a number, as we expect
                if let time2 = Int(tp[1]) {
                    // if time1 and time2 are valid numbers
                    if time1 >= 0 && time2 >= 0 && time2 < 60 {
                        // convert time1 and time2 to seconds = pos
                        let pos: Int = time1*60 + time2
                        // if pos < 0 return
                        guard pos >= 0 else {
                            return;
                        }
                        // get posMs = pos in milliseconds
                        let posMs: UInt64 = UInt64(pos * 1000)
                        // if audio player active is 1
                        if g_player.audioPlayerActive == 1 {                              
                            // if posMs < player1 duration
                            if posMs <= g_player.audio1!.duration {                                
                                // seek to position
                                g_player.audio1?.seekToPos(position: posMs)
                            }
                        }
                        // else if audio player active is 2
                        else if g_player.audioPlayerActive == 2 {                             
                            // if posMs < player2 duration
                            if posMs <= g_player.audio2!.duration {                                
                                // seek to position
                                g_player.audio2?.seekToPos(position: posMs)
                            }
                        }
                    }
                }
            }
        }
    }    
    ///
    /// Clears any search mode
    ///
    /// parameter parts: command arrary
    ///
    func onCommandClearMode(parts: [String]) -> Void {       
        // lock 
        g_lock.lock()
        // clear search type
        g_searchType.removeAll()
        // clear search result
        g_searchResult.removeAll()
        // clear mode search
        g_modeSearch.removeAll()
        // clear mode search stats
        g_modeSearchStats.removeAll()
        // unlock
        g_lock.unlock()
    }
    ///
    /// Show info on given song number.
    ///
    /// parameter parts: command array.
    ///
    func onCommandInfoSong(parts: [String]) -> Void {
        // if argument is song no and is a number
        if let sno = Int(parts[0]) {
            // if sno is a number greater than 0
            if sno > 0 {
                // for each songentry in g_songs
                for s in g_songs {
                    // if entry songno is equal to sno
                    if s.songNo == sno {
                        // set isShowingTopWindow flag to true
                        self.isShowingTopWindow = true
                        // create InfoWindow
                        let wnd: InfoWindow = InfoWindow()
                        // set song entry
                        wnd.song = s
                        // show window, modal call
                        wnd.showWindow()
                        // clear screen current theme
                        Console.clearScreenCurrentTheme()
                        // render this window
                        self.renderWindow()
                        // set isShowingTopWindow flag to false                        
                        self.isShowingTopWindow = false
                        // discontinue loop
                        break
                    }
                }
            }
        }
    }    
    ///
    /// Show help window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandHelp(parts: [String]) -> Void {
        // set isShowingTopWindow flag to true
        self.isShowingTopWindow = true
        // create a HelpWindow
        let wnd: HelpWindow = HelpWindow()
        // show the help window, modal call
        wnd.showWindow()
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // set isShowingTopWindow flag to false
        self.isShowingTopWindow = false
    }    
    ///
    /// Clear music root paths.
    ///
    /// parameter parts: command array.
    ///
    func onCommandClearMusicRootPath(parts: [String]) -> Void {
        // clear PlayerPreferences.musicRootPath
        PlayerPreferences.musicRootPath.removeAll()
        // save PlayerPreferences
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Clear music root paths.
    ///
    /// parameter parts: command array.
    ///
    func onCommandClearExclusionPath(parts: [String]) -> Void {
        // clear PlayerPreferences.exclutionPaths
        PlayerPreferences.exclusionPaths.removeAll()
        // save PlayerPreferences
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Show about window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandAbout(parts: [String]) -> Void {
        // set isShowingTopWindow flag to true
        self.isShowingTopWindow = true
        // create AboutWindow
        let wnd: AboutWindow = AboutWindow()
        // show about window, modal call
        wnd.showWindow()
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // set isShowingTopWindow flag to false
        self.isShowingTopWindow = false
    }    
    ///
    /// Show artist window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandArtist(parts: [String]) -> Void {
        // set isShowingTopWindow flag to true
        self.isShowingTopWindow = true
        // create ArtistWindow
        let wnd: ArtistWindow = ArtistWindow()
        // show artist window, modal call
        wnd.showWindow()
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // set isShowingTopWindow flag to false
        self.isShowingTopWindow = false
    }    
    ///
    /// Show genre window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandGenre(parts: [String]) -> Void {
        // set isShowingTopWindow flag to true
        self.isShowingTopWindow = true
        // create GenreWindow
        let wnd: GenreWindow = GenreWindow()
        // show genre window, modal call
        wnd.showWindow()
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // set isShowingTopWindow flag to false
        self.isShowingTopWindow = false
    }    
    ///
    /// Show mode window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandMode(parts: [String]) -> Void {
        // set isShowingTopWindow flag to true
        self.isShowingTopWindow = true
        // create ModeWindow
        let wnd: ModeWindow = ModeWindow()
        // show mode window, modal call
        wnd.showWindow()
        // clear screen curren theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // set isShowingTopWindow flag to false
        self.isShowingTopWindow = false
    }
    ///
    /// Show info window about current playing item.
    ///
    /// parameter parts: command array.
    ///
    func onCommandInfo(parts: [String]) -> Void {
        // if command parts has 1 element
        if parts.count == 1 {
            // render info song
            self.onCommandInfoSong(parts: parts)
            // return
            return
        }
        // set isShowingTopWindow flag to true
        self.isShowingTopWindow = true
        // create InfoWindow
        let wnd: InfoWindow = InfoWindow()
        // lock
        g_lock.lock()
        // get currently playing song, first item in playlist.
        let song = g_playlist[0]
        // unlock
        g_lock.unlock()
        // set song to info window
        wnd.song = song
        // show info window, modal call
        wnd.showWindow()
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // set isShowingTopWindow to false
        self.isShowingTopWindow = false
    }    
    ///
    /// Reinitialize library and player.
    ///
    /// parameter parts: command array.
    ///
    func onCommandReinitialize(parts: [String]) -> Void {
        // pause playback
        g_player.pause()
        // lock
        g_lock.lock()
        // clear g_searchType
        g_searchType.removeAll()
        // clear g_genres
        g_genres.removeAll()
        // clear g_artists
        g_artists.removeAll()
        // clear g_recordingYears
        g_recordingYears.removeAll()
        // clear g_serachResult
        g_searchResult.removeAll()
        // clear g_modeSearch
        g_modeSearch.removeAll()
        // clear g_modeSearchStats
        g_modeSearchStats.removeAll()
        // clear g_songs
        g_songs.removeAll()
        // clear g_playlist
        g_playlist.removeAll()
        // create backup of g_library
        let backupLibrary: PlayerLibrary = PlayerLibrary()
        // backup of all the songs
        backupLibrary.library = g_library.library
        // backup of dictionary
        backupLibrary.dictionary = g_library.dictionary
        // set backup next available song no
        backupLibrary.setNextAvailableSongNo(g_library.nextAvailableSongNo())        
        // set library to empty array
        g_library.library.removeAll()
        // set library dictionary empty
        g_library.dictionary.removeAll()        
        // save library
        g_library.save()
        // set next available song to 1, we are starting over
        g_library.setNextAvailableSongNo(1)
        // set audio player active to -1, restart player
        g_player.audioPlayerActive = -1
        // set audio player 1 to nil, restart player
        g_player.audio1 = nil
        // set audio player 2 to nil, restart player
        g_player.audio2 = nil
        // if music root path have 0 items
        if PlayerPreferences.musicRootPath.count == 0 {
            // set isShowingTopWindow flag to true
            self.isShowingTopWindow = true
            // create SetupWindow
            let wndS: SetupWindow = SetupWindow()
            // show setup window, modal call.
            wndS.showWindow()
            // set isShowingTopWindow flag to true again
            self.isShowingTopWindow = true
            // create InitializeWindow
            let wndI = InitializeWindow()
            // show setup window, modal call
            wndI.showWindow()
        }
        // we have music root path
        else {            
            // set isShowingTopWindow flag to true
            self.isShowingTopWindow = true
            // create InitializeWindow            
            let wnd = InitializeWindow(backup: backupLibrary)
            // show initialize window, modal call.
            wnd.showWindow()
        }
        // set isShowingTopWindow flag to false
        self.isShowingTopWindow = false
        // get command arguments
        let nparts = reparseCurrentCommandArguments(parts)
        // if we have argument "1", rebuild song no from 1
        if nparts.count == 1 && nparts[0] == "1" {            
            // rebuild song numbers and rebuild library and save library
            self.onCommandRebuildSongNo(parts: parts)        
        }
        else {
            // rebuild all data structures from newly loaded g_songs
            g_library.rebuild()
            // save library
            g_library.save()        
        }
        // render this window
        self.renderWindow()
        // unlock
        g_lock.unlock()
        // start playing again if PlayerPreferences.autoPlayOnStartup is true
        g_player.skip(play: PlayerPreferences.autoplayOnStartup)
    }    
    ///
    /// Rebuild song numbers.
    ///
    /// parameter parts: command array.
    ///
    func onCommandRebuildSongNo(parts: [String]) -> Void {
        // create song index variable, start with 1
        var i: Int = 1
        // for each SongEntry in g_songs
        for s in g_songs {
            // set song no to i
            s.songNo = i
            // increase i with 1
            i += 1
        }
        // set next available song no
        g_library.setNextAvailableSongNo(i)
        // rebuild library
        g_library.rebuild()
        // save library with updated song no
        g_library.save()
    }    
    ///
    /// Show preferences window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandPreferences(parts: [String]) -> Void {
        // set isShowingTopWindow flag to true
        self.isShowingTopWindow = true
        // create PreferencesWindow
        let wnd: PreferencesWindow = PreferencesWindow()
        // show preferences window, modal call.
        wnd.showWindow()
        // clear screen curren theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // set isShowingTopWindow flag to false
        self.isShowingTopWindow = false
    }    
    ///
    /// Show year window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandYear(parts: [String]) -> Void {
        // set isShowingTopWindow flag to true
        self.isShowingTopWindow = true
        // create YearWindow
        let wnd: YearWindow = YearWindow()
        // show year window, modal call.
        wnd.showWindow()
        // clear screen current theme.
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // set isShowingTopWindow flag to false
        self.isShowingTopWindow = false
    }    
    ///
    /// Show search window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSearch(parts: [String]) -> Void {
        // get command arguments
        let nparts = reparseCurrentCommandArguments(parts)
        // if arguments has values
        if nparts.count > 0 {
            // set isShowingTopWindow flag to true
            self.isShowingTopWindow = true
            // create SearchWindow
            let wnd: SearchWindow = SearchWindow()
            // set command arguments to search window
            wnd.parts = nparts
            // set what type of search is to be done.
            wnd.type = SearchType.ArtistOrTitle
            // show search window, modal call.
            wnd.showWindow()
            // clear screen current theme
            Console.clearScreenCurrentTheme()
            // render this window
            self.renderWindow()
            // set isShowingTopeWindow flag to false
            self.isShowingTopWindow = false
        }
    }    
    ///
    /// Show search window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSearchArtist(parts: [String]) -> Void {
        // get command arguments
        let nparts = reparseCurrentCommandArguments(parts)
        // if command arguments has values
        if nparts.count > 0 {
            // set isShowingTopWindow flag to true
            self.isShowingTopWindow = true
            // create SearchWindow
            let wnd: SearchWindow = SearchWindow()
            // set command arguments to search window
            wnd.parts = nparts
            // set what type of search is to be done
            wnd.type = SearchType.Artist
            // show search window, modal call.
            wnd.showWindow()
            // clear screen current theme
            Console.clearScreenCurrentTheme()
            // render this window
            self.renderWindow()
            // set isShowingTopWindow flag to false
            self.isShowingTopWindow = false
        }
    }    
    ///
    /// Show search window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSearchTitle(parts: [String]) -> Void {
        // get command arguments
        let nparts = reparseCurrentCommandArguments(parts)
        // if command arguments has values
        if nparts.count > 0 {
            // set isShowingTopWindow flag to true
            self.isShowingTopWindow = true
            // create SearchWindow
            let wnd: SearchWindow = SearchWindow()
            // set command arguments to search window
            wnd.parts = nparts
            // set what type of search is to be done
            wnd.type = SearchType.Title
            // show search window, modal call.
            wnd.showWindow()
            // clear screen current theme
            Console.clearScreenCurrentTheme()
            // render this window
            self.renderWindow()
            // set isShowingTopWindow flag to false
            self.isShowingTopWindow = false
        }
    }    
    ///
    /// Show search window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSearchAlbum(parts: [String]) -> Void {
        // get command arguments
        let nparts = reparseCurrentCommandArguments(parts)
        // if command arguments has values
        if nparts.count > 0 {
            // set isShowingTopWindow flag to true
            self.isShowingTopWindow = true
            // create SearchWindow
            let wnd: SearchWindow = SearchWindow()
            // set command arguments to search window
            wnd.parts = nparts
            // set what type of search is to be done
            wnd.type = SearchType.Album
            // show search window, modal call.
            wnd.showWindow()
            // clear screen current theme
            Console.clearScreenCurrentTheme()
            // render this window
            self.renderWindow()
            // set isShowingTopWindow flag to false
            self.isShowingTopWindow = false
        }
    }    
    ///
    /// Show search window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSearchGenre(parts: [String]) -> Void {
        // get command arguments
        let nparts = reparseCurrentCommandArguments(parts)
        // if command arguments has values
        if nparts.count > 0 {
            // set isShowingTopWindow flag to true
            self.isShowingTopWindow = true
            // create SearchWindow
            let wnd: SearchWindow = SearchWindow()
            // set command arguments to search window
            wnd.parts = nparts
            // set what type of search is to be done
            wnd.type = SearchType.Genre
            // show search window, modal call.
            wnd.showWindow()
            // clear screen curren theme
            Console.clearScreenCurrentTheme()
            // render this window
            self.renderWindow()
            // set isShowingTopWindow flag to false
            self.isShowingTopWindow = false
        }
    }    
    ///
    /// Show search window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSearchYear(parts: [String]) -> Void {
        // get command arguments
        let nparts = reparseCurrentCommandArguments(parts)
        // if command arguments has values
        if nparts.count > 0 {
            // set isShowingTopWindow flag to true
            self.isShowingTopWindow = true
             // create SearchWindow
            let wnd: SearchWindow = SearchWindow()
             // set command arguments to search window
            wnd.parts = nparts
            // set what type of search is to be done
            wnd.type = SearchType.RecordedYear
            // show search window, modal call.
            wnd.showWindow()
             // clear screen curren theme
            Console.clearScreenCurrentTheme()
            // render this window
            self.renderWindow()
            // set isShowingTopWindow flag to false
            self.isShowingTopWindow = false
        }
    }    
    ///
    /// Updates CMPlayer if newer version is available then exits, updates, and starts again.
    ///
    /// parameter parts: command array.
    ///
    func onCommandUpdate(parts: [String]) -> Void {
        
    }        
    ///
    /// Enable crossfade
    ///
    /// parameter parts: command array.
    ///
    func onCommandClearHistory(parts: [String]) -> Void {
        do {
            // try to clear command history
            try PlayerCommandHistory.default.clear()
        }
        catch {

        }
    }

    func onSetColor(parts: [String]) -> Void {
        // check we have two arguments
        // command is:> set custom-theme <name-to-change> <value1>         
        if parts.count == 2 
        {
            switch parts[0] {
                case "separatorChar":
                    PlayerPreferences.separatorChar = String(parts[1].first!)
                default:
                    return
            }   
            PlayerPreferences.savePreferences()         
            return
        }
        // command is:> set custom-theme <name-to-change> <value1> <value2> 
        if parts.count != 3 {
            return;
        }
        // set colors/modifiers
        switch parts[0] {
            case "fgHeaderColor": 
                PlayerPreferences.fgHeaderColor = ConsoleColor.itsFromString(parts[1], .white)
                PlayerPreferences.fgHeaderModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)
            case "bgHeaderColor":
                PlayerPreferences.bgHeaderColor = ConsoleColor.itsFromString(parts[1], .blue)
                PlayerPreferences.bgHeaderModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)            
            case "fgTitleColor":
                PlayerPreferences.fgTitleColor = ConsoleColor.itsFromString(parts[1], .yellow)
                PlayerPreferences.fgTitleModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)
            case "bgTitleColor":
                PlayerPreferences.bgTitleColor = ConsoleColor.itsFromString(parts[1], .black)
                PlayerPreferences.bgTitleModifier = ConsoleColorModifier.itsFromString(parts[2], .none)            
            case "fgSeparatorColor":
                PlayerPreferences.fgSeparatorColor = ConsoleColor.itsFromString(parts[1], .green)
                PlayerPreferences.fgSeparatorModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)            
            case "bgSeparatorColor":
                PlayerPreferences.bgSeparatorColor = ConsoleColor.itsFromString(parts[1], .black)
                PlayerPreferences.bgSeparatorModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)                        
            case "fgQueueColor":
                PlayerPreferences.fgQueueColor = ConsoleColor.itsFromString(parts[1], .white)
                PlayerPreferences.fgQueueModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)            
            case "bgQueueColor":
                PlayerPreferences.bgQueueColor = ConsoleColor.itsFromString(parts[1], .blue)
                PlayerPreferences.bgQueueModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)                        
            case "fgQueueSongNoColor":
                PlayerPreferences.fgQueueSongNoColor = ConsoleColor.itsFromString(parts[1], .cyan)
                PlayerPreferences.fgQueueSongNoModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)                        
            case "bgQueueSongNoColor":
                PlayerPreferences.bgQueueSongNoColor = ConsoleColor.itsFromString(parts[1], .blue)
                PlayerPreferences.bgQueueSongNoModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)                                    
            case "fgCommandLineColor":
                PlayerPreferences.fgCommandLineColor = ConsoleColor.itsFromString(parts[1], .cyan)
                PlayerPreferences.fgCommandLineModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)                                    
            case "bgCommandLineColor":
                PlayerPreferences.bgCommandLineColor = ConsoleColor.itsFromString(parts[1], .black)
                PlayerPreferences.bgCommandLineModifier = ConsoleColorModifier.itsFromString(parts[2], .none)
            case "fgStatusLineColor":
                PlayerPreferences.fgStatusLineColor = ConsoleColor.itsFromString(parts[1], .white)
                PlayerPreferences.fgStatusLineModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)
            case "bgStatusLineColor":
                PlayerPreferences.bgStatusLineColor = ConsoleColor.itsFromString(parts[1], .black)
                PlayerPreferences.bgStatusLineModifier = ConsoleColorModifier.itsFromString(parts[2], .none)
            case "fgAddendumColor":
                PlayerPreferences.fgAddendumColor = ConsoleColor.itsFromString(parts[1], .white)
                PlayerPreferences.fgAddendumModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)            
            case "bgAddendumColor":
                PlayerPreferences.bgAddendumColor = ConsoleColor.itsFromString(parts[1], .black)
                PlayerPreferences.bgAddendumModifier = ConsoleColorModifier.itsFromString(parts[2], .none)
            case "fgEmptySpaceColor":
                PlayerPreferences.fgEmptySpaceColor = ConsoleColor.itsFromString(parts[1], .white)
                PlayerPreferences.fgEmptySpaceModifier = ConsoleColorModifier.itsFromString(parts[2], .bold)                        
            case "bgEmptySpaceColor":
                PlayerPreferences.bgEmptySpaceColor = ConsoleColor.itsFromString(parts[1], .black)
                PlayerPreferences.bgEmptySpaceModifier = ConsoleColorModifier.itsFromString(parts[2], .none)            
            default: 
                return                
        }
        // save preferences
        PlayerPreferences.savePreferences()
    }

    func onSaveScript(parts: [String]) -> Void {
        // command is:> save script <name>
        if parts.count != 1 {
            return;
        }        

        do {
            // create constant script module
            let script: ScriptModule = try ScriptModule(filename: parts[0])
            // add all script items
            script.addStatement("set viewtype \(PlayerPreferences.viewType.rawValue)")
            script.addStatement("set theme \(PlayerPreferences.colorTheme.rawValue)")            
            // create a index variable i
            var i: Int = 0
            // loop through all SearchType in g_searchType
            for type in g_searchType {
                var modeStatement: String = ""
                // append search type name to modeText
                modeStatement = "search \(type.rawValue)"
                // loop through g_modeSearch
                for j in 0..<g_modeSearch[i].count {
                    // append mode search and search songs count
                    modeStatement += " \"\(g_modeSearch[i][j])\""
                }
                // increase index variable by 1
                i += 1
                script.addStatement(modeStatement)
            }            
            if PlayerPreferences.colorTheme == ColorTheme.Custom {
                script.addStatement("set custom-theme fgHeaderColor \(PlayerPreferences.fgHeaderColor.itsToString()) \(PlayerPreferences.fgHeaderModifier.itsToString())")
                script.addStatement("set custom-theme bgHeaderColor \(PlayerPreferences.bgHeaderColor.itsToString()) \(PlayerPreferences.bgHeaderModifier.itsToString())")                
                script.addStatement("set custom-theme fgTitleColor \(PlayerPreferences.fgTitleColor.itsToString()) \(PlayerPreferences.fgTitleModifier.itsToString())")
                script.addStatement("set custom-theme bgTitleColor \(PlayerPreferences.bgTitleColor.itsToString()) \(PlayerPreferences.bgTitleModifier.itsToString())")                
                script.addStatement("set custom-theme fgSeparatorColor \(PlayerPreferences.fgSeparatorColor.itsToString()) \(PlayerPreferences.fgSeparatorModifier.itsToString())")
                script.addStatement("set custom-theme bgSeparatorColor \(PlayerPreferences.bgSeparatorColor.itsToString()) \(PlayerPreferences.bgSeparatorModifier.itsToString())")
                script.addStatement("set custom-theme fgQueueColor \(PlayerPreferences.fgQueueColor.itsToString()) \(PlayerPreferences.fgQueueModifier.itsToString())")
                script.addStatement("set custom-theme bgQueueColor \(PlayerPreferences.bgQueueColor.itsToString()) \(PlayerPreferences.bgQueueModifier.itsToString())")
                script.addStatement("set custom-theme fgQueueSongNoColor \(PlayerPreferences.fgQueueSongNoColor.itsToString()) \(PlayerPreferences.fgQueueSongNoModifier.itsToString())")
                script.addStatement("set custom-theme bgQueueSongNoColor \(PlayerPreferences.bgQueueSongNoColor.itsToString()) \(PlayerPreferences.bgQueueSongNoModifier.itsToString())")
                script.addStatement("set custom-theme fgCommandLineColor \(PlayerPreferences.fgCommandLineColor.itsToString()) \(PlayerPreferences.fgCommandLineModifier.itsToString())")
                script.addStatement("set custom-theme bgCommandLineColor \(PlayerPreferences.bgCommandLineColor.itsToString()) \(PlayerPreferences.bgCommandLineModifier.itsToString())")
                script.addStatement("set custom-theme fgStatusLineColor \(PlayerPreferences.fgStatusLineColor.itsToString()) \(PlayerPreferences.fgStatusLineModifier.itsToString())")
                script.addStatement("set custom-theme bgStatusLineColor \(PlayerPreferences.bgStatusLineColor.itsToString()) \(PlayerPreferences.bgStatusLineModifier.itsToString())")
                script.addStatement("set custom-theme fgAddendumColor \(PlayerPreferences.fgAddendumColor.itsToString()) \(PlayerPreferences.fgAddendumModifier.itsToString())")
                script.addStatement("set custom-theme bgAddendumColor \(PlayerPreferences.bgAddendumColor.itsToString()) \(PlayerPreferences.bgAddendumModifier.itsToString())")
                script.addStatement("set custom-theme fgEmptySpaceColor \(PlayerPreferences.fgEmptySpaceColor.itsToString()) \(PlayerPreferences.fgEmptySpaceModifier.itsToString())")
                script.addStatement("set custom-theme bgEmptySpaceColor \(PlayerPreferences.bgEmptySpaceColor.itsToString()) \(PlayerPreferences.bgEmptySpaceModifier.itsToString())")
            }
            // save script
            try script.save()
        } 
        catch let error as CmpError {
            // create error message
            let msg = "Error loading script. Message: \(error.message)"
            // log error message
            PlayerLog.ApplicationLog?.logError(title: "[MainWindow].onLoadScript(parts)", text: msg)
        }
        catch {
            // create error message
            let msg = "Unknown error loading script. Message: \(error)"
            // log error message
            PlayerLog.ApplicationLog?.logError(title: "[MainWindow].onLoadScript(parts)", text: msg)
        }
    }

    func onLoadScript(parts: [String]) -> Void {    
        // command is:> load script <name>
        if parts.count != 1 {
            return;
        }

        g_assumeSearchMode = true
        do {
            let script: ScriptModule = try ScriptModule(filename: parts[0])
            try script.load()

            // for each statement in script module
            for s in script.statements {
                // process command
                self.processCommand(command: s)  
            }
        }         
        catch let error as CmpError {
            // create error message
            let msg = "Error loading script. Message: \(error.message)"
            // log error message
            PlayerLog.ApplicationLog?.logError(title: "[MainWindow].onLoadScript(parts)", text: msg)
        }
        catch {
            // create error message
            let msg = "Unknown error loading script. Message: \(error)"
            // log error message
            PlayerLog.ApplicationLog?.logError(title: "[MainWindow].onLoadScript(parts)", text: msg)
        }
        g_assumeSearchMode = false
    }
}// MainWindow
