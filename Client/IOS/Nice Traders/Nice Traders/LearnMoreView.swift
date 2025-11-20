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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack(spacing: 12) {
                        Text("💱")
                            .font(.system(size: 64))
                        
                        Text("How Nice Traders Works")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("The smart way to exchange currency locally")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 40)
                }
                .frame(maxWidth: .infinity)
                
                // Content
                VStack(alignment: .leading, spacing: 32) {
                    // Introduction
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What is Nice Traders?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        Text("Nice Traders is a peer-to-peer platform that connects travelers and locals who want to exchange foreign currency. Instead of paying high fees at banks or exchange kiosks, you can find someone in your neighborhood who has the currency you need and wants what you have.")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "4a5568"))
                            .lineSpacing(6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    
                    // How It Works Section
                    VStack(alignment: .leading, spacing: 24) {
                        Text("How It Works")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "2d3748"))
                            .padding(.horizontal, 24)
                        
                        ProcessStep(number: "1", icon: "📝", title: "Create Your Listing", description: "Post the currency you have and what you want to exchange it for. Set your location and preferred meeting places.")
                        
                        ProcessStep(number: "2", icon: "🔍", title: "Search & Match", description: "Browse listings from people nearby who have what you need. Filter by currency, location, and amount.")
                        
                        ProcessStep(number: "3", icon: "💬", title: "Connect Securely", description: "Contact other users through our secure messaging system. Discuss exchange rates, amounts, and meeting details.")
                        
                        ProcessStep(number: "4", icon: "🤝", title: "Meet & Exchange", description: "Meet in a safe, public location like a coffee shop or bank lobby. Exchange your currency face-to-face.")
                        
                        ProcessStep(number: "5", icon: "⭐", title: "Rate & Review", description: "Rate your exchange partner to help build trust in the community and guide future users.")
                    }
                    
                    // Benefits Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Why Choose Nice Traders?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "2d3748"))
                            .padding(.horizontal, 24)
                        
                        BenefitCard(icon: "💸", title: "Save Money", description: "Banks and airport kiosks charge 5-15% in fees and markups. With Nice Traders, negotiate rates that work for both parties.", color: Color(hex: "48bb78"))
                        
                        BenefitCard(icon: "⚡", title: "Fast & Convenient", description: "Find currency exchanges happening near you right now. No need to drive to the bank or wait in line at the airport.", color: Color(hex: "4299e1"))
                        
                        BenefitCard(icon: "🌍", title: "Support Your Community", description: "Help fellow travelers while getting the currency you need. Build connections with people in your neighborhood.", color: Color(hex: "9f7aea"))
                        
                        BenefitCard(icon: "🔒", title: "Safe & Transparent", description: "View user ratings, meet in public places, and communicate through our secure platform. Safety is our priority.", color: Color(hex: "ed8936"))
                    }
                    .padding(.bottom, 16)
                    
                    // Safety Guidelines
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Safety First")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "2d3748"))
                            .padding(.horizontal, 24)
                        
                        SafetyTip(icon: "🏦", text: "Always meet in well-lit public places like coffee shops, bank lobbies, or shopping centers")
                        SafetyTip(icon: "👥", text: "Bring a friend if possible, especially for larger exchanges")
                        SafetyTip(icon: "💵", text: "Verify the authenticity of currency before completing the exchange")
                        SafetyTip(icon: "📱", text: "Keep communication on our platform until you've successfully met")
                        SafetyTip(icon: "⏰", text: "Meet during daylight hours when possible")
                        SafetyTip(icon: "🚫", text: "Never share personal financial information or send money in advance")
                    }
                    .padding(.bottom, 16)
                    
                    // Pricing Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How Much Does It Cost?")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "2d3748"))
                            .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            PricingRow(label: "Creating Listings", price: "Free")
                            PricingRow(label: "Searching Listings", price: "Free")
                            PricingRow(label: "Contact Access Fee", price: "$2.00", description: "One-time fee to unlock contact info for each listing")
                            
                            Text("The $2.00 contact fee helps prevent spam and ensures serious exchanges. Once paid, you have unlimited messaging with that person.")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "718096"))
                                .padding(.top, 8)
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
                            Text("Get Started")
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
                        
                        Text("Join thousands of smart travelers saving money on currency exchange")
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
