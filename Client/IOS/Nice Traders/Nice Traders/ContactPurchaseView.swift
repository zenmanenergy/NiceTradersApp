//
//  ContactPurchaseView.swift
//  Nice Traders
//
//  Pre-purchase contact view - displays listing details and allows purchase of contact access
//

import SwiftUI
import CoreLocation
import Combine

struct ContactPurchaseView: View {
    let listingId: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    @State private var listing: ListingDetails?
    @State private var contactFee: ContactFee?
    @State private var hasActiveContact: Bool = false
    @State private var isLoading: Bool = true
    @State private var loadError: String?
    @State private var isProcessingPayment: Bool = false
    
    @State private var showReportModal: Bool = false
    @State private var reportReason: String = ""
    @State private var reportDescription: String = ""
    
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
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
                    
                    Text(localizationManager.localize("CONTACT_TRADER"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showReportModal = true }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .frame(height: 60)
            
            // Content
            if isLoading {
                loadingView
            } else if let error = loadError {
                errorView(error)
            } else if let listing = listing {
                ScrollView {
                    VStack(spacing: 16) {
                        listingSummaryView(listing)
                        traderProfileView(listing)
                        contactStatusView(listing)
                        unlockContactView()
                        safetyTipsView
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadContactDetails()
        }
        .sheet(isPresented: $showReportModal) {
            reportModalView()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(localizationManager.localize("LOADING_CONTACT_DETAILS"))
                .foregroundColor(Color(hex: "718096"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Text(error)
                .foregroundColor(Color(hex: "e53e3e"))
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Button(action: { loadContactDetails() }) {
                Text(localizationManager.localize("TRY_AGAIN"))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "667eea"))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    // MARK: - Listing Summary
    
    private func listingSummaryView(_ listing: ListingDetails) -> some View {
        VStack(spacing: 12) {
            HStack {
                // Currency display
                HStack(spacing: 12) {
                    currencyFlagImage(listing.currency)
                        .frame(width: 32, height: 24)
                        .cornerRadius(4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ExchangeRatesAPI.shared.formatAmount(listing.amount, shouldRound: listing.willRoundToNearestDollar) + " \(listing.currency)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        Text(listing.rate == "market" ? localizationManager.localize("MARKET_RATE") : "$" + String(format: "%.4f", listing.customRate) + " per \(listing.currency)")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "667eea"))
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                // Location info
                VStack(alignment: .trailing, spacing: 4) {
                    Text(listing.location)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    Text(localizationManager.localize("WITHIN_N_MILES_RANGE").replacingOccurrences(of: "N", with: String(listing.locationRadius)))
                        .font(.caption)
                        .foregroundColor(Color(hex: "718096"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "f7fafc"))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Trader Profile
    
    private func traderProfileView(_ listing: ListingDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(hasActiveContact ? "\(listing.user.firstName) \(listing.user.lastName ?? "")" : listing.user.firstName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        if listing.user.verified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(Color(hex: "48bb78"))
                                .font(.subheadline)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color(hex: "fbbf24"))
                                .font(.caption)
                            Text(String(format: "%.1f", listing.user.rating))
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "718096"))
                        }
                        
                        Text("\(listing.user.trades) " + localizationManager.localize("COMPLETED_TRADES"))
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "718096"))
                    }
                }
                
                Spacer()
                
                Text(listing.user.lastActive)
                    .font(.caption)
                    .foregroundColor(Color(hex: "48bb78"))
                    .fontWeight(.medium)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                detailRow(label: localizationManager.localize("MEMBER_SINCE_COLON"), value: formatDate(listing.user.joinedDate))
                detailRow(label: localizationManager.localize("RESPONSE_TIME_COLON"), value: listing.user.responseTime)
                detailRow(label: localizationManager.localize("LANGUAGES_COLON"), value: listing.user.languages.joined(separator: ", "))
                detailRow(label: localizationManager.localize("MEETING_PREFERENCE_COLON"), value: listing.meetingPreference == "public" ? localizationManager.localize("PUBLIC_PLACES_ONLY_RECOMMENDED") : localizationManager.localize("FLEXIBLE_MEETING_LOCATIONS"))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color(hex: "718096"))
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color(hex: "4a5568"))
        }
    }
    
    // MARK: - Contact Status
    
    private func contactStatusView(_ listing: ListingDetails) -> some View {
        let statusIcon = hasActiveContact ? "✅" : "💰"
        let statusTitle = hasActiveContact ? localizationManager.localize("CONTACT_ACCESS_ACTIVE") : localizationManager.localize("CONTACT_ACCESS_REQUIRED")
        let statusMessage = hasActiveContact 
            ? localizationManager.localize("CAN_COMMUNICATE_DIRECTLY").replacingOccurrences(of: "[TRADER_NAME]", with: "\(listing.user.firstName) \(listing.user.lastName ?? "")")
            : localizationManager.localize("PAY_TO_CONTACT").replacingOccurrences(of: "[TRADER_NAME]", with: listing.user.firstName)
        let backgroundColor = hasActiveContact ? Color(hex: "f0fff4") : Color(hex: "fffaf0")
        let borderColor = hasActiveContact ? Color(hex: "48bb78") : Color(hex: "ed8936")
        
        return HStack(spacing: 12) {
            Text(statusIcon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.headline)
                    .foregroundColor(Color(hex: "2d3748"))
                
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "718096"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
        )
        .cornerRadius(12)
    }
    

    
    // MARK: - Unlock Contact View
    
    private func unlockContactView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localize("UNLOCK_FULL_CONTACT"))
                .font(.headline)
                .foregroundColor(Color(hex: "2d3748"))
            
