//
//  HelpWindow.swift
//
//  (i): Shows help information on screen.
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
internal class HelpWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    ///
    /// private variables
    ///
    private var helpIndex: Int = 0  // index into helpText to start rendering max one page at a time
    ///
    /// private constants
    /// 
    private let helpText: [String] = [" <song no>", " :: adds song no to playlist",
                                      " exit, quit, q", " :: exits application",
                                      " next, skip, n, s, 'TAB'-key", " :: plays next song",
                                      " play, p", " :: plays music",
                                      " pause, p", " :: pauses music",
                                      " resume", " :: resumes music playback",
                                      " search [<words>]", " :: searches artist and title for a match. case insensitive",
                                      " search artist [<words>]", " :: searches artist for a match. case insensitive",
                                      " search title [<words>]", " :: searches title for a match. case insensitive",
                                      " search album [<words>]", " :: searches album name for a match. case insensitive",
                                      " search genre [<words>]", " :: searches genre for a match. case insensitive",
                                      " search year [<year>]", " :: searches recorded year for a match.",
                                      " mode off", " :: clears mode playback. playback now from entire song library",
                                      " help"," :: shows this help information",
                                      " pref", " :: shows preferences information",
                                      " about"," :: show the about information",
                                      " genre"," :: shows all genre information and statistics",
                                      " year", " :: shows all year information and statistics",
                                      " mode", " :: shows current mode information and statistics",
                                      " repaint", " :: clears and repaints entire console window",
                                      " add mrp <path>", " :: adds the path to music root path",
                                      " remove mrp <path>", " :: removes the path from music root paths",
                                      " clear mrp", " :: clears all paths from music root paths",
                                      " add exp <path>", " :: adds the path to exclusion paths",
                                      " remove exp <path>", " :: removes the path from exclusion paths",
                                      " clear exp", " :: clears all paths from exclusion paths",
                                      " set cft <seconds>", " :: sets the crossfade time in seconds (1-10 seconds)",                                      
                                      " enable crossfade"," :: enables crossfade",
                                      " disable crossfade", " :: disables crossfade",
                                      //" set mf <formats>", " :: sets the supported music formats (separated by ;)",
                                      " enable aos", " :: enables playing on application startup",
                                      " disable aos", " :: disables playing on application startup",
                                      " rebuild songno"," :: rebuilds song numbers",
                                      " goto <mm:ss>", " :: moves playback point to minutes (mm) and seconds (ss) of current song",
                                      " replay", " :: starts playing current song from beginning again",
                                      " reinitialize <1>", " :: reinitializes library (optional 1 = also rebuild song no)",
                                      " info", " :: shows information about first song in playlist",
                                      " info <song no>", " :: show information about song with given song number",
                                      //" update cmplayer", " :: updates cmplayer if new version is found online",
                                      " set viewtype <type>", " :: sets view type. can be 'default' or 'details'",
                                      " set theme <name>", " :: sets theme. name can be 'default', 'blue', 'black' or 'custom'",
                                      " clear history", " :: clears command history",
                                      " set custom-theme fgHeaderColor <color> <bold/none>", " :: sets foreground color of header text",
                                      " set custom-theme bgHeaderColor <color> <bold/none>", " :: sets background color of header text",
                                      " set custom-theme fgTitleColor <color> <bold/none>", " :: sets foreground color of title text",
                                      " set custom-theme bgTitleColor <color> <bold/none>", " :: sets background color of title text",
                                      " set custom-theme fgSeparatorColor <color> <bold/none>", " :: sets foreground color of separator line",
                                      " set custom-theme bgSeparatorColor <color> <bold/none>", " :: sets background color of separator line",
                                      " set custom-theme fgQueueColor <color> <bold/none>", " :: sets foreground color of queue text",
                                      " set custom-theme bgQueueColor <color> <bold/none>", " :: sets background color of queue text",
                                      " set custom-theme fgQueueSongNoColor <color> <bold/none>", " :: sets foreground color of song no in queue text",
                                      " set custom-theme bgQueueSongNoColor <color> <bold/none>", " :: sets background color of song no in queue text",
                                      " set custom-theme fgCommandLineColor <color> <bold/none>", " :: sets foreground color of command line text",
                                      " set custom-theme bgCommandLineColor <color> <bold/none>", " :: sets background color of command line text",
                                      " set custom-theme fgStatusLineColor <color> <bold/none>", " :: sets foreground color of status line text",
                                      " set custom-theme bgStatusLineColor <color> <bold/none>", " :: sets background color of status line text",
                                      " set custom-theme fgAddendumColor <color> <bold/none>", " :: sets foreground color of addendum text",
                                      " set custom-theme bgAddendumColor <color> <bold/none>", " :: sets background color of addendum text",
                                      " set custom-theme fgEmptySpaceColor <color> <bold/none>", " :: sets foreground color of empty text",
                                      " set custom-theme bgEmptySpaceColor <color> <bold/none>", " :: sets background color of empty text",
                                      " set custom-theme separatorChar <char>", " :: sets char for separator line",
                                      " custom-theme colors", " :: 'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan' or 'white'"]
                                      //" restart", " :: restarts the application. picks up changes when files are removed or added"]    
    ///
    /// Shows this HelpWindow on screen.q
    ///
    func showWindow() -> Void {
        // set artistIndex to first item in artistText
        self.helpIndex = 0
        // add to top this window to terminal size change protocol stack
        g_tscpStack.append(self)
        // clear screen current theme
        Console.clearScreenCurrentTheme()
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
        //Console.clearScreenCurrentTheme()
        // render header
        MainWindow.renderHeader(showTime: false)  
        // render empty line
        Console.printXY(1,2," ", g_cols, .center, " ", getThemeBgEmptySpaceColor(), getThemeBgEmptySpaceModifier(), getThemeFgEmptySpaceColor(), getThemeFgEmptySpaceModifier())      
        // render title
        Console.printXY(1,3,":: HELP ::", g_cols, .center, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())
        // render empty line
        Console.printXY(1,4," ", g_cols, .center, " ", getThemeBgEmptySpaceColor(), getThemeBgEmptySpaceModifier(), getThemeFgEmptySpaceColor(), getThemeFgEmptySpaceModifier())
        // line index on screen. start at 5
        var index_screen_lines: Int = 5
        // index into helpText
        var index_search: Int = self.helpIndex
        // max index_search
        let max = self.helpText.count
        // loop while index_search is less than max but...
        while index_search < max {
            // if index_screen_lines is reaching forbidden area on screen
            if index_screen_lines > (g_rows - 3) {
                // discontinue loop
                break
            }
            // if index_search has reached helpText count
            if index_search >= helpText.count {
                // discontinue loop
                break
            }
            // set se to helpText item
            let se = helpText[index_search]
            // if even row
            if index_search % 2 == 0 {
                // print help title in cyan
                Console.printXY(1, index_screen_lines, se, g_cols, .left, " ", getThemeBgQueueSongNoColor(), getThemeBgQueueSongNoModifier(), getThemeFgQueueSongNoColor(), getThemeFgQueueSongNoModifier())
            }
            // else odd
            else {
                // print help text in white
                Console.printXY(1, index_screen_lines, se, g_cols, .left, " ", getThemeBgQueueColor(), getThemeBgQueueModifier(), getThemeFgQueueColor(), getThemeFgQueueModifier())
            }
            // increase index_screen_lines by 1 for next round of loop
            index_screen_lines += 1
            // increase index_search by 1 for next round of loop
            index_search += 1
        }
        // render the last of the lines empty
        while index_screen_lines <= (g_rows-3) {
            // render line
            Console.printXY(1, index_screen_lines, " ", g_cols, .left, " ", getThemeBgQueueColor(), getThemeBgQueueModifier(), getThemeFgQueueColor(), getThemeFgQueueModifier())
            // increase index_search by 1
            index_screen_lines += 1
        }
        // render forbidden area
        // render empty line
        Console.printXY(1,g_rows-2," ", g_cols, .center, " ", getThemeBgEmptySpaceColor(), getThemeBgEmptySpaceModifier(), getThemeFgEmptySpaceColor(), getThemeFgEmptySpaceModifier())                
        // render information
        Console.printXY(1,g_rows-1,"PRESS ANY KEY TO EXIT", g_cols, .center, " ", getThemeBgStatusLineColor(), getThemeBgStatusLineModifier(), getThemeFgStatusLineColor(), getThemeFgStatusLineModifier())
        // render status line
        Console.printXY(1,g_rows,"\((self.helpText.count/2).itsToString()) Commands", g_cols, .center, " ", getThemeBgStatusLineColor(), getThemeBgStatusLineModifier(), getThemeFgStatusLineColor(), getThemeFgStatusLineModifier())
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
        // set self.helpIndex to 0
        self.helpIndex = 0
        // render this window
        self.renderWindow()
        // create a ConsoleKeyboardHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        // add key handler for key down (move down one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            // if helpIndex + page size is less than helpText count
            if (self.helpIndex+(g_rows-7)) <= self.helpText.count {
                // yes, we can increase helpIndex by 1 line
                self.helpIndex += 1
                // render window
                self.renderWindow()                
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key up (move up one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            // if helpIndex >= 1
            if self.helpIndex >= 1 {
                // yes we can safetly decrease index by 1
                self.helpIndex -= 1
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key left (move up one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            // if helpIndex count is larger than a page size
            if self.helpIndex > 0  && self.helpText.count > (g_rows-7) {
                // check if one page up is possible
                if (self.helpIndex - (g_rows-7)) > 0 {
                    // yes its possible do the manouver
                    self.helpIndex -= (g_rows-7) - 1
                }
                // else we will be at top
                else {
                    // at top, set helpIndex to 0
                    self.helpIndex = 0
                }
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key right (move down one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in
            // if helpText count is greater than a page size
            if self.helpIndex >= 0  && self.helpText.count > (g_rows-7) {
                // helpIndex + page size is less than helpText count - a page size
                if (self.helpIndex + (g_rows-7)) <= (self.helpText.count - (g_rows-7)) {
                    // yes we can add a page size to index
                    self.helpIndex += (g_rows-7) - 1
                }
                // else helpIndex + page size is greater than helpText.count - page size
                else {
                    // set helpIndex to helpText count - page size
                    self.helpIndex = self.helpText.count - (g_rows-7) + 1
                    // if we should get a negative value for helpIndex
                    if self.helpIndex < 0 {
                        // set helpIndex to 0
                        self.helpIndex = 0
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
}// HelpWindow
