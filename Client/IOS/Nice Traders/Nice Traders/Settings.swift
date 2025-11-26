//
//  Settings.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import Foundation

class Settings {
    static let shared = Settings()
    
    // Base URL for API - automatically uses localhost when running in simulator
    var baseURL: String {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:9000"
        #else
        return "https://api.nicetraders.net"
        #endif
    }
    
    private init() {}
}
