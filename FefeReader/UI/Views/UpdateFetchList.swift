//
//  UpdateFetchList.swift
//  FefeReader
//
//  Created by Olaf Neumann on 05.06.22.
//
import SwiftUI

struct UpdateFetchListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: UpdateFetch.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \UpdateFetch.date, ascending: false),
        ],
        animation: .default)
    private var requests: FetchedResults<UpdateFetch>

    var body: some View {
        NavigationView {
            List {
                ForEach(requests) { request in
                    if let date = request.date {
                        Text("\(date.formatted()) - \(request.from ?? "no from")")
                    } else {
                        Text("No date")
                            .italic()
                    }
                }
            }
            .navigationTitle("Updates")
        }
    }
}

struct UpdateFetchListView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateFetchListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
