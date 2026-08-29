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

# BUGS
All software have bugs :)

# COPYRIGHT
License GPL-3.0-or-later. This is free software: you are free to change and redistribute it. There is NO WARRENTY, to the extent permitted by law.
