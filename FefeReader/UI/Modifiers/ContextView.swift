//
//  ContextView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 10.12.24.
//

import SwiftUI

struct ContextViewModifier<C: View> : ViewModifier {
    var isPresented: Binding<Bool>
    @ViewBuilder var content: () -> C
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .inspector(isPresented: isPresented, content: self.content)
        } else {
            content
                .popup(isPresented: isPresented, view: self.content) { config in
                    config.type(.floater(verticalPadding: 10, horizontalPadding: 10, useSafeAreaInset: true))
                        .position(.bottom)
                        .closeOnTap(false)
                        .closeOnTapOutside(true)
                        .animation(.easeInOut)
                }
        }
    }
}

extension View {
    func contextView<C: View>(isPresented: Binding<Bool>, content: @escaping () -> C) -> some View {
        return modifier(ContextViewModifier(isPresented: isPresented, content: content))
    }
}

