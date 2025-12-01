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
        
        let urlString = "\(baseURL)/Negotiations/Propose?listingId=\(listingId)&sessionId=\(sessionId)&proposedTime=\(isoTime.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        
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
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/Negotiations/Get?negotiationId=\(negotiationId)&sessionId=\(sessionId)"
        
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
                let result = try JSONDecoder().decode(NegotiationDetailResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Accept Proposal
    
    func acceptProposal(negotiationId: String, completion: @escaping (Result<AcceptResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/Negotiations/Accept?negotiationId=\(negotiationId)&sessionId=\(sessionId)"
        
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
                let result = try JSONDecoder().decode(AcceptResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Reject Negotiation
    
    func rejectNegotiation(negotiationId: String, completion: @escaping (Result<RejectResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/Negotiations/Reject?negotiationId=\(negotiationId)&sessionId=\(sessionId)"
        
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
                let result = try JSONDecoder().decode(RejectResponse.self, from: data)
                completion(.success(result))
            } catch {
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
        
        let urlString = "\(baseURL)/Negotiations/Counter?negotiationId=\(negotiationId)&sessionId=\(sessionId)&proposedTime=\(isoTime.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
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
        
        let urlString = "\(baseURL)/Negotiations/Pay?negotiationId=\(negotiationId)&sessionId=\(sessionId)"
        
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
    
    // MARK: - Get My Negotiations
    
    func getMyNegotiations(completion: @escaping (Result<MyNegotiationsResponse, Error>) -> Void) {
        guard let sessionId = SessionManager.shared.sessionId else {
            completion(.failure(NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "No active session"])))
            return
        }
        
        let urlString = "\(baseURL)/Negotiations/GetMyNegotiations?sessionId=\(sessionId)"
        
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
