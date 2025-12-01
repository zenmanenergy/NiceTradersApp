//
//  PaymentView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/26/25.
//

import SwiftUI

struct PaymentView: View {
    let negotiationId: String
    let userRole: String
    let otherUserName: String
    let onComplete: () -> Void
    let onBothPaid: (() -> Void)?
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var availableCredit: Double = 0
    @State private var showSuccess = false
    @State private var paymentResult: PaymentResponse?
    
    let feeAmount = 2.00
    
    var amountToPay: Double {
        max(0, feeAmount - availableCredit)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.purple)
                            
                            Text(localizationManager.localize("PAYMENT_REQUIRED"))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(localizationManager.localize("PAYMENT_SUBTITLE"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top)
                        
                        // Fee Breakdown
                        VStack(alignment: .leading, spacing: 16) {
                            Text(localizationManager.localize("FEE_BREAKDOWN"))
                                .font(.headline)
                            
                            // Base Fee
                            HStack {
                                Text(localizationManager.localize("NEGOTIATION_FEE"))
                                    .font(.subheadline)
                                Spacer()
                                Text("$\(String(format: "%.2f", feeAmount))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            // Credit Applied
                            if availableCredit > 0 {
                                HStack {
                                    Text(localizationManager.localize("CREDIT_APPLIED"))
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                    Spacer()
                                    Text("-$\(String(format: "%.2f", min(availableCredit, feeAmount)))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                
                                Divider()
                            }
                            
                            // Total
                            HStack {
                                Text(localizationManager.localize("TOTAL_DUE"))
                                    .font(.headline)
                                Spacer()
                                Text("$\(String(format: "%.2f", amountToPay))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Info Box
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.localize("PAYMENT_INFO_TITLE"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(String(format: localizationManager.localize("PAYMENT_INFO_MESSAGE"), otherUserName))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Error Message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        // Pay Button
                        Button(action: processPayment) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(localizationManager.localize("CONFIRM_PAYMENT"))
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localize("CANCEL")) {
                        dismiss()
                    }
                }
            }
            .alert(localizationManager.localize("PAYMENT_SUCCESS"), isPresented: $showSuccess) {
                if let result = paymentResult, result.bothPaid == true {
                    Button(localizationManager.localize("VIEW_ACTIVE_EXCHANGE")) {
                        dismiss()
                        onBothPaid?()
                    }
                } else {
                    Button(localizationManager.localize("OK")) {
                        dismiss()
                        onComplete()
                    }
                }
            } message: {
                if let result = paymentResult {
                    if result.bothPaid == true {
                        Text(localizationManager.localize("BOTH_PAID_MESSAGE"))
                    } else {
                        Text(localizationManager.localize("WAITING_OTHER_PAYMENT"))
                    }
                }
            }
        }
    }
    
    private func processPayment() {
        isLoading = true
        errorMessage = nil
        
        NegotiationService.shared.payNegotiationFee(negotiationId: negotiationId) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        paymentResult = response
                        showSuccess = true
                    } else {
                        errorMessage = response.error ?? localizationManager.localize("PAYMENT_FAILED")
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    PaymentView(
        negotiationId: "NEG-123",
        userRole: "buyer",
        otherUserName: "John",
        onComplete: {
        },
        onBothPaid: nil
    )
}
