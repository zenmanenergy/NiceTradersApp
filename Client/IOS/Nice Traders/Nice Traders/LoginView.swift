//
//  LoginView.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import SwiftUI
import UIKit

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    @State private var email = ""
    @State private var password = ""
    
    @State private var errors: [String: String] = [:]
    @State private var isSubmitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var navigateToDashboard = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.0))
                            .cornerRadius(8)
                    }
                    Spacer()
                }
                
                Text(localizationManager.localize("SIGN_IN"))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, 
green: 0.29, blue: 0.64)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            ScrollView {
                VStack(spacing: 0) {
                    // Welcome Section
                    VStack(spacing: 16) {
                        Text("💱")
                            .font(.system(size: 48))
                        
                        Text(localizationManager.localize("WELCOME_BACK"))
                            .font(.system(size: 29, weight: .semibold))
                            .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
                        
                        Text(localizationManager.localize("SIGN_IN_TO_CONTINUE"))
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    // Form
                    VStack(spacing: 24) {
                        FormField(
                            label: localizationManager.localize("EMAIL"),
                            text: $email,
                            placeholder: localizationManager.localize("ENTER_EMAIL"),
                            keyboardType: .emailAddress,
                            error: errors["email"]
                        )
                        
                        FormField(
                            label: localizationManager.localize("PASSWORD"),
                            text: $password,
                            placeholder: localizationManager.localize("ENTER_PASSWORD"),
                            isSecure: true,
                            error: errors["password"]
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Forgot Password
                    HStack {
                        Spacer()
                        Button(action: {
                            alertMessage = localizationManager.localize("FORGOT_PASSWORD_COMING_SOON")
                            showingAlert = true
                        }) {
                            Text(localizationManager.localize("FORGOT_PASSWORD"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                    
                    // Submit Button
                    Button(action: handleSubmit) {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text(localizationManager.localize("SIGNING_IN"))
                            } else {
                                Text(localizationManager.localize("SIGN_IN"))
                            }
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]),                                                                                                    startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.4), radius: 15, y
: 4)                                                                                                                           }
                    .disabled(isSubmitting)
                    .opacity(isSubmitting ? 0.7 : 1.0)
                    .padding(.horizontal, 24)
                    
                    // Signup Link
                    HStack(spacing: 4) {
                        Text(localizationManager.localize("DONT_HAVE_ACCOUNT"))
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                        
                        Button(action: {
                            // Navigate to signup - will be handled by parent
                            dismiss()
                        }) {
                            Text(localizationManager.localize("SIGN_UP"))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                        }
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 32)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarHidden(true)
        .background(Color.white)
        .onAppear {
            // Clear form when view appears (e.g., after logout)
            if SessionManager.shared.sessionId == nil {
                email = ""
                password = ""
                errors = [:]
            }
        }
        .alert(localizationManager.localize("LOGIN"), isPresented: $showingAlert) {
            Button(localizationManager.localize("OK"), role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .navigationDestination(isPresented: $navigateToDashboard) {
            DashboardView()
        }
    }
    
    func validateForm() -> Bool {
        errors = [:]
        
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errors["email"] = localizationManager.localize("EMAIL_REQUIRED")
        } else if !email.contains("@") || !email.contains(".") {
            errors["email"] = localizationManager.localize("INVALID_EMAIL")
        }
        
        if password.isEmpty {
            errors["password"] = localizationManager.localize("PASSWORD_REQUIRED")
        }
        
        return errors.isEmpty
    }
    
    func handleSubmit() {
        guard validateForm() else { return }
        
        isSubmitting = true
        
        // Get device information
        let deviceInfo = DeviceTokenManager.shared.getDeviceInfo()
        
        // Prepare data for API
        var parameters: [String: String] = [
            "Email": email,
            "Password": password
        ]
        
        // Add device information if available
        parameters.merge(deviceInfo) { (_, new) in new }
        
        // Build query string
        let queryString = parameters.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }.joined(separator: "&")
        
        let urlString = "\(Settings.shared.baseURL)/Login/Login?\(queryString)"
        
        guard let url = URL(string: urlString) else {
            isSubmitting = false
            alertMessage = localizationManager.localize("INVALID_URL")
            showingAlert = true
            return
        }
        
        print("Login URL:", urlString)
        
        // Make API request
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    print("Network error:", error.localizedDescription)
                    alertMessage = localizationManager.localize("NETWORK_ERROR") + ": \(error.localizedDescription)"
                    showingAlert = true
                    return
                }
                
                guard let data = data else {
                    alertMessage = localizationManager.localize("NO_DATA_RECEIVED")
                    showingAlert = true
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Response:", json)
                        
                        if let errorMessage = json["ErrorMessage"] as? String {
                            alertMessage = localizationManager.localize("ERROR") + ": \(errorMessage)"
                            showingAlert = true
                            return
                        }
                        
                        if let sessionId = json["SessionId"] as? String,
                           let userType = json["UserType"] as? String {
                            
                            // Save session data
                            UserDefaults.standard.set(sessionId, forKey: "SessionId")
                            UserDefaults.standard.set(userType, forKey: "UserType")
                            
                            // Save user ID if available
                            if let userId = json["UserId"] as? String {
                                UserDefaults.standard.set(userId, forKey: "UserId")
                            }
                            
                            print("Login successful! SessionId:", sessionId, "UserType:", userType)
                            
                            // Send the locally-selected language preference to the backend
                            LocalizationManager.shared.saveLanguagePreferenceToBackend(languageCode: LocalizationManager.shared.currentLanguage)
                            
                            // Navigate to dashboard
                            navigateToDashboard = true
                        } else {
                            // Clear any stored credentials
                            UserDefaults.standard.removeObject(forKey: "SessionId")
                            UserDefaults.standard.removeObject(forKey: "UserType")
                            UserDefaults.standard.removeObject(forKey: "UserId")
                            
                            alertMessage = localizationManager.localize("INVALID_LOGIN_CREDENTIALS")
                            showingAlert = true
                        }
                    }
                } catch {
                    print("JSON parsing error:", error)
                    alertMessage = localizationManager.localize("FAILED_PARSE_RESPONSE")
                    showingAlert = true
                }
            }
        }.resume()
    }
}

#Preview {
    LoginView()
}
