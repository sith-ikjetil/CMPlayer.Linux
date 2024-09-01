//
//  SongEntry.swift
//
//  (i): A class that represents a song.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
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
    // variables
    //    
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
    ///
    /// constants
    /// 
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
            let msg = "[SongEntry].init(...). path == nil"
            throw CmpError(message: msg)
        }
        
        guard isPathInMusicRootPath(path: url!.path) else {
            let msg = "[SongEntry].init(...). url not in music root path:\(url!.path)"
            throw CmpError(message: msg)            
        }
        
        guard !isPathInExclusionPath(path: url!.path) else {
            let msg = "[SongEntry].init(...). url in exclusion path:\(url!.path)"
            throw CmpError(message: msg)
        }
        
        guard duration > 0 else {
            let msg = "[SongEntry].init(...). Duration invalid with value: \(duration)"            
            throw CmpError(message: msg)
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
        
        self.fullGenre = trimAndSetStringDefaultValue(str: self.genre)
        self.genre = trimAndSetStringDefaultValueMaxLength(str: self.genre)        

        self.fullArtist = trimAndSetStringDefaultValue(str: self.artist)
        self.artist = trimAndSetStringDefaultValueMaxLength(str: self.artist)
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
            let msg = "[SongEntry].init(path,songNo). path == nil"
            throw CmpError(message: msg)
        }
        
        guard isPathInMusicRootPath(path: path!.path) else {
            let msg = "[SongEntry].init(path,songNo). url not in music root path:\(path!.path)"
            throw CmpError(message: msg)            
        }
        
        guard !isPathInExclusionPath(path: path!.path) else {
            let msg = "[SongEntry].init(path,songNo). url in exclusion path:\(path!.path)"
            throw CmpError(message: msg)
        }
                
        self.songNo = songNo
        self.fileURL = path!

        //
        // Only support .mp3 for now.
        //        
        do {
            if path!.path.lowercased().hasSuffix(".mp3") || path!.path.lowercased().hasSuffix(".m4a") {            
                let metadata = try CmpAudioPlayer.gatherMetadata(path: path!)                
                self.title = metadata.title
                self.artist = metadata.artist
                self.albumName = metadata.albumName
                self.recordingYear = metadata.recordingYear
                self.genre = metadata.genre.lowercased()
                self.duration = metadata.duration    
                self.trackNo = metadata.trackNo    

                if self.duration == 0 {
                    let msg = "[SongEntry].init(path,songNo). Duration from CmpAudioPlayer.gatherMetadata was 0."
                    throw CmpError(message: msg)
                }
            }// is .mp3
            else {
                let msg = "[SongEntry].init(path,songNo). Unsupported extension from file: \(path!.lastPathComponent)"
                throw CmpError(message: msg)
            }   
        } catch let error as CmpError {
            let msg = "Error gathering metadata from file: \(path!.path).\nMessage: \(error.message)"
            PlayerLog.ApplicationLog?.logError(title: "[SongEntry].init(path,songNo)", text: msg)
            throw error
        } catch {
            let msg = "Unknown error gathering metadata from file: \(path!.path).\nMessage: \(error)"
            PlayerLog.ApplicationLog?.logError(title: "[SongEntry].init(path,songNo)", text: msg)
            throw error
        }
        
        self.fullGenre = trimAndSetStringDefaultValue(str: self.genre)
        self.genre = trimAndSetStringDefaultValueMaxLength(str: self.genre)

        self.fullArtist = trimAndSetStringDefaultValue(str: self.artist)
        self.artist = trimAndSetStringDefaultValueMaxLength(str: self.artist)
      
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
            s = g_metadataNotFoundName
        }
        return s
    }
    /// 
    /// Trims string and sets default value if it is empty, then if 
    /// length of string is longer than self.maxStringLength it crops 
    /// the length to this length.
    /// 
    func trimAndSetStringDefaultValueMaxLength(str: String) -> String {
        var s = self.trimAndSetStringDefaultValue(str: str)
        if s.count > self.maxStringLength {
            s = String(s[s.startIndex..<s.index(s.startIndex, offsetBy: self.maxStringLength)])
        }
        return s
    }
    ///
    /// Gets the artist with width set by widt of field on screen.
    ///
    func getArtist() -> String {
        var s = self.trimAndSetStringDefaultValue(str: self.fullArtist)

        let layout: MainWindowLayout = MainWindowLayout.get()        
        let maxStringLength = layout.artistCols - 1

        if s.count > maxStringLength {
            s = String(s[s.startIndex..<s.index(s.startIndex, offsetBy: maxStringLength)])
        }

        return s
    }
    ///
    /// Gets the albumName with width set by widt of field on screen.
    ///
    func getAlbumName() -> String {
        var s = self.trimAndSetStringDefaultValue(str: self.fullAlbumName)

        let layout: MainWindowLayout = MainWindowLayout.get()        
        let maxStringLength = layout.artistCols - 1

        if s.count > maxStringLength {
            s = String(s[s.startIndex..<s.index(s.startIndex, offsetBy: maxStringLength)])
        }
        
        return s
    }
    ///
    /// Gets the title with width set by widt of field on screen.
    ///
    func getTitle() -> String {
        var s = self.trimAndSetStringDefaultValue(str: self.fullTitle)

        let layout: MainWindowLayout = MainWindowLayout.get()                        
        let maxStringLength = layout.titleCols - 1
        
        if s.count > maxStringLength {
            s = String(s[s.startIndex..<s.index(s.startIndex, offsetBy: maxStringLength)])
        }
        
        return s
    }
    ///
    /// Gets the genre with width set by widt of field on screen.
    ///
    func getGenre() -> String {
        var s = self.trimAndSetStringDefaultValue(str: self.fullGenre)

        let layout: MainWindowLayout = MainWindowLayout.get()                        
        let maxStringLength = layout.titleCols - 1

        if s.count > maxStringLength {
            s = String(s[s.startIndex..<s.index(s.startIndex, offsetBy: maxStringLength)])
        }
        
        return s
    }        
}// SongEntry
