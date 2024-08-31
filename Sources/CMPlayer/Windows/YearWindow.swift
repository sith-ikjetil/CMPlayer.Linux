//
//  YearWindow.swift
//
//  (i): Shows all years with count of songs in each year. 
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//

//
// import
//
import Foundation

///
/// Represents CMPlayer RecordingYearWindow.
///
internal class YearWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    ///
    /// private variables
    ///
    private var yearIndex: Int = 0          // index into yearText
    private var yearText: [String] = []     // text to show on screen
    ///
    /// Shows this AboutWindow on screen.
    ///
    func showWindow() -> Void {
        // set yearIndex to first item in yearText
        self.yearIndex = 0
        // update yearText array
        self.updateRecordingYearsText()
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
    func updateRecordingYearsText() -> Void
    {
        // update yearText
        // remove all items first
        self.yearText.removeAll()
        // sort all items in g_recordingYears
        let sorted = g_recordingYears.sorted { $0.key < $1.key }
        // loop thorugh all years in sorted
        for g in sorted { 
            // set year string
            let name = String(g.key)
            // create a string that contains count of all songs in that year
            let desc = " :: \(g.value.count) Songs"
            // append name to yearText
            self.yearText.append(name)
            // append desc to yearText
            self.yearText.append(desc)
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
        Console.printXY(1,3,":: RECORDING YEAR ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        // render mode information
        Console.printXY(1,4,"mode year is: \((isSearchTypeInMode(SearchType.RecordedYear)) ? "on" : "off")", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // line index on screen. start at 5
        var index_screen_lines: Int = 5
        // index into yearText
        var index_search: Int = yearIndex
        // max index_search
        let max = self.yearText.count
        // loop while index_search is less than max but...
        while index_search < max {
            // if index_screen_lines is reaching forbidden area on screen
            if index_screen_lines >= (g_rows-3) {
                // discontinue loop
                break
            }
            // if index_search has reached yearText.count
            if index_search >= yearText.count {
                // discontinue loop
                break
            }
            // set se to yearText item
            let se = yearText[index_search]
            // if even row
            if index_search % 2 == 0 {
                // render title (year in cyan)
                Console.printXY(1, index_screen_lines, se, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
            }
            // else if odd row
            else {
                // sub title (song count in white)
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
        Console.printXY(1,g_rows,"\(g_recordingYears.count.itsToString()) Recorded Years", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
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
        // set yearIndex to the beginning = 0
        self.yearIndex = 0
        // render this window
        self.renderWindow()
        // create a ConsoleKeyboardHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        // add key handler for key down (move down one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            // if yearIndex + page size <= yearText.count
            if (self.yearIndex + (g_rows-7)) <= self.yearText.count {
                // increment yearIndex (move down one line)
                self.yearIndex += 1
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key up (move up one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            // if yearIndex is at least 1
            if self.yearIndex >= 1 {
                // saftley decrement yearIndex (move up one line)
                self.yearIndex -= 1
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key left (move up one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            // if yearText count is > page size
            if self.yearIndex > 0 && self.yearText.count > (g_rows-7) {
                // if yearIndex - page size > 0
                if self.yearIndex - (g_rows-7) > 0 {
                    // we can saftely decrement page size and move up one page
                    self.yearIndex -= (g_rows-7) - 1
                }
                // else we are at first page
                else {
                    // set yearIndex to start = 0
                    self.yearIndex = 0
                }
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key right (move down one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in
            // if yearText count > page size
            if self.yearIndex >= 0 && self.yearText.count > (g_rows-7) {
                // if yearIndex + page size < yearText count - page size
                if self.yearIndex + (g_rows-7) < self.yearText.count - (g_rows-7) {
                    // we are not at last page, so increment by a page size and move down one page
                    self.yearIndex += (g_rows-7) - 1
                }
                // else we are at last page
                else {
                    // set yearIndex to last page
                    self.yearIndex = self.yearText.count - (g_rows-7) + 1
                    // should yearIndex be negative handle it
                    if self.yearIndex < 0 {
                        // set yearIndex to start = 0
                        self.yearIndex = 0
                    }
                }
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        keyHandler.addUnknownKeyHandler(closure: { (key: UInt32) -> Bool in
            // return from run()
            return true
        })
        keyHandler.run()
    }// run
}// YearWindow
