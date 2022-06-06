//
//  NotificationService.swift
//  FefeReader
//
//  Created by Olaf Neumann on 06.06.22.
//

import Foundation
import UserNotifications
import UIKit

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    private var center: UNUserNotificationCenter {
        get {
            UNUserNotificationCenter.current()
        }
    }
    
    func addNotifications(for blogEntries: [BlogEntry]) {
        addBadge(withNumber: blogEntries.count)
        for blogEntry in blogEntries {
            addNotification(for: blogEntry)
        }
    }
    
    func addNotification(for blogEntry: BlogEntry) {
        guard let notificationContent = blogEntry.notificationContent else { return }
        
        addNotification(withId: blogEntry.uuid, andContent: notificationContent)
    }
    
    private func addNotification(withId id: UUID?, andContent content: UNNotificationContent) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: (id ?? UUID()).uuidString, content: content, trigger: trigger)
        checkAuthorization(andThenDo:  { center in
            center.add(request)
        })
    }
    
    private func checkAuthorization(explicitly: Bool = false, andThenDo successCompletion: @escaping (UNUserNotificationCenter) -> () = {center in}) {
        center.getNotificationSettings { settings in
            if explicitly && settings.authorizationStatus != .authorized {
                // We need to ask for permission --> fall through
            } else if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                successCompletion(self.center)
                return
            }
            
            let options: UNAuthorizationOptions
            if explicitly {
                options = [.alert, .sound, .badge]
            } else {
                options = [.alert, .sound, .badge, .provisional]
            }
            self.center.requestAuthorization(options: options) { success, error in
                if success {
                    if explicitly {
                        Settings.shared.askForNotificationApproval = false
                    }
                    successCompletion(self.center)
                } else if let error = error {
                    print(error)
                }
            }
        }
    }
    
    func requestAuthorizationExplicitly() {
        checkAuthorization(explicitly: true)
    }
    
    func checkExplicitAuthorization(otherwise handler: @escaping () -> ()) {
        center.getNotificationSettings { settings in
            if settings.authorizationStatus != .authorized {
                handler()
            }
        }
    }
    
    private func addBadge(withNumber number: Int) {
        UIApplication.shared.applicationIconBadgeNumber = number
    }
}

fileprivate extension BlogEntry {
    var notificationContent: UNNotificationContent? {
        get {
            guard let teaserPrefix = teaserPrefix(withMaximumLength: 400) else { return nil }
            
            let notification = UNMutableNotificationContent()
            notification.title = "Blog post from Fefe"
            notification.body = teaserPrefix
            notification.sound = UNNotificationSound.default
            notification.interruptionLevel = .active
            notification.targetContentIdentifier = String(id)
            notification.userInfo["id"] = id
            return notification
        }
    }
}

