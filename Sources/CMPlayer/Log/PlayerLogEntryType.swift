//
//  PlayerLogEntryType.swift
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//

//
// import.
//
import Foundation

///
/// Log entry type class.
///
internal enum PlayerLogEntryType: String {
    case Error = "Error"
    case Warning = "Warning"
    case Information = "Information"
    case Debug = "Debug"
    case Other = "Other"
}
