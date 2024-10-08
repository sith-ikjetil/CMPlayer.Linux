//
// PlayerLibrary.swift
//
// (i): Code dealing with player library. load/save/rebuild.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import.
//
import Foundation
import FoundationNetworking
import FoundationXML
///
/// Represents CMPlayer PlayerLibrary
///
internal class PlayerLibrary {
    //
    // Private properties/constants
    //
    static let filename: String = "library.xml"
    private var nextSongNo: Int = 1    
    //
    // variables
    //
    var library: [SongEntry] = []    
    var dictionary: [String: Int] = [:]    
    ///
    /// Default initializer
    ///
    init() {        
    
    }    
    ///
    /// Find SongEntry in self.dictionary. Return it or nil if not existing.
    ///
    func find(url: URL) -> SongEntry? {
        if let item = self.dictionary[url.path] {
            if self.library.count > item {
                return self.library[item]
            }
        }
        return nil
    }    
    ///
    /// Return next available SongNo.
    ///
    /// returns: Next available song number.
    ///
    func nextAvailableSongNo() -> Int {
        let retVal: Int = self.nextSongNo
        self.nextSongNo += 1
        return retVal
    }    
    ///
    /// Sets the next available number
    ///
    /// parameter songNo: SongNo.
    ///
    func setNextAvailableSongNo(_ songNo: Int) -> Void {
        self.nextSongNo = songNo
    }    
    ///
    /// Loads the CMPlayer.Library.xml song library for faster song initialization load time.
    ///
    func load() throws {
        let fileUrl: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLibrary.filename, isDirectory: false)
        if FileManager.default.fileExists(atPath: fileUrl.path) {            
            do {
                self.dictionary.removeAll()
                self.library.removeAll()
                
                let xd: XMLDocument = try XMLDocument(contentsOf: fileUrl)
                let xeSongLibrary = xd.rootElement()!
            
                let xeSongs = xeSongLibrary.elements(forName: "Song")
                
                for s in xeSongs {
                    var songNo: Int = 0
                    var artist: String = ""
                    var albumName: String = ""
                    var title: String = ""
                    var url: String = ""
                    var duration: UInt64 = 0
                    var genre: String = ""
                    var recordingYear: Int = 0
                    var trackNo: Int = 0
                    
                    if let aNumber = s.attribute(forName: "songNo") {
                        songNo = Int(aNumber.stringValue ?? "0") ?? 0
                    }
                    if let aArtist = s.attribute(forName: "artist") {
                        artist = aArtist.stringValue ?? ""
                    }
                    if let aAlbumName = s.attribute(forName: "albumName") {
                        albumName = aAlbumName.stringValue ?? ""
                    }
                    if let aTitle = s.attribute(forName: "title") {
                        title = aTitle.stringValue ?? ""
                    }
                    if let aDuration = s.attribute(forName: "duration") {
                        duration = UInt64(aDuration.stringValue ?? "0") ?? 0
                    }
                    if let aUrl = s.attribute(forName: "url") {
                        url = aUrl.stringValue ?? ""
                    }
                    if let aGenre = s.attribute(forName: "genre") {
                        genre = aGenre.stringValue?.lowercased() ?? g_metadataNotFoundName
                    }
                    if let aRecordingYear = s.attribute(forName: "recordingYear") {
                        recordingYear = Int(aRecordingYear.stringValue ?? "0") ?? 0
                    }
                    if let aTrackNo = s.attribute(forName: "trackNo") {
                        trackNo = Int(aTrackNo.stringValue ?? "0") ?? 0
                    }

                    if songNo > self.nextSongNo {
                        self.nextSongNo = songNo + 1
                    }
                    
                    if isPathInMusicRootPath(path: url) && !isPathInExclusionPath(path: url) {
                        do
                        {
                            let se = try SongEntry(songNo: songNo, artist: artist, albumName: albumName, title: title, duration: duration, url: URL(fileURLWithPath: url), genre: genre, recordingYear: recordingYear, trackNo: trackNo)
                            self.library.append(se)
                            if url.count > 0 {
                                self.dictionary[url] = self.library.count-1
                            }
                        }
                        catch let error as CmpError {                            
                            let msg = "Error adding song to library. Message: \(error.message)"
                            PlayerLog.ApplicationLog?.logWarning(title: "[PlayerLibrary].load()", text: msg)
                        }
                        catch {
                            
                        }
                    }
                }
            }
            catch {
                let msg = "[PlayerLibrary].load(). Error: \(error)."
                throw CmpError(message: msg)
            }
        }
    }    
    ///
    /// Saves the self.library SongEntry array to CMPlayer.Library.xml.
    ///
    func save() {
        let xeRoot: XMLElement = XMLElement(name: "SongLibrary")
        
        for s in self.library {
            let xeSong: XMLElement = XMLElement(name: "Song")
            xeRoot.addChild(xeSong)
            
            let xnSongNo: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
            xnSongNo.name = "songNo"
            xnSongNo.setStringValue(String(s.songNo), resolvingEntities: false)
            xeSong.addAttribute(xnSongNo)
            
            let xnArtist: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
            xnArtist.name = "artist"
            xnArtist.setStringValue(s.fullArtist, resolvingEntities: false)
            xeSong.addAttribute(xnArtist)
            
            let xnAlbumName: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
            xnAlbumName.name = "albumName"
            xnAlbumName.setStringValue(s.fullAlbumName, resolvingEntities: false)
            xeSong.addAttribute(xnAlbumName)
            
            let xnTitle: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
            xnTitle.name = "title"
            xnTitle.setStringValue(s.fullTitle, resolvingEntities: false)
            xeSong.addAttribute(xnTitle)
            
            let xnDuration: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
            xnDuration.name = "duration"
            xnDuration.setStringValue(String(s.duration), resolvingEntities: false)
            xeSong.addAttribute(xnDuration)
            
            let xnUrl: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
            xnUrl.name = "url"
            xnUrl.setStringValue(s.fileURL?.path ?? "", resolvingEntities: false)
            xeSong.addAttribute(xnUrl)
            
            let xnGenre: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
            xnGenre.name = "genre"
            xnGenre.setStringValue(s.fullGenre.lowercased(), resolvingEntities: false)
            xeSong.addAttribute(xnGenre)
            
            let xnRecordingYear: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
            xnRecordingYear.name = "recordingYear"
            xnRecordingYear.setStringValue(String(s.recordingYear), resolvingEntities: false)
            xeSong.addAttribute(xnRecordingYear)
            
            let xnTrackNo: XMLNode = XMLNode(kind: XMLNode.Kind.attribute)
            xnTrackNo.name = "trackNo"
            xnTrackNo.setStringValue(String(s.trackNo), resolvingEntities: false)
            xeSong.addAttribute(xnTrackNo)
        }
   
        //
        // save
        //
        let fileUrl: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLibrary.filename, isDirectory: false)
        
        let xd: XMLDocument = XMLDocument(rootElement: xeRoot)
        do {
            //let str: String = xd.xmlString
            try xd.xmlString.write(to: fileUrl, atomically: true, encoding: .utf8)
        }
        catch {
            
        }
    }// save
    ///
    /// rebuilds all data structures from newly made g_songs    
    /// 
    func rebuild() {
        // clear self.library        
        self.library.removeAll()
        // clear self.dictionary
        self.dictionary.removeAll()
        // clear g_genres
        g_genres.removeAll()
        // clear g_artists
        g_artists.removeAll()
        // clear g_recordingYears
        g_recordingYears.removeAll()
        // set self.library to g_songs (all songs)
        self.library = g_songs
        // loop through all songs in g_songs(self.library(se above)) and rebuild
        var index: Int = 0
        for se: SongEntry in self.library {
            // append genre
            let genre = se.genre.lowercased()
            if g_genres[genre] == nil {
                g_genres[genre] = []
            }                    
            g_genres[genre]?.append(se)                    
            // append to artists
            let artist = se.artist
            if g_artists[artist] == nil {
                g_artists[artist] = []
            }
            g_artists[artist]?.append(se)                    
            // append to years
            if g_recordingYears[se.recordingYear] == nil {
                g_recordingYears[se.recordingYear] = []
            }                    
            g_recordingYears[se.recordingYear]?.append(se)
            // update g_library.dictionary
            g_library.dictionary[se.fileURL!.path] = index
            // increment index by 1
            index += 1
        }            
    }
}// PlayerLibrary
