//
//  YearWindow.swift
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
    private var yearIndex: Int = 0
    private var yearText: [String] = []    
    ///
    /// Shows this AboutWindow on screen.
    ///
    func showWindow() -> Void {
        self.yearIndex = 0
        self.updateRecordingYearsText()
        
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
    func updateRecordingYearsText() -> Void
    {
        self.yearText.removeAll()
        
        let sorted = g_recordingYears.sorted { $0.key < $1.key }
        
        for g in sorted { 
            let name = String(g.key)
            let desc = " :: \(g.value.count) Songs"
            
            self.yearText.append(name)
            self.yearText.append(desc)
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
        Console.printXY(1,3,":: RECORDING YEAR ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        Console.printXY(1,4,"mode year is: \((isSearchTypeInMode(SearchType.RecordedYear)) ? "on" : "off")", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        
        var index_screen_lines: Int = 5
        var index_search: Int = yearIndex
        let max = self.yearText.count
        while index_search < max {
            if index_screen_lines >= (g_rows-3) {
                break
            }
            
            if index_search >= yearText.count {
                break
            }
            
            let se = yearText[index_search]
            
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
        
        Console.printXY(1,g_rows,"\(g_recordingYears.count.itsToString()) Recorded Years", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        
        Console.gotoXY(80,1)
        print("")
    }    
    ///
    /// Runs AboutWindow keyboard input and feedback.
    ///
    func run() -> Void {
        Console.clearScreenCurrentTheme()
        self.yearIndex = 0
        self.renderWindow()
        
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in
            if (self.yearIndex + (g_rows-7)) <= self.yearText.count {
                self.yearIndex += 1
                self.renderWindow()
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            if self.yearIndex > 0 {
                self.yearIndex -= 1
                self.renderWindow()
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in
            if self.yearIndex > 0 && self.yearText.count > (g_rows-7) {
                if self.yearIndex - (g_rows-7) > 0 {
                    self.yearIndex -= (g_rows-7) - 1
                }
                else {
                    self.yearIndex = 0
                }
                self.renderWindow()
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in
            if self.yearIndex >= 0 && self.yearText.count > (g_rows-7) {
                if self.yearIndex + (g_rows-7) < self.yearText.count - (g_rows-7) {
                    self.yearIndex += (g_rows-7) - 1
                }
                else {
                    self.yearIndex = self.yearText.count - (g_rows-7) + 1
                    if self.yearIndex < 0 {
                        self.yearIndex = 0
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
}// YearWindow
