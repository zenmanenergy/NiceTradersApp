//
//  NegotiationModels.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/26/25.
//

import Foundation

// MARK: - Negotiation Response Models

struct Negotiation: Codable, Identifiable {
    let id: String
    let listingId: String
    let status: NegotiationStatus
    let currentProposedTime: String
    let proposedBy: String
    let buyerPaid: Bool
    let sellerPaid: Bool
    let agreementReachedAt: String?
    let paymentDeadline: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "negotiationId"
        case listingId
        case status
        case currentProposedTime
        case proposedBy
        case buyerPaid
        case sellerPaid
        case agreementReachedAt
        case paymentDeadline
        case createdAt
        case updatedAt
    }
}

enum NegotiationStatus: String, Codable {
    case proposed
    case countered
    case agreed
    case rejected
    case expired
    case cancelled
    case paidPartial = "paid_partial"
    case paidComplete = "paid_complete"
}

struct NegotiationDetail: Codable {
    let negotiation: NegotiationInfo
    let listing: ListingInfo
    let buyer: UserInfo
    let seller: UserInfo
    let userRole: String
    let history: [NegotiationHistoryEntry]
    
    struct NegotiationInfo: Codable {
        let negotiationId: String
        let listingId: String
        let status: NegotiationStatus
        let currentProposedTime: String
        let proposedBy: String
        let buyerPaid: Bool
        let sellerPaid: Bool
        let agreementReachedAt: String?
        let paymentDeadline: String?
        let createdAt: String
        let updatedAt: String
    }
    
    struct ListingInfo: Codable {
        let currency: String
        let amount: Double
        let acceptCurrency: String
        let location: String
    }
    
    struct UserInfo: Codable {
        let userId: String
        let firstName: String
        let lastName: String
        let rating: Double
        let totalExchanges: Int
    }
}

struct NegotiationHistoryEntry: Codable, Identifiable {
    let id = UUID()
    let action: String
    let proposedTime: String?
    let timestamp: String
    let userName: String
    
    enum CodingKeys: String, CodingKey {
        case action
        case proposedTime
        case timestamp
        case userName
    }
}

struct BuyerInfo: Codable {
    let userId: String
    let firstName: String
    let lastName: String
    let rating: Double
    let totalExchanges: Int
    let memberSince: String
    let transactionHistory: [TransactionHistoryEntry]
    let recentRatings: [RatingEntry]
    
    struct TransactionHistoryEntry: Codable, Identifiable {
        let id = UUID()
        let date: String?
        let currency: String
        let amount: Double
        let rating: Int?
        
        enum CodingKeys: String, CodingKey {
            case date, currency, amount, rating
        }
    }
    
    struct RatingEntry: Codable, Identifiable {
        let id = UUID()
        let rating: Int
        let review: String?
        let date: String?
        
        enum CodingKeys: String, CodingKey {
            case rating, review, date
        }
    }
}

struct UserCredit: Codable, Identifiable {
    let id: String
    let amount: Double
    let currency: String
    let reason: String
    let status: CreditStatus
    let createdAt: String
    let expiresAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "creditId"
        case amount
        case currency
        case reason
        case status
        case createdAt
        case expiresAt
    }
}

enum CreditStatus: String, Codable {
    case available
    case applied
    case expired
    case cancelled
}

// MARK: - API Response Models

struct ProposeResponse: Codable {
    let success: Bool
    let negotiationId: String?
    let status: String?
    let proposedTime: String?
    let message: String?
    let error: String?
}

struct AcceptResponse: Codable {
    let success: Bool
    let status: String?
    let agreementReachedAt: String?
    let paymentDeadline: String?
    let message: String?
    let error: String?
}

struct RejectResponse: Codable {
    let success: Bool
    let status: String?
    let message: String?
    let error: String?
}

struct CounterResponse: Codable {
    let success: Bool
    let status: String?
    let proposedTime: String?
    let message: String?
    let error: String?
}

struct PaymentResponse: Codable {
    let success: Bool
    let status: String?
    let transactionId: String?
    let amountCharged: Double?
    let creditApplied: Double?
    let bothPaid: Bool?
    let message: String?
    let error: String?
}

