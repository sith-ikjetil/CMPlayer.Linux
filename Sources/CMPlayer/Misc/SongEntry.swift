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
        if path!.path.lowercased().hasSuffix(".mp3") {
            //print("URL: \(self.fileURL!.path)")
            guard let handle = mpg123_new(nil, nil) else {
                PlayerLog.ApplicationLog?.logWarning(title: "[SongEntry].init(path:songNo:)", text: "mpg123_new failed")
                throw SongEntryError.MpgSoundLibrary
            }

            defer {                
                mpg123_close(handle);
            }
            
            guard mpg123_open(handle, self.fileURL!.path) == 0 else {
                PlayerLog.ApplicationLog?.logWarning(title: "[SongEntry].init(path:songNo:)", text: "mpg123_open failed for URL: \(path!.path)")
                throw SongEntryError.MpgSoundLibrary
            }      

            //
            // find duration
            //              
            var length: off_t = 0
            length = mpg123_length(handle)
            if length <= 0 {
                PlayerLog.ApplicationLog?.logWarning(title: "[SongEntry].init(path:songNo:)", text: "mpg123_length failed with value: \(length)")
                throw SongEntryError.MpgSoundLibrary
            }
            
            // Get the rate and channels to calculate duration
            var rate: CLong = 0
            var channels: Int32 = 0
            var encoding: Int32 = 0
            mpg123_getformat(handle, &rate, &channels, &encoding)
            
            // Calculate duration in seconds
            let duration = Double(length) / Double(rate)
            self.duration = UInt64(duration * 1000)

            // Ensure positive duration
            guard duration > 0 else {
                PlayerLog.ApplicationLog?.logWarning(title: "[SongEntry].init(path:songNo:)", text: "Duration was 0. File: \(path!.path)")
                throw SongEntryError.DurationIsZero
            }

            //print("mpg123_metacheck")
            let metaCheck = mpg123_meta_check(handle)
            if metaCheck & MPG123_ID3 != 0 {
                let id3v1Pointer: UnsafeMutablePointer<UnsafeMutablePointer<mpg123_id3v1>?>? = UnsafeMutablePointer.allocate(capacity: 1)
                id3v1Pointer?.initialize(to: nil)
                
                let id3v2Pointer: UnsafeMutablePointer<UnsafeMutablePointer<mpg123_id3v2>?>? = UnsafeMutablePointer.allocate(capacity: 1)
                id3v2Pointer?.initialize(to: nil)
                
                defer {
                    id3v1Pointer?.deallocate()
                    id3v2Pointer?.deallocate()
                }

                // Call the mpg123_id3 function to fill in the pointers
                if mpg123_id3(handle, id3v1Pointer, id3v2Pointer) == 0 {                    
                    if let id3v2 = id3v2Pointer?.pointee?.pointee {
                        // Access ID3v2 metadata fields safely
                        if id3v2.title?.pointee.p != nil {
                            let title = String(cString: id3v2.title.pointee.p)
                            self.title = title
                        }
                        
                        if id3v2.artist?.pointee.p != nil {
                            let artist = String(cString: id3v2.artist.pointee.p)
                            self.artist = artist
                        }
                        
                        if id3v2.album?.pointee.p != nil {
                            let album = String(cString: id3v2.album.pointee.p)
                            self.albumName = album
                        }

                        if id3v2.year?.pointee.p != nil {
                            let year = String(cString: id3v2.year.pointee.p)
                            self.recordingYear = Int(year) ?? -1
                        }

                        if id3v2.genre?.pointee.p != nil {
                            let genre = String(cString: id3v2.genre.pointee.p)
                            self.genre = genre
                        }                                                

                        // Loop through the text fields to find the track number
                        for i in 0..<id3v2.texts {                            
                            let textItem = id3v2.text[i]
                            let text = String(cString: textItem.text.p)
                            let id = "\(Character(UnicodeScalar(UInt32(textItem.id.0))!))\(Character(UnicodeScalar(UInt32(textItem.id.1))!))\(Character(UnicodeScalar(UInt32(textItem.id.2))!))\(Character(UnicodeScalar(UInt32(textItem.id.3))!))"
                            if id == "TRCK" {
                                self.trackNo = Int(text) ?? -1
                            }
                        }                                                
                    } 
                    else if let id3v1 = id3v1Pointer?.pointee?.pointee {
                        // ID3v1 fallback                        
                        let title = String(cString: withUnsafePointer(to: id3v1.title) {
                            UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                        })
                        let artist = String(cString: withUnsafePointer(to: id3v1.artist) {
                            UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                        })
                        let album = String(cString: withUnsafePointer(to: id3v1.album) {
                            UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                        })
                        let year = String(cString: withUnsafePointer(to: id3v1.year) {
                            UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                        })
                        //let comment = String(cString: withUnsafePointer(to: id3v1.comment) {
                        //    UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                        //})
                        let genre = id3v1.genre
                        
                        self.title = title
                        self.artist = artist
                        self.albumName = album
                        self.recordingYear = Int(year) ?? -1
                        self.genre = convertId3V1GenreIndexToName(index: genre)                        
                    } 
                    else {
                        throw SongEntryError.MetadataNotFound
                    }
                } 
                else {
                    throw SongEntryError.MpgSoundLibrary
                }                
            }// mpg123_meta_check                                    
        }// is .mp3
        else {
            throw SongEntryError.InvalidSongEntryType
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
