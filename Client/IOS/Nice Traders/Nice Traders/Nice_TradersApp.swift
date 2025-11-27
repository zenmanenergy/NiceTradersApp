//
//  Nice_TradersApp.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import SwiftUI

@main
struct Nice_TradersApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        print("🟡 [App] Nice_TradersApp initializing...")
        
        // Disable text field haptic feedback
        UserDefaults.standard.set(false, forKey: "_UITextInputHapticFeedbackEnabled")
        UserDefaults.standard.set(false, forKey: "UIFeedbackGenerator")
        UserDefaults.standard.set(0, forKey: "AppleTextInputHapticFeedback")
        
        // Force LocalizationManager to initialize early
        let initialLang = LocalizationManager.shared.currentLanguage
        print("🟡 [App] LocalizationManager loaded with language: \(initialLang)")
        
        // If user is logged in, load their language preference from backend
        if SessionManager.shared.isLoggedIn {
            print("🟡 [App] User is logged in, loading language from backend...")
            LocalizationManager.shared.loadLanguageFromBackend()
        }
        
        print("🟡 [App] Nice_TradersApp initialization complete")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
