//
//  AudioHelpers.swift
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
    if seconds >= g_crossfadeMinTime && seconds <= g_crossfadeMaxTime {
        return true
    }
    return false
}
///
/// Renders FFMPEG error
/// 
/// converts an av error code to string.
///
func renderFfmpegError(error: Int32) -> String {
    var errBuf = [CChar](repeating: 0, count: 128)
    av_strerror(error, &errBuf, errBuf.count)
    return "\(String(cString: errBuf))"
}
/// 
/// Renders ALSA error.
/// - Parameter error: 
/// - Returns: 
func renderAlsaError(error: Int32) -> String {
    if let errorMessage = snd_strerror(error) {        
        return "\(String(cString: errorMessage))"
    }
    return ""
}
/// 
/// - Parameter error: 
/// - Returns: 
func renderMpg123Error(error: Int32) -> String {
    if let errorMessage = mpg123_plain_strerror(error) {        
        return "\(String(cString: errorMessage))"
    }        
    return ""
}
