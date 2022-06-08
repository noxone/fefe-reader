//
//  FefeBlog.swift
//  FefeReader
//
//  Created by Olaf Neumann on 31.05.22.
//

import Foundation
import SwiftSoup

class FefeBlogService : ObservableObject {
    static let shared = FefeBlogService()
    
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
            return oldestEntryDate > Calendar.current.date(byAdding: .month, value: 1, to: FefeBlogService.earliestPost)!
        } else {
            return true
        }
    }()
    
    private init() {
    }
    
    func createUrl(forId id: Int) -> URL {
        return URL(string: "?ts=\(String(id, radix: 16))", relativeTo: FefeBlogService.baseUrl)!
    }
    
    func markAsRead(_ blogEntry: BlogEntry) {
        blogEntry.readTimestamp = Date()
        blogEntry.updatedSinceLastRead = false
        persistance.save()
    }
    
    func markAsUnread(_ blogEntry: BlogEntry) {
        blogEntry.readTimestamp = nil
        blogEntry.updatedSinceLastRead = false
        persistance.save()
    }
    
    func toggleRead(_ blogEntry: BlogEntry) {
        if blogEntry.isRead {
            markAsUnread(blogEntry)
        } else {
            markAsRead(blogEntry)
        }
    }
    
    func toggleBookmark(for blogEntry: BlogEntry) {
        blogEntry.bookmarkDate = blogEntry.isBookmarked ? nil : Date()
        persistance.save()
    }
    
    func refreshWithNotifications(origin: String) {
        let blogEntries = FefeBlogService.shared.refresh(origin: origin)
        NotificationService.shared.addNotifications(for: blogEntries)
    }
    
    func refresh(origin: String) -> [BlogEntry] {
        print("Refresh...................", origin, Date())
        PersistenceController.shared.createUpdateFetch(from: origin)
        return loadCurrentMonth()
    }
        
    private func loadCurrentMonth() -> [BlogEntry] {
        return loadMonthIntoDatabase(forDate: Date()).createdBlogEntries
    }
    
    func loadOlderEntries() {
        guard let oldestEntry = persistance.getOldestBlogEntry() else {
            _ = loadCurrentMonth()
            return
        }
        
        // Assumption is: We only load full months. So regardless whether this post is from
        // the first of the month or not: We need to load the previous month.
        let dateOfPost = oldestEntry.date ?? Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        
        var dateToLoad = dateOfPost
        
        var count = 0
        repeat {
            dateToLoad = Calendar.current.date(byAdding: .month, value: -1, to: dateToLoad)!
        
            if dateToLoad < FefeBlogService.earliestPost {
                canLoadMore = false
                return
            }
        
            count = loadMonthIntoDatabase(forDate: dateToLoad).touchedEntries
        } while (count == 0)
    }
    
    private func loadMonthIntoDatabase(forDate date: Date) -> (touchedEntries: Int, createdBlogEntries: [BlogEntry]) {
        let rawEntries = downloadAndParseRawEntries(forDate: date)
        
        var createdBlogEntries: [BlogEntry] = []
        
        for rawEntry in rawEntries {
            let blogEntry = persistance.getBlogEntry(withId: rawEntry.id)
            
            if let blogEntry = blogEntry {
                // Update content
                // TODO
                if blogEntry.content != rawEntry.content {
                    blogEntry.content = rawEntry.content
                    if blogEntry.isRead {
                        blogEntry.updatedSinceLastRead = true
                    }
                }
                blogEntry.relativeNumber = Int16(rawEntry.relativeNumber)
            } else {
                // Create entry
                let newBlogEntry = persistance.createBlogEntry(from: rawEntry)
                createdBlogEntries.append(newBlogEntry)
            }
        }
        persistance.save()
        
        return (touchedEntries: rawEntries.count, createdBlogEntries: createdBlogEntries)
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
            return FefeBlogService.blogDateFormatter.date(from: try element.text())
        } catch {
            // TODO better error handling
            print("Unable to parse date from element.", error)
            return nil
        }
    }
    
    func isFefeBlogEntryUrl(_ url: URL) -> Bool {
        return url.host == FefeBlogService.baseUrl.host && (url.query?.contains("ts=") ?? false)
    }
    
    func getIdFromFefeUrl(_ url: URL) -> Int? {
        let href = url.absoluteString
        if let firstIndex = href.firstIndex(of: "=") {
            let index = href.index(firstIndex, offsetBy: 1)
            let idString = String(href[index...])
            return Int(idString, radix: 16)!
        }
        return nil
    }
    
    private func getUrlFor(id: Int) -> URL {
        return URL(string: "?ts=\(String(id, radix: 16))", relativeTo: FefeBlogService.baseUrl)!
    }
    
    func loadBlogEntryFor(id: Int) -> BlogEntry? {
        if let html = downloadHtmlFor(url: getUrlFor(id: id)) {
            if let rawEntry = parseHtmlToRawEntries(html: html, relativeUrl: FefeBlogService.baseUrl).first {
                let entry = PersistenceController.shared.createBlogEntry(from: rawEntry, temporary: true)
                PersistenceController.shared.save()
                return entry
            }
        }
        return nil
    }
    
    private func parseElementIntoRawEntry(_ element: Element, relativUrl: URL) -> RawEntry? {
        do {
            if let link = element.children().first(), link.tagName() == "a" {
                let href = try link.attr("href")
                if let hrefUrl = URL(string: href, relativeTo: relativUrl), isFefeBlogEntryUrl(hrefUrl) {
                    if let id = getIdFromFefeUrl(hrefUrl) {
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
        if let url = URL(string: "?mon=\(FefeBlogService.urlDateFormatter.string(for: date)!)", relativeTo: FefeBlogService.baseUrl) {
            if let html = downloadHtmlFor(url: url) {
                return (url: url, html: html)
            } else {
                return nil
            }
        } else {
            print("URL was not valid")
            return nil
        }
    }
    
    private func downloadHtmlFor(url: URL) -> String? {
        do {
            return try String(contentsOf: url)
        } catch {
            print("Unable to load content for URL: ", url)
            // TODO: better error handling
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
