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
    static let baseUrl = URL(string: "https://blog.fefe.de")!
    
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
    
    private let persistence = PersistenceController.shared
    
    private let defaultContext: NSManagedObjectContext
    
    @Published
    private(set) var canLoadMore: Bool = true
    
    init (context: NSManagedObjectContext) {
        self.defaultContext = context

        if let oldestEntryDate = persistence.getOldestBlogEntry(context: context)?.date {
            canLoadMore = oldestEntryDate > Calendar.current.date(byAdding: .month, value: 1, to: FefeBlogService.earliestPost)!
        }
    }
    
    static func createUrl(forId id: Int) -> URL {
        return URL(string: "?ts=\(String(id, radix: 16))", relativeTo: FefeBlogService.baseUrl)!
    }
    
    static func isFefeBlogEntryUrl(_ url: URL) -> Bool {
        return url.host == FefeBlogService.baseUrl.host && (url.query?.contains("ts=") ?? false)
    }
    
    static func getIdFromFefeUrl(_ url: URL) -> Int? {
        let href = url.absoluteString
        if let firstIndex = href.firstIndex(of: "=") {
            let index = href.index(firstIndex, offsetBy: 1)
            let idString = String(href[index...])
            return Int(idString, radix: 16)!
        }
        return nil
    }
    
    func refreshWithNotifications(origin: String) async throws {
        let blogEntries = try await refresh(origin: origin)
        NotificationService.shared.addNotifications(for: blogEntries)
    }
    
    @discardableResult
    func refresh(origin: String) async throws -> [BlogEntry] {
        print("Refresh...................", origin, Date())
        if (origin == "init") {
            // if this is the first fetch of the application after start, check if there are posts from the previous month. If yes, update that month, too.
            let startOfMonth = Date().startOfMonth
            if let youngestBlogEntry = persistence.getYoungestBlogEntry(olderThan: startOfMonth, context: defaultContext) {
                try await loadMonthsUntilToday(startingFrom: youngestBlogEntry.secureDate)
                return []
            }
        }
        return try await loadCurrentMonth()
    }
    
    func search(for searchString: String, context: NSManagedObjectContext) async throws {
        let url = try getUrlForSearch(searchString.trimmingCharacters(in: .whitespacesAndNewlines))
        try await loadEntriesIntoDatabase(from: url, withValidState: .search, context: context)
        appPrint("Done searching for \(searchString).")
    }
    
    private func getUrlForSearch(_ searchString: String) throws -> URL {
        let queryString = searchString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let url = URL(string: "?q=\(queryString ?? "")", relativeTo: FefeBlogService.baseUrl) {
            return url
        } else {
            print("URL was not valid")
            throw FefeBlogError.urlConstructionFailed
        }
    }
    
    @discardableResult
    private func loadCurrentMonth() async throws -> [BlogEntry] {
        return try await loadMonthIntoDatabase(for: Date(), context: defaultContext)
    }
    
    private func loadMonthsUntilToday(startingFrom date: Date) async throws {
        var dateToLoad = date
        while dateToLoad < Date() {
            print("Load until, for ", dateToLoad)
            try await loadMonthIntoDatabase(for: dateToLoad, context: defaultContext)
            
            var dateComponent = DateComponents()
            dateComponent.month = 1
            dateToLoad = Calendar.current.date(byAdding: dateComponent, to: dateToLoad)!.startOfMonth
        }
    }
    
    func loadOlderEntries(context: NSManagedObjectContext? = nil) async throws {
        let context = context ?? defaultContext
        
        guard let oldestEntry = persistence.getOldestBlogEntry(context: context) else {
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
        
            count = try await loadMonthIntoDatabase(for: dateToLoad, context: context).count
        } while (count == 0)
    }
    
    @discardableResult
    private func loadMonthIntoDatabase(for date: Date, context: NSManagedObjectContext) async throws -> [BlogEntry] {
        print("Load month: ", date)
        let url = try getUrlForMonth(date: date)
        return try await loadEntriesIntoDatabase(from: url, withValidState: .normal, context: context)
    }
    
    @discardableResult
    private func loadEntriesIntoDatabase(from url: URL, withValidState validState: BlogEntry.ValidState, context: NSManagedObjectContext) async throws -> [BlogEntry] {
        let rawEntries: [RawEntry]
        do {
            rawEntries = try await downloadAndParseRawEntries(for: url)
        } catch let error as FefeBlogError {
            throw error
        } catch {
            throw FefeBlogError.unexpectedException(error: error)
        }
        
        return try await persistence.createOrUpdateBlogEntries(from: rawEntries, validState: validState, context: context)
    }
    
    private func downloadAndParseRawEntries(for url: URL) async throws -> [RawEntry] {
        let html = try await downloadString(url: url)
        return try parseHtmlToRawEntries(html: html, relativeUrl: url)
    }
    
    private func getDate(forElement element: Element) throws -> Date? {
        do {
            return FefeBlogService.blogDateFormatter.date(from: try element.text())
        } catch let error as Exception {
            print("Unable to parse date from element.", error)
            throw FefeBlogError.parsingException(exception: error)
        }
    }
    
    private func getUrlFor(id: Int) -> URL {
        return URL(string: "?ts=\(String(id, radix: 16))", relativeTo: FefeBlogService.baseUrl)!
    }
    
    func loadRawEntry(forId id: Int) async throws -> RawEntry? {
        let html = try await downloadString(url: getUrlFor(id: id))
        return try parseHtmlToRawEntries(html: html, relativeUrl: FefeBlogService.baseUrl).first
    }
    
    private func parseHtmlToRawEntries(html: String, relativeUrl: URL) throws -> [RawEntry] {
        do {
            guard !Task.isCancelled else {
                appPrint("Cancelled task!")
                throw FefeBlogError.cancelled
            }
            
            appPrint("Parsing HTML...")
            let doc = try SwiftSoup.parse(html)
            appPrint("HTML parsed")
            let elements = try doc.select("body > h3, body > ul, body > ul > li")
            appPrint("Elements selected from HTML")
            
            var createdRawResults: [RawEntry] = []
            
            var date: Date? = nil
            var currentChildCount = 0
            var relativeNumber = 0
            
            for element in elements {
                guard !Task.isCancelled else {
                    appPrint("Cancelled task!")
                    throw FefeBlogError.cancelled
                }
                
                if element.tagName() == "h3" {
                    date = try getDate(forElement: element)
                    relativeNumber = 0
                } else if element.tagName() == "ul" {
                    currentChildCount = element.children().count
                } else if element.tagName() == "li" {
                    if let date = date {
                        var rawEntry = try parseElementIntoRawEntry(element, relativUrl: relativeUrl)
                        rawEntry.date = date
                        rawEntry.relativeNumber = currentChildCount - relativeNumber
                        createdRawResults.append(rawEntry)
                        relativeNumber += 1
                    } else {
                        print("Skipping element")
                    }
                }
            }
            appPrint("Extracted \(createdRawResults.count) raw entries!")
            
            return createdRawResults
        } catch let error as Exception {
            throw FefeBlogError.parsingException(exception: error)
        }
    }
    
    private func parseElementIntoRawEntry(_ element: Element, relativUrl: URL) throws -> RawEntry {
        do {
            if let link = element.children().first(),
               link.tagName() == "a",
               let hrefUrl = URL(string: try link.attr("href"), relativeTo: relativUrl),
               FefeBlogService.isFefeBlogEntryUrl(hrefUrl),
               let id = FefeBlogService.getIdFromFefeUrl(hrefUrl)
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
    
    private func getUrlForMonth(date: Date) throws -> URL {
        if let url = URL(string: "?mon=\(FefeBlogService.urlDateFormatter.string(for: date)!)", relativeTo: FefeBlogService.baseUrl) {
            return url
        } else {
            print("URL was not valid")
            throw FefeBlogError.urlConstructionFailed
        }
    }
    
    private func downloadString(url: URL) async throws -> String {
        var request = URLRequest(url: url, timeoutInterval: Settings.shared.networkTimeoutInterval)
        request.addValue("text/html", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard response is HTTPURLResponse else { throw FefeBlogError.downloadFailed(url: url, error: nil) }
        let httpResponse = response as! HTTPURLResponse
        guard 200..<300 ~= httpResponse.statusCode else { throw FefeBlogError.downloadFailed(url: url, error: nil) }
        appPrint("Loaded \(data.count) bytes from \(url.absoluteString)")
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

struct RawEntry {
    let id: Int
    let link: URL
    let content: String
    let plainContent: String
    var relativeNumber: Int = 0
    var date: Date = Date()
}

struct Link : Identifiable {
    let label: String?
    let url: URL
    
    var id: String { url.absoluteString }
    
    init?(label: String?, url: URL?) {
        guard let url = url else { return nil }
        self.label = label
        self.url = url
    }
}

enum FefeBlogError : Error {
    case downloadFailed(url: URL, error: Error?)
    case urlConstructionFailed
    case invalidUrl(url: URL)
    case parsingException(exception: Exception)
    case invalidDocumentStructure
    case unexpectedException(error: Error)
    case cancelled
}

extension FefeBlogError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .urlConstructionFailed:
            return "Fehler beim Kontaktieren des Blogs. URL nicht erzeugbar."
        case .invalidUrl(let url):
            return "Fehler beim Kontaktieren des Servers: \(url.absoluteString)"
        case .downloadFailed(let url, let error):
            return "Fehler beim Laden von \(url)\n\(error?.localizedDescription ?? "")"
        case .invalidDocumentStructure:
            return "Unerwartete Antwort vom Blog. Daten können nicht ausgewertet werden."
        case .parsingException(let exception):
            return "Unerwartete Antwort vom Blog. Fehler beim Lesen: \(exception.localizedDescription)"
        case .unexpectedException(let error):
            return "Fehler beim Aktualisieren: \(error.localizedDescription)"
        case .cancelled:
            return "Der Vorgang wurde abgebrochen."
        }
    }
}
