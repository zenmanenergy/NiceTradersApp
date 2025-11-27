//
//  SearchView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/20/25.
//

import SwiftUI
import CoreLocation

struct SearchFilters: Codable {
    var haveCurrency: String
    var wantCurrency: String
    var maxDistance: String
    
    init() {
        haveCurrency = ""
        wantCurrency = ""
        maxDistance = "5"
    }
}

struct PaginationInfo: Codable {
    var total: Int
    var limit: Int
    var offset: Int
    var hasMore: Bool
    
    init() {
        total = 0
        limit = 20
        offset = 0
        hasMore = false
    }
}

struct SearchView: View {
    @Binding var navigateToSearch: Bool
    @StateObject private var locationManager = LocationManager()
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var availableCurrencies: [String] = []
    @State private var availableAcceptCurrencies: [String] = []
    @State private var availableLocations: [String] = []
    @State private var searchResults: [SearchListing] = []
    @State private var searchFilters = SearchFilters()
    @State private var pagination = PaginationInfo()
    
    @State private var isLoading = true
    @State private var loadingFilters = true
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var searchError: String?
    @State private var showFilters = false
    @State private var currencySearchQuery = ""
    @State private var showCurrencyDropdown = false
    @State private var showMapView = false
    @State private var selectedListing: SearchListing?
    @State private var navigateToCreateListing = false
    @State private var navigateToMessages = false
    
