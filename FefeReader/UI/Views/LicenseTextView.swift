//
//  LicenseTextView.swift
//  FefeReader
//
//  Created by Olaf Neumann on 07.06.22.
//

import SwiftUI

struct LicenseTextView: View {
    let licenseText: String
    
    var body: some View {
        ScrollView {
            HStack {
                Text(licenseText)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

struct LicenseTextView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseTextView(licenseText: "abcd")
    }
}
