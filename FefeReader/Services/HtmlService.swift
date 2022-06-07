//
//  HtmlEnhancer.swift
//  FefeReader
//
//  Created by Olaf Neumann on 01.06.22.
//

import Foundation
import SwiftSoup

class HtmlService {
    static let shared = HtmlService()
    
    private init() {}
    
    func enhance(html: String) -> String {
        do {
            let preparedHtmlString = "<html><head><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><style>:root {color-scheme: light dark;--link-color: blue;}@media screen and (prefers-color-scheme: dark){:root{--link-color: #93d5ff;}}body{\(Settings.shared.font.html);font-size:\(Settings.shared.fontSize)pt;}a{color:var(--link-color);}</style></head><body></body></html>"
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
    
    func extractLinks(html: String) -> [URL] {
        do {
            let document = try SwiftSoup.parse(html)
            let links = try document.select("a")
            return try links.compactMap { URL(string: try $0.attr("href")) }
        } catch {
            // TODO: better error handling
            print(error)
            return []
        }
    }
}
