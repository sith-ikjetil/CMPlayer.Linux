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
    static let filename: String = "log"    
    static var ApplicationLog: PlayerLog? = nil     
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
    init(autoSave: Bool){
        self.autoSave = autoSave      
    }          
    ///
    /// Logs an error
    ///
    /// parameter title: title of log entry
    /// parameter text: log entry information
    ///
    func logError(title: String, text: String) {
        guard PlayerPreferences.logError else { 
            return 
        }
        
        if self.entries.count >= PlayerPreferences.logMaxEntries {
            if PlayerPreferences.logMaxSizeReached == .StopLogging {
                return;
            }
            self.clear()
        }

        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Error, title: title, text: text, timeStamp: Date())
        self.entries.append(logEntry)
        if self.autoSave {
            self.appendToPlainTextLog(logEntry: logEntry)
        }
    }    
    ///
    /// Logs a warning
    ///
    /// parameter title: title of log entry
    /// parameter text: log entry information
    ///
    func logWarning(title: String, text: String) {
        guard PlayerPreferences.logWarning else { 
            return 
        }
        
        if self.entries.count >= PlayerPreferences.logMaxEntries {
            if PlayerPreferences.logMaxSizeReached == .StopLogging {
                return;
            }
            self.clear()
        }

        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Warning, title: title, text: text, timeStamp: Date())
        self.entries.append(logEntry)
        if self.autoSave {
            self.appendToPlainTextLog(logEntry: logEntry)
        }
    }    
    ///
    /// Logs an informative entry
    ///
    /// parameter title: title of log entry
    /// parameter text: log entry information
    ///
    func logInformation(title: String, text: String) {                    
        guard PlayerPreferences.logInformation else { 
            return 
        }
        
        if self.entries.count >= PlayerPreferences.logMaxEntries {
            if PlayerPreferences.logMaxSizeReached == .StopLogging {
                return;
            }
            self.clear()
        }

        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Information, title: title, text: text, timeStamp: Date())
        self.entries.append(logEntry)
        if self.autoSave {
            self.appendToPlainTextLog(logEntry: logEntry)
        }
    }    
    ///
    /// Logs a debug entry
    ///
    /// parameter title: title of log entry
    /// parameter text: log entry information
    ///
    func logDebug(title: String, text: String) {
        guard PlayerPreferences.logDebug else { 
            return 
        }
        
        if self.entries.count >= PlayerPreferences.logMaxEntries {
            if PlayerPreferences.logMaxSizeReached == .StopLogging {
                return;
            }
            self.clear()
        }

        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Debug, title: title, text: text, timeStamp: Date())
        self.entries.append(logEntry)
        if self.autoSave {
            self.appendToPlainTextLog(logEntry: logEntry)
        }
    }    
    ///
    /// Logs an other entry.
    ///
    /// parameter title: title of log entry
    /// parameter text: log entry information
    ///
    func logOther(title: String, text: String) {
        guard PlayerPreferences.logOther else { 
            return 
        }
        
        if self.entries.count >= PlayerPreferences.logMaxEntries {
            if PlayerPreferences.logMaxSizeReached == .StopLogging {
                return;
            }
            self.clear()
        }

        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Other, title: title, text: text, timeStamp: Date())
        self.entries.append(logEntry)
        if self.autoSave {
            self.appendToPlainTextLog(logEntry: logEntry)
        }
    }    
    ///
    /// Clears the log.
    ///
    func clear() {        
        self.entries.removeAll()
        
        do {                
            let path: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.filename, isDirectory: false)
            if FileManager.default.fileExists(atPath: path.path) {                
                try "".write(to: path, atomically: true, encoding: .utf8)
            } 
        }
        catch {

        }
    }    
    ///
    /// Saves the log
    ///
    internal func saveLog()
    {
        let path: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.filename, isDirectory: false)
        self.saveLogAs(path: path)
    }
    /// 
    /// Saves the log to the given path.
    ///     
    internal func saveLogAs(path: URL)
    {    
        let text = self.toPlainText()

        do {
            try text.write(to: path, atomically: true, encoding: .utf8)
        } catch {

        }
    }        
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
        let filePath: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.filename, isDirectory: false)

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

