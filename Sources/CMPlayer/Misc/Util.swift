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
/// Returnes true if window size is valid, false otherwise.
/// - Returns: 
internal func isWindowSizeValid() -> Bool {
    if g_rows < g_minRows || g_cols < g_minCols {
        return false
    }

    return true
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
/// Date extension methods.
///
internal extension Date {
    ///
    /// Convert a Date into a YYYY-MM-DD HH:mm:ss string.
    ///
    /// returns: Date as string.
    ///
    func itsToString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: self)
    }
}
///
/// render terminal too small message
/// 
internal func renderTerminalTooSmallMessage()
{
    Console.clearScreenCurrentTheme()
    Console.gotoXY(1,1)
    print("Terminal window must be at least \(g_minCols) by \(g_minRows)")
}