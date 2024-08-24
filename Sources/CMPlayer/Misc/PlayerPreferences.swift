//
//  PlayerPreferences.swift
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//

//
// import.
//
import Foundation
//import FoundationNetworking
import FoundationXML

///
/// What to do when log max size is reached.
///
internal enum LogMaxSizeReached: String {
    case StopLogging = "StopLogging"
    case EmptyLog = "EmptyLog"
}

///
/// What to do with log when application starts
///
internal enum LogApplicationStartLoadType: String {
    case DoNotLoadOldLog = "DoNotLoadOldLog"
    case LoadOldLog = "LoadOldLog"
}

///
/// MainWindow View Type
///
internal enum ViewType: String {
    case Default = "default"
    case Details = "details"
}

//
// Application Color Theme
//
internal enum ColorTheme: String {
    case Default = "default"
    case Blue = "blue"
    case Black = "black"
}

///
/// Represents CMPlayer PlayerPreferences.
///
internal class PlayerPreferences {
    //
    // Static variables
    //
    static let preferencesFilename: String = "CMPlayer.Preferences.xml"
    static var musicRootPath: [String] = []
    static var exclusionPaths: [String] = []
    static var musicFormats: String = "mp3;m4a"
    static var autoplayOnStartup: Bool = true
    static var crossfadeSongs: Bool = true
    static var crossfadeTimeInSeconds: Int = 4
    static var viewType: ViewType = ViewType.Details
    static var colorTheme: ColorTheme = ColorTheme.Default
    static var logInformation: Bool = true
    static var logWarning: Bool = true
    static var logError: Bool = true
    static var logDebug: Bool = true
    static var logOther: Bool = true
    static var logMaxSize: Int = 500
    static var logMaxSizeReached: LogMaxSizeReached = LogMaxSizeReached.EmptyLog
    static let logMaxSizes: [Int] = [100, 500, 1000, 2000, 3000, 4000, 5000]
    static var logApplicationStartLoadType: LogApplicationStartLoadType = LogApplicationStartLoadType.DoNotLoadOldLog    
    ///
    /// Default initializer.
    ///
    init() {
        
    }    
    ///
    /// Loads preferences from file
    ///
    /// parameter fileUrl: Path to preferences file.
    ///
    static func loadPreferences(_ fileUrl: URL ) {
        do {
            let xd: XMLDocument = try XMLDocument(contentsOf: fileUrl)
            let xeRoot = xd.rootElement()!
            
            // General
            var elements: [XMLElement] = xeRoot.elements(forName: "general")
            if elements.count == 1 {
                let xeGeneral: XMLElement = elements[0]
                
                if let aAutoplayOnStartup = xeGeneral.attribute(forName: "autoplayOnStartup" ) {
                    PlayerPreferences.autoplayOnStartup = Bool(aAutoplayOnStartup.stringValue ?? "false") ?? false
                }
                if let aCrossfadeSongs = xeGeneral.attribute(forName: "crossfadeSongs" ) {
                    PlayerPreferences.crossfadeSongs = Bool(aCrossfadeSongs.stringValue ?? "false") ?? false
                }
                if let aCrossfadeTimeInSeconds = xeGeneral.attribute(forName: "crossfadeTimeInSeconds" ) {
                    let cftis = Int(aCrossfadeTimeInSeconds.stringValue ?? "2") ?? 2
                    if isCrossfadeTimeValid(seconds: cftis) {
                        PlayerPreferences.crossfadeTimeInSeconds = cftis
                    }
                }
                if let aViewType = xeGeneral.attribute(forName: "viewType") {
                    PlayerPreferences.viewType = ViewType(rawValue: aViewType.stringValue ?? "default") ?? ViewType.Default
                }
                if let aColorTheme = xeGeneral.attribute(forName: "colorTheme") {
                    PlayerPreferences.colorTheme = ColorTheme(rawValue: aColorTheme.stringValue ?? "blue") ?? ColorTheme.Blue
                }
                
                
                let xeMusicRootPaths = xeGeneral.elements(forName: "musicRootPath")
                for p in xeMusicRootPaths {
                    let path = p.stringValue ?? ""
                    if path.count > 0 {
                        self.musicRootPath.append(path)
                    }
                }
                
                let xeExclusionPaths = xeGeneral.elements(forName: "exclusionPath")
                for p in xeExclusionPaths {
                    let path = p.stringValue ?? ""
                    if path.count > 0 {
                        self.exclusionPaths.append(path)
                    }
                }
            }
            
            // log
            elements = xeRoot.elements(forName: "log")
            if elements.count == 1 {
                let xeLog: XMLElement = elements[0]
                
                if let aLogInformation = xeLog.attribute(forName: "logInformation") {
                    PlayerPreferences.logInformation = Bool(aLogInformation.stringValue ?? "true") ?? true
                }
                
                if let aLogWarning = xeLog.attribute(forName: "logWarning") {
                    PlayerPreferences.logWarning = Bool(aLogWarning.stringValue ?? "true") ?? true
                }
                
                if let aLogError = xeLog.attribute(forName: "logError") {
                    PlayerPreferences.logError = Bool(aLogError.stringValue ?? "true") ?? true
                }
                
                if let aLogDebug = xeLog.attribute(forName: "logDebug") {
                    PlayerPreferences.logDebug = Bool(aLogDebug.stringValue ?? "false") ?? false
                }
                
                if let aLogOther = xeLog.attribute(forName: "logOther") {
                    PlayerPreferences.logOther = Bool(aLogOther.stringValue ?? "false") ?? false
                }
                
                if let aLogMaxSize = xeLog.attribute(forName: "logMaxSize") {
                    PlayerPreferences.logMaxSize = Int(aLogMaxSize.stringValue ?? "1000") ?? 1000
                }
                
                if let aLogMaxSizeReached = xeLog.attribute(forName: "logMaxSizeReached") {
                    PlayerPreferences.logMaxSizeReached = LogMaxSizeReached(rawValue: aLogMaxSizeReached.stringValue ?? "StopLogging") ?? LogMaxSizeReached.StopLogging
                }
                
                if let aLogApplicationStartLoadType = xeLog.attribute(forName: "logApplicationStartLoadType") {
                    PlayerPreferences.logApplicationStartLoadType = LogApplicationStartLoadType(rawValue: aLogApplicationStartLoadType.stringValue ?? "LoadOldLog") ?? LogApplicationStartLoadType.LoadOldLog
                }
                
            }
            
        }
        catch {
            
        }
    }
    ///
    /// Saves preferences to file
    ///
    static func savePreferences() {
        let xeRoot: XMLElement = XMLElement(name: "preferences")
        
        //
        // general element
        //
        let xeGeneral: XMLElement = XMLElement(name: "general")
        xeRoot.addChild(xeGeneral)
        
        for path in self.musicRootPath {
            let xeMusicRootPath: XMLElement = XMLElement(name: "musicRootPath")
            xeMusicRootPath.setStringValue(path, resolvingEntities: false)
            xeGeneral.addChild(xeMusicRootPath)
        }
        
        for path in self.exclusionPaths {
            let xeExclusionPath: XMLElement = XMLElement(name: "exclusionPath")
            xeExclusionPath.setStringValue(path, resolvingEntities: false)
            xeGeneral.addChild(xeExclusionPath)
        }
        
        let xnMusicFormats: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnMusicFormats.name = "musicFormats"
        xnMusicFormats.setStringValue(PlayerPreferences.musicFormats, resolvingEntities: false)
        xeGeneral.addAttribute(xnMusicFormats)
        
        let xnAutoplayOnStartup: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnAutoplayOnStartup.name = "autoplayOnStartup"
        xnAutoplayOnStartup.setStringValue(String(PlayerPreferences.autoplayOnStartup), resolvingEntities: false)
        xeGeneral.addAttribute(xnAutoplayOnStartup)
        
        let xnCrossfadeSongs: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnCrossfadeSongs.name = "crossfadeSongs"
        xnCrossfadeSongs.setStringValue(String(PlayerPreferences.crossfadeSongs), resolvingEntities: false)
        xeGeneral.addAttribute(xnCrossfadeSongs)
        
        let xnCrossfadeTimeInSeconds: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnCrossfadeTimeInSeconds.name = "crossfadeTimeInSeconds"
        xnCrossfadeTimeInSeconds.setStringValue(String(PlayerPreferences.crossfadeTimeInSeconds), resolvingEntities: false)
        xeGeneral.addAttribute(xnCrossfadeTimeInSeconds)
        
        let xnViewType: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnViewType.name = "viewType"
        xnViewType.setStringValue(self.viewType.rawValue, resolvingEntities: false)
        xeGeneral.addAttribute(xnViewType)
        
        let xnColorTheme: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnColorTheme.name = "colorTheme"
        xnColorTheme.setStringValue(self.colorTheme.rawValue, resolvingEntities: false)
        xeGeneral.addAttribute(xnColorTheme)
        
        //
        // log
        //
        let xeLog: XMLElement = XMLElement(name: "log")
        xeRoot.addChild(xeLog)
        
        let xnLogInformation: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnLogInformation.name = "logInformation"
        xnLogInformation.setStringValue(String(self.logInformation), resolvingEntities: false)
        xeLog.addAttribute(xnLogInformation)
        
        let xnLogWarning: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnLogWarning.name = "logWarning"
        xnLogWarning.setStringValue(String(self.logWarning), resolvingEntities: false)
        xeLog.addAttribute(xnLogWarning)
        
        let xnLogError: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnLogError.name = "logError"
        xnLogError.setStringValue(String(self.logError), resolvingEntities: false)
        xeLog.addAttribute(xnLogError)
        
        let xnLogDebug: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnLogDebug.name = "logDebug"
        xnLogDebug.setStringValue(String(self.logDebug), resolvingEntities: false)
        xeLog.addAttribute(xnLogDebug)
        
        let xnLogOther: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnLogOther.name = "logOther"
        xnLogOther.setStringValue(String(self.logOther), resolvingEntities: false)
        xeLog.addAttribute(xnLogOther)
        
        let xnLogMaxSize: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnLogMaxSize.name = "logMaxSize"
        xnLogMaxSize.setStringValue(String(self.logMaxSize), resolvingEntities: false)
        xeLog.addAttribute(xnLogMaxSize)
        
        let xnLogMaxSizeReached: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnLogMaxSizeReached.name = "logMaxSizeReached"
        xnLogMaxSizeReached.setStringValue(self.logMaxSizeReached.rawValue, resolvingEntities: false)
        xeLog.addAttribute(xnLogMaxSizeReached)
        
        let xnLogApplicationStartLoadType: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnLogApplicationStartLoadType.name = "logApplicationStartLoadType"
        xnLogApplicationStartLoadType.setStringValue(self.logApplicationStartLoadType.rawValue, resolvingEntities: false)
        xeLog.addAttribute(xnLogApplicationStartLoadType)
        
        //
        // save
        //
        let url: URL = PlayerDirectories.consoleMusicPlayerDirectory
        let fileUrl = url.appendingPathComponent(PlayerPreferences.preferencesFilename, isDirectory: false)
        
        let xd: XMLDocument = XMLDocument(rootElement: xeRoot)
        do {
            //let str: String = xd.xmlString
            try xd.xmlString.write(to: fileUrl, atomically: true, encoding: .utf8)
        }
        catch {
            
        }
    }
    ///
    /// Ensures that preferences file exists. If it does not create it by saving it. Anyhow load it.
    ///
    static func ensureLoadPreferences()
    {
        let dir = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerPreferences.preferencesFilename, isDirectory: false)
        if FileManager.default.fileExists(atPath: dir.path) == false {
            PlayerPreferences.savePreferences()
        }
        
        PlayerPreferences.loadPreferences(dir)
    }// ensureLoadPreferences
}// PlayerPreferences
