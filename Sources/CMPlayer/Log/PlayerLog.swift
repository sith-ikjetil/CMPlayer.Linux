//
//  PlayerLog.swift
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
/// PlayerLog log class.
///
internal class PlayerLog {
    ///
    /// static constants/variables
    /// 
    static let logFilenameXml: String = "CMPlayer.Log.xml"
    static let logFilenamePlainText: String = "CMPlayer.Log.txt"
    static var ApplicationLog: PlayerLog? = nil 
    ///
    /// variables
    /// 
    var entries: [PlayerLogEntry] = []
    ///
    /// private variables
    /// 
    private var autoSave: Bool = true    
    private var saveType: PlayerLogSaveAsType = PlayerLogSaveAsType.plainText
    ///
    /// Overloaded initializer.
    ///
    init(autoSave: Bool, loadOldLog: Bool, logSaveType: PlayerLogSaveAsType ){
        self.autoSave = autoSave
        self.saveType = logSaveType

        if loadOldLog {
            self.loadOldLog()
        }
    }    
    ///
    /// Loads old log into memory
    ///
    func loadOldLog() {
        guard self.saveType == .xml else {
            return
        }
        
        let url: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.logFilenameXml, isDirectory: false)
        
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                let xd: XMLDocument = try XMLDocument(contentsOf: url, options: XMLNode.Options.documentTidyXML)
                let elements: [XMLElement] = xd.rootElement()?.elements(forName: PlayerLogEntry.XML_ELEMENT_NAME) ?? []
                for e in elements {
                    self.entries.append(PlayerLogEntry(e: e))
                }
            }
        }
        catch {
            PlayerLog.ApplicationLog?.logError(title: "[PlayerLog].loadOldLog()", text: "\(error)")
        }
    }    
    ///
    /// Logs an error
    ///
    /// parameter title: title of log entry
    /// parameter text: log entry information
    ///
    func logError(title: String, text: String) {
        guard PlayerPreferences.logError else { return }
        if self.entries.count >= PlayerPreferences.logMaxSize {
            if PlayerPreferences.logMaxSizeReached == LogMaxSizeReached.EmptyLog {
                self.clear()
            }
            else {
                return
            }
        }
        self.entries.append(PlayerLogEntry(type: PlayerLogEntryType.Error, title: title, text: text, timeStamp: Date()))
        if self.autoSave {
            self.saveLog()
        }    
    }    
    ///
    /// Logs a warning
    ///
    /// parameter title: title of log entry
    /// parameter text: log entry information
    ///
    func logWarning(title: String, text: String) {
        guard PlayerPreferences.logWarning else { return }
        if self.entries.count >= PlayerPreferences.logMaxSize {
            if PlayerPreferences.logMaxSizeReached == LogMaxSizeReached.EmptyLog {
                self.clear()
            }
            else {
                return
            }
        }
        self.entries.append(PlayerLogEntry(type: PlayerLogEntryType.Warning, title: title, text: text, timeStamp: Date()))
        if self.autoSave {
            self.saveLog()
        }    
    }    
    ///
    /// Logs an informative entry
    ///
    /// parameter title: title of log entry
    /// parameter text: log entry information
    ///
    func logInformation(title: String, text: String) {                    
        guard PlayerPreferences.logInformation else { return }        
        if self.entries.count >= PlayerPreferences.logMaxSize {
            if PlayerPreferences.logMaxSizeReached == LogMaxSizeReached.EmptyLog {
                self.clear()
            }
            else {
                return
            }
        }        
        self.entries.append(PlayerLogEntry(type: PlayerLogEntryType.Information, title: title, text: text, timeStamp: Date()))        
        
        if self.autoSave {
            self.saveLog()
        }
        //os_log("(i): %{public}s","\(title): \(text)")
    }    
    ///
    /// Logs a debug entry
    ///
    /// parameter title: title of log entry
    /// parameter text: log entry information
    ///
    func logDebug(title: String, text: String) {
        guard PlayerPreferences.logDebug else { return }
        if self.entries.count >= PlayerPreferences.logMaxSize {
            if PlayerPreferences.logMaxSizeReached == LogMaxSizeReached.EmptyLog {
                self.clear()
            }
            else {
                return
            }
        }
        self.entries.append(PlayerLogEntry(type: PlayerLogEntryType.Debug, title: title, text: text, timeStamp: Date()))
        if self.autoSave {
            self.saveLog()
        }        
    }    
    ///
    /// Logs an other entry.
    ///
    /// parameter title: title of log entry
    /// parameter text: log entry information
    ///
    func logOther(title: String, text: String) {
        guard PlayerPreferences.logOther else { return }
        if self.entries.count >= PlayerPreferences.logMaxSize {
            if PlayerPreferences.logMaxSizeReached == LogMaxSizeReached.EmptyLog {
                self.clear()
            }
            else {
                return
            }
        }
        self.entries.append(PlayerLogEntry(type: PlayerLogEntryType.Other, title: title, text: text, timeStamp: Date()))
        if self.autoSave {
            self.saveLog()
        }     
    }    
    ///
    /// Clears the log.
    ///
    func clear() {        
        self.entries.removeAll()
    }    
    ///
    /// Saves the log as an XML document
    ///
    func saveLogAsXMLDocument() -> XMLDocument {        
        // Create the root element "Log"
        let xeRoot: XMLElement = XMLElement(name: "Log")
        
        // Set the attribute directly on the root element
        xeRoot.addAttribute(XMLNode.attribute(withName: "id", stringValue: "CMPlayer.Linux.Log") as! XMLNode)
        
        for entry in self.entries
        {
            xeRoot.addChild(entry.toXMLElement())
        }

        // Create the XML document with the root element
        let xmlDoc = XMLDocument(rootElement: xeRoot)
        
        return xmlDoc
    }    
    ///
    /// Saves the log
    ///
    internal func saveLogAsXml()
    {                
        let xd: XMLDocument = self.saveLogAsXMLDocument()
        let xml: String = xd.xmlString
        let url: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.logFilenameXml, isDirectory: false)
        
        do {
            try xml.write(to: url, atomically: true,encoding: .utf8)            
        }
        catch {
            PlayerLog.ApplicationLog?.logError(title: "[PlayerLog].saveLog()", text: "\(error)")
        }
    }    
    /// 
    /// saveLog saves as any one of several types.
    /// 
    /// - Parameter type: format to save to
    internal func saveLog() {
        switch self.saveType {
            case .xml:
                self.saveLogAsXml() 
            case .plainText:
                self.saveLogAsPlainText()
        }
    }
    ///
    /// Saves the log
    ///
    internal func saveLogAsPlainText()
    {    
        var text: String = ""
                    
        for entry in self.entries
        {
            text += "[\(entry.type)] \(entry.timeStamp)"
            text += "\n"
            text += "\(entry.title)"
            text += "\n"
            text += "\(entry.text)"
            text += "\n\n"
        }

        let path: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.logFilenamePlainText, isDirectory: false)
        do {
            try text.write(to: path, atomically: true, encoding: .utf8)
        } catch {

        }
    }    
    ///
    /// Saves the log as a file
    ///
    /// parameter url: file to save.
    ///
    func saveLogAs(url: URL) {
        let xd: XMLDocument = self.saveLogAsXMLDocument()
        let xml: String = xd.xmlString
        
        do {
            try xml.write(to: url, atomically: true,encoding: .utf8)
        }
        catch {
            PlayerLog.ApplicationLog?.logError(title: "[PlayerLog].saveLogAs(url)", text: "\(error)")
        }
    }    
    ///
    /// Saves log to a string.
    ///
    /// returnes: a string containing the xml log.
    ///
    func saveLogToString() -> String {
        let xd: XMLDocument = self.saveLogAsXMLDocument()
        return xd.xmlString
    }// saveLogToString
}// PlayerLog

