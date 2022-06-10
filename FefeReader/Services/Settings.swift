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
    let refreshInternal = TimeInterval(5 * 60)
    let notificationDelay = TimeInterval(5)
#else
    let refreshInternal = TimeInterval(15 * 60)
    let notificationDelay = TimeInterval(1)
#endif
    let networkTimeoutInterval = TimeInterval(10)
    
    @Published var askForNotificationApproval: Bool = true
    { didSet { UserDefaults.standard.set(askForNotificationApproval, forKey: "askForNotoficationApproval") } }
    
    @Published var openUrlsInInternalBrowser: Bool = true
    { didSet { UserDefaults.standard.set(openUrlsInInternalBrowser, forKey: "openUrlsInInternalBrowser") } }
    
    @Published var fontSize: Int = 12
    { didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") } }
    
    @Published var overviewLineLimit: Int = 2
    { didSet { UserDefaults.standard.set(overviewLineLimit, forKey: "overviewLineLimit") } }
    
    @Published var font: AppFont = Settings.availableFonts[0]
    { didSet { UserDefaults.standard.set(font.displayName, forKey: "fontName") } }
    
    @Published var regularlyDeleteOldBlogEntries = true
    { didSet { UserDefaults.standard.set(regularlyDeleteOldBlogEntries, forKey: "regularlyDeleteOldBlogEntries") } }
    
    @Published var keepBookmarkedBlogEntries = true
    { didSet { UserDefaults.standard.set(keepBookmarkedBlogEntries, forKey: "keepBookmarkedBlogEntries") } }
    
    private init() {
        let userDefaults = UserDefaults.standard
        self.openUrlsInInternalBrowser = userDefaults.bool(forKey: "openUrlsInInternalBrowser", withDefault: true)
        self.fontSize = userDefaults.integer(forKey: "fontSize", withDefault: 12)
        self.font = userDefaults.stringBasedObject(forKey: "fontName", withDefault: Settings.availableFonts[0], andConverter: { string in
            Settings.availableFonts.first { $0.displayName == string }
        })
        self.overviewLineLimit = userDefaults.integer(forKey: "overviewLineLimit", withDefault: 2)
        self.askForNotificationApproval = userDefaults.bool(forKey: "askForNotoficationApproval", withDefault: true)
        self.regularlyDeleteOldBlogEntries = userDefaults.bool(forKey: "regularlyDeleteOldBlogEntries", withDefault: true)
        self.keepBookmarkedBlogEntries = userDefaults.bool(forKey: "keepBookmarkedBlogEntries", withDefault: true)
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
