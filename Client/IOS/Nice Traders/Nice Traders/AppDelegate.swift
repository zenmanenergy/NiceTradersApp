//
//  AppDelegate.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/25/25.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static let shared = AppDelegate()
    var shouldNavigateToNotificationsOnAppLaunch = false
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        fputs("APPDELEGATE_LAUNCHED\n", stderr)
        fflush(stderr)
        print("🚀 [AppDelegate] App launched")
        print("🚀 [AppDelegate] LaunchOptions: \(launchOptions?.keys.map { $0.rawValue } ?? [])")
        
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
            fputs("NOTIFICATION_PAYLOAD_FOUND\n", stderr)
            fflush(stderr)
            print("📬 [AppDelegate] ✅ App launched from notification tap")
            print("📬 [AppDelegate] Notification payload: \(notificationPayload)")
            
            // Extract notification details
            var notificationTitle = "Notification"
            var notificationBody = ""
            var deepLinkType: String?
            var deepLinkId: String?
            
            if let aps = notificationPayload["aps"] as? [String: Any] {
                print("📬 [AppDelegate] Found APS payload")
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
            }
            
            if let linkType = notificationPayload["deepLinkType"] as? String {
                deepLinkType = linkType
                print("📬 [AppDelegate] DeepLinkType: \(linkType)")
            }
            if let linkId = notificationPayload["deepLinkId"] as? String {
                deepLinkId = linkId
                print("📬 [AppDelegate] DeepLinkId: \(linkId)")
            }
            
            // Add the notification to the manager immediately
            DispatchQueue.main.async {
                print("📬 [AppDelegate] Adding notification to NotificationsManager during app launch")
                let appNotification = AppNotification(
                    title: notificationTitle,
                    body: notificationBody,
                    deepLinkType: deepLinkType,
                    deepLinkId: deepLinkId
                )
                NotificationsManager.shared.addNotification(appNotification)
                print("📬 [AppDelegate] ✅ Notification added. Total notifications: \(NotificationsManager.shared.notifications.count)")
                
                // Set flag to navigate to notifications when DashboardView is ready
                print("📬 [AppDelegate] Setting shouldNavigateToNotificationsOnAppLaunch flag to TRUE")
                AppDelegate.shared.shouldNavigateToNotificationsOnAppLaunch = true
                print("📬 [AppDelegate] ✅ Flag set. Current value: \(AppDelegate.shared.shouldNavigateToNotificationsOnAppLaunch)")
                
                // Delay navigation to ensure DashboardView is loaded and observer is set up
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("📬 [AppDelegate] 📤 Posting NavigateToNotifications notification (delayed 1.0s)")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToNotifications"),
                        object: nil
                    )
                }
            }
            
            // Handle any deep linking or session setup
            handleNotificationTap(userInfo: notificationPayload)
        } else {
            fputs("NORMAL_APP_LAUNCH\n", stderr)
            fflush(stderr)
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
        fputs("DIDRECEIVE_CALLED_\(application.applicationState.rawValue)\n", stderr)
        fflush(stderr)
        print("📬 [AppDelegate] Full payload: \(userInfo)")
        
        // Handle the notification payload
        var notificationTitle = "Notification"
        var notificationBody = ""
        var deepLinkType: String?
        var deepLinkId: String?
        
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
        
        // Extract deep link info
        if let linkType = userInfo["deepLinkType"] as? String {
            deepLinkType = linkType
            print("📬 [AppDelegate] Deep link type: \(linkType)")
        }
        if let linkId = userInfo["deepLinkId"] as? String {
            deepLinkId = linkId
            print("📬 [AppDelegate] Deep link ID: \(linkId)")
        }
        
        // Only add notification if app is NOT active (backgrounded)
        // If active, willPresent will handle it instead
        if application.applicationState != .active {
            DispatchQueue.main.async {
                fputs("DIDRECEIVE_ADDING_NOTIFICATION\n", stderr)
                fflush(stderr)
                print("📬 [AppDelegate] App is backgrounded, adding notification to NotificationsManager")
                let appNotification = AppNotification(
                    title: notificationTitle,
                    body: notificationBody,
                    deepLinkType: deepLinkType,
                    deepLinkId: deepLinkId
                )
                NotificationsManager.shared.addNotification(appNotification)
            }
        } else {
            fputs("DIDRECEIVE_SKIPPING_WILLPRESENT_WILL_HANDLE\n", stderr)
            fflush(stderr)
            print("📬 [AppDelegate] App is active, willPresent will handle the notification")
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
        
        let userInfo = notification.request.content.userInfo
        var deepLinkType: String?
        var deepLinkId: String?
        
        // Extract deep link info
        if let linkType = userInfo["deepLinkType"] as? String {
            deepLinkType = linkType
        }
        if let linkId = userInfo["deepLinkId"] as? String {
            deepLinkId = linkId
        }
        
        // Navigate to notifications view and show the message there
        DispatchQueue.main.async {
            fputs("WILLPRESENT_POSTING_NOTIFICATIONS\n", stderr)
            fflush(stderr)
            print("📱 [AppDelegate] willPresent posting InAppNotificationReceived (don't add directly, listener will add)")
            
            // Tell the app to navigate to notifications view
            print("📱 [AppDelegate] Posting NavigateToNotifications and InAppNotificationReceived")
            NotificationCenter.default.post(
                name: NSNotification.Name("NavigateToNotifications"),
                object: nil
            )
            
            // Post the notification data for the notifications view to display
            // The NotificationsManager listener will receive this and call addNotification
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
        fputs("DIDRECEIVE_NOTIFICATION_TAP\n", stderr)
        fflush(stderr)
        print("👆 [AppDelegate] User tapped notification")
        print("👆 [AppDelegate] Action identifier: \(response.actionIdentifier)")
        let userInfo = response.notification.request.content.userInfo
        print("👆 [AppDelegate] Notification user info: \(userInfo)")
        
        let title = response.notification.request.content.title
        let body = response.notification.request.content.body
        var deepLinkType: String?
        var deepLinkId: String?
        
        // Extract deep link info
        if let linkType = userInfo["deepLinkType"] as? String {
            deepLinkType = linkType
        }
        if let linkId = userInfo["deepLinkId"] as? String {
            deepLinkId = linkId
        }
        
        // Navigate to notifications view
        DispatchQueue.main.async {
            print("📱 [AppDelegate] Posting NavigateToNotifications")
            
            // Add notification to manager if not already there
            let appNotification = AppNotification(
                title: title,
                body: body,
                deepLinkType: deepLinkType,
                deepLinkId: deepLinkId
            )
            NotificationsManager.shared.addNotification(appNotification)
            
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
