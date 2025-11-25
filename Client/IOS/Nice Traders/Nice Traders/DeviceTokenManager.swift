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
    
    private init() {
        requestNotificationPermission()
    }
    
    /// Request notification permission from user
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationPermissionGranted = granted
                
                if granted {
                    print("✓ Notification permission granted")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else {
                    if let error = error {
                        print("✗ Notification permission denied: \(error.localizedDescription)")
                    } else {
                        print("✗ Notification permission denied by user")
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
            print("✓ Device token registered: \(deviceToken)")
            
            // Update the backend with the device token
            self.updateBackendWithDeviceToken(deviceToken)
        }
    }
    
    /// Send device token to backend to update user_devices table
    private func updateBackendWithDeviceToken(_ token: String) {
        // Get user ID from SessionManager
        guard let userId = SessionManager.shared.userId else {
            print("⚠ Cannot update device token: User ID not available")
            return
        }
        
        let device = UIDevice.current
        let appVersion = Bundle.main.appVersion ?? "unknown"
        let osVersion = device.systemVersion
        
        // Build query parameters
        var components = URLComponents(string: "http://localhost:5000/Profile/UpdateDeviceToken")
        components?.queryItems = [
            URLQueryItem(name: "UserId", value: userId),
            URLQueryItem(name: "deviceToken", value: token),
            URLQueryItem(name: "deviceType", value: "ios"),
            URLQueryItem(name: "appVersion", value: appVersion),
            URLQueryItem(name: "osVersion", value: osVersion)
        ]
        
        guard let url = components?.url else {
            print("✗ Invalid URL for device token update")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("✗ Failed to update device token: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✓ Device token successfully updated on backend")
                } else {
                    print("✗ Device token update failed with status: \(httpResponse.statusCode)")
                }
            }
        }.resume()
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
