import SwiftUI

struct DashboardHeader: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    let user: DashboardUserInfo
    @Binding var navigateToProfile: Bool
    @Binding var navigateToMessages: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(user.initials)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(localizationManager.localize("WELCOME")), \(user.firstName)")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Text("⭐ \(user.rating, specifier: "%.1f")")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("\(user.totalExchanges) \(localizationManager.localize("EXCHANGES"))")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            
            Spacer()
            
            Button(action: { navigateToProfile = true }) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
