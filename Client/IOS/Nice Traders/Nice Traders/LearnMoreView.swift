//
//  LearnMoreView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/20/25.
//

import SwiftUI

struct LearnMoreView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showSignup = false
    let localizationManager = LocalizationManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with Back Button
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 0) {
                        // Back Button
                        HStack {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                }
                                .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        // Title Section
                        VStack(spacing: 8) {
                            Text(localizationManager.localize("HOW_NICE_TRADERS_WORKS"))
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(localizationManager.localize("SMART_WAY_EXCHANGE_LOCALLY"))
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Content
                VStack(alignment: .leading, spacing: 32) {
                    // Introduction
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizationManager.localize("WHAT_IS_NICE_TRADERS"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        Text(localizationManager.localize("NICE_TRADERS_DESCRIPTION"))
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "4a5568"))
                            .lineSpacing(6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    
                    // How It Works Section
                    VStack(alignment: .leading, spacing: 24) {
                        Text(localizationManager.localize("HOW_IT_WORKS"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "2d3748"))
                            .padding(.horizontal, 24)
                        
                        ProcessStep(number: "1", icon: "📝", title: localizationManager.localize("CREATE_YOUR_LISTING"), description: localizationManager.localize("CREATE_LISTING_DESCRIPTION"))
                        
                        ProcessStep(number: "2", icon: "🔍", title: localizationManager.localize("SEARCH_AND_MATCH"), description: localizationManager.localize("SEARCH_LISTING_DESCRIPTION"))
                        
                        ProcessStep(number: "3", icon: "💬", title: localizationManager.localize("CONNECT_SECURELY"), description: localizationManager.localize("CONNECT_DESCRIPTION"))
                        
                        ProcessStep(number: "4", icon: "🤝", title: localizationManager.localize("MEET_AND_EXCHANGE"), description: localizationManager.localize("MEET_DESCRIPTION"))
                        
                        ProcessStep(number: "5", icon: "⭐", title: localizationManager.localize("RATE_AND_REVIEW"), description: localizationManager.localize("RATE_DESCRIPTION"))
                    }
                    
                    // Benefits Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localizationManager.localize("WHY_CHOOSE_NICE_TRADERS"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "2d3748"))
                            .padding(.horizontal, 24)
                        
                        BenefitCard(icon: "💸", title: localizationManager.localize("SAVE_MONEY"), description: localizationManager.localize("SAVE_MONEY_DESCRIPTION"), color: Color(hex: "48bb78"))
                        
                        BenefitCard(icon: "⚡", title: localizationManager.localize("FAST_AND_CONVENIENT"), description: localizationManager.localize("FAST_DESCRIPTION"), color: Color(hex: "4299e1"))
                        
                        BenefitCard(icon: "🌍", title: localizationManager.localize("SUPPORT_YOUR_COMMUNITY"), description: localizationManager.localize("COMMUNITY_DESCRIPTION"), color: Color(hex: "9f7aea"))
                        
                        BenefitCard(icon: "🔒", title: localizationManager.localize("SAFE_AND_TRANSPARENT"), description: localizationManager.localize("SAFE_DESCRIPTION"), color: Color(hex: "ed8936"))
                    }
                    .padding(.bottom, 16)
                    
                    // Safety Guidelines
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localizationManager.localize("SAFETY_FIRST"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "2d3748"))
                            .padding(.horizontal, 24)
                        
                        SafetyTip(icon: "🏦", text: localizationManager.localize("MEET_PUBLIC_PLACES"))
                        SafetyTip(icon: "👥", text: localizationManager.localize("BRING_A_FRIEND"))
                        SafetyTip(icon: "💵", text: localizationManager.localize("VERIFY_CURRENCY"))
                        SafetyTip(icon: "📱", text: localizationManager.localize("KEEP_COMMUNICATION"))
                        SafetyTip(icon: "⏰", text: localizationManager.localize("MEET_DAYLIGHT"))
                        SafetyTip(icon: "🚫", text: localizationManager.localize("NO_FINANCIAL_INFO"))
                    }
                    .padding(.bottom, 16)
                    
                    // Pricing Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text(localizationManager.localize("HOW_MUCH_DOES_IT_COST"))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "2d3748"))
                            .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            PricingRow(label: localizationManager.localize("CREATING_LISTINGS"), price: localizationManager.localize("FREE"))
                            PricingRow(label: localizationManager.localize("SEARCHING_LISTINGS"), price: localizationManager.localize("FREE"))
                        }
                        .padding(16)
                        .background(Color(hex: "f7fafc"))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }
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
                                        gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color(hex: "667eea").opacity(0.4), radius: 15, y: 4)
                        }
                        
                        Text(localizationManager.localize("CTA_TAGLINE"))
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "718096"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("VIEW: LearnMoreView")
        }
        .navigationDestination(isPresented: $showSignup) {
            SignupView()
        }
    }
}

// MARK: - Supporting Views

struct ProcessStep: View {
    let number: String
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Text(number)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(icon)
                        .font(.system(size: 24))
                    
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "2d3748"))
                }
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "4a5568"))
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 24)
    }
}

struct BenefitCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(icon)
                .font(.system(size: 32))
                .frame(width: 48, alignment: .center)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "4a5568"))
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(12)
        .shadow(color: color.opacity(0.1), radius: 8, y: 2)
        .padding(.horizontal, 24)
    }
}

struct SafetyTip: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 20))
                .frame(width: 32, alignment: .center)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "4a5568"))
                .lineSpacing(4)
        }
        .padding(.horizontal, 24)
    }
}

struct PricingRow: View {
    let label: String
    let price: String
    var description: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Spacer()
                
                Text(price)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "667eea"))
            }
            
            if let description = description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "718096"))
            }
        }
    }
}

#Preview {
    LearnMoreView()
}
