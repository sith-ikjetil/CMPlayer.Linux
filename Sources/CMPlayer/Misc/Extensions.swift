//
//  Extensions.swift
//
//  (i): Implements extensions methods to different types.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import
//
import Foundation 
///
/// Int extension methods.
///
internal extension Int {
    ///
    /// Convert a Int into a Norwegian style number for text representation. " " as a thousand separator.
    ///
    /// returns: The number as a new string.
    ///
    func itsToString() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.string(from: NSNumber(value: self))!
    }    
}
//
// ConsoleColorModifier extension methods
//
internal extension ConsoleColorModifier {
    // convert to string
    func itsToString() -> String {
        switch self {
            case .bold: return "bold"
            case .none: return "none"        
        }
    }
    // convert from string
    static func itsFromString(_ source: String, _ defaultValue: ConsoleColorModifier) -> ConsoleColorModifier {
        switch source {
            case "bold": return .bold
            case "none": return .none            
            default: return defaultValue
        }
    }
}
//
// ConsoleColor extensions methods
//
internal extension ConsoleColor {
    // convert to string
    func itsToString() -> String {
        switch self {
            case .black: return "black"
            case .blue: return "blue"
            case .cyan: return "cyan"
            case .green: return "green"
            case .magenta: return "magenta"
            case .red: return "red"
            case .white: return "white"
            case .yellow: return "yellow"
            case .reset: return "reset"            
        }
    }
    // convert from string
    static func itsFromString(_ source: String, _ defaultValue: ConsoleColor) -> ConsoleColor {
        switch source {
            case "black": return .black
            case "blue": return .blue
            case "cyan": return .cyan
            case "green": return .green
            case "magenta": return .magenta
            case "red": return .red
            case "white": return .white
            case "yellow": return .yellow
            case "reset": return .reset
            default: return defaultValue
        }
    }
}
///
/// Date extension methods.
///
internal extension Date {
    ///
    /// Convert a Date into a YYYY-MM-DD HH:mm:ss string.
    ///
    /// returns: Date as string.
    ///
    func itsToString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
}
///
/// Padding alignment types.
///
internal enum PrintPaddingTextAlign {
    case left
    case right
    case center
    case ignore
}
///
/// String extension methods.
///
internal extension String {
    ///
    /// Converts a string to a padded string of given length.
    ///
    /// parameter maxLength: Length of new string.
    /// parameter padding: Padding type.
    /// parameter paddingChar: Padding character to use.
    ///
    /// returns: New padded string.
    ///
    func convertStringToLengthPaddedString(_ maxLength: Int,_ padding: PrintPaddingTextAlign,_ paddingChar: Character) -> String {
        var msg: String = self
        
        if msg.count == 0 || maxLength <= 0 {
            return msg
        }

        if maxLength <= msg.count {
            return String(msg.prefix(maxLength))
        }
        
        if msg.count == 0 {
            var result: String = ""
            for _ in 0..<maxLength {
                result.append(paddingChar)
            }
            return result
        }
        
        if msg.count > maxLength {                      
            let idx = msg.index(msg.startIndex, offsetBy: maxLength)
            msg = String(msg[msg.startIndex..<idx])
        }
        
        if maxLength == 1 {
            return String(msg.first!)
        }
        
        switch padding {
        case .ignore:
            if msg.count < maxLength {
                return msg
            }
            let idx = msg.index(msg.startIndex, offsetBy: maxLength)
            return String(msg[msg.startIndex..<idx])
        case .center:
            var str = String(repeating: paddingChar, count: maxLength)
            var len: Double = Double(maxLength)
            len = len / 2.0
            let ulen = UInt64(len)
            if Double(ulen) < len {
                len -= 1
            }
            len -= Double(msg.count) / 2
            let si = str.index(str.startIndex, offsetBy: Int(len))
            str.insert(contentsOf: msg, at: si)
            return String(str[str.startIndex..<str.index(str.startIndex, offsetBy: maxLength)])
        case .left:
            var str = String(repeating: paddingChar, count: maxLength)
            let len = 0
            let si = str.index(str.startIndex, offsetBy: len)
            str.insert(contentsOf: msg, at: si)
            return String(str[str.startIndex..<str.index(str.startIndex, offsetBy: maxLength)])
        case .right:
            var str = String(repeating: paddingChar, count: maxLength)
            let len = maxLength-msg.count
            let si = str.index(str.startIndex, offsetBy: len)
            str.insert(contentsOf: msg, at: si)
            return String(str[str.startIndex..<str.index(str.startIndex, offsetBy: maxLength)]);
            
        }
    }
}// extension String