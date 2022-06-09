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
    
    func showError(message: String) {
        showError = true
        errorMessage = message
    }
    
    func executeShowingError(_ action: @escaping () throws -> () ) {
        do {
            try action()
        } catch let error as FefeBlogError {
            let description = error.localizedDescription
            showError(message: description)
        } catch {
            showError(message: "An error has occurred.")
        }
    }
}
