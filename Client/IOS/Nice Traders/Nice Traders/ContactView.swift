//
//  ContactView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/20/25.
//

import SwiftUI

struct DashboardContactData: Codable {
    let listing: ContactListing
    let other_user: ContactUser
    let type: String
    let purchased_at: String?
    let locked_amount: Double?
    let exchange_rate: Double?
    let listing_id: String
    
    struct ContactListing: Codable {
        let currency: String
        let accept_currency: String?
        let preferred_currency: String?
        let amount: Double
        let meeting_preference: String?
        let location: String
        let will_round_to_nearest_dollar: Bool?
    }
    
    struct ContactUser: Codable {
        let first_name: String
        let last_name: String
        let rating: Double?
        let total_trades: Int?
    }
}

struct DashboardContactMessage: Identifiable, Codable {
    let id: String
    let message_text: String
    let sent_at: String
    let is_from_user: Bool
}

struct DashboardMeetingProposal: Identifiable, Codable {
    let id: String
    let proposal_id: String
    let proposed_location: String
    let proposed_time: String
    let message: String?
    let status: String
    let is_from_me: Bool
    let proposer: DashboardProposerInfo
    
    struct DashboardProposerInfo: Codable {
        let first_name: String
    }
}

struct DashboardCurrentMeeting: Codable {
    let location: String
    let time: String
    let message: String?
    let agreed_at: String
}

struct ContactView: View {
    let contactData: DashboardContactData
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var activeTab: String = "details"
    @State private var messages: [DashboardContactMessage] = []
    @State private var newMessage: String = ""
    @State private var meetingProposals: [DashboardMeetingProposal] = []
    @State private var currentMeeting: DashboardCurrentMeeting?
    @State private var showProposeForm = false
    @State private var proposedLocation = ""
    @State private var proposedDate = Date()
    @State private var proposedTime = Date()
    @State private var proposalMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Navigation
                tabNavigation
                
