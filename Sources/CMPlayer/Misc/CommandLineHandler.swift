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
        print("")        
        exit(ExitCodes.SUCCESS.rawValue)
    }    
}// internal class CommandLineHandler