struct NegotiationDetailResponse: Codable {
    let success: Bool
    let negotiation: NegotiationInfo?
    let listing: ListingInfo?
    let buyer: UserInfo?
    let seller: UserInfo?
    let userRole: String?
    let history: [NegotiationHistoryEntry]?
    let error: String?
    
    struct NegotiationInfo: Codable {
        let negotiationId: String
        let listingId: String
        let status: NegotiationStatus
        let currentProposedTime: String
        let proposedBy: String
        let buyerPaid: Bool
        let sellerPaid: Bool
        let agreementReachedAt: String?
        let paymentDeadline: String?
        let createdAt: String
        let updatedAt: String
    }
    
    struct ListingInfo: Codable {
        let currency: String
        let amount: Double
        let acceptCurrency: String
        let location: String
    }
    
    struct UserInfo: Codable {
        let userId: String
        let firstName: String
        let lastName: String
        let rating: Double
        let totalExchanges: Int
    }
    
    // Convert to NegotiationDetail
    func toNegotiationDetail() -> NegotiationDetail? {
        guard let negotiation = negotiation,
              let listing = listing,
              let buyer = buyer,
              let seller = seller,
              let userRole = userRole,
              let history = history else {
            return nil
        }
        
        return NegotiationDetail(
            negotiation: NegotiationDetail.NegotiationInfo(
                negotiationId: negotiation.negotiationId,
                listingId: negotiation.listingId,
                status: negotiation.status,
                currentProposedTime: negotiation.currentProposedTime,
                proposedBy: negotiation.proposedBy,
                buyerPaid: negotiation.buyerPaid,
                sellerPaid: negotiation.sellerPaid,
                agreementReachedAt: negotiation.agreementReachedAt,
                paymentDeadline: negotiation.paymentDeadline,
                createdAt: negotiation.createdAt,
                updatedAt: negotiation.updatedAt
            ),
            listing: NegotiationDetail.ListingInfo(
                currency: listing.currency,
                amount: listing.amount,
                acceptCurrency: listing.acceptCurrency,
                location: listing.location
            ),
            buyer: NegotiationDetail.UserInfo(
                userId: buyer.userId,
                firstName: buyer.firstName,
                lastName: buyer.lastName,
                rating: buyer.rating,
                totalExchanges: buyer.totalExchanges
            ),
            seller: NegotiationDetail.UserInfo(
                userId: seller.userId,
                firstName: seller.firstName,
                lastName: seller.lastName,
                rating: seller.rating,
                totalExchanges: seller.totalExchanges
            ),
            userRole: userRole,
            history: history
        )
    }
}

struct MyNegotiationsResponse: Codable {
    let success: Bool
    let negotiations: [MyNegotiationItem]?
    let count: Int?
    let error: String?
}

struct MyNegotiationItem: Codable, Identifiable {
    let id: String
    let listingId: String
    let status: NegotiationStatus
    let currentProposedTime: String
    let proposedBy: String
    let buyerPaid: Bool
    let sellerPaid: Bool
    let agreementReachedAt: String?
    let paymentDeadline: String?
    let createdAt: String
    let updatedAt: String
    let listing: ListingInfo
    let userRole: String
    let otherUser: OtherUserInfo
    
    enum CodingKeys: String, CodingKey {
        case id = "negotiationId"
        case listingId
        case status
        case currentProposedTime
        case proposedBy
        case buyerPaid
        case sellerPaid
        case agreementReachedAt
        case paymentDeadline
        case createdAt
        case updatedAt
        case listing
        case userRole
        case otherUser
    }
    
    struct ListingInfo: Codable {
        let currency: String
        let amount: Double
        let acceptCurrency: String
        let location: String
    }
    
    struct OtherUserInfo: Codable {
        let userId: String
        let name: String
        let rating: Double
    }
}

struct BuyerInfoResponse: Codable {
    let success: Bool
    let buyer: BuyerInfo?
    let error: String?
}
