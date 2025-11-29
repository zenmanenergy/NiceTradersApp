//
//  ContactDetailView.swift
//  Nice Traders
//
//  Contact detail page with messaging and meeting coordination
//

import SwiftUI

struct ContactDetailView: View {
    let contactData: ContactData
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    @State private var activeTab: ContactTab = .details
    @State private var messages: [ContactMessage] = []
    @State private var newMessage: String = ""
    @State private var meetingProposals: [MeetingProposal] = []
    @State private var currentMeeting: CurrentMeeting?
    @State private var showProposeForm: Bool = false
    
    // Propose meeting form fields
    @State private var proposedLocation: String = ""
    @State private var proposedDate: Date = Date()
    @State private var proposedTime: Date = Date()
    @State private var proposalMessage: String = ""
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    // Real-time polling states
    @State private var pollingTimer: Timer?
    @State private var lastMessageCount: Int = 0
    @State private var isPolling: Bool = false
    @State private var lastPollTime: Date?
    @State private var messageDeliveryStatus: [String: MessageDeliveryStatus] = [:] // Track delivery status by message ID
    
    enum MessageDeliveryStatus {
        case sending
        case sent
        case delivered
        case failed
    }
    
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
        ZStack {
            VStack(spacing: 0) {
                if activeTab == .messages {
                    // CHAT TAB - Minimal header with back button
                    VStack(spacing: 0) {
                        HStack {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text(contactData.otherUser.firstName)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                            }
                            Spacer()
                            Text("\(contactData.listing.currency) → \(contactData.listing.acceptCurrency ?? contactData.listing.preferredCurrency ?? "")")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    .padding(.top, 0)
                    
                    // Chat messages take full screen
                    messagesView
                } else {
                    // OTHER TABS - Full layout with header and navigation
                    VStack(spacing: 0) {
                        // Header
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            VStack(alignment: .trailing, spacing: 8) {
                                HStack {
                                    Button(action: { dismiss() }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "chevron.left")
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                    }
                                    Spacer()
                                }
                                
                                Spacer()
                                
                                HStack {
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Text(contactData.listing.currency)
                                            Text("→")
                                            Text(contactData.listing.acceptCurrency ?? contactData.listing.preferredCurrency ?? "")
                                        }
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        
                                        Text("$\(ExchangeRatesAPI.shared.formatAmount(contactData.listing.amount, shouldRound: contactData.listing.willRoundToNearestDollar))")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(hex: "FFD700"))
                                    }
                                }
                            }
                            .padding()
                            .padding(.top, 40)
                        }
                        .frame(height: 160)
                    
                        // Tab Navigation (only for non-chat tabs)
                        HStack(spacing: 12) {
                            ForEach(ContactTab.allCases, id: \.self) { tab in
                                Button(action: { activeTab = tab }) {
                                    VStack(spacing: 8) {
                                        Text(tab.icon)
                                            .font(.title2)
                                        Text(tab == .messages ? "\(tab.rawValue) (\(messages.count))" : tab.rawValue)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        activeTab == tab ?
                                        LinearGradient(gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                                        LinearGradient(gradient: Gradient(colors: [.white, .white]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .foregroundColor(activeTab == tab ? .white : Color(hex: "4a5568"))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(activeTab == tab ? Color.clear : Color(hex: "e2e8f0"), lineWidth: 2)
                                    )
                                }
                            }
                        }
                        .padding()
                        
                        // Content based on active tab
                        ScrollView {
                            switch activeTab {
                            case .details:
                                detailsView
                            case .location:
                                locationView
                            case .messages:
                                EmptyView()
                            }
                        }
                        
                        Spacer(minLength: 80)
                    }
                }
            }
            
