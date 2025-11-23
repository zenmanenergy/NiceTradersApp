//
//  LoginView.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                
                Text("Sign In")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]),
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
                        
                        Text("Welcome Back")
                            .font(.system(size: 29, weight: .semibold))
                            .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
                        
                        Text("Sign in to continue exchanging currency")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                    
                    // Form
                    VStack(spacing: 24) {
                        FormField(
                            label: "Email Address",
                            text: $email,
                            placeholder: "Enter your email",
                            keyboardType: .emailAddress,
                            error: errors["email"]
                        )
                        
                        FormField(
                            label: "Password",
                            text: $password,
                            placeholder: "Enter your password",
                            isSecure: true,
                            error: errors["password"]
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Forgot Password
                    HStack {
                        Spacer()
                        Button(action: {
                            alertMessage = "Forgot Password coming soon!"
                            showingAlert = true
                        }) {
                            Text("Forgot Password?")
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
                                Text("Signing In...")
                            } else {
                                Text("Sign In")
                            }
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.4), radius: 15, y: 4)
                    }
                    .disabled(isSubmitting)
                    .opacity(isSubmitting ? 0.7 : 1.0)
                    .padding(.horizontal, 24)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color(red: 0.89, green: 0.91, blue: 0.94))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.63, green: 0.68, blue: 0.75))
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(Color(red: 0.89, green: 0.91, blue: 0.94))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    
                    // Social Login
                    Button(action: {
                        alertMessage = "Google Sign In coming soon!"
                        showingAlert = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                            Text("Continue with Google")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Signup Link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                        
                        Button(action: {
                            // Navigate to signup - will be handled by parent
                            dismiss()
                        }) {
                            Text("Sign Up")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                        }
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 32)
                }
            }
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
        .alert("Login", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
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
            errors["email"] = "Email is required"
        } else if !email.contains("@") || !email.contains(".") {
            errors["email"] = "Please enter a valid email"
        }
        
        if password.isEmpty {
            errors["password"] = "Password is required"
        }
        
        return errors.isEmpty
    }
    
    func handleSubmit() {
        guard validateForm() else { return }
        
        isSubmitting = true
        
        // Prepare data for API
        let parameters: [String: String] = [
            "Email": email,
            "Password": password
        ]
        
        // Build query string
        let queryString = parameters.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }.joined(separator: "&")
        
        let urlString = "\(Settings.shared.baseURL)/Login/Login?\(queryString)"
        
        guard let url = URL(string: urlString) else {
            isSubmitting = false
            alertMessage = "Invalid URL"
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
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showingAlert = true
                    return
                }
                
                guard let data = data else {
                    alertMessage = "No data received from server"
                    showingAlert = true
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Response:", json)
                        
                        if let errorMessage = json["ErrorMessage"] as? String {
                            alertMessage = "Error: \(errorMessage)"
                            showingAlert = true
                            return
                        }
                        
                        if let sessionId = json["SessionId"] as? String,
                           let userType = json["UserType"] as? String {
                            
                            // Save session data
                            UserDefaults.standard.set(sessionId, forKey: "SessionId")
                            UserDefaults.standard.set(userType, forKey: "UserType")
                            
                            print("Login successful! SessionId:", sessionId, "UserType:", userType)
                            
                            // Navigate to dashboard
                            navigateToDashboard = true
                        } else {
                            // Clear any stored credentials
                            UserDefaults.standard.removeObject(forKey: "SessionId")
                            UserDefaults.standard.removeObject(forKey: "UserType")
                            
                            alertMessage = "Invalid login credentials"
                            showingAlert = true
                        }
                    }
                } catch {
                    print("JSON parsing error:", error)
                    alertMessage = "Failed to parse server response"
                    showingAlert = true
                }
            }
        }.resume()
    }
}

#Preview {
    LoginView()
}
