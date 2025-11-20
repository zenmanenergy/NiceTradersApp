//
//  PrivacyView.swift
//  Nice Traders
//
//  Created by GitHub Copilot on 11/20/25.
//

import SwiftUI

struct PrivacyView: View {
    @Environment(\.dismiss) var dismiss
    @State private var navigateToTerms = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Intro section
                    introSection
                    
                    // Privacy content
                    privacyContent
                    
                    // Cross reference to terms
                    crossReference
                }
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToTerms) {
            TermsView()
                .navigationBarBackButtonHidden(true)
        }
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
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Text("Privacy Policy")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Color.clear.frame(width: 40, height: 40)
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
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .italic()
                .padding(.top, 16)
            
            Text("Last Updated: November 15, 2025")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .italic()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Privacy Content
    var privacyContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Section 1: Information We Collect
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("1. Information We Collect")
                
                Text("NICE Traders collects information to provide a safe and effective currency exchange platform. We collect the following types of information:")
                    .privacyText()
                
                Text("Personal Information You Provide:")
                    .subsectionHeader()
                
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Account Information:", "Name, email address, phone number")
                    bulletPoint("Profile Information:", "Profile photo (optional), user preferences")
                    bulletPoint("Currency Listings:", "Currency type, amounts, location preferences")
                    bulletPoint("Communication Data:", "Messages sent through our platform")
                    bulletPoint("Payment Information:", "Payment method details for our $1 service fee")
                }
                
                Text("Information We Collect Automatically:")
                    .subsectionHeader()
                    .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Location Data:", "Approximate location for matching nearby users")
                    bulletPoint("Device Information:", "Device type, operating system, browser information")
                    bulletPoint("Usage Data:", "How you interact with our app, features used")
                    bulletPoint("Log Data:", "IP address, access times, pages viewed")
                }
            }
            
            // Section 2: How We Use Your Information
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("2. How We Use Your Information")
                
                Text("We use the information we collect to:")
                    .privacyText()
                
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Provide Our Service:", "Connect you with other users for currency exchange")
                    bulletPoint("Location Matching:", "Show you nearby currency exchange opportunities")
                    bulletPoint("Communication:", "Enable messaging between matched users")
                    bulletPoint("Safety & Security:", "Verify users, prevent fraud, and maintain platform safety")
                    bulletPoint("Payment Processing:", "Process our $1 service fee per transaction")
                    bulletPoint("Customer Support:", "Respond to your questions and provide assistance")
                    bulletPoint("Service Improvement:", "Analyze usage patterns to improve our platform")
                    bulletPoint("Legal Compliance:", "Comply with applicable laws and regulations")
                }
            }
            
            // Section 3: Information Sharing
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("3. Information Sharing and Disclosure")
                
                Text("We respect your privacy and limit information sharing. We may share your information:")
                    .privacyText()
                
                Text("With Other Users:")
                    .subsectionHeader()
                
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("", "Basic profile information (name, rating) when you connect for exchanges")
                    bulletPoint("", "Messages you send through our platform")
                    bulletPoint("", "Your general location area (not exact address)")
                }
                
                Text("With Service Providers:")
                    .subsectionHeader()
                    .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("", "Payment processors for handling service fees")
                    bulletPoint("", "Cloud storage providers for data hosting")
                    bulletPoint("", "Analytics services to improve our platform")
                }
                
                Text("For Legal Reasons:")
                    .subsectionHeader()
                    .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("", "When required by law or legal process")
                    bulletPoint("", "To protect our rights, property, or safety")
                    bulletPoint("", "To prevent fraud or illegal activity")
                    bulletPoint("", "In connection with investigations by law enforcement")
                }
            }
            
            // Section 4: Location Information
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("4. Location Information")
                
                Text("Location data is essential for NICE Traders functionality:")
                    .privacyText()
                
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Purpose:", "To show you nearby currency exchange opportunities")
                    bulletPoint("Precision:", "We use approximate location (city/neighborhood level)")
                    bulletPoint("Control:", "You can disable location sharing in your device settings")
                    bulletPoint("Storage:", "Location data is stored securely and not shared with third parties")
                }
                
                infoBox("Note: Disabling location sharing may limit your ability to find nearby exchanges.")
            }
            
            // Section 5: Data Security
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("5. Data Security")
                
                Text("We implement security measures to protect your information:")
                    .privacyText()
                
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Encryption:", "Data is encrypted in transit and at rest")
                    bulletPoint("Access Controls:", "Limited employee access on a need-to-know basis")
                    bulletPoint("Regular Audits:", "Security practices are regularly reviewed and updated")
                    bulletPoint("Secure Infrastructure:", "We use industry-standard hosting and security services")
                }
                
                Text("However, no method of transmission over the internet is 100% secure. We cannot guarantee absolute security of your information.")
                    .privacyText()
                    .padding(.top, 8)
            }
            
            // Section 6: Data Retention
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("6. Data Retention")
                
                Text("We retain your information for different periods:")
                    .privacyText()
                
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Account Data:", "Until you delete your account")
                    bulletPoint("Transaction Records:", "7 years for legal and tax compliance")
                    bulletPoint("Messages:", "90 days after exchange completion")
                    bulletPoint("Usage Logs:", "12 months for security and analytics")
                }
            }
            
            // Section 7: Your Privacy Rights
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("7. Your Privacy Rights")
                
                Text("You have the following rights regarding your personal information:")
                    .privacyText()
                
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Access:", "Request a copy of your personal information")
                    bulletPoint("Correction:", "Update or correct inaccurate information")
                    bulletPoint("Deletion:", "Request deletion of your account and data")
                    bulletPoint("Portability:", "Request your data in a portable format")
                    bulletPoint("Opt-out:", "Unsubscribe from marketing communications")
                }
                
                Text("To exercise these rights, contact us at privacy@nicetraders.net")
                    .privacyText()
                    .padding(.top, 8)
            }
            
            // Section 8: Children's Privacy
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("8. Children's Privacy")
                
                Text("NICE Traders is not intended for users under 18 years of age. We do not knowingly collect personal information from children under 18. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.")
                    .privacyText()
            }
            
            // Section 9: International Data Transfers
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("9. International Data Transfers")
                
                Text("Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information during international transfers.")
                    .privacyText()
            }
            
            // Section 10: Changes to Privacy Policy
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("10. Changes to This Privacy Policy")
                
                Text("We may update this Privacy Policy from time to time. We will notify you of any material changes by:")
                    .privacyText()
                
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("", "Posting the new Privacy Policy on this page")
                    bulletPoint("", "Sending you an email notification")
                    bulletPoint("", "Providing an in-app notification")
                }
                
                Text("Changes become effective 30 days after posting unless otherwise specified.")
                    .privacyText()
                    .padding(.top, 8)
            }
            
            // Section 11: Contact Us
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("11. Contact Us")
                
                Text("If you have questions about this Privacy Policy or our privacy practices, contact us:")
                    .privacyText()
                
                VStack(alignment: .leading, spacing: 8) {
                    contactInfo("Email:", "privacy@nicetraders.net")
                    contactInfo("Support:", "support@nicetraders.net")
                    contactInfo("Website:", "https://nicetraders.net")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mailing Address:")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "4a5568"))
                        Text("NICE Traders Privacy Team")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "4a5568"))
                        Text("[Address to be added]")
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
    
    // MARK: - Cross Reference
    var crossReference: some View {
        VStack(spacing: 8) {
            Text("Related Documents:")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
            
            HStack(spacing: 4) {
                Text("Read our")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "2d3748"))
                
                Button(action: {
                    navigateToTerms = true
                }) {
                    Text("Terms of Service")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "667eea"))
                        .underline()
                }
                
                Text("for more information about using NICE Traders.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "2d3748"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(hex: "f0fff4"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "68d391"), lineWidth: 2)
        )
        .cornerRadius(12)
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    // MARK: - Helper Views
    func sectionHeader(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(text)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "2d3748"))
                .padding(.bottom, 8)
            
            Rectangle()
                .fill(Color(hex: "e2e8f0"))
                .frame(height: 2)
        }
    }
    
    func bulletPoint(_ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "4a5568"))
                .frame(width: 10, alignment: .leading)
            
            if title.isEmpty {
                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "4a5568"))
                    .lineSpacing(4)
            } else {
                HStack(alignment: .top, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "4a5568"))
                        .lineSpacing(4)
                }
            }
        }
    }
    
    func infoBox(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("Note:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "744210"))
            
            Text(text.replacingOccurrences(of: "Note: ", with: ""))
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "744210"))
                .lineSpacing(4)
        }
        .padding(16)
        .background(Color(hex: "fff5f5"))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "fed7d7"), lineWidth: 1)
        )
        .cornerRadius(8)
        .padding(.top, 8)
    }
    
    func contactInfo(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "4a5568"))
            
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "4a5568"))
        }
    }
}

// MARK: - Text Extensions
extension Text {
    func privacyText() -> some View {
        self
            .font(.system(size: 15))
            .foregroundColor(Color(hex: "4a5568"))
            .lineSpacing(4)
    }
    
    func subsectionHeader() -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color(hex: "4a5568"))
    }
}

#Preview {
    PrivacyView()
}
