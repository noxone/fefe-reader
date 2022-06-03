//
//  FefeBlog.swift
//  FefeReader
//
//  Created by Olaf Neumann on 31.05.22.
//

import Foundation
import SwiftSoup

class FefeBlog : ObservableObject {
    static let shared = FefeBlog()
    
    private static let baseUrl = URL(string: "https://blog.fefe.de")!
    
    private static let earliestPost: Date = {
        var dateComponents = DateComponents()
        dateComponents.year = 2005
        dateComponents.month = 3
        dateComponents.day = 1
        dateComponents.timeZone = TimeZone(abbreviation: "UTC")
        return Calendar.current.date(from: dateComponents)!
    }()
    
    let persistance = PersistenceController.shared
    
    private static let urlDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.init(identifier: "de")
        formatter.dateFormat = "yyyyMM"
        formatter.timeZone = TimeZone.init(identifier: "UTC")
        return formatter
    }()
    
    private static let blogDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.init(identifier: "us")
        formatter.dateFormat = "eee MMM dd yyyy"
        formatter.timeZone = TimeZone.init(identifier: "UTC")
        return formatter
    }()
    
    @Published
    private(set) var canLoadMore: Bool = {
        if let oldestEntryDate = PersistenceController.shared.getOldestBlogEntry()?.date {
            return oldestEntryDate > Calendar.current.date(byAdding: .month, value: 1, to: FefeBlog.earliestPost)!
        } else {
            return true
        }
    }()
    
    private init() {
    }
    
    func createUrl(forId id: Int) -> URL {
        return URL(string: "?ts=\(String(id, radix: 16))", relativeTo: FefeBlog.baseUrl)!
    }
    
    func markAsRead(_ blogEntry: BlogEntry) {
        blogEntry.readTimestamp = Date()
        blogEntry.updatedSinceLastRead = false
        persistance.save()
    }
    
    func toggleFavourite(for blogEntry: BlogEntry) {
        blogEntry.favourite = !blogEntry.favourite
        persistance.save()
    }
    
    func refresh() async {
        print("Refresh...................")
        loadCurrentMonth()
    }
    
    private func loadCurrentMonth() {
        _ = loadMonthIntoDatabase(forDate: Date())
    }
    
    func loadOlderEntries() {
        guard let oldestEntry = persistance.getOldestBlogEntry() else {
            loadCurrentMonth()
            return
        }
        
        // Assumption is: We only load full months. So regardless whether this post is from
        // the first of the month or not: We need to load the previous month.
        let dateOfPost = oldestEntry.date ?? Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        
        var dateToLoad = dateOfPost
        
        var count = 0
        repeat {
            dateToLoad = Calendar.current.date(byAdding: .month, value: -1, to: dateToLoad)!
        
            if dateToLoad < FefeBlog.earliestPost {
                canLoadMore = false
                return
            }
        
            count = loadMonthIntoDatabase(forDate: dateToLoad)
        } while (count == 0)
    }
    
    private func loadMonthIntoDatabase(forDate date: Date) -> Int {
        let rawEntries = downloadAndParseRawEntries(forDate: date)
        
        for rawEntry in rawEntries {
            let blogEntry = persistance.getBlogEntry(withId: rawEntry.id)
            
            if let blogEntry = blogEntry {
                // Update content
                // TODO
                if blogEntry.content != rawEntry.content {
                    blogEntry.content = rawEntry.content
                    if blogEntry.alreadyRead {
                        blogEntry.updatedSinceLastRead = true
                    }
                }
                blogEntry.relativeNumber = Int16(rawEntry.relativeNumber)
            } else {
                // Create entry
                _ = persistance.createBlogEntry(from: rawEntry)
            }
        }
        persistance.save()
        
        return rawEntries.count
    }
    
    private func downloadAndParseRawEntries(forDate date: Date) -> [RawEntry] {
        if let result = downloadHtmlForMonth(date: date) {
            let entries = parseHtmlToRawEntries(html: result.html, relativeUrl: result.url)
            return entries
        }
        
        return []
    }
    
    private func parseHtmlToRawEntries(html: String, relativeUrl: URL) -> [RawEntry] {
        var result: [RawEntry] = []
        
        let elements: Elements
        do {
            let doc: Document = try SwiftSoup.parse(html)
            // print(try doc.text())
            elements = try doc.select("body > h3, body > ul > li")
        } catch {
            // TODO better error handling
            print("Unable to parse HTML document.", error)
            return []
        }
        var date: Date? = nil
        var relativeNumber = 1
        for element in elements {
            // print(element)
            if element.tagName() == "h3" {
                date = getDate(forElement: element)
                relativeNumber = 1
            } else if element.tagName() == "li" {
                if let date = date, var rawEntry = parseElementIntoRawEntry(element, relativUrl: relativeUrl) {
                    rawEntry.date = date
                    rawEntry.relativeNumber = relativeNumber
                    result.append(rawEntry)
                    relativeNumber += 1
                }
            }
        }
        
        return result
    }
    
    private func getDate(forElement element: Element) -> Date? {
        do {
            return FefeBlog.blogDateFormatter.date(from: try element.text())
        } catch {
            // TODO better error handling
            print("Unable to parse date from element.", error)
            return nil
        }
    }
    
    private func parseElementIntoRawEntry(_ element: Element, relativUrl: URL) -> RawEntry? {
        do {
            if let link = element.children().first(), link.tagName() == "a" {
                let href = try link.attr("href")
                if let hrefUrl = URL(string: href, relativeTo: relativUrl), hrefUrl.host == FefeBlog.baseUrl.host && (hrefUrl.query?.contains("ts=") ?? false) {
                    if let firstIndex = href.firstIndex(of: "=") {
                        let index = href.index(firstIndex, offsetBy: 1)
                        let idString = String(href[index...])
                        let id = Int(idString, radix: 16)!
                        
                        try link.remove()
                        let content = try element.html()

                        //print(date, link, href, id, content)
                        return RawEntry(id: id, link: URL(string: href)!, content: content, plainContent: try element.text())
                    }
                }
            }
            
            return nil
        } catch {
            // TODO better error handling
            print("Unable to parse blog entry from element.", error)
            return nil
        }
    }
    
    private func downloadHtmlForMonth(date: Date) -> (url: URL, html: String)? {
        if let url = URL(string: "?mon=\(FefeBlog.urlDateFormatter.string(for: date)!)", relativeTo: FefeBlog.baseUrl) {
            do {
                return try (url: url, html: String(contentsOf: url))
            } catch {
                print("Unable to load content")
                // TODO
                return nil
            }
        } else {
            print("URL was not valid")
            return nil
        }
    }
}

// TODO make private
struct RawEntry {
    let id: Int
    let link: URL
    let content: String
    let plainContent: String
    var relativeNumber: Int = 0
    var date: Date = Date()
}