            Text(localizationManager.localize("PAY_ONCE_FULL_ACCESS"))
                .font(.subheadline)
                .foregroundColor(Color(hex: "718096"))
            
            // Pricing Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(localizationManager.localize("CONTACT_ACCESS_TITLE"))
                        .font(.headline)
                        .foregroundColor(Color(hex: "2d3748"))
                    Spacer()
                    Text("$" + String(format: "%.2f", contactFee?.price ?? 2.00))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "667eea"))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(contactFee?.features ?? [
                        localizationManager.localize("FEATURE_DIRECT_CONTACT"),
                        localizationManager.localize("FEATURE_EXCHANGE_COORDINATION"),
                        localizationManager.localize("FEATURE_PLATFORM_PROTECTION"),
                        localizationManager.localize("FEATURE_DISPUTE_RESOLUTION")
                    ], id: \.self) { feature in
                        HStack(spacing: 8) {
                            Text("✓")
                                .foregroundColor(Color(hex: "48bb78"))
                            Text(feature)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "4a5568"))
                        }
                    }
                }
            }
            .padding()
            .background(Color(hex: "f7fafc"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "667eea"), lineWidth: 2)
            )
            .cornerRadius(12)
            
            // Payment Section
            VStack(spacing: 12) {
                Text(localizationManager.localize("SECURE_PAYMENT_PROCESSING"))
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "718096"))
                    .multilineTextAlignment(.center)
                
                Button(action: purchaseContact) {
                    HStack(spacing: 12) {
                        if isProcessingPayment {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text(localizationManager.localize("PROCESSING_PAYMENT"))
                        } else {
                            Image(systemName: "creditcard.fill")
                            Text(localizationManager.localize("PAY_WITH_PAYPAL").replacingOccurrences(of: "[PRICE]", with: String(format: "%.2f", contactFee?.price ?? 2.00)))
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isProcessingPayment ? Color(hex: "005ea6") : Color(hex: "0070ba"))
                    .cornerRadius(8)
                }
                .disabled(isProcessingPayment)
                
                Text(localizationManager.localize("PAYMENT_SECURE"))
                    .font(.caption)
                    .foregroundColor(Color(hex: "718096"))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Safety Tips
    
    private var safetyTipsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localize("SAFETY_TIPS"))
                .font(.headline)
                .foregroundColor(Color(hex: "2d3748"))
            
            VStack(alignment: .leading, spacing: 8) {
                safetyTipRow(localizationManager.localize("SAFETY_TIP_1"))
                safetyTipRow(localizationManager.localize("SAFETY_TIP_2"))
                safetyTipRow(localizationManager.localize("SAFETY_TIP_3"))
                safetyTipRow(localizationManager.localize("SAFETY_TIP_4"))
                safetyTipRow(localizationManager.localize("SAFETY_TIP_5"))
            }
        }
        .padding()
        .background(Color(hex: "fffaf0"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "f6ad55"), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    private func safetyTipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("⚠️")
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color(hex: "744210"))
        }
    }
    
    // MARK: - Report Modal
    
    private func reportModalView() -> some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text(localizationManager.localize("HELP_KEEP_PLATFORM_SAFE"))
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "718096"))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localize("REASON_FOR_REPORTING_COLON"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Picker("Report Reason", selection: $reportReason) {
                        Text(localizationManager.localize("SELECT_A_REASON")).tag("")
                        ForEach(getReportReasons(), id: \.value) { reason in
                            Text(reason.label).tag(reason.value)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color(hex: "f7fafc"))
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localize("ADDITIONAL_DETAILS_OPTIONAL_COLON"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    TextEditor(text: $reportDescription)
                        .frame(height: 100)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
                        )
                        .onTapGesture { }
                        .simultaneousGesture(TapGesture().onEnded { })
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { showReportModal = false }) {
                        Text(localizationManager.localize("CANCEL"))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "4a5568"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "e2e8f0"))
                            .cornerRadius(8)
                    }
                    
                    Button(action: submitReport) {
                        Text(localizationManager.localize("SUBMIT_REPORT"))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(reportReason.isEmpty ? Color(hex: "cbd5e0") : Color(hex: "e53e3e"))
                            .cornerRadius(8)
                    }
                    .disabled(reportReason.isEmpty)
                }
            }
            .padding()
            .navigationTitle(localizationManager.localize("REPORT_LISTING"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - API Functions
    
    private func loadContactDetails() {
        guard let sessionId = SessionManager.shared.sessionId else {
            loadError = localizationManager.localize("SESSION_EXPIRED_LOGIN_AGAIN")
            isLoading = false
            return
        }
        
        isLoading = true
        loadError = nil
        
        // Request location permission
        locationManager.requestLocation()
        
        // Get contact details
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Contact/GetContactDetails")!
        var queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: listingId)
        ]
        
        if let location = locationManager.location {
            queryItems.append(URLQueryItem(name: "userLat", value: String(location.coordinate.latitude)))
            queryItems.append(URLQueryItem(name: "userLng", value: String(location.coordinate.longitude)))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            DispatchQueue.main.async {
                self.loadError = self.localizationManager.localize("INVALID_URL")
                self.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.loadError = self.localizationManager.localize("FAILED_LOAD_CONTACT_INFO")
                    self.isLoading = false
                }
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    self.loadError = self.localizationManager.localize("FAILED_PARSE_RESPONSE")
                    self.isLoading = false
                }
                return
            }
            
            if let success = json["success"] as? Bool, success,
               let listingData = json["listing"] as? [String: Any] {
                
                DispatchQueue.main.async {
                    self.listing = self.parseListingDetails(listingData)
                    
                    if let feeData = json["contact_fee"] as? [String: Any] {
                        self.contactFee = self.parseContactFee(feeData)
                    }
                    
                    // Check access
                    self.checkContactAccess()
                }
            } else {
                DispatchQueue.main.async {
                    self.loadError = (json["error"] as? String) ?? "Failed to load listing details"
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    private func checkContactAccess() {
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Contact/CheckContactAccess")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: listingId)
        ]
        
        guard let url = components.url else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success,
               let hasAccess = json["has_access"] as? Bool {
                
                DispatchQueue.main.async {
                    self.hasActiveContact = hasAccess
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    private func purchaseContact() {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("[ContactPurchase] No session ID available")
            return
        }
        
        isProcessingPayment = true
        print("[ContactPurchase] Starting payment process for listing: \(listingId)")
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Contact/PurchaseContactAccess")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: listingId),
            URLQueryItem(name: "paymentMethod", value: "paypal")
        ]
        
        guard let url = components.url else {
            print("[ContactPurchase] Invalid URL")
            DispatchQueue.main.async {
                self.isProcessingPayment = false
            }
            return
        }
        
        print("[ContactPurchase] Request URL: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("[ContactPurchase] Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isProcessingPayment = false
                    // TODO: Show error alert
                }
                return
            }
            
            guard let data = data else {
                print("[ContactPurchase] No data received")
                DispatchQueue.main.async {
                    self.isProcessingPayment = false
                    // TODO: Show error alert
                }
                return
            }
            
            print("[ContactPurchase] Response data: \(String(data: data, encoding: .utf8) ?? "invalid")")
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("[ContactPurchase] Parsed JSON: \(json)")
                
                if let success = json["success"] as? Bool, success {
                    print("[ContactPurchase] Payment successful!")
                    DispatchQueue.main.async {
                        self.isProcessingPayment = false
                        self.hasActiveContact = true
                        // TODO: Show success message
                    }
                } else {
                    let errorMsg = json["error"] as? String ?? "Payment failed"
                    print("[ContactPurchase] Payment failed: \(errorMsg)")
                    DispatchQueue.main.async {
                        self.isProcessingPayment = false
                        // TODO: Show error: errorMsg
                    }
                }
            } else {
                print("[ContactPurchase] Failed to parse JSON response")
                DispatchQueue.main.async {
                    self.isProcessingPayment = false
                    // TODO: Show error
                }
            }
        }.resume()
    }
    
    private func submitReport() {
        guard !reportReason.isEmpty else { return }
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Contact/ReportListing")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: listingId),
            URLQueryItem(name: "reason", value: reportReason),
            URLQueryItem(name: "description", value: reportDescription)
        ]
        
        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                
                DispatchQueue.main.async {
                    self.showReportModal = false
                    self.reportReason = ""
                    self.reportDescription = ""
                    // Show success alert
                }
            }
        }.resume()
    }
    
    // MARK: - Helper Functions
    
    private func parseListingDetails(_ data: [String: Any]) -> ListingDetails {
        let userData = data["user"] as? [String: Any] ?? [:]
        
        return ListingDetails(
            currency: data["currency"] as? String ?? "",
            amount: data["amount"] as? Double ?? 0,
            rate: data["rate"] as? String ?? "market",
            customRate: data["custom_rate"] as? Double ?? 0,
            location: data["location"] as? String ?? "",
            locationRadius: data["location_radius"] as? Int ?? 5,
            meetingPreference: data["meeting_preference"] as? String ?? "public",
            willRoundToNearestDollar: data["will_round_to_nearest_dollar"] as? Bool,
            user: TraderUserInfo(
                firstName: userData["first_name"] as? String ?? "",
                lastName: userData["last_name"] as? String,
                verified: userData["verified"] as? Bool ?? false,
                rating: userData["rating"] as? Double ?? 0,
                trades: userData["trades"] as? Int ?? 0,
                lastActive: userData["last_active"] as? String ?? "",
                joinedDate: userData["joined_date"] as? String ?? "",
                responseTime: userData["response_time"] as? String ?? "",
                languages: userData["languages"] as? [String] ?? ["English"]
            )
        )
    }
    
    private func parseContactFee(_ data: [String: Any]) -> ContactFee {
        ContactFee(
            price: data["price"] as? Double ?? 2.00,
            currency: data["currency"] as? String ?? "USD",
            features: data["features"] as? [String] ?? []
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
    
    private func getReportReasons() -> [ReportReason] {
        return [
            ReportReason(value: "scam", label: localizationManager.localize("REPORT_SCAM_OR_FRAUD")),
            ReportReason(value: "fake", label: localizationManager.localize("REPORT_FAKE_LISTING")),
            ReportReason(value: "inappropriate", label: localizationManager.localize("REPORT_INAPPROPRIATE_CONTENT")),
            ReportReason(value: "spam", label: localizationManager.localize("REPORT_SPAM")),
            ReportReason(value: "other", label: localizationManager.localize("REPORT_OTHER"))
        ]
    }
}

// MARK: - Data Models

struct ListingDetails {
    let currency: String
    let amount: Double
    let rate: String
    let customRate: Double
    let location: String
    let locationRadius: Int
    let meetingPreference: String
    let willRoundToNearestDollar: Bool?
    let user: TraderUserInfo
}

struct TraderUserInfo {
    let firstName: String
    let lastName: String?
    let verified: Bool
    let rating: Double
    let trades: Int
    let lastActive: String
    let joinedDate: String
    let responseTime: String
    let languages: [String]
}

struct ContactFee {
    let price: Double
    let currency: String
    let features: [String]
}

struct ReportReason {
    let value: String
    let label: String
}

// MARK: - Helper Extension for Flag Images
extension ContactPurchaseView {
    func currencyFlagImage(_ currencyCode: String) -> some View {
        Group {
            if let uiImage = UIImage(named: currencyCode.lowercased()) {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                // Fallback placeholder when flag image is missing
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "e2e8f0"))
                    
                    VStack(spacing: 2) {
                        Text(currencyCode)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color(hex: "4a5568"))
                    }
                }
            }
        }
    }
}

// LocationManager is defined in SharedModels.swift
// Extensions are in SharedModels.swift
