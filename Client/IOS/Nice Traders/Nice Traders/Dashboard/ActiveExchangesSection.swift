import SwiftUI
import MapKit

struct ActiveExchangesSection: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    let exchanges: [ActiveExchange]
    let purchasedContactsData: [[String: Any]]
    @Binding var selectedContactData: ContactData?
    @Binding var navigateToContact: Bool
    @Binding var navigateToNegotiation: Bool
    @Binding var selectedExchangeId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🤝 \(localizationManager.localize("ALL_ACTIVE_EXCHANGES")) (\(exchanges.count))")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(localizationManager.localize("PRIORITY"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
            
            if exchanges.isEmpty {
                Text(localizationManager.localize("NO_ACTIVE_EXCHANGES"))
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
            } else {
                ForEach(exchanges) { exchange in
                    ActiveExchangeCard(exchange: exchange)
                        .onTapGesture {
                            navigateToExchange(exchange)
                        }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    private func navigateToExchange(_ exchange: ActiveExchange) {
        let listing = ContactListing(
            listingId: exchange.id,
            currency: exchange.currencyFrom,
            amount: exchange.amount,
            acceptCurrency: exchange.currencyTo,
            preferredCurrency: exchange.currencyTo,
            meetingPreference: nil,
            location: exchange.location,
            latitude: exchange.latitude,
            longitude: exchange.longitude,
            radius: exchange.radius,
            willRoundToNearestDollar: exchange.willRoundToNearestDollar
        )
        let otherUser = OtherUser(
            firstName: exchange.traderName,
            lastName: "",
            rating: 0.0,
            totalTrades: 0
        )
        let contactData = ContactData(
            listing: listing,
            otherUser: otherUser,
            lockedAmount: nil,
            exchangeRate: nil,
            fromCurrency: exchange.currencyFrom,
            toCurrency: exchange.currencyTo,
            purchasedAt: nil
        )
        selectedContactData = contactData
        navigateToContact = true
    }
}

struct ActiveExchangeCard: View {
    let exchange: ActiveExchange
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var displayLocation: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(String(format: exchange.willRoundToNearestDollar ? "%.0f" : "%.2f", exchange.amount))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text(exchange.currencyFrom)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("→")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        
                        if let convertedAmount = exchange.convertedAmount {
                            Text(String(format: exchange.willRoundToNearestDollar ? "%.0f" : "%.2f", convertedAmount))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text(exchange.currencyTo)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        } else {
                            Text(exchange.currencyTo)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                
                Spacer()
            }
            
            Text(exchange.traderName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Text(displayLocation.isEmpty ? exchange.location : displayLocation)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .onAppear {
                    geocodeLocation(exchange.location)
                }
            
            getStatusView()
            
            HStack {
                Text("💬 " + localizationManager.localize("START_CONVERSATION"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func getStatusView() -> some View {
        // Debug output
        let _ = {
            print("[DEBUG-getStatusView] Using displayStatus from API: \(exchange.displayStatus ?? "NIL")")
        }()
        
        if let displayStatus = exchange.displayStatus, !displayStatus.isEmpty {
            // Parse meeting time if available
            if let meetingTime = exchange.meetingTime {
                Text(DateFormatters.formatCompact(meetingTime))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Use the status from the API
            Text(displayStatus)
                .font(.system(size: 13))
                .foregroundColor(displayStatus.contains("✅") ? .white : Color(red: 1.0, green: 0.84, blue: 0.0))
                .fontWeight(.semibold)
        } else {
            // Fallback if no displayStatus from API
            Text("📍 Propose time & location")
                .font(.system(size: 13))
                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                .fontWeight(.semibold)
        }
    }
    
    private func geocodeLocation(_ locationString: String) {
        let components = locationString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard components.count == 2,
              let latitude = Double(components[0]),
              let longitude = Double(components[1]) else {
            displayLocation = locationString
            return
        }
        
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let placemark = placemarks?.first {
                    var addressParts: [String] = []
                    if let city = placemark.locality { addressParts.append(city) }
                    if let state = placemark.administrativeArea { addressParts.append(state) }
                    if let country = placemark.country { addressParts.append(country) }
                    
                    displayLocation = !addressParts.isEmpty ? addressParts.joined(separator: ", ") : locationString
                } else {
                    displayLocation = locationString
                }
            }
        }
    }
}
