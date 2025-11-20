//
//  SearchView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/20/25.
//

import SwiftUI

struct SearchListing: Identifiable, Codable {
    let id: Int
    let listingId: Int
    let currency: String
    let amount: Double
    let acceptCurrency: String
    let location: String?
    let meetingPreference: String
    let availableUntil: String?
    let status: String
    let createdAt: String?
    let user: ListingUser
    
    struct ListingUser: Codable {
        let firstName: String
        let lastName: String
        let rating: Double?
        let trades: Int?
        let verified: Bool?
    }
}

struct SearchFilters: Codable {
    var currency: String
    var amountMin: String
    var amountMax: String
    var rateType: String
    var meetingPreference: String
    var verifiedOnly: Bool
    
    init() {
        currency = ""
        amountMin = ""
        amountMax = ""
        rateType = "any"
        meetingPreference = "any"
        verifiedOnly = false
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
    @Binding var showSearch: Bool
    @State private var availableCurrencies: [String] = []
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
            
            ScrollView {
                VStack(spacing: 0) {
                    // Quick Search
                    quickSearchSection
                    
                    // Advanced Filters
                    if showFilters {
                        filtersPanel
                    }
                    
                    // Results Section
                    resultsSection
                }
            }
            .background(Color(hex: "f8fafc"))
        }
        .navigationBarHidden(true)
        .onAppear {
            loadInitialData()
        }
    }
    
    // MARK: - Header View
    var headerView: some View {
        HStack {
            Button(action: {
                showSearch = false
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Text("Search Currency")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    showFilters.toggle()
                }
            }) {
                Image(systemName: "slider.horizontal.3")
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Search Currency")
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(hex: "a0aec0"))
                    
                    TextField("Search currencies...", text: $currencySearchQuery)
                        .font(.system(size: 16))
                        .onTapGesture {
                            showCurrencyDropdown = true
                        }
                        .onChange(of: currencySearchQuery) {
                            showCurrencyDropdown = true
                        }
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(showCurrencyDropdown ? Color(hex: "667eea") : Color(hex: "e2e8f0"), lineWidth: 2)
                )
                
                if showCurrencyDropdown && !loadingFilters {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(filteredCurrencies, id: \.self) { currency in
                                Button(action: {
                                    selectCurrency(currency)
                                }) {
                                    HStack {
                                        Text(currency)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(searchFilters.currency == currency ? Color(hex: "667eea") : Color(hex: "2d3748"))
                                        
                                        Spacer()
                                        
                                        if searchFilters.currency == currency {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(Color(hex: "667eea"))
                                        }
                                    }
                                    .padding(16)
                                    .background(searchFilters.currency == currency ? Color(hex: "edf2f7") : Color.white)
                                }
                                
                                if currency != filteredCurrencies.last {
                                    Divider()
                                }
                            }
                            
                            if filteredCurrencies.isEmpty {
                                Text("No currencies found")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "a0aec0"))
                                    .padding(16)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
                }
            }
            
            if !searchFilters.currency.isEmpty {
                HStack {
                    HStack(spacing: 12) {
                        Text(getCurrencyFlag(searchFilters.currency))
                            .font(.system(size: 20))
                        
                        Text("Searching for \(searchFilters.currency)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "667eea"))
                    }
                    
                    Spacer()
                    
                    Button(action: clearCurrencySelection) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "667eea"))
                            .frame(width: 24, height: 24)
                            .background(Color(hex: "667eea").opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                .padding(16)
                .background(Color(hex: "edf2f7"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "667eea"), lineWidth: 2)
                )
            }
        }
        .padding(24)
        .background(Color.white)
    }
    
    // MARK: - Filters Panel
    var filtersPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Search Filters")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Spacer()
                
                Button(action: clearFilters) {
                    Text("Clear All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "667eea"))
                        .underline()
                }
            }
            
            VStack(spacing: 16) {
                // Currency Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Currency")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    Picker("Currency", selection: $searchFilters.currency) {
                        Text("Any Currency").tag("")
                        ForEach(availableCurrencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                    .disabled(loadingFilters)
                }
                
                // Amount Range
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount Range")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    HStack(spacing: 12) {
                        TextField("Min", text: $searchFilters.amountMin)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                            )
                        
                        Text("to")
                            .foregroundColor(Color(hex: "718096"))
                        
                        TextField("Max", text: $searchFilters.amountMax)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                            )
                    }
                }
                
                // Rate Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate Type")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    Picker("Rate Type", selection: $searchFilters.rateType) {
                        Text("Any Rate").tag("any")
                        Text("Market Rate").tag("market")
                        Text("Custom Rate").tag("custom")
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                }
                
                // Meeting Preference
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meeting Type")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    Picker("Meeting Type", selection: $searchFilters.meetingPreference) {
                        Text("Any Location").tag("any")
                        Text("Public Places Only").tag("public")
                        Text("Flexible Locations").tag("flexible")
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                    )
                }
                
                // Verified Only
                HStack {
                    Toggle("Verified traders only", isOn: $searchFilters.verifiedOnly)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "4a5568"))
                        .tint(Color(hex: "667eea"))
                }
                .padding(16)
                .background(Color(hex: "f7fafc"))
                .cornerRadius(8)
            }
            
            Button(action: {
                performSearch(resetPagination: true)
                withAnimation {
                    showFilters = false
                }
            }) {
                Text("Apply Filters")
                    .font(.system(size: 16, weight: .semibold))
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
        }
        .padding(24)
        .background(Color.white)
        .transition(.move(edge: .top).combined(with: .opacity))
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
                    Button(action: {
                        performSearch(resetPagination: true)
                    }) {
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
            return "Searching..."
        } else if hasSearched {
            return "\(searchResults.count) Results Found"
        } else {
            return "Recent Listings"
        }
    }
    
    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Searching for currency listings...")
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
            
            Text("Search Error")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            Text(error)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "718096"))
                .multilineTextAlignment(.center)
            
            Button(action: {
                performSearch(resetPagination: true)
            }) {
                Text("Try Again")
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
            
            Text("No listings found")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            Text("Try adjusting your search filters or check back later for new listings.")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "718096"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Button(action: clearFilters) {
                Text("Clear Filters")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "667eea"))
                    .cornerRadius(8)
            }
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
                    Text("\(Int(listing.amount)) \(listing.currency)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Text("Wants \(listing.acceptCurrency)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "667eea"))
                }
                
                Spacer()
                
                Text(listing.status.capitalized)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "48bb78"))
            }
            
            // Trader Info
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("\(listing.user.firstName) \(listing.user.lastName)")
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
                    Text("Meeting:")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "718096"))
                    
                    Spacer()
                    
                    Text(listing.meetingPreference == "public" ? "Public places" : 
                         listing.meetingPreference == "private" ? "Private" : "Flexible")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "4a5568"))
                }
                
                HStack {
                    Text("Available until:")
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
                
                NavigationLink(destination: Text("Contact Trader")) {
                    Text("Contact Trader")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
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
    func selectCurrency(_ currency: String) {
        searchFilters.currency = currency
        currencySearchQuery = ""
        showCurrencyDropdown = false
        performSearch(resetPagination: true)
    }
    
    func clearCurrencySelection() {
        searchFilters.currency = ""
        currencySearchQuery = ""
        performSearch(resetPagination: true)
    }
    
    func clearFilters() {
        searchFilters = SearchFilters()
        if hasSearched {
            performSearch(resetPagination: true)
        }
    }
    
    func performSearch(resetPagination: Bool) {
        isSearching = true
        hasSearched = true
        searchError = nil
        
        if resetPagination {
            pagination.offset = 0
        }
        
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
        
        if !searchFilters.currency.isEmpty {
            queryItems.append(URLQueryItem(name: "currency", value: searchFilters.currency))
        }
        if !searchFilters.amountMin.isEmpty {
            queryItems.append(URLQueryItem(name: "minAmount", value: searchFilters.amountMin))
        }
        if !searchFilters.amountMax.isEmpty {
            queryItems.append(URLQueryItem(name: "maxAmount", value: searchFilters.amountMax))
        }
        
        components.queryItems = queryItems
        
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
                    let decoder = JSONDecoder()
                    let listings = listingsData.compactMap { dict -> SearchListing? in
                        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                              let listing = try? decoder.decode(SearchListing.self, from: jsonData) else {
                            return nil
                        }
                        return listing
                    }
                    
                    if resetPagination {
                        searchResults = listings
                    } else {
                        searchResults.append(contentsOf: listings)
                    }
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
        performSearch(resetPagination: false)
    }
    
    func loadInitialData() {
        loadSearchFilters()
        performInitialSearch()
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
                    availableLocations = json["locations"] as? [String] ?? []
                }
            }
        }.resume()
    }
    
    func performInitialSearch() {
        performSearch(resetPagination: true)
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
    SearchView(showSearch: .constant(true))
}
