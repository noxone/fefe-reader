//
//  AdaptiveButtonStyle.swift
//  FefeReader
//
//  Created by Olaf Neumann on 05.12.24.
//



import SwiftUI

struct AdaptiveButtonStyle : ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var adjustLabelStyle = true
    var controlSize: ControlSize? = nil
    
    private var isLargeScreen: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    func body(content: Content) -> some View {
        let controlSize: ControlSize = .regular
        
        var control = AnyView(content)

        control = AnyView(content.controlSize(controlSize))
        if isLargeScreen {
            control = AnyView(control.buttonStyle(.bordered))
        }

        if adjustLabelStyle {
            if isLargeScreen {
                return AnyView(control.labelStyle(.titleAndIcon))
            } else {
                return AnyView(control.labelStyle(.iconOnly))
            }
        } else {
            return control
        }
    }
}

extension View {
    func adaptiveButtonStyle(adjustLabelStyle: Bool = true, controlSize: ControlSize? = nil) -> some View {
        return modifier(AdaptiveButtonStyle(adjustLabelStyle: adjustLabelStyle, controlSize: controlSize))
    }
}
