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