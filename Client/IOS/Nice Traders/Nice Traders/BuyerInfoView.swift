//
//  BuyerInfoView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/26/25.
//

import SwiftUI

struct BuyerInfoView: View {
    let buyerId: String
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    @State private var buyerInfo: BuyerInfo?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button(localizationManager.localize("RETRY")) {
                            loadBuyerInfo()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let buyer = buyerInfo {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            VStack(spacing: 12) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.blue)
                                
                                Text("\(buyer.firstName) \(buyer.lastName)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                HStack(spacing: 16) {
                                    // Rating
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", buyer.rating))
                                            .font(.headline)
                                    }
                                    
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    
                                    // Total Exchanges
                                    Text("\(buyer.totalExchanges) \(localizationManager.localize("EXCHANGES"))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            
                            // Member Since
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.secondary)
                                Text("\(localizationManager.localize("MEMBER_SINCE")) \(formatMemberSince(buyer.memberSince))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            // Recent Ratings
                            if !buyer.recentRatings.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(localizationManager.localize("RECENT_RATINGS"))
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ForEach(buyer.recentRatings) { rating in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                ForEach(0..<5) { index in
                                                    Image(systemName: index < rating.rating ? "star.fill" : "star")
                                                        .foregroundColor(.yellow)
                                                        .font(.caption)
                                                }
                                                Spacer()
                                                if let date = rating.date {
                                                    Text(NegotiationService.formatDate(date))
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            if let review = rating.review, !review.isEmpty {
                                                Text(review)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding()
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            // Transaction History
                            if !buyer.transactionHistory.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(localizationManager.localize("TRANSACTION_HISTORY"))
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ForEach(buyer.transactionHistory) { transaction in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("\(String(format: "%.2f", transaction.amount)) \(transaction.currency)")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                if let date = transaction.date {
                                                    Text(NegotiationService.formatDate(date))
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            if let rating = transaction.rating {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "star.fill")
                                                        .font(.caption)
                                                        .foregroundColor(.yellow)
                                                    Text("\(rating)")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            // Trust Indicator
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: buyer.rating >= 4.0 ? "checkmark.shield.fill" : "shield.fill")
                                    .foregroundColor(buyer.rating >= 4.0 ? .green : .blue)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(buyer.rating >= 4.0 ? 
                                        localizationManager.localize("TRUSTED_TRADER") :
                                        localizationManager.localize("VERIFIED_TRADER"))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(buyer.rating >= 4.0 ?
                                        localizationManager.localize("TRUSTED_TRADER_DESC") :
                                        localizationManager.localize("VERIFIED_TRADER_DESC"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background((buyer.rating >= 4.0 ? Color.green : Color.blue).opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
            }
            .navigationTitle(localizationManager.localize("BUYER_INFO"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localize("DONE")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadBuyerInfo()
            }
        }
    }
    
    private func loadBuyerInfo() {
        isLoading = true
        errorMessage = nil
        
        NegotiationService.shared.getBuyerInfo(buyerId: buyerId) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success, let buyer = response.buyer {
                        buyerInfo = buyer
                    } else {
                        errorMessage = response.error ?? localizationManager.localize("UNKNOWN_ERROR")
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func formatMemberSince(_ dateString: String) -> String {
        return DateFormatters.formatCompact(dateString)
    }
}

#Preview {
    BuyerInfoView(buyerId: "USR-123")
}
