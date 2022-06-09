//
//  DateExtension.swift
//  FefeReader
//
//  Created by Olaf Neumann on 08.06.22.
//

import Foundation

extension Date {
    var startOfMonth: Date {
        get {
            var components = Calendar.current.dateComponents([.year, .month, .timeZone], from: self)
            components.timeZone = TimeZone(abbreviation: "UTC")
            return Calendar.current.date(from: components)!
        }
    }
}
