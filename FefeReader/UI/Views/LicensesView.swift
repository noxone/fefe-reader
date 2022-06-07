//
//  Licenses.swift
//  FefeReader
//
//  Created by Olaf Neumann on 07.06.22.
//

import SwiftUI

struct LicensesView: View {
    var body: some View {
        List {
            Section("Fonts") {
                NavigationLink("Allison") {
                    LicenseTextView(licenseText: "License for Allison")
                        .navigationTitle("Allison")
                }
            }
            Section("Libraries") {
                Text("PopupView")
                Text("SwiftSoup")
                Text("SwiftUIWebView")
            }
        }
        .navigationTitle("Licenses")
    }
}

struct LicensesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LicensesView()
        }
    }
}
