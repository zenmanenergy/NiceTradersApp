import Foundation

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
    let hasBuyer: Bool
    let isPaid: Bool
}

struct ActiveExchange: Identifiable {
    let id: String
    let currencyFrom: String
    let currencyTo: String
    let amount: Double
    let convertedAmount: Double?
    let traderName: String
    let location: String
    let latitude: Double
    let longitude: Double
    let radius: Int
    let type: ExchangeType
    let willRoundToNearestDollar: Bool
    let meetingTime: String?
    let status: String?
    let hasLocationProposal: Bool
    let isLocationProposalFromMe: Bool
    let timeAccepted: Bool
    let locationAccepted: Bool
    let displayStatus: String?
    
    enum ExchangeType {
        case buyer, seller
    }
    
    var amountWithCurrency: String {
        "\(String(format: "%.2f", amount)) \(currencyFrom) → \(String(format: "%.2f", convertedAmount ?? 0)) \(currencyTo)"
    }
}

struct PendingNegotiation: Identifiable {
    let id: String
    let listingId: String
    let buyerName: String
    let currency: String
    let amount: Double
    let acceptCurrency: String
    let proposedTime: String
    let convertedAmount: Double?
    let status: String
    let willRoundToNearestDollar: Bool
    let actionRequired: Bool
    let userRole: String
}
