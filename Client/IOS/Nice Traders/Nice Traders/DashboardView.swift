//
//  DashboardView.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import SwiftUI
import MapKit

// Note: ContactData, ContactListing, and OtherUser types are defined in ContactDetailView.swift
// They should be moved to a shared models file, but for now we reference them here

struct DashboardView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var user: DashboardUserInfo = DashboardUserInfo(name: "Loading...", rating: 0, totalExchanges: 0, joinDate: "Loading...")
    @State private var myListings: [Listing] = []
    @State private var allActiveExchanges: [ActiveExchange] = []
    @State private var purchasedContactsData: [[String: Any]] = [] // Store raw data
    @State private var pendingNegotiations: [PendingNegotiation] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var navigateToCreateListing = false
    @State private var navigateToSearch = false
    @State private var navigateToProfile = false
    @State private var currentRequestToken = UUID() // Track which load request is current
    @State private var navigateToMessages = false
    @State private var navigateToContact = false
    @State private var selectedContactData: ContactData?
    @State private var selectedTab = 0
    
    var body: some View {
        return ZStack {
            if isLoading {
                LoadingView()
            } else if let error = error {
                ErrorView(error: error) {
                    loadDashboardData()
                }
            } else if navigateToContact && selectedContactData != nil {
                // Show ContactDetailView instead of DashboardView - no navigationDestination needed
                ContactDetailView(contactData: selectedContactData!, navigateToContact: $navigateToContact)
            } else {
                MainDashboardView(
                    user: user,
                    myListings: myListings,
                    allActiveExchanges: allActiveExchanges,
                    purchasedContactsData: purchasedContactsData,
                    pendingNegotiations: pendingNegotiations,
                    selectedContactData: $selectedContactData,
                    navigateToContact: $navigateToContact,
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
            print("VIEW: DashboardView - Displaying dashboard")
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
        
        // Handle deep links from push notifications
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToListing"), object: nil, queue: .main) { notification in
            if notification.userInfo?["listingId"] as? String != nil {
                navigateToSearch = true
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToNegotiations"), object: nil, queue: .main) { notification in
            if notification.userInfo?["negotiationId"] as? String != nil {
                // Set selected tab to My Negotiations (usually tab 3 or 4, depending on your structure)
                selectedTab = 3  // Adjust based on your actual tab structure
            }
        }
    }
    
    func removeNavigationListeners() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToSearch"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToCreateListing"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToMessages"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToListing"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToNegotiations"), object: nil)
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
        
        // Generate new token for this load request
        currentRequestToken = UUID()
        let thisRequestToken = currentRequestToken
        
        // Clear existing data to prevent duplicates
        allActiveExchanges = []
        purchasedContactsData = []
        pendingNegotiations = []
        
        // Get dashboard summary
        getDashboardSummary(sessionId: sessionId) { response in
            // Ignore if this response is from an old request
            guard thisRequestToken == self.currentRequestToken else { return }
            
            if let dashboardData = response["data"] as? [String: Any],
               let userData = dashboardData["user"] as? [String: Any] {
                
                
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
                    
                    myListings = recentListings.compactMap { listingDict -> Listing? in
                        
                        guard let listingId = listingDict["listingId"] as? String,
                              let currency = listingDict["currency"] as? String,
                              let acceptCurrency = listingDict["acceptCurrency"] as? String,
                              let location = listingDict["location"] as? String,
                              let status = listingDict["status"] as? String else {
                            return nil
                        }
                        
                        // Handle amount as either Int or Double
                        let amount: Double
                        if let amountInt = listingDict["amount"] as? Int {
                            amount = Double(amountInt)
                        } else if let amountDouble = listingDict["amount"] as? Double {
                            amount = amountDouble
                        } else {
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
                            contactCount: 0,
                            willRoundToNearestDollar: listingDict["willRoundToNearestDollar"] as? Bool ?? false
                        )
                    }
                    
                    // Fetch meeting proposals for each listing
                    var proposalCounts: [String: Int] = [:]
                    let dispatchGroup = DispatchGroup()
                    
                    for listing in myListings {
                        dispatchGroup.enter()
                        getMeetingProposals(sessionId: sessionId, listingId: listing.id) { result in
                            if let result = result,
                               let proposals = result["proposals"] as? [[String: Any]] {
                                let pendingCount = proposals.filter { prop in
                                    (prop["status"] as? String) == "pending"
                                }.count
                                proposalCounts[listing.id] = pendingCount
                            } else {
                                proposalCounts[listing.id] = 0
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        // Update listings with proposal counts
                        self.myListings = self.myListings.map { listing in
                            var updatedListing = listing
                            if let pendingCount = proposalCounts[listing.id] {
                                updatedListing.pendingLocationProposals = pendingCount
                            }
                            return updatedListing
                        }
                    }
                } else {
                }
            } else {
            }
            
            isLoading = false
        }
        
        // Get purchased contacts
        getPurchasedContacts(sessionId: sessionId) { contacts in
            // Ignore if this response is from an old request
            guard thisRequestToken == self.currentRequestToken else { return }
            
            // Store raw data for navigation
            self.purchasedContactsData = contacts
            
            let purchasedExchanges = contacts.compactMap { contact -> ActiveExchange? in
                guard let listing = contact["listing"] as? [String: Any],
                      let seller = contact["seller"] as? [String: Any],
                      let currency = listing["currency"] as? String,
                      let acceptCurrency = listing["accept_currency"] as? String,
                      let location = listing["location"] as? String,
                      let sellerName = seller["name"] as? String,
                      let listingId = contact["listing_id"] as? String else {
                    return nil
                }
                
                
                let amount: Double
                if let amountInt = listing["amount"] as? Int {
                    amount = Double(amountInt)
                } else if let amountDouble = listing["amount"] as? Double {
                    amount = amountDouble
                } else {
                    return nil
                }
                
                let convertedAmount = ExchangeRatesAPI.shared.convertAmountSync(amount, from: currency, to: acceptCurrency)
                let willRound = (listing["will_round_to_nearest_dollar"] as? Bool) ?? false
                let meetingTime = contact["current_meeting"] as? [String: Any] ?? nil
                let meetingTimeStr = (meetingTime?["time"] as? String) ?? nil
                
                return ActiveExchange(
                    id: listingId,
                    currencyFrom: currency,
                    currencyTo: acceptCurrency,
                    amount: amount,
                    convertedAmount: convertedAmount,
                    traderName: sellerName,
                    location: location,
                    type: .buyer,
                    willRoundToNearestDollar: willRound,
                    meetingTime: meetingTimeStr
                )
            }
            
            
            
            // Deduplicate purchased exchanges by listing ID before adding
            var seenIds = Set<String>()
            let uniquePurchasedExchanges = purchasedExchanges.filter { exchange in
                if seenIds.contains(exchange.id) {
                    return false
                }
                seenIds.insert(exchange.id)
                return true
            }
            
            self.allActiveExchanges.append(contentsOf: uniquePurchasedExchanges)
        }
        
        // Get listing purchases
        getListingPurchases(sessionId: sessionId) { purchases in
            // Ignore if this response is from an old request
            guard thisRequestToken == self.currentRequestToken else { return }
            let sellerExchanges = purchases.compactMap { purchase -> ActiveExchange? in
                guard let listing = purchase["listing"] as? [String: Any],
                      let buyer = purchase["buyer"] as? [String: Any],
                      let currency = listing["currency"] as? String,
                      let acceptCurrency = listing["accept_currency"] as? String,
                      let location = listing["location"] as? String,
                      let buyerName = buyer["name"] as? String,
                      let listingId = purchase["listing_id"] as? String else {
                    return nil
                }
                
                
                let amount: Double
                if let amountInt = listing["amount"] as? Int {
                    amount = Double(amountInt)
                } else if let amountDouble = listing["amount"] as? Double {
                    amount = amountDouble
                } else {
                    return nil
                }
                
                // Calculate converted amount using exchange rates
                let convertedAmount = ExchangeRatesAPI.shared.convertAmountSync(amount, from: currency, to: acceptCurrency)
                let willRound = (listing["will_round_to_nearest_dollar"] as? Bool) ?? false
                
                return ActiveExchange(
                    id: listingId,
                    currencyFrom: currency,
                    currencyTo: acceptCurrency,
                    amount: amount,
                    convertedAmount: convertedAmount,
                    traderName: buyerName,
                    location: location,
                    type: .seller,
                    willRoundToNearestDollar: willRound,
                    meetingTime: nil
                )
            }
            
            
            
            // Deduplicate - filter out seller exchanges for listings already in buyer list
            let existingBuyerListingIds = Set(self.allActiveExchanges.map { $0.id })
            
            let uniqueSellerExchanges = sellerExchanges.filter { !existingBuyerListingIds.contains($0.id) }
            
            
            self.allActiveExchanges.append(contentsOf: uniqueSellerExchanges)
            
            
        }
        
        // Get pending negotiations (for both buyers and sellers)
        getNegotiations(sessionId: sessionId) { negotiations in
            // Ignore if this response is from an old request
            guard thisRequestToken == self.currentRequestToken else { return }
            print("[DashboardView] Processing \(negotiations.count) negotiations")
            
            let pending = negotiations.filter { neg in
                guard neg["userRole"] as? String != nil else {
                    print("[DashboardView] Skipping negotiation - no userRole: \(neg)")
                    return false
                }
                // Show negotiations where status is proposed/countered/agreed/paid_partial (active negotiations)
                let status = neg["status"] as? String ?? ""
                let include = status == "proposed" || status == "countered" || status == "agreed" || status == "paid_partial"
                print("[DashboardView] Status filter: \(status) -> \(include)")
                return include
            }.compactMap { neg -> PendingNegotiation? in
                print("[DashboardView] Mapping negotiation: \(neg)")
                guard let negId = neg["negotiationId"] as? String else {
                    print("[DashboardView] Missing negotiationId - keys: \(neg.keys)")
                    return nil
                }
                guard let listing = neg["listing"] as? [String: Any] else {
                    print("[DashboardView] Missing listing - keys: \(neg.keys)")
                    return nil
                }
                guard let otherUser = neg["otherUser"] as? [String: Any] else {
                    print("[DashboardView] Missing otherUser - keys: \(neg.keys)")
                    return nil
                }
                guard let proposedTime = neg["currentProposedTime"] as? String else {
                    print("[DashboardView] Missing currentProposedTime - keys: \(neg.keys)")
                    return nil
                }
                guard let currency = listing["currency"] as? String else {
                    print("[DashboardView] Missing currency in listing - keys: \(listing.keys)")
                    return nil
                }
                guard let acceptCurrency = listing["acceptCurrency"] as? String else {
                    print("[DashboardView] Missing acceptCurrency in listing - keys: \(listing.keys), values: \(listing)")
                    return nil
                }
                guard let buyerName = otherUser["name"] as? String else {
                    print("[DashboardView] Missing buyerName in otherUser - keys: \(otherUser.keys)")
                    return nil
                }
                guard let status = neg["status"] as? String else {
                    print("[DashboardView] Missing status - keys: \(neg.keys)")
                    return nil
                }
                
                let amount: Double
                if let amountInt = listing["amount"] as? Int {
                    amount = Double(amountInt)
                } else if let amountDouble = listing["amount"] as? Double {
                    amount = amountDouble
                } else {
                    print("[DashboardView] Missing or invalid amount")
                    return nil
                }
                
                let convertedAmount = ExchangeRatesAPI.shared.convertAmountSync(amount, from: currency, to: acceptCurrency)
                
                // Handle willRoundToNearestDollar - could be Bool or Int
                let willRound: Bool
                if let boolVal = listing["willRoundToNearestDollar"] as? Bool {
                    willRound = boolVal
                } else if let intVal = listing["willRoundToNearestDollar"] as? Int {
                    willRound = intVal != 0
                } else {
                    willRound = false
                }
                
                let actionRequired = (neg["actionRequired"] as? Bool) ?? false
                let userRole = (neg["userRole"] as? String) ?? "buyer"
                
                let pending = PendingNegotiation(
                    id: negId,
                    buyerName: buyerName,
                    currency: currency,
                    amount: amount,
                    acceptCurrency: acceptCurrency,
                    proposedTime: proposedTime,
                    convertedAmount: convertedAmount,
                    status: status,
                    willRoundToNearestDollar: willRound,
                    actionRequired: actionRequired,
                    userRole: userRole
                )
                print("[DashboardView] Created PendingNegotiation: \(pending.id) - \(proposedTime)")
                return pending
            }
            
            print("[DashboardView] Final pendingNegotiations count: \(pending.count)")
            self.pendingNegotiations = pending
            print("[DashboardView] Updated self.pendingNegotiations to: \(self.pendingNegotiations.count) items")
            print("[DashboardView] pendingNegotiations is now: \(self.pendingNegotiations)")
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
    
    func getNegotiations(sessionId: String, completion: @escaping ([[String: Any]]) -> Void) {
        let urlString = "\(Settings.shared.baseURL)/Negotiations/GetMyNegotiations?sessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        print("[DashboardView] getNegotiations URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("[DashboardView] Invalid URL")
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[DashboardView] getNegotiations error: \(error)")
                }
                guard let data = data else {
                    print("[DashboardView] No data received")
                    completion([])
                    return
                }
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("[DashboardView] Failed to parse JSON")
                    completion([])
                    return
                }
                print("[DashboardView] Raw JSON response: \(json)")
                
                guard let success = json["success"] as? Bool else {
                    print("[DashboardView] No success field")
                    completion([])
                    return
                }
                guard success else {
                    print("[DashboardView] success=false")
                    completion([])
                    return
                }
                guard let negotiations = json["negotiations"] as? [[String: Any]] else {
                    print("[DashboardView] No negotiations array")
                    completion([])
                    return
                }
                print("[DashboardView] Got \(negotiations.count) negotiations from server")
                negotiations.forEach { neg in
                    print("[DashboardView] Negotiation: \(neg)")
                }
                completion(negotiations)
            }
        }.resume()
    }
    
    func getMeetingProposals(sessionId: String, listingId: String, completion: @escaping ([String: Any]?) -> Void) {
        let urlString = "\(Settings.shared.baseURL)/Meeting/GetMeetingProposals?sessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&listingId=\(listingId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let success = json["success"] as? Bool,
                      success else {
                    completion(nil)
                    return
                }
                completion(json)
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
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(localizationManager.localize("LOADING_DASHBOARD"))
                .foregroundColor(.gray)
        }
    }
}

