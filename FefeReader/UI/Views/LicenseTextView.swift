//
//  LicenseTextView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 07.06.22.
//

import SwiftUI

struct LicenseTextView: View {
    private let displayName: String
    private let licenseText: String
    private let url: URL?
    
    init(displayName: String, fileName: String, url: URL? = nil) {
        if let path = Bundle.main.path(forResource: fileName, ofType: "license"), let licenseText = try? String(contentsOfFile: path) {
            self.licenseText = licenseText
        } else {
            licenseText = "Lizenz konnte nicht geladen werden."
        }
        self.displayName = displayName
        self.url = url
    }
    
    var body: some View {
        ScrollView {
            HStack {
                Text(licenseText)
                    .multilineTextAlignment(.leading)
                    .font(.custom("Courier New", size: 15))
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

struct LicenseTextView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseTextView(displayName: "Allison", fileName: "Allison", url: URL(string: "https://google.de"))
    }
}
