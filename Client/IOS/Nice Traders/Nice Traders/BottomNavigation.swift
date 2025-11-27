//
//  BottomNavigation.swift
//  Nice Traders
//
//  Bottom navigation component shared across all views
//

import SwiftUI

struct BottomNavigation: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    var activeTab: String = "home" // "home", "search", "create", "messages", "profile"
    
    var body: some View {
        HStack {
            NavItem(icon: "house.fill", label: "HOME", isActive: activeTab == "home", action: goHome)
            NavItem(icon: "magnifyingglass", label: "SEARCH", isActive: activeTab == "search", action: goSearch)
            NavItem(icon: "plus.circle.fill", label: "LIST", isActive: activeTab == "create", action: goCreateListing)
            NavItem(icon: "message.fill", label: "MESSAGES", isActive: activeTab == "messages", action: goMessages)
        }
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(red: 0.89, green: 0.91, blue: 0.94))
                .frame(height: 1),
            alignment: .top
        )
    }
    
    func goHome() {
        // Dismiss to go back to dashboard root
        dismiss()
    }
    
    func goSearch() {
        // Post notification to navigate to search
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToSearch"), object: nil)
    }
    
    func goCreateListing() {
        // Post notification to navigate to create listing
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToCreateListing"), object: nil)
    }
    
    func goMessages() {
        // Post notification to navigate to messages
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToMessages"), object: nil)
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "SessionId")
        UserDefaults.standard.removeObject(forKey: "UserType")
        
        // Post notification to reset navigation
        NotificationCenter.default.post(name: NSNotification.Name("LogoutUser"), object: nil)
        
        dismiss()
    }
}

struct NavItem: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isActive ? Color(red: 0.4, green: 0.49, blue: 0.92) : Color.gray)
                
                Text(localizationManager.localize(label))
                    .font(.system(size: 10))
                    .foregroundColor(isActive ? Color(red: 0.4, green: 0.49, blue: 0.92) : Color.gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
