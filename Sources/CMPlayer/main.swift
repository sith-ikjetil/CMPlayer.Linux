//
//  main.swift
//  ConsoleMusicPlayer.macOS
//
//  Created by Kjetil Kr Solberg on 18/09/2019.
//  Copyright © 2019 Kjetil Kr Solberg. All rights reserved.
//

//
// import.
//
import Foundation
import Cmpg123
import Cao
import Termios
import Glibc

//
// Global constants.
//
internal let g_fieldWidthSongNo: Int = 8
internal let g_fieldWidthArtist: Int = 33
internal let g_fieldWidthTitle: Int = 33
internal let g_fieldWidthDuration: Int = 5
internal let g_player: Player = Player()
internal let g_versionString: String = "1.1.0.1"
internal let g_lock = NSLock()
internal let g_windowContentLineCount = 17

//
// Global variables/properties
//
internal var g_songs: [SongEntry] = []
internal var g_playedSongs: [SongEntry] = []
internal var g_playlist: [SongEntry] = []
internal var g_genres: [String: [SongEntry]] = [:]
internal var g_artists: [String: [SongEntry]] = [:]
internal var g_recordingYears: [Int: [SongEntry]] = [:]
internal var g_searchResult: [SongEntry] = []
internal var g_searchType: [SearchType] = []    // One SearchType for search, and n more for n search+ searches, no duplicates
internal var g_modeSearch: [[String]] = []      // Search terms for each element in g_searchType
internal var g_modeSearchStats: [[Int]] = []    // Search stats for each element in g_searchType matching g_modeSearch
internal var g_library: PlayerLibrary = PlayerLibrary()
internal var g_mainWindow: MainWindow?
internal var g_tscpStack: [TerminalSizeHasChangedProtocol] = []
internal var g_termSizeIsChanging: Bool = false // Terminal size is changing
internal var g_rows: Int = -1
internal var g_cols: Int = -1

//
// Startup code
//
// initialize libmpg123
guard mpg123_init() == 0 else {
    print("Failed to initialize libmpg123")
    exit(1)
}

// initialize libao
ao_initialize()

// ensure we exit/close libmpg123/libao
defer {
    mpg123_exit()
    ao_shutdown()
}

// redirect stderr
// we do this to remove process_comment messages
let stderr_old = redirect_stderr()
guard stderr_old != -1 else {
    print("Failed to redirect stderr to /dev/null")
    exit(1)
}

do {
    // set log system
    PlayerLog.ApplicationLog = PlayerLog(autoSave: true, loadOldLog: false)

    // initialize CMPlayer.Linux
    try g_player.initialize()    

    // run the program and save exit code
    try g_player.run()

    // restore stderr
    restore_stderr(stderr_old)    

    // clear screen
    Console.clearScreen()
    Console.gotoXY(1, 1)    
    system("clear") 
    
    // log exit
    PlayerLog.ApplicationLog?.logInformation(title: "CMPlayer", text: "Application Exited Normally.")        

    // exit with exit code
    exit(ExitCodes.SUCCESS.rawValue)
} catch let error as CmpError {
    let msg = "Application exited abnormally.\n Exception caught.\n Message: \(error.message)"
    let wnd = ErrorWindow()
    wnd.message = msg
    wnd.showWindow()
    system("clear")

    PlayerLog.ApplicationLog?.logError(title: "CMPlayer", text: msg.trimmingCharacters(in: .newlines))        
    exit(ExitCodes.ERROR_UNKNOWN.rawValue)
} catch {        
    let msg = "Application exited abnormally.\n Unknown exception caught.\n Message: \(error)"
    let wnd = ErrorWindow()
    wnd.message = msg
    wnd.showWindow()
    system("clear")

    PlayerLog.ApplicationLog?.logError(title: "CMPlayer", text: msg.trimmingCharacters(in: .newlines))        
    exit(ExitCodes.ERROR_UNKNOWN.rawValue)
}