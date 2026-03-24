//  NotificationManager.swift
//  2dolist
//
//  Created by Mohammad Rasoul Noori on 25/6/2024.
//

import Foundation
import UserNotifications

class NotificationManager {

    func askPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func sendNotification(taskName: String, at time: Date) -> String {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "Complete your task: \(taskName)"
        content.sound = .defaultCritical

        var timeInterval = time.timeIntervalSinceNow

        if abs(timeInterval) <= 30 {
            timeInterval = 1
        } else if timeInterval < 60 {
            return ""
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let requestID = UUID().uuidString
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        return requestID
    }

    func cancelNotification(with id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
