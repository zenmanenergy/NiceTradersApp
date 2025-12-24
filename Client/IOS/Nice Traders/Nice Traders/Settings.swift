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
    
    // PayPal Client ID for SDK integration
    var paypalClientId: String {
        return "AWFaVRhLIgJ7dLWmIw5u0D8mC5HzIaJaM8hvQTN8HfaV5XzF_xDwQBLh8fUcMkxDVWYCJG_IY5AUwPHV"
    }
    
    private init() {}
}
