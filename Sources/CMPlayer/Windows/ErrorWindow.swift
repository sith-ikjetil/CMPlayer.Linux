//
//  ErrorWindow.swift
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//

//
// import
//
import Foundation

internal class ErrorWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    ///
    /// variables
    /// 
    var message: String = ""    
    ///
    /// Shows this ErrorWindow on screen.
    ///
    /// parameter message: The message to show in error.
    ///
    func showWindow() -> Void {
        g_tscpStack.append(self)        
        self.run()
        g_tscpStack.removeLast()
    }    
    //
    // TerminalSizeChangedProtocol implementation handler.
    //
    func terminalSizeHasChanged() {
        Console.clearScreenCurrentTheme()
        self.renderWindow()
    }    
    //
    // Run method.
    //
    func run() -> Void {     
        Console.clearScreenCurrentTheme()   
        self.renderWindow()

        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_ENTER.rawValue, closure: { () -> Bool in
            return true
        })
        keyHandler.run()
    }    
    ///
    /// Renders error message on screen. Waits for user to press Enter key to continue.
    ///
    /// parameter message: The message to show in error.
    ///
    func renderWindow() -> Void {   
        guard isWindowSizeValid() else {
            return
        }

        Console.clearScreenCurrentTheme()
             
        Console.printXY(1, 1, "CMPlayer Error", g_cols, .center, " ", ConsoleColor.blue, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        Console.printXY(1, 3, self.message, g_cols*15, .ignore, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.red, ConsoleColorModifier.bold)
        print("")
        print("")
        print(Console.applyTextColor(colorBg: ConsoleColor.black, modifierBg: ConsoleColorModifier.none, colorText: ConsoleColor.white, modifierText: ConsoleColorModifier.bold, text: "> Press ENTER Key To Continue <"))
        
        Console.gotoXY(g_cols,g_rows-3)
        print("")
    }// renderErrorMessage
}// ErrorWindow
