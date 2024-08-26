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

        let arg1: String = CommandLine.arguments[1].lowercased()
        switch arg1 {
            case "--integrity-check": return CommandLineHandler.execute__integrity_check()
            case "--version": return CommandLineHandler.execute__version()
            case "--purge": return CommandLineHandler.execute__purge()
            case "--set-output-api-ao": return CommandLineHandler.execute__set_output_api_ao()
            case "--set-output-api-alsa": return CommandLineHandler.execute__set_output_api_alsa()
            case "--get-output-api": return CommandLineHandler.execute__get_output_api()
            default: return CommandLineHandler.execute__help();
        }        
    }
    ///
    /// execute --integrity-check
    /// 
    private static func execute__integrity_check()
    {
        PlayerPreferences.ensureLoadPreferences()                    
        ao_initialize()  // initialize libao
        PrintAndExecuteIntegrityCheck()            
        ao_shutdown()    // shutdown ao
        exit(ExitCodes.SUCCESS.rawValue)   
    }
    ///
    /// execute --version
    /// 
    private static func execute__version()
    {
        print("CMPlayer v\(g_versionString)")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --purge
    /// 
    private static func execute__purge()
    {
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
    ///
    /// execute --set-output-api-ao
    /// 
    private static func execute__set_output_api_ao() 
    {
        print("CMPlayer Set Output")
        print("=========================")
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.outputSoundLibrary = OutputSoundLibrary.ao
        PlayerPreferences.savePreferences()
        print("(i): Output sound set to ao")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --set-output-api-alsa
    /// 
    private static func execute__set_output_api_alsa() 
    {
        print("CMPlayer Set Output")
        print("=========================")
        PlayerPreferences.ensureLoadPreferences()
        PlayerPreferences.outputSoundLibrary = OutputSoundLibrary.alsa
        PlayerPreferences.savePreferences()
        print("(i): Output sound set to alsa")
        print("")
        exit(ExitCodes.SUCCESS.rawValue)
    }
    ///
    /// execute --get-output-api
    /// 
    private static func execute__get_output_api()
    {
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
    ///
    /// execute --help and default.
    /// 
    private static func execute__help()
    {
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
}// internal class CommandLineHandler