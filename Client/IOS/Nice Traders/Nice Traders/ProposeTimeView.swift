//
//  ProposeTimeView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/26/25.
//

import SwiftUI

struct ProposeTimeView: View {
    let listingId: String
    let currency: String
    let amount: Double
    let acceptCurrency: String
    let sellerName: String
    let willRoundToNearestDollar: Bool
    @Binding var navigateToDashboard: Bool
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    @State private var proposedDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var negotiationId: String?
    @State private var convertedAmount: String = "..."
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * 1 / 3, height: 6)
                    }
                }
                .frame(height: 6)
                
                Text("Step 1 of 3")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Instructions
                    VStack(spacing: 12) {
                        Text("Step 1: Propose a Meeting Time")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Choose a convenient date and time to meet \(sellerName). Once they agree, you'll both pay $2 to unlock messaging.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Listing Info Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Trading with")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(sellerName)
                                    .font(.headline)
                            }
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Exchange")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("\(String(format: willRoundToNearestDollar ? "%.0f" : "%.2f", amount)) \(currency)")
                                    .font(.headline)
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(convertedAmount) \(acceptCurrency)")
                                    .font(.headline)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .onAppear {
                        calculateConversion()
                    }
                    
                    // Date/Time Picker
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select Meeting Date & Time")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack {
                            DatePicker(
                                "Choose when to meet",
                                selection: $proposedDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Info Box
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("What happens next?")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("The seller can accept, reject, or propose a different time. Once you both agree, you'll each pay $2 within 2 hours to unlock messaging and share exact locations.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Divider()
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Meeting Location")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("The exact meeting location will be determined after both parties have paid. You'll then be able to select a specific location within the agreed distance.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    // Propose Button
                    Button(action: proposeTime) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send Proposal")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .alert("Proposal Sent!", isPresented: $showSuccess) {
                Button("OK") {
                    // Navigate back to dashboard
                    navigateToDashboard = true
                    dismiss()
                }
            } message: {
                Text("Your meeting time proposal has been sent to \(sellerName). You'll be notified when they respond.")
            }
        }
    }
    
    
    private func calculateConversion() {
        ExchangeRatesAPI.shared.convertAmount(amount, from: currency, to: acceptCurrency) { result, error in
            DispatchQueue.main.async {
                if let result = result {
                    // Format with appropriate decimal places based on rounding preference
                    if willRoundToNearestDollar {
                        convertedAmount = String(format: "%.0f", result)
                    } else if result >= 100 {
                        convertedAmount = String(format: "%.2f", result)
                    } else if result >= 10 {
                        convertedAmount = String(format: "%.2f", result)
                    } else {
                        convertedAmount = String(format: "%.4f", result)
                    }
                } else {
                    convertedAmount = "~"
                }
            }
        }
    }
    
    private func proposeTime() {
        print("[ProposeTimeView] 🚀 Starting negotiation proposal")
        print("[ProposeTimeView] Listing ID: \(listingId)")
        print("[ProposeTimeView] Proposed Date: \(proposedDate)")
        
        isLoading = true
        errorMessage = nil
        
        NegotiationService.shared.proposeNegotiation(listingId: listingId, proposedTime: proposedDate) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                print("[ProposeTimeView] 📬 Received response")
                
                switch result {
                case .success(let response):
                    print("[ProposeTimeView] ✅ Success response: \(response)")
                    if response.success, let negId = response.negotiationId {
                        print("[ProposeTimeView] 🎉 Negotiation created: \(negId)")
                        negotiationId = negId
                        showSuccess = true
                    } else {
                        let error = response.error ?? localizationManager.localize("UNKNOWN_ERROR")
                        print("[ProposeTimeView] ⚠️ Success=false, error: \(error)")
                        errorMessage = error
                    }
                case .failure(let error):
                    print("[ProposeTimeView] ❌ Failure: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    @State var navigateToDashboard = false
    return ProposeTimeView(
        listingId: "LST-123",
        currency: "USD",
        amount: 1000.0,
        acceptCurrency: "EUR",
        sellerName: "John Doe",
        willRoundToNearestDollar: false,
        navigateToDashboard: $navigateToDashboard
    )
}
