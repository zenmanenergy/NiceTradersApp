//
//  AppDelegate.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/25/25.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("🚀 [AppDelegate] App launched")
        
        // Suppress known UIKit constraint warnings for keyboard input views
        // These are system-level warnings that don't affect functionality
        // See: https://developer.apple.com/forums/thread/707024
        UserDefaults.standard.set(true, forKey: "UIConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        
        // Initialize device token manager and request notification permissions
        print("🔔 [AppDelegate] Initializing DeviceTokenManager")
        _ = DeviceTokenManager.shared
        
        print("🔔 [AppDelegate] Setting UNUserNotificationCenter delegate")
        UNUserNotificationCenter.current().delegate = self
        
        // Check if launched from notification
        if let notificationPayload = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            print("📬 [AppDelegate] App launched from notification tap")
            print("📬 [AppDelegate] Notification payload: \(notificationPayload)")
            handleNotificationTap(userInfo: notificationPayload)
        } else {
            print("🚀 [AppDelegate] Normal app launch (not from notification)")
        }
        
        return true
    }
    
    // Called when app receives device token from APNs
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ [AppDelegate] Registered for remote notifications")
        print("✅ [AppDelegate] Device token: \(tokenString)")
        DeviceTokenManager.shared.setDeviceToken(deviceToken)
    }
    
    // Called if registration for remote notifications fails
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ [AppDelegate] Failed to register for remote notifications")
        print("❌ [AppDelegate] Error: \(error.localizedDescription)")
        // Mark registration as complete so app doesn't wait
        DeviceTokenManager.shared.setRegistrationFailed()
    }
    
    // Called when app receives a remote notification
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📬 [AppDelegate] didReceiveRemoteNotification called")
        print("📬 [AppDelegate] App state: \(application.applicationState.rawValue) (0=active, 1=inactive, 2=background)")
        print("📬 [AppDelegate] Full payload: \(userInfo)")
        
        // Handle the notification payload
        var notificationTitle = "Notification"
        var notificationBody = ""
        
        if let aps = userInfo["aps"] as? [String: Any] {
            print("📬 [AppDelegate] APS payload: \(aps)")
            if let alert = aps["alert"] as? [String: Any] {
                if let title = alert["title"] as? String {
                    notificationTitle = title
                    print("📬 [AppDelegate] Title: \(title)")
                }
                if let body = alert["body"] as? String {
                    notificationBody = body
                    print("📬 [AppDelegate] Body: \(body)")
                }
            } else if let alert = aps["alert"] as? String {
                notificationBody = alert
                print("📬 [AppDelegate] Alert string: \(alert)")
            }
        } else {
            print("⚠️ [AppDelegate] No APS data in payload")
        }
        
        // If app is in foreground, show an in-app notification banner
        DispatchQueue.main.async {
            if application.applicationState == .active {
                // Show in-app banner notification
                NotificationCenter.default.post(
                    name: NSNotification.Name("InAppNotificationReceived"),
                    object: nil,
                    userInfo: [
                        "title": notificationTitle,
                        "body": notificationBody,
                        "fullPayload": userInfo
                    ]
                )
                
                // Also navigate to notifications
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToNotifications"),
                    object: nil
                )
            }
        }
        
        // Handle notification tap with deep linking and session ID
        // handleNotificationTap(userInfo: userInfo)
        
        completionHandler(.newData)
    }
    
    // Handle notification tap with auto-login and deep linking
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        print("🔗 [AppDelegate] handleNotificationTap called")
        print("🔗 [AppDelegate] User info: \(userInfo)")
        
        // Extract session ID for auto-login
        if let sessionId = userInfo["sessionId"] as? String {
            print("🔗 [AppDelegate] Found session ID: \(sessionId)")
            DispatchQueue.main.async {
                SessionManager.shared.sessionId = sessionId
                print("🔗 [AppDelegate] Set SessionManager.sessionId")
            }
        } else {
            print("🔗 [AppDelegate] No session ID in notification")
        }
        
        // Extract deep link information
        if let deepLinkType = userInfo["deepLinkType"] as? String,
           let deepLinkId = userInfo["deepLinkId"] as? String {
            print("🔗 [AppDelegate] Deep link found - Type: \(deepLinkType), ID: \(deepLinkId)")
            
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
                print("🔗 [AppDelegate] Posted DeepLinkNotification")
            }
        } else {
            print("🔗 [AppDelegate] No deep link info in notification")
        }
    }
    // Called when a notification is received while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 [AppDelegate] willPresent notification called (app in foreground)")
        print("🔔 [AppDelegate] Notification title: \(notification.request.content.title)")
        print("🔔 [AppDelegate] Notification body: \(notification.request.content.body)")
        print("🔔 [AppDelegate] User info: \(notification.request.content.userInfo)")
        
        // Navigate to notifications view and show the message there
        DispatchQueue.main.async {
            print("📱 [AppDelegate] Posting NavigateToNotifications and InAppNotificationReceived")
            
            // Tell the app to navigate to notifications view
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToNotifications"),
                object: nil
            )
            
            // Post the notification data for the notifications view to display
            NotificationCenter.default.post(
                name: NSNotification.Name("InAppNotificationReceived"),
                object: nil,
                userInfo: [
                    "title": notification.request.content.title,
                    "body": notification.request.content.body,
                    "fullPayload": notification.request.content.userInfo
                ]
            )
        }
        
        // Don't show banner - handle it in-app instead
        print("🔔 [AppDelegate] Not showing banner - navigating to notifications view instead")
        completionHandler([])
    }
    
    // Called when user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👆 [AppDelegate] User tapped notification")
        print("👆 [AppDelegate] Action identifier: \(response.actionIdentifier)")
        let userInfo = response.notification.request.content.userInfo
        print("👆 [AppDelegate] Notification user info: \(userInfo)")
        
        // Navigate to notifications view
        DispatchQueue.main.async {
            print("📱 [AppDelegate] Posting NavigateToNotifications")
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToNotifications"),
                object: nil
            )
        }
        
        // Handle notification tap with auto-login and deep linking
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
}
