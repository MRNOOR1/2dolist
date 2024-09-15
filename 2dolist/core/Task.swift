//
//  Task.swift
//  2dolist
//
//  Created by Mohammad Rasoul Noori on 20/7/2024.
//

import SwiftUI
import SwiftData
import Foundation

@Model
class Task {
    var task: String
    var important: Bool
    var timeRemaining: TimeInterval
    var expirationDate: Date

    init(task: String = " ", important: Bool = false) {
        self.task = task
        self.important = important
        self.expirationDate = Date().addingTimeInterval(10)//86400) // Initialize the creation time to the current date and time
        self.timeRemaining = 0
        self.updateRemainingTime()
    }

    func formattedTime() -> String {
        updateRemainingTime()
        let hours = Int(timeRemaining) / 3600
        if hours <= 1 {
            return "\(hours) HR"  // Returns "1 HR" when exactly one hour remains
        } else {
            return "\(hours) HRs"  // Returns the number of hours followed by "HRs" for other cases
        }
    }

    func updateRemainingTime() {
        let currentTime = Date()
        timeRemaining = expirationDate.timeIntervalSince(currentTime)
    }
    

}
