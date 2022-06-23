//
//  LinkDisplayButton.swift
//  FefeReader
//
//  Created by Olaf Neumann on 23.06.22.
//

import SwiftUI

struct LinkDisplayButton: View {
    let link: Link
    let action: (Bool) -> ()
    
    var body: some View {
        Button(action: {action(false)}, label: {
            VStack(alignment: .leading) {
                if let label = link.label {
                    Text(label)
                        .font(.caption)
                        .lineLimit(1)
                }
                Text(link.url.absoluteString)
                    .lineLimit(1)
            }
            .onTapGesture {
                action(false)
            }
            .onLongPressGesture {
                action(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        })
        .buttonStyle(.bordered)
    }
}

struct LinkDisplayButton_Previews: PreviewProvider {
    static var previews: some View {
        LinkDisplayButton(link: Link(label: "abc", url: URL(string: "https://google.de")!)!,action: {_ in})
    }
}
