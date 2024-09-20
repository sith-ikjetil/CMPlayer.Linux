//
//  CommandLineHandler.swift
//
//  (i): Handles command line parameters execution.
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
///
/// import
/// 
import Foundation
import Cao
import Casound
///
/// State class for CommandLineArguments handling
/// of command line arguments. Can be used through
/// ComamndLineHandler.state variable if there is data
/// needed when normal operations commence.
/// 
internal class CommandLineHandlerState {

}
///
/// Handler for command line arguments. 
/// Executes exit() when there is no further loading to take place
/// Just returnes when normal loading is to commence.
/// CommandLineHandler.state is where further loading might find
/// data needed from command line parsing, such as arguments for runtime effects.
/// 
internal class CommandLineHandler {
    ///
    /// static variables
    ///
    static var state: CommandLineHandlerState? = nil
    ///
    /// static functions
    ///
    static func processCommandLine()
    {   
        // guard command line count have minimum of arguments     
        guard CommandLine.argc >= 2 else {            
            // else nothing to do, just return
            return
        }
        // create constant arg1 to CommandLine arguments 1
        let arg1: String = CommandLine.arguments[1].lowercased()
        // switch arg1
        switch arg1 {
            case "--integrity-check": return CommandLineHandler.execute__integrity_check()
            case "--version": return CommandLineHandler.execute__version()
            case "--purge": return CommandLineHandler.execute__purge()
            case "--set-output-api-ao": return CommandLineHandler.execute__set_output_api_ao()
            case "--set-output-api-alsa": return CommandLineHandler.execute__set_output_api_alsa()
            case "--get-output-api": return CommandLineHandler.execute__get_output_api()
            case "--set-max-log-n": return CommandLineHandler.execute__set_max_log_n()
            case "--get-max-log-n": return CommandLineHandler.execute__get_max_log_n()
            case "--set-max-history-n": return CommandLineHandler.execute__set_max_history_n()
            case "--get-max-history-n": return CommandLineHandler.execute__get_max_history_n()
            case "--get-format": return CommandLineHandler.execute__get_format()
            case "--add-format": return CommandLineHandler.execute__add_format()
            case "--remove-format": return CommandLineHandler.execute__remove_format()
            case "--log-information-on": return CommandLineHandler.execute__log_information_on()
            case "--log-information-off": return CommandLineHandler.execute__log_information_off()
            case "--log-warning-on": return CommandLineHandler.execute__log_warning_on()
            case "--log-warning-off": return CommandLineHandler.execute__log_warning_off()
            case "--log-error-on": return CommandLineHandler.execute__log_error_on()
            case "--log-error-off": return CommandLineHandler.execute__log_error_off()
            case "--log-debug-on": return CommandLineHandler.execute__log_debug_on()
            case "--log-debug-off": return CommandLineHandler.execute__log_debug_off()
            case "--log-other-on": return CommandLineHandler.execute__log_other_on()
            case "--log-other-off": return CommandLineHandler.execute__log_other_off()
            case "--get-log-status": return CommandLineHandler.execute__get_log_status()
            default: return CommandLineHandler.execute__help();
        }
    }
    ///
    /// execute --integrity-check
    /// 
    private static func execute__integrity_check()
    {
        // ensure directories exists
        PlayerDirectories.ensureDirectoriesExistence()
        // load preferences
        PlayerPreferences.ensureLoadPreferences()                    
        // initialize ao
        ao_initialize()  // initialize libao 
        // print header
        print("CMPlayer Integrity Check")
        // print separator
        print("========================")
        // print output devices ao and alsa
        PrintAndExecuteOutputDevices()
        // print new line>
        print("")
        // print about library files needed to run
        // PrintAndExecuteLibraryFiles()
        // print new line
        // print("")
        // print info about home directory
        PrintAndExecutePlayerHomeDirectory()
        // print new line>
        print("")
        // print info about library
        PrintAndExecutePlayerLibrary()
        // print new line>
        print("")
        // print info about player preferences
        PrintAndExecutePlayerPreferences()
        // print new line>
        print("")
        // shutdown ao
        ao_shutdown()
        // exit application
        exit(ExitCodes.SUCCESS.rawValue)   
    }
    ///
    /// execute --version
    /// 
    private static func execute__version()
    {        
        // create a closure that gathers distribution name
        let readLinuxReleaseInfo: () -> String? = {
            if let text = try? String(contentsOfFile: "/etc/os-release") {
                let pattern = "PRETTY_NAME=\"(.*)\""
                let regex = try? NSRegularExpression(pattern: pattern)
    
                // Search for the first match
                if let match = regex?.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
                    // Extract the matched range for the first number
                    if let range = Range(match.range(at: 1), in: text) {
                        return String(text[range])
                    }
                }                
            }
            return nil
        }
        // print out version
        print("CMPlayer version \(g_versionString)")
        // if our closure found a distro name
        if let distro = readLinuxReleaseInfo() {
            // print distro name
            print("Distribution: \(distro)")
        }
        // print new line
        print("")
        // exist application
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --purge
    /// 
    private static func execute__purge()
    {
        // print header
        print("CMPlayer: --purge")
        // print separator
        print("=========================")
        // do purge
        if PlayerDirectories.purge() {
            // purge successfull
            // print message
            print("(i): Purge success")
        }
        else {
            // purge not successfull
            // print message
            print("(e): Purge error")
        }
        // print new line
        print("")
        // exit application
        exit(ExitCodes.SUCCESS.rawValue)
    }  
    ///
    /// execute --set-output-api-ao
    /// 
    private static func execute__set_output_api_ao() 
    {
        // print header
        print("CMPlayer: --set-output-api-ao")
        // print separator
        print("=============================")
        // ensure directories exists
        PlayerDirectories.ensureDirectoriesExistence()
        // ensure load preferences
        PlayerPreferences.ensureLoadPreferences()
        // set preferences outputSoundLibrary to ao
        PlayerPreferences.outputSoundLibrary = OutputSoundLibrary.ao
        // save preferences
        PlayerPreferences.savePreferences()
        // print result
        print("(i): Output sound set to ao")
        // print new line
        print("")
        // exist application
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --set-output-api-alsa
    /// 
    private static func execute__set_output_api_alsa() 
    {
        // print header
        print("CMPlayer: --set-output-api-alsa")
        // print separator
        print("===============================")
        // ensure directories exists
        PlayerDirectories.ensureDirectoriesExistence()
        // ensure load preferences
        PlayerPreferences.ensureLoadPreferences()
        // set preferences outputSoundLibrary to alsa
        PlayerPreferences.outputSoundLibrary = OutputSoundLibrary.alsa
        // save preferences
        PlayerPreferences.savePreferences()
        // print result
        print("(i): Output sound set to alsa")
        // print new line
        print("")
        // exit application
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --get-output-api
    /// 
    private static func execute__get_output_api()
    {        
        // print header
        print("CMPlayer: --get-output-api")
        // print separator
        print("==========================")
        // ensure directory exists
        PlayerDirectories.ensureDirectoriesExistence()
        // ensure log preferences
        PlayerPreferences.ensureLoadPreferences()
        // if preferences outputSoundLibrary is ao
        if PlayerPreferences.outputSoundLibrary == OutputSoundLibrary.ao {
            // print result ao
            print("(i): Output api is: ao")
        }
        // else if preferences outputSoundLibrary is alsa
        else if PlayerPreferences.outputSoundLibrary == OutputSoundLibrary.alsa {
            // print result alsa
            print("(i): Output api is: alsa")
        }                   
        // print new line
        print("")
        // exit application
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --set-max-log-size
    /// 
    private static func execute__set_max_log_n()
    {
        // if command line arguments count is less than 3
        if CommandLine.argc < 3 {
            // error then execute__help handler
            CommandLineHandler.execute__help()
            // return
            return
        }        
        // print header        
        print("CMPlayer: --set-max-log-n")
        // print separator
        print("=========================")
        // ensure directories exist
        PlayerDirectories.ensureDirectoriesExistence()
        // ensure load preferences
        PlayerPreferences.ensureLoadPreferences()
        // if command line arguments 2 is a number
        if let n = Int(CommandLine.arguments[2]) {
            // if number is valid
            if n >= 25 && n <= 1000 {
                // set preferences logMaxEntries to n
                PlayerPreferences.logMaxEntries = n
                // save preferences
                PlayerPreferences.savePreferences()
                // print result
                print("(i): Max log entries set to: \(n)")
            }
            else {
                // print error
                print("(e): Invalid max log entries: \(n).")
                // print explanation
                print("(i): Must be a number between 25 and 1000.")
            }
        }
        // else invalid command line argument 2
        else {
            // print error
            print("(e): Invalid max log entries.")
            // print explanation
            print("(i): Must be a number between 25 and 1000.")
        }
        // print new line
        print("")
        // exit application
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --set-max-log-size
    /// 
    private static func execute__get_max_log_n()
    {   
        // print header     
        print("CMPlayer: --get-max-log-n")
        // print separator
        print("=========================")
        // ensure direcetories exists
        PlayerDirectories.ensureDirectoriesExistence()
        // ensure load preferences
        PlayerPreferences.ensureLoadPreferences()
        // print result
        print("(i): Max log entries is: \(PlayerPreferences.logMaxEntries)")
        // print new line
        print("")
        // exit application
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --set-max-log-size
    /// 
    private static func execute__set_max_history_n()
    {
        // if command line arguments count is less than 3
        if CommandLine.argc < 3 {
            // error then call execute__help handler
            CommandLineHandler.execute__help()
            // return
            return
        }                
        // print header
        print("CMPlayer: --set-max-history-n")
        // print separator
        print("=============================")
        // ensure directories exists
        PlayerDirectories.ensureDirectoriesExistence()
        // ensure load preferences
        PlayerPreferences.ensureLoadPreferences()
        // if command line argument 2 is a number
        if let n = Int(CommandLine.arguments[2]) {
            // if n is a valid number
            if n >= 25 && n <= 1000 {
                // set preferences historyMaxEntries
                PlayerPreferences.historyMaxEntries = n
                // save preferences
                PlayerPreferences.savePreferences()
                // print result
                print("(i): Max history entries set to: \(n)")
            }
            // else if n is invalid
            else {
                // print error
                print("(e): Invalid max history entries: \(n).")
                // print explanation
                print("(i): Must be a number between 25 and 1000.")
            }
        }
        // else command line argument 2 is not a number
        else {
            // print error
            print("(e): Invalid max history entries.")
            // print explanation
            print("(i): Must be a number between 25 and 1000.")
        }
        // print new line
        print("")
        // exit application
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --set-max-log-size
    /// 
    private static func execute__get_max_history_n()
    {        
        // print header
        print("CMPlayer: --get-max-history-n")
        // print separator
        print("=============================")
        // ensure directories exists
        PlayerDirectories.ensureDirectoriesExistence()
        // ensure load preferences
        PlayerPreferences.ensureLoadPreferences()
        // print result
        print("(i): Max history entries is: \(PlayerPreferences.historyMaxEntries)")
        // print new line
        print("")
        // exit application
        exit(ExitCodes.SUCCESS.rawValue)
    }
    //
    // execute execute__get_formats()
    //
    private static func execute__get_format()
    {
        // ensure load preferences
        PlayerPreferences.ensureLoadPreferences()
        // print header
        print("CMPlayer: --get-format")
        // print separator
        print("======================")        
        let formats = PlayerPreferences.musicFormats.split(separator: ";")
        for fmt in formats {
            print(" \(fmt)")
        }        
        // exit application
        exit(ExitCodes.SUCCESS.rawValue);
    }
    ///
    /// execute --add-format
    ///
    private static func execute__add_format()
    {
        // if command line arguments count is less than 3
        if CommandLine.argc < 3 {
            // error then call execute__help handler
            CommandLineHandler.execute__help()
            // return
            return
        }                
        // get new format from command line arguments
        let newFormat: String = CommandLine.arguments[2]
        // guard agains invalid format
        guard newFormat.count > 1 && newFormat.first == "." && !newFormat.contains(";") else {
            // error then call execute__help handler
            CommandLineHandler.execute__help()
            // return
            return
        }
        // ensure load preferences
        PlayerPreferences.ensureLoadPreferences()        
        // print header
        print("CMPlayer: --add-format")
        // print separator
        print("======================")
        // split music formats to array
        let formats = PlayerPreferences.musicFormats.split(separator: ";")
        // check if newFormat already is in music formats
        for fmt in formats {
            if fmt == newFormat {
                CommandLineHandler.execute__help()
                return;
            }
        }
        // for each of them
        for fmt in formats {
            // print the format out
            print(" \(fmt)")
        }
        // add the new format to PlayerPreferences.musicFormats
        PlayerPreferences.musicFormats = PlayerPreferences.musicFormats + ";" + newFormat
        // save preferences
        PlayerPreferences.savePreferences()
        // print out new format, indicated by (new)
        print(" \(newFormat) (new)")
        // exit application
        exit(ExitCodes.SUCCESS.rawValue);
    }
    ///
    /// execute --remove-format
    /// 
    private static func execute__remove_format()
    {
         // if command line arguments count is less than 3
        if CommandLine.argc < 3 {
            // error then call execute__help handler
            CommandLineHandler.execute__help()
            // return
            return
        }           
        // get command line argument     
        let removeFormat: String = CommandLine.arguments[2]
        // guard format is ok
        guard removeFormat.count > 1 && removeFormat.first == "." && !removeFormat.contains(";") else {
            // error then call execute__help handler
            CommandLineHandler.execute__help()
            // return
            return
        }
        // ensure load preferences
        PlayerPreferences.ensureLoadPreferences()        
        // print header
        print("CMPlayer: --remove-format")
        // print separator
        print("=========================")
        // get musicformats as an array
        var formats = PlayerPreferences.musicFormats.split(separator: ";")
        // for each format in array
        for i in 0..<formats.count  {
            // if removeFormat found
            if formats[i] == removeFormat {
                // remove format
                formats.remove(at: i)
                // break for
                break
            }
        }                
        // create a new music format string
        var modifiedFormats: String = "";
        // for each format in formats
        for fmt in formats {
            // if we are at format #2++
            if modifiedFormats.count > 0 {
                // add format separator
                modifiedFormats += ";"
            }
            // add current format to modifiedFormats
            modifiedFormats += fmt
        }
        // set modifiedFormats as PlayerPreferences.musicFormats
        PlayerPreferences.musicFormats = modifiedFormats
        // save formats
        PlayerPreferences.savePreferences()                
        // loop through formats
        for fmt in formats {
            // print formats out
            print(" \(fmt)")
        }
        // exit application
        exit(ExitCodes.SUCCESS.rawValue);
    }
    ///
    /// execute --log-information-on
    ///
    private static func execute__log_information_on() {
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.logInformation = true
        PlayerPreferences.savePreferences()
        print("CMPlayer: --log-information-on")
        print("==========================")
        print(" Information : \(PlayerPreferences.logInformation)")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --log-information-off
    ///
    private static func execute__log_information_off() {
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.logInformation = false
        PlayerPreferences.savePreferences()
        print("CMPlayer: --log-information-off")
        print("==========================")
        print(" Information : \(PlayerPreferences.logInformation)")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --log-warning-on
    ///
    private static func execute__log_warning_on() {
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.logWarning = true
        PlayerPreferences.savePreferences()
        print("CMPlayer: --log-warning-on")
        print("==========================")
        print(" Warning     : \(PlayerPreferences.logWarning)")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --log-warning-off
    ///
    private static func execute__log_warning_off() {
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.logWarning = false
        PlayerPreferences.savePreferences()
        print("CMPlayer: --log-warning-off")
        print("==========================")
        print(" Warning     : \(PlayerPreferences.logWarning)")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --log-error-on
    ///
    private static func execute__log_error_on() {
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.logError = true
        PlayerPreferences.savePreferences()
        print("CMPlayer: --log-error-on")
        print("==========================")
        print(" Error       : \(PlayerPreferences.logError)")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --log-error-off
    ///
    private static func execute__log_error_off() {
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.logError = false
        PlayerPreferences.savePreferences()
        print("CMPlayer: --log-error-off")
        print("==========================")
        print(" Error       : \(PlayerPreferences.logError)")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --log-debug-on
    ///
    private static func execute__log_debug_on() {
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.logDebug = true
        PlayerPreferences.savePreferences()
        print("CMPlayer: --log-debug-on")
        print("==========================")
        print(" Debug       : \(PlayerPreferences.logDebug)")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --log-debug-off
    ///
    private static func execute__log_debug_off() {
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.logDebug = false
        PlayerPreferences.savePreferences()
        print("CMPlayer: --log-debug-off")
        print("==========================")
        print(" Debug       : \(PlayerPreferences.logDebug)")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --log-other-on
    ///
    private static func execute__log_other_on() {
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.logOther = true
        PlayerPreferences.savePreferences()
        print("CMPlayer: --log-other-on")
        print("==========================")
        print(" Other       : \(PlayerPreferences.logOther)")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --log-other-off
    ///
    private static func execute__log_other_off() {
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.logOther = false
        PlayerPreferences.savePreferences()
        print("CMPlayer: --log-other-off")
        print("==========================")
        print(" Other       : \(PlayerPreferences.logOther)")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --get-log-status
    ///
    private static func execute__get_log_status() {
        PlayerPreferences.ensureLoadPreferences()
        print("CMPlayer: --get-log-status")
        print("==========================")        
        print(" Information : \(PlayerPreferences.logInformation)")
        print(" Warning     : \(PlayerPreferences.logWarning)")
        print(" Error       : \(PlayerPreferences.logError)")
        print(" Debug       : \(PlayerPreferences.logDebug)")
        print(" Other       : \(PlayerPreferences.logOther)")        
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --help and default.
    /// 
    private static func execute__help()
    {
        print("CMPlayer: --help")
        print("================")
        print("Usage: cmplayer <options>")
        print("<options>")
        print(" --help                    = show this help screen")
        print(" --version                 = show version numbers")
        print(" --integrity-check         = do an integrity check")
        print(" --purge                   = remove all stored data")
        print(" --set-output-api-ao       = sets audio output api to libao (ao)")
        print(" --set-output-api-alsa     = sets audio output api to libasound (alsa)")
        print(" --get-output-api          = gets audio output api")
        print(" --set-max-log-n <max>     = sets max log entries [25,1000]")
        print(" --get-max-log-n           = gets max log entries")
        print(" --set-max-history-n <max> = sets max history entries [25,1000]")
        print(" --get-max-history-n       = gets max history entries")
        print(" --get-format              = gets music formats to try and play")
        print(" --add-format <.ext>       = adds a format to music formats to play <extension>")
        print(" --remove-format <.ext>    = removes a format from music formats <extension>")
        print(" --log-information-on      = turn on information logging")
        print(" --log-information-off     = turn off information logging")
        print(" --log-warning-on          = turn on warning logging")
        print(" --log-warning-off         = turn off warning logging")
        print(" --log-error-on            = turn on error logging")
        print(" --log-error-off           = turn off error logging")
        print(" --log-debug-on            = turn on debug logging")
        print(" --log-debug-off           = turn off debug logging")
        print(" --log-other-on            = turn on other logging")
        print(" --log-other-off           = turn off other logging")
        print(" --get-log-status          = gets log status")
        print("")        
        exit(ExitCodes.SUCCESS.rawValue)
    }    
}// internal class CommandLineHandler