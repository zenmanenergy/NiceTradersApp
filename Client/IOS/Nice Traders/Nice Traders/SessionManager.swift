//
//  SessionManager.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import Foundation
import Combine

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    private init() {}
    
    var sessionId: String? {
        get { UserDefaults.standard.string(forKey: "SessionId") }
        set { 
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "SessionId")
            } else {
                UserDefaults.standard.removeObject(forKey: "SessionId")
            }
        }
    }
    
    var userType: String? {
        get { UserDefaults.standard.string(forKey: "UserType") }
        set { 
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "UserType")
            } else {
                UserDefaults.standard.removeObject(forKey: "UserType")
            }
        }
    }
    
    var userId: String? {
        get { UserDefaults.standard.string(forKey: "UserId") }
        set { 
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "UserId")
            } else {
                UserDefaults.standard.removeObject(forKey: "UserId")
            }
        }
    }
    
    var isLoggedIn: Bool {
        return sessionId != nil
    }
    
    func logout() {
        sessionId = nil
        userType = nil
        userId = nil
    }
    
    func verifySession(completion: @escaping (Bool) -> Void) {
        guard let sessionId = sessionId else {
            completion(false)
            return
        }
        
        let urlString = "\(Settings.shared.baseURL)/Login/Verify?SessionId=\(sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let verifiedSessionId = json["SessionId"] as? String,
                      let verifiedUserType = json["UserType"] as? String else {
                    self.logout()
                    completion(false)
                    return
                }
                
                // Update stored values
                self.sessionId = verifiedSessionId
                self.userType = verifiedUserType
                completion(true)
            }
        }.resume()
    }
}
