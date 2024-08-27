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
    static let logFilenameXml: String = "log.txt"
    static let logFilenamePlainText: String = "log.txt"
    static var ApplicationLog: PlayerLog? = nil 
    static var saveType: PlayerLogSaveType = PlayerLogSaveType.plainText
    ///
    /// variables
    /// 
    var entries: [PlayerLogEntry] = []   
    ///
    /// private variables
    /// 
    private var autoSave: Bool = true        
    ///
    /// Overloaded initializer.
    ///
    init(autoSave: Bool, loadOldLog: Bool, logSaveType: PlayerLogSaveType ){
        self.autoSave = autoSave
        PlayerLog.saveType = logSaveType

        if loadOldLog {
            self.loadOldLog()
        }
    }    
    ///
    /// Loads old log into memory
    ///
    func loadOldLog() {
        guard PlayerLog.saveType == .xml else {
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

        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Error, title: title, text: text, timeStamp: Date())
        self.entries.append(logEntry)
        if self.autoSave {
            if PlayerLog.saveType == .xml {
                self.saveLog()
            }
            else if PlayerLog.saveType == .plainText {
                self.appendToPlainTextLog(logEntry: logEntry)
            }
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

        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Warning, title: title, text: text, timeStamp: Date())
        self.entries.append(logEntry)
        if self.autoSave {
            if PlayerLog.saveType == .xml {
                self.saveLog()
            }
            else if PlayerLog.saveType == .plainText {
                self.appendToPlainTextLog(logEntry: logEntry)
            }
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

        let logEntry =  PlayerLogEntry(type: PlayerLogEntryType.Information, title: title, text: text, timeStamp: Date())   
        self.entries.append(logEntry)
        if self.autoSave {
            if PlayerLog.saveType == .xml {
                self.saveLog()
            }
            else if PlayerLog.saveType == .plainText {
                self.appendToPlainTextLog(logEntry: logEntry)
            }
        }    
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
        
        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Debug, title: title, text: text, timeStamp: Date())
        self.entries.append(logEntry)
        if self.autoSave {
            if PlayerLog.saveType == .xml {
                self.saveLog()
            }
            else if PlayerLog.saveType == .plainText {
                self.appendToPlainTextLog(logEntry: logEntry)
            }
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
        
        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Other, title: title, text: text, timeStamp: Date())
        self.entries.append(logEntry)
        if self.autoSave {
            if PlayerLog.saveType == .xml {
                self.saveLog()
            }
            else if PlayerLog.saveType == .plainText {
                self.appendToPlainTextLog(logEntry: logEntry)
            }
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
    func toXMLDocument() -> XMLDocument {        
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
        let path: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.logFilenameXml, isDirectory: false) 
        saveLogAsXml(path: path)        
    }  
    ///
    ///
    ///
    internal func saveLogAsXml(path: URL) {
        let xd: XMLDocument = self.toXMLDocument()
        let xml: String = xd.xmlString        
        
        do {
            try xml.write(to: path, atomically: true,encoding: .utf8)            
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
        switch PlayerLog.saveType {
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
        let path: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.logFilenamePlainText, isDirectory: false)
        self.saveLogAsPlainText(path: path)
    }
    /// 
    /// Saves the log to the given path.
    ///     
    internal func saveLogAsPlainText(path: URL)
    {    
        let text = self.toPlainText()

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
    func saveLogAs(path: URL) {
        switch PlayerLog.saveType {
            case .xml:
                saveLogAsXml(path: path)            
            case .plainText:
                saveLogAsPlainText(path: path)            
        }        
    }    
    ///
    /// Converts log to xml string.
    ///
    /// returnes: a string containing the xml log.
    ///
    func toXmlString() -> String {
        let xd: XMLDocument = self.toXMLDocument()
        return xd.xmlString
    }// saveLogToString    
    /// 
    /// Converts log to plain text string.
    /// 
    /// - Returns: log as plain text.
    func toPlainText() -> String {
        var text: String = ""

        for entry in self.entries {
            text += entry.toPlainText()
        }

        return text
    }
    ///
    /// Appends text to plain text log
    ///
    private func appendToPlainTextLog(logEntry: PlayerLogEntry) {
        let text: String = logEntry.toPlainText()
        let filePath: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.logFilenamePlainText, isDirectory: false)

        do {
            // Check if file exists
            if !FileManager.default.fileExists(atPath: filePath.path) {
                // If file does not exist, create it with initial content
                try text.write(to: filePath, atomically: true, encoding: .utf8)
            } 
            else {
                // If file exists, append the new content
                let fileHandle = try FileHandle(forWritingTo: filePath)

                defer {
                    // Close the file
                    fileHandle.closeFile()
                }

                // Move to the end of the file
                fileHandle.seekToEndOfFile()
                
                // Convert the string to Data and append it
                if let data = text.data(using: .utf8) {
                    fileHandle.write(data)
                }                
            }            
        } 
        catch {
        
        }
    }
}// PlayerLog

