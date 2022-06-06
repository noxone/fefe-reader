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
    
    init() {
        BlogTasks.shared.registerBackgroundTaks()
    }

    var body: some Scene {
        WindowGroup {
            //ContentView()
            //TestView()
            TabbedBlogView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task {
                    FefeBlog.shared.refresh()
                    //Refresher.shared.scheduleAppRefresh(now: true)
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
