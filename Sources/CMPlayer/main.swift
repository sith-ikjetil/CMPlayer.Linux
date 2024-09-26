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
import Glibc
//
// Global constants.
//
internal let g_fieldWidthSongNo: Int = 9            // fixed
internal let g_fieldWidthArtist: Int = 33           // min
internal let g_fieldWidthTitle: Int = 33            // min
internal let g_fieldWidthDuration: Int = 5          // fixed
internal let g_player: Player = Player()            // main application object
internal let g_versionString: String = "1.5.8.8"    // current working version
internal let g_lock = NSLock()              // global lock 
internal let g_crossfadeMinTime: Int = 1            // seconds
internal let g_crossfadeMaxTime: Int = 20           // seconds
internal let g_asyncCompletionDelay: Float = 0.35   // 350 ms
internal let g_metadataNotFoundName: String = "--unknown--" // metadata not found or invalid has this string
internal let g_minCols: Int = 60 // minimum supported columns terminal size (previous 80)
internal let g_minRows: Int = 12 // minimum supported rows terminal size (previous 24)
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
internal var g_rows: Int = -1                           // current terminal size rows
internal var g_cols: Int = -1                           // current terminal size columns
internal var g_quit: Bool = false                       // are we quitting?
internal var g_doNotPaint: Bool = false                 // do no repaint mainwindow during this flag
internal var g_assumeSearchMode: Bool = false           // assume search will give mode (used for load script)
//======================================
// Startup code
//======================================
// Handle command line arguments
CommandLineHandler.processCommandLine()
// initialize libmpg123
guard mpg123_init() == 0 else {
    print("Failed to initialize libmpg123")
    exit(ExitCodes.ERROR_INIT_LIBMPG.rawValue)
}
// initialize libao
ao_initialize()
// ensure we exit/close libmpg123/libao
atexit( {    
    // close libmpg123
    mpg123_exit()
    // close libao
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
    // initialize CMPlayer.Linux
    try g_player.initialize()    
    // run the program and save exit code
    try g_player.run()
    // ensure g_quit is true to let all async code to exit
    g_quit = true
    // let all players async code stop playing and clean up
    Thread.sleep(forTimeInterval: TimeInterval(g_asyncCompletionDelay))
    // restore stderr
    restore_stderr(stderr_old)    
    // clear screen
    Console.clearScreen()
    // goto 1,1
    Console.gotoXY(1, 1)  
    // reset console colors
    Console.resetConsoleColors()  
    // clear terminal
    system("clear") 
    // write exit message
    print("CMPlayer exited normally.")
    // log exit
    PlayerLog.ApplicationLog?.logInformation(title: "CMPlayer", text: "Application Exited Normally.")            
    // exit with exit code
    exit(ExitCodes.SUCCESS.rawValue)
} catch let error as CmpError {
    // ensure g_quit is true to let all async code to exit
    g_quit = true
    // let all players async code stop playing and clean up
    Thread.sleep(forTimeInterval: TimeInterval(g_asyncCompletionDelay))
    // create message
    let msg = "CMPlayer ABEND.\nException caught.\nMessage: \(error.message)"    
    // clear screen
    Console.clearScreen()
    // goto 1,1
    Console.gotoXY(1, 1)
    // reset console colors
    Console.resetConsoleColors()
    // clear terminal
    system("clear")    
    // write error message
    print(msg)
    // log error
    PlayerLog.ApplicationLog?.logError(title: "CMPlayer", text: msg)
    // exit with exit code
    exit(ExitCodes.ERROR_UNKNOWN.rawValue)
} catch {        
    // ensure g_quit is true to let all async code to exit
    g_quit = true
    // let all players async code stop playing and clean up
    Thread.sleep(forTimeInterval: TimeInterval(g_asyncCompletionDelay))
    // create message
    let msg = "CMPlayer ABEND.\nUnknown exception caught.\nMessage: \(error)"
    // clear screen
    Console.clearScreen()
    // goto 1,1
    Console.gotoXY(1, 1)
    // reset console colors
    Console.resetConsoleColors()
    // clear terminal
    system("clear")  
    // write error message
    print(msg) 
    // log error
    PlayerLog.ApplicationLog?.logError(title: "CMPlayer", text: msg)
    // exit with exit code
    exit(ExitCodes.ERROR_UNKNOWN.rawValue)
}