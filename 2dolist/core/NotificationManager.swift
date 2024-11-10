//  Notification.swift
//  2dolist
//
//  Created by Mohammad Rasoul Noori on 25/6/2024.
//

import Foundation
import UserNotifications

class NotificationManager {
    
    func askPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                print("All set!")
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func sendNotification(taskName: String, at time: Date) -> String {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "complete your task: \(taskName)"
        content.sound = UNNotificationSound.defaultCritical

        
        var timeInterval = time.timeIntervalSinceNow
        
        if abs(timeInterval) <= 30 {
            timeInterval = 1
            print("Adjusted timeInterval for buffer: \(timeInterval) seconds")
        } else if timeInterval < 60 {
            
            print("Notification time interval is below 60 seconds; scheduling canceled.")
            return ""
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let requestID = UUID().uuidString
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled with timeInterval: \(timeInterval) seconds, ID: \(requestID)")
            }
        }

        return requestID
    }

    
    func cancelNotification(with id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        print("Canceled notification with ID: \(id)")
    }
}
