//
//  MyNegotiationsView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/26/25.
//

import SwiftUI

struct MyNegotiationsView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var negotiations: [MyNegotiationItem] = []
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
                            .multilineTextAlignment(.center)
                        Button(localizationManager.localize("RETRY")) {
                            loadNegotiations()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if negotiations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text(localizationManager.localize("NO_ACTIVE_NEGOTIATIONS"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(negotiations) { negotiation in
                                NegotiationCard(negotiation: negotiation)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(localizationManager.localize("MY_NEGOTIATIONS"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                print("VIEW: MyNegotiationsView")
                loadNegotiations()
            }
            .refreshable {
                loadNegotiations()
            }
        }
    }
    
    private func loadNegotiations() {
        isLoading = true
        errorMessage = nil
        
        NegotiationService.shared.getMyNegotiations { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success, let negs = response.negotiations {
                        negotiations = negs
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

struct NegotiationCard: View {
    let negotiation: MyNegotiationItem
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationLink(destination: NegotiationDetailView(negotiationId: negotiation.id)) {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Role + Status
                HStack {
                    // Role Badge
                    Text(negotiation.userRole == "buyer" ? localizationManager.localize("BUYER") : localizationManager.localize("SELLER"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(negotiation.userRole == "buyer" ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        .foregroundColor(negotiation.userRole == "buyer" ? .blue : .green)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    // Status Badge
                    StatusBadge(status: negotiation.status)
                }
                
                // Listing Info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(ExchangeRatesAPI.shared.formatAmount(negotiation.listing.amount, shouldRound: negotiation.listing.willRoundToNearestDollar)) \(negotiation.listing.currency)")
                            .font(.headline)
                        Text("→ \(negotiation.listing.acceptCurrency)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                Divider()
                
                // Other User Info
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.secondary)
                    Text(negotiation.otherUser.name)
                        .font(.subheadline)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", negotiation.otherUser.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Proposed Time
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text(NegotiationService.formatDate(negotiation.currentProposedTime))
                        .font(.subheadline)
                    Spacer()
                }
                
                // Payment Status
                if negotiation.status == .agreed || negotiation.status == .paidPartial {
                    Divider()
                    
                    HStack(spacing: 16) {
                        // User's payment status
                        PaymentStatusIndicator(
                            paid: negotiation.userRole == "buyer" ? negotiation.buyerPaid : negotiation.sellerPaid,
                            label: localizationManager.localize("YOU")
                        )
                        
                        // Other user's payment status
                        PaymentStatusIndicator(
                            paid: negotiation.userRole == "buyer" ? negotiation.sellerPaid : negotiation.buyerPaid,
                            label: negotiation.otherUser.name.components(separatedBy: " ").first ?? ""
                        )
                    }
                    
                    // Payment Deadline
                    if let deadline = negotiation.paymentDeadline,
                       let remaining = NegotiationService.getRemainingTime(deadline: deadline) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                            Text(remaining)
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatusBadge: View {
    let status: NegotiationStatus
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var statusText: String {
        switch status {
        case .proposed: return localizationManager.localize("STATUS_PROPOSED")
        case .countered: return localizationManager.localize("STATUS_COUNTERED")
        case .agreed: return localizationManager.localize("STATUS_AGREED")
        case .rejected: return localizationManager.localize("STATUS_REJECTED")
        case .expired: return localizationManager.localize("STATUS_EXPIRED")
        case .cancelled: return localizationManager.localize("STATUS_CANCELLED")
        case .paidPartial: return localizationManager.localize("STATUS_PAID_PARTIAL")
        case .paidComplete: return localizationManager.localize("STATUS_PAID_COMPLETE")
        }
    }
    
    var statusColor: Color {
        switch status {
        case .proposed, .countered: return .blue
        case .agreed: return .green
        case .paidPartial: return .orange
        case .paidComplete: return .purple
        case .rejected, .cancelled, .expired: return .red
        }
    }
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
}

struct PaymentStatusIndicator: View {
    let paid: Bool
    let label: String
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var body: some View {
        return VStack(spacing: 0) {
            Image(systemName: paid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(paid ? .green : .secondary)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    MyNegotiationsView()
}
