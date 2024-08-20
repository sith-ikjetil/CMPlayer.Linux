//
//  MainWindow.swift
//  ConsoleMusicPlayer-macOS
//
//  Created by Kjetil Kr Solberg on 20/09/2019.
//  Copyright © 2019 Kjetil Kr Solberg. All rights reserved.
//

//
// import
//
import Foundation

///
/// Represents CMPlayer MainWindow.
///
internal class MainWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    //
    // properties/constants/variables.
    //
    static private var timeElapsedMs: UInt64 = 0
    private var quit: Bool = false
    private var currentCommand: String = ""
    private var commands: [PlayerCommand] = []
    private var commandReturnValue: Bool = false
    private let concurrentQueue1 = DispatchQueue(label: "dqueue.cmp.linux.main-window.1", attributes: .concurrent)
    private let concurrentQueue2 = DispatchQueue(label: "dqueue.cmp.linux.main-window.2", attributes: .concurrent)
    private var isShowingTopWindow = false
    private var addendumText: String = ""
    private var updateFileName: String = ""
    private var isTooSmall: Bool = false
    private var showCursor: Bool = false
    private var cursorTimeout: UInt64 = 0
    var exitValue: Int32 = 0    
    ///
    /// Shows this MainWindow on screen.
    ///
    /// returns: ExitCode,  Int32
    ///
    func showWindow() -> Void {
        g_tscpStack.append(self)
        self.run()
        g_tscpStack.removeLast()
    }    
    ///
    /// Handler for TerminalSizeHasChangedProtocol
    ///
    func terminalSizeHasChanged() -> Void {
        Console.clearScreenCurrentTheme()// TODO: Test remove        
        if g_rows >= 24 && g_cols >= 80 {
            self.isTooSmall = false
            self.renderWindow()
        }
        else {
            self.isTooSmall = true
            Console.gotoXY(80,1)
            print("")
        }
    }
    ///
    /// Renders header on screen
    ///
    /// parameter showTime: True if time string is to be shown in header. False otherwise.
    ///
    static func renderHeader(showTime: Bool) -> Void {
        let bgColor = ConsoleColor.blue
        
        if showTime {
            Console.printXY(1,1,"CMPlayer | \(g_versionString) | \(itsRenderMsToFullString(MainWindow.timeElapsedMs, false))", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        }
        else {
            Console.printXY(1,1,"CMPlayer | \(g_versionString)", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        }
    }    
    ///
    /// Renders main window frame on screen
    ///
    func renderFrame() -> Void {
        
        MainWindow.renderHeader(showTime: true)
        
        let bgColor = getThemeBgColor()
        
        Console.printXY(1,2," ", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
    
        if PlayerPreferences.viewType == ViewType.Default {            
            Console.printXY(1,3,"Song No.", g_fieldWidthSongNo+1, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        
            let ncalc: Double = Double(g_cols - g_fieldWidthSongNo+1 - g_fieldWidthDuration) / 2.0
            let artistCols: Int = Int(floor(ncalc))
            let titleCols: Int =  Int(ceil(ncalc))

            Console.printXY(10,3,"Artist", artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        
            Console.printXY(10+artistCols,3,"Title", titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        
            Console.printXY(10+artistCols+titleCols-2,3,"Time", g_fieldWidthDuration, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        
            //let sep = String("\u{2550}")
            Console.printXY(1,4,"=", g_cols, .left, "=", bgColor, ConsoleColorModifier.none, ConsoleColor.green, ConsoleColorModifier.bold)
        }
        else if PlayerPreferences.viewType == ViewType.Details {
            Console.printXY(1,3,"Song No.", g_fieldWidthSongNo+1, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            Console.printXY(1,4," ", g_fieldWidthSongNo+1, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            
            let ncalc: Double = Double(g_cols - g_fieldWidthSongNo+1 - g_fieldWidthDuration) / 2.0
            let artistCols: Int = Int(floor(ncalc))
            let titleCols: Int =  Int(ceil(ncalc))

            Console.printXY(10,3,"Artist", artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            Console.printXY(10,4,"Album Name", artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        
            Console.printXY(10+artistCols,3,"Title", titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            Console.printXY(10+artistCols,4,"Genre", titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        
            Console.printXY(10+artistCols+titleCols-2,3,"Time", g_fieldWidthDuration, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
            Console.printXY(10+artistCols+titleCols-2,4," ", g_fieldWidthDuration, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        
            //let sep = String("\u{2550}")
            Console.printXY(1,5,"=", g_cols, .left, "=", bgColor, ConsoleColorModifier.none, ConsoleColor.green, ConsoleColorModifier.bold)
        }
    }
    ///
    /// Renders a song on screen
    ///
    /// parameter y: Line where song is to be rendered.
    /// parameter songNo: SongNo.
    /// parameter artist. Artist.
    /// parameter song. Title.
    /// parameter time. Duration (ms).
    ///
    func renderSong(_ y: Int, _ song: SongEntry, _ time: UInt64) -> Void
    {
        let bgColor = getThemeSongBgColor()
        let songNoColor = ConsoleColor.cyan
        
        if PlayerPreferences.viewType == ViewType.Default {
            Console.printXY(1, y, String(song.songNo)+" ", g_fieldWidthSongNo+1, .right, " ", bgColor, ConsoleColorModifier.none, songNoColor, ConsoleColorModifier.bold)
            
            let ncalc: Double = Double(g_cols - g_fieldWidthSongNo+1 - g_fieldWidthDuration) / 2.0
            let artistCols: Int = Int(floor(ncalc))
            let titleCols: Int =  Int(ceil(ncalc))

            Console.printXY(10, y, song.getArtist(), artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)            
            Console.printXY(10+artistCols, y, song.getTitle(), titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            
            let timeString: String = itsRenderMsToFullString(time, false)
            let endTimePart: String = String(timeString[timeString.index(timeString.endIndex, offsetBy: -5)..<timeString.endIndex])
            Console.printXY(10+artistCols+titleCols-2, y, endTimePart, g_fieldWidthDuration, .ignore, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        }
        else if PlayerPreferences.viewType == ViewType.Details {
            Console.printXY(1, y, "\(song.songNo) ", g_fieldWidthSongNo+1, .right, " ", bgColor, ConsoleColorModifier.none, songNoColor, ConsoleColorModifier.bold)
            Console.printXY(1, y+1, " ", g_fieldWidthSongNo+1, .right, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            
            let ncalc: Double = Double(g_cols - g_fieldWidthSongNo+1 - g_fieldWidthDuration) / 2.0
            let artistCols: Int = Int(floor(ncalc))
            let titleCols: Int =  Int(ceil(ncalc))

            Console.printXY(10, y, song.getArtist(), artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            Console.printXY(10, y+1, song.getAlbumName(), artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            
            Console.printXY(10+artistCols, y, song.getTitle(), titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            Console.printXY(10+artistCols, y+1, song.getGenre(), titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            
            let timeString: String = itsRenderMsToFullString(time, false)
            let endTimePart: String = String(timeString[timeString.index(timeString.endIndex, offsetBy: -5)..<timeString.endIndex])
            Console.printXY(10+artistCols+titleCols-2, y, endTimePart, g_fieldWidthDuration, .ignore, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            
            Console.printXY(10+artistCols+titleCols-2, y+1, " ", g_fieldWidthDuration, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        }
    }
    /// 
    /// renders addendum text at g_rows-2
    ///     
    func renderAddendumText() -> Void {
        Console.printXY(1,g_rows-2, (self.addendumText.count > 0) ? self.addendumText : " ", g_cols, .left, " ", getThemeBgColor(), ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.none)
    }    
    ///
    /// Renders the command line on screen
    ///
    func renderCommandLine() -> Void
    {
        var text = self.currentCommand
        if text.count > (g_cols-4) {
            text = String(text[text.index(text.endIndex, offsetBy: -1*(g_cols-4))..<text.endIndex])
        }
        
        var cursor = ""
        if self.showCursor {
            cursor = "_"
        }
    
        Console.printXY(1,g_rows-1,">: \(text)\(cursor)", g_cols, .left, " ", getThemeBgColor(), ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
    }    
    ///
    /// Renders the status line on screen
    ///
    func renderStatusLine() -> Void
    {
        var text: String = "\(g_songs.count.itsToString()) Songs"
        
        let modeInfo = getModeStatus()
        if modeInfo.isInMode {
            text.append( " | Mode: ")
            var b: Bool = false
            for mn in modeInfo.modeName {
                if b {
                    text.append(", ")
                }
                text.append(mn)
                b = true
            }
            text.append(" with \(modeInfo.numberOfSongsInMode.itsToString()) Songs")
        }
        else {
            text.append( " | Mode: off | \(g_cols)x\(g_rows) | \(g_playlist.count) Songs in Queue" )
        }
        
        Console.printXY(1,g_rows, text, g_cols, .center, " ", getThemeBgColor(), ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
    }    
    ///
    /// Traverses all songs and ask the screen renderer to render them on screen
    ///
    func renderSongs() -> Void {
        var idx: Int = (PlayerPreferences.viewType == ViewType.Default) ? 5 : 6
        let timeRow: Int = (PlayerPreferences.viewType == ViewType.Default) ? 5 : 6
        var index: Int = 0
        let max: Int = (PlayerPreferences.viewType == ViewType.Default) ? g_rows-7+5 : g_rows-8+6//? 22 : 21
        let bgColor = getThemeBgColor()
        while idx < max {
            if index < g_playlist.count {
                let s = g_playlist[index]
                
                if idx == timeRow {
                    if g_player.audioPlayerActive == -1 && g_playlist.count > 0{
                        renderSong(idx, s, g_playlist[0].duration)
                    }
                    else if g_player.audioPlayerActive == 1 {
                        renderSong(idx, s, g_player.durationAudioPlayer1)
                    }
                    else if g_player.audioPlayerActive == 2 {
                        renderSong(idx, s, g_player.durationAudioPlayer2)
                    }
                }
                else {
                    renderSong(idx, s, s.duration)
                }
            }
            else {
                if PlayerPreferences.viewType == ViewType.Default {
                    Console.printXY(1, idx, " ", g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                }
                else if PlayerPreferences.viewType == ViewType.Details {
                    Console.printXY(1, idx, " ", g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    Console.printXY(1, idx+1, " ", g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                }
            }
            if PlayerPreferences.viewType == ViewType.Default {
                idx += 1
            }
            else if PlayerPreferences.viewType == ViewType.Details {
                idx += 2
            }
            index += 1
        }
    }    
    ///
    /// Renders screen output. Does not clear screen first.
    ///
    func renderWindow() -> Void {
        if g_rows < 24 || g_cols < 80 {
            return
        }

        renderFrame()
        renderSongs()
        renderAddendumText()
        renderCommandLine()
        renderStatusLine()
        
        Console.gotoXY(1, g_rows-3)
        print("")
    }    
    ///
    /// Runs MainWindow keyboard input and feedback. Delegation to other windows and command processing.
    ///
    func run() -> Void {
        Console.clearScreenCurrentTheme()        
        self.renderWindow()
        
        //
        // Setup command processing
        //
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
                         PlayerCommand(commands: [["#"]], closure: self.onCommandAddSongToPlaylist)]
        
        
        //
        // Count down and render songs
        //
        concurrentQueue1.async {
            while !self.quit {
                
                if !self.isShowingTopWindow {
                    if !self.isTooSmall {
                        MainWindow.renderHeader(showTime: true)
                        self.renderWindow()
                    }
                }
                
                g_lock.lock()
                if g_playlist.count > 0 {
                    if g_player.audioPlayerActive == 1 {
                        var time: UInt64 = 0
                        if let a = g_player.audio1 {
                            time = a.timeElapsed
                        }
                        if g_playlist[0].duration >= time {
                            g_player.durationAudioPlayer1 = (g_playlist[0].duration - time)
                        }
                        else {
                            g_player.durationAudioPlayer1 = 0
                        }
                    }
                    else if g_player.audioPlayerActive == 2 {
                        var time: UInt64 = 0
                        if let a = g_player.audio2 {
                            time = a.timeElapsed
                        }
                        if g_playlist[0].duration >= time {
                            g_player.durationAudioPlayer2 = (g_playlist[0].duration - time)
                        }
                        else {
                            g_player.durationAudioPlayer2 = 0
                        }
                    }
                    
                    if g_player.audioPlayerActive == 1 && g_player.audio1 != nil {
                        if (PlayerPreferences.crossfadeSongs && g_player.durationAudioPlayer1 <= PlayerPreferences.crossfadeTimeInSeconds * 1000)
                            || g_player.durationAudioPlayer1 <= 1000 || ( g_player.durationAudioPlayer1 > 0 && !g_player.isPaused && !g_player.audio1!.isPlaying ) {
                            g_player.skip(crossfade: PlayerPreferences.crossfadeSongs)
                        }
                    }
                    else if g_player.audioPlayerActive == 2 && g_player.audio2 != nil {
                        if (PlayerPreferences.crossfadeSongs && g_player.durationAudioPlayer2 <= PlayerPreferences.crossfadeTimeInSeconds * 1000)
                            || g_player.durationAudioPlayer2 <= 1000 || ( g_player.durationAudioPlayer2 > 0 && !g_player.isPaused && !g_player.audio2!.isPlaying) {
                            g_player.skip(crossfade: PlayerPreferences.crossfadeSongs)
                        }
                    }
                    
                }
                g_lock.unlock()
                
                let second: Double = 1_000_000
                usleep(useconds_t(0.050 * second))
            }
        }
        
        //
        // Count down and render songs
        //
        concurrentQueue2.async {
            while !self.quit {
                let second: Double = 1_000_000
                usleep(useconds_t(0.150 * second))
                MainWindow.timeElapsedMs += 150
                self.cursorTimeout += 150
                if self.cursorTimeout >= 600 {
                    self.cursorTimeout = 0
                    self.showCursor = true
                }
                else {
                    self.showCursor = false
                }
            }
        }
        
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_HTAB.rawValue, closure: { () -> Bool in
            _ = self.processCommand(command: "skip")
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_SHIFT_HTAB.rawValue, closure: { () -> Bool in
            _ = self.processCommand(command: "prev")
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_ENTER.rawValue, closure: { () -> Bool in
            var returnValue: Bool = false
            if self.currentCommand.count > 0 {
                returnValue = self.processCommand(command: self.currentCommand)
                self.quit = returnValue
            }
            self.currentCommand.removeAll()
            
            self.renderCommandLine()
            self.renderStatusLine()
            
            return returnValue
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_BACKSPACE.rawValue, closure: { () -> Bool in
            if self.currentCommand.count > 0 {
                self.currentCommand.removeLast()
            }
            return false
        })
        keyHandler.addCharacterKeyHandler(closure: { (ch: Character) -> Bool in
            if self.currentCommand.count == 0 && ch.isWhitespace {
                return false
            }
            
            self.currentCommand.append(ch)
            
            self.renderCommandLine()
            self.renderStatusLine()
            
            return false
        })
        keyHandler.run()
    }    
    ///
    /// Processes commands
    ///
    /// parameter command: Command string to process
    ///
    /// returns: Bool true if application should exit. False otherwise.
    ///
    func processCommand(command: String) -> Bool {
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
        
        return self.commandReturnValue
    }    
    ///
    /// Exits the application
    ///
    /// parameter parts: command array.
    ///
    func onCommandExit(parts: [String]) -> Void {
        self.commandReturnValue = true
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
        /*if g_player.audioPlayerActive == 1 {
            if ( !g_player.audio1!.isPlaying ) {
                g_player.resume()
            }
            g_player.audio1?.currentTime = TimeInterval(exactly: 0.0)!
        }
        else if g_player.audioPlayerActive == 2 {
            if ( !g_player.audio1!.isPlaying ) {
                g_player.resume()
            }
            g_player.audio2?.currentTime = TimeInterval(exactly: 0.0)!
        }*/
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
        else if g_player.audioPlayerActive == 1 {
            if let player = g_player.audio1 {
                if player.isPlaying {
                    self.onCommandPause(parts: parts)
                }
                else {
                    self.onCommandPlay(parts: parts)
                }
            }
        }
        else if g_player.audioPlayerActive == 2 {
            if let player = g_player.audio2 {
                if player.isPlaying {
                    self.onCommandPause(parts: parts)
                }
                else {
                    self.onCommandPlay(parts: parts)
                }
            }
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
            if isCrossfadeTimeValid(ctis) {
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
        /*let tp = parts[0].split(separator: ":" )
        if tp.count == 2 {
            if let time1 = Int(tp[0]) {
                if let time2 = Int(tp[1]) {
                    if time1 >= 0 && time2 >= 0 {
                        let pos: Int = time1*60 + time2
                        if g_player.audioPlayerActive == 1 {
                            g_player.audio1?.currentTime = TimeInterval(exactly: Double(UInt64(Double(g_playlist[0].duration) / 1000.0)) - Double(pos))!
                        }
                        else if g_player.audioPlayerActive == 2 {
                            g_player.audio2?.currentTime = TimeInterval(exactly: Double(UInt64(Double(g_playlist[0].duration) / 1000.0)) - Double(pos))!
                        }
                    }
                }
            }
        }*/
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
}// CMPlayer
