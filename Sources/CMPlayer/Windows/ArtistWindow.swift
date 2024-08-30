//
//  ArtistWindow.swift
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import
//
import Foundation
///
/// Represents CMPlayer AboutWindow.
///
internal class ArtistWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    ///
    /// private variables
    ///
    private var artistIndex: Int = 0        // index into artistText from where we should render text to screen
    private var artistText: [String] = []   // array of strings (line 1: artist then line 2: songs of artist count) repeating
    ///
    /// Shows this AboutWindow on screen.
    ///
    func showWindow() -> Void {
        // set artistIndex to first item in artistText
        self.artistIndex = 0
        // update artistText array
        self.updateArtistText()
        // add to top this window to terminal size change protocol stack
        g_tscpStack.append(self)
        // clear screen current theme
        Console.clearScreenCurrentTheme()
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
    func updateArtistText() -> Void
    {
        // update self.artistText
        // remove all items first
        self.artistText.removeAll()
        // sort all artists in g_artists
        let sorted = g_artists.sorted { $0.key < $1.key }
        // loop through all sorted items
        for g in sorted {
            // set artist name
            let name = g.key
            // create a string with count of all songs belonging to this artist
            let desc = " :: \(g.value.count) Songs"
            // append to artistText name
            self.artistText.append(name)
            // append to artistText desc
            self.artistText.append(desc)
        }
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
        Console.printXY(1,3,":: ARTIST ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        // render mode information
        Console.printXY(1,4,"mode artist is: \((isSearchTypeInMode(SearchType.Artist)) ? "on" : "off")", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // line index on screen. start at 5
        var index_screen_lines: Int = 5
        // index into artistIndex
        var index_search: Int = self.artistIndex
        // max index_search
        let max = self.artistText.count
        // loop while index_search is less than max but...
        while index_search < max {
            // if index_screen_lines is reaching forbidden area on screen
            if index_screen_lines >= (g_rows-3) {
                // break loop
                break
            }
            // if index_search has reached artistText.count
            if index_search >= artistText.count {
                // break loop
                break
            }
            // set se to artistText item
            let se = artistText[index_search]
            // if index_search is divisible by 2
            if index_search % 2 == 0 {
                // artist name in cyan
                Console.printXY(1, index_screen_lines, se, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
            }
            else {
                // number of songs for artist in white
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
        Console.printXY(1,g_rows,"\(g_artists.count.itsToString()) Artists", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // goto g_cols,1
        Console.gotoXY(g_cols,1)
        // print nothing
        print("")
    }
    ///
    /// Runs AboutWindow keyboard input and feedback.
    ///
    func run() -> Void {
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // set self.artistIndex to 0
        self.artistIndex = 0
        // render this window
        self.renderWindow()
        // create a ConsoleKeyboardHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        // add key handler for key down
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            // if artistIndex + page size is less than artistText count
            if (self.artistIndex + (g_rows-7)) <= self.artistText.count {
                // we can increase artistIndex by 1 line
                self.artistIndex += 1
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key up
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            // if artistIndex is larger than 1
            if self.artistIndex >= 1 {
                // we can decrease artistIndex by 1
                self.artistIndex -= 1
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key left
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            // if artistText count is larger than a page size
            if self.artistIndex > 0 && self.artistText.count > (g_rows-7) {
                // check if one page up is possible
                if self.artistIndex - (g_rows-7) > 0 {
                    // yes its possible do the manouver
                    self.artistIndex -= (g_rows-7) - 1
                }
                // else we will be at top
                else {
                    // at top, set artistIndex to 0
                    self.artistIndex = 0
                }
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key right
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in
            // if artistText count is larget than page size
            if self.artistIndex >= 0 && self.artistText.count > (g_rows-7) {
                // artistIndex + page size is less than artistText count - page size
                if self.artistIndex + (g_rows-7) < self.artistText.count - (g_rows-7) {
                    // yes we can add a page size to index
                    self.artistIndex += (g_rows-7) - 1
                }
                // else artistIndex + page size is greater than or equal to artistText count
                else {
                    // set artistIndex to artistText count - page size
                    self.artistIndex = self.artistText.count - (g_rows-7) + 1
                    // if we should get a negative value for artistIndex
                    if (self.artistIndex < 0) {
                        // set artistIndex to 0
                        self.artistIndex = 0
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
}// ArtistWindow
