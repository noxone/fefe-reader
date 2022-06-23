//
//  LinkDisplayButton.swift
//  FefeReader
//
//  Created by Olaf Neumann on 23.06.22.
//

import SwiftUI

struct LinkDisplayButton: View {
    let link: Link
    let action: () -> ()
    
    var body: some View {
        Button(action: action, label: {
            VStack(alignment: .leading) {
                if let label = link.label {
                    Text(label)
                        .font(.caption)
                        .lineLimit(1)
                }
                Text(link.url.absoluteString)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        })
        .buttonStyle(.bordered)
    }
}

struct LinkDisplayButton_Previews: PreviewProvider {
    static var previews: some View {
        LinkDisplayButton(link: Link(label: "abc", url: URL(string: "https://google.de")!)!,action: {})
    }
}
