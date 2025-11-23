//
//  Settings.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import Foundation

class Settings {
    static let shared = Settings()
    
    // Base URL for API
    let baseURL = "http://localhost:9000"
    
    private init() {}
}
