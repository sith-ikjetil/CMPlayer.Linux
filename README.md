# CMPlayer
License: **GPL-3.0-or-later**  
This is a console music player for Linux. 

## Libraries
The player uses the following tools and libraries:
 - Swift
 - libmpg123 (libmpg123.so)
 - ffmpeg
 - libao (libao.so)
 - libavcodec (libavcodec.so)
 - libavformat (libavformat.so)
 - libavutil (libavutil.so)

## Ubuntu
In order to get these libraries onto your Ubuntu distro, you can 
execute the following commands:
 - sudo apt install ffmpeg
 - sudo apt install libavcodec-dev
 - sudo apt install libavformat-dev
 - sudo apt install libmpg123
 - sudo apt install libmpg123-dev
 - sudo apt install libao-common 
 - sudo apt install libao-dev
 - On WSL: sudo apt install pulseaudio (Doesn't always work)

## Fedora
In order to get these libraries onto you Fedora distro, you can 
execute the following commands:
 - sudo dnf install ffmpeg
 - sudo dnf install --allowerasing libavcodec-free-devel
 - sudo dnf install --allowerasing libavformat-free-devel
 - sudo dnf install --allowerasing libswresample-free-devel
 - sudo dnf install libmpg123-devel
 - sudo dnf install libao
 - sudo dnf install libao-devel

## C_INCLUDE_PATH
### Fedora
Remember to set the C_INCLUDE_PATH for ffmpeg headers:
export C_INCLUDE_PATH=/usr/include/ffmpeg:$C_INCLUDE_PATH

## LD_LIBRARY_PATH
After installing Swift, remember to update LD_LIBRARY_PATH. Set 
the following into your .bashrc and .bash_profile.
export LD_LIBRARY_PATH=/opt/swift-5.10.1/usr/lib/swift/linux:$LD_LIBRARY_PATH
(the path is ofcourse up to you where you put swift)

## PATH
You must put swift binaries in you path. An example would be to 
put them into your .bashrc and .bash_profile using the following:
PATH=/opt/swift-5.10.1/usr/bin:$PATH
(the path is ofcourse up to you where you put swift)

## Header files for Cffmpeg
There are the following preprocessor flags defined in Package.swift:
### Cffmpeg
 - CMP_FFMPEG_V6 (for ffmpeg v4)
 - CMP_FFMPEG_V4 (for ffmpeg v5)
 - CMP_TARGET_UBUNTU (for Ubuntu)
 - CMP_TARGET_FEDORA (for Fedora)

Uncomment any flag that is not your platform or target distro.

### Ubuntu
Are located at:
 - /usr/include/x86_64-linux-gnu/<library>

### Fedora
Are located at:
 - /usr/include/ffmpeg/<library>


## CMPlayer (in app) Help Text
```
<song no>
:: adds song to playlist
exit, quit, q                                                                   
:: exits application                                                            
next, skip, n, s, 'TAB'-key                                                           
:: plays next song                                                              
play, p
:: plays, pauses or resumes playback                                            
pause, p
:: pauses music
resume
:: resumes music playback
search [<words>]                                                                
:: searches artist and title for a match. case insensitive                      
search artist [<words>]                                                         
:: searches artist for a match. case insensitive                                
search title [<words>]                                                          
:: searches title for a match. case insensitive                                 
search album [<words>]                                                          
:: searches album name for a match. case insensitive                            
search genre [<words>]                                                          
:: searches genre for a match. case insensitive                                 
search year [<year>]  
:: searches recorded year for a match.                                          
mode off                                                                        
:: clears mode playback. playback now from entire song library                  
help                                                                            
:: shows this help information                                                  
pref                                                                            
:: shows preferences information                                                
about                                                                           
:: show the about information                                                   
genre                                                                           
:: shows all genre information and statistics                                   
year                                                                            
:: shows all year information and statistics                                    
mode                                                                            
:: shows current mode information and statistics                                
repaint                                                                         
:: clears and repaints entire console window 
add mrp <path>                                                                  
:: adds the path to music root folder                                           
remove mrp <path>                                                               
:: removes the path from music root folders                                     
clear mrp                                                                       
:: clears all paths from music root folders                                     
add exp <path>
:: adds the path to exclusion paths
remove exp <path>
:: removes the path from exclusion paths
clear exp
:: clears all paths from exclusion paths
set cft <seconds>                                                               
:: sets the crossfade time in seconds (1-10 seconds)                            
enable crossfade                                                                
:: enables crossfade                                                            
disable crossfade                                                               
:: disables crossfade                                                           
enable aos                                                                      
:: enables playing on application startup                                       
disable aos             
:: disables playing on application startup                                      
rebuild songno                                                                  
:: rebuilds song numbers                                                        
goto <mm:ss>                                                                    
:: moves playback point to minutes (mm) and seconds (ss) of current song        
replay                                                                          
:: starts playing current song from beginning again                             
reinitialize                                                                    
:: reinitializes library and should be called after mrp paths are changed       
info                                                                            
:: shows information about first song in playlist                               
info <song no>                                                                  
:: show information about song with given song number                           
set viewtype <type>                                                             
:: sets view type. can be 'default' or 'details'
set theme <color>                                                               
:: sets theme color. color can be 'default', 'blue' or 'black'
```
