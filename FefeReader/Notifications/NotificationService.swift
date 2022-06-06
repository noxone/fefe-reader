//
//  NotificationService.swift
//  FefeReader
//
//  Created by Olaf Neumann on 06.06.22.
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    private var center: UNUserNotificationCenter {
        get {
            UNUserNotificationCenter.current()
        }
    }
    
    func addNotifications(for blogEntries: [BlogEntry]) {
        for blogEntry in blogEntries {
            addNotification(for: blogEntry)
        }
    }
    
    func addNotification(for blogEntry: BlogEntry) {
        guard let notificationContent = blogEntry.notificationContent else { return }
        
        addNotification(withId: String(blogEntry.id), andContent: notificationContent)
    }
    
    private func addNotification(withId id: String, andContent content: UNNotificationContent) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        checkAuthorization { center in
            center.add(request)
        }
    }
    
    private func checkAuthorization(andThenDo completion: @escaping (UNUserNotificationCenter) -> () = {center in}) {
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                completion(self.center)
            } else {
                self.center.requestAuthorization(options: [.alert, .sound, .provisional, .criticalAlert, .badge]) { success, error in
                    if success {
                        completion(self.center)
                    } else if let error = error {
                        print(error)
                    }
                }
            }
        }
    }
    
    func requestAuthorization() {
        checkAuthorization()
    }
}

fileprivate extension BlogEntry {
    var notificationContent: UNNotificationContent? {
        get {
            guard let teaserPrefix = teaserPrefix(withMaximumLength: 400) else { return nil }
            
            let notification = UNMutableNotificationContent()
            notification.title = "Blog post"
            notification.subtitle = "from Fefe"
            notification.body = teaserPrefix
            notification.sound = UNNotificationSound.default
            return notification
        }
    }
}

