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

//
// Global constants.
//
internal let g_fieldWidthSongNo: Int = 8
internal let g_fieldWidthArtist: Int = 33
internal let g_fieldWidthTitle: Int = 33
internal let g_fieldWidthDuration: Int = 5
internal let g_player: Player = Player()
internal let g_versionString: String = "1.1.0.1"
//internal let g_lock = NSLock()
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
internal var g_modeSearchStats: [[Int]] = []  // Search stats for each element in g_searchType matching g_modeSearch
internal var g_library: PlayerLibrary = PlayerLibrary()
internal var g_mainWindow: MainWindow?
internal var g_tscpStack: [TerminalSizeHasChangedProtocol] = []
internal var g_rows: Int = 24
internal var g_cols: Int = 80

//
// Startup code
//g_player.initialize()
//exit(g_player.run())

//*************************************************
// Initialize libao
ao_initialize()

// Default driver
let defaultDriver = ao_default_driver_id()

// Initialize libmpg123
mpg123_init()

// Open the MP3 file
let filePath = "/home/kjetilso/Music/I/iKjetil/Recordings/Mp3s/RhythmIdea033.mp3"
guard let handle = mpg123_new(nil, nil) else {
    print("Error: Couldn't initialize mpg123 handle.")
    exit(1)
}

if mpg123_open(handle, filePath) != 0 {
    print("Error: Couldn't open file \(filePath).")
    exit(1)
}

// Get audio format information
var rate: CLong = 0
var channels: Int32 = 0
var encoding: Int32 = 0
if mpg123_getformat(handle, &rate, &channels, &encoding) != 0 {
    print("Error: Couldn't get format information.")
    exit(1)
}

// Set the output format
var format = ao_sample_format()
format.bits = 16
format.channels = channels
format.rate = Int32(rate)
format.byte_format = AO_FMT_NATIVE
format.matrix = nil

// Open a live playback device
let device = ao_open_live(defaultDriver, &format, nil)
if device == nil {
    print("Error: Couldn't open audio device.")
    exit(1)
}

// Buffer for audio output
let bufferSize = 4096
var buffer = [UInt8](repeating: 0, count: bufferSize)
var done: Int = 0

// Decode and play the file
while mpg123_read(handle, &buffer, bufferSize, &done) == 0 {
    ao_play(device, &buffer, UInt32(done))
}

// Cleanup
ao_close(device)
mpg123_close(handle)
mpg123_delete(handle)
mpg123_exit()
ao_shutdown()

print("Playback finished.")

exit(0);

