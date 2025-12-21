//
//  NotificationsManager.swift
//  Nice Traders
//
//  Manages in-app notifications received via APNs
//

import SwiftUI
import Combine

struct AppNotification: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let timestamp: Date
    let deepLinkType: String?
    let deepLinkId: String?
    var read: Bool
    
    init(title: String, body: String, deepLinkType: String? = nil, deepLinkId: String? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.body = body
        self.timestamp = Date()
        self.deepLinkType = deepLinkType
        self.deepLinkId = deepLinkId
        self.read = false
    }
}

class NotificationsManager: ObservableObject {
    static let shared = NotificationsManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    
    private let notificationsKey = "SavedNotifications"
    
    private init() {
        loadNotifications()
        setupNotificationListener()
    }
    
    private func setupNotificationListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("InAppNotificationReceived"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let userInfo = notification.userInfo {
                let title = userInfo["title"] as? String ?? "Notification"
                let body = userInfo["body"] as? String ?? ""
                let deepLinkType = userInfo["deepLinkType"] as? String
                let deepLinkId = userInfo["deepLinkId"] as? String
                
                let appNotification = AppNotification(
                    title: title,
                    body: body,
                    deepLinkType: deepLinkType,
                    deepLinkId: deepLinkId
                )
                
                self?.addNotification(appNotification)
            }
        }
    }
    
    func addNotification(_ notification: AppNotification) {
        DispatchQueue.main.async {
            fputs("ADDNOTIFICATION_CALLED_\(notification.title)\n", stderr)
            fflush(stderr)
            print("🔔 [NotificationsManager] Adding notification: \(notification.title)")
            print("🔔 [NotificationsManager] Before: \(self.notifications.count) notifications")
            self.notifications.insert(notification, at: 0)
            print("🔔 [NotificationsManager] After: \(self.notifications.count) notifications")
            self.updateUnreadCount()
            self.saveNotifications()
        }
    }
    
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            var updatedNotification = notifications[index]
            updatedNotification.read = true
            notifications[index] = updatedNotification
            updateUnreadCount()
            saveNotifications()
        }
    }
    
    func deleteNotification(_ notification: AppNotification) {
        notifications.removeAll { $0.id == notification.id }
        updateUnreadCount()
        saveNotifications()
    }
    
    func clearAll() {
        notifications.removeAll()
        updateUnreadCount()
        saveNotifications()
    }
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.read }.count
    }
    
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: notificationsKey)
        }
    }
    
    private func loadNotifications() {
        if let data = UserDefaults.standard.data(forKey: notificationsKey),
           let decoded = try? JSONDecoder().decode([AppNotification].self, from: data) {
            self.notifications = decoded
            updateUnreadCount()
        }
    }
}
