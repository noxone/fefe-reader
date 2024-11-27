//
//  NotificationService.swift
//  FefeReader
//
//  Created by Olaf Neumann on 06.06.22.
//

import Foundation
import UserNotifications
import UIKit

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    
    private override init() {}
    
    var idToOpen: Int64? = nil
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let id = response.notification.request.content.userInfo["id"] as? Int64 {
            print("Open entry: ", id)
            idToOpen = id
        }
        completionHandler()
    }
    
    private var center: UNUserNotificationCenter {
        get {
            UNUserNotificationCenter.current()
        }
    }
    
    func addNotifications(for blogEntries: [BlogEntry]) {
        center.delegate = self
        addBadge(withNumber: blogEntries.count)
        blogEntries.forEach {
            addNotification(for: $0)
        }
    }
    
    func addNotification(for blogEntry: BlogEntry) {
        guard let notificationContent = blogEntry.notificationContent else { return }
        
        addNotification(withId: blogEntry.id, andContent: notificationContent)
    }
    
    private func addNotification(withId id: Int64, andContent content: UNNotificationContent) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Settings.shared.notificationDelayTimeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: String(id), content: content, trigger: trigger)
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
                        DispatchQueue.main.async {
                            Settings.shared.askForNotificationApproval = false
                        }
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
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = number
        }
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