                // Content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            if activeTab == "details" {
                                detailsContent
                            } else if activeTab == "location" {
                                locationContent
                            } else if activeTab == "messages" {
                                messagesContent
                                    .id("messagesBottom")
                            }
                        }
                    }
                    .onChange(of: messages.count) {
                        withAnimation {
                            proxy.scrollTo("messagesBottom", anchor: .bottom)
                        }
                    }
                }
                
                // Fixed message input for messages tab
                if activeTab == "messages" {
                    messageInputView
                }
            
            // Bottom Navigation
            BottomNavigation(activeTab: "messages")
        }
        .background(Color(hex: "f8fafc"))
        .navigationBarHidden(true)
        .onAppear {
            loadMessages()
            loadMeetingProposals()
        }
    }
    
    // MARK: - Header View
    var headerView: some View {
        HStack(alignment: .top) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    Text(contactData.listing.currency)
                        .font(.system(size: 28, weight: .bold))
                    Text("→")
                        .font(.system(size: 24))
                    Text(contactData.listing.accept_currency ?? contactData.listing.preferred_currency ?? "")
                        .font(.system(size: 28, weight: .bold))
                }
                
                Text("$\(ExchangeRatesAPI.shared.formatAmount(contactData.listing.amount, shouldRound: contactData.listing.will_round_to_nearest_dollar))")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color(hex: "FFD700"))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Tab Navigation
    var tabNavigation: some View {
        HStack(spacing: 16) {
            tabButton(tab: "details", icon: "📋", label: "Details")
            tabButton(tab: "location", icon: "📍", label: "Location")
            tabButton(tab: "messages", icon: "💬", label: "Chat (\(messages.count))")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(hex: "f8fafc"))
    }
    
    func tabButton(tab: String, icon: String, label: String) -> some View {
        Button(action: {
            activeTab = tab
        }) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 24))
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(activeTab == tab ?
                       LinearGradient(gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]), startPoint: .leading, endPoint: .trailing) :
                       LinearGradient(gradient: Gradient(colors: [Color.white]), startPoint: .leading, endPoint: .trailing))
            .foregroundColor(activeTab == tab ? .white : Color(hex: "4a5568"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(activeTab == tab ? Color.clear : Color(hex: "e2e8f0"), lineWidth: 2)
            )
        }
    }
    
    // MARK: - Details Content
    var detailsContent: some View {
        VStack(spacing: 24) {
            // Exchange Details
            VStack(alignment: .leading, spacing: 16) {
                Text(localizationManager.localize("EXCHANGE_DETAILS"))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                VStack(spacing: 12) {
                    detailRow(label: "Amount to Exchange:", value: "$\(ExchangeRatesAPI.shared.formatAmount(contactData.listing.amount, shouldRound: contactData.listing.will_round_to_nearest_dollar)) \(contactData.listing.currency)")
                    
                    if let lockedAmount = contactData.locked_amount,
                       let currency = contactData.listing.accept_currency ?? contactData.listing.preferred_currency {
                        detailRow(label: "Receiving:", value: "$\(Int(lockedAmount)) \(currency)")
                    } else {
                        detailRow(label: "Receiving:", value: "Exchange rate pending calculation")
                    }
                    
                    if let rate = contactData.exchange_rate {
                        detailRow(label: "Exchange Rate:", value: String(format: "%.4f", rate))
                    }
                    
                    detailRow(label: "Meeting Preference:", value: contactData.listing.meeting_preference ?? "Not specified")
                    detailRow(label: "General Location:", value: contactData.listing.location)
                    
                    if let purchasedAt = contactData.purchased_at {
                        detailRow(label: "Contact Purchased:", value: formatDate(purchasedAt))
                    }
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            
            // Trader Information
            VStack(alignment: .leading, spacing: 16) {
                Text(localizationManager.localize("TRADER_INFORMATION"))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Text("\(contactData.other_user.first_name) \(contactData.other_user.last_name)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        Text("★")
                            .font(.system(size: 16))
                            .foregroundColor(index < Int(contactData.other_user.rating ?? 0) ? Color(hex: "fbbf24") : Color(hex: "e2e8f0"))
                    }
                    
                    Text("(\\(contactData.other_user.total_trades ?? 0) " + localizationManager.localize("TRADES") + ")")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "718096"))
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .padding(24)
    }
    
    func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "718096"))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .fill(Color(hex: "e2e8f0"))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Location Content
    var locationContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(localizationManager.localize("MEETING_COORDINATION"))
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            // Current Meeting
            if let meeting = currentMeeting {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizationManager.localize("MEETING_AGREED"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "38a169"))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📍 " + localizationManager.localize("LOCATION") + ": \\(meeting.location)")
                        Text("🕒 " + localizationManager.localize("TIME") + ": \\(formatDateTime(meeting.time))")
                        if let message = meeting.message {
                            Text("💬 " + localizationManager.localize("NOTE") + ": \\(message)")
                        }
                        Text("📅 " + localizationManager.localize("AGREED") + ": \\(formatDateTime(meeting.agreed_at))")
                    }
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "2d3748"))
                }
                .padding(20)
                .background(Color(hex: "f0fff4"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "68d391"), lineWidth: 2)
                )
            } else {
                Text(localizationManager.localize("NO_MEETING_SCHEDULED"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "f59e0b"))
                    .frame(maxWidth: .infinity)
                    .padding(16)
                
                Button(action: {
                    showProposeForm.toggle()
                }) {
                    Text("📅 " + localizationManager.localize("PROPOSE_MEETING"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                
                if showProposeForm {
                    proposeForm
                }
            }
            
            // Meeting Proposals
            if !meetingProposals.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text(localizationManager.localize("MEETING_PROPOSALS"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    ForEach(meetingProposals) { proposal in
                        proposalCard(proposal)
                    }
                }
            }
            
            // General Location
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localize("GENERAL_AREA"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Text("📍 \(contactData.listing.location)")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "4a5568"))
                
                Text(localizationManager.localize("SPECIFIC_MEETING_LOCATIONS"))
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "718096"))
                    .italic()
            }
            .padding(20)
            .background(Color(hex: "f8fafc"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundColor(Color(hex: "e2e8f0"))
            )
        }
        .padding(24)
    }
    
    var proposeForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localize("PROPOSE_MEETING_DETAILS"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localize("MEETING_LOCATION"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "4a5568"))
                
                TextField(localizationManager.localize("MEETING_LOCATION_PLACEHOLDER"), text: $proposedLocation)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                    .onTapGesture { }
                    .simultaneousGesture(TapGesture().onEnded { })
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localize("DATE"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    DatePicker("", selection: $proposedDate, displayedComponents: .date)
                        .labelsHidden()
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                        )
                        .onTapGesture { }
                        .simultaneousGesture(TapGesture().onEnded { })
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localize("TIME"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    DatePicker("", selection: $proposedTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                        )
                        .onTapGesture { }
                        .simultaneousGesture(TapGesture().onEnded { })
                }
            }
            
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localize("OPTIONAL_MESSAGE"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "4a5568"))
                    TextEditor(text: $proposalMessage)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                    .onTapGesture { }
                    .simultaneousGesture(TapGesture().onEnded { })
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    showProposeForm = false
                }) {
                    Text(localizationManager.localize("CANCEL"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "4a5568"))
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color(hex: "e2e8f0"))
                        .cornerRadius(8)
                }
                
                Button(action: proposeMeeting) {
                    Text(localizationManager.localize("SEND_PROPOSAL"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color(hex: "667eea"))
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
        )
    }
    
    func proposalCard(_ proposal: DashboardMeetingProposal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(proposal.is_from_me ? "Your proposal" : "From \(proposal.proposer.first_name)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "4a5568"))
                
                Spacer()
                
                statusBadge(proposal.status)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("📍 \(proposal.proposed_location)")
                Text("🕒 \(formatDateTime(proposal.proposed_time))")
                if let message = proposal.message, !message.isEmpty {
                    Text("💬 \(message)")
                }
            }
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "2d3748"))
            
            if !proposal.is_from_me && proposal.status == "pending" {
                HStack(spacing: 12) {
                    Button(action: {
                        respondToProposal(proposal.proposal_id, response: "accepted")
                    }) {
                        Text("✅ " + localizationManager.localize("ACCEPT"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color(hex: "48bb78"))
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        respondToProposal(proposal.proposal_id, response: "rejected")
                    }) {
                        Text("❌ " + localizationManager.localize("REJECT"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color(hex: "f56565"))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(backgroundColor(for: proposal.status))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor(for: proposal.status), lineWidth: 2)
        )
    }
    
    func statusBadge(_ status: String) -> some View {
        let (text, color) = statusInfo(status)
        
        return Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(20)
    }
    
    func statusInfo(_ status: String) -> (String, Color) {
        switch status {
        case "pending":
            return ("⏳ Pending", Color(hex: "d69e2e"))
        case "accepted":
            return ("✅ Accepted", Color(hex: "38a169"))
        case "rejected":
            return ("❌ Rejected", Color(hex: "e53e3e"))
        case "expired":
            return ("⏰ Expired", Color(hex: "a0aec0"))
        default:
            return (status, Color(hex: "6b7280"))
        }
    }
    
    func backgroundColor(for status: String) -> Color {
        switch status {
        case "accepted":
            return Color(hex: "f0fff4")
        case "rejected":
            return Color(hex: "fff5f5")
        case "expired":
            return Color(hex: "f7fafc")
        default:
            return Color.white
        }
    }
    
    func borderColor(for status: String) -> Color {
        switch status {
        case "accepted":
            return Color(hex: "68d391")
        case "rejected":
            return Color(hex: "fc8181")
        case "expired":
            return Color(hex: "a0aec0")
        default:
            return Color(hex: "e2e8f0")
        }
    }
    
    // MARK: - Messages Content
    var messagesContent: some View {
        VStack(spacing: 0) {
            if messages.isEmpty {
                VStack(spacing: 16) {
                    Text("💬")
                        .font(.system(size: 48))
                    
                    Text(localizationManager.localize("NO_MESSAGES_YET_CONTACT"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    Text(localizationManager.localize("START_CONVERSATION"))
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "718096"))
                }
                .frame(maxWidth: .infinity)
                .padding(48)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        messageRow(message)
                    }
                }
                .padding(24)
            }
        }
    }
    
    func messageRow(_ message: DashboardContactMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.is_from_user {
                Circle()
                    .fill(Color(hex: "667eea"))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(contactData.other_user.first_name.prefix(1)))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            
            if message.is_from_user {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: message.is_from_user ? .trailing : .leading, spacing: 4) {
                Text(message.message_text)
                    .font(.system(size: 15))
                    .padding(12)
                    .background(message.is_from_user ? Color(hex: "007AFF") : Color(hex: "E5E5EA"))
                    .foregroundColor(message.is_from_user ? .white : .black)
                    .cornerRadius(18)
                
                Text(formatDateTime(message.sent_at))
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "718096"))
            }
            
            if !message.is_from_user {
                Spacer(minLength: 50)
            }
            
            if message.is_from_user {
                Circle()
                    .fill(Color(hex: "34d399"))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(localizationManager.localize("YOU_LABEL"))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    // MARK: - Message Input
    var messageInputView: some View {
        HStack(spacing: 12) {
            TextField(localizationManager.localize("TYPE_MESSAGE"), text: $newMessage)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(hex: "f8fafc"))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
                )
                .onTapGesture { }
                .simultaneousGesture(TapGesture().onEnded { })
            
            Button(action: sendMessage) {
                Text(localizationManager.localize("SEND_MESSAGE"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(newMessage.isEmpty ? Color(hex: "a0aec0") : Color(hex: "007AFF"))
                    .cornerRadius(20)
            }
            .disabled(newMessage.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -2)
    }
    
    // MARK: - Functions
    func loadMessages() {
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Contact/GetContactMessages")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing_id))
        ]
        
        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let messagesData = json["messages"] as? [[String: Any]] {
                    
                    let decoder = JSONDecoder()
                    messages = messagesData.compactMap { dict -> DashboardContactMessage? in
                        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                              let message = try? decoder.decode(DashboardContactMessage.self, from: jsonData) else {
                            return nil
                        }
                        return message
                    }
                }
            }
        }.resume()
    }
    
    func sendMessage() {
        guard !newMessage.isEmpty,
              let sessionId = SessionManager.shared.sessionId else { return }
        
        let messageToSend = newMessage
        newMessage = ""
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Contact/SendContactMessage")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing_id)),
            URLQueryItem(name: "message", value: messageToSend)
        ]
        
        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    loadMessages()
                }
            }
        }.resume()
    }
    
    func loadMeetingProposals() {
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        let url = URL(string: "\(Settings.shared.baseURL)/Meeting/GetMeetingProposals?sessionId=\(sessionId)&listingId=\(contactData.listing_id)")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    if let proposalsData = json["proposals"] as? [[String: Any]] {
                        let decoder = JSONDecoder()
                        meetingProposals = proposalsData.compactMap { dict -> DashboardMeetingProposal? in
                            guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                                  let proposal = try? decoder.decode(DashboardMeetingProposal.self, from: jsonData) else {
                                return nil
                            }
                            return proposal
                        }
                    }
                    
                    if let meetingData = json["current_meeting"] as? [String: Any],
                       let jsonData = try? JSONSerialization.data(withJSONObject: meetingData) {
                        let decoder = JSONDecoder()
                        currentMeeting = try? decoder.decode(DashboardCurrentMeeting.self, from: jsonData)
                    }
                }
            }
        }.resume()
    }
    
    func proposeMeeting() {
        guard !proposedLocation.isEmpty,
              let sessionId = SessionManager.shared.sessionId else { return }
        
        let dateFormatter = ISO8601DateFormatter()
        let calendar = Calendar.current
        let combinedDate = calendar.dateComponents([.year, .month, .day], from: proposedDate)
        let combinedTime = calendar.dateComponents([.hour, .minute], from: proposedTime)
        
        var dateComponents = DateComponents()
        dateComponents.year = combinedDate.year
        dateComponents.month = combinedDate.month
        dateComponents.day = combinedDate.day
        dateComponents.hour = combinedTime.hour
        dateComponents.minute = combinedTime.minute
        
        guard let finalDate = calendar.date(from: dateComponents) else { return }
        let proposedDateTime = dateFormatter.string(from: finalDate)
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/ProposeMeeting")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing_id)),
            URLQueryItem(name: "proposedLocation", value: proposedLocation),
            URLQueryItem(name: "proposedTime", value: proposedDateTime),
            URLQueryItem(name: "message", value: proposalMessage)
        ]
        
        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    proposedLocation = ""
                    proposalMessage = ""
                    showProposeForm = false
                    loadMeetingProposals()
                }
            }
        }.resume()
    }
    
    func respondToProposal(_ proposalId: String, response: String) {
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/RespondToMeeting")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "proposalId", value: proposalId),
            URLQueryItem(name: "response", value: response)
        ]
        
        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    loadMeetingProposals()
                }
            }
        }.resume()
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatDateTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

#Preview {
    ContactView(contactData: DashboardContactData(
        listing: DashboardContactData.ContactListing(
            currency: "USD",
            accept_currency: "EUR",
            preferred_currency: nil,
            amount: 500,
            meeting_preference: "public",
            location: "New York, NY",
            will_round_to_nearest_dollar: true
        ),
        other_user: DashboardContactData.ContactUser(
            first_name: "John",
            last_name: "Doe",
            rating: 4.5,
            total_trades: 12
        ),
        type: "buyer",
        purchased_at: "2025-11-15",
        locked_amount: 425,
        exchange_rate: 0.85,
        listing_id: "LST-preview-123"
    ))
}
