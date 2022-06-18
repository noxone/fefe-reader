//
//  DebouncedText.swift
//  FefeReader
//
//  Created by Olaf Neumann on 18.06.22.
//

import Foundation
import Combine

// https://stackoverflow.com/questions/66164898/swiftui-combine-debounce-textfield
class TextDebouncer : ObservableObject {
    @Published var debouncedText = ""
    @Published var searchText = ""
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] t in
                self?.debouncedText = t
            }
            .store(in: &subscriptions)
    }
}
