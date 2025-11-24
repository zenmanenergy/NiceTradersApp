//
//  DashboardView.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import SwiftUI

struct DashboardView: View {
    @State private var user: DashboardUserInfo = DashboardUserInfo(name: "Loading...", rating: 0, totalExchanges: 0, joinDate: "Loading...")
    @State private var myListings: [Listing] = []
    @State private var allActiveExchanges: [ActiveExchange] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var navigateToCreateListing = false
    @State private var navigateToSearch = false
    @State private var navigateToProfile = false
    @State private var navigateToMessages = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(error: error) {
                    loadDashboardData()
                }
            } else {
                MainDashboardView(
                    user: user,
                    myListings: myListings,
                    allActiveExchanges: allActiveExchanges,
                    navigateToCreateListing: $navigateToCreateListing,
                    navigateToSearch: $navigateToSearch,
                    navigateToProfile: $navigateToProfile,
                    navigateToMessages: $navigateToMessages,
                    onRefresh: loadDashboardData
                )
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToCreateListing) {
            CreateListingView(navigateToCreateListing: $navigateToCreateListing)
        }
        .navigationDestination(isPresented: $navigateToProfile) {
            ProfileView()
        }
        .navigationDestination(isPresented: $navigateToSearch) {
            SearchView(navigateToSearch: $navigateToSearch)
        }
        .navigationDestination(isPresented: $navigateToMessages) {
            MessagesView(navigateToMessages: $navigateToMessages)
        }
        .onAppear {
            verifySessionAndLoadData()
            setupNavigationListeners()
        }
        .onDisappear {
            removeNavigationListeners()
        }
    }
    
    func setupNavigationListeners() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToSearch"), object: nil, queue: .main) { _ in
            navigateToSearch = true
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToCreateListing"), object: nil, queue: .main) { _ in
            navigateToCreateListing = true
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToMessages"), object: nil, queue: .main) { _ in
            navigateToMessages = true
        }
    }
    
    func removeNavigationListeners() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToSearch"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToCreateListing"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToMessages"), object: nil)
    }
    
    func verifySessionAndLoadData() {
        guard let sessionId = UserDefaults.standard.string(forKey: "SessionId") else {
            // No session, should navigate to login
            return
        }
        
        // Verify session first
        verifySession(sessionId: sessionId) { isValid in
            if isValid {
                loadDashboardData()
            } else {
                // Session invalid, clear and show error
                UserDefaults.standard.removeObject(forKey: "SessionId")
                UserDefaults.standard.removeObject(forKey: "UserType")
                error = "Session expired. Please log in again."
            }
        }
    }
    
    func verifySession(sessionId: String, completion: @escaping (Bool) -> Void) {
        let urlString = "\(Settings.shared.baseURL)/Login/Verify?SessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let _ = json["SessionId"] as? String,
                      let _ = json["UserType"] as? String else {
                    completion(false)
                    return
                }
                completion(true)
            }
        }.resume()
    }
    
    func loadDashboardData() {
        guard let sessionId = UserDefaults.standard.string(forKey: "SessionId") else {
            error = "No session found"
            isLoading = false
            return
        }
        
        isLoading = true
        error = nil
        
        // Get dashboard summary
        getDashboardSummary(sessionId: sessionId) { response in
            print("[Dashboard] Full response: \(response)")
            
            if let dashboardData = response["data"] as? [String: Any],
               let userData = dashboardData["user"] as? [String: Any] {
                
                print("[Dashboard] Found dashboard data")
                print("[Dashboard] User data: \(userData)")
                
                let firstName = userData["firstName"] as? String ?? ""
                let lastName = userData["lastName"] as? String ?? ""
                let dateCreated = userData["dateCreated"] as? String ?? ""
                
                user = DashboardUserInfo(
                    name: "\(firstName) \(lastName)",
                    rating: 0,
                    totalExchanges: 0,
                    joinDate: formatJoinDate(dateCreated)
                )
                
                // Process listings
                if let recentListings = dashboardData["recentListings"] as? [[String: Any]] {
                    print("[Dashboard] Found \(recentListings.count) listings in response")
                    print("[Dashboard] Listings data: \(recentListings)")
                    
                    myListings = recentListings.compactMap { listingDict -> Listing? in
                        print("[Dashboard] Processing listing: \(listingDict)")
                        
                        guard let listingId = listingDict["listingId"] as? String,
                              let currency = listingDict["currency"] as? String,
                              let acceptCurrency = listingDict["acceptCurrency"] as? String,
                              let location = listingDict["location"] as? String,
                              let status = listingDict["status"] as? String else {
                            print("[Dashboard] Failed to parse listing - missing required fields")
                            return nil
                        }
                        
                        // Handle amount as either Int or Double
                        let amount: Double
                        if let amountInt = listingDict["amount"] as? Int {
                            amount = Double(amountInt)
                        } else if let amountDouble = listingDict["amount"] as? Double {
                            amount = amountDouble
                        } else {
                            print("[Dashboard] Failed to parse amount: \(String(describing: listingDict["amount"]))")
                            return nil
                        }
                        
                        return Listing(
                            id: listingId,
                            haveCurrency: currency,
                            haveAmount: amount,
                            wantCurrency: acceptCurrency,
                            wantAmount: 0,
                            location: location,
                            radius: 5,
                            status: status,
                            createdDate: listingDict["createdAt"] as? String ?? "",
                            expiresDate: listingDict["availableUntil"] as? String ?? "",
                            viewCount: 0,
                            contactCount: 0
                        )
                    }
                    
                    print("[Dashboard] Successfully parsed \(myListings.count) listings")
                } else {
                    print("[Dashboard] No recentListings found in dashboard data")
                }
            } else {
                print("[Dashboard] Failed to find data or user in response")
            }
            
            isLoading = false
        }
        
        // Get purchased contacts
        getPurchasedContacts(sessionId: sessionId) { contacts in
            // Process contacts
        }
        
        // Get listing purchases
        getListingPurchases(sessionId: sessionId) { purchases in
            // Process purchases
        }
    }
    
    func getDashboardSummary(sessionId: String, completion: @escaping ([String: Any]) -> Void) {
        let urlString = "\(Settings.shared.baseURL)/Dashboard/GetUserDashboard?SessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            completion([:])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    completion([:])
                    return
                }
                completion(json)
            }
        }.resume()
    }
    
    func getPurchasedContacts(sessionId: String, completion: @escaping ([[String: Any]]) -> Void) {
        let urlString = "\(Settings.shared.baseURL)/Contact/GetPurchasedContacts?sessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let contacts = json["purchased_contacts"] as? [[String: Any]] else {
                    completion([])
                    return
                }
                completion(contacts)
            }
        }.resume()
    }
    
    func getListingPurchases(sessionId: String, completion: @escaping ([[String: Any]]) -> Void) {
        let urlString = "\(Settings.shared.baseURL)/Contact/GetListingPurchases?sessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let purchases = json["listing_purchases"] as? [[String: Any]] else {
                    completion([])
                    return
                }
                completion(purchases)
            }
        }.resume()
    }
    
    func formatJoinDate(_ dateString: String) -> String {
        // Simple date formatting
        return "Member since 2025"
    }
}

