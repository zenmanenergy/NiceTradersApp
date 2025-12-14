//
//  MeetingDetailView.swift
//  Nice Traders
//
//  Contact detail page with messaging and meeting coordination
//  (Refactored to use separate ContactChatView and MeetingLocationView)
//

import SwiftUI

struct MeetingDetailView: View {
    let contactData: ContactData
    let displayStatus: String?
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var navigateToContact: Bool
    
    @State private var activeTab: ContactTab = .details
    @State private var showRatingView: Bool = false
    @State private var hasSubmittedRating: Bool = false
    @State private var contactTabForNavigation: ContactTabType? = nil
    
    // Rating state
    @State private var userRating: Int = 0
    @State private var ratingMessage: String = ""
    @State private var partnerId: String? = nil
    
    // Meeting state - shared with child views
    @State private var currentMeeting: CurrentMeeting?
    @State private var meetingProposals: [MeetingProposal] = []
    @State private var timeAcceptedAt: String? = nil
    @State private var locationAcceptedAt: String? = nil
    
    // Payment state
    @State private var userPaidAt: String? = nil
    @State private var otherUserPaidAt: String? = nil
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    enum ContactTab: String, CaseIterable {
        case details = "Details"
        case location = "Location"
        case messages = "Chat"
        
        var icon: String {
            switch self {
                case .details: return "📋"
                case .location: return "📍"
                case .messages: return "💬"
            }
        }
    }
    
    var body: some View {
        return ZStack {
            VStack(spacing: 0) {
                if activeTab == .messages {
                    // Chat tab - use the dedicated ContactChatView
                    ContactChatView(contactData: contactData, onBackTapped: {
                        activeTab = .details
                    })
                    .padding(.bottom, 80)
                } else {
                    // Other tabs - full layout with header and navigation
                    VStack(spacing: 0) {
                        // Header - Match Dashboard Height
                        HStack(spacing: 12) {
                            // Back button - conditional based on active tab
                            if activeTab == .location {
                                Button(action: {
                                    activeTab = .details
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            } else {
                                Button(action: {
                                    navigateToContact = false
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                            
                            let convertedAmount = ExchangeRatesAPI.shared.convertAmountSync(contactData.listing.amount, from: contactData.listing.currency, to: contactData.listing.acceptCurrency ?? "") ?? contactData.listing.amount
                            let formattedConverted = ExchangeRatesAPI.shared.formatAmount(convertedAmount, shouldRound: contactData.listing.willRoundToNearestDollar ?? false)
                            let formattedOriginal = ExchangeRatesAPI.shared.formatAmount(contactData.listing.amount, shouldRound: contactData.listing.willRoundToNearestDollar ?? false)
                            
                            Text("$\(formattedOriginal) \(contactData.listing.currency) → \(formattedConverted) \(contactData.listing.acceptCurrency ?? "")")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: "FFD700"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                        // Content based on active tab
                        ScrollView {
                            switch activeTab {
                            case .details:
                                detailsView
                            case .location:
                                MeetingLocationView(
                                    contactData: contactData,
                                    displayStatus: displayStatus,
                                    currentMeeting: $currentMeeting,
                                    meetingProposals: $meetingProposals,
                                    onBackTapped: {
                                        activeTab = .details
                                    }
                                )
                            case .messages:
                                EmptyView()
                            }
                        }
                        
                        Spacer(minLength: 80)
                    }
                }
            }
            
            // Bottom Navigation - show contact tabs with home button
            VStack {
                Spacer()
                HStack {
                    Button(action: { navigateToContact = false }) {
                        VStack(spacing: 4) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 20))
                            Text("HOME")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color.gray)
                    }
                    
                    Button(action: { activeTab = .details }) {
                        VStack(spacing: 4) {
                            Text("📋")
                                .font(.system(size: 20))
                            Text("Details")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(activeTab == .details ? Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.15) : Color.clear)
                        .foregroundColor(activeTab == .details ? Color(red: 0.4, green: 0.49, blue: 0.92) : Color.gray)
                        .cornerRadius(8)
                    }
                    
                    Button(action: { activeTab = .location }) {
                        VStack(spacing: 4) {
                            Text("📍")
                                .font(.system(size: 20))
                            Text("Location")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(activeTab == .location ? Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.15) : Color.clear)
                        .foregroundColor(activeTab == .location ? Color(red: 0.4, green: 0.49, blue: 0.92) : Color.gray)
                        .cornerRadius(8)
                    }
                    
                    Button(action: { activeTab = .messages }) {
                        VStack(spacing: 4) {
                            Text("💬")
                                .font(.system(size: 20))
                            Text("Chat")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(activeTab == .messages ? Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.15) : Color.clear)
                        .foregroundColor(activeTab == .messages ? Color(red: 0.4, green: 0.49, blue: 0.92) : Color.gray)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .fill(Color(red: 0.89, green: 0.91, blue: 0.94))
                        .frame(height: 1),
                    alignment: .top
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("VIEW: MeetingDetailView")
            loadMeetingProposals()
        }
    }
    
    // MARK: - Details View
    
    private var detailsView: some View {
        VStack(spacing: 16) {
            exchangeDetailsSection
            traderInformationSection
            timeProposalSection
            paymentTrackingSection
            locationProposalSection
            ratingSection
        }
    }
    
    @ViewBuilder
    private var exchangeDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localize("EXCHANGE_DETAILS"))
                .font(.headline)
                .foregroundColor(Color(hex: "2d3748"))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You bring:")
                            .font(.caption)
                            .foregroundColor(Color(hex: "718096"))
                        Text("$\(formatExchangeAmount(contactData.listing.amount, shouldRound: contactData.listing.willRoundToNearestDollar ?? false)) \(contactData.listing.currency)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2d3748"))
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundColor(Color(hex: "667eea"))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("They bring:")
                            .font(.caption)
                            .foregroundColor(Color(hex: "718096"))
                        Text("\(formatConvertedAmount()) \(contactData.listing.acceptCurrency ?? "")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2d3748"))
                    }
                }
                .padding()
                .background(Color(hex: "f7fafc"))
                .cornerRadius(8)
            }
            
