//
//  MinSizeScrollView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 19.06.22.
//

import SwiftUI

struct MinSizeScrollView<Content>: View where Content : View {
    @State private var scrollViewContentSize: CGSize = .zero
    var maxHeight: CGFloat = 300
    
    private var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack {
            ScrollView(.vertical) {
                VStack() {
                    content
                }
                .background(
                    GeometryReader { geo -> Color in
                        DispatchQueue.main.async {
                            scrollViewContentSize = geo.size
                        }
                        return Color.clear
                    }
                )
            }
            .frame(
                maxHeight: min(maxHeight, scrollViewContentSize.height)
            )
        }
    }
}

struct MinSizeScrollView_Previews: PreviewProvider {
    static var previews: some View {
        MinSizeScrollView {
            VStack {
                Text("bla")
                Text("blub")
            }
        }
    }
}
