//
//  GenreWindow.swift
//
//  (i): Shows all genres with the count of songs in each genre.
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
internal class GenreWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    ///
    /// Private properties/constants.
    ///
    private var genreIndex: Int = 0         // start index into genreText we currently are rendering
    private var genreText: [String] = []    // line 1: genre text, line 2: count songs in that genre. repeat for all genres.
    ///
    /// Shows this AboutWindow on screen.
    ///
    func showWindow() -> Void {
        // set genreIndex to first item in artistText
        self.genreIndex = 0
        // update genreText array
        self.updateGenreText()
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
    func updateGenreText() -> Void
    {
        // update genreText
        // remove all items first
        self.genreText.removeAll()
        // sort all genres in g_genres
        let sorted = g_genres.sorted { $0.key < $1.key }
        // loop through all genres in sorted
        for g in sorted {
            // set genre name
            let name = g.key.lowercased()
            // create a string that contains count of all songs of that genre
            let desc = " :: \(g.value.count) Songs"
            // append to genreText
            self.genreText.append(name)
            // append to genreText
            self.genreText.append(desc)
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
        Console.printXY(1,3,":: GENRE ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        // render mode information
        Console.printXY(1,4,"mode genre is: \((isSearchTypeInMode(SearchType.Genre)) ? "on" : "off")", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // line index on screen. start at 5
        var index_screen_lines: Int = 5
        // index into genreText
        var index_search: Int = self.genreIndex
        // max index_search
        let max = self.genreText.count
        // loop while index_search is less than max but...
        while index_search < max {
            // if index_screen_lines is reaching forbidden area on screen
            if index_screen_lines >= (g_rows-3) {
                // discontinue loop
                break
            }
            // if index_search has reached genreText.count
            if index_search >= genreText.count {
                // discontinue loop
                break
            }
            // set se to genreText item
            let se = genreText[index_search]
            // if even row
            if index_search % 2 == 0 {
                // genre name in cyan
                Console.printXY(1, index_screen_lines, se, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
            }
            // else if odd row
            else {
                // number of songs in genre in white
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
        Console.printXY(1,g_rows,"\(g_genres.count.itsToString()) Genres", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
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
        // set genreIndex to the beginning = 0
        self.genreIndex = 0
        // render this window
        self.renderWindow()        
        // create a ConsoleKeyboardHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        // add key handler for key down (move down one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            // if genreIndex plus a page size is less than genreText count
            if (self.genreIndex + (g_rows-7)) <= self.genreText.count {
                // yes, we can safetely increase genreIndex by 1
                self.genreIndex += 1
                // render this window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key up (move up one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            // if genreIndex is larger or equal than 1
            if self.genreIndex >= 1 
            {
                // yes, we can saftely decrease genreIndex by 1
                self.genreIndex -= 1
                // render this window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key left (move up one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            // if genreText count is greated than a page size
            if self.genreIndex > 0 && self.genreText.count > (g_rows-7) {
                // if genreIndex - page size is greater than 0
                if self.genreIndex - (g_rows-7) > 0 {
                    // subtract page size form genreIndex
                    self.genreIndex -= (g_rows-7) - 1
                }
                // no is smaller
                else {
                    // we are at start, set genreIndex to 0
                    self.genreIndex = 0
                }
                // render this window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key right (move down one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in
            // if genreText count is greated than a page size
            if self.genreIndex >= 0 && self.genreText.count > (g_rows-7) {
                // if genreIndex + page size is less than genreText count minus a page size
                // (can we move a page down)
                if self.genreIndex + (g_rows-7) < self.genreText.count - (g_rows-7) {
                    // yes add a page to index
                    self.genreIndex += (g_rows-7) - 1
                }
                // no we are at end
                else {
                    // set genreIndex to genreText - a page size
                    self.genreIndex = self.genreText.count - (g_rows-7) + 1
                    // if genreIndex happens to be < 0
                    if self.genreIndex < 0 {
                        // set genreIndex to 0
                        self.genreIndex = 0
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
}// GenreWindow
