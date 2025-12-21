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
        // Suppress known UIKit constraint warnings for keyboard input views
        // These are system-level warnings that don't affect functionality
        // See: https://developer.apple.com/forums/thread/707024
        UserDefaults.standard.set(true, forKey: "UIConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        
        // Initialize device token manager and request notification permissions
        _ = DeviceTokenManager.shared
        
        // Handle notification if app was launched by tapping a notification (app was closed)
        if let notificationPayload = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
            print("[AppDelegate] App launched from notification: \(notificationPayload)")
            processRemoteNotification(notificationPayload)
        }
        
        return true
    }
    
    // Process remote notification (called from both didReceiveRemoteNotification and launchOptions)
    private func processRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        print("[AppDelegate] processRemoteNotification called with: \(userInfo)")
        
        var notificationTitle = "Notification"
        var notificationBody = ""
        
        if let aps = userInfo["aps"] as? [String: Any] {
            if let alert = aps["alert"] as? [String: Any] {
                if let title = alert["title"] as? String {
                    notificationTitle = title
                }
                if let body = alert["body"] as? String {
                    notificationBody = body
                }
            } else if let alert = aps["alert"] as? String {
                notificationBody = alert
            }
        }
        
        // Save to NotificationsManager
        DispatchQueue.main.async {
            let notification = AppNotification(
                title: notificationTitle,
                body: notificationBody
            )
            NotificationsManager.shared.addNotification(notification)
            print("[AppDelegate] Added notification to NotificationsManager: \(notification)")
        }
        
        // Handle deep linking
        handleNotificationTap(userInfo: userInfo)
    }
    
    // Called when app receives device token from APNs
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        DeviceTokenManager.shared.setDeviceToken(deviceToken)
    }
    
    // Called if registration for remote notifications fails
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Mark registration as complete so app doesn't wait
        DeviceTokenManager.shared.setRegistrationFailed()
    }
    
    // Called when app receives a remote notification
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("[AppDelegate] didReceiveRemoteNotification called")
        print("[AppDelegate] userInfo: \(userInfo)")
        
        // Process the notification
        processRemoteNotification(userInfo)
        
        // If app is in foreground, show an in-app notification banner
        DispatchQueue.main.async {
            print("[AppDelegate] Application state: \(application.applicationState.rawValue)")
            if application.applicationState == .active {
                print("[AppDelegate] App is active, posting InAppNotificationReceived")
                // Show in-app banner notification
                NotificationCenter.default.post(
                    name: NSNotification.Name("InAppNotificationReceived"),
                    object: nil,
                    userInfo: userInfo
                )
                
                // Navigate to notifications page
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToNotifications"),
                    object: nil
                )
            }
        }
        
        completionHandler(.newData)
    }
    
    // Handle notification tap with auto-login and deep linking
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Extract session ID for auto-login
        if let sessionId = userInfo["sessionId"] as? String {
            DispatchQueue.main.async {
                SessionManager.shared.sessionId = sessionId
            }
        }
        
        // Extract deep link information
        if let deepLinkType = userInfo["deepLinkType"] as? String,
           let deepLinkId = userInfo["deepLinkId"] as? String {
            
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
