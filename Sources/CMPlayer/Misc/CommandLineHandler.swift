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
    static var state: CommandLineHandlerState? = nil
    static func processCommandLine()
    {        
        guard CommandLine.argc >= 2 else {            
            return
        }

        if CommandLine.arguments[1].lowercased() == "--integrity-check" {
            PlayerPreferences.ensureLoadPreferences()                    
            ao_initialize()  // initialize libao
            PrintAndExecuteIntegrityCheck()            
            ao_shutdown()    // shutdown ao
            exit(ExitCodes.SUCCESS.rawValue)   
        }
        else if CommandLine.arguments[1].lowercased() == "--version" {
            print("CMPlayer v\(g_versionString)")
            print("")
            exit(ExitCodes.SUCCESS.rawValue)
        }
        else if CommandLine.arguments[1].lowercased() == "--purge" {
            print("CMPlayer Purge")
            print("=========================")
            if PlayerDirectories.purge() {
                print("(i): Purge success")
            }
            else {
                print("(e): Purge error")
            }
            print("")
            exit(ExitCodes.SUCCESS.rawValue)
        }
        else if CommandLine.arguments[1].lowercased() == "--set-output-api-ao" {
            print("CMPlayer Set Output")
            print("=========================")
            PlayerPreferences.ensureLoadPreferences()
            PlayerPreferences.outputSoundLibrary = OutputSoundLibrary.ao
            PlayerPreferences.savePreferences()
            print("(i): Output sound set to ao")
            print("")
            exit(ExitCodes.SUCCESS.rawValue)
        }
        else if CommandLine.arguments[1].lowercased() == "--set-output-api-alsa" {
            print("CMPlayer Set Output")
            print("=========================")
            PlayerPreferences.ensureLoadPreferences()
            PlayerPreferences.outputSoundLibrary = OutputSoundLibrary.alsa
            PlayerPreferences.savePreferences()
            print("(i): Output sound set to alsa")
            print("")
            exit(ExitCodes.SUCCESS.rawValue)
        }
        else if CommandLine.arguments[1].lowercased() == "--get-output-api" {
            PlayerPreferences.ensureLoadPreferences()
            print("CMPlayer Get Output")
            print("=========================")
            if PlayerPreferences.outputSoundLibrary == OutputSoundLibrary.ao {
                print("(i): Output api is: ao")
            }
            else if PlayerPreferences.outputSoundLibrary == OutputSoundLibrary.alsa {
                print("(i): Output api is: alsa")
            }                   
            print("")
            exit(ExitCodes.SUCCESS.rawValue)
        }
        else {
            print("CMPlayer Help")
            print("=========================")
            print("Usage: cmplayer <options>")
            print("<options>")
            print(" --help                = show this help screen")
            print(" --version             = show version numbers")
            print(" --integrity-check     = do an integrity check")
            print(" --purge               = remove all stored data")
            print(" --set-output-api-ao   = sets audio output api to libao (ao)")
            print(" --set-output-api-alsa = sets audio output api to libasound (alsa)")
            print(" --get-output-api      = gets audio output api")
            print("")        
            exit(ExitCodes.SUCCESS.rawValue)
        }
    }
}