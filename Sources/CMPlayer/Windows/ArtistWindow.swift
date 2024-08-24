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
    private var artistIndex: Int = 0
    private var artistText: [String] = []    
    ///
    /// Shows this AboutWindow on screen.
    ///
    func showWindow() -> Void {
        self.artistIndex = 0
        
        self.updateArtistText()
        
        g_tscpStack.append(self)
        Console.clearScreenCurrentTheme()
        self.renderWindow()
        self.run()
        
        g_tscpStack.removeLast()
    }    
    ///
    /// TerminalSizeChangedProtocol method
    ///
    func terminalSizeHasChanged() -> Void {
        Console.clearScreenCurrentTheme()
        self.renderWindow()
    }    
    ///
    /// Updates the genere text array. Called before visual showing.
    ///
    func updateArtistText() -> Void
    {
        self.artistText.removeAll()
        
        let sorted = g_artists.sorted { $0.key < $1.key }
        
        for g in sorted {
            let name = g.key
            let desc = " :: \(g.value.count) Songs"
    
            self.artistText.append(name)
            self.artistText.append(desc)
        }
    }    
    ///
    /// Renders screen output. Does clear screen first.
    ///
    func renderWindow() -> Void {
        if g_rows < 24 || g_cols < 80 {
            return
        }
        
        Console.clearScreenCurrentTheme()
        MainWindow.renderHeader(showTime: false)
        
        let bgColor = getThemeBgColor()
        Console.printXY(1,3,":: ARTIST ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        Console.printXY(1,4,"mode artist is: \((isSearchTypeInMode(SearchType.Artist)) ? "on" : "off")", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        
        var index_screen_lines: Int = 5
        var index_search: Int = self.artistIndex
        let max = self.artistText.count
        while index_search < max {
            if index_screen_lines >= (g_rows-3) {
                break
            }
            
            if index_search >= artistText.count {
                break
            }
            
            let se = artistText[index_search]
            
            if index_search % 2 == 0 {
                Console.printXY(1, index_screen_lines, se, 80, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
            }
            else {
                Console.printXY(1, index_screen_lines, se, 80, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            }
            
            index_screen_lines += 1
            index_search += 1
        }
        
        Console.printXY(1,g_rows-1,"PRESS ANY KEY TO EXIT", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        
        Console.printXY(1,g_rows,"\(g_artists.count.itsToString()) Artists", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        
        Console.gotoXY(g_cols,1)
        print("")
    }
    ///
    /// Runs AboutWindow keyboard input and feedback.
    ///
    func run() -> Void {
        Console.clearScreenCurrentTheme()
        self.artistIndex = 0
        self.renderWindow()
        
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            if (self.artistIndex + (g_rows-7)) <= self.artistText.count {
                self.artistIndex += 1
                self.renderWindow()
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            if self.artistIndex >= 1 {
                self.artistIndex -= 1
                self.renderWindow()
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            if self.artistIndex > 0 && self.artistText.count > (g_rows-7) {
                if self.artistIndex - (g_rows-7) > 0 {
                    self.artistIndex -= (g_rows-7) - 1
                }
                else {
                    self.artistIndex = 0
                }
                self.renderWindow()
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in
            if self.artistIndex >= 0 && self.artistText.count > (g_rows-7) {
                if self.artistIndex + (g_rows-7) < self.artistText.count - (g_rows-7) {
                    self.artistIndex += (g_rows-7) - 1
                }
                else {
                    self.artistIndex = self.artistText.count - (g_rows-7) + 1
                    if (self.artistIndex < 0) {
                        self.artistIndex = 0
                    }
                }
                self.renderWindow()
            }
            return false
        })
        keyHandler.addUnknownKeyHandler(closure: { (key: UInt32) -> Bool in
            return true
        })
        keyHandler.run()
    }// run
}// ArtistWindow
