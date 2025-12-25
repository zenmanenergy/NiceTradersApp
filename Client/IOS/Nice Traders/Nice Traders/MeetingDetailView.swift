//
//  MeetingDetailView.swift
//  Nice Traders
//
//  Contact detail page with messaging and meeting coordination
//  Refactored to use separate extensions for models, sections, and API methods
//

import SwiftUI

struct MeetingDetailView: View {
    let contactData: ContactData
    let initialDisplayStatus: String?
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var navigateToContact: Bool
    
    @State var activeTab: ContactTab = .details
    @State var showRatingView: Bool = false
    @State var hasSubmittedRating: Bool = false
    @State var contactTabForNavigation: ContactTabType? = nil
    
    // Rating state
    @State var userRating: Int = 0
    @State var ratingMessage: String = ""
    @State var partnerId: String? = nil
    
    // Meeting state - shared with child views
    @State var currentMeeting: CurrentMeeting?
    @State var meetingProposals: [MeetingProposal] = []
    @State var displayStatus: String?
    @State var timeAcceptedAt: String? = nil
    @State var locationAcceptedAt: String? = nil
    
    // Payment state
    @State var userPaidAt: String? = nil
    @State var otherUserPaidAt: String? = nil
    
    // User rating and trades state
    @State var otherUserRating: Double? = nil
    @State var otherUserTotalTrades: Int? = nil
    
    // Countdown timer
    @State var countdownText: String = ""
    @State var countdownTimer: Timer? = nil
    
    @State var isLoading: Bool = false
    @State var errorMessage: String?
    
    // PayPal payment state
    @State var showPaymentConfirmation: Bool = false
    @State var isCapturingPayment: Bool = false
    @State var showPayPalPayment: Bool = false
    @State var currentUserName: String = ""
    
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
                                    initialDisplayStatus: displayStatus,
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
                    // Check payment status
                    let userHasPaid = userPaidAt != nil && !(userPaidAt?.isEmpty ?? true)
                    let otherUserHasPaid = otherUserPaidAt != nil && !(otherUserPaidAt?.isEmpty ?? true)
                    let bothPaid = userHasPaid && otherUserHasPaid
                    
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
                    
                    Button(action: { if bothPaid { activeTab = .location } }) {
                        VStack(spacing: 4) {
                            Text("📍")
                                .font(.system(size: 20))
                            Text("Location")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(activeTab == .location ? Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.15) : Color.clear)
                        .foregroundColor(activeTab == .location && bothPaid ? Color(red: 0.4, green: 0.49, blue: 0.92) : (bothPaid ? Color.gray : Color.gray.opacity(0.5)))
                        .cornerRadius(8)
                        .opacity(bothPaid ? 1.0 : 0.6)
                    }
                    .disabled(!bothPaid)
                    
                    Button(action: { if bothPaid { activeTab = .messages } }) {
                        VStack(spacing: 4) {
                            Text("💬")
                                .font(.system(size: 20))
                            Text("Chat")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(activeTab == .messages ? Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.15) : Color.clear)
                        .foregroundColor(activeTab == .messages && bothPaid ? Color(red: 0.4, green: 0.49, blue: 0.92) : (bothPaid ? Color.gray : Color.gray.opacity(0.5)))
                        .cornerRadius(8)
                        .opacity(bothPaid ? 1.0 : 0.6)
                    }
                    .disabled(!bothPaid)
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
            // Initialize displayStatus with initial value
            if displayStatus == nil {
                displayStatus = initialDisplayStatus
            }
            loadMeetingProposals()
        }
        .onChange(of: activeTab) { newTab in
            // Reload proposals when switching to Details tab
            if newTab == .details {
                print("🔄 [MDV] Switching to Details tab - reloading proposals")
                loadMeetingProposals()
            }
        }
        .sheet(isPresented: $showRatingView) {
            RatingModalView(
                isPresented: $showRatingView,
                partnerName: contactData.otherUser.firstName,
                onSubmitRating: { rating, message in
                    userRating = rating
                    ratingMessage = message
                    submitRating()
                }
            )
        }
        .sheet(isPresented: $showPayPalPayment) {
            PayPalCheckoutView(
                negotiationId: contactData.listing.listingId,
                onSuccess: {
                    self.loadMeetingProposals()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showPayPalPayment = false
                    }
                }, onCancel: {
                    self.showPayPalPayment = false
            }, onError: { error in
                self.errorMessage = "Payment error: \(error)"
                self.showPayPalPayment = false
            }
        )
        }
    }
    
    // MARK: - Details View
    
    private var detailsView: some View {
        VStack(spacing: 16) {
            // Action buttons at the top
            actionButtonsSection
            
            // Check acceptance status
            let timeExplicitlyAccepted = timeAcceptedAt != nil && !(timeAcceptedAt?.isEmpty ?? true)
            let locationProposals = meetingProposals.filter { !$0.proposedLocation.isEmpty }
            let locationAccepted = locationProposals.contains { $0.status == "accepted" }
            
            // Show time proposal at top if not accepted
            if !timeExplicitlyAccepted {
                timeProposalSection
            }
            
            // Show location proposal at top if not accepted
            if !locationAccepted {
                locationProposalSection
            }
            
            // Payment tracking
            paymentTrackingSection
            
            // If location is accepted, show it
            if locationAccepted {
                locationProposalSection
            }
            
            // If time is accepted (and location isn't), show it
            if timeExplicitlyAccepted && !locationAccepted {
                acceptedTimeSection
            }
            
            exchangeDetailsSection
            
            traderInformationSection
            ratingSection
            
            // Cancel buttons at the bottom
            cancelButtonsSection
        }
    }
}
