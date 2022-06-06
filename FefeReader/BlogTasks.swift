//
//  BackgroundTasks.swift
//  FefeReader
//
//  Created by Olaf Neumann on 05.06.22.
//

import BackgroundTasks

class BlogTasks {
    static let shared = BlogTasks()
    
    static let TASK_REFRESH_ID = "org.olafneumann.fefe-reader.FefeBlog.refresh"
    
    private init() {}
    
    // https://medium.com/@spaceotech/how-to-update-app-content-with-background-tasks-using-the-task-scheduler-in-ios-13-95d465c462e7
    func registerBackgroundTaks() {
        print("--- Register background tasks")
        BGTaskScheduler.shared.cancelAllTaskRequests()
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BlogTasks.TASK_REFRESH_ID, using: nil) { (task) in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    func cancelAllPendingBGTask() {
        print("--- Cancel background tasks")
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
    
    func scheduleAppRefresh() {
        print("--- Schedule app refresh")
        let request = BGAppRefreshTaskRequest(identifier: BlogTasks.TASK_REFRESH_ID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("could not schedule app refresh: \(error)")
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        print("--- Handle app refresh")
        
        scheduleAppRefresh()
        
        FefeBlog.shared.refreshWithNotifications(origin: "background")
        
        task.expirationHandler = {
            print("cancel operations")
        }
        
        task.setTaskCompleted(success: true)
    }
}
