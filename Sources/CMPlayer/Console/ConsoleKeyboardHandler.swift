//
//  ConsoleKeyboardHandler.swift
//
//  (i): Code that deals with keyboard presses. Call addXXXKeyHandler
//       to add handlers for keypresses. The call run(). Run() is a
//       blocking call that returnes only when a keyhandler return true.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import.
//
import Foundation
///
/// Represents CMPlayer ConsoleKeyboardHandler
///
internal class ConsoleKeyboardHandler {
    //
    // private variables
    //
    private var keyHandlers: [UInt32 : () -> Bool] = [:]            // registered key handlers
    private var unknownKeyHandlers: [(UInt32) -> Bool] = []         // registered unknown key handlers
    private var characterKeyHandlers: [(Character) -> Bool] = []    // registerd character key handler
    private var inKey27: Bool = false   // escape key
    private var inKey79: Bool = false   // escape + O
    //
    // Default initializer
    //
    init() {
        
    }    
    ///
    /// Adds a closure keyboard handler for given key from getchar()
    ///
    /// parameter key: getchar() return value.
    /// parameter closure: A Keyboard handler for key pressed.
    ///
    /// returns: True if ConsoleKeyboardHandler should stop processing keys and return from run. False otherwise.
    ///
    func addKeyHandler(key: UInt32, closure: @escaping () -> Bool) {
        self.keyHandlers[key] = closure
    }    
    ///
    /// Adds a closure keyboard handler for given key from getchar() that is not processed with addKeyHandler handler.
    ///
    /// parameter closure: A Closure for handling key pressed.
    ///
    /// returns: True is ConsoleKeyboardHandler should stop processing keys and return from run. False otherwise.
    ///
    func addUnknownKeyHandler(closure: @escaping (UInt32) -> Bool) {
        self.unknownKeyHandlers.append(closure)
    }    
    ///
    /// Adds a closure keyboard handler for given input character.
    ///
    /// parameter closure: A Closure for handling key pressed.
    ///
    /// returns: True is ConsoleKeyboardHandler should stop processing keys and return from run. False otherwise.
    ///
    func addCharacterKeyHandler(closure: @escaping (Character) -> Bool) {
        self.characterKeyHandlers.append(closure)
    }    
    ///
    /// Runs keyboard processing using getchar(). Calls key event handlers .
    ///
    func run() {
        // create a flag variable for escape key pressed
        var b27: Bool = false
        // create a flag variable for [ key
        var b91: Bool = false
        // create a flag variable is we should continue executing run()
        var doRun: Bool = true
        // loop as long as doRun = true
        while doRun {
            // get data from standard input
            let inputData = FileHandle.standardInput.availableData
            // guard we have input
            guard inputData.count > 0 else {
                // else continue looping
                continue
            }
            // create optional tmp string from input data
            let tmp = String(data: inputData, encoding: .utf8)
            // if inputString is not nil
            if let inputString = tmp {
                // loop through all characters in inputString
                for c in inputString.unicodeScalars {
                    // if we are not in an esacpe sequence
                    // - but an escape key is pressed.
                    if !b91 && !b27 && c.value == 27 {
                        // set b27 flag to true
                        b27 = true
                        // continue looping
                        continue
                    }
                    // else if we are in an escape sequence 
                    // - and we pressed [
                    else if b27 && c.value == 91 {
                        // set b91 flag to true
                        b91 = true
                        // continue looping
                        continue
                    }
                    // create a key variable (32 bit) for current character
                    var key = c.value
                    // if b91 flag is set
                    if b91 {
                        // set b27 flag to false
                        b27 = false
                        // set b91 flag to false
                        b91 = false
                        // we have arrow keys
                        key += 300 // WE HAVE ARROW KEYS
                    }
                    // we are not in an escape [ sequence
                    else {
                        // create a character constant for character c
                        let ch: Character = Character(c)
                        // if character is valid
                        if (ch.isLetter || ch.isNumber || ch.isWhitespace || ch.isPunctuation || ch.isMathSymbol) && !ch.isNewline {
                            // loop through all characterKeyHandlers
                            for handler in self.characterKeyHandlers {
                                // if handler returns true
                                if handler(ch) {
                                    // set doRun flag to false, exit run()
                                    doRun = false
                                    // break loop
                                    break;
                                }
                            }
                        }
                    }
                    // process key handlers
                    // - if returns true
                    if processKey(key: key) {
                        // set doRun flag to false, exit run()
                        doRun = false
                        // break loop
                        break;
                    }
                }
            }
        }
    }            
    ///
    /// Processes a keystroke from getchar()
    ///
    /// parameter key: Value from getchar()
    ///
    /// returns: True if eventhandler processed the keystroke and eventhandler returned true. 
    ///          False if no eventhandler processed the key. 
    ///          False if eventhandler returned false.
    ///
    func processKey(key: UInt32) -> Bool {
        // if we are not in an escape key
        if !inKey27 {
            // if key is escape
            if key == 27 {
                // set inKey27 flag to true
                inKey27 = true
                // return false
                return false;
            }
        }
        // if we are not in key O
        if !inKey79 {
            // if key is O
            if key == 79 {
                // set inKey79 flag to true
                inKey79 = true;
                // return false
                return false;
            }
        }
        // set inKey27 flag to false
        inKey27 = false
        // set inKey79 to false
        inKey79 = false
        // create a hit variable
        // - hit is true if keyhandler for key is found in self.keyHandlers
        var hit: Bool = false
        // loop through all self.keyHandlers
        for kh in self.keyHandlers {
            // if keyhandler key is = key
            if kh.key == key {
                // set hit flag to true
                hit = true
                // if keyHandler returnes true
                if kh.value() {
                    // return true = exit run()
                    return true
                }
            }
        }
        // we did not get a hit from self.keyHandlers, try self.unknownKeyHandlers
        if !hit {
            // loop through all self.unknownKeyHandlers
            for handler in self.unknownKeyHandlers {
                // if handler returns true
                if handler(key) {
                    // return true = exit run()
                    return true
                }
            }
        }
        // return false = continue run()
        return false
    }// processKey
}// ConsoleKeyboardHandler
