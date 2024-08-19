//
//  SongEntry.swift
//  ConsoleMusicPlayer-macOS
//
//  Created by Kjetil Kr Solberg on 18/09/2019.
//  Copyright © 2019 Kjetil Kr Solberg. All rights reserved.
//

//
// import.
//
import Foundation
import FoundationNetworking
import Cmpg123

///
/// Represents CMPlayer SongEntry
///
internal class SongEntry {
    //
    // Properties/Constants.
    //
    let unknownMetadataStringValue: String = "--unknown--"
    var songNo: Int = 0
    var artist: String = ""
    var fullArtist: String = ""
    var title: String = ""
    var fullTitle: String = ""
    var duration: UInt64 = 0
    var fileURL: URL? = nil
    var genre: String = ""
    var fullGenre: String = ""
    var albumName: String = ""
    var fullAlbumName: String = ""
    var recordingYear: Int = 0
    var trackNo: Int = 0    
    let maxStringLength: Int = 32

    ///
    /// Overloaded initializer. Is only called from PlayerLibrary.load()
    ///
    /// parameter number: Song No.
    /// parameter artist: Artist.
    /// parameter title: Title.
    /// parameter duration: Song length in milliseconds.
    /// parameter url: Song file path.
    ///
    init(songNo: Int, artist: String, albumName: String, title: String, duration: UInt64, url: URL?, genre: String, recordingYear: Int, trackNo: Int) throws {
        guard url != nil else {
            PlayerLog.ApplicationLog?.logError(title: "[SongEntry].init(songNo:,artist:,albumName:,title:,duration:,url:,genre:,recordingYear:,trackNo:)", text: "path == nil")
            throw SongEntryError.PathIsNil
        }
        
        guard isPathInMusicRootPath(path: url!.path) else {
            PlayerLog.ApplicationLog?.logError(title: "[SongEntry].init(songNo:,artist:,albumName:,title:,duration:,url:,genre:,recordingYear:,trackNo:)", text: "url not in music root path:\(url!.path)}")
            throw SongEntryError.PathNotInMusicRootPath
        }
        
        guard !isPathInExclusionPath(path: url!.path) else {
            PlayerLog.ApplicationLog?.logError(title: "[SongEntry].init(songNo:,artist:,albumName:,title:,duration:,url:,genre:,recordingYear:,trackNo:)", text: "url in exclusion path:\(url!.path)}")
            throw SongEntryError.PathInExclusionPath
        }
        
        guard duration > 0 else {
            PlayerLog.ApplicationLog?.logWarning(title: "[SongEntry].init(path:songNo:)", text: "Duration was 0. File: \(url!.path)")
            throw SongEntryError.DurationIsZero
        }
        
        self.songNo = songNo
        self.artist = artist
        self.fullArtist = artist
        self.albumName = albumName
        self.fullAlbumName = albumName
        self.title = title
        self.fullTitle = title
        self.duration = duration
        self.fileURL = url
        self.genre = genre.lowercased()
        self.fullGenre = genre.lowercased()
        self.recordingYear = recordingYear
        self.trackNo = trackNo

    
        self.fullTitle = trimAndSetStringDefaultValue(str: self.title)
        self.title = trimAndSetStringDefaultValueMaxLength(str: self.title)
        
        self.fullAlbumName = trimAndSetStringDefaultValue(str: self.albumName)
        self.albumName = trimAndSetStringDefaultValueMaxLength(str: self.albumName)
        
        //
        // Add to g_genres
        //
        self.fullGenre = trimAndSetStringDefaultValue(str: self.genre)
        self.genre = trimAndSetStringDefaultValueMaxLength(str: self.genre)

        if g_genres[self.genre] == nil {
            g_genres[self.genre] = []
        }
        
        g_genres[self.genre]?.append(self)
        
        //
        // Add to g_artists
        //
        self.fullArtist = trimAndSetStringDefaultValue(str: self.artist)
        self.artist = trimAndSetStringDefaultValueMaxLength(str: self.artist)
        
        if g_artists[self.artist] == nil {
            g_artists[self.artist] = []
        }

        g_artists[self.artist]?.append(self)
        
        //
        // Add to g_releaseYears
        //
        if g_recordingYears[self.recordingYear] == nil {
            g_recordingYears[self.recordingYear] = []
        }
        
        g_recordingYears[self.recordingYear]?.append(self)
    }
    
