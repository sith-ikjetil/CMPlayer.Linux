//
//  ErrorWindow.swift
//
//  (i): Renders an error to screen. Not really used.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import
//
import Foundation
///
/// Represent CMPlayer ErrorWindow
/// 
internal class ErrorWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    ///
    /// variables
    /// 
    var message: String = ""    // message to be shown
    ///
    /// Shows this ErrorWindow on screen.
    ///
    /// parameter message: The message to show in error.
    ///
    func showWindow() -> Void {
        // add to top this window to terminal size change protocol stack
        g_tscpStack.append(self)        
        // run(), modal call
        self.run()
        // remove from top this window from terminal size change protocol stack
        g_tscpStack.removeLast()
    }    
    //
    // TerminalSizeChangedProtocol implementation handler.
    //
    func terminalSizeHasChanged() {
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
    }    
    //
    // Runs this window keyboard input and feedback.
    //
    func run() -> Void {     
         // clear screen current theme
        Console.clearScreenCurrentTheme()   
        // render this window
        self.renderWindow()
        // create a ConsoleKeyboardHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        // add key handler for key enter
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_ENTER.rawValue, closure: { () -> Bool in
            // return from run()
            return true
        })
        // execute run(), modal call
        keyHandler.run()
    }    
    ///
    /// Renders error message on screen. Waits for user to press Enter key to continue.
    ///
    /// parameter message: The message to show in error.
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
        // render custom header
        Console.printXY(1, 1, "CMPlayer Error", g_cols, .center, " ", ConsoleColor.blue, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // render message: 15 lines of potential message
        Console.printXY(1, 3, self.message, g_cols*15, .ignore, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.red, ConsoleColorModifier.bold)        
        // render status line
        print(Console.applyTextColor(colorBg: ConsoleColor.black, modifierBg: ConsoleColorModifier.none, colorText: ConsoleColor.white, modifierText: ConsoleColorModifier.bold, text: "> Press ENTER Key To Continue <"))
        // goto g_cols, g_rows-3
        Console.gotoXY(g_cols,g_rows-3)
        // print empty string
        print("")
    }// renderErrorMessage
}// ErrorWindow
