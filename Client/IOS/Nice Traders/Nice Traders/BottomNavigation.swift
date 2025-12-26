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
    var isContactView: Bool = false
    @Binding var contactActiveTab: ContactTabType?
    var onContactTabChange: ((ContactTabType) -> Void)? = nil
    
    var body: some View {
        // Show contact-specific tabs if in contact detail view
        if isContactView {
            HStack {
                ContactTabNavItem(icon: "📋", label: "Details", isActive: contactActiveTab == .details, action: { 
                    contactActiveTab = .details
                    onContactTabChange?(.details)
                })
                ContactTabNavItem(icon: "📍", label: "Location", isActive: contactActiveTab == .location, action: { 
                    contactActiveTab = .location
                    onContactTabChange?(.location)
                })
                ContactTabNavItem(icon: "💬", label: "Chat", isActive: contactActiveTab == .messages, action: { 
                    contactActiveTab = .messages
                    onContactTabChange?(.messages)
                })
            }
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .fill(Color(red: 0.89, green: 0.91, blue: 0.94))
                    .frame(height: 1),
                alignment: .top
            )
        } else {
            // Show standard navigation
            HStack {
                NavItem(icon: "house.fill", label: "HOME", isActive: activeTab == "home", action: goHome)
                NavItem(icon: "magnifyingglass", label: "SEARCH", isActive: activeTab == "search", action: goSearch)
                NavItem(icon: "plus.circle.fill", label: "LIST", isActive: activeTab == "create", action: goCreateListing)
                NavItem(icon: "bell.fill", label: "NOTIFICATIONS", isActive: activeTab == "messages", action: goNotifications)
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
    
    func goNotifications() {
        // Post notification to navigate to notifications
        NotificationCenter.default.post(name: NSNotification.Name("NavigateToNotifications"), object: nil)
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "session_id")
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
            .padding(.vertical, 8)
            .background(isActive ? Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.15) : Color.clear)
            .cornerRadius(8)
        }
    }
}

enum ContactTabType: String, CaseIterable {
    case details = "Details"
    case location = "Location"
    case messages = "Chat"
}

struct ContactTabNavItem: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(icon)
                    .font(.system(size: 20))
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isActive ? Color(red: 0.4, green: 0.49, blue: 0.92) : Color.gray)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isActive ? Color(red: 0.4, green: 0.49, blue: 0.92) : Color.gray)
        }
    }
}

