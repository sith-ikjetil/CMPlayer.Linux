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
//
// MediaPlayer error
//
internal struct CmpError : Error {
    let message: String
}
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

