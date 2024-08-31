//
//  PreferencesWindow.swift
//
//  (i): Shows preferences on screen.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import
//
import Foundation
///
/// Represents CMPlayer PreferencesWindow.
///
internal class PreferencesWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    //
    // private variables
    //
    private var preferencesIndex: Int = 0           // index int preferencesText
    private var preferencesText: [String] = []      // preferences text to show on screen
    ///
    /// Shows this HelpWindow on screen.
    ///
    func showWindow() -> Void {
        // set preferencesIndex to first item in preferencesText
        self.preferencesIndex = 0
        // update preferencesText
        self.updatePreferencesText()
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
    /// Updates the preferences text based on running values.
    ///
    func updatePreferencesText() {
        // initialize preferencesText by removing any entries
        self.preferencesText.removeAll()
        // appen Music Root Paths title
        self.preferencesText.append(" Music Root Paths")
        // if we have no music root paths
        if PlayerPreferences.musicRootPath.count == 0 {
            // append empty sub item
            self.preferencesText.append(" :: ")
        }
        // else we have at least one music root paty
        else {
            // loop through all music root paths
            for path in PlayerPreferences.musicRootPath
            {
                // append path as sub item
                self.preferencesText.append(" :: \(path)")
            }
        }
        // append Exclution Paths tsitle
        self.preferencesText.append(" Exclusion Paths")
        // if we have no exclusion paths
        if PlayerPreferences.exclusionPaths.count == 0 {
            // append empty sub item
            self.preferencesText.append(" :: ")
        }
        // we have at least one exclusion path
        else {
            // loop through all exclusion paths
            for path in PlayerPreferences.exclusionPaths
            {
                // append path as sub item
                self.preferencesText.append(" :: \(path)")
            }
        }
        // append Audio Output API title
        self.preferencesText.append(" Audio Output API")
        // append audio output api subitem
        self.preferencesText.append(" :: \(PlayerPreferences.outputSoundLibrary.rawValue)")
        // append Music Formats title
        self.preferencesText.append(" Music Formats")
        // append music formats sub item
        self.preferencesText.append(" :: \(PlayerPreferences.musicFormats)")
        // append autoplay on startup title
        self.preferencesText.append(" Enable Autoplay On Startup")
        // append autoplay on startup sub item
        self.preferencesText.append(" :: \(PlayerPreferences.autoplayOnStartup)")
        // append enable crossfade title
        self.preferencesText.append(" Enable Crossfade")
        // append enable crossfade sub item
        self.preferencesText.append(" :: \(PlayerPreferences.crossfadeSongs)")
        // append crossfade time title
        self.preferencesText.append(" Crossfade Time")
        // append crossfade time sub item
        self.preferencesText.append(" :: \(PlayerPreferences.crossfadeTimeInSeconds) seconds")
        // append view type title
        self.preferencesText.append(" View Type")
        // append view type sub item
        self.preferencesText.append(" :: \(PlayerPreferences.viewType.rawValue)")
        // append theme title
        self.preferencesText.append(" Theme")
        // append theme sub item
        self.preferencesText.append(" :: \(PlayerPreferences.colorTheme.rawValue)")        
        // append history max entries title
        self.preferencesText.append(" History Max Entries")
        // append history max entries sub item
        self.preferencesText.append(" :: \(PlayerPreferences.historyMaxEntries)")        
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
        Console.printXY(1,3,":: PREFERENCES ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        // line index on screen. start at 5
        var index_screen_lines: Int = 5
        // index into preferencesText
        var index_search: Int = self.preferencesIndex
        // max index_search
        let max = self.preferencesText.count
        // loop while index_search is less than max but...
        while index_search < max {
            // if index_screen_lines is reaching forbidden area on screen
            if index_screen_lines >= (g_rows-3) {
                // discontinue loop
                break
            }
            // if index_search has reached helpText count
            if index_search >= preferencesText.count {
                // discontinue loop
                break
            }
            // set se to helpText item
            let se = preferencesText[index_search]
            // sub item
            if se.hasPrefix(" ::") {
                // render sub item
                Console.printXY(1, index_screen_lines, se, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            }
            // else item
            else {
                // render item
                Console.printXY(1, index_screen_lines, se, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
            }
            // increase index_screen_lines by 1 for next round of loop
            index_screen_lines += 1
            // increase index_search by 1 for next round of loop
            index_search += 1
        }
        // render forbidden area
        // render information
        Console.printXY(1,g_rows-1, "PRESS ANY KEY TO EXIT", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
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
        // set self.preferencesIndex to 0
        self.preferencesIndex = 0
        // render this window
        self.renderWindow()
        // create a ConsoleKeyboardHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        // add key handler for key down (move down one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            // if preferencesIndex + page size < preferencesText count
            if (self.preferencesIndex + (g_rows-7)) <= self.preferencesText.count {
                // we can saftely move down a line
                self.preferencesIndex += 1
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key up (move up one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            // if preferencesIndex >= 1
            if self.preferencesIndex >= 1 {
                // we can saftely move up one line
                self.preferencesIndex -= 1
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key left (move up one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            // preferencesText count is greater than page size
            if self.preferencesIndex > 0 && self.preferencesText.count > (g_rows-7) {
                // if preferencesIndex - page size is greater than 0
                if (self.preferencesIndex - (g_rows-7)) > 0 {
                    // we can saftely move up a page
                    self.preferencesIndex -= (g_rows-7) - 1
                }
                // else we are at top page
                else {
                    // set preferencesIndex to start = 0
                    self.preferencesIndex = 0
                }
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key right (move down one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in
            // if preferencesText count > page size
            if self.preferencesIndex >= 0 && self.preferencesText.count > (g_rows-7) {
                // if preferencesIndex + page size < preferencesText count - page size
                if self.preferencesIndex + (g_rows-7) < self.preferencesText.count - (g_rows-7) {
                    // we can saftely move down a page
                    self.preferencesIndex += (g_rows-7) - 1
                }
                // else we are at bottom page
                else {
                    // set preferences index to last page
                    self.preferencesIndex = self.preferencesText.count - (g_rows-7) + 1
                    // if preferencesIndex should be negative
                    if self.preferencesIndex < 0 {
                        // set preferencesIndex to start = 0
                        self.preferencesIndex = 0
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
        // execute run(), modal call
        keyHandler.run()
    }// run
}// Preferencesindow
