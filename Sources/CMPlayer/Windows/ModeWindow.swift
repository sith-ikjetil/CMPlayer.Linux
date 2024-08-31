//
//  ModeWindow.swift
//
//  (i): Show information on current mode. Search parameters
//       used and all the songs found in that mode.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import
//
import Foundation
///
/// Represents CMPlayer ModeWindow.
///
internal class ModeWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    ///
    /// private variables
    ///    
    private var modeText: [String] = []                     // modeText items.
    private var inMode: Bool = false                        // are we in a mode
    private var searchResult: [SongEntry] = g_searchResult  // SongEntry items part of the mode
    private var searchIndex: Int = 0                        // index
    ///
    /// Shows this AboutWindow on screen.
    ///
    func showWindow() -> Void {
        // set searchIndex to 0
        self.searchIndex = 0
        // update modeText
        self.updateModeText()
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
    /// Updates the genere text array. Called before visual showing.
    ///
    func updateModeText() -> Void
    {
        // update modeText
        // remove all items first
        self.modeText.removeAll()
        // guard count of g_modeSearch and g_modeSearchStats
        guard g_modeSearch.count == g_modeSearchStats.count else {
            // return
            return
        }
        // if g_searchType count has at least 1 value (we are in a mode)
        if g_searchType.count > 0 {
            // set inMode flag to true
            self.inMode = true
        }
        // create a index variable i
        var i: Int = 0
        // loop through all SearchType in g_searchType
        for type in g_searchType {
            // append search type name to modeText
            self.modeText.append("\(type.rawValue)")
            // loop through g_modeSearch
            for j in 0..<g_modeSearch[i].count {
                // append mode search and search songs count
                self.modeText.append(" :: \(g_modeSearch[i][j]), \(g_modeSearchStats[i][j]) Songs")
            }
            // increase index variable by 1
            i += 1
        }
        // append blank line to modeText
        self.modeText.append(" ");
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
        // set song no color
        let songNoColor = ConsoleColor.cyan
        // render title
        Console.printXY(1,3,":: MODE ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        // render mode information
        Console.printXY(1,4,"mode is: \((g_searchType.count > 0) ? "on" : "off")", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // line index on screen. start at 5
        var index_screen_lines: Int = 5
        // index into modeText
        var index_search: Int = self.searchIndex   
        // max index_search 
        let max = self.modeText.count + self.searchResult.count
        // if viewtype is default
        if PlayerPreferences.viewType == ViewType.Default {
            // get main window layout
            let layout: MainWindowLayout = MainWindowLayout.get()
            // loop while index_search is less than max but...
            while index_search < max {
                // if index_screen_lines is reaching forbidden area on screen
                if index_screen_lines >= (g_rows-3) {
                    // discontinue loop
                    break
                }
                // if index_search has reached modeText + searchResult counts
                if index_search > ((self.modeText.count + self.searchResult.count) - 1) {
                    // discontinue loop
                    break
                }
                // if index_search is in modeText
                if index_search < self.modeText.count {
                    // set constant mt to modeText item
                    let mt = self.modeText[index_search]
                    // if sub item
                    if mt.hasPrefix(" ::") {
                        // render sub item
                        Console.printXY(1, index_screen_lines, mt, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    }
                    // else, we have item
                    else {
                        // render item
                        Console.printXY(1, index_screen_lines, mt, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
                    }
                }
                // index_serach is in modeText count +
                else {
                    // set constant to SongEntry from searchResult
                    let se = self.searchResult[index_search-self.modeText.count]
                    // render song no
                    Console.printXY(layout.songNoX, index_screen_lines, "\(se.songNo) ", layout.songNoCols, .right, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
                    // render artist
                    Console.printXY(layout.artistX, index_screen_lines, "\(se.artist)", layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    // render title
                    Console.printXY(layout.titleX, index_screen_lines, "\(se.title)", layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    // render duration
                    Console.printXY(layout.durationX, index_screen_lines, itsRenderMsToFullString(se.duration, false), layout.durationCols, .ignore, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                }
                // increase index_screen_lines by 1 for next round of loop
                index_screen_lines += 1
                // increase index_search by 1 for next round of loop
                index_search += 1
            }
        }
        else if PlayerPreferences.viewType == ViewType.Details { 
            // get main window layout
            let layout: MainWindowLayout = MainWindowLayout.get()    
            // loop while index_search is less than max but...
            while index_search < max {
                // if index_screen_lines is reaching forbidden area on screen
                if index_screen_lines >= (g_rows-3) {
                    // discontinue loop
                    break
                }
                // if index_search has reached modeText + searchResult counts
                if index_search >= (self.modeText.count + self.searchResult.count) {
                    // discontinue loop
                    break
                }
                // if index_search is in modeText
                if index_search < self.modeText.count {
                    // set constant mt to modeText item
                    let mt = self.modeText[index_search]
                    // if sub item
                    if mt.hasPrefix(" ::") {
                        // render sub item
                        Console.printXY(1, index_screen_lines, mt, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    }
                    // else, we have item
                    else {
                        // if item
                        Console.printXY(1, index_screen_lines, mt, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
                    }
                    // increase index_screen_lines by 1 for next round of loop
                    index_screen_lines += 1
                    // increase index_search by 1 for next round of loop
                    index_search += 1
                }
                else {
                    // set constant to SongEntry from searchResult
                    let song = self.searchResult[index_search-self.modeText.count]
                    // render song no
                    Console.printXY(layout.songNoX, index_screen_lines, "\(song.songNo) ", layout.songNoCols, .right, " ", bgColor, ConsoleColorModifier.none, songNoColor, ConsoleColorModifier.bold)
                    Console.printXY(layout.songNoX, index_screen_lines+1, " ", layout.songNoCols, .right, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    // render artist/albumName
                    Console.printXY(layout.artistX, index_screen_lines, song.artist, layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    Console.printXY(layout.artistX, index_screen_lines+1, song.albumName, layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    // render title/genre
                    Console.printXY(layout.titleX, index_screen_lines, song.title, layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    Console.printXY(layout.titleX, index_screen_lines+1, song.genre, layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    // create a constant with song duration as time string
                    let timeString: String = itsRenderMsToFullString(song.duration, false)
                    // create a constant with last  part of timeString
                    let endTimePart: String = String(timeString[timeString.index(timeString.endIndex, offsetBy: -5)..<timeString.endIndex])
                    // render duration
                    Console.printXY(layout.durationX, index_screen_lines, endTimePart, layout.durationCols, .ignore, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    Console.printXY(layout.durationX, index_screen_lines+1, " ", layout.durationCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    // increase index_screen_lines by 2 for next round of loop
                    index_screen_lines += 2
                    // increase index_search by 1 for next round of loop
                    index_search += 1
                }                
            }
        }       
        // render forbidden area
        // render empty line
        Console.printXY(1,g_rows-3," ", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold) 
        // render information
        Console.printXY(1,g_rows-1,"PRESS ANY KEY TO EXIT", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // render status line
        Console.printXY(1,g_rows,"\(g_searchResult.count.itsToString()) Songs", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // goto g_cols, 1
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
        // set searchIndex to 0
        self.searchIndex = 0   
        // render this window     
        self.renderWindow()
        // create a ConsoleKeyboardHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        // add key handler for key down (move down one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            // if viewtype is default
            if PlayerPreferences.viewType == ViewType.Default {
                // if searchIndex + page size <= total count
                if (self.searchIndex + (g_rows-7)) <= (self.modeText.count+self.searchResult.count) {
                    // increase searchIndex by 1 (move one line down)
                    self.searchIndex += 1
                    // render window
                    self.renderWindow()
                }
            }
            // else if viewtype is details
            else if PlayerPreferences.viewType == ViewType.Details {
                // if searchIndex + page size (details) is < total count
                if (self.searchIndex + ((g_rows-7)/2)) < (self.modeText.count+self.searchResult.count) {
                    // increase searchIndex by 1 (move one line down)
                    self.searchIndex += 1 
                    // render window
                    self.renderWindow()
                }
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key up (move up one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            // if searchIndex is at least 1
            if self.searchIndex >= 1 {
                // decrement searchIndex by 1 (move up line up)
                self.searchIndex -= 1
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key left (move up one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in            
            // if viewtype is default
            if PlayerPreferences.viewType == ViewType.Default {
                // if searchIndex is greater than page size
                if self.searchIndex >= (g_rows-7) {
                    // decrement searchIndex by on page (move up one page)
                    self.searchIndex -= (g_rows-7)                    
                }
                // else, we are at top
                else {
                    // set serachIndex to start position
                    self.searchIndex = 0                    
                }   
                // render window
                self.renderWindow()     
            }
            // else if viewtype is details
            else if PlayerPreferences.viewType == ViewType.Details {
                // if searchIndex is greater than modeText count
                if self.searchIndex >= self.modeText.count {
                    // if searchIndex is greater than one page size
                    if (self.searchIndex - ((g_rows-7)/2)) > 0 {
                        // subtract searchIndex one page
                        self.searchIndex -= ((g_rows-7)/2)
                        // if searchIndex is negative
                        if self.searchIndex < 0 {
                            // then set searchIndex to 0
                            self.searchIndex = 0
                        }
                    }
                    // else
                    else {
                        // set searchIndex to start position
                        self.searchIndex = 0                        
                    }                    
                }
                // else
                else {
                    // set searchIndex to 0
                    self.searchIndex = 0
                }
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key right (move down one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in            
            // if viewtype is default
            if PlayerPreferences.viewType == ViewType.Default {
                // if total items count is greater than page size
                if self.searchIndex >= 0 && (self.modeText.count+self.searchResult.count) > (g_rows-7) {
                    // if searchIndex + page size is less than total items count - page size
                    if self.searchIndex + (g_rows-7) < ((self.modeText.count+self.searchResult.count) - (g_rows-7)) {
                        // we can saftely add a page size
                        self.searchIndex += (g_rows-7) - 1
                    }
                    // else
                    else {
                        // set serachIndex to total items count - page size (last page)
                        self.searchIndex = (self.modeText.count+self.searchResult.count) - (g_rows-7) + 1
                        // if searchIndex should be negative
                        if (self.searchIndex < 0) {
                            // set searchIndex to 0
                            self.searchIndex = 0
                        }
                    }                    
                }             
                // render window
                self.renderWindow()
            }
            // if viewtype is details
            else if PlayerPreferences.viewType == ViewType.Details {
                // if total items count is greater than page size
                if self.searchIndex >= 0 && (self.modeText.count+self.searchResult.count) > (g_rows-7) {
                    // if searchIndex + page size is less than total count - page size
                    if self.searchIndex + ((g_rows-7)/2) < ((self.modeText.count+self.searchResult.count) - ((g_rows-7)/2)) {
                        // saftely add a page size
                        self.searchIndex += ((g_rows-7)/2) 
                    }
                    // else
                    else {
                        // set search index to last page
                        self.searchIndex = (self.modeText.count+self.searchResult.count) - ((g_rows-7)/2)
                        // if searchIndex should happen to be negative
                        if (self.searchIndex < 0) {
                            // set serachIndex to start = 0
                            self.searchIndex = 0
                        }
                    }                    
                }             
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for unknown key handler
        keyHandler.addUnknownKeyHandler(closure: { (key: UInt32) -> Bool in
            // return from run()
            return true
        })
        // execute run(), modal call
        keyHandler.run()
    }// run
}// ModeWindow
