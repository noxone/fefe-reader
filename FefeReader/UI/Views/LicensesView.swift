//
//  Licenses.swift
//  FefeReader
//
//  Created by Olaf Neumann on 07.06.22.
//

import SwiftUI

struct LicensesView: View {
    private static let libraries = ["PopupView", "SwiftSoup", "SwiftUIWebView", "swiftui-introspect"]
    private static let fonts = ["Allison"]
    
    var body: some View {
        List {
            VStack(alignment: .leading, spacing: 10) {
                Text("Alle Blog-Inhalte stammen von [Fefes Blog](https://blog.fefe.de). Dies ist unter der Adresse [https://blog.fefe.de](https://blog.fefe.de) erreichbar und hat ein eigenes Impressum.")
                Text("Der Blog-Autor hat keine Verbindung zu dieser App.")
                Text("Diese App stellt lediglich Blog-Inhalte in einer für dieses Gerät passenden Form dar. Es werden keine Inhalte verändert.")
            }.padding(.vertical, 7)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Der Autor der App hat keinen Einfluss auf die im Blog geposteten Inhalte.")
                Text("Der Autor der App hat keine Verbindung zu dem Blog.")
            }.padding(.vertical, 7)
            
            Section("Applikation") {
                NavigationLink("FefeReader") {
                    LicenseTextView(displayName: "FefeReader", fileName: "FefeReader")
                        .navigationTitle("FefeReader")
                }
            }
            Section("Bibliotheken") {
                ForEach(LicensesView.libraries, id: \.self) { library in
                    NavigationLink(library) {
                        LicenseTextView(displayName: library, fileName: library)
                            .navigationTitle(library)
                    }
                }
            }
            Section("Fonts") {
                ForEach(LicensesView.fonts, id: \.self) { font in
                    NavigationLink(font) {
                        LicenseTextView(displayName: font, fileName: font)
                            .navigationTitle(font)
                    }
                }
            }
        }
    }
}

struct LicensesView_Previews: PreviewProvider {
    static var previews: some View {
        LicensesView()
    }
}
