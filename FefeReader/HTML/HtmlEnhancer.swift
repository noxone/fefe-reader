//
//  HtmlEnhancer.swift
//  FefeReader
//
//  Created by Olaf Neumann on 01.06.22.
//

import Foundation
import SwiftSoup

class HtmlEnhancer {
    static let shared = HtmlEnhancer()
    
    private init() {}
    
    func enhance(html: String) -> String {
        return doStuff(html: html)
    }
    
    private func doStuff(html: String) -> String {
        do {
            let preparedHtmlString = "<html><head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><style>body {font-family: \(Settings.shared.font.html);font-size:\(Settings.shared.fontSize)pt;}</style></head><body></body></html>"
            let preparedHtml = try SwiftSoup.parse(preparedHtmlString)
            let preparedBody = try preparedHtml.select("body")[0]
            
            let strippedBody = try SwiftSoup.parseBodyFragment(html)
            let body = try strippedBody.select("body")[0]
            
            try preparedBody.parent()?.appendChild(body)
            try preparedBody.remove()
            
            let generatedHtml = try preparedHtml.html()
            return generatedHtml
        } catch {
            // TODO proper error handling
            print("Unable to prepare HTML", error)
            return html
        }
    }
}