            // Bottom Navigation (only show for non-chat tabs)
            if activeTab != .messages {
                VStack {
                    Spacer()
                    BottomNavigation(activeTab: "messages")
                }
            }
        }
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            loadMessages()
            loadMeetingProposals()
            startPollingIfNeeded()
        }
        .onChange(of: activeTab) { newTab in
            if newTab == .messages {
                startPollingIfNeeded()
            } else {
                stopPolling()
            }
        }
        .onDisappear {
            stopPolling()
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
                
                detailRow(label: "Amount to Exchange:", value: "$\(ExchangeRatesAPI.shared.formatAmount(contactData.listing.amount, shouldRound: contactData.listing.willRoundToNearestDollar)) \(contactData.listing.currency)")
                
                detailRow(label: "Meeting Preference:", value: contactData.listing.meetingPreference ?? "Not specified")
                
                if let purchasedAt = contactData.purchasedAt {
                    detailRow(label: "Contact Purchased:", value: formatDate(purchasedAt))
                } else {
                    detailRow(label: "Contact Purchased:", value: "Not specified")
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
    
    // MARK: - Location View
    
    private var locationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localize("MEETING_COORDINATION"))
                .font(.headline)
                .foregroundColor(Color(hex: "2d3748"))
            
            // Current Meeting (if agreed)
            if let meeting = currentMeeting {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("✅ " + localizationManager.localize("MEETING_AGREED"))
                            .font(.headline)
                            .foregroundColor(Color(hex: "38a169"))
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("📍 " + localizationManager.localize("LOCATION") + ":")
                                .fontWeight(.semibold)
                            Text(meeting.location)
                        }
                        HStack {
                            Text("🕒 " + localizationManager.localize("TIME") + ":")
                                .fontWeight(.semibold)
                            Text(formatDateTime(meeting.time))
                        }
                        if let message = meeting.message {
                            HStack(alignment: .top) {
                                Text("💬 " + localizationManager.localize("NOTE") + ":")
                                    .fontWeight(.semibold)
                                Text(message)
                            }
                        }
                        HStack {
                            Text("📅 " + localizationManager.localize("AGREED") + ":")
                                .fontWeight(.semibold)
                            Text(formatDateTime(meeting.agreedAt))
                        }
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(hex: "f0fff4"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "68d391"), lineWidth: 2)
                )
                .cornerRadius(12)
            } else {
                HStack {
                    Spacer()
                    Text("⏳ " + localizationManager.localize("NO_MEETING_SCHEDULED"))
                        .foregroundColor(Color(hex: "f59e0b"))
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
            }
            
            // Propose Meeting Button
            if currentMeeting == nil {
                Button(action: { showProposeForm.toggle() }) {
                    Text("📅 " + localizationManager.localize("PROPOSE_MEETING"))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(12)
                }
                
                // Propose Meeting Form
                if showProposeForm {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizationManager.localize("PROPOSE_MEETING_DETAILS"))
                            .font(.headline)
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(localizationManager.localize("MEETING_LOCATION_REQUIRED"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "4a5568"))
                            TextField("e.g., Starbucks on 5th Street", text: $proposedLocation)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onTapGesture { }
                                .simultaneousGesture(TapGesture().onEnded { })
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.localize("DATE_REQUIRED"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "4a5568"))
                                DatePicker("", selection: $proposedDate, in: Date()..., displayedComponents: .date)
                                    .labelsHidden()
                                    .onTapGesture { }
                                    .simultaneousGesture(TapGesture().onEnded { })
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.localize("TIME_REQUIRED"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "4a5568"))
                                DatePicker("", selection: $proposedTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .onTapGesture { }
                                    .simultaneousGesture(TapGesture().onEnded { })
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(localizationManager.localize("OPTIONAL_MESSAGE"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "4a5568"))
                            TextEditor(text: $proposalMessage)
                                .frame(height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                                )
                                .onTapGesture { }
                                .simultaneousGesture(TapGesture().onEnded { })
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: { showProposeForm = false }) {
                                Text(localizationManager.localize("CANCEL"))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "4a5568"))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "e2e8f0"))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: proposeMeeting) {
                                Text(localizationManager.localize("SEND_PROPOSAL"))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "667eea"))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                    .cornerRadius(12)
                }
            }
            
            // Meeting Proposals History
            if !meetingProposals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizationManager.localize("MEETING_PROPOSALS"))
                        .font(.headline)
                        .foregroundColor(Color(hex: "2d3748"))
                    ForEach(meetingProposals) { proposal in
                        proposalCard(proposal)
                    }
                }
            }
            
            // General Location
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localize("GENERAL_AREA"))
                    .font(.headline)
                    .foregroundColor(Color(hex: "2d3748"))
                Text("📍 \(contactData.listing.location)")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "4a5568"))
                Text(localizationManager.localize("SPECIFIC_MEETING_LOCATIONS_NOTE"))
                    .font(.caption)
                    .foregroundColor(Color(hex: "718096"))
                    .italic()
            }
            .padding()
            .background(Color(hex: "f8fafc"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(hex: "e2e8f0"), style: StrokeStyle(lineWidth: 2, dash: [5]))
            )
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding()
    }
    
    private func proposalCard(_ proposal: MeetingProposal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(proposal.isFromMe ? "Your proposal" : "From \(proposal.proposer.firstName)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "4a5568"))
                Spacer()
                statusBadge(proposal.status)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("📍 \(proposal.proposedLocation)")
                Text("🕒 \(formatDateTime(proposal.proposedTime))")
                if let message = proposal.message {
                    Text("💬 \(message)")
                }
            }
            .font(.subheadline)
            .foregroundColor(Color(hex: "4a5568"))
            
            if !proposal.isFromMe && proposal.status == "pending" {
                HStack(spacing: 12) {
                    Button(action: { respondToProposal(proposal.proposalId, response: "accepted") }) {
                        Text("✅ " + localizationManager.localize("ACCEPT"))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(hex: "48bb78"))
                            .cornerRadius(8)
                    }
                    
                    Button(action: { respondToProposal(proposal.proposalId, response: "rejected") }) {
                        Text("❌ " + localizationManager.localize("REJECT"))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(hex: "f56565"))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(backgroundColor(for: proposal.status))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor(for: proposal.status), lineWidth: 2)
        )
        .cornerRadius(12)
    }
    
    private func statusBadge(_ status: String) -> some View {
        let text: String
        let bgColor: Color
        let textColor: Color
        
        switch status {
        case "pending":
            text = "⏳ Pending"
            bgColor = Color(hex: "fef5e7")
            textColor = Color(hex: "d69e2e")
        case "accepted":
            text = "✅ Accepted"
            bgColor = Color(hex: "f0fff4")
            textColor = Color(hex: "38a169")
        case "rejected":
            text = "❌ Rejected"
            bgColor = Color(hex: "fed7d7")
            textColor = Color(hex: "e53e3e")
        case "expired":
            text = "⏰ Expired"
            bgColor = Color(hex: "f7fafc")
            textColor = Color(hex: "a0aec0")
        default:
            text = status
            bgColor = Color.gray.opacity(0.2)
            textColor = Color.gray
        }
        
        return Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(bgColor)
            .foregroundColor(textColor)
            .cornerRadius(20)
    }
    
    private func backgroundColor(for status: String) -> Color {
        switch status {
        case "accepted": return Color(hex: "f0fff4")
        case "rejected": return Color(hex: "fef5e7")
        case "expired": return Color(hex: "f7fafc").opacity(0.8)
        default: return Color.white
        }
    }
    
    private func borderColor(for status: String) -> Color {
        switch status {
        case "accepted": return Color(hex: "68d391")
        case "rejected": return Color(hex: "fc8181")
        case "expired": return Color(hex: "a0aec0")
        default: return Color(hex: "e2e8f0")
        }
    }
    
    // MARK: - Messages View
    
    private var messagesView: some View {
        VStack(spacing: 0) {
            // Real-time indicator (minimal)
            HStack(spacing: 8) {
                if isPolling {
                    Circle()
                        .fill(Color(hex: "34d399"))
                        .frame(width: 6, height: 6)
                    
                    Text("Live")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "34d399"))
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 6, height: 6)
                    
                    Text("Offline")
                        .font(.caption2)
                        .foregroundColor(Color.gray.opacity(0.6))
                }
                
                Spacer()
                
                if let lastPoll = lastPollTime {
                    Text(formatRelativeTime(lastPoll))
                        .font(.caption2)
                        .foregroundColor(Color.gray.opacity(0.6))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "f8fafc").opacity(0.8))
            
            // Messages ScrollView - auto scroll to bottom
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            messageRow(message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: messages.count) { _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if let lastMessage = messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let lastMessage = messages.last {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Message Input
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    TextField("Message...", text: $newMessage)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(hex: "f8fafc"))
                        .cornerRadius(20)
                        .lineLimit(4)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(newMessage.isEmpty ? Color(hex: "a0aec0") : Color(hex: "007AFF"))
                            .cornerRadius(20)
                    }
                    .disabled(newMessage.isEmpty)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: -1)
        }
    }
    
    private func messageRow(_ message: ContactMessage) -> some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 8) {
                if !message.isFromUser {
                    // Avatar for received messages
                    Circle()
                        .fill(Color(hex: "667eea"))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(contactData.otherUser.firstName.prefix(1)))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                }
                
                if message.isFromUser {
                    Spacer()
                }
                
                VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                    Text(message.messageText)
                        .font(.subheadline)
                        .foregroundColor(message.isFromUser ? .white : .black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(message.isFromUser ? Color(hex: "007AFF") : Color(hex: "E5E5EA"))
                        .cornerRadius(18)
                        .cornerRadius(message.isFromUser ? 8 : 18, corners: message.isFromUser ? [.bottomRight] : [.bottomLeft])
                    
                    HStack(spacing: 4) {
                        Text(formatDateTime(message.sentAt))
                            .font(.caption2)
                            .foregroundColor(Color.black.opacity(0.5))
                        
                        if message.isFromUser {
                            // Show delivery status for user's messages
                            if let status = messageDeliveryStatus[message.id] {
                                switch status {
                                case .sending:
                                    Image(systemName: "clock.fill")
                                        .font(.caption2)
                                        .foregroundColor(Color.gray.opacity(0.6))
                                case .sent:
                                    Image(systemName: "checkmark")
                                        .font(.caption2)
                                        .foregroundColor(Color.gray.opacity(0.6))
                                case .delivered:
                                    HStack(spacing: 0) {
                                        Image(systemName: "checkmark")
                                            .font(.caption2)
                                            .foregroundColor(Color.blue)
                                        Image(systemName: "checkmark")
                                            .font(.caption2)
                                            .foregroundColor(Color.blue)
                                    }
                                case .failed:
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(Color.red)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: geometry.size.width * 0.75, alignment: message.isFromUser ? .trailing : .leading)
                
                if !message.isFromUser {
                    Spacer()
                }
                
                if message.isFromUser {
                    // Avatar for sent messages
                    Circle()
                        .fill(Color(hex: "34d399"))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(localizationManager.localize("YOU"))
                                .font(.system(size: 8))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        )
                }
            }
        }
    }
    
    // MARK: - API Functions
    
    private func loadMessages() {
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Contact/GetContactMessages")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing.listingId))
        ]
        
        guard let url = components.url else {
            print("Error: Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error loading messages: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success,
               let messagesData = json["messages"] as? [[String: Any]] {
                
                DispatchQueue.main.async {
                    self.messages = messagesData.compactMap { dict in
                        guard let messageText = dict["message_text"] as? String,
                              let sentAt = dict["sent_at"] as? String,
                              let isFromUser = dict["is_from_user"] as? Bool else { return nil }
                        
                        return ContactMessage(
                            id: dict["message_id"] as? String ?? "",
                            messageText: messageText,
                            sentAt: sentAt,
                            isFromUser: isFromUser
                        )
                    }
                }
            }
        }.resume()
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        let messageToSend = newMessage
        newMessage = ""
        
        // Create a temporary message ID for tracking
        let tempMessageId = UUID().uuidString
        
        // Immediately add message to UI and mark as sending
        let tempMessage = ContactMessage(
            id: tempMessageId,
            messageText: messageToSend,
            sentAt: ISO8601DateFormatter().string(from: Date()),
            isFromUser: true
        )
        
        DispatchQueue.main.async {
            self.messages.append(tempMessage)
            self.messageDeliveryStatus[tempMessageId] = .sending
        }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Contact/SendContactMessage")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing.listingId)),
            URLQueryItem(name: "message", value: messageToSend)
        ]
        
        guard let url = components.url else {
            print("Error: Invalid URL")
            DispatchQueue.main.async {
                self.messageDeliveryStatus[tempMessageId] = .failed
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if error != nil {
                    // Mark as failed
                    self.messageDeliveryStatus[tempMessageId] = .failed
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    // Mark as sent, then reload for actual server message
                    self.messageDeliveryStatus[tempMessageId] = .sent
                    
                    // Reload messages to get the actual message with server timestamp
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.loadMessages()
                    }
                } else {
                    // Mark as failed
                    self.messageDeliveryStatus[tempMessageId] = .failed
                }
            }
        }.resume()
    }
    
    private func loadMeetingProposals() {
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/GetMeetingProposals")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing.listingId))
        ]
        
        guard let url = components.url else {
            print("Error: Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error loading proposals: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                
                DispatchQueue.main.async {
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
                    if let meetingData = json["current_meeting"] as? [String: Any],
                       let location = meetingData["location"] as? String,
                       let time = meetingData["time"] as? String,
                       let agreedAt = meetingData["agreed_at"] as? String {
                        
                        self.currentMeeting = CurrentMeeting(
                            location: location,
                            time: time,
                            message: meetingData["message"] as? String,
                            agreedAt: agreedAt
                        )
                    }
                }
            }
        }.resume()
    }
    
    private func proposeMeeting() {
        guard !proposedLocation.isEmpty else {
            errorMessage = "Please enter a meeting location"
            return
        }
        
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        // Combine date and time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: proposedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: proposedTime)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = 0
        
        guard let combinedDate = calendar.date(from: combined) else { return }
        
        // Format as ISO 8601
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let proposedDateTime = formatter.string(from: combinedDate)
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/ProposeMeeting")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing.listingId)),
            URLQueryItem(name: "proposedLocation", value: proposedLocation),
            URLQueryItem(name: "proposedTime", value: proposedDateTime),
            URLQueryItem(name: "message", value: proposalMessage)
        ]
        
        guard let url = components.url else {
            print("Error: Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error proposing meeting: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                
                DispatchQueue.main.async {
                    // Reset form
                    self.proposedLocation = ""
                    self.proposedDate = Date()
                    self.proposedTime = Date()
                    self.proposalMessage = ""
                    self.showProposeForm = false
                    
                    // Reload proposals
                    self.loadMeetingProposals()
                }
            }
        }.resume()
    }
    
    private func respondToProposal(_ proposalId: String, response: String) {
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/RespondToMeeting")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "proposalId", value: proposalId),
            URLQueryItem(name: "response", value: response)
        ]
        
        guard let url = components.url else {
            print("Error: Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error responding to proposal: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                
                DispatchQueue.main.async {
                    self.loadMeetingProposals()
                }
            }
        }.resume()
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ dateString: String) -> String {
        return DateFormatters.formatCompact(dateString)
    }
    
    private func formatDateTime(_ dateString: String) -> String {
        return DateFormatters.formatCompact(dateString)
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let elapsed = Date().timeIntervalSince(date)
        
        if elapsed < 60 {
            return "now"
        } else if elapsed < 3600 {
            let minutes = Int(elapsed / 60)
            return "\(minutes)m ago"
        } else if elapsed < 86400 {
            let hours = Int(elapsed / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(elapsed / 86400)
            return "\(days)d ago"
        }
    }
    
    // MARK: - Real-Time Polling
    
    private func startPollingIfNeeded() {
        guard pollingTimer == nil else { return }
        guard activeTab == .messages else { return }
        
        // Initial load
        loadMessages()
        lastMessageCount = messages.count
        isPolling = true
        lastPollTime = Date()
        
        // Start polling every 1.5 seconds
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            self.pollMessages()
        }
    }
    
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPolling = false
    }
    
    private func pollMessages() {
        guard activeTab == .messages else {
            stopPolling()
            return
        }
        
        loadMessages()
        lastPollTime = Date()
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
    let location: String
    let time: String
    let message: String?
    let agreedAt: String
}

// Extensions are in SharedModels.swift