            detailRow(label: "Meeting Preference:", value: contactData.listing.meetingPreference ?? "Not specified")
            
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localize("GENERAL_AREA"))
                    .font(.caption)
                    .foregroundColor(Color(hex: "718096"))
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color(hex: "667eea"))
                    Text(contactData.listing.location)
                        .foregroundColor(Color(hex: "2d3748"))
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var traderInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localize("TRADER_INFORMATION"))
                .font(.headline)
                .foregroundColor(Color(hex: "2d3748"))
            
            Text(contactData.otherUser.firstName + " " + contactData.otherUser.lastName)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "2d3748"))
            
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Image(systemName: index < Int(contactData.otherUser.rating ?? 0) ? "star.fill" : "star")
                        .foregroundColor(index < Int(contactData.otherUser.rating ?? 0) ? Color(hex: "fbbf24") : Color(hex: "e2e8f0"))
                }
                Text("(\(contactData.otherUser.totalTrades ?? 0) trades)")
                    .font(.caption)
                    .foregroundColor(Color(hex: "718096"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var timeProposalSection: some View {
        let pendingTimeProposal = meetingProposals.first(where: { 
            !$0.proposedTime.isEmpty && $0.status == "pending"
        })
        
        // Check if both users have paid (time is implicitly accepted when in payment/location phase)
        let userHasPaid = !(userPaidAt?.isEmpty ?? true)
        let otherUserHasPaid = !(otherUserPaidAt?.isEmpty ?? true)
        let bothUsersPaid = userHasPaid && otherUserHasPaid
        
        if (timeAcceptedAt == nil || timeAcceptedAt?.isEmpty ?? true) && !bothUsersPaid {
            // Time not accepted yet AND we haven't moved to payment phase - show proposal/response buttons
            if let pendingTime = pendingTimeProposal, pendingTime.isFromMe {
                // I proposed the time - show waiting/cancel message
                VStack(alignment: .center, spacing: 12) {
                    Text("⏳ Waiting for Acceptance")
                        .font(.headline)
                        .foregroundColor(Color(hex: "f59e0b"))
                    
                    Text("You proposed a meeting time. Waiting for the other trader to accept or counter.")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    if let meeting = currentMeeting {
                        VStack(alignment: .leading, spacing: 8) {
                            detailRow(label: "TIME:", value: formatDateTime(meeting.time))
                        }
                        .padding(12)
                        .background(Color(hex: "fffbeb"))
                        .cornerRadius(8)
                    }
                    
                    Button(action: { rejectExchange() }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Cancel Proposal")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color(hex: "ef4444"))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(hex: "fef3c7"))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else if pendingTimeProposal != nil && !bothUsersPaid {
                // They proposed the time AND we haven't moved to payment phase - show accept/counter/reject buttons
                VStack(alignment: .center, spacing: 12) {
                    Text("Accept this exchange?")
                        .font(.headline)
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    HStack(spacing: 12) {
                        Button(action: { acceptExchange() }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                Text("Accept")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color(hex: "38a169"))
                            .cornerRadius(8)
                        }
                        
                        Button(action: { counterExchange() }) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 14))
                                Text("Counter")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color(hex: "f59e0b"))
                            .cornerRadius(8)
                        }
                    }
                    
                    Button(action: { rejectExchange() }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Reject")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color(hex: "ef4444"))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var locationProposalSection: some View {
        // Show location proposal UI if:
        // 1. Time is explicitly accepted, OR
        // 2. Both users have paid (implicit time acceptance)
        let timeExplicitlyAccepted = timeAcceptedAt != nil && !(timeAcceptedAt?.isEmpty ?? true)
        let userHasPaid = userPaidAt != nil && !userPaidAt!.isEmpty
        let otherUserHasPaid = otherUserPaidAt != nil && !otherUserPaidAt!.isEmpty
        let bothUsersPaid = userHasPaid && otherUserHasPaid
        let shouldShowLocationSection = timeExplicitlyAccepted || bothUsersPaid
        
        if shouldShowLocationSection {
            let pendingLocationProposal = meetingProposals.first(where: { 
                !$0.proposedLocation.isEmpty && $0.status == "pending"
            })
            let acceptedLocationProposal = meetingProposals.first(where: { 
                !$0.proposedLocation.isEmpty && $0.status == "accepted"
            })
            
            if let acceptedLoc = acceptedLocationProposal {
                // Location has been accepted - show confirmation
                VStack(alignment: .center, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "38a169"))
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location Confirmed!")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "38a169"))
                            
                            Text(acceptedLoc.proposedLocation)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "2d3748"))
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(hex: "ecfdf5"))
                    .cornerRadius(8)
                    
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(Color(hex: "667eea"))
                        Text("Ready to Meet")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "667eea"))
                        Spacer()
                    }
                    .padding()
                    .background(Color(hex: "f0f4ff"))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else if let pendingLoc = pendingLocationProposal {
                VStack(alignment: .center, spacing: 12) {
                    if pendingLoc.isFromMe {
                        Text("⏳ Waiting for Location Approval")
                            .font(.headline)
                            .foregroundColor(Color(hex: "f59e0b"))
                        
                        Text("You proposed a meeting location. Waiting for the other trader to accept or counter.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "4a5568"))
                        
                        HStack(spacing: 12) {
                            Button(action: { /* View details */ }) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 14))
                                    Text("View Details")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color(hex: "667eea"))
                                .cornerRadius(8)
                            }
                            
                            Button(action: { counterLocationProposal(proposalId: pendingLoc.proposalId) }) {
                                HStack {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 14))
                                    Text("Counter")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color(hex: "f59e0b"))
                                .cornerRadius(8)
                            }
                        }
                    } else {
                        Text("Accept location?")
                            .font(.headline)
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        HStack(spacing: 12) {
                            Button(action: { acceptLocationProposal(proposalId: pendingLoc.proposalId) }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Accept")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color(hex: "38a169"))
                                .cornerRadius(8)
                            }
                            
                            Button(action: { counterLocationProposal(proposalId: pendingLoc.proposalId) }) {
                                HStack {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 14))
                                    Text("Counter")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color(hex: "f59e0b"))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                // No pending or accepted location proposal - show button to propose one
                VStack(alignment: .center, spacing: 12) {
                    Text("Ready to propose a meeting location?")
                        .font(.headline)
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Button(action: { proposeLocation() }) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 14))
                            Text("Propose Location")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color(hex: "667eea"))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    @ViewBuilder
    private var paymentTrackingSection: some View {
        // Show payment section if time is accepted but location is not yet accepted AND both haven't paid yet
        if timeAcceptedAt != nil && !(timeAcceptedAt?.isEmpty ?? true) {
            // Check if both users have paid
            let userHasPaid = userPaidAt != nil && !(userPaidAt?.isEmpty ?? true)
            let otherUserHasPaid = otherUserPaidAt != nil && !(otherUserPaidAt?.isEmpty ?? true)
            let bothPaid = userHasPaid && otherUserHasPaid
            
            if !bothPaid && (locationAcceptedAt == nil || locationAcceptedAt?.isEmpty ?? true) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Required")
                        .font(.headline)
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Text("Both users need to pay $2.00 before proceeding to location negotiation.")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Your Payment:")
                                .font(.caption)
                                .foregroundColor(Color(hex: "718096"))
                            Spacer()
                            Text(userHasPaid ? "✅ Paid" : "⏳ Pending")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(userHasPaid ? Color(hex: "38a169") : Color(hex: "f59e0b"))
                        }
                        .padding(12)
                        .background(Color(hex: "f7fafc"))
                        .cornerRadius(8)
                        
                        HStack {
                            Text("Other User's Payment:")
                                .font(.caption)
                                .foregroundColor(Color(hex: "718096"))
                            Spacer()
                            Text(otherUserHasPaid ? "✅ Paid" : "⏳ Pending")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(otherUserHasPaid ? Color(hex: "38a169") : Color(hex: "f59e0b"))
                        }
                        .padding(12)
                        .background(Color(hex: "f7fafc"))
                        .cornerRadius(8)
                    }
                    
                    if !userHasPaid {
                        Button(action: { processPayment() }) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 14))
                                Text("Confirm Payment ($2.00)")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color(hex: "667eea"))
                            .cornerRadius(8)
                        }
                    } else if !otherUserHasPaid {
                        HStack {
                            Image(systemName: "hourglass.end")
                                .foregroundColor(Color(hex: "f59e0b"))
                            Text("Awaiting other user's payment...")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "f59e0b"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "fffbeb"))
                        .cornerRadius(8)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "38a169"))
                            Text("Both payments complete!")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "38a169"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "ecfdf5"))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    @ViewBuilder
    private var ratingSection: some View {
        EmptyView()
    }
    

    
    // MARK: - Helper Functions
    
    private func detailRow(label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color(hex: "718096"))
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(Color(hex: "2d3748"))
        }
    }
    
    private func formatDateTime(_ dateString: String) -> String {
        return DateFormatters.formatCompact(dateString)
    }
    
    // MARK: - Complete Exchange
    
    private func completeExchange() {
        print("[MeetingDetailView] completeExchange: Button tapped, showing confirmation alert")
        let alert = UIAlertController(
            title: localizationManager.localize("CONFIRM_EXCHANGE_COMPLETE"),
            message: localizationManager.localize("EXCHANGE_COMPLETE_MESSAGE"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("[MeetingDetailView] completeExchange: User cancelled")
        })
        alert.addAction(UIAlertAction(title: "Complete", style: .default) { _ in
            print("[MeetingDetailView] completeExchange: User confirmed, calling submitCompleteExchange")
            self.submitCompleteExchange()
        })
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            print("[MeetingDetailView] completeExchange: Failed to get root view controller")
            return
        }
        
        rootVC.present(alert, animated: true)
    }
    
    private func submitCompleteExchange() {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[MeetingDetailView] submitCompleteExchange: No session ID")
            return
        }
        
        let baseURL = Settings.shared.baseURL
        let listingId = contactData.listing.listingId
        let urlString = "\(baseURL)/Negotiations/CompleteExchange?SessionId=\(sessionId)&ListingId=\(listingId)"
        print("[MeetingDetailView] submitCompleteExchange: URL = \(urlString)")
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            print("[MeetingDetailView] submitCompleteExchange: Invalid URL \(urlString)")
            return
        }
        
        isLoading = true
        print("[MeetingDetailView] submitCompleteExchange: Making request to \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            print("[MeetingDetailView] submitCompleteExchange: Response received")
            print("[MeetingDetailView] submitCompleteExchange: Error: \(error?.localizedDescription ?? "none")")
            
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown")"
                    self.isLoading = false
                    print("[MeetingDetailView] submitCompleteExchange: Network error: \(error?.localizedDescription ?? "Unknown")")
                }
                return
            }
            
            print("[MeetingDetailView] submitCompleteExchange: Received data, parsing JSON")
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("[MeetingDetailView] submitCompleteExchange: JSON = \(json)")
                if let success = json["success"] as? Bool, success {
                    print("[MeetingDetailView] submitCompleteExchange: Success! exchange_id = \(json["exchange_id"] ?? "none")")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        // Capture partner_id for rating
                        if let partnerIdStr = json["partner_id"] as? String {
                            self.partnerId = partnerIdStr
                            print("[MeetingDetailView] submitCompleteExchange: Set partnerId = \(partnerIdStr)")
                        }
                        self.showRatingView = true
                        print("[MeetingDetailView] submitCompleteExchange: Showing rating view")
                    }
                } else {
                    let errorMsg = json["error"] as? String ?? "Failed to complete exchange"
                    print("[MeetingDetailView] submitCompleteExchange: Failed - \(errorMsg)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = errorMsg
                    }
                }
            } else {
                print("[MeetingDetailView] submitCompleteExchange: Failed to parse JSON")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to complete exchange"
                }
            }
        }.resume()
    }
    
    // MARK: - Rating
    
    private func submitRating() {
        guard userRating > 0 else {
            errorMessage = "Please select a rating"
            return
        }
        
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            return
        }
        
        guard let partnerIdToRate = partnerId else {
            errorMessage = "Partner ID not found"
            return
        }
        
        isLoading = true
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Ratings/SubmitRating")!
        components.queryItems = [
            URLQueryItem(name: "SessionId", value: sessionId),
            URLQueryItem(name: "user_id", value: partnerIdToRate),
            URLQueryItem(name: "Rating", value: String(userRating)),
            URLQueryItem(name: "Review", value: ratingMessage)
        ]
        
        guard let url = components.url else {
            errorMessage = "Invalid URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                guard let data = data, error == nil else {
                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown")"
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    self.hasSubmittedRating = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.dismiss()
                    }
                } else {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.errorMessage = json["error"] as? String ?? "Failed to submit rating"
                    } else {
                        self.errorMessage = "Failed to submit rating"
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Meeting Coordination
    
    private func loadMeetingProposals() {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("🔴 [MDV-LOAD] ERROR: No session ID available")
            return
        }
        
        print("🟠 [MDV-LOAD] ===== START LOAD PROPOSALS =====")
        print("🟠 [MDV-LOAD] Listing ID: \(contactData.listing.listingId)")
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Meeting/GetMeetingProposals")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing.listingId))
        ]
        
        guard let url = components.url else {
            print("🔴 [MDV-LOAD] ERROR: Failed to construct URL")
            return
        }
        
        print("🟠 [MDV-LOAD] Fetching from: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("🟠 [MDV-LOAD] Response received from server")
                
                guard let data = data, error == nil else {
                    print("🔴 [MDV-LOAD] ERROR: Network error - \(error?.localizedDescription ?? "unknown")")
                    return
                }
                
                let responseStr = String(data: data, encoding: .utf8) ?? "no data"
                print("🟠 [MDV-LOAD] Raw response: \(responseStr.prefix(500))...")
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    print("✅ [MDV-LOAD] Response successful")
                    
                    // Parse proposals
                    if let proposalsData = json["proposals"] as? [[String: Any]] {
                        print("🟠 [MDV-LOAD] Found \(proposalsData.count) proposals")
                        
                        self.meetingProposals = proposalsData.compactMap { dict in
                            guard let proposalId = dict["proposal_id"] as? String,
                                  let status = dict["status"] as? String else {
                                print("🔴 [MDV-LOAD] Skipping proposal - missing required fields")
                                return nil
                            }
                            
                            let proposedLocation = dict["proposed_location"] as? String ?? ""
                            let proposedTime = dict["proposed_time"] as? String ?? ""
                            let isFromMe = dict["is_from_me"] as? Bool ?? false
                            // Try new format first (proposed_by_name), fallback to old format (proposer.first_name)
                            let firstName = dict["proposed_by_name"] as? String ?? (dict["proposer"] as? [String: Any])?["first_name"] as? String ?? "Unknown"
                            
                            print("🟠 [MDV-LOAD] Parsed proposal: id=\(proposalId), status=\(status), location=\(proposedLocation), time=\(proposedTime), fromMe=\(isFromMe), proposer=\(firstName)")
                            
                            return MeetingProposal(
                                proposalId: proposalId,
                                proposedLocation: proposedLocation,
                                proposedTime: proposedTime,
                                message: dict["message"] as? String,
                                status: status,
                                isFromMe: isFromMe,
                                proposer: ProposerInfo(firstName: firstName),
                                latitude: dict["latitude"] as? Double,
                                longitude: dict["longitude"] as? Double
                            )
                        }
                        
                        print("✅ [MDV-LOAD] Successfully parsed \(self.meetingProposals.count) proposals")
                        for (i, prop) in self.meetingProposals.enumerated() {
                            print("  [\(i)] \(prop.proposalId) - \(prop.status) - \(prop.proposedLocation)")
                        }
                    } else {
                        print("🟠 [MDV-LOAD] No proposals array in response")
                        self.meetingProposals = []
                    }
                    
                    // Parse current meeting
                    if let meetingData = json["current_meeting"] as? [String: Any] {
                        print("🟠 [MDV-LOAD] Parsing current_meeting...")
                        if let time = meetingData["time"] as? String {
                            // Handle location - if it's nil or null, set to nil
                            let location: String? = meetingData["location"] as? String
                            let latitude: Double? = meetingData["latitude"] as? Double
                            let longitude: Double? = meetingData["longitude"] as? Double
                            let agreedAt = (meetingData["agreed_at"] as? String) ?? ""
                            let timeAcceptedAt: String? = meetingData["timeAcceptedAt"] as? String
                            let locationAcceptedAt: String? = meetingData["locationAcceptedAt"] as? String
                            let userPaidAt: String? = meetingData["userPaidAt"] as? String
                            let otherUserPaidAt: String? = meetingData["otherUserPaidAt"] as? String
                            
                            print("🟠 [MDV-LOAD] Current meeting - time=\(time), location=\(location ?? "nil"), timeAcceptedAt=\(timeAcceptedAt ?? "nil"), locationAcceptedAt=\(locationAcceptedAt ?? "nil"), userPaid=\(userPaidAt ?? "nil"), otherUserPaid=\(otherUserPaidAt ?? "nil")")
                            
                            self.currentMeeting = CurrentMeeting(
                                location: location,
                                latitude: latitude,
                                longitude: longitude,
                                time: time,
                                message: meetingData["message"] as? String,
                                agreedAt: agreedAt,
                                acceptedAt: timeAcceptedAt,
                                locationAcceptedAt: locationAcceptedAt
                            )
                            self.timeAcceptedAt = timeAcceptedAt
                            self.locationAcceptedAt = locationAcceptedAt
                            self.userPaidAt = userPaidAt
                            self.otherUserPaidAt = otherUserPaidAt
                            print("✅ [MDV-LOAD] Set self.timeAcceptedAt to: \(self.timeAcceptedAt ?? "nil")")
                            print("✅ [MDV-LOAD] Set self.locationAcceptedAt to: \(self.locationAcceptedAt ?? "nil")")
                            print("✅ [MDV-LOAD] Set self.userPaidAt to: \(self.userPaidAt ?? "nil")")
                            print("✅ [MDV-LOAD] Set self.otherUserPaidAt to: \(self.otherUserPaidAt ?? "nil")")
                        }
                    } else {
                        print("🟠 [MDV-LOAD] No current_meeting in response - checking for top-level payment info...")
                        // If current_meeting is null, try to get payment info from top level
                        let userPaidAt: String? = json["userPaidAt"] as? String
                        let otherUserPaidAt: String? = json["otherUserPaidAt"] as? String
                        print("🟠 [MDV-LOAD] Top-level userPaidAt: \(userPaidAt ?? "nil"), otherUserPaidAt: \(otherUserPaidAt ?? "nil")")
                        
                        self.userPaidAt = userPaidAt
                        self.otherUserPaidAt = otherUserPaidAt
                        print("✅ [MDV-LOAD] Set self.userPaidAt to: \(self.userPaidAt ?? "nil")")
                        print("✅ [MDV-LOAD] Set self.otherUserPaidAt to: \(self.otherUserPaidAt ?? "nil")")
                    }
                } else {
                    print("🔴 [MDV-LOAD] ERROR: Response indicates failure")
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("🔴 [MDV-LOAD] Error: \(json["error"] as? String ?? "unknown")")
                    }
                }
                
                print("🟠 [MDV-LOAD] ===== END LOAD PROPOSALS =====")
            }
        }.resume()
    }
    
    private func acceptExchange() {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[DEBUG] No session ID available")
            return
        }
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/MeetingTime/Accept")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId)
        ]
        
        guard let url = components.url else {
            print("[DEBUG] Failed to construct URL")
            return
        }
        
        print("[DEBUG] Accept button tapped - calling: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("[DEBUG] Accept response received")
                if let error = error {
                    print("[DEBUG] Accept error: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("[DEBUG] Accept HTTP status: \(httpResponse.statusCode)")
                }
                
                if let data = data {
                    print("[DEBUG] Accept response data: \(String(data: data, encoding: .utf8) ?? "no data")")
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("[DEBUG] Accept JSON parsed: \(json)")
                        if let success = json["success"] as? Bool, success {
                            print("[DEBUG ACCEPT] Accept successful")
                            // Get accepted_at from response - try both field names
                            if let timeAcceptedAtFromResponse = json["timeAcceptedAt"] as? String {
                                print("[DEBUG ACCEPT] Got timeAcceptedAt from response: \(timeAcceptedAtFromResponse)")
                                self.timeAcceptedAt = timeAcceptedAtFromResponse
                            } else if let agreementReachedAt = json["agreementReachedAt"] as? String {
                                print("[DEBUG ACCEPT] Got agreementReachedAt from response: \(agreementReachedAt)")
                                self.timeAcceptedAt = agreementReachedAt
                            } else {
                                print("[DEBUG ACCEPT] No timestamp in response, generating locally")
                                self.timeAcceptedAt = self.iso8601Now()
                            }
                            print("[DEBUG ACCEPT] Set self.timeAcceptedAt to: \(self.timeAcceptedAt ?? "nil")")
                            print("[DEBUG ACCEPT] Reloading meeting proposals...")
                            self.loadMeetingProposals()
                        } else {
                            self.errorMessage = json["error"] as? String ?? "Failed to accept exchange"
                            print("[DEBUG] Accept failed: \(self.errorMessage)")
                        }
                    } else {
                        print("[DEBUG] Failed to parse JSON")
                        self.errorMessage = "Invalid response format"
                    }
                } else {
                    print("[DEBUG] No data in response")
                    self.errorMessage = "No response data"
                }
            }
        }.resume()
    }
    
    private func counterExchange() {
        // Counter should propose a new meeting time
        // For now, show an alert that they need to propose a counter time
        print("[DEBUG] Counter tapped - user should propose a new meeting time")
        // TODO: Open ProposeTimeView or similar
        errorMessage = "Please propose a new meeting time"
    }
    
    private func processPayment() {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[MDV-PAY] No session ID available")
            return
        }
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Payments/ProcessPayment")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId)
        ]
        
        guard let url = components.url else {
            print("[MDV-PAY] Failed to construct payment URL")
            return
        }
        
        isLoading = true
        print("[MDV-PAY] Processing payment - calling: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                print("[MDV-PAY] Payment response received")
                
                if let error = error {
                    print("[MDV-PAY] Payment error: \(error.localizedDescription)")
                    self.errorMessage = "Payment failed: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("[MDV-PAY] Payment HTTP status: \(httpResponse.statusCode)")
                }
                
                if let data = data {
                    print("[MDV-PAY] Response data: \(String(data: data, encoding: .utf8) ?? "no data")")
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let success = json["success"] as? Bool, success {
                            print("[MDV-PAY] Payment successful")
                            // Reload proposals to get updated payment status from server
                            print("[MDV-PAY] Reloading proposals to get updated payment status...")
                            self.loadMeetingProposals()
                        } else {
                            let errorMsg = json["error"] as? String ?? "Payment processing failed"
                            self.errorMessage = errorMsg
                            print("[MDV-PAY] Payment failed: \(errorMsg)")
                        }
                    } else {
                        print("[MDV-PAY] Failed to parse response")
                        self.errorMessage = "Invalid response format"
                    }
                }
            }
        }.resume()
    }
    
    private func rejectExchange() {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[DEBUG] No session ID available for reject")
            return
        }
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/MeetingTime/Reject")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId)
        ]
        
        guard let url = components.url else {
            print("[DEBUG] Failed to construct reject URL")
            return
        }
        
        print("[DEBUG] Reject button tapped - calling: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("[DEBUG] Reject response received")
                if let httpResponse = response as? HTTPURLResponse {
                    print("[DEBUG] Reject HTTP status: \(httpResponse.statusCode)")
                }
                
                if let error = error {
                    print("[DEBUG] Reject error: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    print("[DEBUG] Reject successful")
                    self.dismiss()
                } else {
                    let errorMsg = (try? JSONSerialization.jsonObject(with: data ?? Data())) as? [String: Any]
                    self.errorMessage = errorMsg?["error"] as? String ?? "Failed to reject exchange"
                    print("[DEBUG] Reject failed: \(self.errorMessage)")
                }
            }
        }.resume()
    }
    
    private func proposeLocation() {
        print("[MDV-ACTION] Propose location action triggered")
        activeTab = .location
    }
    
    private func acceptLocationProposal(proposalId: String) {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[MDV-ACTION] ERROR: No session ID available")
            return
        }
        
        print("[MDV-ACTION] Accept location proposal: \(proposalId)")
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Meeting/RespondToMeeting")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "proposalId", value: proposalId),
            URLQueryItem(name: "response", value: "accepted")
        ]
        
        guard let url = components.url else {
            print("[MDV-ACTION] ERROR: Failed to construct URL")
            return
        }
        
        print("[MDV-ACTION] Calling: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("[MDV-ACTION] Response received")
                
                if let error = error {
                    print("[MDV-ACTION] ERROR: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("[MDV-ACTION] HTTP Status: \(httpResponse.statusCode)")
                }
                
                if let data = data {
                    let responseStr = String(data: data, encoding: .utf8) ?? "no data"
                    print("[MDV-ACTION] Response: \(responseStr)")
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let success = json["success"] as? Bool, success {
                            print("✅ [MDV-ACTION] Location accepted successfully!")
                            // Reload proposals to show updated state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.loadMeetingProposals()
                            }
                        } else {
                            let errorMsg = json["error"] as? String ?? "Unknown error"
                            print("[MDV-ACTION] ERROR: \(errorMsg)")
                            self.errorMessage = errorMsg
                        }
                    }
                }
            }
        }.resume()
    }
    
    private func counterLocationProposal(proposalId: String) {
        print("[MDV-ACTION] Counter location proposal: \(proposalId)")
        // TODO: Navigate to MeetingLocationView for counter proposal
    }
    
                    private func cancelLocationProposal(proposalId: String) {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[DEBUG] No session ID available for cancel location")
            return
        }
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Meeting/RespondToMeeting")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "proposalId", value: proposalId),
            URLQueryItem(name: "response", value: "rejected")
        ]
        
        guard let url = components.url else {
            print("[DEBUG] Failed to construct cancel location URL")
            return
        }
        
        print("[DEBUG] Cancel location button tapped - calling: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("[DEBUG] Cancel location response received")
                if let httpResponse = response as? HTTPURLResponse {
                    print("[DEBUG] Cancel location HTTP status: \(httpResponse.statusCode)")
                }
                
                if let error = error {
                    print("[DEBUG] Cancel location error: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    print("[DEBUG] Cancel location successful")
                    self.loadMeetingProposals()
                } else {
                    let errorMsg = (try? JSONSerialization.jsonObject(with: data ?? Data())) as? [String: Any]
                    self.errorMessage = errorMsg?["error"] as? String ?? "Failed to cancel proposal"
                    print("[DEBUG] Cancel location failed: \(self.errorMessage)")
                }
            }
        }.resume()
    }
    
    private func respondToLocationProposal(proposalId: String, response: String) {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[DEBUG] No session ID available for respond to location")
            return
        }
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Meeting/RespondToMeeting")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "proposalId", value: proposalId),
            URLQueryItem(name: "response", value: response)
        ]
        
        guard let url = components.url else {
            print("[DEBUG] Failed to construct respond to location URL")
            return
        }
        
        print("[DEBUG] Respond to location - calling: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("[DEBUG] Respond to location response received")
                if let httpResponse = response as? HTTPURLResponse {
                    print("[DEBUG] Respond to location HTTP status: \(httpResponse.statusCode)")
                }
                
                if let error = error {
                    print("[DEBUG] Respond to location error: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    print("[DEBUG] Respond to location successful")
                    self.loadMeetingProposals()
                } else {
                    let errorMsg = (try? JSONSerialization.jsonObject(with: data ?? Data())) as? [String: Any]
                    self.errorMessage = errorMsg?["error"] as? String ?? "Failed to respond to proposal"
                    print("[DEBUG] Respond to location failed: \(self.errorMessage)")
                }
            }
        }.resume()
    }
    
    private func iso8601Now() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
    
    private func formatExchangeAmount(_ amount: Double, shouldRound: Bool) -> String {
        return ExchangeRatesAPI.shared.formatAmount(amount, shouldRound: shouldRound)
    }
    
    private func formatConvertedAmount() -> String {
        let convertedAmount = ExchangeRatesAPI.shared.convertAmountSync(contactData.listing.amount, from: contactData.listing.currency, to: contactData.listing.acceptCurrency ?? "") ?? contactData.listing.amount
        return ExchangeRatesAPI.shared.formatAmount(convertedAmount, shouldRound: contactData.listing.willRoundToNearestDollar ?? false)
    }
}

