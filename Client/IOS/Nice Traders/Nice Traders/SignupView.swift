//
//  SignupView.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @State private var errors: [String: String] = [:]
    @State private var isSubmitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showLogin = false
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
                
                Text("Create Account")
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
                    // Welcome Text
                    VStack(spacing: 8) {
                        Text("Join NICE Traders")
                            .font(.system(size: 29, weight: .semibold))
                            .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
                        
                        Text("Start exchanging currency with your neighbors")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 32)
                    
                    // Form
                    VStack(spacing: 24) {
                        // Name Row
                        HStack(spacing: 16) {
                            FormField(
                                label: "First Name",
                                text: $firstName,
                                placeholder: "Enter your first name",
                                error: errors["firstName"]
                            )
                            
                            FormField(
                                label: "Last Name",
                                text: $lastName,
                                placeholder: "Enter your last name",
                                error: errors["lastName"]
                            )
                        }
                        
                        FormField(
                            label: "Email Address",
                            text: $email,
                            placeholder: "Enter your email",
                            keyboardType: .emailAddress,
                            error: errors["email"]
                        )
                        
                        FormField(
                            label: "Phone Number",
                            text: $phone,
                            placeholder: "Enter your phone number",
                            keyboardType: .phonePad,
                            error: errors["phone"]
                        )
                        
                        FormField(
                            label: "Password",
                            text: $password,
                            placeholder: "Create a password",
                            isSecure: true,
                            error: errors["password"]
                        )
                        
                        FormField(
                            label: "Confirm Password",
                            text: $confirmPassword,
                            placeholder: "Confirm your password",
                            isSecure: true,
                            error: errors["confirmPassword"]
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Submit Button
                    Button(action: handleSubmit) {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Creating Account...")
                            } else {
                                Text("Create Account")
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
                    .padding(.top, 16)
                    
                    // Login Link
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                        
                        Button(action: {
                            showLogin = true
                        }) {
                            Text("Sign In")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                        }
                    }
                    .padding(.top, 24)
                    
                    // Terms
                    Text("By creating an account, you agree to our **Terms of Service** and **Privacy Policy**")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.63, green: 0.68, blue: 0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .background(Color.white)
        .alert("Signup", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .navigationDestination(isPresented: $showLogin) {
            LoginView()
        }
        .navigationDestination(isPresented: $navigateToDashboard) {
            DashboardView()
        }
    }
    
    func validateForm() -> Bool {
        errors = [:]
        
        if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors["firstName"] = "First name is required"
        }
        
        if lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors["lastName"] = "Last name is required"
        }
        
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errors["email"] = "Email is required"
        } else if !email.contains("@") || !email.contains(".") {
            errors["email"] = "Please enter a valid email"
        }
        
        if phone.trimmingCharacters(in: .whitespaces).isEmpty {
            errors["phone"] = "Phone number is required"
        }
        
        if password.isEmpty {
            errors["password"] = "Password is required"
        } else if password.count < 6 {
            errors["password"] = "Password must be at least 6 characters"
        }
        
        if password != confirmPassword {
            errors["confirmPassword"] = "Passwords do not match"
        }
        
        return errors.isEmpty
    }
    
    func handleSubmit() {
        guard validateForm() else { return }
        
        isSubmitting = true
        
        // Prepare data for API
        let parameters: [String: String] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "phone": phone,
            "password": password
        ]
        
        // Build query string
        let queryString = parameters.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }.joined(separator: "&")
        
        let urlString = "\(Settings.shared.baseURL)/Signup/CreateAccount?\(queryString)"
        
        guard let url = URL(string: urlString) else {
            isSubmitting = false
            alertMessage = "Invalid URL"
            showingAlert = true
            return
        }
        
        print("Signup URL:", urlString)
        
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
                        
                        if let success = json["success"] as? Bool,
                           success,
                           let sessionId = json["sessionId"] as? String,
                           let userType = json["userType"] as? String {
                            
                            // Save session data
                            UserDefaults.standard.set(sessionId, forKey: "SessionId")
                            UserDefaults.standard.set(userType, forKey: "UserType")
                            
                            print("Signup successful! SessionId:", sessionId, "UserType:", userType)
                            
                            // Navigate to dashboard
                            navigateToDashboard = true
                        } else {
                            let errorMsg = json["error"] as? String ?? "Unknown error"
                            alertMessage = "Signup failed: \(errorMsg)"
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

struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(error != nil ? Color(red: 0.9, green: 0.24, blue: 0.24) : Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 2)
            )
            .cornerRadius(12)
            .font(.system(size: 16))
            
            if let error = error {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.9, green: 0.24, blue: 0.24))
            }
        }
    }
}

#Preview {
    SignupView()
}
