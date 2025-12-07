//
//  Nice_TradersApp.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import SwiftUI
import MapKit

@main
struct Nice_TradersApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Pre-warm MapKit to avoid resource loading errors
        _ = MKMapView()
        
        // Disable text field haptic feedback
        UserDefaults.standard.set(false, forKey: "_UITextInputHapticFeedbackEnabled")
        UserDefaults.standard.set(false, forKey: "UIFeedbackGenerator")
        UserDefaults.standard.set(0, forKey: "AppleTextInputHapticFeedback")
        
        // Force LocalizationManager to initialize early
        let initialLang = LocalizationManager.shared.currentLanguage
        
        // If user is logged in, load their language preference from backend
        if SessionManager.shared.isLoggedIn {
            LocalizationManager.shared.loadLanguageFromBackend()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
