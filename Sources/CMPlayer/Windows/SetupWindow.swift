//
//  SetupWindow.swift
//
//  (i): Setup screen where you add an initial music root path that must exist.
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
    private let setupText: [String] = ["CMPlayer needs to have a path to search for music (music root path)",
                                       "In CMPlayer you can have many root paths.",
                                       "In CMPlayer Use: add mrp <path> or: remove mrp <path> to add/remove path.",
                                       "Please enter the path to the root directory of where your music resides."]
    private let pathInvalidText1: String = "Path given does not exist."
    private let pathInvalidText2: String = "(Ctrl+C to exit, or enter a new path)"
    //
    // variables
    //
    var path: String = ""       // current path entered
    var cursor: String = ""     // cursor character
    var finished: Bool = false  // are we finished
    var showPathInvalid: Bool = false   //
    ///
    /// Shows this InitialSetupWindow on screen.
    ///
    func showWindow() -> Void {
        // add to top this window to terminal size change protocol stack
        g_tscpStack.append(self)

        let musicDefaultPath: URL = PlayerDirectories.homeDirectory.appendingPathComponent("Music", isDirectory: false)
        self.path = musicDefaultPath.path

        concurrentQueue.async {
            // loop while finished is false
            while !self.finished {
                // if cursor has a character
                if self.cursor.count > 0 {
                    // set cursor to empty string
                    self.cursor = ""
                }
                // else cursor does not have a character
                else {
                    // set cursor to a character
                    self.cursor = "_"
                }
                // if we can paint (render window/input)
                if !g_doNotPaint {
                    // render input
                    self.renderInput()
                }            
                // sleep for 75 ms
                usleep(75_000)
            }
        }
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
        Console.clearScreen()
        // render this window
        self.renderWindow()
    }    
    ///
    /// Renders screen output. Does clear screen first.
    ///
    /// parameter path: Path to render on screen.
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
        // render title
        Console.printXY(1,3,":: SETUP ::", g_cols, .center, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        // create a y coordinate variable starting from 5
        var y: Int = 5
        // loop through all setupText items
        for txt in self.setupText {
            // render setup text
            Console.printXY(1, y, txt, g_cols, .center, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
            // increment y coordinate
            y += 1
        }
        // render input
        self.renderInput() 
        // render path invalid message
        self.renderPathInvalid()                        
        // goto g_cols,1
        Console.gotoXY(g_cols,1)
        // print nothing
        print("")
    }   
    ///
    /// renders path input only
    ///  
    func renderInput() {
        // render input
        Console.printXY(1,5+self.setupText.count + 1, ":> \(self.path)\(self.cursor)", g_cols, .left, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
    }
    ///
    /// render path invalid message
    /// 
    func renderPathInvalid() {
        // create a variable to  hold the message
        var msg1: String = ""
        var msg2: String = ""
        // if showPathInvalid flag is set
        if self.showPathInvalid {
            // add pathInvalidText1 to msg variable
            msg1 += self.pathInvalidText1          
            // add pathInvalidText2 to msg variable  
            msg2 += self.pathInvalidText2
        }
        // else showPathInvalid flag is not set
        else {
            // add to msg1 variable
            msg1 += " "
            // add to msg2 variable
            msg2 += " "
        }
        // render message 1
        Console.printXY(4,5+self.setupText.count + 2, msg1, g_cols, .left, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.red, ConsoleColorModifier.bold)
        // render message 2
        Console.printXY(4,5+self.setupText.count + 3, msg2, g_cols, .left, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.red, ConsoleColorModifier.bold)
    }
    ///
    /// Runs this window keyboard input and feedback.
    ///
    /// returns: Bool. True if path entered, false otherwise.
    ///
    func run() -> Void {
        // clear screen
        Console.clearScreen()
        // render this window
        self.renderWindow()
        // create a ConsoleKeyboardHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()        
        // add key handler for backspace
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_BACKSPACE.rawValue, closure: { () -> Bool in
            // make sure message is not shown
            self.showPathInvalid = false
            // if path has value
            if self.path.count > 0 {
                // remove last character
                self.path.removeLast()                
            }
            // render this window
            self.renderWindow()
            // do not return from keyHandler.run()
            return false
        })
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_ENTER.rawValue, closure: { () -> Bool in
            // if path has value
            if self.path.count > 0 {
                // if path does not exist
                if !FileManager.default.fileExists(atPath: self.path) {
                    // ignore
                    // show invalid path message
                    self.showPathInvalid = true
                    // render this window
                    self.renderWindow()
                    // do not return from keyHandler.run()
                    return false
                }
                // we have a path, set finished flag to true
                self.finished = true
                // allow async to clean up
                usleep(100_000)
                // append path to PlayerPreference.musicRootPath
                PlayerPreferences.musicRootPath.append(self.path)
                // save preferences
                PlayerPreferences.savePreferences()
                // return from run()
                return true
            }
            // do not return from keyHandler.run()
            return false
        })
        keyHandler.addCharacterKeyHandler(closure: { (ch: Character) -> Bool in
            // append character to path
            self.path.append(String(ch))
            // make sure message is not shown
            self.showPathInvalid = false
            // render this window
            self.renderWindow()
            // do not return from keyHandler.run()
            return false
        })
        // execute run(), modal call
        keyHandler.run()
    }// run
}// SetupWindow
