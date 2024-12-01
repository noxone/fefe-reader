//
//  StringExtension.swift
//  FefeReader
//
//  Created by Olaf Neumann on 01.12.24.
//


import Foundation

extension String {
    var isBlank: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
