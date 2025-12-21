//
//  InAppNotificationBanner.swift
//  Nice Traders
//
//  Created by Steve Nelson on 12/21/25.
//

import SwiftUI

struct InAppNotificationBanner: View {
    @State private var isShowing = false
    @State private var notificationTitle = ""
    @State private var notificationBody = ""
    
    var body: some View {
        VStack {
            if isShowing {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notificationTitle)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(notificationBody)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(12)
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
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    // Auto-dismiss after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
                }
            }
            
            Spacer()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("InAppNotificationReceived"))) { notification in
            print("[InAppNotificationBanner] Received InAppNotificationReceived notification")
            if let userInfo = notification.userInfo {
                let title = userInfo["title"] as? String ?? "Notification"
                let body = userInfo["body"] as? String ?? ""
                
                print("[InAppNotificationBanner] Title: \(title), Body: \(body)")
                
                notificationTitle = title
                notificationBody = body
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = true
                    print("[InAppNotificationBanner] Showing banner")
                }
            } else {
                print("[InAppNotificationBanner] No userInfo in notification")
            }
        }
        .ignoresSafeArea(.all, edges: .top)
    }
}

#Preview {
    InAppNotificationBanner()
}