// MARK: - Supporting Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your dashboard...")
                .foregroundColor(.gray)
        }
    }
}

struct ErrorView: View {
    let error: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Error Loading Dashboard")
                .font(.headline)
                .foregroundColor(.red)
            Text(error)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry", action: retry)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color(red: 0.4, green: 0.49, blue: 0.92))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
    }
}

struct MainDashboardView: View {
    let user: DashboardUserInfo
    let myListings: [Listing]
    let allActiveExchanges: [ActiveExchange]
    @Binding var navigateToCreateListing: Bool
    @Binding var navigateToSearch: Bool
    @Binding var navigateToProfile: Bool
    @Binding var navigateToMessages: Bool
    var onRefresh: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            DashboardHeader(user: user, navigateToProfile: $navigateToProfile, navigateToMessages: $navigateToMessages)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Actions
                    QuickActionsSection(
                        navigateToCreateListing: $navigateToCreateListing,
                        navigateToSearch: $navigateToSearch,
                        navigateToMessages: $navigateToMessages
                    )
                    .padding(.horizontal)
                    .padding(.top, 24)
                    
                    // Active Exchanges
                    ActiveExchangesSection(exchanges: allActiveExchanges)
                        .padding(.horizontal)
                    
                    // My Listings
                    MyListingsSection(listings: myListings, navigateToCreateListing: $navigateToCreateListing, onRefresh: onRefresh)
                        .padding(.horizontal)
                    
                    Spacer(minLength: 80)
                }
                .refreshable {
                    onRefresh?()
                }
            }
            
            // Bottom Navigation
            BottomNavigation(activeTab: "home")
        }
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
    }
}

struct DashboardHeader: View {
    let user: DashboardUserInfo
    @Binding var navigateToProfile: Bool
    @Binding var navigateToMessages: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(user.initials)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome, \(user.firstName)")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Text("⭐ \(user.rating, specifier: "%.1f")")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("\(user.totalExchanges) exchanges")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            
            Spacer()
            
