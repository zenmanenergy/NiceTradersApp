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
        print("🔔 [DeviceTokenManager] Requesting notification permission...")
        
        // First check current authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔔 [DeviceTokenManager] Current authorization status: \(settings.authorizationStatus.rawValue)")
            print("🔔 [DeviceTokenManager] Alert setting: \(settings.alertSetting.rawValue)")
            print("🔔 [DeviceTokenManager] Badge setting: \(settings.badgeSetting.rawValue)")
            print("🔔 [DeviceTokenManager] Sound setting: \(settings.soundSetting.rawValue)")
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("🔔 [DeviceTokenManager] Authorization result - Granted: \(granted)")
            
            if let error = error {
                print("❌ [DeviceTokenManager] Authorization error: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                self.isNotificationPermissionGranted = granted
                
                if granted {
                    print("✅ [DeviceTokenManager] Permission granted, registering for remote notifications")
                    DispatchQueue.main.async {
                        #if targetEnvironment(simulator)
                        print("📱 [DeviceTokenManager] Simulator detected - skipping APNs registration")
                        self.registrationComplete = true
                        #else
                        print("📱 [DeviceTokenManager] Registering for remote notifications on device")
                        UIApplication.shared.registerForRemoteNotifications()
                        #endif
                    }
                } else {
                    print("❌ [DeviceTokenManager] Permission denied by user")
                    self.registrationComplete = true
                }
            }
        }
    }
    
    /// Set the device token when received from APNs
    func setDeviceToken(_ token: Data) {
        let deviceToken = token.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ [DeviceTokenManager] Device token received: \(deviceToken)")
        
        DispatchQueue.main.async {
            self.deviceToken = deviceToken
            self.registrationComplete = true
            
            // Save token to UserDefaults for persistence
            UserDefaults.standard.set(deviceToken, forKey: self.tokenKey)
            print("✅ [DeviceTokenManager] Token saved to UserDefaults")
            
            // Try to send to backend if user is logged in
            if SessionManager.shared.isLoggedIn {
                print("🔄 [DeviceTokenManager] User logged in, updating backend with token")
                self.updateBackendWithDeviceToken(deviceToken)
            } else {
                print("⚠️ [DeviceTokenManager] User not logged in, will update backend later")
            }
        }
    }
    
    /// Public method to update device token for a specific user
    /// Called when we have both user_id and deviceToken available
    func updateDeviceTokenForUser(user_id: String, deviceToken: String) {
        updateBackendWithDeviceToken(deviceToken, user_id: user_id)
    }
    
    /// Send device token to backend to update user_devices table
    private func updateBackendWithDeviceToken(_ token: String, user_id: String? = nil) {
        print("🔄 [DeviceTokenManager] updateBackendWithDeviceToken called")
        
        // Use provided user_id or get from SessionManager
        let user_id_to_use = user_id ?? SessionManager.shared.user_id
        
        guard let user_id_to_use = user_id_to_use else {
            print("⚠️ [DeviceTokenManager] No user_id available, skipping backend update")
            return
        }
        
        print("🔄 [DeviceTokenManager] Updating backend for user: \(user_id_to_use)")
        
        let device = UIDevice.current
        let appVersion = Bundle.main.appVersion ?? "unknown"
        let osVersion = device.systemVersion
        
        print("🔄 [DeviceTokenManager] Device info - App: \(appVersion), OS: \(osVersion)")
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
            print("❌ [DeviceTokenManager] Failed to build URL")
            return
        }
        
        print("🔄 [DeviceTokenManager] Sending request to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [DeviceTokenManager] Backend update failed: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔄 [DeviceTokenManager] Backend response status: \(httpResponse.statusCode)")
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("🔄 [DeviceTokenManager] Backend response: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    print("✅ [DeviceTokenManager] Device token successfully updated on backend")
                } else {
                    print("❌ [DeviceTokenManager] Backend returned error status code")
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
