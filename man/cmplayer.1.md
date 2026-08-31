% cmplayer(1) cmplayer 1.6
% Written by Kjetil Kristoffer Solberg
% August 2026

# NAME
cmplayer - console music player

# SYNOPSIS
**cmplayer** [*OPTIONS*]  

# DESCRIPTION
Plays music through terminal window. You can resize the window and search for music  
and have a queue of music. All music is expected to be locally available music files.

# OPTIONS
**-\-help**                    = show this help screen  
**-\-version**                 = show version numbers  
**-\-integrity-check**         = do an integrity check  
**-\-purge**                   = remove all stored data  
**-\-set-output-api-ao**       = sets audio output api to libao (ao)  
**-\-set-output-api-alsa**     = sets audio output api to libasound (alsa)  
**-\-get-output-api**          = gets audio output api  
**-\-set-max-log-n <max>**     = sets max log entries [25,1000]  
**-\-get-max-log-n**           = gets max log entries  
**-\-set-max-history-n <max>** = sets max history entries [25,1000]  
**-\-get-max-history-n**       = gets max history entries  
**-\-get-format**              = gets music formats to try and play  
**-\-add-format <.ext>**       = adds a format to music formats to play <extension>  
**-\-remove-format <.ext>**    = removes a format from music formats <extension>  
**-\-log-information-on**      = turn on information logging  
**-\-log-information-off**     = turn off information logging  
**-\-log-warning-on**          = turn on warning logging  
**-\-log-warning-off**         = turn off warning logging  
**-\-log-error-on**            = turn on error logging  
**-\-log-error-off**           = turn off error logging  
**-\-log-debug-on**            = turn on debug logging  
**-\-log-debug-off**           = turn off debug logging  
**-\-log-other-on**            = turn on other logging  
**-\-log-other-off**           = turn off other logging  
**-\-get-log-status**          = gets log status  

# IN APP COMMANDS
**\<song no\>** adds song no to playlist.  
**exit, quit, q** exits application.  
**next, skip, n, s, TAB-key** plays next song.  
**play, p** plays music.  
**pause, p** pauses music.  
**resume** resumes music playback.  
**search [\<words\>]** searches artist and title for a match. Case insensitive.  
**search artist [\<words\>]** searches artist for a match. Case insensitive.  
**search title [\<words\>]** searches title for a match. Case insensitive.  
**search album [\<words\>]** searches album name for a match. Case insensitive.  
**search genre [\<words\>]** searches all music in genre for matches. Case insensitive.  
**search year [\<year\>]** searches all music in release years for matches.  
**mode off** clears mode playback. Playback now from entire music library.  
**help** shows help information.  
**pref** shows preferences information.  
**about** shows about information.  
**genre** shows all genre information and statistics.  
**year** shows all year information and statistics.  
**mode** shows current mode information and statistics.  
**repaint** clears and repaints the entire console window.  
**add mrp \<path\>** adds the path to music root paths.  
**remove mrp \<path\>** removes the path from music root paths.  
**clear mrp** clears all paths from music root paths.  
**add exp \<path\>** adds the path to exclusion paths.  
**remoove exp \<path\>** removes the path from exclusion paths.  
**clear exp** clears all paths from exclusion paths.  
**set cft \<seconds\>** sets the crossfade time in seconds (1-10 seconds).  
**enable crossfade** enables crossfade.  
**disable crossfade** disables crossfade.  
**enable aos** enables playing on application startup.  
**disable aos** disables playing on application startup.  
**rebuild songno** rebuilds song numbers  
**goto \<mm:ss\>** moves playback point to minutes (mm) and seconds (ss) of current song.  
**replay** start playing current song from beginning again.  
**reinitialize <1>** reinitializes library (optional 1 = also rebuild song no.  
**info** shows information about first song in playlist.  
**info \<songno\>** show information about song with given song number.  
**set viewtype \<type\>** sets view type. Can be 'default' or 'details'.  
**set theme \<name\>** sets theme. Name can be 'default', 'blue', 'black' or 'custom'.  
**clear history** clears command history.  
**set custom-theme fgHeaderColor \<color\> \<bold/none\>** sets foreground color of header text.  
**set custom-theme bgHeaderColor \<color\> \<bold/none\>** sets background color of header text.  
**set custom-theme fgTitleColor \<color\> \<bold/none\>** sets foreground color of title text.   
**set custom-theme bgTitleColor \<color\> \<bold/none\>** sets background color of title text.  
**set custom-theme fgSeparatorColor \<color\> \<bold/none\>** sets foreground color of separator line.   
**set custom-theme bgSeparatorColor \<color\> \<bold/none\>** sets background color of separator line.  
**set custom-theme fgQueueColor \<color\> \<bold/none\>** sets foreground color of queue text.  
**set custom-theme bgQueueColor \<color\> \<bold/none\>** sets background color of queue text.  
**set custom-theme fgQueueSongNoColor \<color\> \<bold/none\>** sets foreground color of song no in queue text.  
**set custom-theme bgQueueSongNoColor \<color\> \<bold/none\>** sets background color of song no in queue text.  
**set custom-theme fgCommandLineColor \<color\> \<bold/none\>** sets foreground color of command line text.  
**set custom-theme bgCommandLineColor \<color\> \<bold/none\>** sets background color of command line text.  
**set custom-theme fgStatusLineColor \<color\> \<bold/none\>** sets foreground color of status line text.  
**set custom-theme bgStatusLineColor \<color\> \<bold/none\>** sets background color of status line text.  
**set custom-theme fgAddendumColor \<color\> \<bold/none\>** sets foreground color of addendum text.  
**set custom-theme bgAddendumColor \<color\> \<bold/none\>** sets background color of addendum text.  
**set custom-theme fgEmptySpaceColor \<color\> \<bold/none\>** sets foreground color of empty text.  
**set custom-theme bgEmptySpaceColor \<color\> \<bold/none\>** sets background color of empty text.  
**set custom-theme separatorChar \<char\>** sets char for separator line.  
(custom-theme colors) = 'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan' or 'white'.  
**save script \<name\>** saves current state as script name.  
**load script \<name\>** loads state from script name".  
**load script .** loads default state.  
**rm script \<name\>** removes script name.  
**script** show all scripts saved.  

# BUGS
All software have bugs :)

# COPYRIGHT
License GPL-3.0-or-later. This is free software: you are free to change and redistribute it. There is NO WARRENTY, to the extent permitted by law.
