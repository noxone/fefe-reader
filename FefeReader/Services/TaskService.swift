//
//  TaskService.swift
//  FefeReader
//
//  Created by Olaf Neumann on 22.06.22.
//

import Foundation

class TaskService {
    static let shared = TaskService()
    
    private init() {}
    
    private var singleTasks = [String:Task<(), Error>]()
    private let queue = DispatchQueue(label: "locksy")
    
    func set(task: Task<(), Error>, for category: String) {
        queue.sync {
            let oldTask = singleTasks[category]
            if let oldTask = oldTask {
                cancelTask(for: category)
                oldTask.cancel()
            }
            
            singleTasks[category] = task
        }
    }
    
    func cancelTask(for category: String) {
        queue.sync {
            if let task = singleTasks[category] {
                appPrint("Cancel old '\(category)' task.")
                task.cancel()
                singleTasks[category] = nil
            }
        }
    }
}
