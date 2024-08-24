//
//  PlayerCommand.swift
//
//  Created by Kjetil Kr Solberg on 24-09-2024.
//  Copyright © 2024 Kjetil Kr Solberg. All rights reserved.
//

//
// import.
//
import Foundation
///
/// MainWindows Commands class
/// 
internal class PlayerCommand {
    ///
    /// private variables
    /// 
    private var commands: [[String]]
    private var handler: ([String]) -> Void
    /// 
    /// initializer    
    /// - Parameters:
    ///   - commands: 
    ///   - closure: 
    init(commands: [[String]], closure: @escaping ([String]) -> Void) {
        self.commands = commands
        self.handler = closure
    }
    /// 
    /// Executes a command
    /// - Parameter command: array of input command values
    /// - Returns: true if command is found and executed, false otherwise
    func execute(command: [String]) -> Bool {
        for i in 0..<self.commands.count {
            if command.count >= self.commands[i].count {
                var isFound = true
                
                //
                // Special case, only enter a number
                //
                var number: Int = -1
                if self.commands[0].count == 1 && self.commands[0][0] == "#" && command.count == 1 {
                    number = Int(command[0]) ?? -1
                    if number != -1 {
                        self.handler(command)
                        return true
                    }
                }
                
                //
                // All other cases
                //
                for j in 0..<self.commands[i].count {
                    if self.commands[i][j] != command[j] {
                        isFound = false
                        break
                    }
                }
                if isFound {
                    var newCommand = command
                    for _ in 0..<self.commands[i].count {
                        newCommand.removeFirst()
                    }
                    self.handler(newCommand)
                    return true
                }
            }
        }
        return false
    }// execute(command: [String])
}// internal class PlayerCommand
