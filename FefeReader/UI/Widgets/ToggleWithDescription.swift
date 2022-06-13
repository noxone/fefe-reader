//
//  ToggleWithDescription.swift
//  FefeReader
//
//  Created by Olaf Neumann on 13.06.22.
//

import SwiftUI

struct ToggleWithDescription: View {
    var title: LocalizedStringKey
    var isOn: Binding<Bool>
    var descriptionForOn: LocalizedStringKey
    var descriptionForOff: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(title, isOn: isOn)
            Text(isOn.wrappedValue ? descriptionForOn : descriptionForOff)
                .lineLimit(10)
                .font(.footnote)
        }

    }
}

struct ToggleWithDescription_Previews: PreviewProvider {
    static var previews: some View {
        ToggleWithDescription(title: "Title", isOn: .constant(true), descriptionForOn: "Description On", descriptionForOff: "Description Off")
    }
}
