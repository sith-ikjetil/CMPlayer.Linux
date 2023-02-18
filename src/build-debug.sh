#!/bin/bash                                                                                                                  
#: Title       : build-debug.sh                                                                                              
#: Date        : 2023-02-17                                                                                                  
#: Author      : Kjetil Kristoffer Solberg <post@ikjetil.no>                                                                 
#: Version     : 1.0                                                                                                         
#: Description : Builds CMPlayer.Linux.                                                                                                
echo "Compiling CMPlayer.Linux ..."
echo "> using debug build <"

swiftc -g \
        ./main.swift \
        ./Player.swift \
        ./Misc/PlayerCommand.swift \
        ./Misc/PlayerDirectories.swift \
        ./Misc/PlayerLibrary.swift \
        ./Misc/PlayerPreferences.swift \
        ./Misc/SongEntry.swift \
        ./Misc/Util.swift \
        ./Console/Console.swift \
        ./Console/ConsoleKey.swift \
        ./Console/ConsoleKeyboardHandler.swift \
        ./Windows/AboutWindow.swift \
        ./Windows/ArtistWindow.swift \
        ./Windows/ErrorWindow.swift \
        ./Windows/GenreWindow.swift \
        ./Windows/HelpWindow.swift \
        ./Windows/InfoWindow.swift \
        ./Windows/InitializeWindow.swift \
        ./Windows/MainWindow.swift \
        ./Windows/ModeWindow.swift \
        ./Windows/PreferencesWindow.swift \
        ./Windows/SearchWindow.swift \
        ./Windows/SetupWindow.swift \
        ./Windows/YearWindow.swift

if [[ $? -eq 0 ]]
then
    echo "> CMPlayer.Linux build ok <"
else
    echo "> CMPlayer.Linux build error <"
fi

echo "> build process complete <"

