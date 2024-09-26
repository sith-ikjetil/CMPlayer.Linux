//
//  ScriptWindow.swift
//
//  (i): Shows all script files in scripts subfolder.
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
internal class ScriptWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    ///
    /// Private properties/constants.
    ///
    private var scriptIndex: Int = 0         // start index into genreText we currently are rendering
    private var scriptText: [String] = []    // line 1: genre text, line 2: count songs in that genre. repeat for all genres.
    ///
    /// Shows this AboutWindow on screen.
    ///
    func showWindow() -> Void {
        // set genreIndex to first item in artistText
        self.scriptIndex = 0
        // update genreText array
        self.updateScriptText()
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
    /// Updates the scripts text array. Called before visual showing.
    ///
    func updateScriptText() -> Void
    {
        // update genreText
        // remove all items first
        self.scriptText.removeAll()
        FileManager.default.enumerator(atPath: PlayerDirectories.consoleMusicPlayerScriptsDirectory.path)?.forEach { (item) in
            if let item: String = item as? String {
                var isDir : ObjCBool = false
                let filePath: String = PlayerDirectories.consoleMusicPlayerScriptsDirectory.path + "/" + item
                if FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir) {
                    if !isDir.boolValue {
                        self.scriptText.append(item)
                    }
                }
            }
        }        
        // sort scriptText alphabetically
        let sorted = self.scriptText.sorted { $0 < $1 }
        // remove all items first
        self.scriptText.removeAll()
        // loop through all filenames in sorted
        for g in sorted {            
            // append to scriptText alphabetically sorted
            self.scriptText.append(g)
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
        //Console.clearScreenCurrentTheme()
        // render header
        MainWindow.renderHeader(showTime: false)  
        // render empty line
        Console.printXY(1,2," ", g_cols, .center, " ", getThemeBgEmptySpaceColor(), getThemeBgEmptySpaceModifier(), getThemeFgEmptySpaceColor(), getThemeFgEmptySpaceModifier())      
        // render title
        Console.printXY(1,3,":: SCRIPT ::", g_cols, .center, " ", getThemeBgTitleColor(), getThemeBgTitleModifier(), getThemeFgTitleColor(), getThemeFgTitleModifier())        
        // line index on screen. start at 5
        var index_screen_lines: Int = 5
        // index into genreText
        var index_search: Int = self.scriptIndex
        // max index_search
        let max = self.scriptText.count
        // loop while index_search is less than max but...
        while index_search < max {
            // if index_screen_lines is reaching forbidden area on screen
            if index_screen_lines > (g_rows-3) {
                // discontinue loop
                break
            }
            // if index_search has reached genreText.count
            if index_search >= scriptText.count {
                // discontinue loop
                break
            }
            // set se to genreText item
            let se = scriptText[index_search]
            // render row (script file)
            Console.printXY(1, index_screen_lines, se, g_cols, .left, " ", getThemeBgQueueColor(), getThemeBgQueueModifier(), getThemeFgQueueColor(), getThemeFgQueueModifier())            
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
        Console.printXY(1,g_rows,"\(self.scriptText.count.itsToString()) Script Files", g_cols, .center, " ", getThemeBgStatusLineColor(), getThemeBgStatusLineModifier(), getThemeFgStatusLineColor(), getThemeFgStatusLineModifier())
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
        self.scriptIndex = 0
        // render this window
        self.renderWindow()        
        // create a ConsoleKeyboardHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        // add key handler for key down (move down one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            // if genreIndex plus a page size is less than genreText count
            if (self.scriptIndex + (g_rows-7)) <= self.scriptText.count {
                // yes, we can safetely increase genreIndex by 1
                self.scriptIndex += 1
                // render this window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key up (move up one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            // if genreIndex is larger or equal than 1
            if self.scriptIndex >= 1 
            {
                // yes, we can saftely decrease genreIndex by 1
                self.scriptIndex -= 1
                // render this window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key left (move up one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            // if genreText count is greated than a page size
            if self.scriptIndex > 0 && self.scriptText.count > (g_rows-7) {
                // if genreIndex - page size is greater than 0
                if self.scriptIndex - (g_rows-7) > 0 {
                    // subtract page size form genreIndex
                    self.scriptIndex -= (g_rows-7) - 1
                }
                // no is smaller
                else {
                    // we are at start, set genreIndex to 0
                    self.scriptIndex = 0
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
            if self.scriptIndex >= 0 && self.scriptText.count > (g_rows-7) {
                // if genreIndex + page size is less than genreText count minus a page size
                // (can we move a page down)
                if self.scriptIndex + (g_rows-7) < self.scriptText.count - (g_rows-7) {
                    // yes add a page to index
                    self.scriptIndex += (g_rows-7) - 1
                }
                // no we are at end
                else {
                    // set genreIndex to genreText - a page size
                    self.scriptIndex = self.scriptText.count - (g_rows-7) + 1
                    // if genreIndex happens to be < 0
                    if self.scriptIndex < 0 {
                        // set genreIndex to 0
                        self.scriptIndex = 0
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
}// ScriptWindow
