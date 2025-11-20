//
//  ContentView.swift
//  Nice Traders
//
//  Created by Steve Nelson on 11/20/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showSignup = false
    @State private var showLogin = false
    @State private var showLearnMore = false
    @State private var isCheckingSession = true
    @State private var navigateToDashboard = false
    @State private var navigationId = UUID()
    
    var body: some View {
        NavigationStack {
            Group {
                if isCheckingSession {
                    ProgressView("Checking session...")
                        .onAppear {
                            checkExistingSession()
                        }
                } else {
                    ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                VStack(spacing: 8) {
                    Text("NICE Traders")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Neighborhood International Currency Exchange")
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
                .clipShape(RoundedRectangle(cornerRadius: 30))
                
                // Hero Section
                VStack(spacing: 16) {
                    Text("💱")
                        .font(.system(size: 64))
                        .padding(.top, 32)
                    
                    Text("Exchange Currency Locally")
                        .font(.system(size: 29, weight: .semibold))
                        .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
                        .multilineTextAlignment(.center)
                    
                    Text("Connect with neighbors to exchange foreign currency safely and affordably. Skip the expensive fees and get the cash you need from your community.")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
                
                // Features Section
                VStack(spacing: 24) {
                    FeatureRow(icon: "🗺️", title: "Find Nearby", description: "See currency exchanges happening in your neighborhood")
                    
                    FeatureRow(icon: "💰", title: "Better Rates", description: "Avoid high bank and airport exchange fees")
                    
                    FeatureRow(icon: "🛡️", title: "Safe Exchanges", description: "Meet in public places with user ratings for safety")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // CTA Section
                VStack(spacing: 16) {
                    Button(action: {
                        showSignup = true
                    }) {
                        Text("Get Started")
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
                        Text("Learn More")
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
                    Text("Join thousands of travelers saving money on currency exchange")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                    
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.59))
                        
                        Button(action: {
                            showLogin = true
                        }) {
                            Text("Sign In")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                        }
                    }
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.97, green: 0.98, blue: 0.99))
            }
            .background(Color.white)
                    }
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
            .navigationDestination(isPresented: $navigateToDashboard) {
                DashboardView()
            }
        }
        .id(navigationId)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LogoutUser"))) { _ in
            // Reset all navigation state
            showSignup = false
            showLogin = false
            showLearnMore = false
            navigateToDashboard = false
            isCheckingSession = false
            navigationId = UUID() // Force NavigationStack to reset
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    func checkExistingSession() {
        SessionManager.shared.verifySession { isValid in
            if isValid {
                navigateToDashboard = true
            }
            isCheckingSession = false
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

#Preview {
    ContentView()
}