struct ErrorView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    let error: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(localizationManager.localize("ERROR_LOADING_DASHBOARD"))
                .font(.headline)
                .foregroundColor(.red)
            Text(error)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(localizationManager.localize("RETRY"), action: retry)
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
    let purchasedContactsData: [[String: Any]]
    let pendingNegotiations: [PendingNegotiation]
    @Binding var selectedContactData: ContactData?
    @Binding var navigateToContact: Bool
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
                    Spacer()
                        .frame(height: 16)
                    
                    // Pending Negotiations (for sellers)
                    if !pendingNegotiations.isEmpty {
                        PendingNegotiationsSection(negotiations: pendingNegotiations)
                            .padding(.horizontal)
                            .onAppear {
                                print("[MainDashboardView] Rendering PendingNegotiationsSection with \(pendingNegotiations.count) items")
                            }
                    }
                    
                    // Active Exchanges
                    ActiveExchangesSection(
                        exchanges: allActiveExchanges,
                        purchasedContactsData: purchasedContactsData,
                        selectedContactData: $selectedContactData,
                        navigateToContact: $navigateToContact
                    )
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
            BottomNavigation(activeTab: "home", isContactView: false, contactActiveTab: .constant(nil))
        }
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
    }
}

struct DashboardHeader: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
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
                    Text("\(localizationManager.localize("WELCOME")), \(user.firstName)")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Text("⭐ \(user.rating, specifier: "%.1f")")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("\(user.totalExchanges) \(localizationManager.localize("EXCHANGES"))")
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
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var navigateToCreateListing: Bool
    @Binding var navigateToSearch: Bool
    @Binding var navigateToMessages: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localize("QUICK_ACTIONS"))
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "💰",
                    text: localizationManager.localize("LIST_CURRENCY"),
                    isPrimary: true,
                    action: { navigateToCreateListing = true }
                )
                
                QuickActionButton(
                    icon: "🔍",
                    text: localizationManager.localize("SEARCH"),
                    action: { navigateToSearch = true }
                )
                
                QuickActionButton(
                    icon: "💬",
                    text: localizationManager.localize("MESSAGES"),
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
    @ObservedObject var localizationManager = LocalizationManager.shared
    let exchanges: [ActiveExchange]
    let purchasedContactsData: [[String: Any]]
    @Binding var selectedContactData: ContactData?
    @Binding var navigateToContact: Bool
    
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
                            openContactDetail(for: exchange)
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
    
    private func openContactDetail(for exchange: ActiveExchange) {
        // Find the purchased contact data for this exchange
        if let contactDict = purchasedContactsData.first(where: { dict in
            (dict["listing_id"] as? String) == exchange.id
        }) {
            // Parse the contact data into ContactData struct
            guard let listing = contactDict["listing"] as? [String: Any],
                  let seller = contactDict["seller"] as? [String: Any],
                  let currency = listing["currency"] as? String,
                  let location = listing["location"] as? String,
                  let sellerFirstName = seller["name"] as? String else {
                return
            }
            
            let amount: Double
            if let amountInt = listing["amount"] as? Int {
                amount = Double(amountInt)
            } else if let amountDouble = listing["amount"] as? Double {
                amount = amountDouble
            } else {
                return
            }
            
            let nameParts = sellerFirstName.split(separator: " ")
            let firstName = String(nameParts.first ?? "")
            let lastName = nameParts.count > 1 ? String(nameParts.dropFirst().joined(separator: " ")) : ""
            
            let contactData = ContactData(
                listing: ContactListing(
                    listingId: exchange.id,
                    currency: currency,
                    amount: amount,
                    acceptCurrency: listing["accept_currency"] as? String,
                    preferredCurrency: nil,
                    meetingPreference: listing["meeting_preference"] as? String,
                    location: location,
                    latitude: {
                        if let latDouble = listing["latitude"] as? Double {
                            return latDouble
                        } else if let latString = listing["latitude"] as? String, let latDouble = Double(latString) {
                            return latDouble
                        }
                        return 0.0
                    }(),
                    longitude: {
                        if let lngDouble = listing["longitude"] as? Double {
                            return lngDouble
                        } else if let lngString = listing["longitude"] as? String, let lngDouble = Double(lngString) {
                            return lngDouble
                        }
                        return 0.0
                    }(),
                    radius: (listing["location_radius"] as? Int) ?? 5,
                    willRoundToNearestDollar: listing["will_round_to_nearest_dollar"] as? Bool
                ),
                otherUser: OtherUser(
                    firstName: firstName,
                    lastName: lastName,
                    rating: nil,
                    totalTrades: nil
                ),
                lockedAmount: contactDict["locked_amount"] as? Double,
                exchangeRate: contactDict["exchange_rate"] as? Double,
                fromCurrency: contactDict["from_currency"] as? String,
                toCurrency: contactDict["to_currency"] as? String,
                purchasedAt: contactDict["purchased_at"] as? String
            )
            
            selectedContactData = contactData
            navigateToContact = true
        }
    }
}

