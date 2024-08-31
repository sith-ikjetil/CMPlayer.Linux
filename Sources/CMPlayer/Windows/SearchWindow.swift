//
//  SearchWindow.swift
//
//  (i): Renders search result to screen.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import
//
import Foundation
///
/// Represents CMPlayer SearchWindow.
///
internal class SearchWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    //
    // private variables
    //
    private var searchIndex: Int = 0        // index into searchResult
    private var partsYear: [String] = []    // years
    private var modeOff: Bool = false       // are we not in a mode
    //
    // variables
    //
    var searchResult: [SongEntry] = []      // search result
    var stats: [Int] = []                   // search result stats
    var parts: [String] = []                // search terms
    var type: SearchType = SearchType.ArtistOrTitle   // search type (default ArtistOrTitle)   
    ///
    /// TerminalSizeChangedProtocol method
    ///
    func terminalSizeHasChanged() -> Void {
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
    }    
    ///
    /// Perform narrow search from arguments.
    ///
    func performNarrowSearch(terms: [String], type: SearchType) -> Void {        
        // clear self.searchResult
        self.searchResult.removeAll(keepingCapacity: false)
        // clear partsYear
        self.partsYear.removeAll()
        // clear stats
        self.stats.removeAll()
        // loop through all terms
        for _ in 0..<terms.count {
            // append stat, default to 0
            self.stats.append(0)
        }
        // if search type is genre
        if type == SearchType.Genre {
            // create an index variable set to 0
            var index: Int = 0
            // for each search term in terms
            for name in terms {
                // lowercase the term
                let name = name.lowercased()
                // loop through all songs in g_searchResult
                for s in g_searchResult {
                    // if we find a match for genre
                    if s.genre == name {
                        // append song to searchResult
                        self.searchResult.append(s)
                        // update stats
                        self.stats[index] += 1
                    }
                }
                index += 1
            }
        }
        // else if search type is recorded year
        else if type == SearchType.RecordedYear {
            // get current year as a constant
            let currentYear = Calendar.current.component(.year, from: Date()) + 1
            // create an index variable
            var index: Int = 0
            // for each year in terms
            for year in terms {
                // try to split the term in case year is written as "2010-2020"
                let yearsSubs = year.split(separator: "-")
                // keeper of years variable
                var years: [String] = []
                // for each year in yearsSubs
                for ys in yearsSubs {
                    // append year to years
                    years.append(String(ys))
                }
                // if years count is 1
                if years.count == 1 {
                    // convert year to Int
                    let resultYear = Int(years[0]) ?? -1
                    // if resultYear is valid
                    if resultYear >= 0 && resultYear <= currentYear {
                        // for each SongEntry in g_searchResult
                        for s in g_searchResult {
                            // if found
                            if s.recordingYear == resultYear {
                                // add song to self.searchResult
                                self.searchResult.append(s)
                                // update stats
                                self.stats[index] += 1
                            }
                        }
                        // append year to partsYear
                        self.partsYear.append(String(resultYear))
                    }
                    // increment index
                    index += 1
                }
                else if years.count == 2 {
                    // create constant year from
                    let from: Int = Int(years[0]) ?? -1
                    // create constant year to
                    let to: Int = Int(years[1]) ?? -1
                    // if to year is less than or equal to current year
                    if to <= currentYear {
                        // if years (from, to) are valid
                        if from != -1 && to != -1 && from <= to {
                            // create a constant from year + 1
                            let xfrom: Int = from + 1
                            // loop through xfrom -> to
                            for _ in xfrom...to {
                                // append 0 to stats
                                self.stats.append(0)
                            }
                            // loop through years from -> to
                            for y in from...to {
                                // loop through all SongEntry in g_searchResult
                                for s in g_searchResult {
                                    // if found
                                    if s.recordingYear == y {
                                        // add song to self.searchResult
                                        self.searchResult.append(s)
                                        // update stats
                                        self.stats[index] += 1
                                    }
                                }
                                // increment index
                                index += 1
                                // append year to partsYear
                                self.partsYear.append(String(y))
                            }
                        }
                    }
                }
            }
        }
        // else 
        else {
            // loop through entire g_searchResult
            for se in g_searchResult {
                // create constant artist and get artist lowercased
                let artist = se.artist.lowercased()
                // create constant title and get title lowercased
                let title = se.title.lowercased()
                // create constant album and get album lowercased
                let album = se.albumName.lowercased()
                // create an index variable
                var index: Int = 0
                // loop through each search term                
                for t in terms {
                    // create a constant term which is the term t lowercased
                    let term = t.lowercased()
                    // if search type is artist or title                    
                    if type == SearchType.ArtistOrTitle {
                        // if artist or title contains term
                        if artist.contains(term) || title.contains(term) {
                            // yes, append song to searchResult
                            self.searchResult.append(se)
                            // increment stats with 1
                            self.stats[index] += 1
                            // discontinue loop
                            break
                        }
                    }
                    // else if search type is artist
                    else if type == SearchType.Artist {
                        // if artist contains term
                        if artist.contains(term) {
                           // yes, append song to searchResult
                            self.searchResult.append(se)
                            // increment stats with 1
                            self.stats[index] += 1
                            // discontinue loop
                            break
                        }
                    }
                    // else if search type is title
                    else if type == SearchType.Title {
                        // if title contains term
                        if title.contains(term) {
                            // yes, append song to searchResult
                            self.searchResult.append(se)
                            // increment stats with 1
                            self.stats[index] += 1
                            // discontinue loop
                            break
                        }
                    }
                    // else if search type is album
                    else if type == SearchType.Album {
                        // if album contains term
                        if album.contains(term) {
                            // yes, append song to searchResult
                            self.searchResult.append(se)
                            // increment stats with 1
                            self.stats[index] += 1
                            // discontinue loop
                            break
                        }
                    }
                    // increment index
                    index += 1
                }
            }
        }
        // sort serachResult
        self.searchResult = self.searchResult.sorted {sortSongEntry(se1: $0, se2: $1)} // $0.artist < $1.artist }
    }    
    ///
    /// Performs search from arguments. Searches g_songs.
    ///
    /// parameter terms: Array of search terms.
    ///
    func performSearch(terms: [String], type: SearchType) -> Void {
        // loop and find if we are in a mode of same type as type
        for t in g_searchType {
            // type is the same
            if t == type {
                // set modOff flag to true
                modeOff = true
                // discontinue loop
                break;
            }
        }
        // if we have a mode and global serach result has items
        if !modeOff && g_searchResult.count > 0 {
            // perform a narrowing search
            performNarrowSearch(terms: terms, type: type)
            // return
            return
        }
        // we are not in a mode, like a first search
        // clear searchResult
        self.searchResult.removeAll(keepingCapacity: false)
        // clear partsYear
        self.partsYear.removeAll()
        // clear stats
        self.stats.removeAll()
        // for every item in terms (search parameters)
        for _ in 0..<terms.count {
            // append 0 to stats (number of items found for that search parameter)
            // - initialized stats to 0
            self.stats.append(0)
        }
        // if search type is genre
        if type == SearchType.Genre {
            // create an index variable set to 0
            var index: Int = 0
            // for each search term in terms
            for name in terms {
                // lowercase the term
                let name = name.lowercased()                
                // try lookup the genre from g_genres
                if let genre = g_genres[name] {                                        
                    // we found it, does it have a count of at least 1
                    if genre.count >= 1 {
                        // yes append SongEntries for that genre to searchResult
                        self.searchResult.append(contentsOf: genre)
                        // add to search term the count of genres
                        self.stats[index] += genre.count
                    }
                }
                // increment index
                index += 1
            }            
        }
        // else if search type is recorded year
        else if type == SearchType.RecordedYear {
            // get current year as a constant
            let currentYear = Calendar.current.component(.year, from: Date()) + 1
            // create an index variable
            var index: Int = 0
            // for each year in terms
            for year in terms {
                // try to split the term in case year is written as "2010-2020"
                let yearsSubs = year.split(separator: "-")
                // keeper of years variable
                var years: [String] = []
                // for each year in yearsSubs
                for ys in yearsSubs {
                    // append year to years
                    years.append(String(ys))
                }
                // if years count is 1
                if years.count == 1 {
                    // convert year to Int
                    let resultYear = Int(years[0]) ?? -1
                    // if resultYear is valid
                    if resultYear >= 0 && resultYear <= currentYear {
                        // try to find item in g_recordingYears
                        if g_recordingYears[resultYear] != nil {
                            // we found it, check for count at least 1
                            if g_recordingYears[resultYear]!.count >= 1 {
                                // we have items in g_recordingYears for resultYear
                                // - append items to searchResult
                                self.searchResult.append(contentsOf: g_recordingYears[resultYear]!)
                                // append resultYear to partsYear
                                self.partsYear.append(String(resultYear))
                                // increments stats[index] with count
                                self.stats[index] += g_recordingYears[resultYear]!.count
                            }
                        }
                    }
                    // increment index
                    index += 1
                }
                // else years count is 2
                else if years.count == 2 {
                    // create constant year from
                    let from: Int = Int(years[0]) ?? -1
                    // create constant year to
                    let to: Int = Int(years[1]) ?? -1
                    // if to year is less than or equal to current year
                    if to <= currentYear {
                        // if years (from, to) are valid
                        if from != -1 && to != -1 && from <= to {
                            // create a constant from year + 1
                            let xfrom: Int = from + 1
                            // loop through xfrom -> to
                            for _ in xfrom...to {
                                // append 0 to stats
                                self.stats.append(0)
                            }
                            // loop through years from -> to
                            for y in from...to {
                                // if we have SongEntries for year y in g_recordingYears
                                if g_recordingYears[y] != nil {
                                    // yes, and do we have count of at least 1
                                    if g_recordingYears[y]!.count >= 1 {
                                        // add g_recordingYears[y] to searchResult
                                        self.searchResult.append(contentsOf: g_recordingYears[y]!)
                                        // add year to partsYear
                                        self.partsYear.append(String(y))
                                        // update stat to items count for year y
                                        self.stats[index] += g_recordingYears[y]!.count
                                        // increment index
                                        index += 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // else 
        else {
            // loop through entire g_songs
            for se in g_songs {
                // create constant artist and get artist lowercased
                let artist = se.artist.lowercased()
                // create constant title and get title lowercased
                let title = se.title.lowercased()
                // create constant album and get album lowercased
                let album = se.albumName.lowercased()
                // create an index variable
                var index: Int = 0
                // loop through each search term
                for t in terms {
                    // create a constant term which is the term t lowercased
                    let term = t.lowercased()
                    // if search type is artist or title
                    if type == SearchType.ArtistOrTitle {
                        // if artist or title contains term
                        if artist.contains(term) || title.contains(term) {
                            // yes, append song to searchResult
                            self.searchResult.append(se)
                            // increment stats with 1
                            self.stats[index] += 1
                            // discontinue loop
                            break
                        }
                    }
                    // else if search type is artist
                    else if type == SearchType.Artist {
                        // if artist contains term
                        if artist.contains(term) {
                            // yes, append song to searchResult
                            self.searchResult.append(se)
                            // increment stats with 1
                            self.stats[index] += 1
                            // discontinue loop
                            break
                        }
                    }
                    // else if search type is title
                    else if type == SearchType.Title {
                        // if title contains term
                        if title.contains(term) {
                            // yes, append song to searchResult
                            self.searchResult.append(se)
                            // increment stats with 1
                            self.stats[index] += 1
                            // discontinue loop
                            break
                        }
                    }
                    // else if search type is album
                    else if type == SearchType.Album {
                        // if album contains term
                        if album.contains(term) {
                            // yes, append song to searchResult
                            self.searchResult.append(se)
                            // increment stats with 1
                            self.stats[index] += 1
                            // discontinue loop
                            break
                        }
                    }
                    // increment index
                    index += 1
                }
            }
        }
        // sort serachResult
        self.searchResult = self.searchResult.sorted {sortSongEntry(se1: $0, se2: $1)} // $0.artist < $1.artist }
    }    
    ///
    /// Shows this SearchWindow on screen.
    ///
    func showWindow() -> Void {
        // add to top this window to terminal size change protocol stack
        g_tscpStack.append(self)
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // run(), modal call
        self.run()
        // remove from top this window from terminal size change protocol stack
        g_tscpStack.removeLast()
    }    
    ///
    /// Renders screen output. Does clear screen first.
    ///
    func renderWindow() -> Void {
        // guard window size is valid
        guard isWindowSizeValid() else {
            // else write terminal too small message
            renderTerminalTooSmallMessage()
            // return
            return
        }
        // clear screen current theme
        Console.clearScreenCurrentTheme()                
        // render header
        MainWindow.renderHeader(showTime: false)
        // get bg color from current theme
        let bgColor = getThemeBgColor()
        // render title
        Console.printXY(1,3,":: SEARCH RESULT ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        // if view type is default
        if PlayerPreferences.viewType == ViewType.Default {
            // get main window layout
            let layout: MainWindowLayout = MainWindowLayout.get()
            // line index on screen. start at 5
            var index_screen_lines: Int = 5
            // index into searchResult
            var index_search: Int = self.searchIndex
            // max index_search
            let max = self.searchResult.count
            // loop while index_search is less than max but...
            while index_search < max {
                // if index_screen_lines is reaching forbidden area on screen
                if index_screen_lines >= (g_rows-3) {
                    // discontinue loop
                    break
                }
                // if index_search has reached searchResult count
                if index_search >= self.searchResult.count {
                    // discontinue loop
                    break
                }
                // set se to searchResults current SongEntry
                let se = self.searchResult[index_search]
                // render song no
                Console.printXY(layout.songNoX, index_screen_lines, "\(se.songNo) ", layout.songNoCols, .right, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
                // render artist
                Console.printXY(layout.artistX, index_screen_lines, se.getArtist(), layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                // render title
                Console.printXY(layout.titleX, index_screen_lines, se.getTitle(), layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                // render duration
                Console.printXY(layout.durationX, index_screen_lines, itsRenderMsToFullString(se.duration, false), layout.durationCols, .ignore, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                // increase index_screen_lines by 1 for next round of loop
                index_screen_lines += 1
                // increase index_search by 1 for next round of loop
                index_search += 1
            }
        }
        // else if view type is details
        else if PlayerPreferences.viewType == ViewType.Details {
            // get main window layout
            let layout: MainWindowLayout = MainWindowLayout.get()
            // line index on screen. start at 5
            var index_screen_lines: Int = 5
            // index into searchResult
            var index_search: Int = self.searchIndex
            // max index_search
            let max = self.searchResult.count
            // loop while index_search is less than max but...
            while index_search < max {
                // if index_screen_lines is reaching forbidden area on screen
                if index_screen_lines >= (g_rows-3) {
                    // discontinue loop
                    break
                }
                // if index_search has reached searchResult count
                if index_search >= self.searchResult.count {
                    // discontinue loop
                    break
                }
                // set se to searchResults current SongEntry
                let song = self.searchResult[index_search]
                // render song no
                Console.printXY(1, index_screen_lines, "\(song.songNo) ", layout.songNoCols, .right, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.cyan, ConsoleColorModifier.bold)
                Console.printXY(1, index_screen_lines+1, " ", layout.songNoCols, .right, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)                                
                // render artist/albumName
                Console.printXY(layout.artistX, index_screen_lines, song.getArtist(), layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                Console.printXY(layout.artistX, index_screen_lines+1, song.getAlbumName(), layout.artistCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                // render title/genre
                Console.printXY(layout.titleX, index_screen_lines, song.getTitle(), layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                Console.printXY(layout.titleX, index_screen_lines+1, song.getGenre(), layout.titleCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                // create constant with value of duration as time string
                let timeString: String = itsRenderMsToFullString(song.duration, false)
                // create a constant with only the last part of timeString
                let endTimePart: String = String(timeString[timeString.index(timeString.endIndex, offsetBy: -5)..<timeString.endIndex])
                // render duration using endTimePart
                Console.printXY(layout.durationX, index_screen_lines, endTimePart, layout.durationCols, .ignore, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                Console.printXY(layout.durationX, index_screen_lines+1, " ", layout.durationCols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
                // increase index_screen_lines by 2 for next round of loop
                index_screen_lines += 2
                // increase index_search by 1 for next round of loop
                index_search += 1
            }
        }
        // render forbidden area
        // if we have a search result
        if self.searchResult.count > 0 {
            // render information - mode then exit
            Console.printXY(1,g_rows-1,"PRESS 'SPACEBAR' TO SET MODE. PRESS ANY OTHER KEY TO EXIT", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        }
        else {
            // render information - no mode just exit
            Console.printXY(1,g_rows-1,"PRESS ANY KEY TO EXIT", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        }
        // render status line
        Console.printXY(1,g_rows,"\(self.searchResult.count.itsToString()) Songs", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // goto g_cols, 1
        Console.gotoXY(g_cols,1)
        // print nothing
        print("")
    }        
    ///
    /// Runs this window keyboard input and feedback.
    ///
    /// parameter parts: command parts from search input command.
    ///
    func run() -> Void {
        // set serachIndex to 0
        self.searchIndex = 0
        // do search
        self.performSearch(terms: self.parts, type: self.type)
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // create a ConsoleKeyboardHandler constant
        let keyHandler: ConsoleKeyboardHandler = ConsoleKeyboardHandler()
        // add key handler for key down (move down one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_DOWN.rawValue, closure: { () -> Bool in 
            // if viewtype is default
            if PlayerPreferences.viewType == ViewType.Default {                       
                // if searchIndex + page size < searchResult count
                if (self.searchIndex+(g_rows-7)) < self.searchResult.count {
                    // saftley increment searchIndex (move down one line)
                    self.searchIndex += 1
                    // render window
                    self.renderWindow()
                }
            }
            // else if viewtype is details
            else if PlayerPreferences.viewType == ViewType.Details {
                // if searchIndex + page size < searchResult count
                if (self.searchIndex+((g_rows-7)/2)) < self.searchResult.count {
                    // saftley increment searchIndex (move down one line)
                    self.searchIndex += 1
                    // render window
                    self.renderWindow()
                }                
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key up (move up one line)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_UP.rawValue, closure: { () -> Bool in
            // if searchIndex is at least 1
            if self.searchIndex >= 1 {
                // saftley decrement searchIndex by 1 (move up one line)
                self.searchIndex -= 1
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key left (move up one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_LEFT.rawValue, closure: { () -> Bool in  
            // if viewtype is default
            if PlayerPreferences.viewType == ViewType.Default {
                // if searchIndex is >= page size
                if self.searchIndex >= (g_rows-7-1) {
                    // saftley decrement by one page size
                    self.searchIndex -= (g_rows-7) - 1                   
                }
                // else we are first page
                else {
                    // set searchIndex to start = 0
                    self.searchIndex = 0                    
                }
                // render window   
                self.renderWindow()     
            }
            // else if viewtype is details
            else if PlayerPreferences.viewType == ViewType.Details {          
                // if searchIndex is >= page size
                if self.searchIndex >= ((g_rows-7)/2) {
                    // saftley decrement by one page size
                    self.searchIndex -= ((g_rows-7)/2)                    
                }
                // else we are first page
                else {
                    // set searchIndex to start = 0
                    self.searchIndex = 0                    
                }
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for key right (move down one page)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_RIGHT.rawValue, closure: { () -> Bool in            
            // if viewtype is default
            if PlayerPreferences.viewType == ViewType.Default {
                // if searchResult count is > than page size
                 if self.searchIndex >= 0 && self.searchResult.count > (g_rows-7) {
                    // if searchIndex + page size < searchResult count - page size (are we not at last page)
                    if self.searchIndex + (g_rows-7) < self.searchResult.count - (g_rows-7) {
                        // increment searchIndex by a page (move down one page)
                        self.searchIndex += (g_rows-7) - 1
                    }
                    // else at last page
                    else {
                        // set searchIndex to last page
                        self.searchIndex = self.searchResult.count - (g_rows-7) + 1
                        // should searchIndex be negative
                        if (self.searchIndex < 0) {
                            // set searchIndex to start = 0
                            self.searchIndex = 0
                        }
                    }                    
                }
                // render window
                self.renderWindow()                
            }
            // else if viewtype is details
            else if PlayerPreferences.viewType == ViewType.Details {
                // if searchResult count > page size
                if self.searchIndex >= 0 && self.searchResult.count > (g_rows-7) {
                    // if searchIndex + page size < searchResult count - page size (are we not at last page)
                    if self.searchIndex + ((g_rows-7)/2) < (self.searchResult.count - ((g_rows-7)/2)) {
                        // increment searchIndex by a page (move down one page)
                        self.searchIndex += ((g_rows-7)/2) 
                    }
                    // else at last page
                    else {
                        // set searchIndex to last page
                        self.searchIndex = (self.searchResult.count) - ((g_rows-7)/2)
                        // should searchIndex be negative
                        if (self.searchIndex < 0) {
                            // set searchIndex to start = 0
                            self.searchIndex = 0
                        }
                    }                    
                }
                // render window
                self.renderWindow()
            }
            // do not return from keyHandler.run()
            return false
        })
        // add key handler for spacebar (set mode and exit screen back to mainwindow)
        keyHandler.addKeyHandler(key: ConsoleKey.KEY_SPACEBAR.rawValue, closure: { () -> Bool in
            // if we have a search result
            if self.searchResult.count > 0 {
                // if we are not in a mode
                if self.modeOff {
                    // lock
                    g_lock.lock()
                    // clear g_searchType
                    g_searchType.removeAll()
                    // clear g_searchResult
                    g_searchResult.removeAll()
                    // clear g_search
                    g_modeSearch.removeAll()
                    // clear g_searchStats
                    g_modeSearchStats.removeAll()
                    // unlock
                    g_lock.unlock()
                }
                // if search type = artist/title/albumName                
                if  self.type == SearchType.ArtistOrTitle ||
                    self.type == SearchType.Artist ||
                    self.type == SearchType.Title ||
                    self.type == SearchType.Album
                {
                    // append result from search
                    g_modeSearch.append(self.parts)
                }
                // else if search type = genre
                else if self.type == SearchType.Genre {
                    // append result from search
                    g_modeSearch.append(self.parts)
                }
                // else if search type = recorded year
                else if self.type == SearchType.RecordedYear {
                    // append result from search
                    g_modeSearch.append(self.partsYear)
                }
                // set global search result to self search result
                g_searchResult = self.searchResult
                // set global search stats to self search stats
                g_modeSearchStats.append(self.stats)
                // set global search type to self search type
                g_searchType.append(self.type)
            }
            // return from run()
            return true
        })
        // add key handler for unknown key handler
        keyHandler.addUnknownKeyHandler(closure: { (key: UInt32) -> Bool in
            // return from run()
            return true
        })
        // execute run(), modal call
        keyHandler.run()
    }// run
}// SearchWindow
