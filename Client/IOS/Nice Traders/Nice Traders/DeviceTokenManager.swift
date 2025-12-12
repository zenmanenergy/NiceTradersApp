//
//  DeviceTokenManager.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/25/25.
//

import Foundation
import UserNotifications
import UIKit
import Combine

class DeviceTokenManager: ObservableObject {
    static let shared = DeviceTokenManager()
    
    @Published var deviceToken: String?
    @Published var isNotificationPermissionGranted = false
    @Published var registrationComplete = false // Track if APNs registration completed (success or failure)
    
    private let tokenKey = "SavedDeviceToken"
    
    private init() {
        // Load saved token from UserDefaults
        if let savedToken = UserDefaults.standard.string(forKey: tokenKey) {
            self.deviceToken = savedToken
        }
        requestNotificationPermission()
    }
    
    /// Request notification permission from user
    func requestNotificationPermission() {
        // First check current authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            DispatchQueue.main.async {
                self.isNotificationPermissionGranted = granted
                
                if granted {
                    DispatchQueue.main.async {
                        #if targetEnvironment(simulator)
                        self.registrationComplete = true
                        #else
                        UIApplication.shared.registerForRemoteNotifications()
                        #endif
                    }
                } else {
                    if let error = error {
                    } else {
                    }
                }
            }
        }
    }
    
    /// Set the device token when received from APNs
    func setDeviceToken(_ token: Data) {
        let deviceToken = token.map { String(format: "%02.2hhx", $0) }.joined()
        
        DispatchQueue.main.async {
            self.deviceToken = deviceToken
            self.registrationComplete = true
            
            // Save token to UserDefaults for persistence
            UserDefaults.standard.set(deviceToken, forKey: self.tokenKey)
            
            // Try to send to backend if user is logged in
            self.updateBackendWithDeviceToken(deviceToken)
        }
    }
    
    /// Public method to update device token for a specific user
    /// Called when we have both user_id and deviceToken available
    func updateDeviceTokenForUser(user_id: String, deviceToken: String) {
        updateBackendWithDeviceToken(deviceToken, user_id: user_id)
    }
    
    /// Send device token to backend to update user_devices table
    private func updateBackendWithDeviceToken(_ token: String, user_id: String? = nil) {
        
        // Use provided user_id or get from SessionManager
        let user_id_to_use = user_id ?? SessionManager.shared.user_id
        
        guard let user_id_to_use = user_id_to_use else {
            return
        }
        
        let device = UIDevice.current
        let appVersion = Bundle.main.appVersion ?? "unknown"
        let osVersion = device.systemVersion
        
        
        // Build query parameters
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Profile/UpdateDeviceToken")
        components?.queryItems = [
            URLQueryItem(name: "user_id", value: user_id_to_use),
            URLQueryItem(name: "deviceToken", value: token),
            URLQueryItem(name: "deviceType", value: "ios"),
            URLQueryItem(name: "appVersion", value: appVersion),
            URLQueryItem(name: "osVersion", value: osVersion)
        ]
        
        guard let url = components?.url else {
            return
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                }
                
                if httpResponse.statusCode == 200 {
                } else {
                }
            }
        }.resume()
    }
    
    /// Called when APNs registration fails
    func setRegistrationFailed() {
        DispatchQueue.main.async {
            self.registrationComplete = true
        }
    }
    
    /// Get device information
    func getDeviceInfo() -> [String: String] {
        let device = UIDevice.current
        let appVersion = Bundle.main.appVersion
        let osVersion = device.systemVersion
        let deviceName = device.model
        
        var info: [String: String] = [
            "deviceType": "ios",
            "osVersion": osVersion,
            "deviceName": deviceName
        ]
        
        if let appVersion = appVersion {
            info["appVersion"] = appVersion
        }
        
        if let deviceToken = deviceToken {
            info["deviceToken"] = deviceToken
        }
        
        return info
    }
}

// Extension to get app version
extension Bundle {
    var appVersion: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
