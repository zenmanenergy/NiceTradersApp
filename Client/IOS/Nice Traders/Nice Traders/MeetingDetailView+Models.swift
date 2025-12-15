//
//  MeetingDetailView+Models.swift
//  Nice Traders
//
//  Data models for MeetingDetailView
//

import Foundation

struct ContactData {
    let listing: ContactListing
    let otherUser: OtherUser
    let lockedAmount: Double?
    let exchangeRate: Double?
    let fromCurrency: String?
    let toCurrency: String?
    let purchasedAt: String?
}

struct ContactListing {
    let listingId: String
    let currency: String
    let amount: Double
    let acceptCurrency: String?
    let preferredCurrency: String?
    let meetingPreference: String?
    let location: String
    let latitude: Double
    let longitude: Double
    let radius: Int
    let willRoundToNearestDollar: Bool?
}

struct OtherUser {
    let firstName: String
    let lastName: String
    let rating: Double?
    let totalTrades: Int?
}

struct ContactMessage: Identifiable {
    let id: String
    let messageText: String
    let sentAt: String
    let isFromUser: Bool
}

struct MeetingProposal: Identifiable {
    let id = UUID()
    let proposalId: String
    let proposedLocation: String
    let proposedTime: String
    let message: String?
    let status: String
    let isFromMe: Bool
    let proposer: ProposerInfo
    let latitude: Double?
    let longitude: Double?
}

struct ProposerInfo {
    let firstName: String
}

struct CurrentMeeting {
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let time: String
    let message: String?
    let agreedAt: String
    let acceptedAt: String?
    let locationAcceptedAt: String?
}