    var filteredCurrencies: [String] {
        if currencySearchQuery.isEmpty {
            return availableCurrencies
        }
        return availableCurrencies.filter { currency in
            currency.lowercased().contains(currencySearchQuery.lowercased())
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            if showMapView {
                // Map View
                ListingMapView(
                    listings: searchResults,
                    userLocation: locationManager.location,
                    showUserLocation: true,
                    selectedListing: $selectedListing
                )
            } else {
                // List View
                ScrollView {
                    VStack(spacing: 0) {
                        // Quick Search
                        quickSearchSection
                        
                        // Results Section
                        resultsSection
                    }
                }
                .background(Color(hex: "f8fafc"))
            }
            
            // Bottom Navigation
            BottomNavigation(activeTab: "search")
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToCreateListing) {
            CreateListingView(navigateToCreateListing: $navigateToCreateListing)
        }
        .navigationDestination(isPresented: $navigateToMessages) {
            MessagesView(navigateToMessages: $navigateToMessages)
        }
        .onAppear {
            loadInitialData()
            locationManager.requestLocation()
            
            // Give location manager a moment to update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let loc = locationManager.location {
                    print("[SearchView] Location ready: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
                } else {
                    print("[SearchView] Location not available yet")
                }
            }
        }
    }
    
    // MARK: - Header View
    var headerView: some View {
        HStack {
            Button(action: {
                navigateToSearch = false
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Text(localizationManager.localize("SEARCH_CURRENCY"))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    showMapView.toggle()
                }
            }) {
                Image(systemName: showMapView ? "list.bullet" : "map")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
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
    }
    
    // MARK: - Quick Search Section
    var quickSearchSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(localizationManager.localize("FIND_CURRENCY_EXCHANGE"))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "2d3748"))
            
            // Question 1: What currency do you have?
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localize("WHAT_CURRENCY_HAVE"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "4a5568"))
                
                Picker("I have", selection: $searchFilters.haveCurrency) {
                    Text(localizationManager.localize("SELECT_CURRENCY")).tag("")
                    ForEach(availableCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                .pickerStyle(.menu)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                )
            }
            
            // Question 2: What currency do you want?
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localize("WHAT_CURRENCY_WANT"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "4a5568"))
                
                Picker("I want", selection: $searchFilters.wantCurrency) {
                    Text(localizationManager.localize("SELECT_CURRENCY")).tag("")
                    ForEach(availableAcceptCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                .pickerStyle(.menu)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                )
            }
            
            // Question 3: How far are you willing to travel?
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localize("HOW_FAR_TRAVEL"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "4a5568"))
                
                Picker("Distance", selection: $searchFilters.maxDistance) {
                    Text(localizationManager.localize("ONE_MILE")).tag("1")
                    Text(localizationManager.localize("FIVE_MILES")).tag("5")
                    Text(localizationManager.localize("TEN_MILES")).tag("10")
                    Text(localizationManager.localize("TWENTY_FIVE_MILES")).tag("25")
                    Text(localizationManager.localize("FIFTY_MILES")).tag("50")
                    Text(localizationManager.localize("ONE_HUNDRED_MILES")).tag("100")
                }
                .pickerStyle(.menu)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                )
            }
            
            // Search Button
            Button(action: performSearch) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text(localizationManager.search)
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    Group {
                        if searchFilters.haveCurrency.isEmpty || searchFilters.wantCurrency.isEmpty {
                            Color.gray.opacity(0.3)
                        } else {
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(searchFilters.haveCurrency.isEmpty || searchFilters.wantCurrency.isEmpty || isSearching)
        }
        .padding(24)
        .background(Color.white)
    }
    
    // MARK: - Results Section
    var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(resultTitle)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Spacer()
                
                if hasSearched && !isSearching {
                    Button(action: performSearch) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "667eea"))
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "667eea").opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            if isSearching {
                loadingView
            } else if let error = searchError {
                errorView(error)
            } else if searchResults.isEmpty && hasSearched {
                noResultsView
            } else {
                listingsGrid
                
                if pagination.hasMore {
                    loadMoreButton
                }
            }
        }
        .padding(24)
    }
    
    var resultTitle: String {
        if isSearching {
            return localizationManager.localize("SEARCHING")
        } else if hasSearched {
            return "\(searchResults.count) " + localizationManager.localize("RESULTS_FOUND")
        } else {
            return localizationManager.localize("RECENT_LISTINGS")
        }
    }
    
    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(localizationManager.localize("SEARCHING_FOR_CURRENCY"))
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "718096"))
        }
        .frame(maxWidth: .infinity)
        .padding(48)
    }
    
    func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Text("⚠️")
                .font(.system(size: 48))
            
            Text(localizationManager.localize("SEARCH_ERROR"))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            Text(error)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "718096"))
                .multilineTextAlignment(.center)
            
            Button(action: performSearch) {
                Text(localizationManager.localize("TRY_AGAIN"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "e53e3e"))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(48)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    var noResultsView: some View {
        VStack(spacing: 16) {
            Text("🔍")
                .font(.system(size: 48))
            
            Text("Try adjusting your search or check back later for new listings.")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "718096"))
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "718096"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
    }
    
    var listingsGrid: some View {
        VStack(spacing: 24) {
            ForEach(searchResults) { listing in
                listingCard(listing)
            }
        }
    }
    
    func listingCard(_ listing: SearchListing) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.localize("WANTS") + " \\(listing.acceptCurrency)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "667eea"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(listing.status.capitalized)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "48bb78"))
                    
                    let distanceStr = listing.approximateDistanceString(from: locationManager.location)
                    if !distanceStr.isEmpty {
                        Text(distanceStr)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "718096"))
                    }
                }
            }
            
            // Trader Info
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(listing.user.firstName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        if listing.user.verified == true {
                            Circle()
                                .fill(Color(hex: "48bb78"))
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text("⭐")
                                .font(.system(size: 13))
                            Text(String(format: "%.1f", listing.user.rating ?? 0))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "f6ad55"))
                        }
                        
                        Text("(\(listing.user.trades ?? 0) trades)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "718096"))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    // View profile action
                }) {
                    Text("👤")
                        .font(.system(size: 18))
                        .frame(width: 40, height: 40)
                        .background(Color(hex: "f7fafc"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
                        )
                }
            }
            .padding(.bottom, 8)
            .overlay(
                Rectangle()
                    .fill(Color(hex: "f1f5f9"))
                    .frame(height: 1),
                alignment: .bottom
            )
            
            // Details
            VStack(spacing: 8) {
                HStack {
                    Text(localizationManager.localize("MEETING"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "718096"))
                    
                    Spacer()
                    
                    Text(listing.meetingPreference == "public" ? "Public places" : 
                         listing.meetingPreference == "private" ? "Private" : "Flexible")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "4a5568"))
                }
                
                HStack {
                    Text(localizationManager.localize("AVAILABLE_UNTIL"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "718096"))
                    
                    Spacer()
                    
                    Text(formatDate(listing.availableUntil ?? ""))
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "4a5568"))
                }
            }
            
            // Footer
            HStack {
                if let createdAt = listing.createdAt {
                    Text(formatDate(createdAt))
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "a0aec0"))
                }
                
                Spacer()
                
                NavigationLink(destination: ContactPurchaseView(listingId: listing.listingId)) {
                    Text("Contact Trader")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "e2e8f0"), lineWidth: 1)
        )
    }
    
    var loadMoreButton: some View {
        Button(action: loadMore) {
            Text(isSearching ? "Loading..." : "Load More (\(pagination.total - searchResults.count) remaining)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color(hex: "4a5568"))
                .cornerRadius(8)
        }
        .disabled(isSearching)
    }
    
    // MARK: - Functions
    func performSearch() {
        isSearching = true
        hasSearched = true
        searchError = nil
        pagination.offset = 0
        
        guard let sessionId = SessionManager.shared.sessionId else {
            isSearching = false
            return
        }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Search/SearchListings")!
        var queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "limit", value: String(pagination.limit)),
            URLQueryItem(name: "offset", value: String(pagination.offset))
        ]
        
        // Add currency filters - Currency is what they have, AcceptCurrency is what they want
        // This finds listings that have what we want and accept what we have
        if !searchFilters.haveCurrency.isEmpty {
            queryItems.append(URLQueryItem(name: "Currency", value: searchFilters.wantCurrency))
        }
        if !searchFilters.wantCurrency.isEmpty {
            queryItems.append(URLQueryItem(name: "AcceptCurrency", value: searchFilters.haveCurrency))
        }
        
        // Add distance filter with user's location
        if !searchFilters.maxDistance.isEmpty {
            queryItems.append(URLQueryItem(name: "MaxDistance", value: searchFilters.maxDistance))
            
            // Add user's current location for distance calculation
            if let location = locationManager.location {
                let lat = location.coordinate.latitude
                let lng = location.coordinate.longitude
                print("[SearchView] Using location: \(lat), \(lng)")
                queryItems.append(URLQueryItem(name: "UserLatitude", value: String(lat)))
                queryItems.append(URLQueryItem(name: "UserLongitude", value: String(lng)))
            } else {
                print("[SearchView] WARNING: No location available for distance search")
            }
        }
        
        components.queryItems = queryItems
        
        print("[SearchView] Search URL: \(components.url?.absoluteString ?? "invalid")")
        
        guard let url = components.url else {
            DispatchQueue.main.async {
                isSearching = false
                searchError = "Invalid URL"
                searchResults = []
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    isSearching = false
                    searchError = "No data received"
                    searchResults = []
                }
                return
            }
            
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool, success else {
                DispatchQueue.main.async {
                    isSearching = false
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        searchError = json["error"] as? String ?? "Failed to search listings"
                    } else {
                        searchError = "Failed to search listings"
                    }
                    searchResults = []
                }
                return
            }
            
            DispatchQueue.main.async {
                isSearching = false
                
                if let listingsData = json["listings"] as? [[String: Any]] {
                    print("[Search] Found \(listingsData.count) listings in response")
                    let decoder = JSONDecoder()
                    let listings = listingsData.compactMap { dict -> SearchListing? in
                        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                              let listing = try? decoder.decode(SearchListing.self, from: jsonData) else {
                            print("[Search] Failed to decode listing: \(dict)")
                            return nil
                        }
                        return listing
                    }
                    
                    print("[Search] Successfully decoded \(listings.count) listings")
                    searchResults = listings
                    hasSearched = true
                } else {
                    print("[Search] No listings array found in response")
                }
                
                if let paginationData = json["pagination"] as? [String: Any] {
                    pagination.total = paginationData["total"] as? Int ?? 0
                    pagination.hasMore = paginationData["hasMore"] as? Bool ?? false
                }
            }
        }.resume()
    }
    
    func loadMore() {
        guard pagination.hasMore && !isSearching else { return }
        pagination.offset += pagination.limit
        performSearch()
    }
    
    func loadInitialData() {
        loadSearchFilters()
    }
    
    func loadSearchFilters() {
        loadingFilters = true
        
        let url = URL(string: "\(Settings.shared.baseURL)/Search/GetSearchFilters")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                loadingFilters = false
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    availableCurrencies = json["currencies"] as? [String] ?? []
                    availableAcceptCurrencies = json["acceptCurrencies"] as? [String] ?? []
                    availableLocations = json["locations"] as? [String] ?? []
                }
            }
        }.resume()
    }
    
    func formatDate(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "Not specified" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        
        return dateString
    }
    
    func getCurrencyFlag(_ code: String) -> String {
        let countryCode = String(code.prefix(2))
        let base: UInt32 = 127397
        var flagString = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            flagString.append(String(UnicodeScalar(base + scalar.value)!))
        }
        return flagString
    }
}

#Preview {
    SearchView(navigateToSearch: .constant(true))
}
