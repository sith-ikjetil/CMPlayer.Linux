//
//  PlayerLogEntry.swift
//
//  (i): Code that represent a log item.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import.
//
import Foundation
import FoundationXML
///
/// Log entry class.
///
internal class PlayerLogEntry {
    ///
    /// variables
    /// 
    var type: PlayerLogEntryType    // log type (information, debug, warning, other or error)
    var title: String               // title of log item
    var text: String                // text of log item
    var timeStamp: Date             // timestamp of log item
    ///
    /// Overloaded initializer
    ///
    /// parameter type: log entry type.
    /// parameter title: log entry title.
    /// parameter text: log entry information.
    /// parameter timeStamp: date time of log entry.
    ///
    init( type: PlayerLogEntryType, title: String, text: String, timeStamp: Date)
    {
        // set self.type to type
        self.type = type
        // set self.title to title
        self.title = title
        // set self.text to text
        self.text = text
        // set self.timeStamp to timeStamp
        self.timeStamp = timeStamp
    }    
    /// 
    /// Converts entry into plain text for loggin purposes.
    /// 
    /// - Returns: 
    func toPlainText(n: Int) -> String {        
        // create a variable named text of type string with self.type
        var text: String = "\(n)> Type=\(self.type.rawValue.convertStringToLengthPaddedString(11,.left," ")) "
        // append self.timeStamp
        text += "When=\(self.timeStamp.itsToString()) "
        // append self.title
        text += "Title=\(self.title) "
        // append self.text
        text += "Description=\(self.text.replacingOccurrences(of: "\n", with: " "))"
        // append next line
        text += "\n"
        // return text
        return text
    }
}// PlayerLogEntry
