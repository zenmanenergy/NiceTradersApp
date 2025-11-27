//
//  ContentView.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @State private var showSignup = false
    @State private var showLogin = false
    @State private var showLearnMore = false
    @State private var isCheckingSession = true
    @State private var navigateToDashboard = false
    @State private var isCheckingPermissions = false
    @State private var showingSplash = true
    @State private var navigationId = UUID()
    
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var locationManager = UserLocationManager.shared
    @ObservedObject var deviceTokenManager = DeviceTokenManager.shared
    
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
    
    var permissionsReadyToProceed: Bool {
        // Just check location - notification registration can happen in background
        locationGranted
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if showingSplash {
                    // Show splash screen while loading
                    SplashScreenView()
                        .onAppear {
                            checkPermissionsAndSession()
                        }
                } else if SessionManager.shared.isLoggedIn {
                    // User is logged in - go to dashboard
                    DashboardView()
                } else {
                    // User not logged in - show landing page
                    ZStack {
                        VStack(spacing: 0) {
                            // Header Section
                            VStack(spacing: 8) {
                                Text(localizationManager.localize("NICE_TRADERS_HEADER"))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(localizationManager.localize("NEIGHBORHOOD_CURRENCY_EXCHANGE"))
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                            }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                        .padding(.bottom, 48)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .ignoresSafeArea()
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                // Hero Section
                                VStack(spacing: 5) {
                                    Text("💱")
                                        .font(.system(size: 64))
                                    
                                    Text(localizationManager.localize("EXCHANGE_CURRENCY_LOCALLY"))
                                        .font(.system(size: 29, weight: .semibold))
                                        .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
                                        .multilineTextAlignment(.center)
                                    
                                    Text(localizationManager.localize("LANDING_PAGE_DESCRIPTION"))
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                                        .lineSpacing(6)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                }
                                .padding(.bottom, 32)
                                
                                // Features Section
                                VStack(spacing: 24) {
                                    FeatureRow(icon: "🗺️", title: localizationManager.localize("FIND_NEARBY"), description: localizationManager.localize("FIND_NEARBY_DESC"))
                                    
                                    FeatureRow(icon: "💰", title: localizationManager.localize("BETTER_RATES"), description: localizationManager.localize("BETTER_RATES_DESC"))
                                    
                                    FeatureRow(icon: "🛡️", title: localizationManager.localize("SAFE_EXCHANGES"), description: localizationManager.localize("SAFE_EXCHANGES_DESC"))
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 32)
                                
                                // CTA Section
                                VStack(spacing: 16) {
                                    Button(action: {
                                        showSignup = true
                                    }) {
                                        Text(localizationManager.localize("GET_STARTED"))
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .cornerRadius(12)
                                            .shadow(color: Color(red: 0.4, green: 0.49, blue: 0.92).opacity(0.4), radius: 15, y: 4)
                                    }
                                    
                                    Button(action: {
                                        showLearnMore = true
                                    }) {
                                        Text(localizationManager.localize("LEARN_MORE"))
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(red: 0.4, green: 0.49, blue: 0.92), lineWidth: 2)
                                            )
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 32)
                                
                                // Footer
                                VStack {
                                    Text(localizationManager.localize("LANDING_FOOTER"))
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 24)
                                    
                                    HStack(spacing: 4) {
                                        Text(localizationManager.localize("ALREADY_HAVE_ACCOUNT"))
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                                        
                                        Button(action: {
                                            showLogin = true
                                        }) {
                                            Text(localizationManager.localize("SIGN_IN"))
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                                        }
                                    }
                                    .padding(.bottom, 24)
                                }
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 0.97, green: 0.98, blue: 0.99))
                            }
                        }
                        .background(Color.white)
                        .background(Color.blue.opacity(0.3))
                        .offset(y: -50)
                    }
                    
                    // Language selector overlay - absolutely positioned in upper right
                    VStack {
                        HStack {
                            Spacer()
                            LanguageFlagSelector()
                                .padding(.top, 12)
                                .padding(.trailing, 16)
                        }
                        Spacer()
                    }
                    }  // Close ZStack
                }
            }
            .navigationDestination(isPresented: $showSignup) {
                SignupView()
            }
            .navigationDestination(isPresented: $showLogin) {
                LoginView()
            }
            .navigationDestination(isPresented: $showLearnMore) {
                LearnMoreView()
            }
        }
        .id(navigationId)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LogoutUser"))) { _ in
            // Clear session
            SessionManager.shared.logout()
            
            // Reset all navigation state
            showSignup = false
            showLogin = false
            showLearnMore = false
            navigateToDashboard = false
            isCheckingSession = false
            showingSplash = false // Don't show splash on logout
            
            // Force NavigationStack to reset and return to landing page
            navigationId = UUID()
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    func checkPermissionsAndSession() {
        // Skip permission waiting - just proceed directly to session check
        // Permissions can be requested/granted later when needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isCheckingSession = true
            checkExistingSession()
        }
    }
    
    func checkExistingSession() {
        SessionManager.shared.verifySession { isValid in
            if isValid {
                // Session is valid and permissions are granted, go to dashboard
                navigateToDashboard = true
            }
            isCheckingSession = false
            showingSplash = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(icon)
                .font(.system(size: 32))
                .frame(width: 48, alignment: .center)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(red: 0.97, green: 0.98, blue: 0.99))
        .cornerRadius(12)
        .overlay(
            Rectangle()
                .fill(Color(red: 0.4, green: 0.49, blue: 0.92))
                .frame(width: 4)
                .cornerRadius(2),
            alignment: .leading
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
