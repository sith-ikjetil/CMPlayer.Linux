//
//  AudioHelpers.swift
//
//  (i): Helper functions and etc. that is used in audio decoding or playback.
//
//  Created by Kjetil Kr Solberg on 27-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//
import Foundation
import Cmpg123
import Casound
import Cffmpeg
///
/// Alsa output state struct.
///
internal struct AlsaState {
    let pcmDeviceName = "default"
    var pcmHandle: OpaquePointer? = nil
    var channels: UInt32 = 2
    var sampleRate: UInt32 = 44100
    var bufferSize: snd_pcm_uframes_t = 1024
}
///
/// Validates if crossfade time is a valid crossfade time.
///
/// parameter ctis: Crossfade time in seconds.
///
/// returns: True if crossfade time is valid. False otherwise.
///
internal func isCrossfadeTimeValid(seconds: Int) -> Bool {    
    // if time (parameter seconds) is valid
    if seconds >= g_crossfadeMinTime && seconds <= g_crossfadeMaxTime {
        // return true
        return true
    }
    // time is invalid
    // return false
    return false
}
///
/// renders an FFMPEG error code to string.
///
func renderFfmpegError(error: Int32) -> String {
    // create a error string buffer variable
    var errBuf = [CChar](repeating: 0, count: 128)
    // convert error code to string
    av_strerror(error, &errBuf, errBuf.count)
    // return error string
    return "\(String(cString: errBuf))"
}
/// 
/// renders an libasound (ALSA) error code to string.
///
func renderAlsaError(error: Int32) -> String {
    // if error has a message
    if let errorMessage = snd_strerror(error) {        
        // return message
        return "\(String(cString: errorMessage))"
    }
    // error has no message
    // return empty string
    return ""
}
/// 
/// render a libmpg123 error code to string
///
func renderMpg123Error(error: Int32) -> String {
    // if error has a message
    if let errorMessage = mpg123_plain_strerror(error) {        
        // return message
        return "\(String(cString: errorMessage))"
    }        
    // error has noe message
    // return empty string
    return ""
}
