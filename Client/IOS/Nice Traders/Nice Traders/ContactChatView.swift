//
//  ContactChatView.swift
//  Nice Traders
//
//  Chat messaging view for contacts
//

import SwiftUI

struct ContactChatView: View {
    let contactData: ContactData
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    var onBackTapped: (() -> Void)?
    
    @State var messages: [ContactMessage] = []
    @State var newMessage: String = ""
    @State var messageDeliveryStatus: [String: MessageDeliveryStatus] = [:]
    
    // Real-time polling states
    @State var pollingTimer: Timer?
    @State var lastMessageCount: Int = 0
    @State var isPolling: Bool = false
    @State var lastPollTime: Date?
    
    enum MessageDeliveryStatus {
        case sending
        case sent
        case delivered
        case failed
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with back button
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            print("DEBUG: Back button tapped in ContactChatView")
                            if let callback = onBackTapped {
                                print("DEBUG: Calling onBackTapped callback")
                                callback()
                            } else {
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                        }
                        Spacer()
                        let convertedAmount = ExchangeRatesAPI.shared.convertAmountSync(contactData.listing.amount, from: contactData.listing.currency, to: contactData.listing.acceptCurrency ?? contactData.listing.preferredCurrency ?? "") ?? contactData.listing.amount
                        let formattedConverted = ExchangeRatesAPI.shared.formatAmount(convertedAmount, shouldRound: contactData.listing.willRoundToNearestDollar ?? false)
                        let formattedOriginal = ExchangeRatesAPI.shared.formatAmount(contactData.listing.amount, shouldRound: contactData.listing.willRoundToNearestDollar ?? false)
                        
                        Text("$\(formattedOriginal) \(contactData.listing.currency) → \(formattedConverted) \(contactData.listing.acceptCurrency ?? "")")
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
        }
        .navigationBarHidden(true)
        .onAppear {
            print("VIEW: ContactChatView")
            loadMessages()
            startPollingIfNeeded()
        }
        .onDisappear {
            stopPolling()
        }
    }
    
    private func messageRow(_ message: ContactMessage) -> some View {
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
                .frame(maxWidth: .infinity * 0.75, alignment: message.isFromUser ? .trailing : .leading)
                
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
    
    // MARK: - API Functions
    
    private func loadMessages() {
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Contact/GetContactMessages")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing.listingId))
        ]
        
        guard let url = components.url else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
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
    
    // MARK: - Helper Functions
    
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
        loadMessages()
        lastPollTime = Date()
    }
}

#Preview {
    ContactChatView(
        contactData: ContactData(
            listing: ContactListing(
                listingId: "1",
                currency: "USD",
                amount: 100,
                acceptCurrency: "EUR",
                preferredCurrency: "USD",
                meetingPreference: "public",
                location: "New York, NY",
                latitude: 40.7128,
                longitude: -74.0060,
                radius: 50,
                willRoundToNearestDollar: false
            ),
            otherUser: OtherUser(firstName: "John", lastName: "Doe", rating: 4.5, totalTrades: 10),
            lockedAmount: nil,
            exchangeRate: nil,
            fromCurrency: nil,
            toCurrency: nil,
            purchasedAt: nil
        )
    )
}
