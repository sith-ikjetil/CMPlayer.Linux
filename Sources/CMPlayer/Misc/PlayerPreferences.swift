//
//  PlayerPreferences.swift
//
//  (i): Code that deals with the applications preferences.
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
/// What to do when log max size is reached.
///
internal enum LogMaxSizeReached: String {
    case StopLogging = "StopLogging"
    case EmptyLog = "EmptyLog"
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
    case Custom = "custom"
}
//
// Sound output library to use
//
internal enum OutputSoundLibrary: String {
    case ao = "ao"
    case alsa = "alsa"
}
///
/// Represents CMPlayer PlayerPreferences.
///
internal class PlayerPreferences {
    //
    // Static variables
    //
    static let filename: String = "preferences.xml"
    static var musicRootPath: [String] = []
    static var exclusionPaths: [String] = []
    static var musicFormats: String = ".mp3;.m4a"
    static var autoplayOnStartup: Bool = true
    static var crossfadeSongs: Bool = true
    static var crossfadeTimeInSeconds: Int = 4
    static var viewType: ViewType = ViewType.Details
    static var colorTheme: ColorTheme = ColorTheme.Default
    static var outputSoundLibrary: OutputSoundLibrary = OutputSoundLibrary.ao
    static var logInformation: Bool = true
    static var logWarning: Bool = true
    static var logError: Bool = true
    static var logDebug: Bool = true
    static var logOther: Bool = true
    static var logMaxEntries: Int = 250
    static var historyMaxEntries: Int = 1000
    static var logMaxSizeReached: LogMaxSizeReached = LogMaxSizeReached.EmptyLog
    static var fgHeaderColor: ConsoleColor = .white
    static var bgHeaderColor: ConsoleColor = .blue
    static var fgHeaderModifier: ConsoleColorModifier = .bold
    static var bgHeaderModifier: ConsoleColorModifier = .bold
    static var fgTitleColor: ConsoleColor = .yellow
    static var bgTitleColor: ConsoleColor = .black
    static var fgTitleModifier: ConsoleColorModifier = .bold
    static var bgTitleModifier: ConsoleColorModifier = .none
    static var fgSeparatorColor: ConsoleColor = .green
    static var bgSeparatorColor: ConsoleColor = .black
    static var fgSeparatorModifier: ConsoleColorModifier = .bold
    static var bgSeparatorModifier: ConsoleColorModifier = .none
    static var fgQueueColor: ConsoleColor = .white
    static var bgQueueColor: ConsoleColor = .blue
    static var fgQueueModifier: ConsoleColorModifier = .bold
    static var bgQueueModifier: ConsoleColorModifier = .bold
    static var fgQueueSongNoColor: ConsoleColor = .cyan
    static var bgQueueSongNoColor: ConsoleColor = .blue
    static var fgQueueSongNoModifier: ConsoleColorModifier = .bold
    static var bgQueueSongNoModifier: ConsoleColorModifier = .bold
    static var fgCommandLineColor: ConsoleColor = .cyan
    static var bgCommandLineColor: ConsoleColor = .black
    static var fgCommandLineModifier: ConsoleColorModifier = .bold
    static var bgCommandLineModifier: ConsoleColorModifier = .none
    static var fgStatusLineColor: ConsoleColor = .white
    static var bgStatusLineColor: ConsoleColor = .black
    static var fgStatusLineModifier: ConsoleColorModifier = .bold
    static var bgStatusLineModifier: ConsoleColorModifier = .none
    static var fgAddendumColor: ConsoleColor = .white
    static var bgAddendumColor: ConsoleColor = .black
    static var fgAddendumModifier: ConsoleColorModifier = .bold
    static var bgAddendumModifier: ConsoleColorModifier = .none
    static var fgEmptySpaceColor: ConsoleColor = .white
    static var bgEmptySpaceColor: ConsoleColor = .black
    static var fgEmptySpaceModifier: ConsoleColorModifier = .bold
    static var bgEmptySpaceModifier: ConsoleColorModifier = .bold
    
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
        PlayerPreferences.musicRootPath.removeAll()
        PlayerPreferences.exclusionPaths.removeAll()
        
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
                    PlayerPreferences.colorTheme = ColorTheme(rawValue: aColorTheme.stringValue ?? "default") ?? ColorTheme.Default
                }
                if let aOutputSoundLibrary = xeGeneral.attribute(forName: "outputSoundLibrary") {
                    PlayerPreferences.outputSoundLibrary = OutputSoundLibrary(rawValue: aOutputSoundLibrary.stringValue ?? "ao") ?? OutputSoundLibrary.ao
                }
                if let aHistoryMaxEntries = xeGeneral.attribute(forName: "historyMaxEntries") {
                    PlayerPreferences.historyMaxEntries = Int(aHistoryMaxEntries.stringValue ?? "1000") ?? 1000
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

                // header colors
                if let afgHeaderColor = xeGeneral.attribute(forName: "fgHeaderColor") {
                    PlayerPreferences.fgHeaderColor = ConsoleColor.itsFromString(afgHeaderColor.stringValue ?? "white", .white)
                }
                if let abgHeaderColor = xeGeneral.attribute(forName: "bgHeaderColor") {
                    PlayerPreferences.bgHeaderColor = ConsoleColor.itsFromString(abgHeaderColor.stringValue ?? "blue", .blue)
                }
                if let afgHeaderModifier = xeGeneral.attribute(forName: "fgHeaderModifier") {
                    PlayerPreferences.fgHeaderModifier = ConsoleColorModifier.itsFromString(afgHeaderModifier.stringValue ?? "bold", .bold)
                }
                if let abgHeaderModifier = xeGeneral.attribute(forName: "bgHeaderModifier") {
                    PlayerPreferences.bgHeaderModifier = ConsoleColorModifier.itsFromString(abgHeaderModifier.stringValue ?? "bold", .bold)
                }

                // title colors
                if let afgTitleColor = xeGeneral.attribute(forName: "fgTitleColor") {
                    PlayerPreferences.fgTitleColor = ConsoleColor.itsFromString(afgTitleColor.stringValue ?? "yellow", .yellow)
                }
                if let abgTitleColor = xeGeneral.attribute(forName: "bgTitleColor") {
                    PlayerPreferences.bgTitleColor = ConsoleColor.itsFromString(abgTitleColor.stringValue ?? "black", .black)
                }
                if let afgTitleModifier = xeGeneral.attribute(forName: "fgTitleModifier") {
                    PlayerPreferences.fgTitleModifier = ConsoleColorModifier.itsFromString(afgTitleModifier.stringValue ?? "bold", .bold)
                }
                if let abgTitleModifier = xeGeneral.attribute(forName: "bgTitleModifier") {
                    PlayerPreferences.bgTitleModifier = ConsoleColorModifier.itsFromString(abgTitleModifier.stringValue ?? "none", .none)
                }
                
                // spearator colors
                if let afgSeparatorColor = xeGeneral.attribute(forName: "fgSeparatorColor") {
                    PlayerPreferences.fgSeparatorColor = ConsoleColor.itsFromString(afgSeparatorColor.stringValue ?? "green", .green)
                }
                if let abgSeparatorColor = xeGeneral.attribute(forName: "bgSeparatorColor") {
                    PlayerPreferences.bgSeparatorColor = ConsoleColor.itsFromString(abgSeparatorColor.stringValue ?? "black", .black)
                }
                if let afgSeparatorModifier = xeGeneral.attribute(forName: "fgSeparatorModifier") {
                    PlayerPreferences.fgSeparatorModifier = ConsoleColorModifier.itsFromString(afgSeparatorModifier.stringValue ?? "bold", .bold)
                }
                if let abgSeparatorModifier = xeGeneral.attribute(forName: "bgSeparatorModifier") {
                    PlayerPreferences.bgSeparatorModifier = ConsoleColorModifier.itsFromString(abgSeparatorModifier.stringValue ?? "none", .none)
                }
                
                // queue colors
                if let afgQueueColor = xeGeneral.attribute(forName: "fgQueueColor") {
                    PlayerPreferences.fgQueueColor = ConsoleColor.itsFromString(afgQueueColor.stringValue ?? "white", .white)
                }
                if let abgQueueColor = xeGeneral.attribute(forName: "bgQueueColor") {
                    PlayerPreferences.bgQueueColor = ConsoleColor.itsFromString(abgQueueColor.stringValue ?? "blue", .blue)
                }
                if let afgQueueModifier = xeGeneral.attribute(forName: "fgQueueModifier") {
                    PlayerPreferences.fgQueueModifier = ConsoleColorModifier.itsFromString(afgQueueModifier.stringValue ?? "bold", .bold)
                }
                if let abgQueueModifier = xeGeneral.attribute(forName: "bgQueueModifier") {
                    PlayerPreferences.bgQueueModifier = ConsoleColorModifier.itsFromString(abgQueueModifier.stringValue ?? "bold", .bold)
                }
                

                // queue song no colors
                if let afgQueueSongNoColor = xeGeneral.attribute(forName: "fgQueueSongNoColor") {
                    PlayerPreferences.fgQueueSongNoColor = ConsoleColor.itsFromString(afgQueueSongNoColor.stringValue ?? "cyan", .cyan)
                }
                if let abgQueueSongNoColor = xeGeneral.attribute(forName: "bgQueueSongNoColor") {
                    PlayerPreferences.bgQueueSongNoColor = ConsoleColor.itsFromString(abgQueueSongNoColor.stringValue ?? "blue", .blue)
                }
                if let afgQueueSongNoModifier = xeGeneral.attribute(forName: "fgQueueSongNoModifier") {
                    PlayerPreferences.fgQueueSongNoModifier = ConsoleColorModifier.itsFromString(afgQueueSongNoModifier.stringValue ?? "bold", .bold)
                }
                if let abgQueueSongNoModifier = xeGeneral.attribute(forName: "bgQueueSongNoModifier") {
                    PlayerPreferences.bgQueueSongNoModifier = ConsoleColorModifier.itsFromString(abgQueueSongNoModifier.stringValue ?? "bold", .bold)
                }

                // command line colors
                if let afgCommandLineColor = xeGeneral.attribute(forName: "fgCommandLineColor") {
                    PlayerPreferences.fgCommandLineColor = ConsoleColor.itsFromString(afgCommandLineColor.stringValue ?? "cyan", .cyan)
                }
                if let abgCommandLineColor = xeGeneral.attribute(forName: "bgCommandLineColor") {
                    PlayerPreferences.bgCommandLineColor = ConsoleColor.itsFromString(abgCommandLineColor.stringValue ?? "black", .blue)
                }
                if let afgCommandLineModifier = xeGeneral.attribute(forName: "fgCommandLineModifier") {
                    PlayerPreferences.fgCommandLineModifier = ConsoleColorModifier.itsFromString(afgCommandLineModifier.stringValue ?? "bold", .bold)
                }
                if let abgCommandLineModifier = xeGeneral.attribute(forName: "bgCommandLineModifier") {
                    PlayerPreferences.bgCommandLineModifier = ConsoleColorModifier.itsFromString(abgCommandLineModifier.stringValue ?? "none", .none)
                }

                // status line colors
                if let afgStatusLineColor = xeGeneral.attribute(forName: "fgStatusLineColor") {
                    PlayerPreferences.fgStatusLineColor = ConsoleColor.itsFromString(afgStatusLineColor.stringValue ?? "white", .white)
                }
                if let abgStatusLineColor = xeGeneral.attribute(forName: "bgStatusLineColor") {
                    PlayerPreferences.bgStatusLineColor = ConsoleColor.itsFromString(abgStatusLineColor.stringValue ?? "black", .black)
                }
                if let afgStatusLineModifier = xeGeneral.attribute(forName: "fgStatusLineModifier") {
                    PlayerPreferences.fgStatusLineModifier = ConsoleColorModifier.itsFromString(afgStatusLineModifier.stringValue ?? "bold", .bold)
                }
                if let abgStatusLineModifier = xeGeneral.attribute(forName: "bgStatusLineModifier") {
                    PlayerPreferences.bgStatusLineModifier = ConsoleColorModifier.itsFromString(abgStatusLineModifier.stringValue ?? "none", .none)
                }
                
                // alt colors
                if let afgAddendumColor = xeGeneral.attribute(forName: "fgAddendumColor") {
                    PlayerPreferences.fgAddendumColor = ConsoleColor.itsFromString(afgAddendumColor.stringValue ?? "white", .white)
                }
                if let abgAddendumColor = xeGeneral.attribute(forName: "bgAddendumColor") {
                    PlayerPreferences.bgAddendumColor = ConsoleColor.itsFromString(abgAddendumColor.stringValue ?? "black", .black)
                }
                if let afgAddendumModifier = xeGeneral.attribute(forName: "fgAddendumModifier") {
                    PlayerPreferences.fgAddendumModifier = ConsoleColorModifier.itsFromString(afgAddendumModifier.stringValue ?? "bold", .bold)
                }
                if let abgAddendumModifier = xeGeneral.attribute(forName: "bgAddendumModifier") {
                    PlayerPreferences.bgAddendumModifier = ConsoleColorModifier.itsFromString(abgAddendumModifier.stringValue ?? "none", .none)
                }

                // empty space color
                if let afgEmptySpaceColor = xeGeneral.attribute(forName: "fgEmptySpaceColor") {
                    PlayerPreferences.fgEmptySpaceColor = ConsoleColor.itsFromString(afgEmptySpaceColor.stringValue ?? "white", .white)
                }
                if let abgEmptySpaceColor = xeGeneral.attribute(forName: "bgEmptySpaceColor") {
                    PlayerPreferences.bgEmptySpaceColor = ConsoleColor.itsFromString(abgEmptySpaceColor.stringValue ?? "black", .black)
                }
                if let afgEmptySpaceModifier = xeGeneral.attribute(forName: "fgEmptySpaceModifier") {
                    PlayerPreferences.fgEmptySpaceModifier = ConsoleColorModifier.itsFromString(afgEmptySpaceModifier.stringValue ?? "bold", .bold)
                }
                if let abgEmptySpaceModifier = xeGeneral.attribute(forName: "bgEmptySpaceModifier") {
                    PlayerPreferences.bgEmptySpaceModifier = ConsoleColorModifier.itsFromString(abgEmptySpaceModifier.stringValue ?? "none", .none)
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
                
                if let aLogMaxEntries = xeLog.attribute(forName: "logMaxEntries") {
                    PlayerPreferences.logMaxEntries = Int(aLogMaxEntries.stringValue ?? "100") ?? 100
                }
                
                if let aLogMaxSizeReached = xeLog.attribute(forName: "logMaxSizeReached") {
                    PlayerPreferences.logMaxSizeReached = LogMaxSizeReached(rawValue: aLogMaxSizeReached.stringValue ?? "StopLogging") ?? LogMaxSizeReached.StopLogging
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

        let xnOutputSoundLibrary: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnOutputSoundLibrary.name = "outputSoundLibrary"
        xnOutputSoundLibrary.setStringValue(self.outputSoundLibrary.rawValue, resolvingEntities: false)
        xeGeneral.addAttribute(xnOutputSoundLibrary)

        let xnHistoryMaxEntries: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnHistoryMaxEntries.name = "historyMaxEntries"
        xnHistoryMaxEntries.setStringValue(String(self.historyMaxEntries), resolvingEntities: false)
        xeGeneral.addAttribute(xnHistoryMaxEntries)

        //
        // colors
        //
        // header color
        let xnfgHeaderColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgHeaderColor.name = "fgHeaderColor"
        xnfgHeaderColor.setStringValue(self.fgHeaderColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgHeaderColor)

        let xnbgHeaderColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgHeaderColor.name = "bgHeaderColor"
        xnbgHeaderColor.setStringValue(self.bgHeaderColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgHeaderColor)

        let xnfgHeaderModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgHeaderModifier.name = "fgHeaderModifier"
        xnfgHeaderModifier.setStringValue(self.fgHeaderModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgHeaderModifier)

        let xnbgHeaderModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgHeaderModifier.name = "bgHeaderModifier"
        xnbgHeaderModifier.setStringValue(self.bgHeaderModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgHeaderModifier)
        
        // title color
        let xnfgTitleColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgTitleColor.name = "fgTitleColor"
        xnfgTitleColor.setStringValue(self.fgTitleColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgTitleColor)
        
        let xnbgTitleColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgTitleColor.name = "bgTitleColor"
        xnbgTitleColor.setStringValue(self.bgTitleColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgTitleColor)

        let xnfgTitleModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgTitleModifier.name = "fgTitleModifier"
        xnfgTitleModifier.setStringValue(self.fgTitleModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgTitleModifier)

        let xnbgTitleModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgTitleModifier.name = "bgTitleModifier"
        xnbgTitleModifier.setStringValue(self.bgTitleModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgTitleModifier)
        
        // separator
        let xnfgSeparatorColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgSeparatorColor.name = "fgSeparatorColor"
        xnfgSeparatorColor.setStringValue(self.fgSeparatorColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgSeparatorColor)
        
        let xnbgSeparatorColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgSeparatorColor.name = "bgSeparatorColor"
        xnbgSeparatorColor.setStringValue(self.bgSeparatorColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgSeparatorColor)

        let xnfgSeparatorModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgSeparatorModifier.name = "fgSeparatorModifier"
        xnfgSeparatorModifier.setStringValue(self.fgSeparatorModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgSeparatorModifier)

        let xnbgSeparatorModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgSeparatorModifier.name = "bgSeparatorModifier"
        xnbgSeparatorModifier.setStringValue(self.bgSeparatorModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgSeparatorModifier)
        
        // queue
        let xnfgQueueColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgQueueColor.name = "fgQueueColor"
        xnfgQueueColor.setStringValue(self.fgQueueColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgQueueColor)
        
        let xnbgQueueColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgQueueColor.name = "bgQueueColor"
        xnbgQueueColor.setStringValue(self.bgQueueColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgQueueColor)

        let xnfgQueueModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgQueueModifier.name = "fgQueueModifier"
        xnfgQueueModifier.setStringValue(self.fgQueueModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgQueueModifier)

        let xnbgQueueModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgQueueModifier.name = "bgQueueModifier"
        xnbgQueueModifier.setStringValue(self.bgQueueModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgQueueModifier)        

        // queue song no
        let xnfgQueueSongNoColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgQueueSongNoColor.name = "fgQueueSongNoColor"
        xnfgQueueSongNoColor.setStringValue(self.fgQueueSongNoColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgQueueSongNoColor)
        
        let xnbgQueueSongNoColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgQueueSongNoColor.name = "bgQueueSongNoColor"
        xnbgQueueSongNoColor.setStringValue(self.bgQueueSongNoColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgQueueSongNoColor)

        let xnfgQueueSongNoModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgQueueSongNoModifier.name = "fgQueueSongNoModifier"
        xnfgQueueSongNoModifier.setStringValue(self.fgQueueSongNoModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgQueueSongNoModifier)

        let xnbgQueueSongNoModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgQueueSongNoModifier.name = "bgQueueSongNoModifier"
        xnbgQueueSongNoModifier.setStringValue(self.bgQueueSongNoModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgQueueSongNoModifier)
        
        // command line
        let xnfgCommandLineColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgCommandLineColor.name = "fgCommandLineColor"
        xnfgCommandLineColor.setStringValue(self.fgCommandLineColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgCommandLineColor)
        
        let xnbgCommandLineColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgCommandLineColor.name = "bgCommandLineColor"
        xnbgCommandLineColor.setStringValue(self.bgCommandLineColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgCommandLineColor)

        let xnfgCommandLineModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgCommandLineModifier.name = "fgCommandLineModifier"
        xnfgCommandLineModifier.setStringValue(self.fgCommandLineModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgCommandLineModifier)

        let xnbgCommandLineModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgCommandLineModifier.name = "bgCommandLineModifier"
        xnbgCommandLineModifier.setStringValue(self.bgCommandLineModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgCommandLineModifier)
        
        // status lines
        let xnfgStatusLineColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgStatusLineColor.name = "fgStatusLineColor"
        xnfgStatusLineColor.setStringValue(self.fgStatusLineColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgStatusLineColor)
        
        let xnbgStatusLineColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgStatusLineColor.name = "bgStatusLineColor"
        xnbgStatusLineColor.setStringValue(self.bgStatusLineColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgStatusLineColor)

        let xnfgStatusLineModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgStatusLineModifier.name = "fgStatusLineModifier"
        xnfgStatusLineModifier.setStringValue(self.fgStatusLineModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgStatusLineModifier)

        let xnbgStatusLineModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgStatusLineModifier.name = "bgStatusLineModifier"
        xnbgStatusLineModifier.setStringValue(self.bgStatusLineModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgStatusLineModifier)

        // alt
        let xnfgAddendumColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgAddendumColor.name = "fgAddendumColor"
        xnfgAddendumColor.setStringValue(self.fgAddendumColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgAddendumColor)
        
        let xnbgAddendumColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgAddendumColor.name = "bgAddendumColor"
        xnbgAddendumColor.setStringValue(self.bgAddendumColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgAddendumColor)

        let xnfgAddendumModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgAddendumModifier.name = "fgAddendumModifier"
        xnfgAddendumModifier.setStringValue(self.fgAddendumModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgAddendumModifier)

        let xnbgAddendumModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgAddendumModifier.name = "bgAddendumModifier"
        xnbgAddendumModifier.setStringValue(self.bgAddendumModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgAddendumModifier)
        
        // empty space
        let xnfgEmptySpaceColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgEmptySpaceColor.name = "fgEmptySpaceColor"
        xnfgEmptySpaceColor.setStringValue(self.fgEmptySpaceColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgEmptySpaceColor)
        
        let xnbgEmptySpaceColor: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgEmptySpaceColor.name = "bgEmptySpaceColor"
        xnbgEmptySpaceColor.setStringValue(self.bgEmptySpaceColor.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgEmptySpaceColor)

        let xnfgEmptySpaceModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnfgEmptySpaceModifier.name = "fgEmptySpaceModifier"
        xnfgEmptySpaceModifier.setStringValue(self.fgEmptySpaceModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnfgEmptySpaceModifier)

        let xnbgEmptySpaceModifier: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnbgEmptySpaceModifier.name = "bgEmptySpaceModifier"
        xnbgEmptySpaceModifier.setStringValue(self.bgEmptySpaceModifier.itsToString(), resolvingEntities: false)
        xeGeneral.addAttribute(xnbgEmptySpaceModifier)
        
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
        
        let xnLogMaxEntries: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnLogMaxEntries.name = "logMaxEntries"
        xnLogMaxEntries.setStringValue(String(self.logMaxEntries), resolvingEntities: false)
        xeLog.addAttribute(xnLogMaxEntries)
        
        let xnLogMaxSizeReached: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
        xnLogMaxSizeReached.name = "logMaxSizeReached"
        xnLogMaxSizeReached.setStringValue(self.logMaxSizeReached.rawValue, resolvingEntities: false)
        xeLog.addAttribute(xnLogMaxSizeReached)
                
        //
        // save
        //
        let url: URL = PlayerDirectories.consoleMusicPlayerDirectory
        let fileUrl = url.appendingPathComponent(PlayerPreferences.filename, isDirectory: false)
        
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
        let dir = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerPreferences.filename, isDirectory: false)
        if FileManager.default.fileExists(atPath: dir.path) == false {
            PlayerPreferences.savePreferences()
        }
        
        PlayerPreferences.loadPreferences(dir)
    }// ensureLoadPreferences
}// PlayerPreferences
