//
//  Settings.swift
//  FefeReader
//
//  Created by Olaf Neumann on 01.06.22.
//

import Foundation
import SwiftUI

class Settings : ObservableObject {
    static let shared = Settings()
    
    static let availableFonts = [
        AppFont(displayName: "System default", font: .body, html: "font:-apple-system-body"),
        AppFont(displayName: "Helvetica Neue", font: .custom("Helvetica Neue", size: CGFloat(18)), html: "font-family:\"Helvetica Neue\""),
        AppFont(displayName: "Times new Roman", font: .custom("Times New Roman", size: CGFloat(18)), html: "font-family:\"Times New Roman\""),
        AppFont(displayName: "Courier New", font: .custom("Courier New", size: CGFloat(18)), html: "font-family:monospace"),
        AppFont(displayName: "Optima", font: .custom("Optima", size: CGFloat(18)), html: "font-family:Optima")
        // TODO: Add more fonts
    ]

    static let issueUrl = URL(string: "https://github.com/noxone/fefe-reader/issues")!
    
#if targetEnvironment(simulator)
    let refreshInternal = TimeInterval(10)
    let notificationDelay = TimeInterval(5)
#else
    let refreshInternal = TimeInterval(15 * 60)
    let notificationDelay = TimeInterval(1)
#endif
    
    @Published var askForNotificationApproval: Bool = true
    { didSet { save() } }
    
    @Published var openUrlsInInternalBrowser: Bool = true
    { didSet { save() } }
    
    @Published var fontSize: Int = 12
    { didSet { save() } }
    
    @Published var overviewLineLimit: Int = 2
    { didSet { save() } }
    
    @Published var font: AppFont = Settings.availableFonts[0]
    { didSet { save() } }
    
    @Published var regularlyDeleteOldBlogEntries = true
    { didSet { save() } }
    
    private init() {
        let settings = UserDefaults.standard
        self.openUrlsInInternalBrowser = settings.bool(forKey: "openUrlsInInternalBrowser", withDefault: true)
        self.fontSize = settings.integer(forKey: "fontSize", withDefault: 12)
        self.font = settings.stringBasedObject(forKey: "fontName", withDefault: Settings.availableFonts[0], andConverter: { string in
            Settings.availableFonts.first { $0.displayName == string }
        })
        self.overviewLineLimit = settings.integer(forKey: "overviewLineLimit", withDefault: 2)
        self.askForNotificationApproval = settings.bool(forKey: "askForNotoficationApproval", withDefault: true)
        self.regularlyDeleteOldBlogEntries = settings.bool(forKey: "regularlyDeleteOldBlogEntries", withDefault: true)
    }
    
    func save() {
        let settings = UserDefaults.standard
        settings.set(openUrlsInInternalBrowser, forKey: "openUrlsInInternalBrowser")
        settings.set(fontSize, forKey: "fontSize")
        settings.set(overviewLineLimit, forKey: "overviewLineLimit")
        settings.set(font.displayName, forKey: "fontName")
        settings.set(askForNotificationApproval, forKey: "askForNotoficationApproval")
        settings.set(regularlyDeleteOldBlogEntries, forKey: "regularlyDeleteOldBlogEntries")
    }
}

extension UserDefaults {
    func bool(forKey key: String, withDefault defaultValue: Bool) -> Bool {
        if object(forKey: key) != nil {
            return bool(forKey: key)
        }
        return defaultValue
    }

    func integer(forKey key: String, withDefault defaultValue: Int) -> Int {
        if object(forKey: key) != nil {
            return integer(forKey: key)
        }
        return defaultValue
    }
    
    func stringBasedObject<T>(forKey key: String, withDefault defaultValue: T, andConverter converter: (String) -> T?) -> T {
        if let string = string(forKey: key) {
            return converter(string) ?? defaultValue
        }
        return defaultValue
    }
}

struct AppFont : Hashable {
    let displayName: String
    let font: Font
    let html: String
}

struct RefreshFrequency : Hashable {
    let display: String
    let seconds: Int
}
