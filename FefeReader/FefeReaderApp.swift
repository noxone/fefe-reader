//
//  FefeReaderApp.swift
//  FefeReader
//
//  Created by Olaf Neumann on 29.05.22.
//

import SwiftUI
import UIKit
import BackgroundTasks
import PopupView
import CoreData

@main
struct FefeReaderApp: App {
    private let persistence: PersistenceController
    private let context: NSManagedObjectContext
    
    private let blogService: FefeBlogService
    private let backgroundTaskService: BackgroundTaskService
    
    @Environment(\.scenePhase) private var scenePhase
    @State var set: Bool = true
    
    @ObservedObject var errorService = ErrorService.shared
    
    private let timer = Timer.publish(every: Settings.shared.refreshTimeInterval, on: .main, in: .common).autoconnect()
        
    init() {
        self.persistence = PersistenceController.shared
        self.context = persistence.persistentContainer.viewContext
        
        self.blogService = FefeBlogService(context: context)
        self.backgroundTaskService = BackgroundTaskService(blogService: blogService, context: context)
        self.backgroundTaskService.registerBackgroundTaks()
    }

    var body: some Scene {
        WindowGroup {
            MainApplicationView()
                .environment(\.managedObjectContext, context)
                .environmentObject(blogService)
                .task { createOtherTasks() }
                .onReceive(timer) { input in
                    Task {
                        do {
                            try await blogService.refreshWithNotifications(origin: .timer, forceBadge: scenePhase == .background)
                        } catch {
                            appPrint("Timer update failed.", error)
                        }
                    }
                }
        }
        .onChange(of: scenePhase) { newPhase in
            Settings.shared.lastAppUsage = Date()
            if newPhase == .active {
                NotificationService.shared.setBadge(number: 0)
            }
            if newPhase == .background {
                backgroundTaskService.cancelAllPendingBackgroundTasks()
                backgroundTaskService.scheduleBackgroundTasks()
            }
        }
    }
    
    private func createOtherTasks() {
        ErrorService.shared.executeShowingError {
            try await blogService.refresh(origin: .initial)
        }
        Task {
            let count = persistence.countBlogEntries(context: context)
            appPrint("\(count) blog entries in database")
            
            let oldestBlogEntry = persistence.getOldestBlogEntry(context: context)
            appPrint("Oldest blog entry date: \(String(describing: oldestBlogEntry?.date))")
        }
        if Settings.shared.regularlyDeleteOldBlogEntries {
            Task(priority: .utility) {
                _ = await persistence.deleteOldBlogEntries(butKeepBookmarks: Settings.shared.keepBookmarkedBlogEntries, context: context)
            }
        }
    }
}
