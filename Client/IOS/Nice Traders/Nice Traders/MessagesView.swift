//
//  MessagesView.swift
//  Nice Traders
//
//  Messages/Inbox view showing all active conversations
//

import SwiftUI

struct PurchasedContact: Identifiable, Codable, Hashable {
    let id: String
    let listingId: String
    let purchasedAt: String
    let currency: String
    let amount: Double
    let acceptCurrency: String
    let location: String?
    let sellerFirstName: String
    let sellerLastName: String
    let sellerUserId: String
    let messageCount: Int
    let lastMessage: String?
    let lastMessageTime: String?
    let willRoundToNearestDollar: Bool?
    
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
        case willRoundToNearestDollar = "will_round_to_nearest_dollar"
    }
}

struct MessagesView: View {
    @Binding var navigateToMessages: Bool
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var purchasedContacts: [PurchasedContact] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedContact: PurchasedContact?
    @State private var navigateToSearch = false
    @State private var navigateToCreateListing = false
    
    var body: some View {
        return VStack(spacing: 0) {
            // Header
            HStack {
                Text(localizationManager.localize("MESSAGES"))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "2d3748"))
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(Color.white)
            
            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Text(localizationManager.localize("LOADING_MESSAGES"))
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
                        Text(localizationManager.localize("TRY_AGAIN"))
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
                    Text(localizationManager.localize("NO_CONVERSATIONS_YET"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "2d3748"))
                    Text(localizationManager.localize("PURCHASE_CONTACT_ACCESS"))
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
                    .padding(.bottom, 80)
                }
            }
            
            // Bottom Navigation
            BottomNavigation(activeTab: "messages", isContactView: false, contactActiveTab: .constant(nil))
        }
        .background(Color(hex: "f7fafc"))
        .navigationBarHidden(true)
        .navigationDestination(item: $selectedContact) { contact in
            ContactView(contactData: convertToDashboardContactData(contact))
        }
        .navigationDestination(isPresented: $navigateToSearch) {
            SearchView(navigateToSearch: $navigateToSearch)
        }
        .navigationDestination(isPresented: $navigateToCreateListing) {
            CreateListingView(navigateToCreateListing: $navigateToCreateListing)
        }
        .onAppear {
            print("VIEW: MessagesView - Displaying inbox with \(purchasedContacts.count) conversations")
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
                    Text(localizationManager.localize("NO_MESSAGES_YET"))
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
        return DateFormatters.formatRelative(isoString)
    }
    
    func convertToDashboardContactData(_ contact: PurchasedContact) -> DashboardContactData {
        return DashboardContactData(
            listing: DashboardContactData.ContactListing(
                currency: contact.currency,
                accept_currency: contact.acceptCurrency,
                preferred_currency: nil,
                amount: contact.amount,
                meeting_preference: nil,
                location: contact.location ?? "",
                will_round_to_nearest_dollar: contact.willRoundToNearestDollar
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