    ///
    /// Overloaded initializer.
    ///
    /// parameter path: URL file path to song.
    /// parameter num: Song No.
    ///
    init(path: URL?, songNo: Int) throws
    {        
        guard path != nil else {
            PlayerLog.ApplicationLog?.logError(title: "[SongEntry].init(path:,songNo:)", text: "path == nil")
            throw SongEntryError.PathIsNil
        }
        
        guard isPathInMusicRootPath(path: path!.path) else {
            PlayerLog.ApplicationLog?.logError(title: "[SongEntry].init(path:,songNo:)", text: "path not in music root path: \(path!.path)")
            throw SongEntryError.PathNotInMusicRootPath
        }
        
        guard !isPathInExclusionPath(path: path!.path) else {
            PlayerLog.ApplicationLog?.logError(title: "[SongEntry].init(path:,songNo:)", text: "url in exclusion path:\(path!.path)}")
            throw SongEntryError.PathInExclusionPath
        }
        
        self.songNo = songNo
        self.fileURL = path!

        //
        // Only support .mp3 for now.
        //        
        do {
            if path!.path.lowercased().hasSuffix(".mp3") {            
                let metadata = try Mp3AudioPlayer.gatherMetadata(path: path)
                self.title = metadata.title
                self.artist = metadata.artist
                self.albumName = metadata.albumName
                self.recordingYear = metadata.recordingYear
                self.genre = metadata.genre        
            }// is .mp3
            else {
                throw SongEntryError.InvalidSongEntryType
            }   
        } catch {
            PlayerLog.ApplicationLog?.logError(title: "[SongEntry].init(path:,songNo:)", text: "Error gathering metadata from file: \(path!.lastPathComponent). Message: \(error)")
        }
        
        //
        // Add to genre
        //
        self.fullGenre = trimAndSetStringDefaultValue(str: self.genre)
        self.genre = trimAndSetStringDefaultValueMaxLength(str: self.genre)
        if g_genres[self.genre] == nil {
            g_genres[self.genre] = []
        }
        
        g_genres[self.genre]?.append(self)
        
        //
        // Add to g_artists
        //
        self.fullArtist = trimAndSetStringDefaultValue(str: self.artist)
        self.artist = trimAndSetStringDefaultValueMaxLength(str: self.artist)
        if g_artists[self.artist] == nil {
            g_artists[self.artist] = []
        }
    
        g_artists[self.artist]?.append(self)
    
        
        //
        // Add to g_releaseYears
        //
        if g_recordingYears[self.recordingYear] == nil {
            g_recordingYears[self.recordingYear] = []
        }
       
        g_recordingYears[self.recordingYear]?.append(self)
        
        self.fullTitle = trimAndSetStringDefaultValue(str: self.title)
        self.title = trimAndSetStringDefaultValueMaxLength(str: self.title)
        
        self.fullAlbumName = trimAndSetStringDefaultValue(str: self.albumName)
        self.albumName = trimAndSetStringDefaultValueMaxLength(str: self.albumName)
    }
    
    ///
    /// Trims string and sets default value if it is empty
    ///
    func trimAndSetStringDefaultValue(str: String) -> String {
        var s = str.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.count == 0 {
            s = self.unknownMetadataStringValue
        }
        return s
    }
    
    func trimAndSetStringDefaultValueMaxLength(str: String) -> String {
        var s = self.trimAndSetStringDefaultValue(str: str)
        if s.count > self.maxStringLength {
            s = String(s[s.startIndex..<s.index(s.startIndex, offsetBy: self.maxStringLength)])
        }
        return s
    }

    func getArtist() -> String {
        var s = self.trimAndSetStringDefaultValue(str: self.fullArtist)

        let ncalc: Double = Double(g_cols - g_fieldWidthSongNo+1 - g_fieldWidthDuration) / 2.0
        let artistCols: Int = Int(floor(ncalc))
        //let titleCols: Int =  Int(ceil(ncalc))
        let maxStringLength = artistCols - 1

        if s.count > maxStringLength {
            s = String(s[s.startIndex..<s.index(s.startIndex, offsetBy: maxStringLength)])
        }

        return s
    }

    func getAlbumName() -> String {
        var s = self.trimAndSetStringDefaultValue(str: self.fullAlbumName)

        let ncalc: Double = Double(g_cols - g_fieldWidthSongNo+1 - g_fieldWidthDuration) / 2.0
        let artistCols: Int = Int(floor(ncalc))
        //let titleCols: Int =  Int(ceil(ncalc))
        let maxStringLength = artistCols - 1

        if s.count > maxStringLength {
            s = String(s[s.startIndex..<s.index(s.startIndex, offsetBy: maxStringLength)])
        }
        
        return s
    }

    func getTitle() -> String {
        var s = self.trimAndSetStringDefaultValue(str: self.fullTitle)

        let ncalc: Double = Double(g_cols - g_fieldWidthSongNo+1 - g_fieldWidthDuration) / 2.0
        //let artistCols: Int = Int(floor(ncalc))
        let titleCols: Int =  Int(ceil(ncalc))
        let maxStringLength = titleCols - 3
        
        if s.count > maxStringLength {
            s = String(s[s.startIndex..<s.index(s.startIndex, offsetBy: maxStringLength)])
        }
        
        return s
    }

    func getGenre() -> String {
        var s = self.trimAndSetStringDefaultValue(str: self.fullGenre)

        let ncalc: Double = Double(g_cols - g_fieldWidthSongNo+1 - g_fieldWidthDuration) / 2.0
        //let artistCols: Int = Int(floor(ncalc))
        let titleCols: Int =  Int(ceil(ncalc))
        let maxStringLength = titleCols - 3

        if s.count > maxStringLength {
            s = String(s[s.startIndex..<s.index(s.startIndex, offsetBy: maxStringLength)])
        }
        
        return s
    }        
}// SongEntry
