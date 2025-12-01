//
//  SignupView.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import SwiftUI
import UIKit

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    
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
                
                Text(localizationManager.localize("SIGN_UP"))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46,  green: 0.29, blue: 0.64)]),                                                                                                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            ScrollView {
                VStack(spacing: 0) {
                    // Welcome Text
                    VStack(spacing: 8) {
                        Text(localizationManager.localize("JOIN_NICE_TRADERS"))
                            .font(.system(size: 29, weight: .semibold))
                            .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
                        
                        Text(localizationManager.localize("START_EXCHANGING_WITH_NEIGHBORS"))
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    
                    // Form
                    VStack(spacing: 24) {
                        // Name Row
                        HStack(spacing: 16) {
                            FormField(
                                label: localizationManager.localize("FIRST_NAME"),
                                text: $firstName,
                                placeholder: localizationManager.localize("ENTER_FIRST_NAME"),
                                error: errors["firstName"]
                            )
                            
                            FormField(
                                label: localizationManager.localize("LAST_NAME"),
                                text: $lastName,
                                placeholder: localizationManager.localize("ENTER_LAST_NAME"),
                                error: errors["lastName"]
                            )
                        }
                        
                        FormField(
                            label: localizationManager.localize("EMAIL"),
                            text: $email,
                            placeholder: localizationManager.localize("ENTER_EMAIL"),
                            keyboardType: .emailAddress,
                            error: errors["email"]
                        )
                        
                        FormField(
                            label: localizationManager.localize("PHONE_NUMBER"),
                            text: $phone,
                            placeholder: localizationManager.localize("ENTER_PHONE"),
                            keyboardType: .phonePad,
                            error: errors["phone"]
                        )
                        
                        FormField(
                            label: localizationManager.localize("PASSWORD"),
                            text: $password,
                            placeholder: localizationManager.localize("CREATE_PASSWORD"),
                            isSecure: true,
                            error: errors["password"]
                        )
                        
                        FormField(
                            label: localizationManager.localize("CONFIRM_PASSWORD"),
                            text: $confirmPassword,
                            placeholder: localizationManager.localize("CONFIRM_PASSWORD_PLACEHOLDER"),
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
                                Text(localizationManager.localize("CREATING_ACCOUNT"))
                            } else {
                                Text(localizationManager.localize("SIGN_UP"))
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
                    .padding(.top, 16)
                    
                    // Login Link
                    HStack(spacing: 4) {
                        Text(localizationManager.localize("ALREADY_HAVE_ACCOUNT"))
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                        
                        Button(action: {
                            showLogin = true
                        }) {
                            Text(localizationManager.localize("SIGN_IN"))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                        }
                    }
                    .padding(.top, 24)
                    
                    // Terms
                    Text(localizationManager.localize("TERMS_AND_PRIVACY"))
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.63, green: 0.68, blue: 0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarHidden(true)
        .background(Color.white)
        .alert(localizationManager.localize("SIGNUP"), isPresented: $showingAlert) {
            Button(localizationManager.localize("OK"), role: .cancel) { }
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
            errors["firstName"] = localizationManager.localize("FIRST_NAME_REQUIRED")
        }
        
        if lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors["lastName"] = localizationManager.localize("LAST_NAME_REQUIRED")
        }
        
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errors["email"] = localizationManager.localize("EMAIL_REQUIRED")
        } else if !email.contains("@") || !email.contains(".") {
            errors["email"] = localizationManager.invalidEmail
        }
        
        if phone.trimmingCharacters(in: .whitespaces).isEmpty {
            errors["phone"] = localizationManager.localize("PHONE_REQUIRED")
        }
        
        if password.isEmpty {
            errors["password"] = localizationManager.localize("PASSWORD_REQUIRED")
        } else if password.count < 6 {
            errors["password"] = localizationManager.localize("PASSWORD_MIN_LENGTH")
        }
        
        if password != confirmPassword {
            errors["confirmPassword"] = localizationManager.passwordMismatch
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
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "phone": phone,
            "password": password
        ]
        
        // Add device information if available
        parameters.merge(deviceInfo) { (_, new) in new }
        
        // Build query string
        let queryString = parameters.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }.joined(separator: "&")
        
        let urlString = "\(Settings.shared.baseURL)/Signup/CreateAccount?\(queryString)"
        
        guard let url = URL(string: urlString) else {
            isSubmitting = false
            alertMessage = localizationManager.localize("INVALID_URL")
            showingAlert = true
            return
        }
        // Make API request
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
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
                        if let errorMessage = json["ErrorMessage"] as? String {
                            alertMessage = localizationManager.error + ": \(errorMessage)"
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
                            
                            // Save user ID if available
                            if let userId = json["userId"] as? String {
                                UserDefaults.standard.set(userId, forKey: "UserId")
                                
                                // If device token is already available, update it now
                                if let deviceToken = DeviceTokenManager.shared.deviceToken {
                                    DeviceTokenManager.shared.updateDeviceTokenForUser(userId: userId, deviceToken: deviceToken)
                                }
                            }
                            // Send the locally-selected language preference to the backend
                            LocalizationManager.shared.saveLanguagePreferenceToBackend(languageCode: LocalizationManager.shared.currentLanguage)
                            
                            // Navigate to dashboard
                            navigateToDashboard = true
                        } else {
                            let errorMsg = json["error"] as? String ?? localizationManager.localize("UNKNOWN_ERROR")
                            alertMessage = localizationManager.localize("SIGNUP_FAILED") + ": \(errorMsg)"
                            showingAlert = true
                        }
                    }
                } catch {
                    alertMessage = localizationManager.localize("FAILED_PARSE_RESPONSE")
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
            
            ZStack {
                if isSecure {
                    NoHapticSecureField(placeholder: placeholder, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                } else {
                    NoHapticTextField(placeholder: placeholder, text: $text, keyboardType: keyboardType)
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

struct NoHapticTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
        textField.font = UIFont.systemFont(ofSize: 16)
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        @objc func textChanged(_ textField: UITextField) {
            text = textField.text ?? ""
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            // Override to prevent default behavior
        }
    }
}

struct NoHapticSecureField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
        textField.font = UIFont.systemFont(ofSize: 16)
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        @objc func textChanged(_ textField: UITextField) {
            text = textField.text ?? ""
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            // Override to prevent default behavior
        }
    }
}

#Preview {
    SignupView()
}
