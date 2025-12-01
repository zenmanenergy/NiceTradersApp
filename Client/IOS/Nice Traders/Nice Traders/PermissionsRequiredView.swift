//
//  PermissionsRequiredView.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/25/25.
//

import SwiftUI
import CoreLocation

struct PermissionsRequiredView: View {
    @ObservedObject var locationManager = UserLocationManager.shared
    @ObservedObject var deviceTokenManager = DeviceTokenManager.shared
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    @State private var notificationPermissionDenied = false
    @State private var locationPermissionDenied = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var notificationsGranted: Bool {
        deviceTokenManager.isNotificationPermissionGranted
    }
    
    var locationGranted: Bool {
        locationManager.authorizationStatus == .authorizedWhenInUse || 
        locationManager.authorizationStatus == .authorizedAlways
    }
    
    var bothPermissionsGranted: Bool {
        notificationsGranted && locationGranted
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                    
                    Text(localizationManager.localize("REQUIRED_PERMISSIONS"))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(localizationManager.localize("REQUIRED_PERMISSIONS_DESC"))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
                
                Spacer()
                
                // Permission Cards
                VStack(spacing: 16) {
                    // Notifications Permission Card
                    PermissionCard(
                        icon: "bell.fill",
                        iconColor: notificationsGranted ? Color.green : Color(red: 0.9, green: 0.24, blue: 0.24),
                        title: localizationManager.localize("PUSH_NOTIFICATIONS"),
                        description: localizationManager.localize("PUSH_NOTIFICATIONS_DESC"),
                        isGranted: notificationsGranted,
                        action: {
                            if !notificationsGranted {
                                deviceTokenManager.requestNotificationPermission()
                            }
                        }
                    )
                    
                    // Location Permission Card
                    PermissionCard(
                        icon: "location.fill",
                        iconColor: locationGranted ? Color.green : Color(red: 0.9, green: 0.24, blue: 0.24),
                        title: localizationManager.localize("LOCATION_ACCESS"),
                        description: localizationManager.localize("LOCATION_ACCESS_DESC"),
                        isGranted: locationGranted,
                        action: {
                            if !locationGranted {
                                locationManager.requestLocation()
                            }
                        }
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Status
                if bothPermissionsGranted {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(localizationManager.localize("ALL_PERMISSIONS_GRANTED"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                } else {
                    VStack(spacing: 8) {
                        Text(localizationManager.localize("BOTH_PERMISSIONS_REQUIRED"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .alert(localizationManager.localize("PERMISSION_DENIED"), isPresented: $showingAlert) {
            Button(localizationManager.localize("OK"), role: .cancel) { }
            Button(localizationManager.localize("SETTINGS"), role: .none) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            print("VIEW: PermissionsRequiredView")
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        return VStack(spacing: 0) {
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(iconColor)
                        
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
                    }
                    
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.green)
                } else {
                    Button(action: action) {
                        Text("Grant")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color(red: 0.4, green: 0.49, blue: 0.92))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isGranted ? Color.green.opacity(0.3) : Color(red: 0.9, green: 0.24, blue: 0.24).opacity(0.2), lineWidth: 2)
            )
        }
    }
}

#Preview {
    PermissionsRequiredView()
}
