//
//  Console.swift
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//

//
// import
//
import Foundation
import Termios

///
/// Represents console color.
///
enum ConsoleColor : Int {
    case black = 30
    case red = 31
    case green = 32
    case yellow = 33
    case blue = 34
    case magenta = 35
    case cyan = 36
    case white = 37
    case reset = 0
}
///
/// Console color modifier
///
enum ConsoleColorModifier : Int {
    case none = 0
    case bold = 1
}
///
/// Represents CMPlayer Console
///
internal class Console {
    //
    // Private properties/constants.
    //
    static private let concurrentQueue1 = DispatchQueue(label: "cqueue.cmplayer.linux.console.1", attributes: .concurrent)
    //static private let concurrentQueue2 = DispatchQueue(label: "cqueue.console.music.player.macos.2.console", attributes: .concurrent)
    static private let sigintSrcSIGINT = DispatchSource.makeSignalSource(signal: Int32(SIGINT), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGQUIT = DispatchSource.makeSignalSource(signal: Int32(SIGQUIT), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGILL = DispatchSource.makeSignalSource(signal: Int32(SIGILL), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGTRAP = DispatchSource.makeSignalSource(signal: Int32(SIGTRAP), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGABRT = DispatchSource.makeSignalSource(signal: Int32(SIGABRT), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGEMT = DispatchSource.makeSignalSource(signal: Int32(SIGEMT), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGFPE = DispatchSource.makeSignalSource(signal: Int32(SIGFPE), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGKILL = DispatchSource.makeSignalSource(signal: Int32(SIGKILL), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGBUS = DispatchSource.makeSignalSource(signal: Int32(SIGBUS), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGSEGV = DispatchSource.makeSignalSource(signal: Int32(SIGSEGV), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGSYS = DispatchSource.makeSignalSource(signal: Int32(SIGSYS), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGPIPE = DispatchSource.makeSignalSource(signal: Int32(SIGPIPE), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGALRM = DispatchSource.makeSignalSource(signal: Int32(SIGALRM), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGHUP = DispatchSource.makeSignalSource(signal: Int32(SIGHUP), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGTERM = DispatchSource.makeSignalSource(signal: Int32(SIGTERM), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGURG = DispatchSource.makeSignalSource(signal: Int32(SIGURG), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGSTOP = DispatchSource.makeSignalSource(signal: Int32(SIGSTOP), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGTSTP = DispatchSource.makeSignalSource(signal: Int32(SIGTSTP), queue: Console.concurrentQueue2)
    //static private let sigintSrcSIGCONT = DispatchSource.makeSignalSource(signal: Int32(SIGCONT), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGCHLD = DispatchSource.makeSignalSource(signal: Int32(SIGCHLD), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGTTIN = DispatchSource.makeSignalSource(signal: Int32(SIGTTIN), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGTTOU = DispatchSource.makeSignalSource(signal: Int32(SIGTTOU), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGIO = DispatchSource.makeSignalSource(signal: Int32(SIGIO), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGXCPU = DispatchSource.makeSignalSource(signal: Int32(SIGXCPU), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGXFSZ = DispatchSource.makeSignalSource(signal: Int32(SIGXFSZ), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGVTALRM = DispatchSource.makeSignalSource(signal: Int32(SIGVTALRM), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGPROF = DispatchSource.makeSignalSource(signal: Int32(SIGPROF), queue: Console.concurrentQueue1)
    static private let sigintSrcSIGWINCH = DispatchSource.makeSignalSource(signal: Int32(SIGWINCH), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGUSR1 = DispatchSource.makeSignalSource(signal: Int32(SIGUSR1), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGUSR2 = DispatchSource.makeSignalSource(signal: Int32(SIGUSR2), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGTHR = DispatchSource.makeSignalSource(signal: Int32(SIGTHR), queue: Console.concurrentQueue1)
    //static private let sigintSrcSIGLIBRT = DispatchSource.makeSignalSource(signal: Int32(SIGLIBRT), queue: Console.concurrentQueue1)
    ///
    /// Clears console screen.
    ///
    static func clearScreen() -> Void {
        //print(applyTextColor(colorBg: ConsoleColor.black, modifierBg: ConsoleColorModifier.none, colorText: ConsoleColor.white , modifierText: ConsoleColorModifier.none , text: " "))
        //print("\u{001B}[2J")
        Console.printXY(1,1," ", g_rows*g_cols, .left, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.none)
    }
    ///
    /// Clears console screen given colors.
    ///
    static func clearScreen(colorBg: ConsoleColor, modBg: ConsoleColorModifier, colorText: ConsoleColor, modText: ConsoleColorModifier) -> Void {
        //print(applyTextColor(colorBg: colorBg, modifierBg: modBg, colorText: colorText, modifierText: modText, text: " "))
        //print("\u{001B}[2J")
        Console.printXY(1,1," ", g_rows*g_cols, .left, " ", colorBg, modBg, colorText, modText)
    }
    ///
    /// Clears console screen current theme.
    ///
    static func clearScreenCurrentTheme() -> Void {
        switch PlayerPreferences.colorTheme {
        case .Default:
            Console.printXY(1,1," ", g_rows*g_cols, .left, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.none)
        case .Blue:
            Console.printXY(1,1," ", g_rows*g_cols, .left, " ", ConsoleColor.blue, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.none)
        case .Black:
            Console.printXY(1,1," ", g_rows*g_cols, .left, " ", ConsoleColor.black, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.none)
        }
        //print("\u{001B}[2J")
    }    
    ///
    /// Hides console cursor.
    ///
    static func hideCursor() -> Void {
        print("\u{001B}[?25l")
    }
    ///
    /// Shows console cursor.
    ///
    static func showCursor() -> Void {
        print("\u{001B}[?25h")
    }
    ///
    /// Turns console echo off.
    ///
    static func echoOff() -> Void {
        do {
            let oldt = try Termios.fetch(fd: STDIN_FILENO)
            var newt = oldt;
            newt.localFlags.subtract([.echo, .canonical])
            try newt.update(fd: STDIN_FILENO)
        }
        catch {
            let msg = "CMPlayer ABEND.\n[Console].echoOff().\nUnknown error.\nMessage: \(error)"               
            
            Console.clearScreen()
            Console.gotoXY(1, 1)
            system("clear")
            
            print(msg)

            PlayerLog.ApplicationLog?.logError(title: "[Console].echoOff()", text: msg.trimmingCharacters(in: .newlines))
            exit(ExitCodes.ERROR_CONSOLE.rawValue)
        }
    }    
    ///
    /// Turns console echo on.
    ///
    static func echoOn() -> Void {
        do {
            let oldt = try Termios.fetch(fd: STDIN_FILENO)
            var newt = oldt;
            newt.localFlags.formSymmetricDifference([.echo, .canonical])
            try newt.update(fd: STDIN_FILENO)
        }
        catch {
            let msg = "CMPlayer ABEND.\n[Console].echoOn().\nUnknown error.\nMessage: \(error)"            
            
            Console.clearScreen()
            Console.gotoXY(1, 1)
            system("clear")
            
            print(msg)

            PlayerLog.ApplicationLog?.logError(title: "[Console].echoOn()", text: msg.trimmingCharacters(in: .newlines))
            exit(ExitCodes.ERROR_CONSOLE.rawValue)
        }
    }
    ///
    /// Applies color to text string.
    ///
    /// parameter colorBg: Background console color.
    /// parameter modifierBg: Background console color modifier.
    /// parameter colorText: Text console color.
    /// parameter modifierText: Text console color modifier.
    /// parameter text: Text to output to console.
    ///
    /// returns: String to be written to console using print.
    ///
    static func applyTextColor(colorBg: ConsoleColor, modifierBg:  ConsoleColorModifier, colorText: ConsoleColor, modifierText: ConsoleColorModifier, text: String) -> String {
        
        let addToText: String = (modifierText == ConsoleColorModifier.bold) ? ";1": ""
        let addToBg: String = (modifierBg == ConsoleColorModifier.bold) ? ";1": ""
        
        return "\u{001B}[\(colorText.rawValue)\(addToText)m\u{001B}[\(colorBg.rawValue+10)\(addToBg)m\(text)\u{001B}[0m"
    }
    ///
    /// Sets terminal size in character length.
    ///
    /// parameter width. Number of characters in x axis.
    /// parameter height: Number of characters in y axis.
    ///
    static func setTerminalSize(width: Int, height: Int) -> Void {
        print("\u{001B}[8;\(height);\(width)t", terminator: "")
    }
    ///
    /// Moves console position.
    ///
    /// parameter x: Console x position.
    /// parameter y: Console y position.
    ///
    static func gotoXY(_ x: Int, _ y: Int) -> Void
    {
        print("\u{001B}[\(y);\(x)H", terminator: "")
    }
    ///
    /// Prints a string to console at given position.
    ///
    /// parameter x: Console x position.
    /// parameter y: Console y position.
    /// parameter text: Text to be written to console.
    /// parameter maxLength: Maximum length of string to be written.
    /// parameter padding: How should string content be aligned.
    /// parameter paddingChar: What char should be applied with padding to maximum length.
    /// parameter bgColor: Console background color.
    /// parameter modifierBg: Console background color modifier.
    /// parameter colorText: Console text color.
    /// parameter modifierText: Console text color modifier
    ///
    static func printXY(_ x: Int,_ y: Int,_ text: String,_ maxLength: Int,_ padding: PrintPaddingTextAlign,_ paddingChar: Character, _ bgColor: ConsoleColor, _ modifierBg: ConsoleColorModifier, _ colorText: ConsoleColor,_ modifierText: ConsoleColorModifier) -> Void {
        let nmsg = text.convertStringToLengthPaddedString(maxLength, padding, paddingChar)
        print("\u{001B}[\(y);\(x)H\(Console.applyTextColor(colorBg: bgColor, modifierBg: modifierBg, colorText: colorText, modifierText: modifierText, text: nmsg))", terminator: "")
    }    
    ///
    /// Initializes console.
    ///
    static func initialize() -> Void {
        
        var w = winsize()        
        if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w) == 0 {
            g_rows = Int(w.ws_row)
            g_cols = Int(w.ws_col)
        }                

        Console.hideCursor()
        Console.echoOff()
        
        signal(SIGTSTP,SIG_IGN)
        signal(SIGINT,SIG_IGN)
        
        atexit( {
            Console.showCursor()
            Console.echoOn()
        })

        //
        // Respond to Ctrl+C
        //
        sigintSrcSIGINT.setEventHandler {
            g_doNotPaint = true // windows that repaint async does not paint over the printed message before exit

            let msg: String = "CMPlayer exited due to Ctrl+C."            

            Console.clearScreen()
            Console.gotoXY(1, 1)
            system("clear")
            
            print(msg)

            exit(ExitCodes.ERROR_CANCEL.rawValue)
        }
        sigintSrcSIGINT.resume()
        
        //
        // Respond to window resize
        //
        sigintSrcSIGWINCH.setEventHandler {            
            var w = winsize()
            var rows: Int = g_rows
            var cols: Int = g_cols
            if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w) == 0 {
                rows = Int(w.ws_row)
                cols = Int(w.ws_col)
            }
            
            g_rows = rows
            g_cols = cols
            if g_tscpStack.count > 0 {
                g_termSizeIsChanging = true
                g_tscpStack.last?.terminalSizeHasChanged()
                g_termSizeIsChanging = false
            }
        }
        sigintSrcSIGWINCH.resume()
    }// initialize
}// Console