// MARK: - Data Models

struct ContactData {
    let listing: ContactListing
    let otherUser: OtherUser
    let lockedAmount: Double?
    let exchangeRate: Double?
    let fromCurrency: String?
    let toCurrency: String?
    let purchasedAt: String?
}

struct ContactListing {
    let listingId: String
    let currency: String
    let amount: Double
    let acceptCurrency: String?
    let preferredCurrency: String?
    let meetingPreference: String?
    let location: String
    let latitude: Double
    let longitude: Double
    let radius: Int
    let willRoundToNearestDollar: Bool?
}

struct OtherUser {
    let firstName: String
    let lastName: String
    let rating: Double?
    let totalTrades: Int?
}

struct ContactMessage: Identifiable {
    let id: String
    let messageText: String
    let sentAt: String
    let isFromUser: Bool
}

struct MeetingProposal: Identifiable {
    let id = UUID()
    let proposalId: String
    let proposedLocation: String
    let proposedTime: String
    let message: String?
    let status: String
    let isFromMe: Bool
    let proposer: ProposerInfo
    let latitude: Double?
    let longitude: Double?
}

struct ProposerInfo {
    let firstName: String
}

struct CurrentMeeting {
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let time: String
    let message: String?
    let agreedAt: String
    let acceptedAt: String?
    let locationAcceptedAt: String?
}
