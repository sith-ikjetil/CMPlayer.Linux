//
//  IgnitionLogEntry.swift
//  Ignition
//
//  Created by Kjetil Kr Solberg on 22/01/2019.
//  Copyright © 2019 Kjetil Kr Solberg. All rights reserved.
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
    static let XML_ELEMENT_NAME: String = "LogEntry"
    var type: PlayerLogEntryType
    var title: String
    var text: String
    var timeStamp: Date
    
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
        self.type = type
        self.title = title
        self.text = text
        self.timeStamp = timeStamp
    }
    
    ///
    /// Overloaded initializer
    ///
    /// parameter e: XML element representing a log entry
    ///
    init( e: XMLElement )
    {
        self.title = e.attribute(forName: "Title")?.stringValue ?? ""
        self.text = e.stringValue ?? ""
        self.type = PlayerLogEntryType(rawValue: e.attribute(forName: "Type")?.stringValue ?? "Other") ?? PlayerLogEntryType.Other
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        self.timeStamp = dateFormatter.date(from: e.attribute(forName: "TimeStamp")?.stringValue ?? "") ?? Date()
    }
    
    ///
    /// Creates an xml element representing this log entry.
    ///
    /// returnes: XML element.
    ///
    func toXMLElement() -> XMLElement {        
        let xe = XMLElement(name: PlayerLogEntry.XML_ELEMENT_NAME)
    
        // Set the text content of the element
        xe.stringValue = self.text
        
        // Add the "Title" attribute
        let xnTitle = XMLNode.attribute(withName: "Title", stringValue: self.title) as! XMLNode
        xe.addAttribute(xnTitle)
        
        // Add the "Type" attribute
        let xnType = XMLNode.attribute(withName: "Type", stringValue: self.type.rawValue) as! XMLNode
        xe.addAttribute(xnType)
        
        // Format the date and add the "TimeStamp" attribute
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        let xnTimeStamp = XMLNode.attribute(withName: "TimeStamp", stringValue: dateFormatter.string(from: self.timeStamp)) as! XMLNode
        xe.addAttribute(xnTimeStamp)
        
        return xe
    }//toXMLElement
}// PlayerLogEntry
