//
//  PlayerDirectories.swift
//
//  (i): Code dealing with directories used in this application.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import.
//
import Foundation
import FoundationNetworking
///
/// Represents CMPlayer PlayerDirectories
///
internal class PlayerDirectories {    
    //
    // Computed properties
    //
    internal static var homeDirectory: URL {
        return FileManager.default.homeDirectoryForCurrentUser
    }
    internal static var consoleMusicPlayerDirectory: URL {
        return PlayerDirectories.homeDirectory.appendingPathComponent(".cmplayer", isDirectory: true)
    }    
    internal static var consoleMusicPlayerScriptsDirectory: URL {
        return PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent("scripts", isDirectory: true)
    }    
    ///
    /// Ensures that directories needed exists. Is called upon application startup.
    ///
    internal static func ensureDirectoriesExistence() {
        let cmpDir: URL = PlayerDirectories.consoleMusicPlayerDirectory
        if FileManager.default.fileExists(atPath: cmpDir.path) == false {
            do {
                try FileManager.default.createDirectory(at: cmpDir, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                
            }
        }
        let scriptDir: URL = PlayerDirectories.consoleMusicPlayerScriptsDirectory
        if FileManager.default.fileExists(atPath: scriptDir.path) == false {
            do {
                try FileManager.default.createDirectory(at: scriptDir, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                
            }
        }
    }// enusreDirectoriesExistence
    internal static func purge() -> Bool {
        let cmpDir: URL = PlayerDirectories.consoleMusicPlayerDirectory
        if FileManager.default.fileExists(atPath: cmpDir.path) {
            do {
                try FileManager.default.removeItem(at: cmpDir)                
            }
            catch {
                return false
            }
        }                
        return true
    }
}// PlayerDirectories
