//
//  FefeBlog.swift
//  FefeReader
//
//  Created by Olaf Neumann on 31.05.22.
//

import Foundation
import SwiftSoup
import CoreData

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
    
    private init() {}
    
    private let dataAccess = DataAccess.shared
    private let stack = CoreDataStack.shared

    @Published
    private(set) var canLoadMore: Bool = {
        if let oldestEntryDate = DataAccess.shared.getOldestBlogEntry()?.date {
            return oldestEntryDate > Calendar.current.date(byAdding: .month, value: 1, to: FefeBlogService.earliestPost)!
        } else {
            return true
        }
    }()
    
    func createUrl(forId id: Int) -> URL {
        return URL(string: "?ts=\(String(id, radix: 16))", relativeTo: FefeBlogService.baseUrl)!
    }
    
    func markAsRead(_ blogEntry: BlogEntry) {
        stack.update(blogEntry) {
            $0.readTimestamp = Date()
            $0.updatedSinceLastRead = false
        }
    }
    
    func markAsUnread(_ blogEntry: BlogEntry) {
        stack.update(blogEntry) {
            $0.readTimestamp = nil
            $0.updatedSinceLastRead = false
        }
    }
    
    func toggleRead(_ blogEntry: BlogEntry) {
        if blogEntry.isRead {
            markAsUnread(blogEntry)
        } else {
            markAsRead(blogEntry)
        }
    }
    
    func toggleBookmark(for blogEntry: BlogEntry) {
        stack.update(blogEntry) {
            $0.bookmarkDate = $0.isBookmarked ? nil : Date()
        }
    }
    
    func refreshWithNotifications(origin: String) async throws {
        let blogEntries = try await refresh(origin: origin)
        NotificationService.shared.addNotifications(for: blogEntries)
    }
    
    @discardableResult
    func refresh(origin: String) async throws -> [BlogEntry] {
        print("Refresh...................", origin, Date())
        dataAccess.createUpdateFetch(from: origin)
        return try await loadCurrentMonth()
    }
        
    private func loadCurrentMonth() async throws -> [BlogEntry] {
        return try await loadMonthIntoDatabase(for: Date()).newlyCreateBlogEntries
    }
    
    func loadOlderEntries() async throws {
        guard let oldestEntry = DataAccess.shared.getOldestBlogEntry(includingBookmarks:  false) else {
            _ = try await loadCurrentMonth()
            return
        }
        
        // Assumption is: We only load full months. So regardless whether this post is from
        // the first of the month or not: We need to load the previous month.
        let dateOfOldestEntry = oldestEntry.date ?? Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        
        var dateToLoad = dateOfOldestEntry
        
        var count = 0
        repeat {
            var components = Calendar.current.dateComponents([.year, .month], from: dateToLoad)
            components.timeZone = TimeZone(abbreviation: "UTC")
            components.month = components.month! - 1
            dateToLoad = Calendar.current.date(from: components)!
        
            if dateToLoad < FefeBlogService.earliestPost {
                canLoadMore = false
                return
            }
        
            count = try await loadMonthIntoDatabase(for: dateToLoad).newlyCreateBlogEntries.count
        } while (count == 0)
    }
    
    private func loadMonthIntoDatabase(for date: Date) async throws -> LoadBlogEntriesResult {
        let rawEntries: [RawEntry]
        do {
            rawEntries = try await downloadAndParseRawEntries(forDate: date)
        } catch let error as FefeBlogError {
            throw error
        } catch {
            throw FefeBlogError.unexpectedException(error: error)
        }
        
        var createdBlogEntries: [BlogEntry] = []
        
        stack.withMainContext { context in
            for rawEntry in rawEntries {
                if let blogEntry = dataAccess.getBlogEntry(withId: rawEntry.id) {
                    // Update content
                    if blogEntry.content != rawEntry.content {
                        blogEntry.content = rawEntry.content
                        if blogEntry.isRead {
                            blogEntry.updatedSinceLastRead = true
                        }
                    }
                    blogEntry.relativeNumber = Int16(rawEntry.relativeNumber)
                } else {
                    // Create entry
                    let newBlogEntry = dataAccess.createBlogEntry(from: rawEntry)
                    createdBlogEntries.append(newBlogEntry)
                }
            }
        }
        
        return LoadBlogEntriesResult(newlyCreateBlogEntries: createdBlogEntries, numberOfLoadedEntries: rawEntries.count)
    }
    
    private func downloadAndParseRawEntries(forDate date: Date) async throws -> [RawEntry] {
        let result = try await downloadHtmlForMonth(date: date)
        return try parseHtmlToRawEntries(html: result.html, relativeUrl: result.url)
    }
    
    private func getDate(forElement element: Element) throws -> Date? {
        do {
            return FefeBlogService.blogDateFormatter.date(from: try element.text())
        } catch let error as Exception {
            print("Unable to parse date from element.", error)
            throw FefeBlogError.parsingException(exception: error)
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
    
    func loadTemporaryBlogEntryFor(id: Int) async throws -> BlogEntry? {
        if let entry = dataAccess.getBlogEntry(withId: id, onlyNormal: false) {
            return entry
        }
        
        let html = try await downloadString(url: getUrlFor(id: id))
        if let rawEntry = try parseHtmlToRawEntries(html: html, relativeUrl: FefeBlogService.baseUrl).first {
            let entry = dataAccess.createBlogEntry(from: rawEntry, temporary: true)
            return entry
        }
        return nil
    }
    
    private func parseHtmlToRawEntries(html: String, relativeUrl: URL) throws -> [RawEntry] {
        do {
            let doc = try SwiftSoup.parse(html)
            let elements = try doc.select("body > h3, body > ul > li")
            
            var result: [RawEntry] = []
            
            var date: Date? = nil
            var relativeNumber = 1
            
            for element in elements {
                // print(element)
                if element.tagName() == "h3" {
                    date = try getDate(forElement: element)
                    relativeNumber = 1
                } else if element.tagName() == "li" {
                    if let date = date {
                        var rawEntry = try parseElementIntoRawEntry(element, relativUrl: relativeUrl)
                        rawEntry.date = date
                        rawEntry.relativeNumber = relativeNumber
                        result.append(rawEntry)
                        relativeNumber += 1
                    } else {
                        print("Skipping element")
                    }
                }
            }
            
            return result
        } catch let error as Exception {
            throw FefeBlogError.parsingException(exception: error)
        }
    }
    
    private func parseElementIntoRawEntry(_ element: Element, relativUrl: URL) throws -> RawEntry {
        do {
            if let link = element.children().first(),
                link.tagName() == "a",
                let hrefUrl = URL(string: try link.attr("href"), relativeTo: relativUrl),
                isFefeBlogEntryUrl(hrefUrl),
                let id = getIdFromFefeUrl(hrefUrl)
            {
                try link.remove()
                let htmlContent = try element.html()
                let textContent = try element.text()

                return RawEntry(id: id, link: hrefUrl, content: htmlContent, plainContent: textContent)
            } else {
                throw FefeBlogError.invalidDocumentStructure
            }
        } catch let error as Exception {
            throw FefeBlogError.parsingException(exception: error)
        }
    }
    
    private func downloadHtmlForMonth(date: Date) async throws -> (url: URL, html: String) {
        if let url = URL(string: "?mon=\(FefeBlogService.urlDateFormatter.string(for: date)!)", relativeTo: FefeBlogService.baseUrl) {
            return (url: url, html: try await downloadString(url: url))
        } else {
            print("URL was not valid")
            throw FefeBlogError.urlConstructionFailed
        }
    }
    
    /*private func downloadHtmlFor(url: URL) throws -> String {
        do {
            return try String(contentsOf: url)
        } catch {
            print("Unable to load content for URL: ", url)
            throw FefeBlogError.downloadFailed(url: url, error: error)
        }
    }*/
    
    private func downloadString(url: URL) async throws -> String {
        var request = URLRequest(url: url, timeoutInterval: Settings.shared.networkTimeoutInterval)
        request.addValue("text/html", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard response is HTTPURLResponse else { throw FefeBlogError.downloadFailed(url: url, error: nil) }
        let httpResponse = response as! HTTPURLResponse
        guard 200..<300 ~= httpResponse.statusCode else { throw FefeBlogError.downloadFailed(url: url, error: nil) }
        if let content = String(data: data, encoding: httpResponse.encoding) {
            return content
        } else {
            throw FefeBlogError.downloadFailed(url: url, error: nil)
        }
    }
}

fileprivate extension HTTPURLResponse {
    var encoding: String.Encoding {
        var usedEncoding = String.Encoding.utf8 // Some fallback value
        if let encodingName = self.textEncodingName {
            let encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(encodingName as CFString))
            if encoding != UInt(kCFStringEncodingInvalidId) {
                usedEncoding = String.Encoding(rawValue: encoding)
            }
        }
        return usedEncoding
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

struct LoadBlogEntriesResult {
    let newlyCreateBlogEntries: [BlogEntry]
    let numberOfLoadedEntries: Int
}

enum FefeBlogError : Error {
    case downloadFailed(url: URL, error: Error?)
    case urlConstructionFailed
    case invalidUrl(url: URL)
    case parsingException(exception: Exception)
    case invalidDocumentStructure
    case unexpectedException(error: Error)
}

/*extension FefeBlogError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .downloadError(let url):
            return "Unable to load content for URL: \(url)"
        }
    }
}*/

// TODO: improve error messages
extension FefeBlogError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .downloadFailed(let url, _ /* let error*/):
            return "Unable to load content for URL: \(url)"
        default:
            return "ERROR, error"
        }
    }
}
