//
//  FefeReaderApp.swift
//  FefeReader
//
//  Created by Olaf Neumann on 29.05.22.
//

import SwiftUI

@main
struct FefeReaderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            //ContentView()
            //TestView()
            TabbedBlogView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task {
                    await FefeBlog.shared.refresh()
                }
        }
    }
}
