//
//  ErrorService.swift
//  FefeReader
//
//  Created by Olaf Neumann on 09.06.22.
//

import SwiftUI

class ErrorService : ObservableObject {
    static let shared = ErrorService()
    
    @Published var showError = false
    @Published var errorMessage = ""
    
    private init() {}
    
    func showError(error: Error) {
        showError = true
        errorMessage = error.localizedDescription
    }
}
