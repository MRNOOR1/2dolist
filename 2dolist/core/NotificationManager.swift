//
//  Notification.swift
//  2dolist
//
//  Created by Mohammad Rasoul Noori on 25/6/2024.
//

import Foundation
import UserNotifications

class NotificationManager {
    
    func AskPermission(){
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        { success, error in
            if success {
                print("All set!")
            } else if let error {
                print(error.localizedDescription)
            }
        }
    }
    
    func sendNotification(taskName: String){
        let content = UNMutableNotificationContent()
        content.title = "1 Hour to complete the task"
        content.subtitle = taskName
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error.localizedDescription)")
            }
        }
    }
}

