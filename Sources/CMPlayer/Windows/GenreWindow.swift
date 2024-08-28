//
//  GenreWindow.swift
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
    private var genreIndex: Int = 0
    private var genreText: [String] = []
    
    ///
    /// Shows this AboutWindow on screen.
    ///
    func showWindow() -> Void {
        self.genreIndex = 0
        self.updateGenreText()
        
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
    func updateGenreText() -> Void
    {
        self.genreText.removeAll()
        
        let sorted = g_genres.sorted { $0.key < $1.key }
        
        for g in sorted {
            let name = g.key.lowercased()
            let desc = " :: \(g.value.count) Songs"
    
            self.genreText.append(name)
            self.genreText.append(desc)
        }
    }
    
    ///
    /// Renders screen output. Does clear screen first.
    ///
    func renderWindow() -> Void {
        guard isWindowSizeValid() else {
            renderTerminalTooSmallMessage()
            return
        }
        
        Console.clearScreenCurrentTheme()
        MainWindow.renderHeader(showTime: false)
        
        let bgColor = getThemeBgColor()
        Console.printXY(1,3,":: GENRE ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        Console.printXY(1,4,"mode genre is: \((isSearchTypeInMode(SearchType.Genre)) ? "on" : "off")", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        
        var index_screen_lines: Int = 5
        var index_search: Int = self.genreIndex
        let max = self.genreText.count
        while index_search < max {
            if index_screen_lines >= (g_rows-3) {
                break
            }
            
            if index_search >= genreText.count {
                break
            }
            
            let se = genreText[index_search]
            
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
        
        Console.printXY(1,g_rows,"\(g_genres.count.itsToString()) Genres", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        
        Console.gotoXY(g_cols,1)
        print("")
    }  
    ///
    /// Runs AboutWindow keyboard input and feedback.
    ///
    func run() -> Void {
        Console.clearScreenCurrentTheme()
        self.genreIndex = 0
        self.renderWindow()
        
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            if (self.genreIndex + (g_rows-7)) <= self.genreText.count {
                self.genreIndex += 1
                self.renderWindow()
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            if self.genreIndex > 0 {
                self.genreIndex -= 1
                self.renderWindow()
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            if self.genreIndex > 0 && self.genreText.count > (g_rows-7) {
                if self.genreIndex - (g_rows-7) > 0 {
                    self.genreIndex -= (g_rows-7) - 1
                }
                else {
                    self.genreIndex = 0
                }
                self.renderWindow()
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in
            if self.genreIndex >= 0 && self.genreText.count > (g_rows-7) {
                if self.genreIndex + (g_rows-7) < self.genreText.count - (g_rows-7) {
                    self.genreIndex += (g_rows-7) - 1
                }
                else {
                    self.genreIndex = self.genreText.count - (g_rows-7) + 1
                    if self.genreIndex < 0 {
                        self.genreIndex = 0
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
}// GenreWindow
