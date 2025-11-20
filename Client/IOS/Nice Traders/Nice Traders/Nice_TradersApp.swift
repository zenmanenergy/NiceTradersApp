//
//  Nice_TradersApp.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import SwiftUI

@main
struct Nice_TradersApp: App {
    init() {
        // Suppress haptic feedback warnings in simulator
        #if targetEnvironment(simulator)
        UserDefaults.standard.set(false, forKey: "UIFeedbackGenerator")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
