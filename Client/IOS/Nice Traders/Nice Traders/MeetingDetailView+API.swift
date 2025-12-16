//
//  MeetingDetailView+API.swift
//  Nice Traders
//
//  API methods for MeetingDetailView (load proposals, accept, reject, payment, etc.)
//

import Foundation
import SwiftUI

extension MeetingDetailView {
    
    // MARK: - Load Meeting Proposals
    
    func loadMeetingProposals() {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("🔴 [MDV-LOAD] ERROR: No session ID available")
            return
        }
        
        print("🟠 [MDV-LOAD] ===== START LOAD PROPOSALS =====")
        print("🟠 [MDV-LOAD] Listing ID: \(contactData.listing.listingId)")
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Meeting/GetMeetingProposals")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing.listingId))
        ]
        
        guard let url = components.url else {
            print("🔴 [MDV-LOAD] ERROR: Failed to construct URL")
            return
        }
        
        print("🟠 [MDV-LOAD] Fetching from: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("🟠 [MDV-LOAD] Response received from server")
                
                guard let data = data, error == nil else {
                    print("🔴 [MDV-LOAD] ERROR: Network error - \(error?.localizedDescription ?? "unknown")")
                    return
                }
                
                let responseStr = String(data: data, encoding: .utf8) ?? "no data"
                print("🟠 [MDV-LOAD] Raw response: \(responseStr.prefix(500))...")
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    print("✅ [MDV-LOAD] Response successful")
                    
                    // Update displayStatus from server
                    if let newDisplayStatus = json["displayStatus"] as? String {
                        print("🟠 [MDV-LOAD] Updated displayStatus: \(newDisplayStatus)")
                        self.displayStatus = newDisplayStatus
                    }
                    
                    // Parse proposals
                    if let proposalsData = json["proposals"] as? [[String: Any]] {
                        print("🟠 [MDV-LOAD] Found \(proposalsData.count) proposals")
                        
                        self.meetingProposals = proposalsData.compactMap { dict in
                            guard let proposalId = dict["proposal_id"] as? String,
                                  let status = dict["status"] as? String else {
                                print("🔴 [MDV-LOAD] Skipping proposal - missing required fields")
                                return nil
                            }
                            
                            let proposedLocation = dict["proposed_location"] as? String ?? ""
                            let proposedTime = dict["proposed_time"] as? String ?? ""
                            let isFromMe = dict["is_from_me"] as? Bool ?? false
                            // Try new format first (proposed_by_name), fallback to old format (proposer.first_name)
                            let firstName = dict["proposed_by_name"] as? String ?? (dict["proposer"] as? [String: Any])?["first_name"] as? String ?? "Unknown"
                            
                            print("🟠 [MDV-LOAD] Parsed proposal: id=\(proposalId), status=\(status), location=\(proposedLocation), time=\(proposedTime), fromMe=\(isFromMe), proposer=\(firstName)")
                            
                            return MeetingProposal(
                                proposalId: proposalId,
                                proposedLocation: proposedLocation,
                                proposedTime: proposedTime,
                                message: dict["message"] as? String,
                                status: status,
                                isFromMe: isFromMe,
                                proposer: ProposerInfo(firstName: firstName),
                                latitude: dict["latitude"] as? Double,
                                longitude: dict["longitude"] as? Double
                            )
                        }
                        
                        print("✅ [MDV-LOAD] Successfully parsed \(self.meetingProposals.count) proposals")
                        for (i, prop) in self.meetingProposals.enumerated() {
                            print("  [\(i)] \(prop.proposalId) - \(prop.status) - \(prop.proposedLocation)")
                        }
                    } else {
                        print("🟠 [MDV-LOAD] No proposals array in response")
                        self.meetingProposals = []
                    }
                    
                    // Parse current meeting
                    if let meetingData = json["current_meeting"] as? [String: Any] {
                        print("🟠 [MDV-LOAD] Parsing current_meeting...")
                        if let time = meetingData["time"] as? String {
                            // Handle location - if it's nil or null, set to nil
                            let location: String? = meetingData["location"] as? String
                            let latitude: Double? = meetingData["latitude"] as? Double
                            let longitude: Double? = meetingData["longitude"] as? Double
                            let agreedAt = (meetingData["agreed_at"] as? String) ?? ""
                            let timeAcceptedAt: String? = meetingData["timeAcceptedAt"] as? String
                            let locationAcceptedAt: String? = meetingData["locationAcceptedAt"] as? String
                            let userPaidAt: String? = meetingData["userPaidAt"] as? String
                            let otherUserPaidAt: String? = meetingData["otherUserPaidAt"] as? String
                            
                            print("🟠 [MDV-LOAD] Current meeting - time=\(time), location=\(location ?? "nil"), timeAcceptedAt=\(timeAcceptedAt ?? "nil"), locationAcceptedAt=\(locationAcceptedAt ?? "nil"), userPaid=\(userPaidAt ?? "nil"), otherUserPaid=\(otherUserPaidAt ?? "nil")")
                            
                            self.currentMeeting = CurrentMeeting(
                                location: location,
                                latitude: latitude,
                                longitude: longitude,
                                time: time,
                                message: meetingData["message"] as? String,
                                agreedAt: agreedAt,
                                acceptedAt: timeAcceptedAt,
                                locationAcceptedAt: locationAcceptedAt
                            )
                            self.timeAcceptedAt = timeAcceptedAt
                            self.locationAcceptedAt = locationAcceptedAt
                            self.userPaidAt = userPaidAt
                            self.otherUserPaidAt = otherUserPaidAt
                            print("✅ [MDV-LOAD] Set self.timeAcceptedAt to: \(self.timeAcceptedAt ?? "nil")")
                            print("✅ [MDV-LOAD] Set self.locationAcceptedAt to: \(self.locationAcceptedAt ?? "nil")")
                            print("✅ [MDV-LOAD] Set self.userPaidAt to: \(self.userPaidAt ?? "nil")")
                            print("✅ [MDV-LOAD] Set self.otherUserPaidAt to: \(self.otherUserPaidAt ?? "nil")")
                        }
                    } else {
                        print("🟠 [MDV-LOAD] No current_meeting in response - checking for top-level payment info...")
                        // If current_meeting is null, try to get payment info from top level
                        let userPaidAt: String? = json["userPaidAt"] as? String
                        let otherUserPaidAt: String? = json["otherUserPaidAt"] as? String
                        print("🟠 [MDV-LOAD] Top-level userPaidAt: \(userPaidAt ?? "nil"), otherUserPaidAt: \(otherUserPaidAt ?? "nil")")
                        
                        self.userPaidAt = userPaidAt
                        self.otherUserPaidAt = otherUserPaidAt
                        print("✅ [MDV-LOAD] Set self.userPaidAt to: \(self.userPaidAt ?? "nil")")
                        print("✅ [MDV-LOAD] Set self.otherUserPaidAt to: \(self.otherUserPaidAt ?? "nil")")
                    }
                } else {
                    print("🔴 [MDV-LOAD] ERROR: Response indicates failure")
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("🔴 [MDV-LOAD] Error: \(json["error"] as? String ?? "unknown")")
                    }
                }
                
                print("🟠 [MDV-LOAD] ===== END LOAD PROPOSALS =====")
            }
        }.resume()
    }
    
    // MARK: - Complete Exchange
    
    func completeExchange() {
        print("[MeetingDetailView] completeExchange: Button tapped, showing confirmation alert")
        let alert = UIAlertController(
            title: localizationManager.localize("CONFIRM_EXCHANGE_COMPLETE"),
            message: localizationManager.localize("EXCHANGE_COMPLETE_MESSAGE"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            print("[MeetingDetailView] completeExchange: User cancelled")
        })
        alert.addAction(UIAlertAction(title: "Complete", style: .default) { _ in
            print("[MeetingDetailView] completeExchange: User confirmed, calling submitCompleteExchange")
            self.submitCompleteExchange()
        })
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            print("[MeetingDetailView] completeExchange: Failed to get root view controller")
            return
        }
        
        rootVC.present(alert, animated: true)
    }
    
    private func submitCompleteExchange() {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[MeetingDetailView] submitCompleteExchange: No session ID")
            return
        }
        
        let baseURL = Settings.shared.baseURL
        let listingId = contactData.listing.listingId
        let urlString = "\(baseURL)/Negotiations/CompleteExchange?SessionId=\(sessionId)&ListingId=\(listingId)"
        print("[MeetingDetailView] submitCompleteExchange: URL = \(urlString)")
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            print("[MeetingDetailView] submitCompleteExchange: Invalid URL \(urlString)")
            return
        }
        
        isLoading = true
        print("[MeetingDetailView] submitCompleteExchange: Making request to \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            print("[MeetingDetailView] submitCompleteExchange: Response received")
            print("[MeetingDetailView] submitCompleteExchange: Error: \(error?.localizedDescription ?? "none")")
            
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown")"
                    self.isLoading = false
                    print("[MeetingDetailView] submitCompleteExchange: Network error: \(error?.localizedDescription ?? "Unknown")")
                }
                return
            }
            
            print("[MeetingDetailView] submitCompleteExchange: Received data, parsing JSON")
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("[MeetingDetailView] submitCompleteExchange: JSON = \(json)")
                if let success = json["success"] as? Bool, success {
                    print("[MeetingDetailView] submitCompleteExchange: Success! exchange_id = \(json["exchange_id"] ?? "none")")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        // Capture partner_id for rating
                        if let partnerIdStr = json["partner_id"] as? String {
                            self.partnerId = partnerIdStr
                            print("[MeetingDetailView] submitCompleteExchange: Set partnerId = \(partnerIdStr)")
                        }
                        self.showRatingView = true
                        print("[MeetingDetailView] submitCompleteExchange: Showing rating view")
                    }
                } else {
                    let errorMsg = json["error"] as? String ?? "Failed to complete exchange"
                    print("[MeetingDetailView] submitCompleteExchange: Failed - \(errorMsg)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = errorMsg
                    }
                }
            } else {
                print("[MeetingDetailView] submitCompleteExchange: Failed to parse JSON")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to complete exchange"
                }
            }
        }.resume()
    }
    
    // MARK: - Rating
    
    func submitRating() {
        guard userRating > 0 else {
            errorMessage = "Please select a rating"
            return
        }
        
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            return
        }
        
        guard let partnerIdToRate = partnerId else {
            errorMessage = "Partner ID not found"
            return
        }
        
        isLoading = true
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Ratings/SubmitRating")!
        components.queryItems = [
            URLQueryItem(name: "SessionId", value: sessionId),
            URLQueryItem(name: "user_id", value: partnerIdToRate),
            URLQueryItem(name: "Rating", value: String(userRating)),
            URLQueryItem(name: "Review", value: ratingMessage)
        ]
        
        guard let url = components.url else {
            errorMessage = "Invalid URL"
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                guard let data = data, error == nil else {
                    self.errorMessage = "Network error: \(error?.localizedDescription ?? "Unknown")"
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    self.hasSubmittedRating = true
                    print("[MeetingDetailView] submitRating: Rating submitted successfully, closing rating modal")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Close the rating modal first
                        self.showRatingView = false
                        print("[MeetingDetailView] submitRating: Rating modal closed")
                        
                        // Then navigate back to dashboard
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.navigateToContact = false
                            print("[MeetingDetailView] submitRating: Navigating back to dashboard")
                        }
                    }
                } else {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.errorMessage = json["error"] as? String ?? "Failed to submit rating"
                    } else {
                        self.errorMessage = "Failed to submit rating"
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Cancel Operations
    
    func cancelMeetingTime() {
        let alert = UIAlertController(
            title: "Cancel Meeting Time",
            message: "Are you sure you want to cancel the meeting time? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.submitCancelMeetingTime()
        })
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return
        }
        
        rootVC.present(alert, animated: true)
    }
    
    private func submitCancelMeetingTime() {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            return
        }
        
        let baseURL = Settings.shared.baseURL
        let listingId = contactData.listing.listingId
        let urlString = "\(baseURL)/Meeting/CancelMeetingTime?SessionId=\(sessionId)&ListingId=\(listingId)"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                // Reload proposals after cancellation
                self.timeAcceptedAt = nil
                self.loadMeetingProposals()
            }
        }.resume()
    }
    
    func cancelLocation() {
        let alert = UIAlertController(
            title: "Cancel Location",
            message: "Are you sure you want to cancel the meeting location? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.submitCancelLocation()
        })
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return
        }
        
        rootVC.present(alert, animated: true)
    }
    
    private func submitCancelLocation() {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            return
        }
        
        let baseURL = Settings.shared.baseURL
        let listingId = contactData.listing.listingId
        let urlString = "\(baseURL)/Meeting/CancelLocation?SessionId=\(sessionId)&ListingId=\(listingId)"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                // Reload proposals after cancellation
                self.locationAcceptedAt = nil
                self.loadMeetingProposals()
            }
        }.resume()
    }
    
    // MARK: - Meeting Coordination
    
    func acceptExchange() {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[DEBUG] No session ID available")
            return
        }
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/MeetingTime/Accept")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId)
        ]
        
        guard let url = components.url else {
            print("[DEBUG] Failed to construct URL")
            return
        }
        
        print("[DEBUG] Accept button tapped - calling: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("[DEBUG] Accept response received")
                if let error = error {
                    print("[DEBUG] Accept error: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("[DEBUG] Accept HTTP status: \(httpResponse.statusCode)")
                }
                
                if let data = data {
                    print("[DEBUG] Accept response data: \(String(data: data, encoding: .utf8) ?? "no data")")
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("[DEBUG] Accept JSON parsed: \(json)")
                        if let success = json["success"] as? Bool, success {
                            print("[DEBUG ACCEPT] Accept successful")
                            // Get accepted_at from response - try both field names
                            if let timeAcceptedAtFromResponse = json["timeAcceptedAt"] as? String {
                                print("[DEBUG ACCEPT] Got timeAcceptedAt from response: \(timeAcceptedAtFromResponse)")
                                self.timeAcceptedAt = timeAcceptedAtFromResponse
                            } else if let agreementReachedAt = json["agreementReachedAt"] as? String {
                                print("[DEBUG ACCEPT] Got agreementReachedAt from response: \(agreementReachedAt)")
                                self.timeAcceptedAt = agreementReachedAt
                            } else {
                                print("[DEBUG ACCEPT] No timestamp in response, generating locally")
                                self.timeAcceptedAt = self.iso8601Now()
                            }
                            print("[DEBUG ACCEPT] Set self.timeAcceptedAt to: \(self.timeAcceptedAt ?? "nil")")
                            print("[DEBUG ACCEPT] Reloading meeting proposals...")
                            self.loadMeetingProposals()
                        } else {
                            self.errorMessage = json["error"] as? String ?? "Failed to accept exchange"
                            print("[DEBUG] Accept failed: \(self.errorMessage)")
                        }
                    } else {
                        print("[DEBUG] Failed to parse JSON")
                        self.errorMessage = "Invalid response format"
                    }
                } else {
                    print("[DEBUG] No data in response")
                    self.errorMessage = "No response data"
                }
            }
        }.resume()
    }
    
    func counterExchange() {
        // Counter should propose a new meeting time
        // For now, show an alert that they need to propose a counter time
        print("[DEBUG] Counter tapped - user should propose a new meeting time")
        // TODO: Open ProposeTimeView or similar
        errorMessage = "Please propose a new meeting time"
    }
    
    func processPayment() {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[MDV-PAY] No session ID available")
            return
        }
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Payments/ProcessPayment")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId)
        ]
        
        guard let url = components.url else {
            print("[MDV-PAY] Failed to construct payment URL")
            return
        }
        
        isLoading = true
        print("[MDV-PAY] Processing payment - calling: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                print("[MDV-PAY] Payment response received")
                
                if let error = error {
                    print("[MDV-PAY] Payment error: \(error.localizedDescription)")
                    self.errorMessage = "Payment failed: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("[MDV-PAY] Payment HTTP status: \(httpResponse.statusCode)")
                }
                
                if let data = data {
                    print("[MDV-PAY] Response data: \(String(data: data, encoding: .utf8) ?? "no data")")
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let success = json["success"] as? Bool, success {
                            print("[MDV-PAY] Payment successful")
                            // Reload proposals to get updated payment status from server
                            print("[MDV-PAY] Reloading proposals to get updated payment status...")
                            self.loadMeetingProposals()
                        } else {
                            let errorMsg = json["error"] as? String ?? "Payment processing failed"
                            self.errorMessage = errorMsg
                            print("[MDV-PAY] Payment failed: \(errorMsg)")
                        }
                    } else {
                        print("[MDV-PAY] Failed to parse response")
                        self.errorMessage = "Invalid response format"
                    }
                }
            }
        }.resume()
    }
    
    func rejectExchange() {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[DEBUG] No session ID available for reject")
            return
        }
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/MeetingTime/Reject")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId)
        ]
        
        guard let url = components.url else {
            print("[DEBUG] Failed to construct reject URL")
            return
        }
        
        print("[DEBUG] Reject button tapped - calling: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("[DEBUG] Reject response received")
                if let httpResponse = response as? HTTPURLResponse {
                    print("[DEBUG] Reject HTTP status: \(httpResponse.statusCode)")
                }
                
                if let error = error {
                    print("[DEBUG] Reject error: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    print("[DEBUG] Reject successful")
                    self.dismiss()
                } else {
                    let errorMsg = (try? JSONSerialization.jsonObject(with: data ?? Data())) as? [String: Any]
                    self.errorMessage = errorMsg?["error"] as? String ?? "Failed to reject exchange"
                    print("[DEBUG] Reject failed: \(self.errorMessage)")
                }
            }
        }.resume()
    }
    
    func proposeLocation() {
        print("[MDV-ACTION] Propose location action triggered")
        activeTab = .location
    }
    
    func acceptLocationProposal(proposalId: String) {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[MDV-ACTION] ERROR: No session ID available")
            return
        }
        
        print("[MDV-ACTION] Accept location proposal: \(proposalId)")
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Meeting/RespondToMeeting")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "proposalId", value: proposalId),
            URLQueryItem(name: "response", value: "accepted")
        ]
        
        guard let url = components.url else {
            print("[MDV-ACTION] ERROR: Failed to construct URL")
            return
        }
        
        print("[MDV-ACTION] Calling: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("[MDV-ACTION] Response received")
                
                if let error = error {
                    print("[MDV-ACTION] ERROR: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("[MDV-ACTION] HTTP Status: \(httpResponse.statusCode)")
                }
                
                if let data = data {
                    let responseStr = String(data: data, encoding: .utf8) ?? "no data"
                    print("[MDV-ACTION] Response: \(responseStr)")
                    
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let success = json["success"] as? Bool, success {
                            print("✅ [MDV-ACTION] Location accepted successfully!")
                            // Reload proposals to show updated state
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.loadMeetingProposals()
                            }
                        } else {
                            let errorMsg = json["error"] as? String ?? "Unknown error"
                            print("[MDV-ACTION] ERROR: \(errorMsg)")
                            self.errorMessage = errorMsg
                        }
                    }
                }
            }
        }.resume()
    }
    
    func counterLocationProposal(proposalId: String) {
        print("[MDV-ACTION] Counter location proposal: \(proposalId)")
        // The view will switch to location tab and allow user to propose a new location
        // The location tab (MeetingLocationView) handles the counter-proposal workflow
    }
    
    func cancelPendingLocationProposal() {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[DEBUG] No session ID available for cancel location")
            return
        }
        
        let baseURL = Settings.shared.baseURL
        let listingId = contactData.listing.listingId
        var components = URLComponents(string: "\(baseURL)/Meeting/CancelLocation")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: listingId)
        ]
        
        guard let url = components.url else {
            print("[DEBUG] Failed to construct cancel location URL")
            return
        }
        
        print("[DEBUG] Cancel location button tapped - calling: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("[DEBUG] Cancel location response received")
                if let httpResponse = response as? HTTPURLResponse {
                    print("[DEBUG] Cancel location HTTP status: \(httpResponse.statusCode)")
                }
                
                if let error = error {
                    print("[DEBUG] Cancel location error: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    print("[DEBUG] Cancel location successful")
                    // Reload proposals to reflect the deletion
                    self.loadMeetingProposals()
                } else {
                    let errorMsg = (try? JSONSerialization.jsonObject(with: data ?? Data())) as? [String: Any]
                    self.errorMessage = errorMsg?["error"] as? String ?? "Failed to cancel location"
                    print("[DEBUG] Cancel location failed: \(self.errorMessage)")
                }
            }
        }.resume()
    }
    
    private func respondToLocationProposal(proposalId: String, response: String) {
        guard let sessionId = SessionManager.shared.sessionId else {
            errorMessage = "No active session"
            print("[DEBUG] No session ID available for respond to location")
            return
        }
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Meeting/RespondToMeeting")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "proposalId", value: proposalId),
            URLQueryItem(name: "response", value: response)
        ]
        
        guard let url = components.url else {
            print("[DEBUG] Failed to construct respond to location URL")
            return
        }
        
        print("[DEBUG] Respond to location - calling: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("[DEBUG] Respond to location response received")
                if let httpResponse = response as? HTTPURLResponse {
                    print("[DEBUG] Respond to location HTTP status: \(httpResponse.statusCode)")
                }
                
                if let error = error {
                    print("[DEBUG] Respond to location error: \(error.localizedDescription)")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    print("[DEBUG] Respond to location successful")
                    self.loadMeetingProposals()
                } else {
                    let errorMsg = (try? JSONSerialization.jsonObject(with: data ?? Data())) as? [String: Any]
                    self.errorMessage = errorMsg?["error"] as? String ?? "Failed to respond to proposal"
                    print("[DEBUG] Respond to location failed: \(self.errorMessage)")
                }
            }
        }.resume()
    }
    
    // MARK: - Utility Functions
    
    func iso8601Now() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
    
    func startCountdownTimer(meetingTime: String?) {
        guard let meetingTime = meetingTime else { return }
        
        guard let meetingDate = DateFormatters.parseISO8601(meetingTime) else { return }
        
        countdownTimer?.invalidate()
        
        updateCountdown(meetingDate: meetingDate)
        
        // Update every 60 seconds (1 minute)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            updateCountdown(meetingDate: meetingDate)
        }
    }
    
    private func updateCountdown(meetingDate: Date) {
        let now = Date()
        let timeInterval = meetingDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            countdownText = "Meeting time is now!"
            countdownTimer?.invalidate()
            return
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        let hourText = hours == 1 ? "hour" : "hours"
        let minuteText = minutes == 1 ? "minute" : "minutes"
        
        if hours > 0 && minutes > 0 {
            countdownText = "\(hours) \(hourText) \(minutes) \(minuteText) until meeting"
        } else if hours > 0 {
            countdownText = "\(hours) \(hourText) until meeting"
        } else if minutes > 0 {
            countdownText = "\(minutes) \(minuteText) until meeting"
        } else {
            countdownText = "Less than a minute until meeting"
        }
    }
    
    func formatExchangeAmount(_ amount: Double, shouldRound: Bool) -> String {
        return ExchangeRatesAPI.shared.formatAmount(amount, shouldRound: shouldRound)
    }
    
    func formatConvertedAmount() -> String {
        let convertedAmount = ExchangeRatesAPI.shared.convertAmountSync(contactData.listing.amount, from: contactData.listing.currency, to: contactData.listing.acceptCurrency ?? "") ?? contactData.listing.amount
        return ExchangeRatesAPI.shared.formatAmount(convertedAmount, shouldRound: contactData.listing.willRoundToNearestDollar ?? false)
    }
}
