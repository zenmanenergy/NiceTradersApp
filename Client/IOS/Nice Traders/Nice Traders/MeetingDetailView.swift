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
    
    // Meeting state - shared with child views
    @State private var currentMeeting: CurrentMeeting?
    @State private var meetingProposals: [MeetingProposal] = []
    @State private var timeAcceptedAt: String? = nil
    @State private var locationAcceptedAt: String? = nil
    
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
            // Exchange Details
            VStack(alignment: .leading, spacing: 16) {
                Text(localizationManager.localize("EXCHANGE_DETAILS"))
                    .font(.headline)
                    .foregroundColor(Color(hex: "2d3748"))
                
                // Who is exchanging what
                VStack(alignment: .leading, spacing: 12) {
                    // You bringing...
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
                
                // General Area
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
            
            // Trader Information
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
            
            // Button Set 1: Accept/Reject/Counter - show when listing_meeting_time.accepted_at is null
            print("[BUTTON DEBUG] SET 1: timeAcceptedAt='\(timeAcceptedAt ?? "nil")', isEmpty=\(timeAcceptedAt?.isEmpty ?? true)")
            if timeAcceptedAt == nil || timeAcceptedAt?.isEmpty ?? true {
                VStack(alignment: .center, spacing: 12) {
                    Text("Accept this exchange?")
                        .font(.headline)
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            acceptExchange()
                        }) {
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
                        
                        Button(action: {
                            counterExchange()
                        }) {
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
                    
                    Button(action: {
                        rejectExchange()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Reject")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color(hex: "dc2626"))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(hex: "f0f9ff"))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            // Button Set 2: Propose Location - show when listing_meeting_time.accepted_at is NOT null AND listing_meeting_location.accepted_at IS null
            print("[BUTTON DEBUG] SET 2: timeAcceptedAt='\(timeAcceptedAt ?? "nil")', locAcceptedAt='\(locationAcceptedAt ?? "nil")'")
            if timeAcceptedAt != nil && !(timeAcceptedAt?.isEmpty ?? true) && (locationAcceptedAt == nil || locationAcceptedAt?.isEmpty ?? true) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("⚠️ " + localizationManager.localize("MEETING_LOCATION_REQUIRED"))
                            .font(.headline)
                            .foregroundColor(Color(hex: "dc2626"))
                        Spacer()
                    }
                    
                    Text("You need to agree on a meeting location and time before completing this exchange.")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    if let meeting = currentMeeting {
                        VStack(alignment: .leading, spacing: 8) {
                            detailRow(label: localizationManager.localize("TIME") + ":", value: formatDateTime(meeting.time))
                        }
                    }
                    
                    Button(action: {
                        activeTab = .location
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                            Text("PROPOSE MEETING LOCATION")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color(hex: "667eea"))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(hex: "fee2e2"))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            // Show meeting details when both time and location are accepted
            print("[BUTTON DEBUG] SET 3 DETAILS: timeAcceptedAt='\(timeAcceptedAt ?? "nil")', locAcceptedAt='\(locationAcceptedAt ?? "nil")'")
            if timeAcceptedAt != nil && !(timeAcceptedAt?.isEmpty ?? true) && locationAcceptedAt != nil && !(locationAcceptedAt?.isEmpty ?? true) {
                if let meeting = currentMeeting {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("✅ " + localizationManager.localize("MEETING_AGREED"))
                                .font(.headline)
                                .foregroundColor(Color(hex: "38a169"))
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            detailRow(label: localizationManager.localize("LOCATION") + ":", value: meeting.location ?? "Not set")
                            detailRow(label: localizationManager.localize("TIME") + ":", value: formatDateTime(meeting.time))
                            if let message = meeting.message, !message.isEmpty {
                                detailRow(label: localizationManager.localize("NOTE") + ":", value: message)
                            }
                        }
                    }
                    .padding()
                    .background(Color(hex: "f0fff4"))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
            
            // Button Set 3: Mark Exchange Complete - show when both accepted_at values are NOT null
            print("[BUTTON DEBUG] SET 3 BUTTON: timeAcceptedAt='\(timeAcceptedAt ?? "nil")', locAcceptedAt='\(locationAcceptedAt ?? "nil")'")
            if timeAcceptedAt != nil && !(timeAcceptedAt?.isEmpty ?? true) && locationAcceptedAt != nil && !(locationAcceptedAt?.isEmpty ?? true) {
                Button(action: completeExchange) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("MARK EXCHANGE COMPLETE")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "10b981"), Color(hex: "059669")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding()
            }
            
            // Rating Section
            if showRatingView && !hasSubmittedRating {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizationManager.localize("RATE_EXCHANGE"))
                        .font(.headline)
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    VStack(spacing: 16) {
                        // Star Rating
                        VStack(spacing: 8) {
                            Text("How was your experience?")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "718096"))
                            
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Button(action: { userRating = star }) {
                                        Image(systemName: star <= userRating ? "star.fill" : "star")
                                            .font(.system(size: 28))
                                            .foregroundColor(star <= userRating ? Color(hex: "fbbf24") : Color(hex: "cbd5e0"))
                                    }
                                }
                                Spacer()
                            }
                        }
                        
                        // Rating Message
                        TextField("Optional: Share feedback about this exchange", text: $ratingMessage)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3)
                        
                        // Submit Button
                        Button(action: submitRating) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("SUBMIT RATING")
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
                    .background(Color(hex: "f7fafc"))
                    .cornerRadius(12)
                }
                .padding()
            } else if hasSubmittedRating {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "10b981"))
                            .font(.system(size: 20))
                        Text("Rating submitted!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "10b981"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(hex: "ecfdf5"))
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .padding()
    }
    
    private func detailRow(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "718096"))
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "2d3748"))
            }
            Divider()
        }
    }
    
    // MARK: - API Functions
    
    // MARK: - Helper Functions
    
    private func formatDateTime(_ dateString: String) -> String {
        return DateFormatters.formatCompact(dateString)
    }
    
    // MARK: - Complete Exchange
    
    private func completeExchange() {
        let alert = UIAlertController(
            title: localizationManager.localize("CONFIRM_EXCHANGE_COMPLETE"),
            message: localizationManager.localize("EXCHANGE_COMPLETE_MESSAGE"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Complete", style: .default) { _ in
            self.submitCompleteExchange()
        })
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return
        }
        
        rootVC.present(alert, animated: true)
    }
    
    private func submitCompleteExchange() {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            return
        }
        
        let baseURL = Settings.shared.baseURL
        let url = URL(string: "\(baseURL)/Negotiations/CompleteExchange?SessionId=\(sessionId)&ListingId=\(contactData.listing.listingId)")!
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown")"
                    self.isLoading = false
                }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showRatingView = true
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.errorMessage = json["error"] as? String ?? "Failed to complete exchange"
                    } else {
                        self.errorMessage = "Failed to complete exchange"
                    }
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
        
        isLoading = true
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Ratings/SubmitRating")!
        components.queryItems = [
            URLQueryItem(name: "SessionId", value: sessionId),
            URLQueryItem(name: "ListingId", value: contactData.listing.listingId),
            URLQueryItem(name: "Rating", value: String(userRating)),
            URLQueryItem(name: "Comments", value: ratingMessage)
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
            return
        }
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Meeting/GetMeetingProposals")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing.listingId))
        ]
        
        guard let url = components.url else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    // Parse proposals
                    if let proposalsData = json["proposals"] as? [[String: Any]] {
                        self.meetingProposals = proposalsData.compactMap { dict in
                            guard let proposalId = dict["proposal_id"] as? String,
                                  let proposedLocation = dict["proposed_location"] as? String,
                                  let proposedTime = dict["proposed_time"] as? String,
                                  let status = dict["status"] as? String,
                                  let isFromMe = dict["is_from_me"] as? Bool,
                                  let proposerData = dict["proposer"] as? [String: Any],
                                  let firstName = proposerData["first_name"] as? String else { return nil }
                            
                            return MeetingProposal(
                                proposalId: proposalId,
                                proposedLocation: proposedLocation,
                                proposedTime: proposedTime,
                                message: dict["message"] as? String,
                                status: status,
                                isFromMe: isFromMe,
                                proposer: ProposerInfo(firstName: firstName)
                            )
                        }
                    }
                    
                    // Parse current meeting
                    if let meetingData = json["current_meeting"] as? [String: Any] {
                        if let time = meetingData["time"] as? String {
                            // Handle location - if it's nil or null, set to nil
                            let location: String? = meetingData["location"] as? String
                            let latitude: Double? = meetingData["latitude"] as? Double
                            let longitude: Double? = meetingData["longitude"] as? Double
                            let agreedAt = (meetingData["agreed_at"] as? String) ?? ""
                            let acceptedAt: String? = meetingData["accepted_at"] as? String
                            let locationAcceptedAt: String? = meetingData["location_accepted_at"] as? String
                            
                            print("[DEBUG LOAD] Parsed from response - acceptedAt: \(acceptedAt ?? "nil"), locationAcceptedAt: \(locationAcceptedAt ?? "nil")")
                            
                            self.currentMeeting = CurrentMeeting(
                                location: location,
                                latitude: latitude,
                                longitude: longitude,
                                time: time,
                                message: meetingData["message"] as? String,
                                agreedAt: agreedAt,
                                acceptedAt: acceptedAt,
                                locationAcceptedAt: locationAcceptedAt
                            )
                            self.timeAcceptedAt = acceptedAt
                            self.locationAcceptedAt = locationAcceptedAt
                            print("[DEBUG LOAD] Set self.timeAcceptedAt to: \(self.timeAcceptedAt ?? "nil")")
                        }
                    }
                }
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
                            if let acceptedAtFromResponse = json["agreementReachedAt"] as? String {
                                print("[DEBUG ACCEPT] Got agreementReachedAt from response: \(acceptedAtFromResponse)")
                                self.timeAcceptedAt = acceptedAtFromResponse
                            } else if let acceptedAtFromResponse = json["accepted_at"] as? String {
                                print("[DEBUG ACCEPT] Got accepted_at from response: \(acceptedAtFromResponse)")
                                self.timeAcceptedAt = acceptedAtFromResponse
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
