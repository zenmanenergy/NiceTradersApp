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
    
    var session_id: String? {
        get { UserDefaults.standard.string(forKey: "session_id") }
        set { 
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "session_id")
            } else {
                UserDefaults.standard.removeObject(forKey: "session_id")
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
    
    var user_id: String? {
        get { UserDefaults.standard.string(forKey: "user_id") }
        set { 
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "user_id")
            } else {
                UserDefaults.standard.removeObject(forKey: "user_id")
            }
        }
    }
    
    var firstName: String? {
        get { UserDefaults.standard.string(forKey: "firstName") }
        set { 
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "firstName")
            } else {
                UserDefaults.standard.removeObject(forKey: "firstName")
            }
        }
    }
    
    var lastName: String? {
        get { UserDefaults.standard.string(forKey: "lastName") }
        set { 
            if let value = newValue {
                UserDefaults.standard.set(value, forKey: "lastName")
            } else {
                UserDefaults.standard.removeObject(forKey: "lastName")
            }
        }
    }
    
    var isLoggedIn: Bool {
        return session_id != nil
    }
    
    func logout() {
        session_id = nil
        userType = nil
        user_id = nil
        firstName = nil
        lastName = nil
    }
    
    func verifySession(completion: @escaping (Bool) -> Void) {
        guard let session_id = session_id else {
            completion(false)
            return
        }
        
        let urlString = "\(Settings.shared.baseURL)/Login/Verify?session_id=\(session_id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let verifiedSessionId = json["session_id"] as? String,
                      let verifiedUserType = json["UserType"] as? String else {
                    self.logout()
                    completion(false)
                    return
                }
                
                // Update stored values
                self.session_id = verifiedSessionId
                self.userType = verifiedUserType
                completion(true)
            }
        }.resume()
    }
}
