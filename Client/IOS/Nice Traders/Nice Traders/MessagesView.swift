//
//  MessagesView.swift
//  Nice Traders
//
//  Messages/Inbox view showing all active conversations
//

import SwiftUI

struct PurchasedContact: Identifiable, Codable, Hashable {
    let id: Int
    let listingId: Int
    let purchasedAt: String
    let currency: String
    let amount: Double
    let acceptCurrency: String
    let location: String?
    let sellerFirstName: String
    let sellerLastName: String
    let sellerUserId: Int
    let messageCount: Int
    let lastMessage: String?
    let lastMessageTime: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "access_id"
        case listingId = "listing_id"
        case purchasedAt = "purchased_at"
        case currency
        case amount
        case acceptCurrency = "accept_currency"
        case location
        case sellerFirstName = "seller_first_name"
        case sellerLastName = "seller_last_name"
        case sellerUserId = "seller_user_id"
        case messageCount = "message_count"
        case lastMessage = "last_message"
        case lastMessageTime = "last_message_time"
    }
}

struct MessagesView: View {
    @Binding var showMessages: Bool
    @State private var purchasedContacts: [PurchasedContact] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedContact: PurchasedContact?
    
    var body: some View {
        ZStack {
            Color(hex: "f7fafc")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header with back button
                HStack {
                    Button(action: {
                        showMessages = false
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(Color(hex: "667eea"))
                    }
                    
                    Spacer()
                    
                    Text("Messages")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Spacer()
                    
                    // Invisible button for spacing
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16))
                        }
                    }
                    .opacity(0)
                    .disabled(true)
                }
                .padding()
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading messages...")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "718096"))
                        .padding(.top)
                    Spacer()
                } else if let error = error {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "f56565"))
                        Text(error)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "718096"))
                            .multilineTextAlignment(.center)
                        Button(action: loadPurchasedContacts) {
                            Text("Try Again")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color(hex: "667eea"))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    Spacer()
                } else if purchasedContacts.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Text("💬")
                            .font(.system(size: 64))
                        Text("No Conversations Yet")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "2d3748"))
                        Text("Purchase contact access to start chatting with traders")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "718096"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(purchasedContacts) { contact in
                                contactRow(contact)
                                    .onTapGesture {
                                        selectedContact = contact
                                    }
                                
                                if contact.id != purchasedContacts.last?.id {
                                    Divider()
                                        .padding(.leading, 80)
                                }
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 8)
                        .padding()
                    }
                }
            }
        }
        .navigationDestination(item: $selectedContact) { contact in
            ContactView(contactData: convertToDashboardContactData(contact))
        }
        .onAppear {
            loadPurchasedContacts()
        }
    }
    
    func contactRow(_ contact: PurchasedContact) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(Color(hex: "667eea"))
                .frame(width: 56, height: 56)
                .overlay(
                    Text("\(contact.sellerFirstName.prefix(1))\(contact.sellerLastName.prefix(1))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(contact.sellerFirstName) \(contact.sellerLastName)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Spacer()
                    
                    if let lastTime = contact.lastMessageTime {
                        Text(formatTime(lastTime))
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "a0aec0"))
                    }
                }
                
                Text("\(Int(contact.amount)) \(contact.currency) → \(contact.acceptCurrency)")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "667eea"))
                
                if let lastMessage = contact.lastMessage {
                    Text(lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "718096"))
                        .lineLimit(2)
                } else {
                    Text("No messages yet")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "a0aec0"))
                        .italic()
                }
            }
            
            if contact.messageCount > 0 {
                Circle()
                    .fill(Color(hex: "667eea"))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text("\(contact.messageCount)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .padding()
        .background(Color.white)
    }
    
    func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = formatter.date(from: isoString) else {
            return ""
        }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            if days == 1 {
                return "Yesterday"
            } else if days < 7 {
                return "\(days)d ago"
            } else {
                let weekFormatter = DateFormatter()
                weekFormatter.dateFormat = "MMM d"
                return weekFormatter.string(from: date)
            }
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
    
    func convertToDashboardContactData(_ contact: PurchasedContact) -> DashboardContactData {
        return DashboardContactData(
            listing: DashboardContactData.ContactListing(
                currency: contact.currency,
                accept_currency: contact.acceptCurrency,
                preferred_currency: nil,
                amount: contact.amount,
                meeting_preference: nil,
                location: contact.location ?? ""
            ),
            other_user: DashboardContactData.ContactUser(
                first_name: contact.sellerFirstName,
                last_name: contact.sellerLastName,
                rating: nil,
                total_trades: nil
            ),
            type: "buyer",
            purchased_at: contact.purchasedAt,
            locked_amount: nil,
            exchange_rate: nil,
            listing_id: contact.listingId
        )
    }
    
    func loadPurchasedContacts() {
        guard let sessionId = UserDefaults.standard.string(forKey: "SessionId") else {
            error = "No active session"
            isLoading = false
            return
        }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Contact/GetPurchasedContacts")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId)
        ]
        
        guard let url = components.url else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    self.error = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let success = json["success"] as? Bool else {
                    self.error = "Invalid response"
                    return
                }
                
                if !success {
                    self.error = json["error"] as? String ?? "Failed to load messages"
                    return
                }
                
                if let contactsData = json["contacts"] as? [[String: Any]] {
                    let decoder = JSONDecoder()
                    purchasedContacts = contactsData.compactMap { dict in
                        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                              let contact = try? decoder.decode(PurchasedContact.self, from: jsonData) else {
                            return nil
                        }
                        return contact
                    }
                }
            }
        }.resume()
    }
}
