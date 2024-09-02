//
//  PlayerLog.swift
//
//  (i): Code that handles logging.
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
    static let filename: String = "log"             // log filename
    static var ApplicationLog: PlayerLog? = nil     // application log
    ///
    /// variables
    /// 
    var entries: [PlayerLogEntry] = []   // log entries
    ///
    /// private variables
    /// 
    private var autoSave: Bool = true    // should the log save entries as soon as they heppen
    ///
    /// Overloaded initializer.
    ///
    init(autoSave: Bool){
        // set self.autosave to initializer value autoSave
        self.autoSave = autoSave      
    }          
    ///
    /// Logs an error
    ///
    /// parameter title: title of log entry
    /// parameter text: log entry information
    ///
    func logError(title: String, text: String) {
        // guard we should log error
        guard PlayerPreferences.logError else { 
            // else we should not log
            // return
            return 
        }
        // if we have too  many entries
        if self.entries.count >= PlayerPreferences.logMaxEntries {
            // if we should stop logging when max size is reached
            if PlayerPreferences.logMaxSizeReached == .StopLogging {
                // then return
                return;
            }
            // no it means we should clear log
            self.clear()
        }
        // create log entry
        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Error, title: title, text: text, timeStamp: Date())
        // append log entry to self.entries
        self.entries.append(logEntry)
        // is the self.autoSave flag is set to true
        if self.autoSave {
            // then save the log entry
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
        // guard we should log warning
        guard PlayerPreferences.logWarning else { 
            // else we should not log
            // return
            return 
        }
        // if we have too many entries
        if self.entries.count >= PlayerPreferences.logMaxEntries {
            // if we should stop logging when max size is reached
            if PlayerPreferences.logMaxSizeReached == .StopLogging {
                // then return
                return;
            }
            // no it means we should clear log
            self.clear()
        }
        // create log entry
        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Warning, title: title, text: text, timeStamp: Date())
        // append log entry to self.entries
        self.entries.append(logEntry)
        // is the self.autoSave flag is set to true
        if self.autoSave {
            // then save the log entry
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
        // guard we should log information
        guard PlayerPreferences.logInformation else { 
            // else we should not log
            // return
            return 
        }
        // if we have too many entries
        if self.entries.count >= PlayerPreferences.logMaxEntries {
            // if we should stop logging when max size is reached
            if PlayerPreferences.logMaxSizeReached == .StopLogging {
                // then return
                return;
            }
            // no it means we should clear log
            self.clear()
        }
        // create log entry
        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Information, title: title, text: text, timeStamp: Date())
        // append log entry to self.entries
        self.entries.append(logEntry)
        // is the self.autoSave flag is set to true
        if self.autoSave {
            // then save the log entry
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
        // guard we should log debug
        guard PlayerPreferences.logDebug else { 
            // else we should not log
            // return
            return 
        }
        // if we have too many entries
        if self.entries.count >= PlayerPreferences.logMaxEntries {
            // if we should stop logging when max size is reached
            if PlayerPreferences.logMaxSizeReached == .StopLogging {
                // then return
                return;
            }
            // no it means we should clear log
            self.clear()
        }
        // create log entry
        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Debug, title: title, text: text, timeStamp: Date())
        // append log entry to self.entries
        self.entries.append(logEntry)
        // is the self.autoSave flag is set to true
        if self.autoSave {
            // then save the log entry
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
        // guard we should log other
        guard PlayerPreferences.logOther else { 
            // else we should not log
            // return
            return 
        }
        // if we have too many entries
        if self.entries.count >= PlayerPreferences.logMaxEntries {
            // if we should stop logging when max size is reached
            if PlayerPreferences.logMaxSizeReached == .StopLogging {
                // then return
                return;
            }
            // no it means we should clear log
            self.clear()
        }
        // create log entry
        let logEntry = PlayerLogEntry(type: PlayerLogEntryType.Other, title: title, text: text, timeStamp: Date())
        // append log entry to self.entries
        self.entries.append(logEntry)
        // is the self.autoSave flag is set to true
        if self.autoSave {
            // then save the log entry
            self.appendToPlainTextLog(logEntry: logEntry)
        }
    }    
    ///
    /// Clears the log.
    ///
    func clear() {        
        // clear self.entries
        self.entries.removeAll()
        
        do {                
            // create constant path with path+filename to log
            let path: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.filename, isDirectory: false)
            // if file exists
            if FileManager.default.fileExists(atPath: path.path) {                
                // clear the log, write an empty string to file
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
        // create constant path with path + filename to log
        let path: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.filename, isDirectory: false)
        // save log as this path
        self.saveLogAs(path: path)
    }
    /// 
    /// Saves the log to the given path.
    ///     
    internal func saveLogAs(path: URL)
    {    
        // create a constant string text with this entire log as text
        let text = self.toPlainText()

        do {
            // try to write the log text to path
            try text.write(to: path, atomically: true, encoding: .utf8)            
        } catch {

        }
    }        
    /// 
    /// Converts log to plain text string.
    /// 
    /// - Returns: log as plain text.
    func toPlainText() -> String {
        // create variable of type string
        var text: String = ""
        // loop throuh all entries in self.entries
        for entry in self.entries {
            // append entry as text to text variable
            text += entry.toPlainText()
        }
        // return text variable
        return text
    }
    ///
    /// Appends text to plain text log
    ///
    private func appendToPlainTextLog(logEntry: PlayerLogEntry) {
        // create a variable text of type string which contains the text version of logEntry
        let text: String = logEntry.toPlainText()
        // create a constant filePath that contains the filename + path to log file
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
                // defer and make sure we close file handle
                defer {
                    // Close the file
                    fileHandle.closeFile()
                }
                // Move to the end of the file
                fileHandle.seekToEndOfFile()
                // Convert the string to Data and append it
                if let data = text.data(using: .utf8) {
                    // append text to log
                    fileHandle.write(data)
                }                
            }            
        } 
        catch {
        
        }
    }
}// PlayerLog

