//
//  Task.swift
//  2dolist
//
//  Created by Mohammad Rasoul Noori on 20/7/2024.
//

import SwiftUI
import SwiftData
import Foundation

let notifications = NotificationManager()

@Model
class Task {
    @Attribute(.unique) var id: UUID
    var task: String
    var important: Bool
    var importantColorIndex: Int
    var timeRemaining: TimeInterval
    var expirationDate: Date
    var notificationID: String?
    var isCompleted: Bool
    var completedAt: Date?
    /// Weekday indices that this task repeats on. 0 = Sunday … 6 = Saturday.
    /// Empty array means the task does not repeat.
    var repeatDays: [Int] = []
    /// Optional free-text notes attached to the task.
    var notes: String = ""

    var isRepeating: Bool { !repeatDays.isEmpty }

    init(task: String = "", important: Bool = false) {
        self.id = UUID()
        self.task = task
        self.important = important
        self.importantColorIndex = 0
        self.expirationDate = Date().addingTimeInterval(86400)
        self.timeRemaining = 0
        self.isCompleted = false
        self.completedAt = nil
        self.repeatDays = []
        self.notes = ""
        self.updateRemainingTime()
    }
    
    func formattedTime() -> String {
        guard timeRemaining > 0 else { return "OVERDUE" }
        let t = Int(timeRemaining)
        let hours = t / 3600
        if hours >= 1 {
            return hours == 1 ? "1 HR" : "\(hours) HRS"
        }
        let minutes = (t % 3600) / 60
        return minutes == 1 ? "1 MIN" : "\(minutes) MINS"
    }
    
    func updateRemainingTime() {
        let currentTime = Date()
        timeRemaining = expirationDate.timeIntervalSince(currentTime)
    }
    
    
}

