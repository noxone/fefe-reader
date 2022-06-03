//
//  TextExtension.swift
//  FefeReader
//
//  Created by Olaf Neumann on 31.05.22.
//

import SwiftUI

extension Text {
    //https://swiftwombat.com/how-to-apply-text-modifiers-based-on-the-swiftui-view-state/
    func active(
        _ active: Bool,
        _ modifier: (Text) -> Text
    ) -> Text {
        guard active else { return self }
        return modifier(self)
    }

    func active(
        _ active: Bool,
        _ modifier: (Text) -> () -> Text
    ) -> Text {
        guard active else { return self }
        return modifier(self)()
    }
}
