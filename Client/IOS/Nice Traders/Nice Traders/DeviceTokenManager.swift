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
    
    private init() {
        requestNotificationPermission()
    }
    
    /// Request notification permission from user
    func requestNotificationPermission() {
        print("🔵 [DeviceTokenManager] Requesting notification permission...")
        
        // First check current authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔵 [DeviceTokenManager] Current authorization status: \(settings.authorizationStatus.rawValue)")
            print("🔵 [DeviceTokenManager] Alert setting: \(settings.alertSetting.rawValue)")
            print("🔵 [DeviceTokenManager] Badge setting: \(settings.badgeSetting.rawValue)")
            print("🔵 [DeviceTokenManager] Sound setting: \(settings.soundSetting.rawValue)")
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("🔵 [DeviceTokenManager] requestAuthorization callback - granted: \(granted)")
            
            DispatchQueue.main.async {
                self.isNotificationPermissionGranted = granted
                
                if granted {
                    print("✓ [DeviceTokenManager] Notification permission granted - calling registerForRemoteNotifications")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                        print("✓ [DeviceTokenManager] registerForRemoteNotifications called")
                    }
                } else {
                    if let error = error {
                        print("✗ [DeviceTokenManager] Notification permission denied with error: \(error.localizedDescription)")
                    } else {
                        print("✗ [DeviceTokenManager] Notification permission denied by user")
                    }
                }
            }
        }
    }
    
    /// Set the device token when received from APNs
    func setDeviceToken(_ token: Data) {
        let deviceToken = token.map { String(format: "%02.2hhx", $0) }.joined()
        print("🔵 [DeviceTokenManager] setDeviceToken called with token: \(deviceToken)")
        
        DispatchQueue.main.async {
            self.deviceToken = deviceToken
            self.registrationComplete = true
            print("✓ [DeviceTokenManager] Device token stored locally: \(deviceToken)")
            
            // Update the backend with the device token
            print("🔵 [DeviceTokenManager] Calling updateBackendWithDeviceToken...")
            self.updateBackendWithDeviceToken(deviceToken)
        }
    }
    
    /// Send device token to backend to update user_devices table
    private func updateBackendWithDeviceToken(_ token: String) {
        print("🔵 [DeviceTokenManager] updateBackendWithDeviceToken called with token: \(token)")
        
        // Get user ID from SessionManager
        guard let userId = SessionManager.shared.userId else {
            print("⚠ [DeviceTokenManager] Cannot update device token: User ID not available")
            print("⚠ [DeviceTokenManager] SessionManager.shared.userId is nil")
            return
        }
        
        print("✓ [DeviceTokenManager] User ID found: \(userId)")
        
        let device = UIDevice.current
        let appVersion = Bundle.main.appVersion ?? "unknown"
        let osVersion = device.systemVersion
        
        print("🔵 [DeviceTokenManager] Device info - appVersion: \(appVersion), osVersion: \(osVersion)")
        
        // Build query parameters
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Profile/UpdateDeviceToken")
        components?.queryItems = [
            URLQueryItem(name: "UserId", value: userId),
            URLQueryItem(name: "deviceToken", value: token),
            URLQueryItem(name: "deviceType", value: "ios"),
            URLQueryItem(name: "appVersion", value: appVersion),
            URLQueryItem(name: "osVersion", value: osVersion)
        ]
        
        guard let url = components?.url else {
            print("✗ [DeviceTokenManager] Invalid URL for device token update")
            return
        }
        
        print("🔵 [DeviceTokenManager] Making request to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("✗ [DeviceTokenManager] Failed to update device token: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔵 [DeviceTokenManager] Response status code: \(httpResponse.statusCode)")
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("🔵 [DeviceTokenManager] Response body: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    print("✓ [DeviceTokenManager] Device token successfully updated on backend")
                } else {
                    print("✗ [DeviceTokenManager] Device token update failed with status: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
    /// Called when APNs registration fails
    func setRegistrationFailed() {
        DispatchQueue.main.async {
            self.registrationComplete = true
            print("✓ [DeviceTokenManager] Registration marked as complete (failed)")
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
