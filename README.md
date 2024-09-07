# CMPlayer.Linux
License: **GPL-3.0-or-later**  
This is a console music player for Linux.  
  
<img src="https://kjetil.azurewebsites.net/images/CMPlayerUbuntuWSL2.png" alt="CMPlayer.Linux" style="width:50%">  
<img src="https://kjetil.azurewebsites.net/images/CMPlayerUbuntuWSL.png" alt="CMPlayer.Linux" style="width:70%;">  

## Application
The applications name is **cmplayer** and the following arguments are supported:  
 - --help (shows usage screen)
 - --version (shows version number)
 - --integrity-check (does a quick integrity check of cmplayer)
 - --purge (remove all stored data)
 - --set-output-api-ao (sets audio output api to libao (ao))
 - --set-output-api-alsa (sets audio output api to libasound (alsa))
 - --get-output-api (gets audio output api)
 - --set-max-log-n max (sets max log entries [25,1000])
 - --get-max-log-n (gets max log entries)
 - --set-max-history-n max (sets max history entries [25,1000])
 - --get-max-history-n (gets max history entries)
  
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
 - libasound (libasound.so)
 - libavcodec (libavcodec.so)
 - libavformat (libavformat.so)
 - libavutil (libavutil.so)
  
## Ubuntu
In order to get these libraries onto your Ubuntu distro, you can execute the following commands:  
 - sudo apt install ffmpeg
 - sudo apt install libavcodec-dev
 - sudo apt install libavformat-dev
 - sudo apt install libmpg123-dev
 - sudo apt isntall libasound-dev
 - sudo apt install libao-dev
 - On WSL: sudo apt install pulseaudio (can be helpful, but doesn't always work)
   
## Fedora
In order to get these libraries onto you Fedora distro, you can execute the following commands:  
 - sudo dnf install ffmpeg
 - sudo dnf install --allowerasing libavcodec-free-devel
 - sudo dnf install --allowerasing libavformat-free-devel
 - sudo dnf install --allowerasing libswresample-free-devel
 - sudo dnf install libmpg123-devel
 - sudo dnf install alsa-lib-devel
 - sudo dnf install libao-devel

## Manjaro
In order to get these libraries onto you Manjaro distro, you can execute the following commands:  
 - sudo pacman -Syu libao
 - sudo pacman -Syu alsa-lib
 - sudo pacman -Syu mpg123
   
## C_INCLUDE_PATH
### Fedora
Remember to set the C_INCLUDE_PATH for ffmpeg headers:  
```bash
export C_INCLUDE_PATH=/usr/include/ffmpeg:$C_INCLUDE_PATH  
```
  
## LD_LIBRARY_PATH
After installing Swift, remember to update LD_LIBRARY_PATH. Set the following  
into your .bashrc and .bash_profile.  
```bash
export LD_LIBRARY_PATH=/opt/swift-5.10.1/usr/lib/swift/linux:$LD_LIBRARY_PATH  
```
(the path is of course up to you where you put swift)  
  
## PATH
You must put swift binaries in you path. An example would be to put them into your .bashrc  
and .bash_profile using the following:  
```bash
PATH=/opt/swift-5.10.1/usr/bin:$PATH  
```
(the path is of course up to you where you put swift)  
  
## Preprocessor Flags
There are the following preprocessor flags defined in Package.swift:
### cSettings and swiftSettings
 - CMP_FFMPEG_V7            (ffmpeg v7)
 - CMP_FFMPEG_V6            (ffmpeg v6)
 - CMP_FFMPEG_V5            (ffmpeg v5)
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
  
### Cao (swift C wrapper library for libao (ao))
Are located at:
 - /usr/include/ao/ (Ubuntu 22.04, 24.04)
 - /usr/include/ao/ (Fedora 40)
 - /usr/include/ao/ (Manjaro 24)
  
### Casound (swift C wrapper library for libasound (alsa))
Are located at:
 - /usr/include/alsa/ (Ubuntu 22.04, 24.04)
 - /usr/include/alsa/ (Fedora 40)
 - /usr/include/alsa/ (Manjaro 24)
  
### Cmpg123 (swift C wrapper library for libmpg123)
Are located at:
 - /usr/include/ (Ubuntu 22.04)
 - /usr/include/x86_64-linux-gnu/ (Ubuntu 24.04)
 - /usr/include/ (Fedora 40)
 - /usr/include/ (Manjaro 24)
  
## How to build CMPlayer.Linux
CMPlayer.Linux is written in Swift. That means that Swift must be  
installed firstly. See www.swift.org for download and install of Swift.
  
Building **cmplayer** is relativly easy. After you clone the  
project using the following:  
```bash
git clone https://github.com/sith-ikjetil/CMPlayer.Linux.git
```
You first must edit Package.swift in the CMPlayer.Linux directory.  
You must uncomment the .define statements that apply, and comment out  
those that do not apply. Like this:  
```swift
cSettings: [
    .define("CMP_PLATFORM_AMD64"),
    //.define("CMP_PLATFORM_ARM64"),
    .define("CMP_TARGET_UBUNTU_V22_04"),
    //.define("CMP_TARGET_UBUNTU_V24_04"),
    //.define("CMP_TARGET_FEDORA_V40"),
    //.define("CMP_TARGET_MANJARO_V24"),
    .define("CMP_FFMPEG_V4"),
    //.define("CMP_FFMPEG_V5"),
    //.define("CMP_FFMPEG_V6"),
    //.define("CMP_FFMPEG_V7"),
],
swiftSettings: [
    .define("CMP_PLATFORM_AMD64"),
    //.define("CMP_PLATFORM_ARM64"),
    .define("CMP_TARGET_UBUNTU_V22_04"),
    //.define("CMP_TARGET_UBUNTU_V24_04"),
    //.define("CMP_TARGET_FEDORA_V40"),
    //.define("CMP_TARGET_MANJARO_V24"),
    .define("CMP_FFMPEG_V4"),
    //.define("CMP_FFMPEG_V5"),
    //.define("CMP_FFMPEG_V6"),
    //.define("CMP_FFMPEG_V7"),
]
```
In order to know which version of ffmpeg you have, you type in  
ffmpeg in your terminal and see which version is installed on your  
system. Again, uncomment the version that apply, and comment out the versions  
that does not apply.  
  
You should set the CMP_TARGET_? to the closes match to your system. If none of these  
flags work on you system, you might need to add support for your own system.  
  
You then need to stay in the CMPlayer.Linux directory and  execute the  
following commands:  
```bash
swift build
```
If you get compiler errors, you might need the **C_INCLUDE_PATH** set in  
your .bashrc and .bash_profile. If it builds without errors, you can then  
build for release using the command:  
```bash
swift build -c release
```
If it once again builds without errors, you can find the binary in  
the CMPlayer.Linux/.build/release directory. Then it is simply a job  
to copy **cmplayer** to /usr/bin and execute the application.  
  
You might get runtime errors for libraries that **cmplayer** depends on  
but are not installed. It is written about further up in this README.md  
file. You might also need to have gcc and g++ installed. See also  
**LD_LIBRARY_PATH** further up. 