            Button(action: { navigateToProfile = true }) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct QuickActionsSection: View {
    @Binding var navigateToCreateListing: Bool
    @Binding var navigateToSearch: Bool
    @Binding var navigateToMessages: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "💰",
                    text: "List Currency",
                    isPrimary: true,
                    action: { navigateToCreateListing = true }
                )
                
                QuickActionButton(
                    icon: "🔍",
                    text: "Search",
                    action: { navigateToSearch = true }
                )
                
                QuickActionButton(
                    icon: "💬",
                    text: "Messages",
                    action: { navigateToMessages = true }
                )
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let text: String
    var isPrimary: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 24))
                
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isPrimary ? .white : Color(red: 0.29, green: 0.33, blue: 0.38))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isPrimary ?
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(colors: [.white, .white], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPrimary ? Color.clear : Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 2)
            )
            .shadow(color: isPrimary ? Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.3) : Color.clear, radius: 8, y: 4)
        }
    }
}

struct ActiveExchangesSection: View {
    let exchanges: [ActiveExchange]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🤝 All Active Exchanges (\(exchanges.count))")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("PRIORITY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
            
            if exchanges.isEmpty {
                Text("No active exchanges yet")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .padding()
            } else {
                ForEach(exchanges) { exchange in
                    ActiveExchangeCard(exchange: exchange)
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
}

struct EmptyStateView: View {
    @Binding var showSearch: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("💱")
                .font(.system(size: 60))
            
            Text("No Active Exchanges Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text("Browse listings and purchase contact access to start exchanging currencies")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            Button("Browse Listings") {
                showSearch = true
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.2))
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .cornerRadius(25)
        }
        .padding(.vertical, 32)
    }
}

struct ActiveExchangeCard: View {
    let exchange: ActiveExchange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(exchange.currencyFrom) → \(exchange.currencyTo)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("$\(exchange.amount, specifier: "%.0f")")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
            }
            
            Text(exchange.traderName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            Text(exchange.location)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            HStack {
                Text(exchange.type == .buyer ? "Buying from" : "Selling to")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text("💬 Start conversation")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(15)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MyListingsSection: View {
    let listings: [Listing]
    @Binding var navigateToCreateListing: Bool
    var onRefresh: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Active Listings (\(listings.count))")
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
            
            if listings.isEmpty {
                EmptyListingsView(navigateToCreateListing: $navigateToCreateListing)
            } else {
                ForEach(listings) { listing in
                    ListingCard(listing: listing, onDelete: {
                        onRefresh?()
                    })
                }
            }
        }
    }
}

struct EmptyListingsView: View {
    @Binding var navigateToCreateListing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📝")
                .font(.system(size: 48))
            
            Text("No active listings yet")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Button("Create Your First Listing") {
                navigateToCreateListing = true
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(red: 0.4, green: 0.49, blue: 0.92))
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 2)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
        )
    }
}

struct ListingCard: View {
    let listing: Listing
    @State private var showEditListing = false
    var onDelete: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("\(listing.haveAmount, specifier: "%.0f") \(listing.haveCurrency)")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("→")
                        .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                    
                    Text(listing.wantCurrency)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Spacer()
                
                Text("ACTIVE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(12)
            }
            
            HStack(spacing: 16) {
                Label("\(listing.viewCount)", systemImage: "eye.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Label("\(listing.contactCount)", systemImage: "message.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Label("\(listing.radius)mi", systemImage: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(red: 0.97, green: 0.98, blue: 0.99))
            .cornerRadius(8)
            
            Button(action: {
                showEditListing = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Listing")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 0.4, green: 0.49, blue: 0.92))
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        .sheet(isPresented: $showEditListing) {
            NavigationView {
                EditListingView(listingId: listing.id)
            }
            .onDisappear {
                onDelete?()
            }
        }
    }
}

// MARK: - Data Models

struct DashboardUserInfo {
    let name: String
    let rating: Double
    let totalExchanges: Int
    let joinDate: String
    
    var initials: String {
        name.split(separator: " ").compactMap { $0.first }.map(String.init).joined()
    }
    
    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}

struct Listing: Identifiable, Hashable {
    let id: String
    let haveCurrency: String
    let haveAmount: Double
    let wantCurrency: String
    let wantAmount: Double
    let location: String
    let radius: Int
    let status: String
    let createdDate: String
    let expiresDate: String
    let viewCount: Int
    let contactCount: Int
}

struct ActiveExchange: Identifiable {
    let id = UUID()
    let currencyFrom: String
    let currencyTo: String
    let amount: Double
    let traderName: String
    let location: String
    let type: ExchangeType
    
    enum ExchangeType {
        case buyer, seller
    }
}

// MARK: - Bottom Navigation is in BottomNavigation.swift

#Preview {
    DashboardView()
}
