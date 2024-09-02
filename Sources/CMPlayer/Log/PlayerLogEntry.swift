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
    func toPlainText() -> String {
        // create a variable named text of type string
        var text: String = ""    
        // append self.type, self.timeStamp and self.title
        text += "[\(self.type)] [\(self.timeStamp.itsToString())] Title: \(self.title)"
        // append a new line
        text += "\n"
        // append self.text
        text += "Text: \(self.text)"
        // append two new lines, entries separated by a line
        text += "\n\n"

        return text
    }
}// PlayerLogEntry
