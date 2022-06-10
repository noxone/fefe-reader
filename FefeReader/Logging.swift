//
//  Logging.swift
//  FefeReader
//
//  Created by Olaf Neumann on 10.06.22.
//

import Foundation

import Foundation
import os

fileprivate let MAIN_LOGGER = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "main")

func appPrint(_ text: String) {
    MAIN_LOGGER.log("\(text)")
}

func appPrint(_ text: String, _ error: NSError) {
    MAIN_LOGGER.error("\(text): \(error.localizedDescription)")
}

func appPrint(_ text: String, _ error: Error) {
    MAIN_LOGGER.error("\(text): \(error.localizedDescription)")
}

class RaiseError {
    static func raise(error: Error? = nil) {
        // TODO
    }
}
