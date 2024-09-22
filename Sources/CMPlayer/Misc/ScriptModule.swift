//
//  AudioHelpers.swift
//
//  (i): Helper functions/etc. that is used in audio decoding or playback.
//
//  Created by Kjetil Kr Solberg on 27-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
import Foundation

internal class ScriptModule {
    private let m_filename: String
    private var m_statements: [String]

    var filename: String {
        get {
            return self.m_filename
        }
    }    

    var statements: [String] {
        get {
            return self.m_statements
        }
    }

    init(filename: String) throws {
        if filename.count == 0 {
            // no, create error message
            let msg: String = "[ScriptModule].init. Invalid filename zero length"
            // throw error
            throw CmpError(message: msg)
        }
        self.m_filename = filename
        self.m_statements = []
    }

    func load() throws {
        var filePath: URL = PlayerDirectories.consoleMusicPlayerScriptsDirectory
        filePath.appendPathComponent(self.m_filename)

        if !FileManager.default.fileExists(atPath: filePath.path) {
            // no, create error message
            let msg: String = "[ScriptModule].load. File not found: \(filePath.path)"
            // throw error
            throw CmpError(message: msg)
        }        

        let fileContents: String = try String(contentsOfFile: filePath.path)
        fileContents.enumerateLines { line, _ in            
            if line.count > 0  {
                self.m_statements.append(line)                 
            }
        }
    }

    func save() throws {
        var filePath: URL = PlayerDirectories.consoleMusicPlayerScriptsDirectory
        filePath.appendPathComponent(self.m_filename)

        if FileManager.default.fileExists(atPath: filePath.path) {
            try FileManager.default.removeItem(at: filePath)             
        }        

        var fileContents: String = ""
        for s: String in self.m_statements {
            if s.count > 0 {
                fileContents += s
                fileContents += "\n"
            }
        }        
        try fileContents.write(to: filePath, atomically: true, encoding: .utf8)
    }

    func addStatement(_ statement: String) {
        if statement.count > 0 {
            self.m_statements.append(statement)
        }
    }

    func clearStatement() {
        self.m_statements.removeAll()
    }
}