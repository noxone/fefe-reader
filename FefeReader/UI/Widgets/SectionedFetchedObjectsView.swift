//
//  SectionedBlogEntryList.swift
//  FefeReader
//
//  Created by Olaf Neumann on 21.06.22.
//

import SwiftUI
import CoreData

// https://medium.com/@acwrightdesign/dynamic-predicates-with-core-data-in-swiftui-d95a747c354c
struct SectionedFetchedObjectsView<S: Hashable, T, Content>: View where T : NSManagedObject, Content: View {
    
    let content: (SectionedFetchResults<S, T>) -> Content
        
    var request: SectionedFetchRequest<S, T>
    var results: SectionedFetchResults<S, T>{ request.wrappedValue }

    init(
            sectionIdentifier: KeyPath<T, S>,
            sortDescriptors: [NSSortDescriptor] = [],
            predicate: NSPredicate = NSPredicate(value: true),
            @ViewBuilder content: @escaping (SectionedFetchResults<S, T>) -> Content
        ) {
            self.content = content
            self.request = SectionedFetchRequest(
                entity: T.entity(),
                sectionIdentifier: sectionIdentifier,
                sortDescriptors: sortDescriptors,
                predicate: predicate
            )
        }
    
    var body: some View {
        self.content(results)
    }
}

/*struct SectionedBlogEntryList_Previews: PreviewProvider {
    static var previews: some View {
        SectionedBlogEntryList()
    }
}*/
