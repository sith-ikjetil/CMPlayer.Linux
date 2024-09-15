//
//  InitializeWindow.swift
//
//  (i): Finds all available and supported songs and gathers 
//       metadata.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
//
// import
//
import Foundation
///
/// Represents CMPlayer HelpWindow.
///
internal class InitializeWindow : TerminalSizeHasChangedProtocol, PlayerWindowProtocol {
    //
    // private variables
    //
    private var backup: PlayerLibrary? = nil        // backup library
    private var filesFoundCompleted: Int = 0        // percent found files
    private var libraryLoadedCompleted: Int = 0     // percent library loaded
    private var isFinished: Bool = false            // are we finished
    private var currentPath: String = ""            // current path we are looking for files in
    private var musicFormats: [String] = []         // music formats supported
    private var countFindSongs: Int = 0             // number of files found
    private var countFoundMetadata: Int = 0         // number of files metadata has been gathered
    ///
    /// private constants
    /// 
    private let concurrentQueue1 = DispatchQueue(label: "cqueue.cmplayer.linux.Initialize", attributes: .concurrent)
    ///
    /// default initializer
    ///
    init() {
        
    }
    ///
    /// overriden initializer
    /// - for use with reinitialize command
    /// - ensure same song no for existing song
    /// - just add new ones
    /// - faster loading
    ///
    init(backup: PlayerLibrary) {
        // set backup library        
        self.backup = backup        
        g_library.setNextAvailableSongNo(max(g_library.nextAvailableSongNo(),self.backup!.nextAvailableSongNo()))
    }    
    /// Shows this HelpWindow on screen.
    ///
    /// parameter song: Instance of SongEntry to render info.
    ///
    func showWindow() -> Void {
        // add to top this window to terminal size change protocol stack
        g_tscpStack.append(self)
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // render this window
        self.renderWindow()
        // run async
        concurrentQueue1.async {            
            // perform work (initialization)
            self.initialize()
            // set isFinished flag to true (this will end run())
            self.isFinished = true
        }
        // run(), modal call
        self.run()
        // remove from top this window from terminal size change protocol stack
        g_tscpStack.removeLast()
    }
    /// 
    /// Finds all songs and appends them to g_songs and initializes g_playlist.
    ///     
    func initialize() -> Void {
        // remove all songs in g_songs
        g_songs.removeAll()       
        // remove all songs from g_playlist
        g_playlist.removeAll()       
        // get music formats supported
        self.musicFormats = PlayerPreferences.musicFormats.components(separatedBy: ";")
        // for each music root path
        for mrpath in PlayerPreferences.musicRootPath {            
            // files found completed at 0%
            self.filesFoundCompleted = 0              
            // find all songs (files) and return path string array              
            let result = findSongs(path: mrpath)            
            // files found completed at 100%
            self.filesFoundCompleted = 100        
            // set current path to current music root path
            self.currentPath = mrpath
            // set library loaded completed to 0%
            self.libraryLoadedCompleted = 0
            // create variable i that keeps tab on file number
            var i: Int = 1
            // loop through all songs (file paths)
            for r in result {
                // set currentPath = current music root path
                self.currentPath = mrpath
                // set libraryLoadedCompleted % completion of loading of library
                self.libraryLoadedCompleted = Int(Double(i) * Double(100.0) / Double(result.count))
                // create constant u of type URL for current file (song)
                let u: URL = URL(fileURLWithPath: r)
                // if we have the song in library
                if let se = g_library.find(url: u) {                    
                    // yes, then just append the SongEntry from library
                    g_songs.append(se)                      
                }
                // check backup library
                else if let se = backup?.find(url: u) {
                    // yes, then just append the SongEntry from backup library
                    g_songs.append(se)                                        
                }
                // no this is a new file (song)
                else {
                    // create a constant of next available song no.
                    let nasno = g_library.nextAvailableSongNo()
                    do {
                        // Attempt to create a song entry object
                        // gathers metadata
                        let songEntry = try SongEntry(path: URL(fileURLWithPath: r),songNo: nasno)
                        // increase countFoundMetadata by 1. number of files metadata gathered
                        self.countFoundMetadata += 1
                        // add to g_songs
                        g_songs.append(songEntry)                        
                    }
                    // a known error occured
                    catch _ as CmpError {
                        // set next available song no
                        g_library.setNextAvailableSongNo(nasno)
                    }
                    // an unknown error occurred
                    catch  {
                        // set next availble song no
                        g_library.setNextAvailableSongNo(nasno)
                    }
                }
                // increase file (song) number by 1
                i += 1
            }
        }
        // if we have found even a single song
        if g_songs.count > 0 {
            // create a constant r1 with random SongEntry
            let r1 = g_songs.randomElement()
            // create a constant r2 with random SongEntry
            let r2 = g_songs.randomElement()
            // append r1
            g_playlist.append(r1!)
            // append r2
            g_playlist.append(r2!)
        }
    }    
    ///
    /// Finds all songs from path and all folder paths under path. Songs must be 
    /// of format in PlayerPreferences.musicFormats.
    ///
    /// parameter path: The root path to start finding supported audio files.
    /// returns: [String]. Array of file paths to audio files found.
    ///
    func findSongs(path: String) -> [String]
    {
        // set return variable, array of strings (filepaths)
        var results: [String] = []
        // if path is not in music root path or is in exclution path
        if !isPathInMusicRootPath(path: path) || isPathInExclusionPath(path: path) {            
            // return results (empty)
            return results
        }
        
        do
        {
            // gather all files and directories in path
            let result = try FileManager.default.contentsOfDirectory(atPath: path)
            // loop through all elements in path
            for r in result {
                // create a String variable of path and filename
                var nr = "\(path)/\(r)"
                if path.hasSuffix("/") {
                    nr = "\(path)\(r)"
                }                
                // set currentPath to nr
                self.currentPath = nr
                // if nr is a directory
                if isDirectory(path: nr) {                    
                    // add to results the return value of findSongs nr as path (recursion)
                    results.append(contentsOf: findSongs(path: nr))
                }
                // nr is a file
                else {         
                    // can we read from the file           
                    if FileManager.default.isReadableFile(atPath: nr) {
                        // loop through all music format supported
                        for f in self.musicFormats {                            
                            // is the file a supported music format
                            if r.hasSuffix(f) {                             
                                // yes, increase countFindSongs (number of found songs)
                                self.countFindSongs += 1 // count variable
                                // add song (file+path) to results
                                results.append(nr)                
                                // discontinue for-loop 
                                break
                            }                            
                        }
                    }            
                }
            }
        }
        catch {
            // remove all items from results
            results.removeAll()
        }
        
        return results
    }    
    ///
    /// Determines if a path is a directory or not.
    ///
    /// parameter path. Path to check.
    ///
    /// returns: Bool. True if path is directory. False otherwise.
    ///
    func isDirectory(path: String) -> Bool {
        // set up variable isDirectory
        var isDirectory: ObjCBool = false
        // if file exists
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
            // return if this is a directory or not
            return isDirectory.boolValue;
        }
        // if file does not exist, return false
        return false;
    }// isDirectory    
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
        // render header
        MainWindow.renderHeader(showTime: false)
        // get bg color from current theme
        let bgColor: ConsoleColor = ConsoleColor.black
        // render title
        Console.printXY(1,3,":: INITIALIZE ::", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.yellow, ConsoleColorModifier.bold)
        // render current path
        Console.printXY(1, 5, "Current Path: " + self.currentPath, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // create a string variable for holding files found
        var pstFiles: String = "\(self.filesFoundCompleted)"
        // if we have found at least one song
        if self.countFindSongs > 0 {
            // append files found
            pstFiles += " (\(self.countFindSongs) files found)"
        } 
        // render song files found
        Console.printXY(1, 6, "Finding Song Files: " + pstFiles, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // create a string variable for hold metadata gathered from files
        var pstLib: String = "\(self.libraryLoadedCompleted)%"
        // if we have found at least 1 metadata file
        if self.countFoundMetadata > 0 {
            // append metadata from countFoundMetadata files
            pstLib += " (gathered metadata from \(self.countFoundMetadata) files)"
        } 
        // render song library update
        Console.printXY(1, 7, "Updating Song Library: " + pstLib, g_cols, .left, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // render status line
        Console.printXY(1,g_rows-1,"PLEASE BE PATIENT", g_cols, .center, " ", bgColor, ConsoleColorModifier.none, ConsoleColor.white, ConsoleColorModifier.bold)
        // goto g_cols,1
        Console.gotoXY(g_cols,1)
        // print nothing
        print("")
    }    
    ///
    /// Runs HelpWindow keyboard input and feedback.
    ///
    func run() -> Void {
        // clear screen current theme
        Console.clearScreenCurrentTheme()
        // loop while we are not finished
        while !self.isFinished {
            // if we can paint
            if !g_doNotPaint {
                // render window
                self.renderWindow()
            }    
            // sleep 100 ms
            usleep(100_000)
        }
    }// run
}// InitializeWindow
