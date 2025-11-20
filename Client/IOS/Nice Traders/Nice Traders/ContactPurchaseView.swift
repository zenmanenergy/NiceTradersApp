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
                    
                    Text("Contact Trader")
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
                        
                        if hasActiveContact {
                            contactDetailsView()
                        } else {
                            unlockContactView()
                        }
                        
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
            Text("Loading contact details...")
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
                Text("Try Again")
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
                    Image(listing.currency.lowercased())
                        .resizable()
                        .frame(width: 32, height: 24)
                        .cornerRadius(4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(listing.amount, specifier: "%.2f") \(listing.currency)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        Text(listing.rate == "market" ? "Market Rate" : "$\(listing.customRate, specifier: "%.4f") per \(listing.currency)")
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
                    
                    Text("Within \(listing.locationRadius) miles")
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
                        Text(listing.user.name)
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
                        
                        Text("\(listing.user.trades) completed trades")
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
                detailRow(label: "Member since:", value: formatDate(listing.user.joinedDate))
                detailRow(label: "Response time:", value: listing.user.responseTime)
                detailRow(label: "Languages:", value: listing.user.languages.joined(separator: ", "))
                detailRow(label: "Meeting preference:", value: listing.meetingPreference == "public" ? "Public places only" : "Flexible locations")
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
        HStack(spacing: 12) {
            Text(hasActiveContact ? "✅" : "💰")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(hasActiveContact ? "Contact Access Active" : "Contact Access Required")
                    .font(.headline)
                    .foregroundColor(Color(hex: "2d3748"))
                
                Group {
                    if hasActiveContact {
                        Text("You can communicate directly with \(listing.user.name) and coordinate your exchange.")
                    } else {
                        Text("Pay $2.00 to contact \(listing.user.name) and coordinate your exchange.")
                    }
                }
                .font(.subheadline)
                .foregroundColor(Color(hex: "718096"))
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(hasActiveContact ? Color(hex: "f0fff4") : Color(hex: "fffaf0"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(hasActiveContact ? Color(hex: "48bb78") : Color(hex: "ed8936"), lineWidth: 2)
        )
        .cornerRadius(12)
    }
    
    // MARK: - Contact Details (if access granted)
    
    private func contactDetailsView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Direct Contact")
                .font(.headline)
                .foregroundColor(Color(hex: "2d3748"))
            
            VStack(spacing: 12) {
                HStack {
                    Text("Phone:")
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "4a5568"))
                    Spacer()
                    Text("+1 (555) 123-4567")
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "2d3748"))
                }
                .padding()
                .background(Color(hex: "f7fafc"))
                .cornerRadius(8)
                
                HStack {
                    Text("Email:")
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "4a5568"))
                    Spacer()
                    Text("sarah.chen@email.com")
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "2d3748"))
                }
                .padding()
                .background(Color(hex: "f7fafc"))
                .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                Button(action: { /* Call action */ }) {
                    Text("📞 Call Now")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "68d391"))
                        .cornerRadius(8)
                }
                
                Button(action: { /* Message action */ }) {
                    Text("💬 Send Message")
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
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Unlock Contact View
    
    private func unlockContactView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Unlock Full Contact")
                .font(.headline)
                .foregroundColor(Color(hex: "2d3748"))
            
            Text("Pay once to get full contact access and coordinate your exchange")
                .font(.subheadline)
                .foregroundColor(Color(hex: "718096"))
            
            // Pricing Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Contact Access")
                        .font(.headline)
                        .foregroundColor(Color(hex: "2d3748"))
                    Spacer()
                    Text("$\(contactFee?.price ?? 2.00, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "667eea"))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(contactFee?.features ?? ["Direct contact with seller", "Exchange coordination", "Platform protection", "Dispute resolution support"], id: \.self) { feature in
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
                Text("Secure payment processing through PayPal. You can pay with your PayPal account or credit card.")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "718096"))
                    .multilineTextAlignment(.center)
                
                Button(action: purchaseContact) {
                    HStack(spacing: 12) {
                        if isProcessingPayment {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Processing Payment...")
                        } else {
                            Image(systemName: "creditcard.fill")
                            Text("Pay $\(contactFee?.price ?? 2.00, specifier: "%.2f") with PayPal")
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
                
                Text("🔒 Your payment information is secure and encrypted. We never store your payment details.")
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
            Text("Safety Tips")
                .font(.headline)
                .foregroundColor(Color(hex: "2d3748"))
            
            VStack(alignment: .leading, spacing: 8) {
                safetyTipRow("Always meet in public places during daylight hours")
                safetyTipRow("Bring a friend or let someone know your plans")
                safetyTipRow("Verify the currency before completing the exchange")
                safetyTipRow("Use NICE Traders' dispute resolution if issues arise")
                safetyTipRow("Never share personal financial information")
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
                Text("Help us keep the platform safe by reporting inappropriate listings.")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "718096"))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason for reporting:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Picker("Report Reason", selection: $reportReason) {
                        Text("Select a reason").tag("")
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
                    Text("Additional details (optional):")
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
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { showReportModal = false }) {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "4a5568"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "e2e8f0"))
                            .cornerRadius(8)
                    }
                    
                    Button(action: submitReport) {
                        Text("Submit Report")
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
            .navigationTitle("Report Listing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - API Functions
    
    private func loadContactDetails() {
        guard let sessionId = SessionManager.shared.sessionId else {
            loadError = "Session expired. Please log in again."
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
                self.loadError = "Invalid URL"
                self.isLoading = false
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.loadError = "Failed to load contact information"
                    self.isLoading = false
                }
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    self.loadError = "Failed to parse response"
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
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        isProcessingPayment = true
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Contact/PurchaseContactAccess")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: listingId),
            URLQueryItem(name: "paymentMethod", value: "paypal")
        ]
        
        guard let url = components.url else {
            DispatchQueue.main.async {
                self.isProcessingPayment = false
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.isProcessingPayment = false
                    // Show error alert
                }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                
                DispatchQueue.main.async {
                    self.isProcessingPayment = false
                    self.hasActiveContact = true
                    // Show success message
                }
            } else {
                DispatchQueue.main.async {
                    self.isProcessingPayment = false
                    // Show error
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
            user: TraderUserInfo(
                name: userData["name"] as? String ?? "",
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
            ReportReason(value: "scam", label: "Scam or fraud"),
            ReportReason(value: "fake", label: "Fake listing"),
            ReportReason(value: "inappropriate", label: "Inappropriate content"),
            ReportReason(value: "spam", label: "Spam"),
            ReportReason(value: "other", label: "Other")
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
    let user: TraderUserInfo
}

struct TraderUserInfo {
    let name: String
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

// LocationManager is defined in SharedModels.swift
// Extensions are in SharedModels.swift
