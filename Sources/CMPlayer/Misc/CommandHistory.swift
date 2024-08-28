import Foundation

///
/// CommandHistory keeps track of commands and their history.
/// 
internal class CommandHistory {
    ///
    /// static constants
    /// 
    static let filename = "history"
    ///
    /// static variables
    ///
    static let player: CommandHistory = CommandHistory()
    //
    // private variables
    //
    private var history: [String] = []
    private var historyIndex: Int = -1
    /// 
    /// adds a command to history
    /// 
    /// - Parameter command: 
    func add(command: String) {
        self.history.append(command)
        self.historyIndex = self.history.count
        self.writeCommandToHistory(command: command)
    }
    ///
    /// goes down in history, towards index 0.
    /// 
    func push() -> String? {
         if self.history.count > 0 {
            self.historyIndex -= 1
            if historyIndex >= 0 {
                if self.historyIndex < self.history.count {
                    return self.history[self.historyIndex]
                }               
                else {
                    self.historyIndex = self.history.count
                    return ""
                } 
            }
            else if self.historyIndex < 0 {
                self.historyIndex = 0
                return self.history[self.historyIndex]
            }
        }
        return nil
    }
    /// 
    /// does up in history, towards index history.count.
    /// 
    func pop() -> String? {
        if self.history.count > 0 {
            self.historyIndex += 1
            if self.historyIndex >= 0 {
                if self.historyIndex < self.history.count {
                    return self.history[self.historyIndex]
                }
                else {
                    self.historyIndex = self.history.count
                    return ""
                }
            }
            else if self.historyIndex < 0 {
                self.historyIndex = 0
                return self.history[self.historyIndex]
            }
        }
        return nil
    }
    /// 
    /// appends a command to history file.
    /// 
    /// - Parameter command:  command to write.
    private func writeCommandToHistory(command: String) {        
        let text: String = "\(command)\n"
        let filePath: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(CommandHistory.filename, isDirectory: false)
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
    /// 
    /// renders history to a String.
    /// 
    /// - Returns: 
    func render() -> String {
        var text: String = ""
        for cmd in self.history {
            text += "\(cmd)\n"
        }
        return text
    }
    /// 
    /// saves history to default file.
    /// 
    /// - Throws: 
    func save() throws {
        let filePath: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(CommandHistory.filename, isDirectory: false)
        try render().write(to: filePath, atomically: true, encoding: .utf8)
    }
    /// 
    /// clears history from this instance and from file.
    ///     
    func clear() throws {
        self.history.removeAll()
        let filePath: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(CommandHistory.filename, isDirectory: false)
        try "".write(to: filePath, atomically: true, encoding: .utf8)        
    }
    ///
    /// ensure history file exists and has no more than PlayerPreferences.historyMaxEntries entries.
    /// 
    func ensureLoadCommandHistory() throws {        
        let filePath: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(CommandHistory.filename, isDirectory: false)
        if !FileManager.default.fileExists(atPath: filePath.path) {
            try "".write(to: filePath, atomically: true, encoding: .utf8)
            return
        }    

        let fileContents = try String(contentsOfFile: filePath.path)
        fileContents.enumerateLines { line, _ in
            self.add(command: line)
        }

        let historyCount = self.history.count
        while self.history.count > PlayerPreferences.historyMaxEntries {
            self.history.remove(at: 0)
        }
        self.historyIndex = self.history.count
        if historyCount > PlayerPreferences.historyMaxEntries {
            try self.save()
        }
    }
}