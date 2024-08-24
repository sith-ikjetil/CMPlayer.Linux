# CMPlayer.Linux
License: **GPL-3.0-or-later**  
This is a console music player for Linux.  
  
## Application
The applications name is **cmplayer** and the following  
arguments are supported:
 - --help (shows usage screen)
 - --version (shows version number)
 - --integrity-check (does a quick integrity check of cmplayer)
  
## Supported File Formats
The following file formats are currently supported:
 - .mp3
 - .m4a
  
## Libraries
The player uses the following tools and libraries:
 - Swift (version 5.10.1+)
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
 - On WSL: sudo apt install pulseaudio (can be helpful, but doesn't always work)
   
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

## Manjaro
In order to get these libraries onto you Manjaro distro, you can  
execute the following commands:
 - sudo pacman -Syu libao
 - sudo pacman -Syu mpg123
  
## C_INCLUDE_PATH
### Fedora
Remember to set the C_INCLUDE_PATH for ffmpeg headers:  
```bash
export C_INCLUDE_PATH=/usr/include/ffmpeg:$C_INCLUDE_PATH  
```
  
## LD_LIBRARY_PATH
After installing Swift, remember to update LD_LIBRARY_PATH. Set  
the following into your .bashrc and .bash_profile.  
```bash
export LD_LIBRARY_PATH=/opt/swift-5.10.1/usr/lib/swift/linux:$LD_LIBRARY_PATH  
```
(the path is of course up to you where you put swift)  
  
## PATH
You must put swift binaries in you path. An example would be to  
put them into your .bashrc and .bash_profile using the following:  
```bash
PATH=/opt/swift-5.10.1/usr/bin:$PATH  
```
(the path is of course up to you where you put swift)  
  
## Preprocessor Flags
There are the following preprocessor flags defined in Package.swift:
### cSettings and swiftSettings
 - CMP_FFMPEG_V7            (ffmpeg v7)
 - CMP_FFMPEG_V6            (ffmpeg v6)
 - CMP_FFMPEG_V4            (ffmpeg v4)
 - CMP_TARGET_UBUNTU_V22_04 (Ubuntu 22.04)
 - CMP_TARGET_UBUNTU_V24_04 (Ubuntu 24.04)
 - CMP_TARGET_FEDORA_V40    (Fedora 40)
 - CMP_TARGET_MANJARO_V24   (Manjaro 24)
  
Uncomment any flag that is not your version of ffmpeg or target distro.  
  
## Header Files
The following are the location of include header files to the  
Swift C wrapper libraries used by CMPlayer.Linux.    
### Cffmpeg (swift C wrapper library for ffmpeg)
Are located at:
 - /usr/include/x86_64-linux-gnu/*library* (Ubuntu 22.04, 24.04)
 - /usr/include/ffmpeg/*library* (Fedora 40)
 - /usr/include/*library* (Manjaro 24)
  
### Cao (swift C wrapper library for libao)
Are located at:
 - /usr/include/ao/ (Ubuntu 22.04, 24.04)
 - /usr/include/ao/ (Fedora)
 - /usr/include/ao/ (Manjaro)
  
### Cmpg123 (swift C wrapper library for libmpg123)
Are located at:
 - /usr/include/ (Ubuntu 22.04)
 - /usr/include/x86_64-linux-gnu/ (Ubuntu 24.04)
 - /usr/include/ (Fedora 40)
 - /usr/include/ (Manjaro 24)
  
## CMPlayer.Linux (in app) Help Text
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
