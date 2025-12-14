import SwiftUI

struct PendingNegotiationsSection: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    let negotiations: [PendingNegotiation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("⏰ Pending Proposals (\(negotiations.count))")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let badgeText = getPendingBadgeText() {
                    Text(badgeText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(badgeText == "ACTION REQUIRED" ? Color.orange : Color.blue)
                        .cornerRadius(12)
                }
            }
            
            ForEach(negotiations) { negotiation in
                NavigationLink(destination: NegotiationDetailView(listingId: negotiation.id, navigateToNegotiation: .constant(false))) {
                    PendingNegotiationCard(negotiation: negotiation)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    private func getPendingBadgeText() -> String? {
        let hasActionRequired = negotiations.contains { $0.actionRequired }
        let hasPaidPartial = negotiations.contains { $0.status == "paid_partial" }
        
        if hasActionRequired {
            return "ACTION REQUIRED"
        } else if hasPaidPartial {
            return "AWAITING PAYMENT"
        }
        return nil
    }
}

struct PendingNegotiationCard: View {
    let negotiation: PendingNegotiation
    
    private var statusText: String {
        switch negotiation.status {
        case "negotiating":
            return negotiation.actionRequired ? "🎯 Action Required" : "⏳ Waiting for Acceptance"
        case "agreed":
            return "✅ Payment Required"
        case "paid_partial":
            return "⏳ Awaiting Payment"
        case "paid_complete":
            return "✅ Ready to Meet"
        default:
            return "💬 Review & Respond"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 4) {
                    Text(String(format: negotiation.willRoundToNearestDollar ? "%.0f" : "%.2f", negotiation.amount))
                        .font(.system(size: 18, weight: .bold))
                    Text(negotiation.currency)
                        .font(.system(size: 16, weight: .semibold))
                    Text("→")
                        .font(.system(size: 16, weight: .bold))
                    if let converted = negotiation.convertedAmount {
                        Text(String(format: negotiation.willRoundToNearestDollar ? "%.0f" : "%.2f", converted))
                            .font(.system(size: 18, weight: .bold))
                        Text(negotiation.acceptCurrency)
                            .font(.system(size: 16, weight: .semibold))
                    } else {
                        Text(negotiation.acceptCurrency)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.white.opacity(0.9))
                Text(negotiation.buyerName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.white.opacity(0.9))
                Text(DateFormatters.formatCompact(negotiation.proposedTime))
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            HStack {
                Text(statusText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }
}
