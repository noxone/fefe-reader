//
//  BlogEntryListView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 21.06.22.
//

import SwiftUI

struct SearchableList<Content>: View where Content: View {
    @Environment(\.isSearching) private var isSearching
    
    private let content: (Bool) -> Content
    private let isSearchingBinding: Binding<Bool>
    private let selection: Binding<BlogEntry?>
    
    init(selection: Binding<BlogEntry?>, indicator: Binding<Bool>, @ViewBuilder content: @escaping (Bool) -> Content) {
        self.selection = selection
        self.isSearchingBinding = indicator
        self.content = content
    }
    
    var body: some View {
        List(selection: selection) {
            content(isSearching)
        }
        .onChange(of: isSearching) {
            isSearchingBinding.wrappedValue = $0
        }
    }
}

struct SearchableList_Previews: PreviewProvider {
    static var previews: some View {
        SearchableList(selection: .constant(nil), indicator: .constant(true)) { _ in
            Text("hallo")
            Text("blub")
        }
    }
}
