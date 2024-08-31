//
//  AboutWindow.swift
//
//  (i): Shows about information on screen.
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
internal class AboutWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    ///
    /// private variables
    ///
    private var aboutIndex: Int = 0 // index into aboutText
    ///
    /// private constants
    /// 
    private let aboutText: [String] = ["   CMPlayer (Console Music Player) is a clone and improvement over the",
                                       "   Interactive DJ software written in summer 1997 running on DOS.",
                                       "   ",
                                       "   The CMPlayer software runs on Linux as a console application.",
                                       "   ",
                                       "   CMPlayer is a different kind of music player. It selects random songs",
                                       "   from your library and runs to play continually. You choose music",
                                       "   by searching for them, and in the main window entering the number",
                                       "   associated with the song to add to the playlist.",
                                       "   ",
                                       "   CMPlayer was made by Kjetil Kristoffer Solberg <post@ikjetil.no>",
                                       "   ",
                                       "   ENJOY!"] // String to show on this windows screen   
    ///
    /// Shows this AboutWindow on screen.
    ///
    func showWindow() -> Void {
        // set aboutIndex to first aboutText item
        self.aboutIndex = 0
        // add to top this window to terminal size change protocol stack
        g_tscpStack.append(self)
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // run, modal call
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
    /// Renders screen output. Does clear screen first.
    ///
    func renderWindow() -> Void {
        // if window size is invalid
        guard isWindowSizeValid() else {   
            // render terminal too small message         
            renderTerminalTooSmallMessage()
            // return
            return
        }        
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render header
        MainWindow.renderHeader(showTime: false)        
        //  create bgColor constant with current theme bg color
        let bgColor = getThemeBgColor()
        // render title
        Console.printXY(1,3,":: ABOUT ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)        
        // set index_screen_lines to start at line 5
        var index_screen_lines: Int = 5
        // set index_search to aboutIndex
        var index_search: Int = self.aboutIndex
        // set max to aboutText count
        let max = self.aboutText.count
        // while we are rendering less than max
        while index_search < max {
            // if index_screen_lines is greather than g_rows - 3 we discontiue loop
            if index_screen_lines > (g_rows - 3) {
                // discontinue loop
                break
            }
            // if index into aboutText is greater or equal to aboutText.count discontinue loop
            if index_search >= self.aboutText.count {
                // discontinue loop
                break
            }            
            // set se to current item in aboutText
            let se = self.aboutText[index_search]
            // render item in abouText
            Console.printXY(1, index_screen_lines, se, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            // increase index_screen_lines by 1 (y coordinate)
            index_screen_lines += 1
            // increase index_search by 1 (aboutText index)
            index_search += 1
        }
        // render status line
        Console.printXY(1,g_rows-1,"PRESS ANY KEY TO EXIT", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
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
        // set aboutIndex to 0
        self.aboutIndex = 0
        // render this window
        self.renderWindow()
        // create a ConsoleKeyboardHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        // add key handler for key down (move down one line)        
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            // if we have rendered less than abouText.count
            if (self.aboutIndex + (g_rows-7)) <= self.aboutText.count {
                // increase aboutIndex by 1
                self.aboutIndex += 1
                // render this window
                self.renderWindow()
            }
            // do not return from run()
            return false
        })
        // add key handler for key up (move up one line)        
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            // if aboutIndex is greater than 0
            if self.aboutIndex > 0 {
                // decrease abouIndex by 1
                self.aboutIndex -= 1
                // render window
                self.renderWindow()
            }
            // do not return from run()
            return false
        })
        // add key handler for key left (move up one page)        
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            // if abouIndex > 0 and we have more text in aboutText than fits the window
            if self.aboutIndex > 0 && self.aboutText.count > (g_rows-7) {
                // if aboutIndex - one page is > 0
                if self.aboutIndex - (g_rows-7) > 0 {
                    // decrease aboutIndex by one page
                    self.aboutIndex -= (g_rows-7) - 1
                }
                // abouIndex should be 0, we've moved to the top
                else {
                    // set aboutIndex to 0
                    self.aboutIndex = 0
                }
                // render this window
                self.renderWindow()
            }
            // do not return from run()
            return false
        })
        // add key handler for key right (move down one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in
            // if aboutIndex > 0 we have more text left in aboutText then next window size
            if self.aboutIndex >= 0 && self.aboutText.count > (g_rows-7) {
                // if aboutIndex + 1 page is less than aboutText.count - one Page
                if self.aboutIndex + (g_rows-7) < self.aboutText.count - (g_rows-7) {
                    // add to aboutIndex one page more
                    self.aboutIndex += (g_rows-7) - 1
                }
                // we are at last page
                else {
                    // set aboutIndex to aboutText - 1 page 
                    self.aboutIndex = self.aboutText.count - (g_rows-7) + 1
                    // if we have a negative aboutIndex
                    if self.aboutIndex < 0 {
                        // set aboutIndex to 0
                        self.aboutIndex = 0
                    }
                }
                // render this page
                self.renderWindow()
            }
            // do not return from run()
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
}// AboutWindow
