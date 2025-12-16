import Foundation
import SwiftUI
import Combine

class DashboardViewModel: ObservableObject {
    @Published var user: DashboardUserInfo = DashboardUserInfo(name: "Loading...", rating: 0, totalExchanges: 0, joinDate: "Loading...")
    @Published var myListings: [Listing] = []
    @Published var allActiveExchanges: [ActiveExchange] = []
    @Published var purchasedContactsData: [[String: Any]] = []
    @Published var pendingNegotiations: [PendingNegotiation] = []
    @Published var isLoading = true
    @Published var error: String?
    
    private var currentRequestToken = UUID()
    private var globalSeenIds = Set<String>()
    
    func loadDashboardData() {
        guard let sessionId = UserDefaults.standard.string(forKey: "SessionId") else {
            error = "No session found"
            isLoading = false
            return
        }
        
        isLoading = true
        error = nil
        currentRequestToken = UUID()
        let thisRequestToken = currentRequestToken
        
        allActiveExchanges = []
        purchasedContactsData = []
        pendingNegotiations = []
        globalSeenIds = []
        
        fetchDashboardSummary(sessionId: sessionId, thisRequestToken: thisRequestToken)
        fetchPurchasedContacts(sessionId: sessionId, thisRequestToken: thisRequestToken)
        fetchListingPurchases(sessionId: sessionId, thisRequestToken: thisRequestToken)
        fetchPendingNegotiations(sessionId: sessionId, thisRequestToken: thisRequestToken)
    }
    
