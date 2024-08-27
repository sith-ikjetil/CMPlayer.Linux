import Foundation
import Cao
import Casound

///
/// Does an integrity check.
/// 
func PrintAndExecuteIntegrityCheck() {
    print("CMPlayer Integrity Check")
    print("========================")
    PrintAndExecuteOutputDevices()
    //PrintAndExecuteLibraryFiles()
    PrintAndExecutePlayerHomeDirectory()
    PrintAndExecutePlayerLibrary()
    PrintAndExecutePlayerPreferences()
}
///
/// Prints information about output devices.
/// 
func PrintAndExecuteOutputDevices() {        
    print("Audio Output(ao):")
    printAoInfo()    
    print("")
    print("ALSA:")
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
        print(" > (e): Failed to retrieve audio driver information.")
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
        print(" > (e): No sound cards found: '\(String(cString: snd_strerror(err)))'")
        return
    }    

    while card >= 0 {
        // Open the control interface for the card
        let cardName = "hw:\(card)"
        if snd_ctl_open(&ctlHandle, cardName, 0) < 0 {
            print(" > (e): Error opening control interface: '\(String(cString: snd_strerror(err)))'")
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
            print(" > (e): Error getting card information: '\(String(cString: snd_strerror(err)))'")
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
/// Prints some info about cmplayer's home directory and its files.
/// 
func PrintAndExecutePlayerHomeDirectory() {
    print("Player Home:")
    let path = PlayerDirectories.consoleMusicPlayerDirectory
    if FileManager.default.fileExists(atPath: path.path) {
        print(" > (i): Found at: \(path.path)")

        let pathLibrary = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLibrary.filename, isDirectory: false)
        if FileManager.default.fileExists(atPath: pathLibrary.path) {
            print(" > \(PlayerLibrary.filename)     found")
        }
        else {
            print(" > \(PlayerLibrary.filename)     NOT found")
        }
    
        let pathLog = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLog.filename, isDirectory: false)
        if FileManager.default.fileExists(atPath: pathLog.path) {
            print(" > \(PlayerLog.filename)         found")
        }
        else {
            print(" > \(PlayerLog.filename)         NOT found")
        }
    
        let pathPref = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerPreferences.filename, isDirectory: false)
        if FileManager.default.fileExists(atPath: pathPref.path) {
            print(" > \(PlayerPreferences.filename) found")
        }
        else {
            print(" > \(PlayerPreferences.filename) NOT found")
        }
    }
    else {
        print(" > (e): Did not find player home at: \(path.path)")
    }    
    print("")
}
///
/// Prints some statistics about player library.
/// 
func PrintAndExecutePlayerLibrary() {
    print("Player Library:")    
    do {        
        let fileUrl: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerLibrary.filename, isDirectory: false)
        if FileManager.default.fileExists(atPath: fileUrl.path) {
            let lib: PlayerLibrary = PlayerLibrary()
            try lib.load()        
            print(" > Number of valid entries              \(lib.library.count)")    
            print(" > Number of distinct artists           \(g_artists.count)") 
            print(" > Number of distinct genres            \(g_genres.count)")    
            print(" > Number of distinct recording years   \(g_recordingYears.count)")                
        }
        else {
            print(" > (e): Could not find library.")    
        }
    }
    catch let error as CmpError {
        print(" > (e): Could not load library. Message: '\(error.message)'")
    }
    catch {
        print(" > (e): Unknown error. Could not load library. Message: '\(error)'")
    }

    print("")
}
///
/// Prints some info on cmplayers preferences if file exists.
/// 
func PrintAndExecutePlayerPreferences()
{
    print("Player Preferences:")        
    let path: URL = PlayerDirectories.consoleMusicPlayerDirectory.appendingPathComponent(PlayerPreferences.filename, isDirectory: false)
    if FileManager.default.fileExists(atPath: path.path) {
        PlayerPreferences.loadPreferences(path)
        print(" > musicRootPath:")
        for rp in PlayerPreferences.musicRootPath {
            print("   > \(rp)")
        }
        print(" > exclusionPaths:")
        for ep in PlayerPreferences.exclusionPaths {
            print("   > \(ep)")
        }
        print(" > musicFormats             \(PlayerPreferences.musicFormats)")            
        print(" > autoplayOnStartup        \(PlayerPreferences.autoplayOnStartup)")
        print(" > crossfadeSongs           \(PlayerPreferences.crossfadeSongs)")
        print(" > crossfadeTimeInSeconds   \(PlayerPreferences.crossfadeTimeInSeconds)")
        print(" > viewType                 \(PlayerPreferences.viewType.rawValue)" )
        print(" > colorTheme:              \(PlayerPreferences.colorTheme.rawValue)")
        print(" > outputSoundLibrary       \(PlayerPreferences.outputSoundLibrary.rawValue)")
        print(" > logInformation           \(PlayerPreferences.logInformation)")
        print(" > logWarning               \(PlayerPreferences.logWarning)")
        print(" > logError                 \(PlayerPreferences.logError)")
        print(" > logDebug                 \(PlayerPreferences.logDebug)")
        print(" > logOther                 \(PlayerPreferences.logOther)")            
    }
    else {
        print(" > (e): Could not find preferences.")    
    }

    print("")
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

    print("Libraries (.so):")
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
