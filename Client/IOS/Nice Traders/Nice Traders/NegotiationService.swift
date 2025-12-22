//
//  NegotiationService.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/26/25.
//

import Foundation

class NegotiationService {
    static let shared = NegotiationService()
    
    private var baseURL: String {
        Settings.shared.baseURL
    }
    
    private init() {}
    
    // MARK: - Propose Negotiation
    
    func proposeNegotiation(listingId: String, proposedTime: Date, completion: @escaping (Result<ProposeResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let isoTime = ISO8601DateFormatter().string(from: proposedTime)
        
        let urlString = "\(baseURL)/MeetingTime/Propose?listingId=\(listingId)&sessionId=\(sessionId)&proposedTime=\(isoTime.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            #if DEBUG
            // In debug/simulator mode, handle connection errors gracefully
            if let error = error as NSError? {
                
                if error.domain == NSURLErrorDomain && 
                   (error.code == NSURLErrorCannotConnectToHost || 
                    error.code == NSURLErrorCannotFindHost ||
                    error.code == NSURLErrorNetworkConnectionLost) {
                    let mockResponse = ProposeResponse(
                        success: true,
                        negotiationId: "NEG-DEBUG-\(UUID().uuidString.prefix(8))",
                        status: "proposed",
                        proposedTime: ISO8601DateFormatter().string(from: proposedTime),
                        message: "Debug mode - server offline",
                        error: nil
                    )
                    completion(.success(mockResponse))
                    return
                }
            }
            #endif
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            
            do {
                let result = try JSONDecoder().decode(ProposeResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Get Negotiation Details
    
    func getNegotiation(negotiationId: String, completion: @escaping (Result<NegotiationDetailResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("[NegotiationService] Error: No active session")
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/MeetingTime/Get?listingId=\(negotiationId)&sessionId=\(sessionId)"
        print("[NegotiationService] getNegotiation URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("[NegotiationService] Error: Invalid URL")
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            print("[NegotiationService] Response received for negotiationId: \(negotiationId)")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[NegotiationService] HTTP Status: \(httpResponse.statusCode)")
            }
            
            if let error = error {
                print("[NegotiationService] Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("[NegotiationService] Error: No data received")
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Log raw response data
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[NegotiationService] Raw response: \(jsonString.prefix(500))")
            }
            
            do {
                let result = try JSONDecoder().decode(NegotiationDetailResponse.self, from: data)
                print("[NegotiationService] Successfully decoded NegotiationDetailResponse")
                completion(.success(result))
            } catch {
                print("[NegotiationService] Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Accept Proposal
    
    func acceptProposal(negotiationId: String, completion: @escaping (Result<AcceptResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("[NegotiationService] Error: No active session for acceptProposal")
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/MeetingTime/Accept?listingId=\(negotiationId)&sessionId=\(sessionId)"
        print("[NegotiationService] acceptProposal URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("[NegotiationService] Error: Invalid URL for acceptProposal")
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            print("[NegotiationService] acceptProposal response received")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[NegotiationService] acceptProposal HTTP Status: \(httpResponse.statusCode)")
            }
            
            if let error = error {
                print("[NegotiationService] acceptProposal network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("[NegotiationService] acceptProposal error: No data received")
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[NegotiationService] acceptProposal raw response: \(jsonString.prefix(500))")
            }
            
            do {
                let result = try JSONDecoder().decode(AcceptResponse.self, from: data)
                print("[NegotiationService] acceptProposal successfully decoded")
                completion(.success(result))
            } catch {
                print("[NegotiationService] acceptProposal decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Reject Negotiation
    
    func rejectNegotiation(negotiationId: String, completion: @escaping (Result<RejectResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("[NegotiationService] Error: No active session for rejectNegotiation")
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/MeetingTime/Reject?listingId=\(negotiationId)&sessionId=\(sessionId)"
        print("[NegotiationService] rejectNegotiation URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("[NegotiationService] Error: Invalid URL for rejectNegotiation")
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            print("[NegotiationService] rejectNegotiation response received")
            
            if let httpResponse = response as? HTTPURLResponse {
                print("[NegotiationService] rejectNegotiation HTTP Status: \(httpResponse.statusCode)")
            }
            
            if let error = error {
                print("[NegotiationService] rejectNegotiation network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("[NegotiationService] rejectNegotiation error: No data received")
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("[NegotiationService] rejectNegotiation raw response: \(jsonString.prefix(500))")
            }
            
            do {
                let result = try JSONDecoder().decode(RejectResponse.self, from: data)
                print("[NegotiationService] rejectNegotiation successfully decoded")
                completion(.success(result))
            } catch {
                print("[NegotiationService] rejectNegotiation decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Counter Proposal
    
    func counterProposal(negotiationId: String, proposedTime: Date, completion: @escaping (Result<CounterResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let isoTime = ISO8601DateFormatter().string(from: proposedTime)
        
        let urlString = "\(baseURL)/MeetingTime/Counter?listingId=\(negotiationId)&sessionId=\(sessionId)&proposedTime=\(isoTime.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(CounterResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Pay Negotiation Fee
    
    func payNegotiationFee(negotiationId: String, completion: @escaping (Result<PaymentResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/ListingPayment/Pay?listingId=\(negotiationId)&sessionId=\(sessionId)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Debug: print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let result = try decoder.decode(PaymentResponse.self, from: data)
                completion(.success(result))
            } catch let decodingError as DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    ()
                case .typeMismatch(let type, let context):
                    ()
                case .valueNotFound(let type, let context):
                    ()
                case .dataCorrupted(let context):
                    ()
                @unknown default:
                    ()
                }
                completion(.failure(decodingError))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - PayPal Payment Integration
    
    func createPayPalOrder(listingId: String, amount: Double = 2.00, completion: @escaping (Result<CreateOrderResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/Payments/CreateOrder?listingId=\(listingId)&sessionId=\(sessionId)&amount=\(amount)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let result = try decoder.decode(CreateOrderResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func capturePayPalOrder(orderId: String, listingId: String, completion: @escaping (Result<CaptureOrderResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId,
              let userId = SessionManager.shared.user_id else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/Payments/CaptureOrder?orderId=\(orderId)&listingId=\(listingId)&sessionId=\(sessionId)&userId=\(userId)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .useDefaultKeys
                let result = try decoder.decode(CaptureOrderResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Get My Negotiations
    
    func getMyNegotiations(completion: @escaping (Result<MyNegotiationsResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/MeetingTime/GetMy?sessionId=\(sessionId)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(MyNegotiationsResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Propose Meeting Location
    
    func proposeMeetingLocation(listingId: String, latitude: Double, longitude: Double, locationName: String?, completion: @escaping (Result<LocationResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/MeetingLocation/Propose"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "listingId": listingId,
            "sessionId": sessionId,
            "latitude": latitude,
            "longitude": longitude,
            "locationName": locationName ?? ""
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(LocationResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Counter Meeting Location
    
    func counterMeetingLocation(listingId: String, latitude: Double, longitude: Double, locationName: String?, completion: @escaping (Result<LocationResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/MeetingLocation/Counter"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "listingId": listingId,
            "sessionId": sessionId,
            "latitude": latitude,
            "longitude": longitude,
            "locationName": locationName ?? ""
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(LocationResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Accept Meeting Location
    
    func acceptMeetingLocation(listingId: String, completion: @escaping (Result<LocationResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/MeetingLocation/Accept?listingId=\(listingId)&sessionId=\(sessionId)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(LocationResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Reject Meeting Location
    
    func rejectMeetingLocation(listingId: String, completion: @escaping (Result<LocationResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/MeetingLocation/Reject?listingId=\(listingId)&sessionId=\(sessionId)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(LocationResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Get Buyer Info
    
    func getBuyerInfo(buyerId: String, completion: @escaping (Result<BuyerInfoResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/Negotiations/GetBuyerInfo?buyerId=\(buyerId)&sessionId=\(sessionId)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(BuyerInfoResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Helper Extensions

extension NegotiationService {
    /// Format a date string from the API into a user-friendly format
    static func formatDate(_ dateString: String) -> String {
        return DateFormatters.formatCompact(dateString)
    }
    
    /// Get remaining time until payment deadline
    static func getRemainingTime(deadline: String?) -> String? {
        guard let deadline = deadline else { return nil }
        let isoFormatter = ISO8601DateFormatter()
        guard let deadlineDate = isoFormatter.date(from: deadline) else { return nil }
        
        let timeInterval = deadlineDate.timeIntervalSinceNow
        if timeInterval <= 0 {
            return "Expired"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
}
