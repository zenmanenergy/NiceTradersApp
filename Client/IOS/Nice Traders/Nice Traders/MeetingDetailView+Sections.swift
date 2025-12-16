//
//  MeetingDetailView+Sections.swift
//  Nice Traders
//
//  View sections for MeetingDetailView (exchange details, trader info, proposals, etc.)
//

import SwiftUI

extension MeetingDetailView {
    
    @ViewBuilder
    var exchangeDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localizationManager.localize("EXCHANGE_DETAILS"))
                .font(.headline)
                .foregroundColor(Color(hex: "2d3748"))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You bring:")
                            .font(.caption)
                            .foregroundColor(Color(hex: "718096"))
                        Text("$\(formatExchangeAmount(contactData.listing.amount, shouldRound: contactData.listing.willRoundToNearestDollar ?? false)) \(contactData.listing.currency)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2d3748"))
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundColor(Color(hex: "667eea"))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("They bring:")
                            .font(.caption)
                            .foregroundColor(Color(hex: "718096"))
                        Text("\(formatConvertedAmount()) \(contactData.listing.acceptCurrency ?? "")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "2d3748"))
                    }
                }
                .padding()
                .background(Color(hex: "f7fafc"))
                .cornerRadius(8)
            }
            
            // Check if location is accepted
            let locationProposals = meetingProposals.filter { !$0.proposedLocation.isEmpty }
            let hasAcceptedLocation = locationProposals.contains { $0.status == "accepted" }
            
            // Only show these sections if location is NOT accepted
            if !hasAcceptedLocation {
                detailRow(label: "Meeting Preference:", value: contactData.listing.meetingPreference ?? "Not specified")
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationManager.localize("GENERAL_AREA"))
                        .font(.caption)
                        .foregroundColor(Color(hex: "718096"))
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .foregroundColor(Color(hex: "667eea"))
                        Text(contactData.listing.location)
                            .foregroundColor(Color(hex: "2d3748"))
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    var traderInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localizationManager.localize("TRADER_INFORMATION"))
                .font(.headline)
                .foregroundColor(Color(hex: "2d3748"))
            
            Text(contactData.otherUser.firstName + " " + contactData.otherUser.lastName)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "2d3748"))
            
            HStack(spacing: 4) {
                ForEach(0..<5) { index in
                    Image(systemName: index < Int(contactData.otherUser.rating ?? 0) ? "star.fill" : "star")
                        .foregroundColor(index < Int(contactData.otherUser.rating ?? 0) ? Color(hex: "fbbf24") : Color(hex: "e2e8f0"))
                }
                Text("(\(contactData.otherUser.totalTrades ?? 0) trades)")
                    .font(.caption)
                    .foregroundColor(Color(hex: "718096"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    var timeProposalSection: some View {
        let pendingTimeProposal = meetingProposals.first(where: { 
            !$0.proposedTime.isEmpty && $0.status == "pending"
        })
        
        // Check if both users have paid (time is implicitly accepted when in payment/location phase)
        let userHasPaid = !(userPaidAt?.isEmpty ?? true)
        let otherUserHasPaid = !(otherUserPaidAt?.isEmpty ?? true)
        let bothUsersPaid = userHasPaid && otherUserHasPaid
        
        if (timeAcceptedAt == nil || timeAcceptedAt?.isEmpty ?? true) && !bothUsersPaid {
            // Time not accepted yet AND we haven't moved to payment phase - show proposal/response buttons
            if let pendingTime = pendingTimeProposal, pendingTime.isFromMe {
                // I proposed the time - show waiting/cancel message
                VStack(alignment: .center, spacing: 12) {
                    Text("⏳ Waiting for Acceptance")
                        .font(.headline)
                        .foregroundColor(Color(hex: "f59e0b"))
                    
                    Text("You proposed a meeting time. Waiting for the other trader to accept or counter.")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    if let meeting = currentMeeting {
                        VStack(alignment: .leading, spacing: 8) {
                            detailRow(label: "TIME:", value: formatDateTime(meeting.time))
                        }
                        .padding(12)
                        .background(Color(hex: "fffbeb"))
                        .cornerRadius(8)
                    }
                    
                    Button(action: { rejectExchange() }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Cancel Proposal")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color(hex: "ef4444"))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(hex: "fef3c7"))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else if pendingTimeProposal != nil && !bothUsersPaid {
                // They proposed the time AND we haven't moved to payment phase - show accept/counter/reject buttons
                VStack(alignment: .center, spacing: 12) {
                    Text("Accept this exchange?")
                        .font(.headline)
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    HStack(spacing: 12) {
                        Button(action: { acceptExchange() }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                Text("Accept")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color(hex: "38a169"))
                            .cornerRadius(8)
                        }
                        
                        Button(action: { counterExchange() }) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 14))
                                Text("Counter")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color(hex: "f59e0b"))
                            .cornerRadius(8)
                        }
                    }
                    
                    Button(action: { rejectExchange() }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Reject")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color(hex: "ef4444"))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    var locationProposalSection: some View {
        // Show location proposal UI if:
        // 1. Time is explicitly accepted, OR
        // 2. Both users have paid (implicit time acceptance)
        let timeExplicitlyAccepted = timeAcceptedAt != nil && !(timeAcceptedAt?.isEmpty ?? true)
        let userHasPaid = userPaidAt != nil && !userPaidAt!.isEmpty
        let otherUserHasPaid = otherUserPaidAt != nil && !otherUserPaidAt!.isEmpty
        let bothUsersPaid = userHasPaid && otherUserHasPaid
        let shouldShowLocationSection = timeExplicitlyAccepted || bothUsersPaid
        
        if shouldShowLocationSection {
            let pendingLocationProposal = meetingProposals.first(where: { 
                !$0.proposedLocation.isEmpty && $0.status == "pending"
            })
            let acceptedLocationProposal = meetingProposals.first(where: { 
                !$0.proposedLocation.isEmpty && $0.status == "accepted"
            })
            
            if let acceptedLoc = acceptedLocationProposal {
                // Location has been accepted - show confirmation
                VStack(alignment: .center, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "38a169"))
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Location Confirmed!")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "38a169"))
                            
                            Text(acceptedLoc.proposedLocation)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "2d3748"))
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(hex: "ecfdf5"))
                    .cornerRadius(8)
                    
                    // Meeting time and countdown
                    if let meetingTime = currentMeeting?.time {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                // Meeting Time
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(Color(hex: "667eea"))
                                        .font(.system(size: 14))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Meeting Time")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        Text(DateFormatters.formatCompact(meetingTime))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(hex: "2d3748"))
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Countdown Timer
                                HStack(spacing: 8) {
                                    Image(systemName: "hourglass.bottomhalf.fill")
                                        .foregroundColor(Color(hex: "f97316"))
                                        .font(.system(size: 14))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Time Until")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        Text(countdownText.isEmpty ? "Calculating..." : countdownText)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(hex: "f97316"))
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color(hex: "fafafa"))
                        .cornerRadius(8)
                    }
                    
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(Color(hex: "667eea"))
                        Text("Ready to Meet")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "667eea"))
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("Directions")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(Color(hex: "667eea"))
                    }
                    .padding()
                    .background(Color(hex: "f0f4ff"))
                    .cornerRadius(8)
                    .onTapGesture {
                        activeTab = .location
                    }
                    .contentShape(Rectangle())
                }
                .padding()
                .onAppear {
                    startCountdownTimer(meetingTime: currentMeeting?.time)
                }
                .onDisappear {
                    countdownTimer?.invalidate()
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else if let pendingLoc = pendingLocationProposal {
                VStack(alignment: .center, spacing: 12) {
                    if pendingLoc.isFromMe {
                        Text("⏳ Waiting for Location Approval")
                            .font(.headline)
                            .foregroundColor(Color(hex: "f59e0b"))
                        
                        Text("You proposed a meeting location. Waiting for the other trader to accept or counter.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "4a5568"))
                        
                        VStack(spacing: 8) {
                            Button(action: { activeTab = .location }) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 14))
                                    Text("View Details")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color(hex: "667eea"))
                                .cornerRadius(8)
                            }
                            
                            Button(action: { cancelPendingLocationProposal() }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Cancel Location")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color(hex: "ef4444"))
                                .cornerRadius(8)
                            }
                        }
                    } else {
                        Text("Accept location?")
                            .font(.headline)
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        HStack(spacing: 12) {
                            Button(action: { acceptLocationProposal(proposalId: pendingLoc.proposalId) }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Accept")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color(hex: "38a169"))
                                .cornerRadius(8)
                            }
                            
                            Button(action: { 
                                counterLocationProposal(proposalId: pendingLoc.proposalId)
                                activeTab = .location
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 14))
                                    Text("Counter")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color(hex: "f59e0b"))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else if bothUsersPaid {
                // No pending or accepted location proposal - show button to propose one
                // But only if both users have paid
                VStack(alignment: .center, spacing: 12) {
                    Text("Ready to propose a meeting location?")
                        .font(.headline)
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Button(action: { proposeLocation() }) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .font(.system(size: 14))
                            Text("Propose Location")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color(hex: "667eea"))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    @ViewBuilder
    var paymentTrackingSection: some View {
        // Show payment section if time is accepted but location is not yet accepted AND both haven't paid yet
        if timeAcceptedAt != nil && !(timeAcceptedAt?.isEmpty ?? true) {
            // Check if both users have paid
            let userHasPaid = userPaidAt != nil && !(userPaidAt?.isEmpty ?? true)
            let otherUserHasPaid = otherUserPaidAt != nil && !(otherUserPaidAt?.isEmpty ?? true)
            let bothPaid = userHasPaid && otherUserHasPaid
            
            if !bothPaid && (locationAcceptedAt == nil || locationAcceptedAt?.isEmpty ?? true) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Required")
                        .font(.headline)
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Text("Both users need to pay $2.00 before proceeding to location negotiation.")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "4a5568"))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Your Payment:")
                                .font(.caption)
                                .foregroundColor(Color(hex: "718096"))
                            Spacer()
                            Text(userHasPaid ? "✅ Paid" : "⏳ Pending")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(userHasPaid ? Color(hex: "38a169") : Color(hex: "f59e0b"))
                        }
                        .padding(12)
                        .background(Color(hex: "f7fafc"))
                        .cornerRadius(8)
                        
                        HStack {
                            Text("Other User's Payment:")
                                .font(.caption)
                                .foregroundColor(Color(hex: "718096"))
                            Spacer()
                            Text(otherUserHasPaid ? "✅ Paid" : "⏳ Pending")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(otherUserHasPaid ? Color(hex: "38a169") : Color(hex: "f59e0b"))
                        }
                        .padding(12)
                        .background(Color(hex: "f7fafc"))
                        .cornerRadius(8)
                    }
                    
                    if !userHasPaid {
                        Button(action: { processPayment() }) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 14))
                                Text("Confirm Payment ($2.00)")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color(hex: "667eea"))
                            .cornerRadius(8)
                        }
                    } else if !otherUserHasPaid {
                        HStack {
                            Image(systemName: "hourglass.end")
                                .foregroundColor(Color(hex: "f59e0b"))
                            Text("Awaiting other user's payment...")
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "f59e0b"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "fffbeb"))
                        .cornerRadius(8)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "38a169"))
                            Text("Both payments complete!")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "38a169"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "ecfdf5"))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    @ViewBuilder
    var ratingSection: some View {
        EmptyView()
    }
    
    @ViewBuilder
    var actionButtonsSection: some View {
        // Only show action buttons when both time and location are accepted
        if timeAcceptedAt != nil && locationAcceptedAt != nil {
            VStack(alignment: .center, spacing: 12) {
                // Mark Trade as Complete button
                Button(action: completeExchange) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14))
                        Text("Mark Trade as Complete")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .foregroundColor(.white)
                    .background(Color(hex: "10b981"))
                    .cornerRadius(8)
                }
                
                // Extra spacing to prevent accidental clicks
                Spacer()
                    .frame(height: 24)
                
                // Cancel buttons section
                VStack(spacing: 8) {
                    // Cancel Meeting Time button - only show if time accepted
                    if timeAcceptedAt != nil {
                        Button(action: cancelMeetingTime) {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.badge.xmark.fill")
                                    .font(.system(size: 14))
                                Text("Cancel Meeting Time")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .foregroundColor(.white)
                            .background(Color(hex: "ef4444"))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Cancel Location button - only show if location accepted
                    if locationAcceptedAt != nil {
                        Button(action: cancelLocation) {
                            HStack(spacing: 8) {
                                Image(systemName: "location.slash.fill")
                                    .font(.system(size: 14))
                                Text("Cancel Location")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .foregroundColor(.white)
                            .background(Color(hex: "ef4444"))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    func detailRow(label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color(hex: "718096"))
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(Color(hex: "2d3748"))
        }
    }
    
    func formatDateTime(_ dateString: String) -> String {
        return DateFormatters.formatCompact(dateString)
    }
}
