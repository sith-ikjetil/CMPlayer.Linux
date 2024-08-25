//
//  Util.swift
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//

//
// import.
//
import Foundation
import Cao
import Casound

///
/// Alsa output state struct.
///
internal struct AlsaState {
    let pcmDeviceName = "default"
    var pcmHandle: OpaquePointer? = nil
    var channels: UInt32 = 2
    var sampleRate: UInt32 = 44100
    var bufferSize: snd_pcm_uframes_t = 1024
}

///
/// CmpMetadata
/// Container for metadata.
///
internal class CmpMetadata {
    var songNo: Int = 0
    var artist: String = ""    
    var title: String = ""    
    var duration: UInt64 = 0    
    var genre: String = ""    
    var albumName: String = ""    
    var recordingYear: Int = 0
    var trackNo: Int = 0        
}
///
/// Enum exit codes
///
internal enum ExitCodes: Int32 {
    case SUCCESS = 0
    case ERROR_UNKNOWN = 1
    case ERROR_FINDING_FILES = 2
    case ERROR_PLAYING_FILE = 3
    case ERROR_CONSOLE = 4
    case ERROR_INIT_LIBMPG = 5
    case ERROR_REDIRECT = 6
    case ERROR_CANCEL = 7
}
///
/// SearchType, type of search
///
internal enum SearchType : String {
    case Artist = "artist"
    case Title = "title"
    case ArtistOrTitle = "artist or title"
    case Album = "album"
    case Genre = "genre"
    case RecordedYear = "year"
}
//
// MediaPlayer error
//
internal struct CmpError : Error {
    let message: String
}
///
/// Padding alignment types.
///
internal enum PrintPaddingTextAlign {
    case left
    case right
    case center
    case ignore
}
///
/// Protocol for terminal size changed
///
internal protocol TerminalSizeHasChangedProtocol {
    func terminalSizeHasChanged() -> Void
}
///
/// Protocol for windows
///
internal protocol PlayerWindowProtocol {
    func showWindow() -> Void
}
///
/// Check to see if command is one of the supported given commands.
///
/// parameter command: Command to check for.
/// parameter commands: Commands to check in.
///
/// returns: True if command is in commands. False otherwise.
///
internal func isCommandInCommands(_ command: String, _ commands: [String]) -> Bool {
    for c in commands {
        if command == c {
            return true
        }
    }
    return false
}
///
/// Validates if crossfade time is a valid crossfade time.
///
/// parameter ctis: Crossfade time in seconds.
///
/// returns: True if crossfade time is valid. False otherwise.
///
internal func isCrossfadeTimeValid(seconds: Int) -> Bool {    
    if seconds >= g_crossfadeMinTime && seconds <= g_crossfadeMaxTime {
        return true
    }
    return false
}
///
/// Reparses the command arguments. Makes sure that commands that are part of "<search term>" are remade into on search term without the " character.
///
/// parameter command: The search terms comming from command argument.
///
/// returns: The new reparsed command argument array.
///
internal func reparseCurrentCommandArguments(_ command: [String]) -> [String] {
    var retVal: [String] = []

    var temp: String = ""
    
    for c in command {
        if temp.count > 0 {
            if c.count > 0 {
                if c.hasSuffix("\"") {
                    var nc: String = c
                    nc.remove(at: nc.index(nc.endIndex, offsetBy: -1))
                    temp.append(" ")
                    temp.append(nc)
                    retVal.append(temp)
                    temp = ""
                }
                else {
                    temp.append(" ")
                    temp.append(c)
                }
            }
        }
        else if c.count > 0 {
            var nc: String = c
            while nc.hasPrefix(" ") {
                nc.remove(at: nc.startIndex)
            }
            if nc.count > 0 {
                var i: Int = 0
                if c.hasPrefix("\"") {
                    i += 1
                }
                if i == 0 {
                    retVal.append(nc)
                }
                else {
                    nc.remove(at: nc.startIndex)
                    if nc.count > 0 {
                        if nc.hasSuffix("\"") {
                            nc.remove(at: nc.index(nc.endIndex, offsetBy: -1))
                            if nc.count > 0 {
                                retVal.append(nc)
                            }
                        }
                        else {
                            temp = nc
                        }
                    }
                }
            }
        }
    }
    
    return retVal
}
///
/// String extension methods.
///
internal extension String {
    ///
    /// Converts a string to a padded string of given length.
    ///
    /// parameter maxLength: Length of new string.
    /// parameter padding: Padding type.
    /// parameter paddingChar: Padding character to use.
    ///
    /// returns: New padded string.
    ///
    func convertStringToLengthPaddedString(_ maxLength: Int,_ padding: PrintPaddingTextAlign,_ paddingChar: Character) -> String {
        var msg: String = self
        
        if msg.count == 0 || maxLength <= 0 {
            return msg
        }
        
        if msg.count == 0 {
            var result: String = ""
            for _ in 0..<maxLength {
                result.append(paddingChar)
            }
            return result
        }
        
        if msg.count > maxLength {                      
            let idx = msg.index(msg.startIndex, offsetBy: maxLength)
            msg = String(msg[msg.startIndex..<idx])
        }
        
        if maxLength == 1 {
            return String(msg.first!)
        }
        
        switch padding {
        case .ignore:
            if msg.count < maxLength {
                return msg
            }
            let idx = msg.index(msg.startIndex, offsetBy: maxLength)
            return String(msg[msg.startIndex..<idx])
        case .center:
            var str = String(repeating: paddingChar, count: maxLength)
            var len: Double = Double(maxLength)
            len = len / 2.0
            let ulen = UInt64(len)
            if Double(ulen) < len {
                len -= 1
            }
            len -= Double(msg.count) / 2
            let si = str.index(str.startIndex, offsetBy: Int(len))
            str.insert(contentsOf: msg, at: si)
            return String(str[str.startIndex..<str.index(str.startIndex, offsetBy: maxLength)])
        case .left:
            var str = String(repeating: paddingChar, count: maxLength)
            let len = 0
            let si = str.index(str.startIndex, offsetBy: len)
            str.insert(contentsOf: msg, at: si)
            return String(str[str.startIndex..<str.index(str.startIndex, offsetBy: maxLength)])
        case .right:
            var str = String(repeating: paddingChar, count: maxLength)
            let len = maxLength-msg.count
            let si = str.index(str.startIndex, offsetBy: len)
            str.insert(contentsOf: msg, at: si)
            return String(str[str.startIndex..<str.index(str.startIndex, offsetBy: maxLength)]);
            
        }
    }
}// extension String
///
/// Split ms to its parts.
///
/// parameter time_ms: Time in milliseconds.
///
/// returns: part_hours. Number of hours in time_ms.
/// returns: part_minutes. Number of minutes in time_ms.
/// returns: part_seconds. Number of seconds in time_ms.
/// returns: part_ms. Number of milliseconds in time_ms.
///
internal func itsSplitMsToHourMinuteSeconds(_ time_ms: UInt64 ) -> (part_hours: UInt64,part_minutes: UInt64,part_seconds: UInt64,part_ms: UInt64)
{
    let seconds: UInt64 = time_ms / 1000
    
    var part_hours: UInt64 = 0
    var part_minutes: UInt64 = 0
    var part_seconds: UInt64 = 0
    var part_ms: UInt64 = 0
    
    part_hours = seconds / 3600;
    part_minutes = ( seconds - ( part_hours * 3600 ) ) / 60;
    part_seconds = seconds - ( part_hours * 3600 ) - ( part_minutes * 60 );
    part_ms = time_ms - ( part_seconds * 1000 ) - ( part_minutes * 60 * 1000 ) - ( part_hours * 3600 * 1000 );
    
    return (part_hours, part_minutes, part_seconds, part_ms)
}
///
/// Splits hour to its parts.
///
/// parameter houIn: Number of hours to split.
///
/// returns: houRest. Number of hours left in houIn.
/// returns: day. Number of days in houIn.
/// returns: week. Number of weeks in houIn.
/// returns: year. Number of years in houIn.
///
internal func itsSplitHourToYearWeekDayHour(_ houIn: UInt64 ) -> (houRest: UInt64, day: UInt64, week: UInt64, year: UInt64)
{
    var houRest: UInt64 = houIn;
    
    var day: UInt64 = houIn / 24;
    var week: UInt64 = day / 7;
    let year: UInt64 = week / 52;
    
    day -= ( week * 7 );
    
    week -= ( year * 52 );
    
    houRest -= week * 7 * 24;
    houRest -= day * 24;
    houRest -= year * 52 * 7 * 24;
    
    return (houRest, day, week, year)
}
///
/// Renders milliseconds to a fully descriptive time string.
///
/// parameter milliseconds: Number of milliseconds to render.
/// parameter bWithMilliseconds: True is milliseconds should be part of the render. False if not.
///
/// returns: A fully descriptive time string.
///
internal func itsRenderMsToFullString(_ milliseconds: UInt64,_ bWithMilliseconds: Bool) -> String
{
    let (part_hours, min, sec, ms) = itsSplitMsToHourMinuteSeconds(milliseconds)
    let (houRest, day, week, year) = itsSplitHourToYearWeekDayHour(part_hours)
    
    var ss: String = ""
    
    if (year > 0) {
        if (year == 1)
        {
            ss += String(year) + " year "
        }
        else
        {
            ss += String(year) + " years "
        }
    }
    if (week > 0 || year > 0) {
        if (week == 1 || week == 0) {
            ss += String(week) + " week "
        }
        else
        {
            ss += String(week) + " weeks "
        }
    }
    if (day > 0 || week > 0 || year > 0) {
        if (day == 1 || day == 0)
        {
            ss += String(day) + " day "
        }
        else
        {
            ss += String(day) + " days "
        }
    }
    if (houRest > 0 || day > 0 || week > 0 || year > 0)
    {
        if (houRest == 1 || houRest == 0)
        {
            ss += String(houRest) + " hour "
        }
        else
        {
            ss += String(houRest) + " hours "
        }
    }
    
    if (min < 10) {
        ss += "0" + String(min) + ":"
    }
    else
    {
        ss += String(min) + ":"
    }
    if (sec < 10) {
        ss += "0" + String(sec);
    }
    else
    {
        ss += String(sec);
    }
    
    if (bWithMilliseconds)
    {
        if (ms < 10) {
            ss += ".00" + String(ms);
        }
        else if (ms < 100) {
            ss += ".0" + String(ms);
        }
        else {
            ss += "." + String(ms);
        }
    }
    
    return ss
}
///
/// Determines if a song url path is under music root path in Player Preferences
///
/// parameter path: Path to song to determine if it is part of music root paths.
///
/// returns: True if path is under music root path. False otherwise.
///
internal func isPathInMusicRootPath(path: String) -> Bool {
    for p in PlayerPreferences.musicRootPath {
        if path.hasPrefix(p) {
            return true
        }
    }
    return false
}
///
/// Determines if a song url path is under exclustion paths in Player Preferences
///
/// parameter path: Path to song to determine if it is part of music root paths.
///
/// returns: True if path is under music root path. False otherwise.
///
internal func isPathInExclusionPath(path: String) -> Bool {
    for p in PlayerPreferences.exclusionPaths {
        if path.hasPrefix(p) {
            return true
        }
    }
    return false
}
///
/// Int extension methods.
///
internal extension Int {
    ///
    /// Convert a Int into a Norwegian style number for text representation. " " as a thousand separator.
    ///
    /// returns: The number as a new string.
    ///
    func itsToString() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "nb_NO")
        return formatter.string(from: NSNumber(value: self))!
    }
}
///
/// Runs regular expression agains an input string.
///
/// parameter regex: input regular expression
/// parameter text: input string to run regular expression on.
///
/// returns: string array result.
///
internal func regExMatches(for regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                                    range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    }
    catch  {
    }
    
    return []
}
///
/// Compares two song entries.
///
internal func sortSongEntry(se1: SongEntry, se2: SongEntry) -> Bool {
    var cmp = se1.artist.compare(se2.artist)
    
    if cmp.rawValue == 0 {
        cmp = se1.albumName.compare(se2.albumName)
        if cmp.rawValue == 0 {
            if se1.trackNo == se2.trackNo {
                cmp = se1.title.compare(se2.title)
            }
            else {
                return se1.trackNo < se2.trackNo
            }
        }
    }
    
    if cmp.rawValue < 0 {
        return true
    }
    
    return false
}
///
/// Give current theme color
///
internal func getThemeBgColor() -> ConsoleColor {
  switch PlayerPreferences.colorTheme {
  case .Default:
        return ConsoleColor.black
  case .Blue:
        return ConsoleColor.blue
  case .Black:
        return ConsoleColor.black
  }
}
///
/// Give song background theme color
///
internal func getThemeSongBgColor() -> ConsoleColor {
  switch PlayerPreferences.colorTheme {
  case .Default:
        return ConsoleColor.blue
  case .Blue:
        return ConsoleColor.blue
  case .Black:
        return ConsoleColor.black
  }
}
///
/// Get mode information
///
/// returns: set of isInMode, mode name, number of songs
///
internal func getModeStatus() -> (isInMode: Bool, modeName: [String], numberOfSongsInMode: Int) {
    var isInMode: Bool = false
    var modeName: [String] = []
    let numberOfSongsInMode: Int = g_searchResult.count
    
    for type in g_searchType {
        modeName.append( type.rawValue )
        isInMode = true
    }

    return (isInMode: isInMode, modeName: modeName, numberOfSongsInMode: numberOfSongsInMode)
}
/// 
/// Check if SearchType is in g_searchMode
/// 
internal func isSearchTypeInMode(_ type: SearchType) -> Bool {
    for t in g_searchType {
        if t == type {            
            return true
        }
    }
    return false
}
/// 
/// Converts an id3v1 genre id to a genre name.
/// - Parameter index: id3v1 genre id
/// - Returns:  genre name.
internal func convertId3V1GenreIndexToName(index: UInt8) -> String {    
    switch index {
        case 0: return "Blues"
        case 1: return "Classic Rock"
        case 2: return "Country"
        case 3: return "Dance"
        case 4: return "Disco"
        case 5: return "Funk"
        case 6: return "Grunge"
        case 7: return "Hip-Hop"
        case 8: return "Jazz"
        case 9: return "Metal"
        case 10: return "New Age"
        case 11: return "Oldies"
        case 12: return "Other"
        case 13: return "Pop"
        case 14: return "R&B"
        case 15: return "Rap"
        case 16: return "Reggae"
        case 17: return "Rock"
        case 18: return "Techno"
        case 19: return "Industrial"
        case 20: return "Alternative"
        case 21: return "Ska"
        case 22: return "Death Metal"
        case 23: return "Pranks"
        case 24: return "Soundtrack"
        case 25: return "Euro-Techno"
        case 26: return "Ambient"
        case 27: return "Trip-Hop"
        case 28: return "Vocal"
        case 29: return "Jazz+Funk"
        case 30: return "Fusion"
        case 31: return "Trance"
        case 32: return "Classical"
        case 33: return "Instrumental"
        case 34: return "Acid"
        case 35: return "House"
        case 36: return "Game"
        case 37: return "Sound Clip"
        case 38: return "Gospel"
        case 39: return "Noise"
        case 40: return "AlternRock"
        case 41: return "Bass"
        case 42: return "Soul"
        case 43: return "Punk"
        case 44: return "Space"
        case 45: return "Meditative"
        case 46: return "Instrumental Pop"
        case 47: return "Instrumental Rock"
        case 48: return "Ethnic"
        case 49: return "Gothic"
        case 50: return "Darkwave"
        case 51: return "Techno-Industrial"
        case 52: return "Electronic"
        case 53: return "Pop-Folk"
        case 54: return "Eurodance"
        case 55: return "Dream"
        case 56: return "Southern Rock"
        case 57: return "Comedy"
        case 58: return "Cult"
        case 59: return "Gangsta"
        case 60: return "Top 40"
        case 61: return "Christian Rap"
        case 62: return "Pop/Funk"
        case 63: return "Jungle"
        case 64: return "Native American"
        case 65: return "Cabaret"
        case 66: return "New Wave"
        case 67: return "Psychedelic"
        case 68: return "Rave"
        case 69: return "Showtunes"
        case 70: return "Trailer"
        case 71: return "Lo-Fi"
        case 72: return "Tribal"
        case 73: return "Acid Punk"
        case 74: return "Acid Jazz"
        case 75: return "Polka"
        case 76: return "Retro"
        case 77: return "Musical"
        case 78: return "Rock & Roll"
        case 79: return "Hard Rock"
        case 80: return "Folk"
        case 81: return "Folk-Rock"
        case 82: return "National Folk"
        case 83: return "Swing"
        case 84: return "Fast Fusion"
        case 85: return "Bebop"
        case 86: return "Latin"
        case 87: return "Revival"
        case 88: return "Celtic"
        case 89: return "Bluegrass"
        case 90: return "Avantgarde"
        case 91: return "Gothic Rock"
        case 92: return "Progressive Rock"
        case 93: return "Psychedelic Rock"
        case 94: return "Symphonic Rock"
        case 95: return "Slow Rock"
        case 96: return "Big Band"
        case 97: return "Chorus"
        case 98: return "Easy Listening"
        case 99: return "Acoustic"
        case 100: return "Humour"
        case 101: return "Speech"
        case 102: return "Chanson"
        case 103: return "Opera"
        case 104: return "Chamber Music"
        case 105: return "Sonata"
        case 106: return "Symphony"
        case 107: return "Booty Bass"
        case 108: return "Primus"
        case 109: return "Porn Groove"
        case 110: return "Satire"
        case 111: return "Slow Jam"
        case 112: return "Club"
        case 113: return "Tango"
        case 114: return "Samba"
        case 115: return "Folklore"
        case 116: return "Ballad"
        case 117: return "Power Ballad"
        case 118: return "Rhythmic Soul"
        case 119: return "Freestyle"
        case 120: return "Duet"
        case 121: return "Punk Rock"
        case 122: return "Drum Solo"
        case 123: return "A capella"
        case 124: return "Euro-House"
        case 125: return "Dance Hall"        
        case 126: return "Goa"
        case 127: return "Drum & Bass"
        case 128: return "Club-House"
        case 129: return "Hardcore"
        case 130: return "Terror"
        case 131: return "Indie"
        case 132: return "BritPop"
        case 133: return "Negerpunk"
        case 134: return "Polsk Punk"
        case 135: return "Beat"
        case 136: return "Christian Gangsta"
        case 137: return "Heavy Metal"
        case 138: return "Black Metal"
        case 139: return "Crossover"
        case 140: return "Contemporary Christian"
        case 141: return "Christian Rock"
        case 142: return "Merengue"
        case 143: return "Salsa"
        case 144: return "Trash Metal"
        case 145: return "Anime"
        case 146: return "Jpop"
        case 147: return "Synthpop"
        case 148: return "Abstract"
        case 149: return "Art Rock"
        case 150: return "Baroque"
        case 151: return "Bhangra"
        case 152: return "Big Beat"
        case 153: return "Breakbeat"
        case 154: return "Chillout"
        case 155: return "Downtempo"
        case 156: return "Dub"
        case 157: return "EBM"
        case 158: return "Eclectic"
        case 159: return "Electro"
        case 160: return "Electroclash"
        case 161: return "Emo"
        case 162: return "Experimental"
        case 163: return "Garage"
        case 164: return "Global"
        case 165: return "IDM"
        case 166: return "Illbient"
        case 167: return "Industro-Goth"
        case 168: return "Jam Band"
        case 169: return "Krautrock"
        case 170: return "Leftfield"
        case 171: return "Lounge"
        case 172: return "Math Rock"
        case 173: return "New Romantic"
        case 174: return "Nu-Breakz"
        case 175: return "Post-Punk"
        case 176: return "Post-Rock"
        case 177: return "Psytrance"
        case 178: return "Shoegaze"
        case 179: return "Space Rock"
        case 180: return "Trop Rock"
        case 181: return "World Music"
        case 182: return "Neoclassical"
        case 183: return "Audiobook"
        case 184: return "Audio Theatre"
        case 185: return "Neue Deutsche Welle"
        case 186: return "Podcast"
        case 187: return "Indie Rock"
        case 188: return "G-Funk"
        case 189: return "Dubstep"
        case 190: return "Garage Rock"
        case 191: return "Psybient"
        default: return g_metadataNotFoundName
    }
}
///
/// Function to redirect stderr to /dev/null
/// 
func redirect_stderr() -> Int32 {
    let dev_null = open("/dev/null", O_WRONLY)
    if dev_null == -1 {
        perror("open")
        return -1
    }
    
    // Duplicate the stderr file descriptor to preserve it
    let stderr_copy = dup(fileno(stderr))
    if stderr_copy == -1 {
        perror("dup")
        return -1
    }
    
    // Redirect stderr to /dev/null
    if dup2(dev_null, fileno(stderr)) == -1 {
        perror("dup2")
        return -1
    }
    
    close(dev_null)

    return stderr_copy
}
///
/// Function to restore stderr from the backup
/// 
func restore_stderr(_ stderr_copy: Int32) {
    fflush(stderr) // Flush any remaining output
    dup2(stderr_copy, fileno(stderr)) // Restore stderr
    close(stderr_copy) // Close the backup
}
///
/// window size container.
/// 
struct winsize {
    var ws_row: UInt16 = 0
    var ws_col: UInt16 = 0
    var ws_xpixel: UInt16 = 0
    var ws_ypixel: UInt16 = 0
}
/// 
/// Gets terminal size
///
func getTerminalSize() -> (rows: Int, cols: Int)? {
    var w = winsize()
    let result = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w)
    if result == 0 {
        return (rows: Int(w.ws_row), cols: Int(w.ws_col))
    } else {
        return nil
    }
}
/// 
/// Extracts track number from aac metadata track field.
/// 
func extractMetadataTrackNo(text: String) -> Int {
    // Define a regular expression pattern for a number or a number1/number2 format
    let pattern = "\\b(\\d+)/?\\d*\\b"
    
    // Create a regular expression object
    let regex = try? NSRegularExpression(pattern: pattern)
    
    // Search for the first match
    if let match = regex?.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
        // Extract the matched range for the first number
        if let range = Range(match.range(at: 1), in: text) {
            return Int(String(text[range])) ?? 0
        }
    }
    
    return 0
}
/// 
/// Extracts year from aac metadata date/year fields.
/// 
func extractMetadataYear(text: String) -> Int {
    // Define a regular expression pattern for a number or a number1/number2 format
    let pattern = "\\b(\\d{4}).*\\b"
    
    // Create a regular expression object
    let regex = try? NSRegularExpression(pattern: pattern)
    
    // Search for the first match
    if let match = regex?.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
        // Extract the matched range for the first number
        if let range = Range(match.range(at: 1), in: text) {
            return Int(String(text[range])) ?? 0
        }
    }
    
    return 0
}
///
/// Does an integrity check.
/// 
func PrintAndExecuteIntegrityCheck() {
    print("CMPlayer Integrity Check")
    print("========================")
    PrintAndExecuteOutputDevices()
    PrintAndExecuteLibraryFiles()
}
///
/// Prints information about output devices.
/// 
func PrintAndExecuteOutputDevices() {        
    print("ao:")
    printAoInfo()    
    print("")
    print("alsa:")
    printALSAInfo()
    print("")
}
///
/// prints ao information
/// 
func printAoInfo() {
    var driverCount: Int32 = 0    
    if let driverInfoList = ao_driver_info_list(&driverCount) {                
        // Iterate through the available drivers and print them        
        for i in 0..<Int(driverCount) {
            if let driverInfoPointer = driverInfoList[i] {
                let driverInfo = driverInfoPointer.pointee
                print(" > \(String(cString: driverInfo.name))")            
                //if driverInfo.type == AO_TYPE_LIVE {
                //    print("  Description: \(String(cString: driverInfo.short_name))")
                //    print("  Comment: \(String(cString: driverInfo.comment))\n")                    
                //}
            }             
        }    
    } 
    else {        
        print("(e): Failed to retrieve audio driver information.")
    }
}
///
/// prints also infomation
/// 
func printALSAInfo() {
    var err: Int32 = 0
    var card: Int32 = -1    
    var ctlHandle: OpaquePointer?

    // Get the first card
    err = snd_card_next(&card)
    guard err >= 0, card >= 0 else {
        print("(e): No sound cards found: '\(String(cString: snd_strerror(err)))'")
        return
    }    

    while card >= 0 {
        // Open the control interface for the card
        let cardName = "hw:\(card)"
        if snd_ctl_open(&ctlHandle, cardName, 0) < 0 {
            print("(e): Error opening control interface: '\(String(cString: snd_strerror(err)))'")
            break
        }

        // Manually allocate memory for card info
        let cardInfoSize = snd_ctl_card_info_sizeof()
        let cardInfoRaw = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(cardInfoSize))
        defer {
            cardInfoRaw.deallocate()
        }

        // Cast the raw memory to an OpaquePointer
        let cardInfoTyped: OpaquePointer? = OpaquePointer(cardInfoRaw)

        if snd_ctl_card_info(ctlHandle, cardInfoTyped) < 0 {
            print("(e): Error getting card information: '\(String(cString: snd_strerror(err)))'")
            snd_ctl_close(ctlHandle)
            break
        }
        
        print(" > Card \(card): \(String(cString: snd_ctl_card_info_get_id(cardInfoTyped))) [\(String(cString: snd_ctl_card_info_get_name(cardInfoTyped)))], driver \(String(cString: snd_ctl_card_info_get_driver(cardInfoTyped)))")        

        snd_ctl_close(ctlHandle)

        // Move to the next card
        if snd_card_next(&card) < 0 {
            break
        }
    }
}
///
/// Attempts to find .so library files under /usr.
/// Prints out result.
/// 
func PrintAndExecuteLibraryFiles() {    
    let files: [String] = ["libao.so",
                           "libasound.so",
                           "libavcodec.so",
                           "libavformat.so",
                           "libavutil.so",
                           "libmpg123.so"]

    let directories: [String] = ["/usr"]

    print("Libraries:")
    for i: Int in 0..<files.count {
        let fileName = files[i]
        var dir: String = ""
        var bFound: Bool = false
        for j: Int in 0..<directories.count {
            let directory: String = directories[j]
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory)
            if exists && isDirectory.boolValue {
                if let fileURL: URL = findFile(named: fileName, under: URL(fileURLWithPath: directory)) {
                    dir = fileURL.deletingLastPathComponent().path
                    bFound = true
                    break
                }            
            }
        }

        if bFound {
            print(" > \(fileName.convertStringToLengthPaddedString(18, .left," ")) found at: \(dir)")
        }
        else {
            print(" > \(fileName.convertStringToLengthPaddedString(18, .left," ")) NOT found!")
        }
    }
    print("")
}
/// 
/// finds a file. URL if found, nil otherwise.
/// 
func findFile(named fileName: String, under directory: URL) -> URL? {
    let fileManager = FileManager.default
    
    // Create a recursive enumerator to go through all directories and files
    let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil)
    
    // Iterate through the enumerator
    while let fileURL = enumerator?.nextObject() as? URL {
        if fileURL.lastPathComponent == fileName {
            return fileURL
        }
    }
    
    return nil
}