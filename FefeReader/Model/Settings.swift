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
    
    static let defaultFontSize = 12
    // static let availableFonts = ["Arial", "SanFrancisco", "monospaced", "Helvetica Neue", "Avenir Next", "Didot", "Euphemia UCAS"]
    static let availableFonts = [
        AppFont(displayName: "Helvetica Neue", font: .custom("Helvetica Neue", size: CGFloat(18)), html: "\"Helvetica Neue\""),
        AppFont(displayName: "Times new Roman", font: .custom("Times New Roman", size: CGFloat(18)), html: "\"Times New Roman\""),
        AppFont(displayName: "Courier New", font: .custom("Courier New", size: CGFloat(18)), html: "monospace"),
        AppFont(displayName: "Optima", font: .custom("Optima", size: CGFloat(18)), html: "Optima")
        // TODO: Add more fonts
    ]
    
    private init() {}
    
    @Published var openUrlsInInternalBrowser: Bool = true
    @Published var fontSize: Int = defaultFontSize
    @Published var overviewLineLimit: Int = 2
    @Published var font: AppFont = Settings.availableFonts[0]
    
    let issueUrl = URL(string: "https://github.com/noxone/fefe-reader/issues")!
    
}

struct AppFont : Hashable {
    let displayName: String
    let font: Font
    let html: String
}
