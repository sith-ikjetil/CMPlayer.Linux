import Foundation

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
///
/// render terminal too small message
/// 
internal func renderTerminalTooSmallMessage()
{
    Console.clearScreenCurrentTheme()
    Console.gotoXY(1,1)
    print("Terminal window must be at least \(g_minCols)x\(g_minRows) (\(g_cols)x\(g_rows)).")
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
    case .Custom:
        return PlayerPreferences.bgEmptySpaceColor
  }
}
/// 
/// getThemeBgHeaderColor
/// 
/// - Returns: current theme bg header color
internal func getThemeBgHeaderColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.blue
        case .Blue: return ConsoleColor.blue
        case .Black: return ConsoleColor.black
        case .Custom: return PlayerPreferences.bgHeaderColor
    }
}
/// 
/// getThemeBgHeaderModifier
/// 
/// - Returns: current theme bg header color modifier
internal func getThemeBgHeaderModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.bold
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.none
        case .Custom: return PlayerPreferences.bgHeaderModifier
    }
}
/// 
/// getThemeBgHeaderColor
/// 
/// - Returns: current theme bg header color
internal func getThemeFgHeaderColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.white
        case .Blue: return ConsoleColor.white
        case .Black: return ConsoleColor.white
        case .Custom: return PlayerPreferences.fgHeaderColor
    }
}
/// 
/// getThemeBgHeaderModifier
/// 
/// - Returns: current theme bg header color modifier
internal func getThemeFgHeaderModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.bold
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.bold
        case .Custom: return PlayerPreferences.fgHeaderModifier
    }
}
/// 
/// getThemeBgEmptySpaceColor
/// 
/// - Returns: current emtpy space bg color
internal func getThemeBgEmptySpaceColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.black
        case .Blue: return ConsoleColor.blue
        case .Black: return ConsoleColor.black
        case .Custom: return PlayerPreferences.bgEmptySpaceColor
    }
}
/// 
/// getThemeBgEmptySpaceModifier
/// 
/// - Returns: current emtpy space bg color modifier
internal func getThemeBgEmptySpaceModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.bold
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.bold
        case .Custom: return PlayerPreferences.bgEmptySpaceModifier
    }
}
/// 
/// getThemeFgEmptySpaceColor
/// 
/// - Returns: current emtpy space bg color
internal func getThemeFgEmptySpaceColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.white
        case .Blue: return ConsoleColor.white
        case .Black: return ConsoleColor.white
        case .Custom: return PlayerPreferences.fgEmptySpaceColor
    }
}
/// 
/// getThemeFgEmptySpaceModifier
/// 
/// - Returns: current emtpy space bg color modifier
internal func getThemeFgEmptySpaceModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.bold
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.bold
        case .Custom: return PlayerPreferences.fgEmptySpaceModifier
    }
}
/// 
/// getThemeBgQueueSongNoColor
/// 
/// - Returns: current song no queue bg color
internal func getThemeBgQueueSongNoColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.blue
        case .Blue: return ConsoleColor.blue
        case .Black: return ConsoleColor.black
        case .Custom: return PlayerPreferences.bgQueueSongNoColor
    }
}
/// 
/// getThemeBgQueueSongNoModifier
/// 
/// - Returns: current song no queue bg color modifier
internal func getThemeBgQueueSongNoModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.bold
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.none
        case .Custom: return PlayerPreferences.bgQueueSongNoModifier
    }
}
/// 
/// getThemeBgQueueColor
/// 
/// - Returns: current queue bg color
internal func getThemeBgQueueColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.blue
        case .Blue: return ConsoleColor.blue
        case .Black: return ConsoleColor.black
        case .Custom: return PlayerPreferences.bgQueueColor
    }
}
/// 
/// getThemeBgQueueModifier
/// 
/// - Returns: current queue bg color modifier
internal func getThemeBgQueueModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.bold
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.none
        case .Custom: return PlayerPreferences.bgQueueModifier
    }
}
/// 
/// getThemeBgTitleColor
/// 
/// - Returns: title bg color
internal func getThemeBgTitleColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.black
        case .Blue: return ConsoleColor.blue
        case .Black: return ConsoleColor.black
        case .Custom: return PlayerPreferences.bgTitleColor
    }
}
/// 
/// getThemeBgTitleModifier
/// 
/// - Returns: title bg color modifier
internal func getThemeBgTitleModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.none
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.none
        case .Custom: return PlayerPreferences.bgTitleModifier
    }
}
/// 
/// getThemeBgSeparatorColor
/// 
/// - Returns: separator bg color
internal func getThemeBgSeparatorColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.black
        case .Blue: return ConsoleColor.blue
        case .Black: return ConsoleColor.black
        case .Custom: return PlayerPreferences.bgSeparatorColor
    }
}
/// 
/// getThemeBgSeparatorModifier
/// 
/// - Returns: separator bg color modifier
internal func getThemeBgSeparatorModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.none
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.none
        case .Custom: return PlayerPreferences.bgSeparatorModifier
    }
}
/// 
/// getThemeFgTitleColor
/// 
/// - Returns: title fg color
internal func getThemeFgTitleColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.yellow
        case .Blue: return ConsoleColor.yellow
        case .Black: return ConsoleColor.yellow
        case .Custom: return PlayerPreferences.fgTitleColor
    }
}
/// 
/// getThemeFgTitleModifier
/// 
/// - Returns: title fg color modifier
internal func getThemeFgTitleModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.bold
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.bold
        case .Custom: return PlayerPreferences.fgTitleModifier
    }
}
/// 
/// getThemeFgSeparatorColor
/// 
/// - Returns: separator fg color
internal func getThemeFgSeparatorColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.green
        case .Blue: return ConsoleColor.green
        case .Black: return ConsoleColor.green
        case .Custom: return PlayerPreferences.fgSeparatorColor
    }
}
/// 
/// getThemeFgSeparatorModifier
/// 
/// - Returns: separator fg color modifier
internal func getThemeFgSeparatorModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.bold
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.bold
        case .Custom: return PlayerPreferences.fgSeparatorModifier
    }
}
/// 
/// getThemeFgQueueSongNoColor
/// 
/// - Returns: separator fg color
internal func getThemeFgQueueSongNoColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.cyan
        case .Blue: return ConsoleColor.cyan
        case .Black: return ConsoleColor.cyan
        case .Custom: return PlayerPreferences.fgQueueSongNoColor
    }
}
/// 
/// getThemeFgQueueSongNoModifier
/// 
/// - Returns: separator fg color modifier
internal func getThemeFgQueueSongNoModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.bold
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.bold
        case .Custom: return PlayerPreferences.fgQueueSongNoModifier
    }
}
/// 
/// getThemeFgQueueColor
/// 
/// - Returns: separator fg color
internal func getThemeFgQueueColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.white
        case .Blue: return ConsoleColor.white
        case .Black: return ConsoleColor.white
        case .Custom: return PlayerPreferences.fgQueueColor
    }
}
/// 
/// getThemeFgQueueModifier
/// 
/// - Returns: separator fg color modifier
internal func getThemeFgQueueModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.bold
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.bold
        case .Custom: return PlayerPreferences.fgQueueModifier
    }
}
/// 
/// getThemeBgCommandLineColor
/// 
/// - Returns: command line bg color
internal func getThemeBgCommandLineColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.black
        case .Blue: return ConsoleColor.blue
        case .Black: return ConsoleColor.black
        case .Custom: return PlayerPreferences.bgCommandLineColor
    }
}
/// 
/// getThemeBgCommandLineModifier
/// 
/// - Returns: command line bg color modifier
internal func getThemeBgCommandLineModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.none
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.none
        case .Custom: return PlayerPreferences.bgCommandLineModifier
    }
}
/// 
/// getThemeFgCommandLineColor
/// 
/// - Returns: separator fg color
internal func getThemeFgCommandLineColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.cyan
        case .Blue: return ConsoleColor.white
        case .Black: return ConsoleColor.cyan
        case .Custom: return PlayerPreferences.fgQueueColor
    }
}
/// 
/// getThemeFgCommandLineModifier
/// 
/// - Returns: separator fg color modifier
internal func getThemeFgCommandLineModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.bold
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.bold
        case .Custom: return PlayerPreferences.fgQueueModifier
    }
}
/// 
/// getThemeBgStatusLineColor
/// 
/// - Returns: status line bg color
internal func getThemeBgStatusLineColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.black
        case .Blue: return ConsoleColor.blue
        case .Black: return ConsoleColor.black
        case .Custom: return PlayerPreferences.bgStatusLineColor
    }
}
/// 
/// getThemeBgStatusLineModifier
/// 
/// - Returns: status line bg color modifier
internal func getThemeBgStatusLineModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.none
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.none
        case .Custom: return PlayerPreferences.bgStatusLineModifier
    }
}
/// 
/// getThemeFgStatusLineColor
/// 
/// - Returns: separator fg color
internal func getThemeFgStatusLineColor() -> ConsoleColor {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColor.white
        case .Blue: return ConsoleColor.white
        case .Black: return ConsoleColor.white
        case .Custom: return PlayerPreferences.fgStatusLineColor
    }
}
/// 
/// getThemeFgStatusLineModifier
/// 
/// - Returns: separator fg color modifier
internal func getThemeFgStatusLineModifier() -> ConsoleColorModifier {
    switch PlayerPreferences.colorTheme {
        case .Default: return ConsoleColorModifier.bold
        case .Blue: return ConsoleColorModifier.bold
        case .Black: return ConsoleColorModifier.bold
        case .Custom: return PlayerPreferences.fgStatusLineModifier
    }
}
///
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
//
// Represent MainWindow fields pos and sizes.
//
internal class MainWindowLayout {
    // cols
    let songNoCols: Int = g_fieldWidthSongNo
    var artistCols: Int = 0
    var titleCols: Int = 0
    let durationCols: Int = g_fieldWidthDuration    
    // x
    let songNoX: Int = 1    
    var artistX: Int = 0
    var titleX: Int = 0
    var durationX: Int = 0

    func getTotalCols() -> Int {
        return self.songNoCols + self.durationCols + self.artistCols + self.titleCols
    }

    static func get() -> MainWindowLayout {
            //
            // calculate cols
            //
            let layout: MainWindowLayout = MainWindowLayout()
            let ncalc: Int = Int(floor(Double(g_cols - layout.songNoCols - layout.durationCols) / 2.0))
            layout.artistCols = ncalc
            layout.titleCols =  ncalc

            var total: Int = layout.getTotalCols()
            if total < g_cols {
                while total < g_cols {
                    layout.titleCols += 1
                    total = layout.getTotalCols()
                }
            }
            else if total > g_cols {
                while total > g_cols {
                    layout.titleCols -= 1
                    total = layout.getTotalCols()
                }
            }

            //
            // calculate x
            //
            layout.artistX = layout.songNoCols + 1
            layout.titleX = layout.artistX + layout.artistCols 
            layout.durationX = layout.titleX + layout.titleCols 
            return layout
    }
}