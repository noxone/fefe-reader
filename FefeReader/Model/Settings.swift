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
    static let availableRefreshFrequencies = [
        RefreshFrequency(display: "5 minutes", seconds: 5 * 60),
        RefreshFrequency(display: "15 minutes", seconds: 15 * 60),
        RefreshFrequency(display: "30 minutes", seconds: 30 * 60),
        RefreshFrequency(display: "1 hour", seconds: 60 * 60),
        RefreshFrequency(display: "2 hours", seconds: 2 * 60 * 60),
        RefreshFrequency(display: "daily", seconds: 24 * 60 * 60)
    ]

    static let issueUrl = URL(string: "https://github.com/noxone/fefe-reader/issues")!
    
    @Published var openUrlsInInternalBrowser: Bool = true
    { didSet { save() } }
    
    @Published var fontSize: Int = 12
    { didSet { save() } }
    
    @Published var overviewLineLimit: Int = 2
    { didSet { save() } }
    
    @Published var font: AppFont = Settings.availableFonts[0]
    { didSet { save() } }
    
    @Published var refreshFrequency: RefreshFrequency = Settings.availableRefreshFrequencies[2]
    { didSet { save() } }
    
    private init() {
        let settings = UserDefaults.standard
        self.openUrlsInInternalBrowser = settings.bool(forKey: "openUrlsInInternalBrowser", withDefault: true)
        self.fontSize = settings.integer(forKey: "fontSize", withDefault: 12)
        self.overviewLineLimit = settings.integer(forKey: "overviewLineLimit", withDefault: 2)
    }
    
    func save() {
        let settings = UserDefaults.standard
        settings.set(openUrlsInInternalBrowser, forKey: "openUrlsInInternalBrowser")
        settings.set(fontSize, forKey: "fontSize")
        settings.set(overviewLineLimit, forKey: "overviewLineLimit")
        settings.set(font.displayName, forKey: "fontName")
        settings.set(refreshFrequency.seconds, forKey: "refreshFrequency")
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
