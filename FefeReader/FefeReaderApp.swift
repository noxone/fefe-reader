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
    
    @Environment(\.scenePhase) var scenePhase
    @State var set: Bool = true
    
    private let timer = Timer.publish(every: TimeInterval(5 * 60), on: .main, in: .common).autoconnect()
        
    init() {
        BlogTasks.shared.registerBackgroundTaks()
    }

    var body: some Scene {
        WindowGroup {
            TabbedBlogView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task {
                    NotificationService.shared.requestAuthorization()
                    BlogTasks.shared.cancelAllPendingBGTask()
                    _ = FefeBlog.shared.refresh(origin: "init")
                }
                .onReceive(timer) { input in
                    FefeBlog.shared.refreshWithNotifications(origin: "timer")
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                BlogTasks.shared.cancelAllPendingBGTask()
                BlogTasks.shared.scheduleAppRefresh()
            }
        }
    }
}
