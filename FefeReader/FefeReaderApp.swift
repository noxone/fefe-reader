//
//  FefeReaderApp.swift
//  FefeReader
//
//  Created by Olaf Neumann on 29.05.22.
//

import SwiftUI
import UIKit
import BackgroundTasks

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
                    ErrorService.shared.executeShowingError {
                        try await blogService.refresh(origin: "init")
                    }
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
                            try await blogService.refreshWithNotifications(origin: "timer")
                        } catch {
                            appPrint("Timer update failed.", error)
                        }
                    }
                }
                .popup(isPresented: $errorService.showError, type: .toast, position: .top, autohideIn: 5, closeOnTap: true) {
                    errorPopup
                }

        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
            if newPhase == .background {
                taskService.cancelAllPendingBackgroundTasks()
                taskService.scheduleBackgroundTasks()
            }
        }
    }
    
    private var errorPopup: some View {
        Text(errorService.errorMessage)
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 60, leading: 32, bottom: 16, trailing: 32))
            .frame(maxWidth: .infinity)
            .background(errorService.color)
    }
}
