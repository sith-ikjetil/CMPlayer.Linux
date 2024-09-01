//
//  ConsoleKey.swift
//
//  (i): Code that identifies console key press codes.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import.
//
import Foundation
//
// Console Keys
//
internal enum ConsoleKey : UInt32 {
    case KEY_BACKSPACE = 127
    case KEY_ENTER = 10
    case KEY_UP = 365 
    case KEY_DOWN = 366 
    case KEY_RIGHT = 367 
    case KEY_LEFT = 368 
    case KEY_HTAB = 9
    case KEY_SHIFT_HTAB = 390
    case KEY_SPACEBAR = 32
    case KEY_EOF = 0
}
