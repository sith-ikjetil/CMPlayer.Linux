//////////////////////////////////////////////////////////////
//: Filename    : MainWindow.swift
//: Date        : 2024-09-24
//: Author      : "Kjetil Kristoffer Solberg" <post@ikjetil.no>
//: Version     : 
//: Description : Console Music Player main window.
//
// import
//
import Foundation
///
/// Represents CMPlayer MainWindow.
///
internal class MainWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    ///
    /// static private variables
    /// 
    static private var timeElapsedMs: UInt64 = 0   
    //
    // private variables
    //        
    private var currentCommand: String = ""
    private var commands: [PlayerCommand] = []    
    private var isShowingTopWindow = false
    private var addendumText: String = ""
    private var updateFileName: String = ""
    private var isTooSmall: Bool = false
    private var showCursor: Bool = false
    private var cursorTimeout: UInt64 = 0    
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
        // set header background color
        let bgColor = ConsoleColor.blue
        // if we show time render this
        if showTime {
            Console.printXY(1,1,"CMPlayer | v\(g_versionString) | \(itsRenderMsToFullString(MainWindow.timeElapsedMs, false))", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        }
        // else we render this without time
        else {
            Console.printXY(1,1,"CMPlayer | v\(g_versionString)", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        }
    }    
    ///
    /// Renders main window frame on screen
    ///
    func renderFrame() -> Void {
        // render header
        MainWindow.renderHeader(showTime: true)
        // set background color from theme
        let bgColor = getThemeBgColor()
        // render blank line y = 2
        Console.printXY(1,2," ", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // render default view
        if PlayerPreferences.viewType == ViewType.Default {  
            // get layout info
            let layout: MainWindowLayout = MainWindowLayout.get()    
            // render song no header
            Console.printXY(layout.songNoX,3,"Song No.", layout.songNoCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)                    
            // render artist header
            Console.printXY(layout.artistX,3,"Artist", layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            // render title header
            Console.printXY(layout.titleX,3,"Title", layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            // render time header
            Console.printXY(layout.durationX,3,"Time", layout.durationCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            // render separator line
            Console.printXY(1,4,"=", g_cols, .left, "=", bgColor, ConsoleColorModifier.none, ConsoleColor.green, ConsoleColorModifier.bold)
        }
        // else render details view
        else if PlayerPreferences.viewType == ViewType.Details {
            // get layout info
            let layout: MainWindowLayout = MainWindowLayout.get()    
            // render song no and empty header
            Console.printXY(1,3,"Song No.", layout.songNoCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            Console.printXY(1,4," ", layout.songNoCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)                        
            // render artist and album name header
            Console.printXY(layout.artistX,3,"Artist", layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            Console.printXY(layout.artistX,4,"Album Name", layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            // render title and genre header
            Console.printXY(layout.titleX,3,"Title", layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            Console.printXY(layout.titleX,4,"Genre", layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            // render time and empty header
            Console.printXY(layout.durationX,3,"Time", layout.durationCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            Console.printXY(layout.durationX,4," ", layout.durationCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            // render separator line
            Console.printXY(1,5,"=", g_cols, .left, "=", bgColor, ConsoleColorModifier.none, ConsoleColor.green, ConsoleColorModifier.bold)
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
        // get background color from current theme
        let bgColor = getThemeSongBgColor()
        // set song no color
        let songNoColor = ConsoleColor.cyan
        // if viewtype is set to default
        if PlayerPreferences.viewType == ViewType.Default {
            // get layout info
            let layout: MainWindowLayout = MainWindowLayout.get() 
            // render song no
            Console.printXY(layout.songNoX, y, "\(song.songNo) ", layout.songNoCols, .right, " ", bgColor, ConsoleColorModifier.none, songNoColor, ConsoleColorModifier.bold)
            // render artist
            Console.printXY(layout.artistX, y, song.getArtist(), layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)            
            // render title
            Console.printXY(layout.titleX, y, song.getTitle(), layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            // set time string
            let timeString: String = itsRenderMsToFullString(time, false)
            let endTimePart: String = String(timeString[timeString.index(timeString.endIndex, offsetBy: -5)..<timeString.endIndex])
            // render duration left
            Console.printXY(layout.durationX, y, endTimePart, layout.durationCols, .ignore, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        }
        // if viewtype is set to details
        else if PlayerPreferences.viewType == ViewType.Details {
            // get layout info
            let layout: MainWindowLayout = MainWindowLayout.get() 
            // render song no and empty field
            Console.printXY(layout.songNoX, y, "\(song.songNo) ", layout.songNoCols, .right, " ", bgColor, ConsoleColorModifier.none, songNoColor, ConsoleColorModifier.bold)
            Console.printXY(layout.songNoX, y+1, " ", layout.songNoCols, .right, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            // render artist and album name
            Console.printXY(layout.artistX, y, song.getArtist(), layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            Console.printXY(layout.artistX, y+1, song.getAlbumName(), layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            // render title and genre
            Console.printXY(layout.titleX, y, song.getTitle(), layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            Console.printXY(layout.titleX, y+1, song.getGenre(), layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            // set time string
            let timeString: String = itsRenderMsToFullString(time, false)
            let endTimePart: String = String(timeString[timeString.index(timeString.endIndex, offsetBy: -5)..<timeString.endIndex])
            // render duration and empty field
            Console.printXY(layout.durationX, y, endTimePart, layout.durationCols, .ignore, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)            
            Console.printXY(layout.durationX, y+1, " ", layout.durationCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        }
    }
    /// 
    /// renders addendum text at g_rows-2
    ///     
    func renderAddendumText() -> Void {
        // render addendum text from self.addendumText
        Console.printXY(1,g_rows-2, (self.addendumText.count > 0) ? self.addendumText : " ", g_cols, .left, " ", getThemeBgColor(), ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.none)
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
        Console.printXY(1,g_rows-1,">: \(text)\(cursor)", g_cols, .left, " ", getThemeBgColor(), ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
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
        Console.printXY(1,g_rows, text, g_cols, .center, " ", getThemeBgColor(), ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
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
        // render frame        
        renderFrame()
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
    /// Runs MainWindow keyboard input and feedback. Delegation to other windows and command processing.
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
                         PlayerCommand(commands: [["clear", "history"]], closure: self.onCommandClearHistory),]                
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
        PlayerLog.ApplicationLog?.logInformation(title: "[MainWindow].processCommand(command:)", text: "Command: \(command)")
        
        let parts = command.components(separatedBy: " ")
        
        var isHandled = false
        for cmd in self.commands {
            if cmd.execute(command: parts) {
                isHandled = true
                break
            }
        }
                    
        if !isHandled {
            PlayerLog.ApplicationLog?.logInformation(title: "[MainWindow].processCommand(command:)", text: "Command NOT Reckognized: \(command)")
        }           
    }    
    ///
    /// Exits the application
    ///
    /// parameter parts: command array.
    ///
    func onCommandExit(parts: [String]) -> Void {
        g_quit = true
    }    
    ///
    /// Restarts the application
    ///
    /// parameter parts: command array.
    ///
    func onCommandRestart(parts: [String]) -> Void {
        //let fname:String = CommandLine.arguments.first!
        
        //let _ = NSWorkspace.shared.openFile(fname)
        
        //self.commandReturnValue = true
    }    
    ///
    /// Sets main window song bg color
    ///
    func onCommandSetColorTheme(parts: [String]) -> Void {
        if ( parts[0] == "blue" ) {
            PlayerPreferences.colorTheme = ColorTheme.Blue
            PlayerPreferences.savePreferences()
        }
        else if parts[0] == "black" {
            PlayerPreferences.colorTheme = ColorTheme.Black
            PlayerPreferences.savePreferences()
        }
        else if parts[0] == "default" {
            PlayerPreferences.colorTheme = ColorTheme.Default
            PlayerPreferences.savePreferences()
        }
        self.renderWindow()
    }    
    /// 
    /// Plays previous song
    /// - Parameter parts:  command array.
    /// 
    func onCommandPrev(parts: [String]) {
        g_lock.lock()
        g_player.prev()
        g_lock.unlock()
    }    
    ///
    /// Sets ViewType on Main Window
    ///
    func onCommandSetViewType(parts: [String]) -> Void {
        PlayerPreferences.viewType = ViewType(rawValue: parts[0].lowercased() ) ?? ViewType.Default
        PlayerPreferences.savePreferences()
        self.renderFrame()
    }    
    ///
    /// Restarts current playing song.
    ///
    /// parameter parts: command array.
    ///
    func onCommandReplay(parts: [String]) -> Void {
        g_lock.lock()
        if g_player.audioPlayerActive == 1 {
            if ( !g_player.audio1!.isPlaying ) {
                g_player.resume()
            }            
            g_player.audio1?.seekToPos(position: g_player.audio1!.duration)
        }
        else if g_player.audioPlayerActive == 2 {
            if ( !g_player.audio1!.isPlaying ) {
                g_player.resume()
            }
            g_player.audio2?.seekToPos(position: g_player.audio2!.duration)
        }
        g_lock.unlock()
    }    
    ///
    /// Play next song
    ///
    /// parameter parts: command array.
    ///
    func onCommandNextSong(parts: [String]) -> Void {
        g_lock.lock()
        g_player.skip(crossfade: false)
        g_lock.unlock()
    }    
    ///
    /// Play if not playing.
    ///
    /// parameter parts: command array.
    ///
    func onCommandPlay(parts: [String]) -> Void {
        if g_player.audioPlayerActive == -1 {
            g_player.play(player: 1, playlistIndex: 0)
        }
        else if g_player.audioPlayerActive == 1 {
            g_player.resume()
        }
        else if g_player.audioPlayerActive == 2 {
            g_player.resume()
        }
    }    
    ///
    /// Pause playback.
    ///
    /// parameter parts: command array.
    ///
    func onCommandPause(parts: [String]) -> Void {
        g_player.pause()
    }    
    ///
    /// Play or pause playback
    ///
    /// parameter parts: command array.
    ///
    func onCommandPlayOrPause(parts: [String]) -> Void {
        if g_player.audioPlayerActive == -1 {
            self.onCommandPlay(parts: parts)
        }
        
        if g_player.isPaused {
            g_player.resume()
        }
        else {
            g_player.pause()
        }        
    }    
    ///
    /// Resume playback.
    ///
    /// parameter parts: command array.
    ///
    func onCommandResume(parts: [String]) -> Void {
        g_player.resume()
    }    
    ///
    /// Repaint main window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandRepaint(parts: [String]) -> Void {
        Console.clearScreenCurrentTheme()
        self.renderWindow()
    }    
    ///
    /// Add song to playlist
    ///
    /// parameter parts: command array.
    /// parameter songNo: song number to add.
    ///
    func onCommandAddSongToPlaylist(parts: [String]) -> Void {
        if let songNo = Int(parts[0]) {
            for se in g_songs {
                if se.songNo == songNo {
                    g_playlist.append(se)
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
        PlayerPreferences.crossfadeSongs = true
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Disable crossfade.
    ///
    /// parameter parts: command array.
    ///
    func onCommandDisableCrossfade(parts: [String]) -> Void {
        PlayerPreferences.crossfadeSongs = false
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Enable audoplay on startup and after reinitialize.
    ///
    /// parameter parts: command array.
    ///
    func onCommandEnableAutoPlayOnStartup(parts: [String]) -> Void {
        PlayerPreferences.autoplayOnStartup = true
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Disable autoplay on startup and after reinitialize.
    ///
    /// parameter parts: command array.
    ///
    func onCommandDisableAutoPlayOnStartup(parts: [String]) -> Void {
        PlayerPreferences.autoplayOnStartup = false
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Add path to root paths.
    ///
    /// parameter parts: command array.
    ///
    func onCommandAddMusicRootPath(parts: [String]) -> Void {
        let nparts = reparseCurrentCommandArguments(parts)
        PlayerPreferences.musicRootPath.append(nparts[0])
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Add path to exclusion paths.
    ///
    /// parameter parts: command array.
    ///
    func onCommandAddExclusionPath(parts: [String]) -> Void {
        let nparts = reparseCurrentCommandArguments(parts)
        PlayerPreferences.exclusionPaths.append(nparts[0])
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Remove root path.
    ///
    /// parameter parts: command array.
    ///
    func onCommandRemoveMusicRootPath(parts: [String]) -> Void {
        let nparts = reparseCurrentCommandArguments(parts)
        var i: Int = 0
        while i < PlayerPreferences.musicRootPath.count {
            if PlayerPreferences.musicRootPath[i] == nparts[0] {
                PlayerPreferences.musicRootPath.remove(at: i)
                PlayerPreferences.savePreferences()
                break
            }
            i += 1
        }
    }    
    ///
    /// Remove exclustion path.
    ///
    /// parameter parts: command array.
    ///
    func onCommandRemoveExclusionPath(parts: [String]) -> Void {
        let nparts = reparseCurrentCommandArguments(parts)
        var i: Int = 0
        while i < PlayerPreferences.exclusionPaths.count {
            if PlayerPreferences.exclusionPaths[i] == nparts[0] {
                PlayerPreferences.exclusionPaths.remove(at: i)
                PlayerPreferences.savePreferences()
                break
            }
            i += 1
        }
    }    
    ///
    /// Set crossfade time in seconds.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSetCrossfadeTimeInSeconds(parts: [String]) -> Void {
        if let ctis = Int(parts[0]) {
            if isCrossfadeTimeValid(seconds: ctis) {
                PlayerPreferences.crossfadeTimeInSeconds = ctis
                PlayerPreferences.savePreferences()
            }
        }
    }    
    ///
    /// Set music formats.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSetMusicFormats(parts: [String]) -> Void {
        PlayerPreferences.musicFormats = parts[0]
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Goto playback point of current playing item.
    ///
    /// parameter parts: command array.
    ///
    func onCommandGoTo(parts: [String]) -> Void {
        let tp = parts[0].split(separator: ":" )
        if tp.count == 2 {
            if let time1 = Int(tp[0]) {
                if let time2 = Int(tp[1]) {
                    if time1 >= 0 && time2 >= 0 && time2 < 60 {
                        let pos: Int = time1*60 + time2
                        
                        guard pos >= 0 else {
                            return;
                        }

                        let posMs: UInt64 = UInt64(pos * 1000)
                        if g_player.audioPlayerActive == 1 {                              
                            if posMs < g_player.audio1!.duration {                                
                                g_player.audio1?.seekToPos(position: posMs)
                            }
                        }
                        else if g_player.audioPlayerActive == 2 {                             
                            if posMs < g_player.audio2!.duration {                                
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
        g_lock.lock()
        g_searchType.removeAll()
        g_searchResult.removeAll()
        g_modeSearch.removeAll()
        g_modeSearchStats.removeAll()
        g_lock.unlock()
    }
    ///
    /// Show info on given song number.
    ///
    /// parameter parts: command array.
    ///
    func onCommandInfoSong(parts: [String]) -> Void {
        if let sno = Int(parts[0]) {
            if sno > 0 {
                for s in g_songs {
                    if s.songNo == sno {
                        self.isShowingTopWindow = true
                        let wnd: InfoWindow = InfoWindow()
                        wnd.song = s
                        wnd.showWindow()
                        Console.clearScreenCurrentTheme()
                        self.renderWindow()
                        self.isShowingTopWindow = false
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
        self.isShowingTopWindow = true
        let wnd: HelpWindow = HelpWindow()
        wnd.showWindow()
        Console.clearScreenCurrentTheme()
        self.renderWindow()
        self.isShowingTopWindow = false
    }    
    ///
    /// Clear music root paths.
    ///
    /// parameter parts: command array.
    ///
    func onCommandClearMusicRootPath(parts: [String]) -> Void {
        PlayerPreferences.musicRootPath.removeAll()
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Clear music root paths.
    ///
    /// parameter parts: command array.
    ///
    func onCommandClearExclusionPath(parts: [String]) -> Void {
        PlayerPreferences.exclusionPaths.removeAll()
        PlayerPreferences.savePreferences()
    }    
    ///
    /// Show about window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandAbout(parts: [String]) -> Void {
        self.isShowingTopWindow = true
        let wnd: AboutWindow = AboutWindow()
        wnd.showWindow()
        Console.clearScreenCurrentTheme()
        self.renderWindow()
        self.isShowingTopWindow = false
    }    
    ///
    /// Show artist window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandArtist(parts: [String]) -> Void {
        self.isShowingTopWindow = true
        let wnd: ArtistWindow = ArtistWindow()
        wnd.showWindow()
        Console.clearScreenCurrentTheme()
        self.renderWindow()
        self.isShowingTopWindow = false
    }    
    ///
    /// Show genre window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandGenre(parts: [String]) -> Void {
        self.isShowingTopWindow = true
        let wnd: GenreWindow = GenreWindow()
        wnd.showWindow()
        Console.clearScreenCurrentTheme()
        self.renderWindow()
        self.isShowingTopWindow = false
    }    
    ///
    /// Show mode window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandMode(parts: [String]) -> Void {
        self.isShowingTopWindow = true
        let wnd: ModeWindow = ModeWindow()
        wnd.showWindow()
        Console.clearScreenCurrentTheme()
        self.renderWindow()
        self.isShowingTopWindow = false
    }
    ///
    /// Show info window about current playing item.
    ///
    /// parameter parts: command array.
    ///
    func onCommandInfo(parts: [String]) -> Void {
        if parts.count == 1 {
            self.onCommandInfoSong(parts: parts)
            return
        }
        self.isShowingTopWindow = true
        let wnd: InfoWindow = InfoWindow()
        g_lock.lock()
        let song = g_playlist[0]
        g_lock.unlock()
        wnd.song = song
        wnd.showWindow()
        Console.clearScreenCurrentTheme()
        self.renderWindow()
        self.isShowingTopWindow = false
    }    
    ///
    /// Reinitialize library and player.
    ///
    /// parameter parts: command array.
    ///
    func onCommandReinitialize(parts: [String]) -> Void {
        g_player.pause()
                
        g_lock.lock()
        
        g_searchType.removeAll()
        g_genres.removeAll()
        g_artists.removeAll()
        g_recordingYears.removeAll()
        g_searchResult.removeAll()
        g_modeSearch.removeAll()
        g_modeSearchStats.removeAll()
        g_songs.removeAll()
        g_playlist.removeAll()
        g_library.library = []
        g_library.save()
        g_library.setNextAvailableSongNo(1)
        
        g_player.audioPlayerActive = -1
        g_player.audio1 = nil
        g_player.audio2 = nil
        
        if PlayerPreferences.musicRootPath.count == 0 {
            self.isShowingTopWindow = true
            let wndS: SetupWindow = SetupWindow()
            wndS.showWindow()
            self.isShowingTopWindow = true
            let wndI = InitializeWindow()
            wndI.showWindow()
        }
        else {
            self.isShowingTopWindow = true
            let wnd = InitializeWindow()
            wnd.showWindow()
        }
        self.isShowingTopWindow = false
        
        g_library.library = g_songs
        g_library.save()
        
        self.renderWindow()
        
        g_lock.unlock()
        
        g_player.skip(play: PlayerPreferences.autoplayOnStartup)
    }    
    ///
    /// Rebuild song numbers.
    ///
    /// parameter parts: command array.
    ///
    func onCommandRebuildSongNo(parts: [String]) -> Void {
        var i: Int = 1
        for s in g_songs {
            s.songNo = i
            i += 1
        }
        g_library.setNextAvailableSongNo(i)
        g_library.library = g_songs
        g_library.save()
    }    
    ///
    /// Show preferences window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandPreferences(parts: [String]) -> Void {
        self.isShowingTopWindow = true
        let wnd: PreferencesWindow = PreferencesWindow()
        wnd.showWindow()
        Console.clearScreenCurrentTheme()
        self.renderWindow()
        self.isShowingTopWindow = false
    }    
    ///
    /// Show year window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandYear(parts: [String]) -> Void {
        self.isShowingTopWindow = true
        let wnd: YearWindow = YearWindow()
        wnd.showWindow()
        Console.clearScreenCurrentTheme()
        self.renderWindow()
        self.isShowingTopWindow = false
    }    
    ///
    /// Show search window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSearch(parts: [String]) -> Void {
        let nparts = reparseCurrentCommandArguments(parts)
        
        if nparts.count > 0 {
            self.isShowingTopWindow = true
            let wnd: SearchWindow = SearchWindow()
            wnd.parts = nparts
            wnd.type = SearchType.ArtistOrTitle
            wnd.showWindow()
            Console.clearScreenCurrentTheme()
            self.renderWindow()
            self.isShowingTopWindow = false
        }
    }    
    ///
    /// Show search window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSearchArtist(parts: [String]) -> Void {
        let nparts = reparseCurrentCommandArguments(parts)
        
        if nparts.count > 0 {
            self.isShowingTopWindow = true
            let wnd: SearchWindow = SearchWindow()
            wnd.parts = nparts
            wnd.type = SearchType.Artist
            wnd.showWindow()
            Console.clearScreenCurrentTheme()
            self.renderWindow()
            self.isShowingTopWindow = false
        }
    }    
    ///
    /// Show search window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSearchTitle(parts: [String]) -> Void {
        let nparts = reparseCurrentCommandArguments(parts)
        
        if nparts.count > 0 {
            self.isShowingTopWindow = true
            let wnd: SearchWindow = SearchWindow()
            wnd.parts = nparts
            wnd.type = SearchType.Title
            wnd.showWindow()
            Console.clearScreenCurrentTheme()
            self.renderWindow()
            self.isShowingTopWindow = false
        }
    }    
    ///
    /// Show search window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSearchAlbum(parts: [String]) -> Void {
        let nparts = reparseCurrentCommandArguments(parts)
        
        if nparts.count > 0 {
            self.isShowingTopWindow = true
            let wnd: SearchWindow = SearchWindow()
            wnd.parts = nparts
            wnd.type = SearchType.Album
            wnd.showWindow()
            Console.clearScreenCurrentTheme()
            self.renderWindow()
            self.isShowingTopWindow = false
        }
    }    
    ///
    /// Show search window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSearchGenre(parts: [String]) -> Void {
        let nparts = reparseCurrentCommandArguments(parts)
        
        if nparts.count > 0 {
            self.isShowingTopWindow = true
            let wnd: SearchWindow = SearchWindow()
            wnd.parts = nparts
            wnd.type = SearchType.Genre
            wnd.showWindow()
            Console.clearScreenCurrentTheme()
            self.renderWindow()
            self.isShowingTopWindow = false
        }
    }    
    ///
    /// Show search window.
    ///
    /// parameter parts: command array.
    ///
    func onCommandSearchYear(parts: [String]) -> Void {
        let nparts = reparseCurrentCommandArguments(parts)
        
        if nparts.count > 0 {
            self.isShowingTopWindow = true
            let wnd: SearchWindow = SearchWindow()
            wnd.parts = nparts
            wnd.type = SearchType.RecordedYear
            wnd.showWindow()
            Console.clearScreenCurrentTheme()
            self.renderWindow()
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
            try PlayerCommandHistory.default.clear()
        }
        catch {

        }
    }    
}// MainWindow
