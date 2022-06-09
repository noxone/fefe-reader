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
    
    @ObservedObject var errorService = ErrorService.shared
    
    private let timer = Timer.publish(every: Settings.shared.refreshInternal, on: .main, in: .common).autoconnect()
        
    init() {
        BlogTasks.shared.registerBackgroundTaks()
    }

    var body: some Scene {
        WindowGroup {
            TabbedBlogView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task {
                    BlogTasks.shared.cancelAllPendingBackgroundTasks()
                    _ = FefeBlogService.shared.refresh(origin: "init")
                }
                .task {
                    persistenceController.cleanUpDatabase(deleteOldBlogEntries: Settings.shared.regularlyDeleteOldBlogEntries, keepBookmarks: Settings.shared.keepBookmarkedBlogEntries)
                }
                .onReceive(timer) { input in
                    FefeBlogService.shared.refreshWithNotifications(origin: "timer")
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
                BlogTasks.shared.cancelAllPendingBackgroundTasks()
                BlogTasks.shared.scheduleBackgroundTasks()
            }
        }
    }
    
    private var errorPopup: some View {
        Text("Do you want to receive notifications when Fefe publishes new blog entries?")
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 60, leading: 32, bottom: 16, trailing: 32))
            .frame(maxWidth: .infinity)
            .background(Color(hex: "FE504E"))
    }
}