struct EmptyStateView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var showSearch: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("💱")
                .font(.system(size: 60))
            
            Text(localizationManager.localize("NO_ACTIVE_EXCHANGES_YET"))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text(localizationManager.localize("BROWSE_LISTINGS_MESSAGE"))
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            Button(localizationManager.localize("BROWSE_LISTINGS")) {
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
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var displayLocation: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main exchange display
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
            
            if let meetingTime = exchange.meetingTime {
                Text(formatDateTime(meetingTime))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Text("⏳ Waiting for location response")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text(exchange.type == .buyer ? "Buying from" : "Selling to")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text("💬 " + localizationManager.localize("START_CONVERSATION"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func geocodeLocation(_ locationString: String) {
        // Parse lat/lng from location string (format: "37.7858, -122.4064")
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
                    // Build a readable location string
                    var addressParts: [String] = []
                    
                    if let city = placemark.locality {
                        addressParts.append(city)
                    }
                    if let state = placemark.administrativeArea {
                        addressParts.append(state)
                    }
                    if let country = placemark.country {
                        addressParts.append(country)
                    }
                    
                    if !addressParts.isEmpty {
                        self.displayLocation = addressParts.joined(separator: ", ")
                    } else {
                        self.displayLocation = locationString
                    }
                } else {
                    self.displayLocation = locationString
                }
            }
        }
    }
    
    private func formatDateTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

struct MyListingsSection: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    let listings: [Listing]
    @Binding var navigateToCreateListing: Bool
    var onRefresh: (() -> Void)?
    
    var totalPendingProposals: Int {
        listings.reduce(0) { $0 + $1.pendingLocationProposals }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(localizationManager.localize("MY_ACTIVE_LISTINGS")) (\(listings.count))")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
                
                Spacer()
                
                if totalPendingProposals > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                        Text("\(totalPendingProposals)")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
            }
            
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
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var navigateToCreateListing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📝")
                .font(.system(size: 48))
            
            Text(localizationManager.localize("NO_ACTIVE_LISTINGS"))
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Button(localizationManager.localize("CREATE_FIRST_LISTING")) {
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
    @ObservedObject var localizationManager = LocalizationManager.shared
    let listing: Listing
    @State private var showEditListing = false
    @State private var convertedAmount: Double? = nil
    var onDelete: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("\(listing.haveAmount, specifier: "%.0f") \(listing.haveCurrency)")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("→")
                        .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                    
                    if let converted = convertedAmount {
                        if listing.willRoundToNearestDollar {
                            Text("\(String(format: "%.0f", converted)) \(listing.wantCurrency)")
                                .font(.system(size: 14, weight: .semibold))
                        } else {
                            Text("\(String(format: "%.2f", converted)) \(listing.wantCurrency)")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    } else {
                        Text(listing.wantCurrency)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                
                Spacer()
                
                VStack(spacing: 6) {
                    Text(localizationManager.localize("ACTIVE"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(12)
                    
                    if listing.pendingLocationProposals > 0 {
                        Text("📍 \(listing.pendingLocationProposals) Proposal\(listing.pendingLocationProposals != 1 ? "s" : "")")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                }
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
                    Text(localizationManager.localize("EDIT_LISTING"))
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
        .onAppear {
            convertedAmount = ExchangeRatesAPI.shared.convertAmountSync(listing.haveAmount, from: listing.haveCurrency, to: listing.wantCurrency)
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
    let willRoundToNearestDollar: Bool
    var pendingLocationProposals: Int = 0
    var acceptedLocationProposals: Int = 0
}

struct ActiveExchange: Identifiable {
    let id: String // listing_id
    let currencyFrom: String
    let currencyTo: String
    let amount: Double
    let convertedAmount: Double?
    let traderName: String
    let location: String
    let type: ExchangeType
    let willRoundToNearestDollar: Bool
    let meetingTime: String? // ISO datetime string
    
    enum ExchangeType {
        case buyer, seller
    }
}

struct PendingNegotiation: Identifiable {
    let id: String // negotiation_id
    let buyerName: String
    let currency: String
    let amount: Double
    let acceptCurrency: String
    let proposedTime: String
    let convertedAmount: Double?
    let status: String
    let willRoundToNearestDollar: Bool
    let actionRequired: Bool
    let userRole: String // "buyer" or "seller"
}

// MARK: - Pending Negotiations Section

struct PendingNegotiationsSection: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    let negotiations: [PendingNegotiation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("⏰ Pending Proposals (\(negotiations.count))")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Check if any negotiations require action from current user
                let badgeText = getPendingBadgeText()
                if let badgeText = badgeText {
                    Text(badgeText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(badgeText == "ACTION REQUIRED" ? Color.orange : Color.blue)
                        .cornerRadius(12)
                }
            }
            
            ForEach(negotiations) { negotiation in
                NavigationLink(destination: NegotiationDetailView(negotiationId: negotiation.id)) {
                    PendingNegotiationCard(negotiation: negotiation)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    private func getPendingBadgeText() -> String? {
        // Check if any negotiations require action from current user
        let hasActionRequired = negotiations.contains { neg in
            return neg.actionRequired
        }
        
        let hasPaidPartial = negotiations.contains { neg in
            return neg.status == "paid_partial"
        }
        
        if hasActionRequired {
            return "ACTION REQUIRED"
        } else if hasPaidPartial {
            return "AWAITING PAYMENT"
        }
        
        return nil
    }
}

struct PendingNegotiationCard: View {
    let negotiation: PendingNegotiation
    
    private var statusText: String {
        switch negotiation.status {
        case "proposed":
            // Someone proposed, context-dependent
            return negotiation.userRole == "seller" ? "💬 Review & Respond" : "⏳ Awaiting Response"
        case "countered":
            // Someone countered - seller is waiting, buyer needs to act
            return negotiation.userRole == "seller" ? "⏳ Awaiting Response" : "🔴 Action Required"
        case "agreed":
            return "✓ Meeting Confirmed"
        case "paid_partial", "paid_complete":
            return "💰 Payment Pending"
        default:
            return "💬 Review & Respond"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 4) {
                    Text(String(format: negotiation.willRoundToNearestDollar ? "%.0f" : "%.2f", negotiation.amount))
                        .font(.system(size: 18, weight: .bold))
                    Text(negotiation.currency)
                        .font(.system(size: 16, weight: .semibold))
                    Text("→")
                        .font(.system(size: 16, weight: .bold))
                    if let converted = negotiation.convertedAmount {
                        Text(String(format: negotiation.willRoundToNearestDollar ? "%.0f" : "%.2f", converted))
                            .font(.system(size: 18, weight: .bold))
                        Text(negotiation.acceptCurrency)
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Text(negotiation.acceptCurrency)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.white.opacity(0.9))
                Text(negotiation.buyerName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.white.opacity(0.9))
                Text(formatProposedTime(negotiation.proposedTime))
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            HStack {
                let statusText = self.statusText
                Text(statusText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }
    
    private func formatProposedTime(_ isoString: String) -> String {
        return DateFormatters.formatCompact(isoString)
    }
}

// MARK: - Bottom Navigation is in BottomNavigation.swift

#Preview {
    DashboardView()
}
