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

@main
struct FefeReaderApp: App {
    private let persistenceController = PersistenceController.shared
    
    private let blogService: FefeBlogService
    private let taskService: BackgroundTaskService
    
    @Environment(\.scenePhase) private var scenePhase
    @State var set: Bool = true
    
    @ObservedObject var errorService = ErrorService.shared
    
    private let timer = Timer.publish(every: Settings.shared.refreshTimeInterval, on: .main, in: .common).autoconnect()
        
    init() {
        let context = persistenceController.persistentContainer.viewContext
        blogService = FefeBlogService(context: context)
        taskService = BackgroundTaskService(blogService: blogService, context: context)
        
        taskService.registerBackgroundTaks()
    }

    var body: some Scene {
        WindowGroup {
            MainApplicationView()
                .environment(\.managedObjectContext, persistenceController.persistentContainer.viewContext)
                .environmentObject(blogService)
                .task {
                    let context = persistenceController.persistentContainer.viewContext
                    let count = persistenceController.countBlogEntries(context: context)
                    appPrint("\(count) blog entries in database")
                    let oldestBlogEntry = persistenceController.getOldestBlogEntry(context: context)
                    appPrint("Oldest blog entry date: \(String(describing: oldestBlogEntry?.date))")
                }
                .task {
                    taskService.cancelAllPendingBackgroundTasks()
                }
                .task {
                    if Settings.shared.regularlyDeleteOldBlogEntries {
                        Task(priority: .utility) {
                            await persistenceController.deleteOldBlogEntries(butKeepBookmarks: Settings.shared.keepBookmarkedBlogEntries, context: persistenceController.persistentContainer.viewContext)
                        }
                    }
                }
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
                ErrorService.shared.executeShowingError {
                    try await blogService.refresh(origin: .initial)
                }
            }
            if newPhase == .background {
                taskService.cancelAllPendingBackgroundTasks()
                taskService.scheduleBackgroundTasks()
            }
        }
    }
}
