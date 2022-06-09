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
                    ErrorService.shared.executeShowingError {
                        try FefeBlogService.shared.refresh(origin: "init")
                    }
                }
                .task {
                    persistenceController.cleanUpDatabase(deleteOldBlogEntries: Settings.shared.regularlyDeleteOldBlogEntries, keepBookmarks: Settings.shared.keepBookmarkedBlogEntries)
                }
                .onReceive(timer) { input in
                    do {
                        try FefeBlogService.shared.refreshWithNotifications(origin: "timer")
                    } catch {
                        // TODO: log error
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
                BlogTasks.shared.cancelAllPendingBackgroundTasks()
                BlogTasks.shared.scheduleBackgroundTasks()
            }
        }
    }
    
    private var errorPopup: some View {
        Text(errorService.errorMessage)
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 60, leading: 32, bottom: 16, trailing: 32))
            .frame(maxWidth: .infinity)
            .background(Color(hex: "FE504E"))
    }
}

// TODO: remove and add color to assets instead
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(red: Double(r) / 0xff, green: Double(g) / 0xff, blue: Double(b) / 0xff)
    }
}
