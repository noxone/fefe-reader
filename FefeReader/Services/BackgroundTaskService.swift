//
//  BackgroundTasks.swift
//  FefeReader
//
//  Created by Olaf Neumann on 05.06.22.
//

import BackgroundTasks
import CoreData

class BackgroundTaskService {
    static let TASK_REFRESH_ID = "org.olafneumann.fefe-reader.FefeBlog.refresh"
    static let TASK_CLEANUP_ID = "org.olafneumann.fefe-reader.FefeBlog.cleanUpDatabase"
    
    private let blogService: FefeBlogService
    private let context: NSManagedObjectContext
    
    init(blogService: FefeBlogService, context: NSManagedObjectContext) {
        self.blogService = blogService
        self.context = context
    }
    
    // https://medium.com/@spaceotech/how-to-update-app-content-with-background-tasks-using-the-task-scheduler-in-ios-13-95d465c462e7
    func registerBackgroundTaks() {
        cancelAllPendingBackgroundTasks()
        print("--- Register background tasks")
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundTaskService.TASK_REFRESH_ID, using: .main) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundTaskService.TASK_CLEANUP_ID, using: .main) { task in
            self.handleCleanUpTask(task: task as! BGProcessingTask)
        }
    }
    
    func cancelAllPendingBackgroundTasks() {
        print("--- Cancel background tasks")
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    func scheduleBackgroundTasks() {
        cancelAllPendingBackgroundTasks()
        scheduleRefreshTask()
        scheduleCleanUpTask()
    }
    
    private func scheduleRefreshTask() {
        if Settings.shared.checkForUpdatesInBackground {
            print("--- Schedule refresh task")
            let request = BGAppRefreshTaskRequest(identifier: BackgroundTaskService.TASK_REFRESH_ID)
            request.earliestBeginDate = Date(timeIntervalSinceNow: Settings.shared.refreshTimeInterval)
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("Could not schedule refresh task: \(error)")
            }
        } else {
            print("--- Background refresh is deactivated")
        }
    }
    
    private func scheduleCleanUpTask() {
        print("--- Schedule clean up task")
        let request = BGProcessingTaskRequest(identifier: BackgroundTaskService.TASK_CLEANUP_ID)
        // TODO: Set to one daily processing
        request.earliestBeginDate = Date(timeIntervalSinceNow: Settings.shared.refreshTimeInterval)
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = false
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule clean up task: \(error)")
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        print("--- Handle refresh task")
        scheduleRefreshTask()

        task.expirationHandler = {
            print("Cancel refresh task")
        }

        Task {
            do {
                try await blogService.refreshWithNotifications(origin: "background")
                task.setTaskCompleted(success: true)
            } catch {
                appPrint("Unable to refresh", error)
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    
    private func handleCleanUpTask(task: BGProcessingTask) {
        print("--- Handle clean up task")
        scheduleCleanUpTask()
        
        task.expirationHandler = {
            print("Cancel clean up task")
        }
        
        Task {
            let settings = Settings.shared
            if settings.regularlyDeleteOldBlogEntries {
                let deletedEntryCount = await PersistenceController.shared.deleteOldBlogEntries(butKeepBookmarks: settings.keepBookmarkedBlogEntries, context: context)
                appPrint("Cleared \(deletedEntryCount) entries in background.")
            }
            task.setTaskCompleted(success: true)
        }
    }
}
