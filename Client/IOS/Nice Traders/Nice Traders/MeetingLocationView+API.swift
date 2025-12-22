//
//  MeetingLocationView+API.swift
//  Nice Traders
//
//  API methods for MeetingLocationView

import SwiftUI
import MapKit

extension MeetingLocationView {
    func refreshDisplayStatus() {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("[DEBUG MLV refreshDisplayStatus] ERROR: No session ID available")
            return
        }
        
        print("[DEBUG MLV refreshDisplayStatus] Starting refresh...")
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Meeting/GetMeetingProposals")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId)
        ]
        
        guard let url = components.url else {
            print("[DEBUG MLV refreshDisplayStatus] ERROR: Failed to construct URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("[DEBUG MLV refreshDisplayStatus] ERROR: Network error - \(error?.localizedDescription ?? "unknown")")
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    if let newDisplayStatus = json["displayStatus"] as? String {
                        print("[DEBUG MLV refreshDisplayStatus] Updated displayStatus: \(newDisplayStatus)")
                        self.displayStatus = newDisplayStatus
                    } else {
                        print("[DEBUG MLV refreshDisplayStatus] WARNING: displayStatus not in response")
                    }
                } else {
                    print("[DEBUG MLV refreshDisplayStatus] ERROR: Failed to parse response")
                }
            }
        }.resume()
    }
    
    func refreshListingData() {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("[DEBUG MLV refreshListingData] ERROR: No session ID available")
            return
        }
        
        print("[DEBUG MLV refreshListingData] Starting refresh of listing data...")
        
        let baseURL = Settings.shared.baseURL
        let urlString = "\(baseURL)/Dashboard/GetUserDashboard?SessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            print("[DEBUG MLV refreshListingData] ERROR: Failed to construct URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("[DEBUG MLV refreshListingData] ERROR: Network error - \(error?.localizedDescription ?? "unknown")")
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let dashboardData = json["data"] as? [String: Any],
                   let activeExchanges = dashboardData["activeExchanges"] as? [[String: Any]] {
                    
                    // Find the exchange matching our listing ID
                    if let matchingExchange = activeExchanges.first(where: { ($0["listingId"] as? String) == self.contactData.listing.listingId }) {
                        if let listingData = matchingExchange["listing"] as? [String: Any] {
                            // Update contactData with fresh listing data
                            let radius = (listingData["radius"] as? Int) ?? self.contactData.listing.radius
                            let latitude = (listingData["latitude"] as? Double) ?? self.contactData.listing.latitude
                            let longitude = (listingData["longitude"] as? Double) ?? self.contactData.listing.longitude
                            
                            print("[DEBUG MLV refreshListingData] Updated listing data - radius: \(radius), lat: \(latitude), lng: \(longitude)")
                            
                            // Create updated ContactListing with fresh data
                            let updatedListing = ContactListing(
                                listingId: self.contactData.listing.listingId,
                                currency: self.contactData.listing.currency,
                                amount: self.contactData.listing.amount,
                                acceptCurrency: self.contactData.listing.acceptCurrency,
                                preferredCurrency: self.contactData.listing.preferredCurrency,
                                meetingPreference: self.contactData.listing.meetingPreference,
                                location: self.contactData.listing.location,
                                latitude: latitude,
                                longitude: longitude,
                                radius: radius,
                                willRoundToNearestDollar: self.contactData.listing.willRoundToNearestDollar
                            )
                            
                            // Update the contactData state
                            self.contactData = ContactData(
                                listing: updatedListing,
                                otherUser: self.contactData.otherUser,
                                lockedAmount: self.contactData.lockedAmount,
                                exchangeRate: self.contactData.exchangeRate,
                                fromCurrency: self.contactData.fromCurrency,
                                toCurrency: self.contactData.toCurrency,
                                purchasedAt: self.contactData.purchasedAt
                            )
                        }
                    } else {
                        print("[DEBUG MLV refreshListingData] WARNING: Could not find matching exchange for listing \(self.contactData.listing.listingId)")
                    }
                } else {
                    print("[DEBUG MLV refreshListingData] ERROR: Failed to parse response or invalid data")
                }
            }
        }.resume()
    }
    
    func respondToProposal(proposalId: String, response: String) {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("ERROR: No session ID available")
            return
        }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/RespondToMeeting")!
        let queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "proposalId", value: proposalId),
            URLQueryItem(name: "response", value: response)
        ]
        components.queryItems = queryItems
        
        guard let url = components.url else {
            print("ERROR: Failed to construct URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("ERROR: Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("ERROR: No data received")
                return
            }
            
            do {
                let result = try JSONDecoder().decode(RespondToProposalResponse.self, from: data)
                if result.success {
                    print("✓ Responded to proposal: \(response)")
                    
                    DispatchQueue.main.async {
                        // Reload proposals to reflect the change
                        // This would need to be called from parent view to reload
                    }
                } else {
                    if let error = result.error {
                        print("ERROR: Server error: \(error)")
                    }
                }
            } catch {
                print("ERROR: Failed to parse response: \(error)")
            }
        }.resume()
    }
    
    func proposeLocation(location: MapSearchResult, message: String?) {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("🔴 [MLV-PROPOSE] ERROR: No session ID available")
            return
        }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/ProposeMeeting")!
        let queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId),
            URLQueryItem(name: "proposedLatitude", value: "\(location.coordinate.latitude)"),
            URLQueryItem(name: "proposedLongitude", value: "\(location.coordinate.longitude)"),
            URLQueryItem(name: "proposedLocation", value: location.name),
            URLQueryItem(name: "message", value: message ?? "")
        ]
        components.queryItems = queryItems
        
        guard let url = components.url else {
            print("🔴 ERROR: Failed to construct URL")
            return
        }
        
        print("🟡 [MLV-PROPOSE] Making request to: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("🔴 [MLV-PROPOSE] Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("🔴 [MLV-PROPOSE] No data received")
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let success = json["success"] as? Bool {
                    if success {
                        print("🟢 [MLV-PROPOSE] SUCCESS: Location proposal sent")
                        DispatchQueue.main.async {
                            self.successMessageText = localizationManager.localize("LOCATION_PROPOSAL_SENT")
                            self.showSuccessMessage = true
                            self.searchText = ""
                            self.searchResults = []
                            self.selectedResultId = nil
                            self.showLocationProposalConfirm = false
                            self.selectedLocationForProposal = nil
                            
                            // Reload proposals after a short delay to let server process
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.reloadMeetingProposals()
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                self.showSuccessMessage = false
                            }
                        }
                    } else {
                        let errorMsg = json["error"] as? String ?? "Unknown error"
                        print("🔴 [MLV-PROPOSE] Server error: \(errorMsg)")
                    }
                }
            } else {
                print("🔴 [MLV-PROPOSE] Failed to parse response")
            }
        }.resume()
    }
    
    func reloadMeetingProposals() {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("[DEBUG MLV reloadMeetingProposals] ERROR: No session ID")
            return
        }
        
        print("[DEBUG MLV reloadMeetingProposals] Starting reload...")
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/GetMeetingProposals")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId)
        ]
        
        guard let url = components.url else {
            print("[DEBUG MLV reloadMeetingProposals] ERROR: Failed to construct URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("[DEBUG MLV reloadMeetingProposals] ERROR: Network error")
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    if let proposalsData = json["data"] as? [[String: Any]] {
                        let newProposals = proposalsData.compactMap { dict -> MeetingProposal? in
                            guard let proposalId = dict["proposal_id"] as? String,
                                  let status = dict["status"] as? String,
                                  let proposedLocation = dict["proposed_location"] as? String else {
                                return nil
                            }
                            
                            let proposedTime = dict["proposed_time"] as? String ?? ""
                            let message = dict["message"] as? String
                            let isFromMe = dict["is_from_me"] as? Bool ?? false
                            let latitude = dict["proposed_latitude"] as? Double
                            let longitude = dict["proposed_longitude"] as? Double
                            
                            return MeetingProposal(
                                proposalId: proposalId,
                                proposedLocation: proposedLocation,
                                proposedTime: proposedTime,
                                message: message,
                                status: status,
                                isFromMe: isFromMe,
                                proposer: ProposerInfo(firstName: dict["proposed_by_name"] as? String ?? (dict["proposer"] as? [String: Any])?["first_name"] as? String ?? "Unknown"),
                                latitude: latitude,
                                longitude: longitude
                            )
                        }
                        
                        print("[DEBUG MLV reloadMeetingProposals] Loaded \(newProposals.count) proposals")
                        self.meetingProposals = newProposals
                        
                        // Update current meeting if any proposal is accepted
                        if let acceptedProposal = newProposals.first(where: { $0.status == "accepted" }) {
                            self.currentMeeting = CurrentMeeting(
                                location: acceptedProposal.proposedLocation,
                                latitude: acceptedProposal.latitude,
                                longitude: acceptedProposal.longitude,
                                time: acceptedProposal.proposedTime,
                                message: acceptedProposal.message,
                                agreedAt: "",
                                acceptedAt: "",
                                locationAcceptedAt: ""
                            )
                        }
                    }
                } else {
                    print("[DEBUG MLV reloadMeetingProposals] ERROR: Failed to parse response")
                }
            }
        }.resume()
    }
}
