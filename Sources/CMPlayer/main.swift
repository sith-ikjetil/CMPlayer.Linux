//
//  main.swift
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//

//
// import.
//
import Foundation
import Cmpg123
import Cao
import Casound
import Termios
import Glibc

//
// Global constants.
//
internal let g_fieldWidthSongNo: Int = 9   // fixed
internal let g_fieldWidthArtist: Int = 33  // min
internal let g_fieldWidthTitle: Int = 33   // min
internal let g_fieldWidthDuration: Int = 5 // fixed
internal let g_player: Player = Player()   // main application object
internal let g_versionString: String = "1.5.5.0"
internal let g_lock = NSLock()     // global lock 
internal let g_crossfadeMinTime: Int = 1   // seconds
internal let g_crossfadeMaxTime: Int = 20  // seconds
internal let g_asyncCompletionDelay: Float = 0.2
internal let g_metadataNotFoundName: String = "--unknown--"
//
// Global variables/properties
//
internal var g_songs: [SongEntry] = []                  // all songs
internal var g_playedSongs: [SongEntry] = []            // previously played songs
internal var g_playlist: [SongEntry] = []               // main playlist
internal var g_genres: [String: [SongEntry]] = [:]      // songs belonging to each genre
internal var g_artists: [String: [SongEntry]] = [:]     // songs belonging to each artist
internal var g_recordingYears: [Int: [SongEntry]] = [:] // songs belonging to each recording year
internal var g_searchResult: [SongEntry] = []           // songs in mode (search result)
internal var g_searchType: [SearchType] = []            // One SearchType for search, and n more for n search+ searches, no duplicates
internal var g_modeSearch: [[String]] = []              // Search terms for each element in g_searchType
internal var g_modeSearchStats: [[Int]] = []            // Search stats for each element in g_searchType matching g_modeSearch
internal var g_library: PlayerLibrary = PlayerLibrary() // library
internal var g_mainWindow: MainWindow?                  // main window
internal var g_tscpStack: [TerminalSizeHasChangedProtocol] = [] // each window as they appear is added, then when close removed
internal var g_termSizeIsChanging: Bool = false         // Terminal size is changing
internal var g_rows: Int = -1
internal var g_cols: Int = -1
internal var g_quit: Bool = false
internal var g_doNotPaint: Bool = false
//
// Startup code
//
// Check for command line arguments.
if CommandLine.argc >= 2 {
    if CommandLine.arguments[1].lowercased() == "--integrity-check" {
        // initialize libao
        ao_initialize()        
        PrintAndExecuteIntegrityCheck()
        // shutdown ao
        ao_shutdown() 
        exit(ExitCodes.SUCCESS.rawValue)   
    }
    else if CommandLine.arguments[1].lowercased() == "--version" {
        print("CMPlayer v\(g_versionString)")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    else if CommandLine.arguments[1].lowercased() == "--purge" {
        print("CMPlayer Purge")
        print("=========================")
        if PlayerDirectories.purge() {
            print("(i): Purge success")
        }
        else {
            print("(e): Purge error")
        }
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    else if CommandLine.arguments[1].lowercased() == "--set-output-ao" {
        print("CMPlayer Set Output")
        print("=========================")
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.outputSoundLibrary = OutputSoundLibrary.ao
        PlayerPreferences.savePreferences()
        print("(i): Output sound set to ao")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    else if CommandLine.arguments[1].lowercased() == "--set-output-alsa" {
        print("CMPlayer Set Output")
        print("=========================")
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.outputSoundLibrary = OutputSoundLibrary.alsa
        PlayerPreferences.savePreferences()
        print("(i): Output sound set to alsa")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    else {
        print("CMPlayer Help")
        print("=========================")
        print("Usage: cmplayer <options>")
        print("<options>")
        print(" --help            = show this help screen")
        print(" --version         = show version numbers")
        print(" --integrity-check = do an integrity check")
        print(" --purge           = remove all stored data")
        print(" --set-output-ao   = sets audio playback to use libao (ao)")
        print(" --set-output-alsa = sets audio playback to use libasound (alsa)")
        print("")        
        exit(ExitCodes.SUCCESS.rawValue)
    }    
}

// initialize libmpg123
guard mpg123_init() == 0 else {
    print("Failed to initialize libmpg123")
    exit(ExitCodes.ERROR_INIT_LIBMPG.rawValue)
}

// initialize libao
ao_initialize()

// ensure we exit/close libmpg123/libao
atexit( {    
    // close libraries
    mpg123_exit()
    ao_shutdown()
})

// we have normal startup
// redirect stderr
// we do this to remove process_comment messages
let stderr_old = redirect_stderr()
guard stderr_old != -1 else {    
    print("Failed to redirect stderr to /dev/null")
    exit(ExitCodes.ERROR_REDIRECT.rawValue)
}

// stderr redirect successfull
// normal startup and normal execution continue
do {
    // set log system
    PlayerLog.ApplicationLog = PlayerLog(autoSave: true, loadOldLog: false, logSaveType: PlayerLogSaveAsType.plainText)

    // initialize CMPlayer.Linux
    try g_player.initialize()    
    
    // run the program and save exit code
    try g_player.run()

    // ensure g_quit is true to let all async code to exit
    g_quit = true
    
    // let all players stop playing and clean up
    Thread.sleep(forTimeInterval: TimeInterval(g_asyncCompletionDelay))

    // restore stderr
    restore_stderr(stderr_old)    

    // clear screen
    Console.clearScreen()
    Console.gotoXY(1, 1)    
    system("clear") 
    
    print("CMPlayer exited normally.")

    // log exit
    PlayerLog.ApplicationLog?.logInformation(title: "CMPlayer", text: "Application Exited Normally.")        
    
    // exit with exit code
    exit(ExitCodes.SUCCESS.rawValue)
} catch let error as CmpError {
    // allow for concurrent threads to exit
    g_quit = true
    Thread.sleep(forTimeInterval: TimeInterval(g_asyncCompletionDelay))

    let msg = "CMPlayer ABEND.\nException caught.\nMessage: \(error.message)"    

    Console.clearScreen()
    Console.gotoXY(1, 1)
    system("clear")    
    
    print(msg)

    PlayerLog.ApplicationLog?.logError(title: "CMPlayer", text: msg)
    exit(ExitCodes.ERROR_UNKNOWN.rawValue)
} catch {        
    // allow for concurrent threads to exit
    g_quit = true
    Thread.sleep(forTimeInterval: TimeInterval(g_asyncCompletionDelay))

    let msg = "CMPlayer ABEND.\nUnknown exception caught.\nMessage: \(error)"

    Console.clearScreen()
    Console.gotoXY(1, 1)
    system("clear")    
    print(msg) 

    PlayerLog.ApplicationLog?.logError(title: "CMPlayer", text: msg)
    exit(ExitCodes.ERROR_UNKNOWN.rawValue)
}