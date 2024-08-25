//
//  ModeWindow.swift
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
    private var modeText: [String] = []
    private var inMode: Bool = false
    private var searchResult: [SongEntry] = g_searchResult
    private var searchIndex: Int = 0    
    ///
    /// Shows this AboutWindow on screen.
    ///
    func showWindow() -> Void {
        self.searchIndex = 0
        self.updateModeText()
        
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
    func updateModeText() -> Void
    {
        self.modeText.removeAll()
        
        guard g_modeSearch.count == g_modeSearchStats.count else {
            return
        }
        
        if g_searchType.count > 0 {
            self.inMode = true
        }
        
        var i: Int = 0
        for type in g_searchType {
            self.modeText.append("\(type.rawValue)")
            for j in 0..<g_modeSearch[i].count {
                self.modeText.append(" :: \(g_modeSearch[i][j]), \(g_modeSearchStats[i][j]) Songs")
            }
            i += 1
        }
        
        self.modeText.append(" ");
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
        let songNoColor = ConsoleColor.cyan
        
        Console.printXY(1,3,":: MODE ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        Console.printXY(1,4,"mode is: \((g_searchType.count > 0) ? "on" : "off")", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)

        var index_screen_lines: Int = 5
        var index_search: Int = self.searchIndex    
        let max = self.modeText.count + self.searchResult.count
        if PlayerPreferences.viewType == ViewType.Default {
            let layout: MainWindowLayout = MainWindowLayout.get()
            while index_search < max {
                if index_screen_lines >= (g_rows-3) {
                    break
                }
                
                if index_search > ((self.modeText.count + self.searchResult.count) - 1) {
                    break
                }
                
                if index_search < self.modeText.count {
                    let mt = self.modeText[index_search]
                    
                    if mt.hasPrefix(" ::") {
                        Console.printXY(1, index_screen_lines, mt, 80, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    }
                    else {
                        Console.printXY(1, index_screen_lines, mt, 80, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
                    }
                }
                else {
                    let se = self.searchResult[index_search-self.modeText.count]
                
                    Console.printXY(layout.songNoX, index_screen_lines, "\(se.songNo) ", layout.songNoCols, .right, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
                
                    Console.printXY(layout.artistX, index_screen_lines, "\(se.artist)", layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)

                    Console.printXY(layout.titleX, index_screen_lines, "\(se.title)", layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                
                    Console.printXY(layout.durationX, index_screen_lines, itsRenderMsToFullString(se.duration, false), layout.durationCols, .ignore, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                }
                index_screen_lines += 1
                index_search += 1
            }
        }
        else if PlayerPreferences.viewType == ViewType.Details { 
            let layout: MainWindowLayout = MainWindowLayout.get()          
            while index_search < max {
                if index_screen_lines >= (g_rows-3) {
                    break
                }
                
                if index_search >= (self.modeText.count + self.searchResult.count) {
                    break
                }
                
                if index_search < self.modeText.count {
                    let mt = self.modeText[index_search]
                    
                    if mt.hasPrefix(" ::") {
                        Console.printXY(1, index_screen_lines, mt, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    }
                    else {
                        Console.printXY(1, index_screen_lines, mt, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
                    }
                    
                    index_screen_lines += 1
                    index_search += 1
                }
                else {
                    let song = self.searchResult[index_search-self.modeText.count]
                    
                    Console.printXY(layout.songNoX, index_screen_lines, "\(song.songNo) ", layout.songNoCols, .right, " ", bgColor, ConsoleColorModifier.none, songNoColor, ConsoleColorModifier.bold)
                    Console.printXY(layout.songNoX, index_screen_lines+1, " ", layout.songNoCols, .right, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    
                    Console.printXY(layout.artistX, index_screen_lines, song.artist, layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    Console.printXY(layout.artistX, index_screen_lines+1, song.albumName, layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    
                    Console.printXY(layout.titleX, index_screen_lines, song.title, layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    Console.printXY(layout.titleX, index_screen_lines+1, song.genre, layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    
                    let timeString: String = itsRenderMsToFullString(song.duration, false)
                    let endTimePart: String = String(timeString[timeString.index(timeString.endIndex, offsetBy: -5)..<timeString.endIndex])
                    Console.printXY(layout.durationX, index_screen_lines, endTimePart, layout.durationCols, .ignore, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    
                    Console.printXY(layout.durationX, index_screen_lines+1, " ", layout.durationCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                    
                    index_screen_lines += 2
                    index_search += 1
                }                
            }
        }       

        Console.printXY(1,g_rows-3," ", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold) 
        Console.printXY(1,g_rows-1,"PRESS ANY KEY TO EXIT", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        Console.printXY(1,g_rows,"\(g_searchResult.count.itsToString()) Songs", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        
        Console.gotoXY(g_cols,1)
        print("")
    }          
    ///
    /// Runs AboutWindow keyboard input and feedback.
    ///
    func run() -> Void {
        Console.clearScreenCurrentTheme()
        self.searchIndex = 0        
        self.renderWindow()
        
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            if PlayerPreferences.viewType == ViewType.Default {
                if (self.searchIndex + (g_rows-7)) <= (self.modeText.count+self.searchResult.count) {
                    self.searchIndex += 1
                    self.renderWindow()
                }
            }
            else if PlayerPreferences.viewType == ViewType.Details {
                if (self.searchIndex + ((g_rows-7)/2)) < (self.modeText.count+self.searchResult.count) {
                    self.searchIndex += 1
                    self.renderWindow()
                }
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            if self.searchIndex >= 1 {
                self.searchIndex -= 1
                self.renderWindow()
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in            
            if PlayerPreferences.viewType == ViewType.Default {
                if self.searchIndex >= (g_rows-7) {
                    self.searchIndex -= (g_rows-7)                    
                }
                else {
                    self.searchIndex = 0                    
                }   
                self.renderWindow()     
            }
            else if PlayerPreferences.viewType == ViewType.Details {
                if self.searchIndex >= self.modeText.count {
                    if (self.searchIndex - ((g_rows-7)/2)) > 0 {
                        self.searchIndex -= ((g_rows-7)/2)
                        if self.searchIndex < 0 {
                            self.searchIndex = 0
                        }
                    }
                    else {
                        self.searchIndex = 0                        
                    }                    
                }
                else {
                    self.searchIndex = 0
                }
                self.renderWindow()
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in            
            if PlayerPreferences.viewType == ViewType.Default {
                if self.searchIndex >= 0 && (self.modeText.count+self.searchResult.count) > (g_rows-7) {
                    if self.searchIndex + (g_rows-7) < ((self.modeText.count+self.searchResult.count) - (g_rows-7)) {
                        self.searchIndex += (g_rows-7) - 1
                    }
                    else {
                        self.searchIndex = (self.modeText.count+self.searchResult.count) - (g_rows-7) + 1
                        if (self.searchIndex < 0) {
                            self.searchIndex = 0
                        }
                    }                    
                }             
                self.renderWindow()
            }
            else if PlayerPreferences.viewType == ViewType.Details {
                if self.searchIndex >= 0 && (self.modeText.count+self.searchResult.count) > (g_rows-7) {
                    if self.searchIndex + ((g_rows-7)/2) < ((self.modeText.count+self.searchResult.count) - ((g_rows-7)/2)) {
                        self.searchIndex += ((g_rows-7)/2) 
                    }
                    else {
                        self.searchIndex = (self.modeText.count+self.searchResult.count) - ((g_rows-7)/2)
                        if (self.searchIndex < 0) {
                            self.searchIndex = 0
                        }
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
}// ModeWindow
