//
//  PayPalCheckoutView.swift
//  Nice Traders
//
//  Credit Card Payment Form
//

import SwiftUI

struct PayPalCheckoutView: View {
    let negotiationId: String
    let onSuccess: () -> Void
    let onCancel: () -> Void
    let onError: (String) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var orderId: String?
    @State private var cardNumber = ""
    @State private var expiryMonth = ""
    @State private var expiryYear = ""
    @State private var cvv = ""
    @State private var cardholderName = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var paymentStatus: String? = nil // "card_processed", "capturing", "captured"
    @State private var isCreatingOrder = true
    
    var body: some View {
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
                    
                    if let orderId = orderId {
                        Text("Order: \(orderId.prefix(12))...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                .scaleEffect(0.8)
                            Text("Preparing order...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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
                                .disabled(isCreatingOrder)
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
                                .disabled(isCreatingOrder)
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
                                        .disabled(isCreatingOrder)
                                    
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
                                        .disabled(isCreatingOrder)
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
                                    .disabled(isCreatingOrder)
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
                            processPayment()
                        }) {
                            if isProcessing {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Processing Card...")
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
                        .disabled(isProcessing || isCreatingOrder || orderId == nil)
                        
                        Button(action: {
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
                        .disabled(isProcessing || isCreatingOrder)
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
        .onAppear {
            // Pre-populate cardholder name
            if cardholderName.isEmpty {
                let firstName = SessionManager.shared.firstName ?? ""
                let lastName = SessionManager.shared.lastName ?? ""
                let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                
                if !fullName.isEmpty {
                    cardholderName = fullName
                }
            }
            
            // Create the PayPal order in background
            createPayPalOrder()
        }
    }
    
    private func createPayPalOrder() {
        NegotiationService.shared.createPayPalOrder(listingId: negotiationId) { result in
            DispatchQueue.main.async {
                isCreatingOrder = false
                
                switch result {
                case .success(let response):
                    if response.success, let id = response.orderId {
                        self.orderId = id
                    } else {
                        errorMessage = response.error ?? "Failed to create order"
                    }
                case .failure(let error):
                    errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func processPayment() {
        if cardholderName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter name"
            return
        }
        
        if cardNumber.filter({ $0.isNumber }).count < 13 {
            errorMessage = "Invalid card number"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        // Send card details to backend for processing
        let baseURL = Settings.shared.baseURL
        let urlString = "\(baseURL)/Payments/ProcessCardPayment"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid server URL"
            isProcessing = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "orderId": orderId ?? "",
            "session_id": SessionManager.shared.session_id ?? "",
            "cardNumber": cardNumber,
            "cardholderName": cardholderName,
            "expiryMonth": expiryMonth,
            "expiryYear": expiryYear,
            "cvv": cvv
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            errorMessage = "Failed to process request"
            isProcessing = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    self.isProcessing = false
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No response from server"
                    self.isProcessing = false
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let success = json["success"] as? Bool, success {
                        self.isProcessing = false
                        self.paymentStatus = "captured"
                        // ProcessCardPayment already captured the order, so we're done
                        self.onSuccess()
                    } else {
                        let errorMsg = json["error"] as? String ?? "Payment processing failed"
                        self.errorMessage = errorMsg
                        self.isProcessing = false
                    }
                } else {
                    self.errorMessage = "Invalid response from server"
                    self.isProcessing = false
                }
            }
        }.resume()
    }
}

#Preview {
    PayPalCheckoutView(
        negotiationId: "test-negotiation",
        onSuccess: { },
        onCancel: { },
        onError: { _ in }
    )
}
