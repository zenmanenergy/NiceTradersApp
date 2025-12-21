import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedContactData: ContactData?
    @State private var selectedDisplayStatus: String?
    @State private var navigateToContact = false
    @State private var navigateToCreateListing = false
    @State private var navigateToSearch = false
    @State private var navigateToProfile = false
    @State private var navigateToMessages = false
    @State private var navigateToNotifications = false
    @State private var navigateToNegotiation = false
    @State private var selectedExchangeId: String?
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    LoadingView()
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        viewModel.loadDashboardData()
                    }
                } else if navigateToContact && selectedContactData != nil {
                    MeetingDetailView(contactData: selectedContactData!, initialDisplayStatus: selectedDisplayStatus, navigateToContact: $navigateToContact)
                } else {
                    MainDashboardView(
                        viewModel: viewModel,
                        selectedContactData: $selectedContactData,
                        selectedDisplayStatus: $selectedDisplayStatus,
                        navigateToContact: $navigateToContact,
                        navigateToCreateListing: $navigateToCreateListing,
                        navigateToProfile: $navigateToProfile,
                        navigateToMessages: $navigateToMessages,
                        navigateToNegotiation: $navigateToNegotiation,
                        selectedExchangeId: $selectedExchangeId,
                        onRefresh: {
                            viewModel.loadDashboardData()
                        },
                        onRefreshAsync: { completion in
                            viewModel.loadDashboardData()
                            // Wait for data to load
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                var waitTime = 0.0
                                let checkTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                                    waitTime += 0.1
                                    if !viewModel.isLoading || waitTime > 5.0 {
                                        timer.invalidate()
                                        completion()
                                    }
                                }
                            }
                        }
                    )
                }
            }
            
            // In-app notification banner (always on top)
            InAppNotificationBanner()
                .zIndex(1000)
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
        .navigationDestination(isPresented: $navigateToNotifications) {
            NotificationsView()
        }
        .navigationDestination(isPresented: $navigateToNegotiation) {
            if let listingId = selectedExchangeId {
                NegotiationDetailView(listingId: listingId, navigateToNegotiation: $navigateToNegotiation)
            }
        }
        .onAppear {
            verifySessionAndLoadData()
            setupNavigationListeners(
                onSearch: { navigateToSearch = true },
                onCreateListing: { navigateToCreateListing = true },
                onMessages: { navigateToMessages = true }
            )
        }
        .onChange(of: navigateToContact) { oldValue, newValue in
            // When returning from MeetingDetailView (navigateToContact becomes false), refresh dashboard
            if !newValue && oldValue {
                viewModel.loadDashboardData()
            }
        }
        .onDisappear {
            removeNavigationListeners()
        }
    }
    
    private func verifySessionAndLoadData() {
        guard let sessionId = UserDefaults.standard.string(forKey: "SessionId") else {
            return
        }
        
        verifySession(sessionId: sessionId) { isValid in
            if isValid {
                viewModel.loadDashboardData()
            } else {
                UserDefaults.standard.removeObject(forKey: "SessionId")
                UserDefaults.standard.removeObject(forKey: "UserType")
                viewModel.error = "Session expired. Please log in again."
            }
        }
    }
    
    private func verifySession(sessionId: String, completion: @escaping (Bool) -> Void) {
        let urlString = "\(Settings.shared.baseURL)/Login/Verify?SessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      json["SessionId"] as? String != nil,
                      json["UserType"] as? String != nil else {
                    completion(false)
                    return
                }
                completion(true)
            }
        }.resume()
    }
    
    private func setupNavigationListeners(onSearch: @escaping () -> Void, onCreateListing: @escaping () -> Void, onMessages: @escaping () -> Void) {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToSearch"), object: nil, queue: .main) { _ in
            onSearch()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToCreateListing"), object: nil, queue: .main) { _ in
            onCreateListing()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToMessages"), object: nil, queue: .main) { _ in
            onMessages()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToNotifications"), object: nil, queue: .main) { _ in
            navigateToNotifications = true
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToListing"), object: nil, queue: .main) { _ in
            navigateToSearch = true
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("NavigateToNegotiations"), object: nil, queue: .main) { notification in
            selectedTab = 3
        }
    }
    
    private func removeNavigationListeners() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToSearch"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToCreateListing"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToMessages"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToNotifications"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToListing"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NavigateToNegotiations"), object: nil)
    }
}

struct MainDashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var selectedContactData: ContactData?
    @Binding var selectedDisplayStatus: String?
    @Binding var navigateToContact: Bool
    @Binding var navigateToCreateListing: Bool
    @Binding var navigateToProfile: Bool
    @Binding var navigateToMessages: Bool
    @Binding var navigateToNegotiation: Bool
    @Binding var selectedExchangeId: String?
    var onRefresh: (() -> Void)?
    var onRefreshAsync: ((@escaping () -> Void) -> Void)?
    
    var filteredActiveExchanges: [ActiveExchange] {
        let pendingListingIds = Set(viewModel.pendingNegotiations.map { $0.listingId })
        return viewModel.allActiveExchanges.filter { !pendingListingIds.contains($0.id) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            DashboardHeader(user: viewModel.user, navigateToProfile: $navigateToProfile, navigateToMessages: $navigateToMessages)
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 16)
                    
                    if !viewModel.pendingNegotiations.isEmpty {
                        PendingNegotiationsSection(negotiations: viewModel.pendingNegotiations)
                            .padding(.horizontal)
                    }
                    
                    ActiveExchangesSection(
                        exchanges: filteredActiveExchanges,
                        purchasedContactsData: viewModel.purchasedContactsData,
                        selectedContactData: $selectedContactData,
                        selectedDisplayStatus: $selectedDisplayStatus,
                        navigateToContact: $navigateToContact,
                        navigateToNegotiation: $navigateToNegotiation,
                        selectedExchangeId: $selectedExchangeId
                    )
                    .padding(.horizontal)
                    
                    MyListingsSection(
                        listings: viewModel.myListings,
                        navigateToCreateListing: $navigateToCreateListing,
                        onRefresh: { viewModel.loadDashboardData() }
                    )
                    .padding(.horizontal)
                    
                    Spacer(minLength: 80)
                }
                .refreshable {
                    return await withCheckedContinuation { continuation in
                        onRefreshAsync? { () in
                            continuation.resume()
                        }
                    }
                }
            }
            
            BottomNavigation(activeTab: "home", isContactView: false, contactActiveTab: .constant(nil))
        }
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
    }
}

#Preview {
    DashboardView()
}
