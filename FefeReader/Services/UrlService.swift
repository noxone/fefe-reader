//
//  UrlService.swift
//  FefeReader
//
//  Created by Olaf Neumann on 06.06.22.
//

import Foundation
import UIKit

class UrlService {
    // static let sjared = UrlService()
    
    private init() {}
    
    static func openUrl(_ url: URL) {
        UIApplication.shared.open(url)
    }
}
