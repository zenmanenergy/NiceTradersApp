//
//  ProfileView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/20/25.
//

import SwiftUI

struct UserProfile: Codable {
    var name: String
    var email: String
    var phone: String
    var joinDate: String
    var rating: Double
    var totalExchanges: Int
    var completedExchanges: Int
    var verificationStatus: String
    var location: String
    var bio: String
}

struct ExchangeHistoryItem: Identifiable, Codable {
    let id: String
    let date: String
    let currency: String
    let amount: Int
    let partner: String
    let rating: Int
    let type: String
    let status: String
}

struct NotificationSettings: Codable {
    var newMessages: Bool
    var exchangeUpdates: Bool
    var marketingEmails: Bool
    var pushNotifications: Bool
}

struct PrivacySettings: Codable {
    var showLocation: Bool
    var showExchangeHistory: Bool
    var allowDirectMessages: Bool
}

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var user: UserProfile = UserProfile(
        name: "Loading...",
        email: "",
        phone: "",
        joinDate: "",
        rating: 0,
        totalExchanges: 0,
        completedExchanges: 0,
        verificationStatus: "unverified",
        location: "",
        bio: ""
    )
    
    @State private var exchangeHistory: [ExchangeHistoryItem] = []
    @State private var notificationSettings = NotificationSettings(
        newMessages: true,
        exchangeUpdates: true,
        marketingEmails: false,
        pushNotifications: true
    )
    @State private var privacySettings = PrivacySettings(
        showLocation: true,
        showExchangeHistory: false,
        allowDirectMessages: true
    )
    
    @State private var isEditing = false
    @State private var editedUser: UserProfile?
    @State private var isLoading = true
    @State private var navigateToSearch = false
    @State private var navigateToCreateListing = false
    @State private var navigateToMessages = false

    @State private var navigateToExchangeHistory = false
    @State private var navigateToLanguagePicker = false
    
    var successRate: Int {
        guard user.totalExchanges > 0 else { return 0 }
        return Int((Double(user.completedExchanges) / Double(user.totalExchanges)) * 100)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            if isLoading {
                ProgressView("Loading profile...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 32) {
                        // User Profile Section
                        userProfileSection
                        
                        // Stats Section
                        statsSection
                        
                        // Exchange History Button
                        exchangeHistoryButton
                        
                        // Contact Info
                        contactSection
                        
                        // Settings
                        settingsSection
                        
                        // Recent Exchanges
                        recentExchangesSection
                        
                        // Account Actions
                        accountActionsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            
            // Bottom Navigation
            BottomNavigation(activeTab: "profile")
        }
        .background(Color(hex: "f8fafc"))
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToExchangeHistory) {
            // ExchangeHistoryView would go here
            Text("Exchange History")
        }
        .navigationDestination(isPresented: $navigateToLanguagePicker) {
            LanguagePickerView()
        }
        .navigationDestination(isPresented: $navigateToSearch) {
            SearchView(navigateToSearch: $navigateToSearch)
        }
        .navigationDestination(isPresented: $navigateToCreateListing) {
            CreateListingView(navigateToCreateListing: $navigateToCreateListing)
        }
        .navigationDestination(isPresented: $navigateToMessages) {
            MessagesView(navigateToMessages: $navigateToMessages)
        }
        .onAppear {
            loadProfileData()
        }
    }
    
    // MARK: - Header View
    var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Text("Profile")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: toggleEdit) {
                Image(systemName: isEditing ? "checkmark" : "pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - User Profile Section
    var userProfileSection: some View {
        VStack(spacing: 16) {
            // Avatar with verification badge
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(getInitials(from: user.name))
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 4)
                
                if user.verificationStatus == "verified" {
                    Circle()
                        .fill(Color(hex: "48bb78"))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                }
            }
            
            if isEditing, let editedUser = editedUser {
                VStack(spacing: 12) {
                    TextField("Full Name", text: Binding(
                        get: { editedUser.name },
                        set: { self.editedUser?.name = $0 }
                    ))
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                    
                    TextEditor(text: Binding(
                        get: { editedUser.bio },
                        set: { self.editedUser?.bio = $0 }
                    ))
                    .font(.system(size: 15))
                    .frame(height: 80)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                    
                    TextField("Location", text: Binding(
                        get: { editedUser.location },
                        set: { self.editedUser?.location = $0 }
                    ))
                    .font(.system(size: 15))
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                    
                    HStack(spacing: 12) {
                        Button(action: saveChanges) {
                            Text("Save Changes")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(hex: "48bb78"))
                                .cornerRadius(8)
                        }
                        
                        Button(action: cancelEdit) {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "4a5568"))
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(hex: "e2e8f0"))
                                .cornerRadius(8)
                        }
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Text(user.name)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Text(user.bio)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "718096"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Text("📍")
                            Text(user.location)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "718096"))
                        }
                        
                        HStack(spacing: 8) {
                            Text("📅")
                            Text("Member since \(user.joinDate)")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "718096"))
                        }
                    }
                }
            }
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(Color.white)
        .cornerRadius(20)
        .padding(.top, -32)
    }
    
    // MARK: - Stats Section
    var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exchange Stats")
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            HStack(spacing: 12) {
                // Rating
                VStack(spacing: 8) {
                    Text(String(format: "%.1f", user.rating))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: "667eea"))
                    
                    Text("Rating")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "718096"))
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Text("⭐")
                                .font(.system(size: 13))
                                .opacity(index < Int(user.rating) ? 1.0 : 0.3)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                )
                
                // Total Exchanges
                VStack(spacing: 8) {
                    Text("\(user.totalExchanges)")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: "667eea"))
                    
                    Text("Total Exchanges")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "718096"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                )
                
                // Success Rate
                VStack(spacing: 8) {
                    Text("\(successRate)%")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: "667eea"))
                    
                    Text("Success Rate")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "718096"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                )
            }
        }
    }
    
    // MARK: - Exchange History Button
    var exchangeHistoryButton: some View {
        Button(action: {
            navigateToExchangeHistory = true
        }) {
            HStack(spacing: 16) {
                Text("📊")
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("View Exchange History")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Text("See all your past exchanges")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "718096"))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "cbd5e0"))
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
            )
        }
    }
    
    // MARK: - Contact Section
    var contactSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            VStack(spacing: 16) {
                if isEditing, let editedUser = editedUser {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "4a5568"))
                        
                        TextField("Email", text: Binding(
                            get: { editedUser.email },
                            set: { self.editedUser?.email = $0 }
                        ))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(Color(hex: "f7fafc"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "4a5568"))
                        
                        TextField("Phone", text: Binding(
                            get: { editedUser.phone },
                            set: { self.editedUser?.phone = $0 }
                        ))
                        .keyboardType(.phonePad)
                        .font(.system(size: 15))
                        .padding(12)
                        .background(Color(hex: "f7fafc"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                        )
                    }
                } else {
                    HStack {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "4a5568"))
                        
                        Spacer()
                        
                        Text(user.email)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "718096"))
                    }
                    
                    HStack {
                        Text("Phone")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "4a5568"))
                        
                        Spacer()
                        
                        Text(user.phone)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "718096"))
                    }
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
            )
        }
    }
    
    // MARK: - Settings Section
    var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            // Notifications
            VStack(alignment: .leading, spacing: 0) {
                Text("Notifications")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                    .padding(.bottom, 16)
                
                settingToggle("New Messages", isOn: $notificationSettings.newMessages)
                settingToggle("Exchange Updates", isOn: $notificationSettings.exchangeUpdates)
                settingToggle("Push Notifications", isOn: $notificationSettings.pushNotifications)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
            )
            
            // Privacy
            VStack(alignment: .leading, spacing: 0) {
                Text("Privacy")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                    .padding(.bottom, 16)
                
                settingToggle("Show Location", isOn: $privacySettings.showLocation)
                settingToggle("Allow Direct Messages", isOn: $privacySettings.allowDirectMessages)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
            )
            
            // Language Setting
            Button(action: {
                navigateToLanguagePicker = true
            }) {
                HStack(spacing: 16) {
                    Text("🌐")
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Language")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        Text(localizationManager.supportedLanguages[localizationManager.currentLanguage] ?? "English")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "718096"))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(hex: "cbd5e0"))
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                )
            }
        }
    }
    
    // MARK: - Recent Exchanges Section
    var recentExchangesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Exchanges")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Spacer()
                
                Button(action: {
                    navigateToExchangeHistory = true
                }) {
                    Text("View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "667eea"))
                }
            }
            
            VStack(spacing: 12) {
                ForEach(exchangeHistory.prefix(3)) { exchange in
                    exchangeHistoryItem(exchange)
                }
            }
        }
    }
    
    func exchangeHistoryItem(_ exchange: ExchangeHistoryItem) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(exchange.currency)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(hex: "667eea"))
                        .cornerRadius(20)
                    
                    Text(exchange.type.capitalized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(exchange.type == "sold" ? Color(hex: "c53030") : Color(hex: "22543d"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(exchange.type == "sold" ? Color(hex: "fed7d7") : Color(hex: "c6f6d5"))
                        .cornerRadius(20)
                }
                
                Text("$\(exchange.amount)")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                HStack {
                    Text(exchange.partner)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "718096"))
                    
                    Spacer()
                    
                    Text(formatDate(exchange.date))
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "718096"))
                }
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Text("⭐")
                            .font(.system(size: 13))
                            .opacity(index < exchange.rating ? 1.0 : 0.3)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color(hex: "a0aec0"))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
        )
    }
    
    // MARK: - Account Actions Section
    var accountActionsSection: some View {
        VStack(spacing: 12) {
            Button(action: handleLogout) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color(hex: "4299e1"))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Views
    func settingToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "4a5568"))
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color(hex: "667eea"))
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Functions
    func getInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.joined()
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func toggleEdit() {
        if isEditing {
            saveChanges()
        } else {
            editedUser = user
            isEditing = true
        }
    }
    
    func saveChanges() {
        guard let editedUser = editedUser,
              let sessionId = SessionManager.shared.sessionId else {
            isEditing = false
            return
        }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Profile/UpdateProfile")!
        components.queryItems = [
            URLQueryItem(name: "SessionId", value: sessionId),
            URLQueryItem(name: "name", value: editedUser.name),
            URLQueryItem(name: "email", value: editedUser.email),
            URLQueryItem(name: "phone", value: editedUser.phone),
            URLQueryItem(name: "location", value: editedUser.location),
            URLQueryItem(name: "bio", value: editedUser.bio)
        ]
        
        guard let url = components.url else {
            isEditing = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    user = editedUser
                }
                isEditing = false
            }
        }.resume()
    }
    
    func cancelEdit() {
        editedUser = nil
        isEditing = false
    }
    
    func handleLogout() {
        SessionManager.shared.logout()
        NotificationCenter.default.post(name: NSNotification.Name("LogoutUser"), object: nil)
    }
    
    func confirmDeleteAccount() {
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Profile/DeleteAccount")!
        components.queryItems = [
            URLQueryItem(name: "SessionId", value: sessionId)
        ]
        
        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    SessionManager.shared.logout()
                    NotificationCenter.default.post(name: NSNotification.Name("LogoutUser"), object: nil)
                }
            }
        }.resume()
    }
    
    func loadProfileData() {
        guard let sessionId = SessionManager.shared.sessionId else {
            isLoading = false
            return
        }
        
        // Load profile
        let profileURL = URL(string: "\(Settings.shared.baseURL)/Profile/GetProfile?SessionId=\(sessionId)")!
        URLSession.shared.dataTask(with: profileURL) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let profile = json["profile"] as? [String: Any] {
                    
                    user.name = profile["name"] as? String ?? user.name
                    user.email = profile["email"] as? String ?? user.email
                    user.phone = profile["phone"] as? String ?? user.phone
                    user.location = profile["location"] as? String ?? user.location
                    user.bio = profile["bio"] as? String ?? user.bio
                    user.rating = profile["rating"] as? Double ?? user.rating
                    user.totalExchanges = profile["totalExchanges"] as? Int ?? user.totalExchanges
                    user.completedExchanges = profile["completedExchanges"] as? Int ?? user.completedExchanges
                    user.verificationStatus = profile["verificationStatus"] as? String ?? user.verificationStatus
                    user.joinDate = profile["joinDate"] as? String ?? user.joinDate
                }
            }
        }.resume()
        
        // Load exchange history
        let historyURL = URL(string: "\(Settings.shared.baseURL)/Profile/GetExchangeHistory?SessionId=\(sessionId)")!
        URLSession.shared.dataTask(with: historyURL) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let exchanges = json["exchanges"] as? [[String: Any]] {
                    
                    exchangeHistory = exchanges.compactMap { dict -> ExchangeHistoryItem? in
                        guard let id = dict["id"] as? String,
                              let date = dict["date"] as? String,
                              let currency = dict["currency"] as? String,
                              let amount = dict["amount"] as? Int,
                              let partner = dict["partner"] as? String,
                              let rating = dict["rating"] as? Int,
                              let type = dict["type"] as? String,
                              let status = dict["status"] as? String else {
                            return nil
                        }
                        
                        return ExchangeHistoryItem(
                            id: id,
                            date: date,
                            currency: currency,
                            amount: amount,
                            partner: partner,
                            rating: rating,
                            type: type,
                            status: status
                        )
                    }
                }
                isLoading = false
            }
        }.resume()
    }
}

#Preview {
    ProfileView()
}
