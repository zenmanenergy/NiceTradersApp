import SwiftUI

struct LoadingView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(localizationManager.localize("LOADING_DASHBOARD"))
                .foregroundColor(.gray)
        }
    }
}

struct ErrorView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    let error: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(localizationManager.localize("ERROR_LOADING_DASHBOARD"))
                .font(.headline)
                .foregroundColor(.red)
            Text(error)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(localizationManager.localize("RETRY"), action: retry)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color(red: 0.4, green: 0.49, blue: 0.92))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
    }
}
