//
//  SetupWindow.swift
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//

//
// import
//
import Foundation

///
/// Represents CMPlayer InitialSetupWindow.
///
internal class SetupWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    ///
    /// private constants
    ///
    private let concurrentQueue = DispatchQueue(label: "dqueue.cmp.linux.setup-window.1", attributes: .concurrent)
    private let setupText: [String] = ["CMPlayer needs to have a path to search for music",
                                       "In CMPlayer you can have many root paths.",
                                       "In CMPlayer Use: add mrp <path> or: remove mrp <path> to add remove path.",
                                       "Please enter the path to the root directory of where your music resides."]
    //
    // variables
    //
    var path: String = ""
    var cursor: String = ""
    var finished: Bool = false    
    ///
    /// Shows this InitialSetupWindow on screen.
    ///
    func showWindow() -> Void {
        g_tscpStack.append(self)

        let musicDefaultPath: URL = PlayerDirectories.homeDirectory.appendingPathComponent("Music", isDirectory: false)
        self.path = musicDefaultPath.path

        concurrentQueue.async {

            while !self.finished {
                if self.cursor.count > 0 {
                    self.cursor = ""
                }
                else {
                    self.cursor = "_"
                }

                self.renderInput()

                let second: Double = 1_000_000
                usleep(useconds_t(0.075 * second))
            }
        }

        self.run()
        g_tscpStack.removeLast()
    }    
    ///
    /// TerminalSizeChangedProtocol method
    ///
    func terminalSizeHasChanged() -> Void {
        Console.clearScreen()
        self.renderWindow()
    }    
    ///
    /// Renders screen output. Does clear screen first.
    ///
    /// parameter path: Path to render on screen.
    ///
    func renderWindow() -> Void {
        guard isWindowSizeValid() else {
            renderTerminalTooSmallMessage()
            return
        }
        
        Console.clearScreenCurrentTheme()
        MainWindow.renderHeader(showTime: false)
        
        Console.printXY(1,3,":: SETUP ::", g_cols, .center, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        
        var y: Int = 5
        for txt in self.setupText {
            Console.printXY(1, y, txt, g_cols, .center, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            y += 1
        }

        self.renderInput()                
        
        Console.gotoXY(g_cols,1)
        print("")
    }   
    ///
    /// renders path input only
    ///  
    func renderInput() {
        Console.printXY(1,5+self.setupText.count + 1, ":> \(self.path)\(self.cursor)", g_cols, .left, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
    }
    ///
    /// Runs InitialSetupWindow keyboard input and feedback.
    ///
    /// returns: Bool. True if path entered, false otherwise.
    ///
    func run() -> Void {
        Console.clearScreen()
        self.renderWindow()
        
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()        
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_BACKSPACE.rawValue, closure: { () -> Bool in
            if self.path.count > 0 {
                self.path.removeLast()
                self.renderWindow()
            }
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_ENTER.rawValue, closure: { () -> Bool in
            if self.path.count > 0 {
                if !FileManager.default.fileExists(atPath: self.path) {
                    return false
                }
                self.finished = true
                PlayerPreferences.musicRootPath.append(self.path)
                PlayerPreferences.savePreferences()
                return true
            }
            return false
        })
        keyHandler.addCharacterKeyHandler(closure: { (ch: Character) -> Bool in
            self.path.append(String(ch))
            self.renderWindow()
            
            return false
        })
        keyHandler.run()
    }// run
}// SetupWindow
