//
//  NegotiationDetailView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/26/25.
//

import SwiftUI

struct NegotiationDetailView: View {
    let negotiationId: String
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    @State private var negotiation: NegotiationDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCounterProposal = false
    @State private var showPayment = false
    @State private var showBuyerInfo = false
    @State private var isProcessing = false
    @State private var actionMessage: String?
    
    var body: some View {
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
                        loadNegotiation()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if let negotiation = negotiation {
                ScrollView {
                    VStack(spacing: 20) {
                        // Proposed Time (moved to top)
                        proposedTimeCard(negotiation)
                        
                        // Status Header
                        statusHeader(negotiation)
                        
                        // Listing Info
                        listingInfo(negotiation)
                        
                        // Other User Info
                        otherUserInfo(negotiation)
                        
                        // Payment Status (if agreed)
                        if negotiation.negotiation.status == .agreed || negotiation.negotiation.status == .paidPartial {
                            paymentStatusCard(negotiation)
                        }
                        
                        // Action Buttons
                        actionButtons(negotiation)
                        
                        // History
                        historySection(negotiation)
                        
                        // Action Message
                        if let actionMessage = actionMessage {
                            Text(actionMessage)
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding()
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(localizationManager.localize("NEGOTIATION_DETAILS"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadNegotiation()
        }
        .sheet(isPresented: $showCounterProposal) {
            if let negotiation = negotiation {
                CounterProposalSheet(
                    negotiationId: negotiationId,
                    currentTime: negotiation.negotiation.currentProposedTime
                ) {
                    loadNegotiation()
                }
            }
        }
        .sheet(isPresented: $showPayment) {
            if let negotiation = negotiation {
                PaymentView(
                    negotiationId: negotiationId,
                    userRole: negotiation.userRole,
                    otherUserName: negotiation.userRole == "buyer" ? negotiation.seller.firstName : negotiation.buyer.firstName
                ) {
                    loadNegotiation()
                }
            }
        }
        .sheet(isPresented: $showBuyerInfo) {
            if let negotiation = negotiation, negotiation.userRole == "seller" {
                BuyerInfoView(buyerId: negotiation.buyer.userId)
            }
        }
    }
    
    // MARK: - View Components
    
    private func statusHeader(_ negotiation: NegotiationDetail) -> some View {
        VStack(spacing: 8) {
            StatusBadge(status: negotiation.negotiation.status)
            
            if negotiation.negotiation.status == .proposed || negotiation.negotiation.status == .countered {
                let isWaitingForMe = negotiation.negotiation.proposedBy != (negotiation.userRole == "buyer" ? negotiation.buyer.userId : negotiation.seller.userId)
                
                Text(isWaitingForMe ? 
                    localizationManager.localize("WAITING_FOR_YOUR_RESPONSE") :
                    localizationManager.localize("WAITING_FOR_OTHER_RESPONSE"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func listingInfo(_ negotiation: NegotiationDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localize("LISTING"))
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(String(format: "%.2f", negotiation.listing.amount)) \(negotiation.listing.currency)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if let usdValue = calculateUSDValue(amount: negotiation.listing.amount, currency: negotiation.listing.currency) {
                        Text("→ \(negotiation.listing.acceptCurrency) (≈ $\(String(format: "%.2f", usdValue)) USD)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("→ \(negotiation.listing.acceptCurrency)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .onAppear {
            // Convert to USD for display
            if negotiation.listing.currency != "USD" {
                ExchangeRatesAPI.shared.convertAmount(negotiation.listing.amount, from: negotiation.listing.currency, to: "USD") { _, _ in
                    // Trigger view update
                }
            }
        }
    }
    
    private func calculateUSDValue(amount: Double, currency: String) -> Double? {
        if currency == "USD" {
            return amount
        }
        let amountString = String(amount)
        let result = ExchangeRatesAPI.shared.calculateReceiveAmount(from: currency, to: "USD", amount: amountString)
        return Double(result)
    }
    
    private func otherUserInfo(_ negotiation: NegotiationDetail) -> some View {
        let otherUser = negotiation.userRole == "buyer" ? negotiation.seller : negotiation.buyer
        
        return Button(action: {
            if negotiation.userRole == "seller" {
                showBuyerInfo = true
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(negotiation.userRole == "buyer" ? localizationManager.localize("SELLER") : localizationManager.localize("BUYER"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(otherUser.firstName) \(otherUser.lastName)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", otherUser.rating))
                                .font(.caption)
                        }
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("\(otherUser.totalExchanges) \(localizationManager.localize("EXCHANGES"))")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if negotiation.userRole == "seller" {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func proposedTimeCard(_ negotiation: NegotiationDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localize("PROPOSED_MEETING_TIME"))
                .font(.headline)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(NegotiationService.formatDate(negotiation.negotiation.currentProposedTime))
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            let proposer = negotiation.negotiation.proposedBy == negotiation.buyer.userId ? negotiation.buyer : negotiation.seller
            Text("\(localizationManager.localize("PROPOSED_BY")) \(proposer.firstName)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func paymentStatusCard(_ negotiation: NegotiationDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localize("PAYMENT_STATUS"))
                .font(.headline)
            
            HStack(spacing: 20) {
                PaymentStatusIndicator(
                    paid: negotiation.negotiation.buyerPaid,
                    label: negotiation.buyer.firstName
                )
                
                PaymentStatusIndicator(
                    paid: negotiation.negotiation.sellerPaid,
                    label: negotiation.seller.firstName
                )
            }
            
            if let deadline = negotiation.negotiation.paymentDeadline,
               let remaining = NegotiationService.getRemainingTime(deadline: deadline) {
                Divider()
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text(remaining)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func actionButtons(_ negotiation: NegotiationDetail) -> some View {
        let isMyTurn = negotiation.negotiation.proposedBy != (negotiation.userRole == "buyer" ? negotiation.buyer.userId : negotiation.seller.userId)
        let isPaid = negotiation.userRole == "buyer" ? negotiation.negotiation.buyerPaid : negotiation.negotiation.sellerPaid
        
        VStack(spacing: 12) {
            // Accept/Reject/Counter (when it's user's turn and status is proposed/countered)
            if (negotiation.negotiation.status == .proposed || negotiation.negotiation.status == .countered) && isMyTurn {
                Button(action: { acceptProposal() }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(localizationManager.localize("ACCEPT_PROPOSAL"))
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isProcessing)
                
                Button(action: { showCounterProposal = true }) {
                    Text(localizationManager.localize("COUNTER_PROPOSE"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: { rejectNegotiation() }) {
                    Text(localizationManager.localize("REJECT"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
            }
            
            // Pay button (when agreed and user hasn't paid)
            if negotiation.negotiation.status == .agreed || negotiation.negotiation.status == .paidPartial {
                if !isPaid {
                    Button(action: { showPayment = true }) {
                        Text(localizationManager.localize("PAY_NOW"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func historySection(_ negotiation: NegotiationDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localize("NEGOTIATION_HISTORY"))
                .font(.headline)
            
            ForEach(negotiation.history) { entry in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: iconForAction(entry.action))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.userName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(labelForAction(entry.action))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let time = entry.proposedTime {
                            Text(NegotiationService.formatDate(time))
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        Text(NegotiationService.formatDate(entry.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func loadNegotiation() {
        isLoading = true
        errorMessage = nil
        
        NegotiationService.shared.getNegotiation(negotiationId: negotiationId) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success, let neg = response.toNegotiationDetail() {
                        negotiation = neg
                    } else {
                        errorMessage = response.error ?? localizationManager.localize("UNKNOWN_ERROR")
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func acceptProposal() {
        isProcessing = true
        
        NegotiationService.shared.acceptProposal(negotiationId: negotiationId) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        actionMessage = response.message
                        loadNegotiation()
                    } else {
                        errorMessage = response.error
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func rejectNegotiation() {
        isProcessing = true
        
        NegotiationService.shared.rejectNegotiation(negotiationId: negotiationId) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        actionMessage = response.message
                        loadNegotiation()
                    } else {
                        errorMessage = response.error
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func iconForAction(_ action: String) -> String {
        switch action {
        case "initial_proposal": return "calendar.badge.plus"
        case "counter_proposal": return "arrow.2.squarepath"
        case "accepted": return "checkmark.circle"
        case "rejected": return "xmark.circle"
        case "buyer_paid", "seller_paid": return "dollarsign.circle"
        default: return "circle"
        }
    }
    
    private func labelForAction(_ action: String) -> String {
        switch action {
        case "initial_proposal": return localizationManager.localize("ACTION_INITIAL_PROPOSAL")
        case "counter_proposal": return localizationManager.localize("ACTION_COUNTER_PROPOSAL")
        case "accepted": return localizationManager.localize("ACTION_ACCEPTED")
        case "rejected": return localizationManager.localize("ACTION_REJECTED")
        case "buyer_paid": return localizationManager.localize("ACTION_BUYER_PAID")
        case "seller_paid": return localizationManager.localize("ACTION_SELLER_PAID")
        default: return action
        }
    }
}

// MARK: - Counter Proposal Sheet

struct CounterProposalSheet: View {
    let negotiationId: String
    let currentTime: String
    let onComplete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var proposedDate = Date().addingTimeInterval(86400)
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(localizationManager.localize("COUNTER_PROPOSAL_SUBTITLE"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top)
                
                DatePicker(
                    localizationManager.localize("SELECT_DATE_TIME"),
                    selection: $proposedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .onTapGesture { }
                .simultaneousGesture(TapGesture().onEnded { })
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button(action: submitCounter) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(localizationManager.localize("SEND_COUNTER_PROPOSAL"))
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
                
                Spacer()
            }
            .padding()
            .navigationTitle(localizationManager.localize("COUNTER_PROPOSE"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localize("CANCEL")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitCounter() {
        isLoading = true
        errorMessage = nil
        
        NegotiationService.shared.counterProposal(negotiationId: negotiationId, proposedTime: proposedDate) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        dismiss()
                        onComplete()
                    } else {
                        errorMessage = response.error
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        NegotiationDetailView(negotiationId: "NEG-123")
    }
}
