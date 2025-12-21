//
//  NotificationsView.swift
//  Nice Traders
//

import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var notificationsManager = NotificationsManager.shared
    @State private var selectedNotification: AppNotification?
    @State private var navigateToListing = false
    @State private var navigateToNegotiation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }
                    Spacer()
                    
                    if !notificationsManager.notifications.isEmpty {
                        Button(action: { notificationsManager.clearAll() }) {
                            Text("Clear All")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Text("Notifications")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.49, blue: 0.92),
                        Color(red: 0.46, green: 0.29, blue: 0.64)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            if notificationsManager.notifications.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No Notifications")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    Text("You're all caught up!")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxHeight: .infinity)
                .frame(maxWidth: .infinity)
                
                Spacer()
            } else {
                List {
                    ForEach(notificationsManager.notifications) { notification in
                        NotificationRow(notification: notification) {
                            handleNotificationTap(notification)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                notificationsManager.deleteNotification(notification)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            
            BottomNavigation(activeTab: "messages", isContactView: false, contactActiveTab: .constant(nil))
        }
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToListing) {
            if let listingId = selectedNotification?.deepLinkId {
                SearchView(navigateToSearch: .constant(false))
            }
        }
        .navigationDestination(isPresented: $navigateToNegotiation) {
            if let negotiationId = selectedNotification?.deepLinkId {
                NegotiationDetailView(listingId: negotiationId, navigateToNegotiation: .constant(true))
            }
        }
    }
    
    private func handleNotificationTap(_ notification: AppNotification) {
        notificationsManager.markAsRead(notification)
        selectedNotification = notification
        
        // Navigate based on deep link type
        if let deepLinkType = notification.deepLinkType {
            switch deepLinkType {
            case "listing":
                navigateToListing = true
            case "negotiation":
                navigateToNegotiation = true
            default:
                break
            }
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    @ObservedObject var notificationsManager = NotificationsManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(spacing: 0) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                        .frame(width: 32, height: 32)
                        .background(Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.15))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        if !notification.read {
                            Circle()
                                .fill(Color(red: 0.4, green: 0.49, blue: 0.92))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.body)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    Text(formatDate(notification.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(.gray.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(notification.read ? Color.clear : Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.05))
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationsView()
}
