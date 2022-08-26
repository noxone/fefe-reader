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
    @Published var color = Color.errorBackground
    
    private init() {}
    
    func showError(message: String) {
        showError = true
        errorMessage = message
        color = Color.errorBackground
    }
    
    func showSuccess(message: String) {
        showError = true
        errorMessage = message
        color = Color.successBackground
    }
    
    // @discardableResult
    func executeShowingError(for category: String? = nil, _ action: @escaping () async throws -> (), andAlwaysDo deferredAction: @escaping () -> () = {} ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Task.detached(priority: .userInitiated) {
                await self.executeShowingErrorAsync(action, andAlwaysDo: deferredAction)
            } as Task<(), Error>
            if let category = category {
                TaskService.shared.set(task: task, for: category)
            }
        }
    }

    func executeShowingErrorAsync(_ action: @escaping () async throws -> (), andAlwaysDo deferredAction: () -> () = {}) async {
        defer {
            deferredAction()
        }
        do {
            try await action()
        } catch FefeBlogError.cancelled {
            // do nothing
        } catch let error as FefeBlogError {
            let description = error.localizedDescription
            showError(message: description)
        } catch {
            showError(message: "An error has occurred.")
        }
    }
}
