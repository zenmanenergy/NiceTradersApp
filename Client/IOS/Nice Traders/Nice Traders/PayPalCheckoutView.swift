//
//  PayPalCheckoutView.swift
//  Nice Traders
//
//  Credit Card Payment Form
//

import SwiftUI

struct PayPalCheckoutView: View {
    let orderId: String
    let listingId: String
    let cardholderNameInitial: String
    let onSuccess: () -> Void
    let onCancel: () -> Void
    let onError: (String) -> Void
    
    @Environment(\.dismiss) var dismiss: DismissAction
    @State private var cardNumber = ""
    @State private var expiryMonth = ""
    @State private var expiryYear = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var isProcessing = false
    @State private var isCaptureProcessing = false
    @State private var errorMessage: String?
    @State private var paymentStatus: String? = nil // "card_processed", "capturing", "captured"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("Payment")
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                            Image(systemName: "creditcard.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .padding()
                        
                        Text("Order: \(orderId.prefix(12))...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .background(Color.white)
                    
                    Divider()
                    
                    // Form
                    ScrollView {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cardholder Name")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                TextField("John Doe", text: $cardholderName)
                                    .textContentType(.name)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Card Number")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                TextField("1234 5678 9012 3456", text: $cardNumber)
                                    .textContentType(.creditCardNumber)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Expires")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    HStack(spacing: 8) {
                                        TextField("MM", text: $expiryMonth)
                                            .keyboardType(.numberPad)
                                            .frame(maxWidth: 50)
                                            .padding(12)
                                            .background(Color.white)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                        
                                        Text("/")
                                            .foregroundColor(.secondary)
                                        
                                        TextField("YY", text: $expiryYear)
                                            .keyboardType(.numberPad)
                                            .frame(maxWidth: 50)
                                            .padding(12)
                                            .background(Color.white)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("CVV")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    TextField("123", text: $cvv)
                                        .textContentType(.creditCardSecurityCode)
                                        .keyboardType(.numberPad)
                                        .padding(12)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                            
                            if let error = errorMessage {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                    
                                    Text(error)
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(16)
                    }
                    
                    // Status messages
                    if let status = paymentStatus {
                        HStack(spacing: 12) {
                            if status == "card_processed" {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Card processed. Finalizing payment...")
                                    .font(.subheadline)
                            } else if status == "capturing" {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                Text("Finalizing PayPal payment...")
                                    .font(.subheadline)
                            } else if status == "captured" {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Payment complete!")
                                    .font(.subheadline)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(status == "captured" ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .padding(16)
                    }
                    
                    // Buttons
                    VStack(spacing: 12) {
                        if paymentStatus != "captured" {
                            Button(action: {
                                print("[PAY BUTTON] TAPPED")
                                processPayment()
                            }) {
                                if isProcessing || isCaptureProcessing {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        Text(isProcessing ? "Processing Card..." : "Finalizing Payment...")
                                            .fontWeight(.semibold)
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Pay $2.00")
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(isProcessing || isCaptureProcessing)
                            
                            Button(action: {
                                print("[CANCEL BUTTON] TAPPED")
                                onCancel()
                                dismiss()
                            }) {
                                Text("Cancel")
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                            .disabled(isProcessing || isCaptureProcessing)
                        } else {
                            Button(action: { dismiss() }) {
                                Text("Done")
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            print("[PayPalCheckoutView] 🟠 onAppear called")
            print("[PayPalCheckoutView] 🟠 orderId: \(orderId)")
            print("[PayPalCheckoutView] 🟠 cardholderNameInitial: '\(cardholderNameInitial)'")
            
            // DEBUG: Print user details from SessionManager
            print("[PayPalCheckoutView] DEBUG - SessionManager.firstName: '\(SessionManager.shared.firstName ?? "nil")'")
            print("[PayPalCheckoutView] DEBUG - SessionManager.lastName: '\(SessionManager.shared.lastName ?? "nil")'")
            print("[PayPalCheckoutView] DEBUG - SessionManager.user_id: '\(SessionManager.shared.user_id ?? "nil")'")
            
            print("[PayPalCheckoutView] 🟠 cardholderName before: '\(cardholderName)'")
            
            // Pre-populate cardholder name with user's first and last name from SessionManager
            if cardholderName.isEmpty {
                let firstName = SessionManager.shared.firstName ?? ""
                let lastName = SessionManager.shared.lastName ?? ""
                let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                
                print("[PayPalCheckoutView] DEBUG - firstName from session: '\(firstName)'")
                print("[PayPalCheckoutView] DEBUG - lastName from session: '\(lastName)'")
                print("[PayPalCheckoutView] DEBUG - fullName combined: '\(fullName)'")
                
                if !fullName.isEmpty {
                    cardholderName = fullName
                    print("[PayPalCheckoutView] ✅ Set cardholderName to: '\(cardholderName)'")
                } else if !cardholderNameInitial.isEmpty {
                    cardholderName = cardholderNameInitial
                    print("[PayPalCheckoutView] ✅ Set cardholderName to initial: '\(cardholderName)'")
                } else {
                    print("[PayPalCheckoutView] ⚠️  No name available from session or initial")
                }
            }
            print("[PayPalCheckoutView] 🟠 cardholderName after: '\(cardholderName)'")
        }
    }
    
    private func processPayment() {
        print("[PROCESS PAYMENT] Called for orderId: \(orderId)")
        print("[PROCESS PAYMENT] Card: \(cardNumber), Name: \(cardholderName)")
        
        if cardholderName.trimmingCharacters(in: .whitespaces).isEmpty {
            print("[PROCESS PAYMENT] ERROR: Empty name")
            errorMessage = "Please enter name"
            return
        }
        
        if cardNumber.filter({ $0.isNumber }).count < 13 {
            print("[PROCESS PAYMENT] ERROR: Invalid card")
            errorMessage = "Invalid card number"
            return
        }
        
        print("[PROCESS PAYMENT] Validation passed, processing...")
        isProcessing = true
        errorMessage = nil
        
        // Send card details to backend for processing
        let baseURL = Settings.shared.baseURL
        let urlString = "\(baseURL)/Payments/ProcessCardPayment"
        
        guard let url = URL(string: urlString) else {
            print("[PROCESS PAYMENT] ERROR: Invalid URL")
            errorMessage = "Invalid server URL"
            isProcessing = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "orderId": orderId,
            "sessionId": SessionManager.shared.sessionId ?? "",
            "cardNumber": cardNumber,
            "cardholderName": cardholderName,
            "expiryMonth": expiryMonth,
            "expiryYear": expiryYear,
            "cvv": cvv
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("[PROCESS PAYMENT] ERROR: Failed to encode request - \(error)")
            errorMessage = "Failed to process request"
            isProcessing = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                print("[PROCESS PAYMENT] Backend response received")
                
                if let error = error {
                    print("[PROCESS PAYMENT] ERROR: Network error - \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    self.isProcessing = false
                    return
                }
                
                guard let data = data else {
                    print("[PROCESS PAYMENT] ERROR: No response data")
                    self.errorMessage = "No response from server"
                    self.isProcessing = false
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("[PROCESS PAYMENT] Response: \(json)")
                    
                    if let success = json["success"] as? Bool, success {
                        print("[PROCESS PAYMENT] ✅ SUCCESS - ProcessCardPayment already captured the order")
                        print("[PROCESS PAYMENT] ✅ Payment is complete, no need to call capturePayPalOrder again")
                        self.isProcessing = false
                        self.paymentStatus = "captured"
                        print("[PROCESS PAYMENT] ✅ Set paymentStatus = captured, calling onSuccess()")
                        // ProcessCardPayment already captured the order, so we're done
                        self.onSuccess()
                    } else {
                        let errorMsg = json["error"] as? String ?? "Payment processing failed"
                        print("[PROCESS PAYMENT] ERROR: \(errorMsg)")
                        self.errorMessage = errorMsg
                        self.isProcessing = false
                    }
                } else {
                    print("[PROCESS PAYMENT] ERROR: Failed to parse response")
                    self.errorMessage = "Invalid response from server"
                    self.isProcessing = false
                }
            }
        }.resume()
    }
    
    private func capturePayPalOrder() {
        // Prevent double-tapping the pay button
        if isCaptureProcessing {
            print("[PayPalCheckoutView] Capture already in progress, ignoring duplicate call")
            return
        }
        
        print("[PayPalCheckoutView] Starting PayPal capture for order: \(orderId)")
        isCaptureProcessing = true
        paymentStatus = "capturing"
        errorMessage = nil
        print("[PayPal-Capture] ✅ Reset: paymentStatus=capturing, errorMessage=nil")
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Payments/CaptureOrder")!
        
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            isCaptureProcessing = false
            return
        }
        
        components.queryItems = [
            URLQueryItem(name: "orderId", value: orderId),
            URLQueryItem(name: "listingId", value: listingId),
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "userId", value: SessionManager.shared.user_id ?? "")
        ]
        
        guard let url = components.url else {
            errorMessage = "Failed to construct capture URL"
            isCaptureProcessing = false
            return
        }
        
        print("[PayPalCheckoutView] Calling capture endpoint: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            print("[PayPal-Capture] 📨 RESPONSE RECEIVED from backend")
            DispatchQueue.main.async {
                print("[PayPal-Capture] 📍 On main thread - processing response")
                self.isCaptureProcessing = false
                print("[PayPal-Capture] ✅ Set isCaptureProcessing = false")
                
                if let error = error {
                    print("[PayPalCheckoutView] Capture error: \(error.localizedDescription)")
                    self.errorMessage = "Capture failed: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No response from capture endpoint"
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("[PayPal-Capture] 📦 Parsed JSON: \\(json)")
                    
                    if let success = json["success"] as? Bool, success {
                        print("[PayPal-Capture] ✅✅✅ SUCCESS! Calling onSuccess()")
                        self.paymentStatus = "captured"
                        print("[PayPal-Capture] ✅ paymentStatus = captured")
                        self.onSuccess()
                    } else {
                        let errorMsg = json["error"] as? String ?? "Payment capture failed"
                        print("[PayPal-Capture] ❌❌❌ FAILED: \(errorMsg)")
                        print("[PayPal-Capture] ❌ Setting errorMessage")
                        self.errorMessage = "Payment failed: \(errorMsg)"
                        print("[PayPal-Capture] ❌ errorMessage is now: \(self.errorMessage ?? "nil")")
                    }
                } else {
                    print("[PayPalCheckoutView] Failed to parse capture response")
                    self.errorMessage = "Invalid response from payment server"
                }
            }
        }.resume()
    }
}

#Preview {
    PayPalCheckoutView(
        orderId: "test-order",
        listingId: "test-listing",
        cardholderNameInitial: "John Doe",
        onSuccess: { },
        onCancel: { },
        onError: { _ in }
    )
}
