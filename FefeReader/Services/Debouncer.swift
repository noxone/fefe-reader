//
//  DebouncedText.swift
//  FefeReader
//
//  Created by Olaf Neumann on 18.06.22.
//

import Foundation
import Combine

// https://stackoverflow.com/questions/66164898/swiftui-combine-debounce-textfield
class Debouncer<T> : ObservableObject {
    @Published var debounced: T
    @Published var input: T
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(_ defaultValue: T) {
        self.debounced = defaultValue
        self.input = defaultValue
        
        $input
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] t in
                self?.debounced = t
            }
            .store(in: &subscriptions)
    }
}

extension Debouncer where T == String {
    convenience init() {
        self.init("")
    }
}
