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
        
        completionHandler(.newData)
    }
}
