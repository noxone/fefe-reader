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
    
    @Environment(\.scenePhase) private var scenePhase
    @State var set: Bool = true
    
    private let timer = Timer.publish(every: Settings.shared.refreshInternal, on: .main, in: .common).autoconnect()
        
    init() {
        BlogTasks.shared.registerBackgroundTaks()
    }

    var body: some Scene {
        WindowGroup {
            TabbedBlogView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task {
                    BlogTasks.shared.cancelAllPendingBGTask()
                    _ = FefeBlogService.shared.refresh(origin: "init")
                }
                .onReceive(timer) { input in
                    FefeBlogService.shared.refreshWithNotifications(origin: "timer")
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
            if newPhase == .background {
                BlogTasks.shared.cancelAllPendingBGTask()
                BlogTasks.shared.scheduleAppRefresh()
            }
        }
    }
}
