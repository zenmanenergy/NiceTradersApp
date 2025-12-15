import SwiftUI

struct LocationProposalCard: View {
    let proposal: MeetingProposal
    let displayStatus: String?
    let meetingTime: String?
    var onAccept: () -> Void
    var onReject: () -> Void
    var onCounterPropose: () -> Void
    
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var countdownText: String = ""
    @State private var countdownTimer: Timer?
    
    var statusColor: Color {
        switch proposal.status {
        case "pending":
            return Color(hex: "fbbf24")
        case "accepted":
            return Color(hex: "10b981")
        case "rejected":
            return Color(hex: "ef4444")
        default:
            return Color.gray
        }
    }
    
    var statusText: String {
        switch proposal.status {
        case "pending":
            return localizationManager.localize("AWAITING_LOCATION_RESPONSE")
        case "accepted":
            return localizationManager.localize("LOCATION_ACCEPTED")
        case "rejected":
            return localizationManager.localize("REJECT_LOCATION")
        default:
            return proposal.status
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(proposal.proposedLocation)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
            }
            
            // Always visible details
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                // Time and Countdown
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localizationManager.localize("MEETING_TIME"))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            
                            if let time = meetingTime {
                                Text(DateFormatters.formatCompact(time))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "2d3748"))
                            } else {
                                Text(DateFormatters.formatCompact(proposal.proposedTime))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "2d3748"))
                            }
                        }
                        
                        Spacer()
                    }
                    
                    // Countdown Timer
                    if !countdownText.isEmpty && proposal.status == "accepted" {
                        HStack(spacing: 8) {
                            Image(systemName: "hourglass.bottomhalf.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "f97316"))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("TIME_UNTIL_MEETING")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "f97316"))
                                    .textCase(.uppercase)
                                
                                Text(countdownText)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "f97316"))
                            }
                            
                            Spacer()
                        }
                    }
                }
                    
                    // Proposer
                    if !proposal.proposer.firstName.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "person")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PROPOSED_BY")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                
                                Text(proposal.proposer.firstName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "2d3748"))
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Message
                    if let message = proposal.message, !message.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MESSAGE")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            
                            Text(message)
                                .font(.caption)
                                .foregroundColor(Color(hex: "4a5568"))
                                .italic()
                        }
                        .padding(8)
                        .background(Color(hex: "f0f9ff"))
                        .cornerRadius(6)
                    }
                    
                    // Action buttons (only if pending and displayStatus indicates we should accept/reject)
                    if proposal.status == "pending" && !proposal.isFromMe && (displayStatus?.contains("Action: Acceptance") ?? false) {
                        HStack(spacing: 8) {
                            Button(action: onReject) {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 12))
                                    Text(localizationManager.localize("REJECT_LOCATION"))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .foregroundColor(.white)
                                .background(Color(hex: "ef4444"))
                                .cornerRadius(6)
                            }
                            
                            Button(action: onAccept) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 12))
                                    Text(localizationManager.localize("ACCEPT_LOCATION"))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .foregroundColor(.white)
                                .background(Color(hex: "10b981"))
                                .cornerRadius(6)
                            }
                        }
                        
                        Button(action: onCounterPropose) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.2.squarepath")
                                    .font(.system(size: 12))
                                Text(localizationManager.localize("COUNTER_PROPOSE_LOCATION"))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .foregroundColor(Color(hex: "667eea"))
                            .background(Color(hex: "f0f4ff"))
                            .cornerRadius(6)
                        }
                    }
                }
        }
        .padding(12)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(
                statusColor.opacity(0.3),
                lineWidth: 1
            )
        )
        .cornerRadius(8)
        .onAppear {
            startCountdownTimer()
        }
        .onDisappear {
            countdownTimer?.invalidate()
            countdownTimer = nil
        }
    }
    
    private func startCountdownTimer() {
        let timeString = meetingTime ?? proposal.proposedTime
        guard let meetingDate = DateFormatters.parseISO8601(timeString) else {
            return
        }
        
        updateCountdown(meetingDate: meetingDate)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            updateCountdown(meetingDate: meetingDate)
        }
    }
    
    private func updateCountdown(meetingDate: Date) {
        let now = Date()
        let timeInterval = meetingDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            countdownText = "Meeting time has arrived"
            return
        }
        
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        let hourText = hours == 1 ? "hour" : "hours"
        let minuteText = minutes == 1 ? "minute" : "minutes"
        
        if hours > 0 {
            countdownText = "\(hours) \(hourText) \(minutes) \(minuteText) until meeting"
        } else {
            countdownText = "\(minutes) \(minuteText) until meeting"
        }
    }
}

#Preview {
    LocationProposalCard(
        proposal: MeetingProposal(
            proposalId: "MPR-test",
            proposedLocation: "Central Park",
            proposedTime: "Dec 6, 2025 at 2:00 PM",
            message: "Great spot for meeting",
            status: "pending",
            isFromMe: false,
            proposer: ProposerInfo(firstName: "John"),
            latitude: 40.7829,
            longitude: -73.9654
        ),
        displayStatus: "🎯 Action: Acceptance",
        meetingTime: "Dec 14, 2025 at 10:00 AM",
        onAccept: {},
        onReject: {},
        onCounterPropose: {}
    )
}
