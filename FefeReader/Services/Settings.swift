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
    
    private let KEY_REFRESH_INTERVAL = "refreshInterval"
    private let KEY_NOTIFICATION_APPROVAL = "askForNotificationApproval"
    private let KEY_OPEN_URLS_IN_INTERNAL_BROWSER = "openUrlsInInternalBrowser"
    private let KEY_FONT_SIZE = "fontSize"
    private let KEY_FONT_NAME = "fontName"
    private let KEY_OVERVIEW_LINE_LIMIT = "overviewLineLimit"
    private let KEY_DELETE_OLD_BLOG_ENTRIES = "regularlyDeleteOldBlogEntries"
    private let KEY_KEEP_BOOKMARKS = "keepBookmarkedBlogEntries"
    private let KEY_CHECK_FOR_UPDATES = "checkForUpdatesInBackground"
    private let KEY_TINT_READ_BLOGENTRIES = "tintReadBlogentries"
    
    private let KEY_ENABLE_DELETION = "enableDeletion"
    
    static let availableFonts = [
        AppFont(displayName: "Standard", font: .body, html: "font:-apple-system-body"),
        AppFont(displayName: "Helvetica Neue", font: .custom("Helvetica Neue", size: CGFloat(18)), html: "font-family:\"Helvetica Neue\""),
        AppFont(displayName: "Times new Roman", font: .custom("Times New Roman", size: CGFloat(18)), html: "font-family:\"Times New Roman\""),
        AppFont(displayName: "Courier New", font: .custom("Courier New", size: CGFloat(18)), html: "font-family:monospace"),
        AppFont(displayName: "Optima", font: .custom("Optima", size: CGFloat(18)), html: "font-family:Optima")
        // MAYBE: Add more fonts
    ]

    static let issueUrl = URL(string: "https://github.com/noxone/fefe-reader/issues")!
    static let discussionUrl = URL(string: "https://github.com/noxone/fefe-reader/discussions")!
    
    static let MIN_FONT_SIZE = 2
    static let DEFAULT_FONT_SIZE = 12
    static let DEFAULT_FONT = availableFonts.first!
    
#if targetEnvironment(simulator)
    let refreshInternal = TimeInterval(5 * 60)
    let notificationDelay = TimeInterval(5)
#else
    var refreshTimeInterval: TimeInterval { get { Double(refreshInterval) * 60.0 } }
    let notificationDelayTimeInterval = TimeInterval(1)
#endif
    let networkTimeoutInterval = TimeInterval(10)
    
    @Published var refreshInterval: Int = Int(RefreshIntervalDuration.x15.rawValue)
    { didSet { UserDefaults.standard.set(refreshInterval, forKey: KEY_REFRESH_INTERVAL) } }
    
    @Published var askForNotificationApproval: Bool = true
    { didSet { UserDefaults.standard.set(askForNotificationApproval, forKey: KEY_NOTIFICATION_APPROVAL) } }
    
    @Published var openUrlsInInternalBrowser: Bool = true
    { didSet { UserDefaults.standard.set(openUrlsInInternalBrowser, forKey: KEY_OPEN_URLS_IN_INTERNAL_BROWSER) } }
    
    @Published var fontSize: Int = 12
    { didSet { UserDefaults.standard.set(fontSize, forKey: KEY_FONT_SIZE) } }
    
    @Published var overviewLineLimit: Int = 2
    { didSet { UserDefaults.standard.set(overviewLineLimit, forKey: KEY_OVERVIEW_LINE_LIMIT) } }
    
    @Published var font: AppFont = Settings.availableFonts[0]
    { didSet { UserDefaults.standard.set(font.displayName, forKey: KEY_FONT_NAME) } }
    
    @Published var regularlyDeleteOldBlogEntries = true
    { didSet { UserDefaults.standard.set(regularlyDeleteOldBlogEntries, forKey: KEY_DELETE_OLD_BLOG_ENTRIES) } }
    
    @Published var keepBookmarkedBlogEntries = true
    { didSet { UserDefaults.standard.set(keepBookmarkedBlogEntries, forKey: KEY_KEEP_BOOKMARKS) } }
    
    @Published var checkForUpdatesInBackground = true
    { didSet { UserDefaults.standard.set(checkForUpdatesInBackground, forKey: KEY_CHECK_FOR_UPDATES) } }
    
    @Published var tintReadBlogentries = true
    { didSet { UserDefaults.standard.set(tintReadBlogentries, forKey: KEY_TINT_READ_BLOGENTRIES) } }
    
    @Published var enableDeletion = false
    { didSet { UserDefaults.standard.set(enableDeletion, forKey: KEY_ENABLE_DELETION) } }
    
    private init() {
        let userDefaults = UserDefaults.standard
        self.openUrlsInInternalBrowser = userDefaults.bool(forKey:KEY_OPEN_URLS_IN_INTERNAL_BROWSER, withDefault: true)
        self.fontSize = userDefaults.integer(forKey: KEY_FONT_SIZE, withDefault: 12)
        self.font = userDefaults.stringBasedObject(forKey: KEY_FONT_NAME, withDefault: Settings.availableFonts[0], andConverter: { string in
            Settings.availableFonts.first { $0.displayName == string }
        })
        self.overviewLineLimit = userDefaults.integer(forKey: KEY_OVERVIEW_LINE_LIMIT, withDefault: 2)
        self.askForNotificationApproval = userDefaults.bool(forKey: KEY_NOTIFICATION_APPROVAL, withDefault: true)
        self.regularlyDeleteOldBlogEntries = userDefaults.bool(forKey: KEY_DELETE_OLD_BLOG_ENTRIES, withDefault: true)
        self.refreshInterval = userDefaults.integer(forKey: KEY_REFRESH_INTERVAL, withDefault: RefreshIntervalDuration.x15.rawValue)
        self.keepBookmarkedBlogEntries = userDefaults.bool(forKey: KEY_KEEP_BOOKMARKS, withDefault: true)
        self.checkForUpdatesInBackground = userDefaults.bool(forKey: KEY_CHECK_FOR_UPDATES, withDefault: true)
        self.tintReadBlogentries = userDefaults.bool(forKey: KEY_TINT_READ_BLOGENTRIES, withDefault: true)
        
        self.enableDeletion = userDefaults.bool(forKey: KEY_ENABLE_DELETION, withDefault: false)
    }
    
    enum RefreshIntervalDuration : Int, CaseIterable, Identifiable {
        case x5 = 5, x10 = 10, x15 = 15, x20 = 20, x30 = 30, x45 = 45, x60 = 60
        
        var id: Int { rawValue }
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
