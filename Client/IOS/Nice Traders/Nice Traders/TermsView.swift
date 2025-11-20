//
//  TermsView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/20/25.
//

import SwiftUI

struct TermsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            ScrollView {
                VStack(spacing: 0) {
                    // Intro Section
                    introSection
                    
                    // Terms Content
                    termsContent
                    
                    // Acceptance Section
                    acceptanceSection
                }
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
    
    // MARK: - Header View
    var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Text("Terms of Service")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Spacer to balance layout
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - Intro Section
    var introSection: some View {
        VStack(spacing: 8) {
            Text("NICE Traders")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("Neighborhood International Currency Exchange")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
            
            Text("Effective Date: November 15, 2025")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .italic()
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Terms Content
    var termsContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Section 1
            termsSection(
                number: "1",
                title: "Acceptance of Terms",
                content: "By accessing and using NICE Traders (\"the Service\"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service."
            )
            
            // Section 2
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(number: "2", title: "Description of Service")
                
                termsText("NICE Traders is a peer-to-peer platform that connects individuals who want to exchange foreign currency in person within their local communities. The Service:")
                
                bulletPoint("Allows users to list foreign currency they wish to exchange")
                bulletPoint("Enables users to search for available currency exchanges nearby")
                bulletPoint("Facilitates communication between users through our messaging system")
                bulletPoint("Provides a rating system for user safety and trust")
                bulletPoint("Charges a $1 fee per person for each exchange transaction")
            }
            
            // Section 3
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(number: "3", title: "User Responsibilities")
                
                termsText("As a user of NICE Traders, you agree to:")
                
                bulletPoint("Provide accurate and truthful information when creating listings")
                bulletPoint("Meet other users only in safe, public locations")
                bulletPoint("Conduct exchanges honestly and fairly")
                bulletPoint("Respect other users and maintain professional conduct")
                bulletPoint("Comply with all applicable local and international laws regarding currency exchange")
                bulletPoint("Not use the Service for money laundering or other illegal activities")
            }
            
            // Section 4
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(number: "4", title: "Safety and Security")
                
                termsText("Your safety is important to us. NICE Traders:")
                
                bulletPoint("Recommends meeting only in well-lit, public places")
                bulletPoint("Provides suggested safe meeting locations")
                bulletPoint("Offers user rating and review systems")
                bulletPoint("Reserves the right to suspend accounts for suspicious activity")
                
                importantBox("NICE Traders is not responsible for the safety of in-person meetings. Users assume all risks associated with meeting other users.")
            }
            
            // Section 5
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(number: "5", title: "Fees and Payments")
                
                termsText("NICE Traders charges a $1 fee per person for each currency exchange transaction. This fee:")
                
                bulletPoint("Is charged when users unlock messaging to communicate")
                bulletPoint("Helps maintain platform security and prevent spam")
                bulletPoint("Is non-refundable once messaging is unlocked")
                bulletPoint("Does not guarantee completion of currency exchange")
            }
            
            // Section 6
            termsSection(
                number: "6",
                title: "Privacy Policy",
                content: "Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your information when you use our Service. By using NICE Traders, you agree to the collection and use of information in accordance with our Privacy Policy."
            )
            
            // Section 7
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(number: "7", title: "Prohibited Uses")
                
                termsText("You may not use NICE Traders for:")
                
                bulletPoint("Any unlawful purpose or to solicit others to perform unlawful acts")
                bulletPoint("Money laundering or other financial crimes")
                bulletPoint("Harassment, abuse, or harm of another person")
                bulletPoint("Creating false or misleading listings")
                bulletPoint("Impersonating another person or entity")
                bulletPoint("Attempting to circumvent our fee structure")
            }
            
            // Section 8
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(number: "8", title: "Limitation of Liability")
                
                termsText("NICE Traders provides a platform for users to connect but does not:")
                
                bulletPoint("Guarantee the completion of any currency exchange")
                bulletPoint("Verify the authenticity of currency being exchanged")
                bulletPoint("Take responsibility for disputes between users")
                bulletPoint("Assume liability for losses incurred during exchanges")
                
                termsText("Users engage in currency exchanges at their own risk.")
            }
            
            // Section 9
            termsSection(
                number: "9",
                title: "Account Termination",
                content: "We reserve the right to terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms."
            )
            
            // Section 10
            termsSection(
                number: "10",
                title: "Changes to Terms",
                content: "We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If revisions are material, we will try to provide at least 30 days notice prior to any new terms taking effect."
            )
            
            // Section 11
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(number: "11", title: "Contact Information")
                
                termsText("If you have any questions about these Terms of Service, please contact us at:")
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Email:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        Text("support@nicetraders.net")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "4a5568"))
                    }
                    
                    HStack {
                        Text("Website:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        Text("https://nicetraders.net")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "4a5568"))
                    }
                }
                .padding(16)
                .background(Color(hex: "f7fafc"))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }
    
    // MARK: - Acceptance Section
    var acceptanceSection: some View {
        VStack {
            Text("By creating an account with NICE Traders, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .padding(24)
                .background(Color(hex: "e6fffa"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "38b2ac"), lineWidth: 2)
                )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    // MARK: - Helper Views
    func termsSection(number: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(number: number, title: title)
            termsText(content)
        }
    }
    
    func sectionHeader(number: String, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(number). \(title)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            Rectangle()
                .fill(Color(hex: "e2e8f0"))
                .frame(height: 2)
        }
    }
    
    func termsText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(Color(hex: "4a5568"))
            .lineSpacing(6)
    }
    
    func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("•")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "4a5568"))
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "4a5568"))
                .lineSpacing(6)
        }
    }
    
    func importantBox(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("Important:")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "2d3748"))
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "4a5568"))
                .lineSpacing(6)
        }
        .padding(.top, 8)
    }
}

#Preview {
    TermsView()
}
