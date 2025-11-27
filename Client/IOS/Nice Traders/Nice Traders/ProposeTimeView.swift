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
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    @State private var proposedDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var negotiationId: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Info
                        VStack(spacing: 12) {
                            Text(localizationManager.localize("PROPOSE_MEETING_TIME"))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(localizationManager.localize("PROPOSE_MEETING_SUBTITLE"))
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
                                    Text(localizationManager.localize("TRADING_WITH"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(sellerName)
                                        .font(.headline)
                                }
                                Spacer()
                            }
                            
                            Divider()
                            
                            HStack {
                                Text(localizationManager.localize("LISTING"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("\(String(format: "%.2f", amount)) \(currency)")
                                        .font(.headline)
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(acceptCurrency)
                                        .font(.headline)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Date/Time Picker
                        VStack(alignment: .leading, spacing: 16) {
                            Text(localizationManager.localize("PROPOSED_MEETING_TIME"))
                                .font(.headline)
                                .padding(.horizontal)
                            
                            DatePicker(
                                localizationManager.localize("SELECT_DATE_TIME"),
                                selection: $proposedDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Info Box
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.localize("PROPOSAL_INFO_TITLE"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(localizationManager.localize("PROPOSAL_INFO_MESSAGE"))
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
                        
                        // Propose Button
                        Button(action: proposeTime) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(localizationManager.localize("SEND_PROPOSAL"))
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localize("CANCEL")) {
                        dismiss()
                    }
                }
            }
            .alert(localizationManager.localize("SUCCESS"), isPresented: $showSuccess) {
                Button(localizationManager.localize("OK")) {
                    dismiss()
                }
            } message: {
                Text(localizationManager.localize("PROPOSAL_SENT_MESSAGE"))
            }
        }
    }
    
    private func proposeTime() {
        isLoading = true
        errorMessage = nil
        
        NegotiationService.shared.proposeNegotiation(listingId: listingId, proposedTime: proposedDate) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success, let negId = response.negotiationId {
                        negotiationId = negId
                        showSuccess = true
                    } else {
                        errorMessage = response.error ?? localizationManager.localize("UNKNOWN_ERROR")
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ProposeTimeView(
        listingId: "LST-123",
        currency: "USD",
        amount: 1000.0,
        acceptCurrency: "EUR",
        sellerName: "John Doe"
    )
}
