//
//  AppDelegate.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/25/25.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("🔵 [AppDelegate] Application did finish launching")
        
        // Initialize device token manager and request notification permissions
        print("🔵 [AppDelegate] Initializing DeviceTokenManager...")
        _ = DeviceTokenManager.shared
        print("✓ [AppDelegate] DeviceTokenManager initialized")
        
        return true
    }
    
    // Called when app receives device token from APNs
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("✅ [AppDelegate] *** didRegisterForRemoteNotificationsWithDeviceToken CALLED ***")
        print("✅ [AppDelegate] Device token received from APNs: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        DeviceTokenManager.shared.setDeviceToken(deviceToken)
    }
    
    // Called if registration for remote notifications fails
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ [AppDelegate] *** didFailToRegisterForRemoteNotificationsWithError CALLED ***")
        print("❌ [AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
        // Mark registration as complete so app doesn't wait
        DeviceTokenManager.shared.setRegistrationFailed()
    }
    
    // Called when app receives a remote notification
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("✓ AppDelegate: Received remote notification: \(userInfo)")
        
        // Handle the notification payload
        if let title = userInfo["aps"] as? [String: Any],
           let alert = title["alert"] as? [String: Any] {
            print("  Title: \(alert["title"] ?? "")")
            print("  Body: \(alert["body"] ?? "")")
        }
        
        // Handle notification tap with deep linking and session ID
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler(.newData)
    }
    
    // Handle notification tap with auto-login and deep linking
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Extract session ID for auto-login
        if let sessionId = userInfo["sessionId"] as? String {
            print("✓ AppDelegate: Session ID found in notification: \(sessionId)")
            DispatchQueue.main.async {
                SessionManager.shared.sessionId = sessionId
            }
        }
        
        // Extract deep link information
        if let deepLinkType = userInfo["deepLinkType"] as? String,
           let deepLinkId = userInfo["deepLinkId"] as? String {
            print("✓ AppDelegate: Deep link detected - Type: \(deepLinkType), ID: \(deepLinkId)")
            
            // Post notification to trigger navigation in the app
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("DeepLinkNotification"),
                    object: nil,
                    userInfo: [
                        "deepLinkType": deepLinkType,
                        "deepLinkId": deepLinkId,
                        "sessionId": userInfo["sessionId"] as? String ?? ""
                    ]
                )
            }
        }
    }
}
