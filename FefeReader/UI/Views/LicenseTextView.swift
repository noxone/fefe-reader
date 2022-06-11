//
//  LicenseTextView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 07.06.22.
//

import SwiftUI

struct LicenseTextView: View {
    // private var licensePath: String
    private var licenseText: String = "No license loaded."
    
    init(name: String) {
        if let path = Bundle.main.path(forResource: name, ofType: "license"), let licenseText = try? String(contentsOfFile: path) {
            self.licenseText = licenseText
        } else {
            licenseText = "Could not load license."
        }
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
        LicenseTextView(name: "Allison")
    }
}