    private func fetchDashboardSummary(sessionId: String, thisRequestToken: UUID) {
        let urlString = "\(Settings.shared.baseURL)/Dashboard/GetUserDashboard?SessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.isLoading = false }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard thisRequestToken == self?.currentRequestToken else { return }
            
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let dashboardData = json["data"] as? [String: Any],
                      let userData = dashboardData["user"] as? [String: Any] else {
                    self?.isLoading = false
                    return
                }
                
                self?.processDashboardSummary(dashboardData, userData: userData, sessionId: sessionId, thisRequestToken: thisRequestToken)
            }
        }.resume()
    }
    
    private func processDashboardSummary(_ dashboardData: [String: Any], userData: [String: Any], sessionId: String, thisRequestToken: UUID) {
        let firstName = userData["firstName"] as? String ?? ""
        let lastName = userData["lastName"] as? String ?? ""
        let dateCreated = userData["dateCreated"] as? String ?? ""
        
        user = DashboardUserInfo(
            name: "\(firstName) \(lastName)",
            rating: 0,
            totalExchanges: 0,
            joinDate: formatJoinDate(dateCreated)
        )
        
        var proposalCounts: [String: Int] = [:]
        var hasLocationProposalMap: [String: Bool] = [:]
        var meetingDataMap: [String: [String: Any?]] = [:]
        let dispatchGroup = DispatchGroup()
        
        // Process my listings
        if let recentListings = dashboardData["recentListings"] as? [[String: Any]] {
            myListings = recentListings.compactMap { parseListing($0) }
            
            for listing in myListings {
                dispatchGroup.enter()
                fetchMeetingProposals(sessionId: sessionId, listingId: listing.id) { result in
                    let pendingCount = (result?["proposals"] as? [[String: Any]])?.filter { ($0["status"] as? String) == "pending" }.count ?? 0
                    proposalCounts[listing.id] = pendingCount
                    
                    let hasLocationProposal = (result?["proposals"] as? [[String: Any]])?.contains { prop in
                        (prop["type"] as? String) == "location" && (prop["status"] as? String) != "rejected"
                    } ?? false
                    hasLocationProposalMap[listing.id] = hasLocationProposal
                    
                    meetingDataMap[listing.id] = self.extractMeetingData(from: result)
                    dispatchGroup.leave()
                }
            }
        }
        
        // Process active exchanges
        if let activeExchangesData = dashboardData["activeExchanges"] as? [[String: Any]] {
            let dashboardExchanges = activeExchangesData.compactMap { parseActiveExchange($0) }
            
            let uniqueDashboardExchanges = dashboardExchanges.filter { exchange in
                if globalSeenIds.contains(exchange.id) { return false }
                globalSeenIds.insert(exchange.id)
                return true
            }
            allActiveExchanges.append(contentsOf: uniqueDashboardExchanges)
            
            for exchange in uniqueDashboardExchanges {
                dispatchGroup.enter()
                fetchMeetingProposals(sessionId: sessionId, listingId: exchange.id) { result in
                    hasLocationProposalMap[exchange.id] = (result?["proposals"] as? [[String: Any]])?.contains { prop in
                        (prop["type"] as? String) == "location" && (prop["status"] as? String) != "rejected"
                    } ?? false
                    meetingDataMap[exchange.id] = self.extractMeetingData(from: result)
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.updateExchangesWithMeetingData(proposalCounts: proposalCounts, hasLocationProposalMap: hasLocationProposalMap, meetingDataMap: meetingDataMap)
            self.isLoading = false
        }
    }
    
    private func fetchPurchasedContacts(sessionId: String, thisRequestToken: UUID) {
        let urlString = "\(Settings.shared.baseURL)/Contact/GetPurchasedContacts?sessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard thisRequestToken == self?.currentRequestToken else { return }
            
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let contacts = json["purchased_contacts"] as? [[String: Any]] else {
                    return
                }
                
                self?.purchasedContactsData = contacts
                let purchasedExchanges = contacts.compactMap { self?.parsePurchasedContact($0) ?? nil }.compactMap { $0 }
                
                let uniquePurchasedExchanges = purchasedExchanges.filter { exchange in
                    if self?.globalSeenIds.contains(exchange.id) ?? false { return false }
                    self?.globalSeenIds.insert(exchange.id)
                    return true
                }
                
                self?.allActiveExchanges.append(contentsOf: uniquePurchasedExchanges)
            }
        }.resume()
    }
    
    private func fetchListingPurchases(sessionId: String, thisRequestToken: UUID) {
        let urlString = "\(Settings.shared.baseURL)/Contact/GetListingPurchases?sessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard thisRequestToken == self?.currentRequestToken else { return }
            
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let purchases = json["listing_purchases"] as? [[String: Any]] else {
                    return
                }
                
                let sellerExchanges = purchases.compactMap { self?.parseListingPurchase($0) ?? nil }.compactMap { $0 }
                let existingIds = Set(self?.allActiveExchanges.map { $0.id } ?? [])
                let uniqueSellerExchanges = sellerExchanges.filter { !existingIds.contains($0.id) }
                
                self?.allActiveExchanges.append(contentsOf: uniqueSellerExchanges)
            }
        }.resume()
    }
    
    private func fetchPendingNegotiations(sessionId: String, thisRequestToken: UUID) {
        let urlString = "\(Settings.shared.baseURL)/Negotiations/GetMyNegotiations?sessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard thisRequestToken == self?.currentRequestToken else { return }
            
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let success = json["success"] as? Bool,
                      success,
                      let negotiations = json["negotiations"] as? [[String: Any]] else {
                    return
                }
                
                self?.pendingNegotiations = negotiations.compactMap { self?.parsePendingNegotiation($0) ?? nil }.compactMap { $0 }
            }
        }.resume()
    }
    
    private func fetchMeetingProposals(sessionId: String, listingId: String, completion: @escaping ([String: Any]?) -> Void) {
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
    
    // MARK: - Parsing Helpers
    
    private func parseListing(_ dict: [String: Any]) -> Listing? {
        guard let listingId = dict["listingId"] as? String,
              let currency = dict["currency"] as? String,
              let acceptCurrency = dict["acceptCurrency"] as? String,
              let location = dict["location"] as? String,
              let status = dict["status"] as? String else {
            return nil
        }
        
        let amount: Double
        if let amountInt = dict["amount"] as? Int {
            amount = Double(amountInt)
        } else if let amountDouble = dict["amount"] as? Double {
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
            createdDate: dict["createdAt"] as? String ?? "",
            expiresDate: dict["availableUntil"] as? String ?? "",
            viewCount: 0,
            contactCount: 0,
            willRoundToNearestDollar: dict["willRoundToNearestDollar"] as? Bool ?? false
        )
    }
    
    private func parseActiveExchange(_ dict: [String: Any]) -> ActiveExchange? {
        guard let listingId = dict["listingId"] as? String else { return nil }
        
        let listingData: [String: Any] = (dict["listing"] as? [String: Any]) ?? dict
        
        guard let currency = listingData["currency"] as? String,
              let acceptCurrency = listingData["acceptCurrency"] as? String ?? listingData["accept_currency"] as? String,
              let location = listingData["location"] as? String else {
            return nil
        }
        
        let amount: Double
        if let amountInt = listingData["amount"] as? Int {
            amount = Double(amountInt)
        } else if let amountDouble = listingData["amount"] as? Double {
            amount = amountDouble
        } else {
            return nil
        }
        
        let convertedAmount = ExchangeRatesAPI.shared.convertAmountSync(amount, from: currency, to: acceptCurrency)
        let latitude = (listingData["latitude"] as? Double) ?? 0.0
        let longitude = (listingData["longitude"] as? Double) ?? 0.0
        let radius = (listingData["radius"] as? Int) ?? 0
        let willRound = (listingData["willRoundToNearestDollar"] as? Bool) ?? (listingData["will_round_to_nearest_dollar"] as? Bool) ?? false
        let userRole = (dict["userRole"] as? String) ?? "buyer"
        let otherUser = dict["otherUser"] as? [String: Any]
        let otherUserName = otherUser?["name"] as? String ?? "Unknown User"
        let negotiationStatus = (dict["negotiationStatus"] as? String) ?? (dict["status"] as? String) ?? "proposed"
        
        // Parse time acceptance status from backend
        let acceptedAtValue = dict["acceptedAt"]
        let timeAccepted = acceptedAtValue != nil && acceptedAtValue is NSNull == false
        
        // Parse meeting time from backend
        let meetingTimeString = dict["meetingTime"] as? String
        
        // Parse display status from backend
        let displayStatusValue = dict["displayStatus"] as? String
        
        let exchange = ActiveExchange(
            id: listingId,
            currencyFrom: currency,
            currencyTo: acceptCurrency,
            amount: amount,
            convertedAmount: convertedAmount,
            traderName: otherUserName,
            location: location,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            type: userRole == "buyer" ? .buyer : .seller,
            willRoundToNearestDollar: willRound,
            meetingTime: meetingTimeString,
            status: negotiationStatus,
            hasLocationProposal: false,
            isLocationProposalFromMe: false,
            timeAccepted: timeAccepted,
            locationAccepted: false,
            displayStatus: displayStatusValue
        )
        
        return exchange
    }
    
    private func parsePurchasedContact(_ contact: [String: Any]) -> ActiveExchange? {
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
        let latitude = (listing["latitude"] as? Double) ?? 0.0
        let longitude = (listing["longitude"] as? Double) ?? 0.0
        let radius = (listing["radius"] as? Int) ?? 0
        
        return ActiveExchange(
            id: listingId,
            currencyFrom: currency,
            currencyTo: acceptCurrency,
            amount: amount,
            convertedAmount: convertedAmount,
            traderName: sellerName,
            location: location,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            type: .buyer,
            willRoundToNearestDollar: (listing["will_round_to_nearest_dollar"] as? Bool) ?? false,
            meetingTime: nil,
            status: "proposed",
            hasLocationProposal: false,
            isLocationProposalFromMe: false,
            timeAccepted: false,
            locationAccepted: false,
            displayStatus: nil
        )
    }
    
    private func parseListingPurchase(_ purchase: [String: Any]) -> ActiveExchange? {
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
        
        let convertedAmount = ExchangeRatesAPI.shared.convertAmountSync(amount, from: currency, to: acceptCurrency)
        let latitude = (listing["latitude"] as? Double) ?? 0.0
        let longitude = (listing["longitude"] as? Double) ?? 0.0
        let radius = (listing["radius"] as? Int) ?? 0
        
        return ActiveExchange(
            id: listingId,
            currencyFrom: currency,
            currencyTo: acceptCurrency,
            amount: amount,
            convertedAmount: convertedAmount,
            traderName: buyerName,
            location: location,
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            type: .seller,
            willRoundToNearestDollar: (listing["will_round_to_nearest_dollar"] as? Bool) ?? false,
            meetingTime: nil,
            status: "proposed",
            hasLocationProposal: false,
            isLocationProposalFromMe: false,
            timeAccepted: false,
            locationAccepted: false,
            displayStatus: nil
        )
    }
    
    private func parsePendingNegotiation(_ neg: [String: Any]) -> PendingNegotiation? {
        guard let timeNegotiationId = neg["timeNegotiationId"] as? String,
              let listing = neg["listing"] as? [String: Any],
              let listingId = listing["listingId"] as? String,
              let otherUser = neg["otherUser"] as? [String: Any],
              let proposedTime = neg["currentProposedTime"] as? String,
              let currency = listing["currency"] as? String,
              let acceptCurrency = listing["acceptCurrency"] as? String,
              let buyerName = otherUser["name"] as? String,
              let status = neg["status"] as? String else {
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
        
        let willRound: Bool
        if let boolVal = listing["willRoundToNearestDollar"] as? Bool {
            willRound = boolVal
        } else if let intVal = listing["willRoundToNearestDollar"] as? Int {
            willRound = intVal != 0
        } else {
            willRound = false
        }
        
        return PendingNegotiation(
            id: timeNegotiationId,
            listingId: listingId,
            buyerName: buyerName,
            currency: currency,
            amount: amount,
            acceptCurrency: acceptCurrency,
            proposedTime: proposedTime,
            convertedAmount: convertedAmount,
            status: status,
            willRoundToNearestDollar: willRound,
            actionRequired: (neg["actionRequired"] as? Bool) ?? false,
            userRole: (neg["userRole"] as? String) ?? "buyer"
        )
    }
    
    private func updateExchangesWithMeetingData(proposalCounts: [String: Int], hasLocationProposalMap: [String: Bool], meetingDataMap: [String: [String: Any?]]) {
        myListings = myListings.map { listing in
            var updated = listing
            updated.pendingLocationProposals = proposalCounts[listing.id] ?? 0
            return updated
        }
        
        allActiveExchanges = allActiveExchanges.map { exchange in
            let meetingData = meetingDataMap[exchange.id] ?? [:]
            return ActiveExchange(
                id: exchange.id,
                currencyFrom: exchange.currencyFrom,
                currencyTo: exchange.currencyTo,
                amount: exchange.amount,
                convertedAmount: exchange.convertedAmount,
                traderName: exchange.traderName,
                location: exchange.location,
                latitude: exchange.latitude,
                longitude: exchange.longitude,
                radius: exchange.radius,
                type: exchange.type,
                willRoundToNearestDollar: exchange.willRoundToNearestDollar,
                meetingTime: meetingData["meetingTime"] as? String ?? exchange.meetingTime,
                status: exchange.status,
                hasLocationProposal: hasLocationProposalMap[exchange.id] ?? false,
                isLocationProposalFromMe: (meetingData["isLocationProposalFromMe"] as? Bool) ?? false,
                timeAccepted: (meetingData["timeAccepted"] as? Bool) ?? exchange.timeAccepted,
                locationAccepted: (meetingData["locationAccepted"] as? Bool) ?? false,
                displayStatus: exchange.displayStatus
            )
        }
    }
    
    private func extractMeetingData(from result: [String: Any]?) -> [String: Any?] {
        guard let proposals = result?["proposals"] as? [[String: Any]] else {
            return ["meetingTime": nil, "timeAccepted": false, "locationAccepted": false, "isLocationProposalFromMe": false]
        }
        
        var meetingTime: String? = nil
        var timeAccepted: Bool = false
        var locationAccepted: Bool = false
        var isLocationProposalFromMe: Bool = false
        
        for proposal in proposals {
            if let type = proposal["type"] as? String {
                if type == "time" && (proposal["status"] as? String) == "accepted" {
                    meetingTime = proposal["proposed_time"] as? String
                    timeAccepted = true
                } else if type == "location" && (proposal["status"] as? String) != "rejected" {
                    isLocationProposalFromMe = (proposal["is_from_me"] as? Bool) ?? false
                    if (proposal["status"] as? String) == "accepted" {
                        locationAccepted = true
                    }
                }
            }
        }
        
        return ["meetingTime": meetingTime, "timeAccepted": timeAccepted, "locationAccepted": locationAccepted, "isLocationProposalFromMe": isLocationProposalFromMe]
    }
    
    private func formatJoinDate(_ dateString: String) -> String {
        return "Member since 2025"
    }
}
