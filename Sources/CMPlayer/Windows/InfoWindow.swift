//
//  InfoWindow.swift
//
//  (i): Displays information about a song in a this window.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import
//
import Foundation
///
/// Represents CMPlayer HelpWindow.
///
internal class InfoWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    //
    // private variables
    //
    private var infoIndex: Int = 0          // index into infoText from where we should render infoText to screen (one page at a time)
    private var infoText: [String] = []     // array of string [(line 1: key)(line 2: value)] representing information about a song
    ///
    /// variables
    /// 
    var song: SongEntry?    // SongEntry to show information about
    ///
    /// Shows this HelpWindow on screen.
    ///
    /// parameter song: Instance of SongEntry to render info.
    ///
    func showWindow() -> Void {
        // set infoIndex to first item in infoText
        self.infoIndex = 0
        // update infoText variable with information from song
        self.updateInfoText()
        // add to top this window to terminal size change protocol stack
        g_tscpStack.append(self)
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // run(), modal call
        self.run()
        // remove from top this window from terminal size change protocol stack
        g_tscpStack.removeLast()
    }    
    ///
    /// TerminalSizeChangedProtocol method
    ///
    func terminalSizeHasChanged() -> Void {
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
    }    
    ///
    /// Updates information to be rendered on screen
    ///    
    func updateInfoText() -> Void {
        // update self.infoText
        // remove all items first
        self.infoText.removeAll()
        // add song no title to infoText
        self.infoText.append("song no.")
        // add song no to infoText
        self.infoText.append(" :: \(self.song?.songNo ?? 0)")
        // add artist title to infoText
        self.infoText.append("artist")
        // add artist to infoText
        self.infoText.append(" :: \(self.song?.fullArtist ?? "")")
        // add album title to infoText
        self.infoText.append("album")
        // add album n ame to infoText
        self.infoText.append(" :: \(self.song?.fullAlbumName ?? "")")
        // add track no title to infoText
        self.infoText.append("track no.")
        // add track no to infoText
        self.infoText.append(" :: \(self.song?.trackNo ?? 0)")
        // add title title to infoText
        self.infoText.append("title")
        // add title to infoText
        self.infoText.append(" :: \(self.song?.fullTitle ?? "")")
        // add duration title to infoText
        self.infoText.append("duration")
        // add duration to infoText
        self.infoText.append(" :: \(itsRenderMsToFullString(self.song?.duration ?? 0, false))")
        // add recording year title to infoText
        self.infoText.append("recording year")
        // add recording year to infoText
        self.infoText.append(" :: \(self.song?.recordingYear ?? 0)")
        // add genre title to infoText
        self.infoText.append("genre")
        // add genre to infoText
        self.infoText.append(" :: \(self.song?.fullGenre ?? "")")
        // add filename title to infoText
        self.infoText.append("filename")
        // add filename to infoText
        self.infoText.append(" :: \(self.song?.fileURL?.lastPathComponent ?? "")")
        // add path title to infoText
        self.infoText.append("path")
        // add path to infoText
        self.infoText.append(" :: \(self.song?.fileURL?.deletingLastPathComponent().path ?? "")")
    }
    ///
    /// Renders screen output. Does clear screen first.
    ///
    func renderWindow() -> Void {
        // guard window size is valid
        guard isWindowSizeValid() else {
            // else write terminal too small message
            renderTerminalTooSmallMessage()
            // return
            return
        }
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render header
        MainWindow.renderHeader(showTime: false)
        // get bg color from current theme
        let bgColor = getThemeBgColor()
        // render title
        Console.printXY(1,3,":: SONG INFORMATION ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        // render blank line
        Console.printXY(1,4," ", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        // line index on screen. start at 5
        var index_screen_lines: Int = 5
        // index into infoIndex
        var index_search: Int = infoIndex
        // max index_search
        let max = infoText.count
        // loop while index_search is less than max but...
        while index_search < max {
            // if index_screen_lines is reaching forbidden area on screen
            if index_screen_lines >= (g_rows-3) {
                // discontinue loop
                break
            }
            // if index_search has reached artistText count
            if index_search >= infoText.count {
                // discontinue loop
                break
            }
            // set se to infoText item
            let se = infoText[index_search]
            // if not prefix is sub item
            if !se.hasPrefix(" ::") {
                // print key (line 1)
                Console.printXY(1, index_screen_lines, se, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
            }
            // else is sub item
            else {
                // print value (line 2)
                Console.printXY(1, index_screen_lines, se, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            }
            // increase index_screen_lines by 1 for next round of loop
            index_screen_lines += 1
            // increase index_search by 1 for next round of loop
            index_search += 1
        }
        // render forbidden area
        // render information
        Console.printXY(1,g_rows-1,"PRESS ANY KEY TO EXIT", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // render status line
        Console.printXY(1,g_rows," ", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // goto g_cols,1
        Console.gotoXY(g_cols,1)
        // print nothing
        print("")
    }    
    ///
    /// Runs this window keyboard input and feedback.
    ///
    func run() -> Void {
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // set self.artistIndex to 0
        self.infoIndex = 0
        // render this window
        self.renderWindow()
        // create a ConsoleKeyboardHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        // add key handler for key down (move down one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            // if infoIndex + page size is less than infoText count
            if (self.infoIndex + (g_rows-7)) <= self.infoText.count {
                // we can move down one line, add to infoIndex value of 1
                self.infoIndex += 1
                // render this window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key up (move up one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            // if infoIndex is >= 1
            if self.infoIndex >= 1 {
                // yes, we can saftely decrease infoIndex by 1
                self.infoIndex -= 1
                // render this window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key left (move up one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            // if infoText count is greater than page size
            if self.infoIndex > 0 && self.infoText.count > (g_rows-7) {
                // if infoIndex - page size is greater than 0
                if (self.infoIndex - (g_rows-7)) > 0 {
                    // yes, saftely move one page up
                    self.infoIndex -= (g_rows-7) - 1
                }
                // no, we are at top
                else {
                    // set infoIndex to 0 (start first line)
                    self.infoIndex = 0
                }
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key right (move down one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in             
            // if infoIndex + page size is less than infoText.count - page size
            if (self.infoIndex + (g_rows-7)) <= (self.infoText.count - (g_rows-7)) {
                // we can saftely move down a page
                self.infoIndex += (g_rows-7) - 1
            }
            // no, we are at bottom
            else {                
                // set infoIndex to end - page size
                self.infoIndex = self.infoText.count - (g_rows-7) + 1                
                // if infoIndex is negative
                if (self.infoIndex < 0 ) {
                    // set infoIndex to 0
                    self.infoIndex = 0
                }
            }
            self.renderWindow()
            // do not return from keyHandler.run()
            return false            
        })
        keyHandler.addUnknownKeyHandler(closure: { (key: UInt32) -> Bool in
            // return from run()
            return true
        })
        // execute run(), modal call
        keyHandler.run()
    }// run
}// InfoWindow
