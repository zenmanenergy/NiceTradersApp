//
//  PayPalCheckoutView.swift
//  Nice Traders
//
//  Native PayPal Checkout UI using PayPal SDK
//

import SwiftUI
import SafariServices

struct PayPalCheckoutView: View {
    let orderId: String
    let onSuccess: () -> Void
    let onCancel: () -> Void
    let onError: (String) -> Void
    
    @Environment(\.dismiss) var dismiss: DismissAction
    @State var approvalURL: URL?
    @State var isLoading: Bool = true
    
    var body: some View {
        ZStack {
            if let url = approvalURL {
                SafariViewControllerRepresentable(
                    url: url,
                    onDismiss: {
                        dismiss()
                        onCancel()
                    }
                )
                .ignoresSafeArea()
            } else if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading PayPal...")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.top, 12)
                }
            } else {
                VStack {
                    Text("Failed to load PayPal checkout")
                        .foregroundColor(.red)
                    Button("Close") {
                        dismiss()
                        onCancel()
                    }
                }
            }
        }
        .onAppear {
            fetchApprovalURL()
        }
    }
    
    private func fetchApprovalURL() {
        let baseURL = Settings.shared.baseURL
        let urlString = "\(baseURL)/Payments/GetPayPalApprovalURL?orderId=\(orderId)"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                guard let data = data, error == nil else {
                    onError(error?.localizedDescription ?? "Network error")
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let approvalURLString = json["approvalURL"] as? String,
                   let url = URL(string: approvalURLString) {
                    approvalURL = url
                } else {
                    onError("Failed to get approval URL")
                }
            }
        }.resume()
    }
}

// MARK: - SafariViewController Representable

struct SafariViewControllerRepresentable: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true
        
        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.preferredControlTintColor = UIColor(red: 0.4, green: 0.49, blue: 0.92, alpha: 1)
        safariVC.dismissButtonStyle = .close
        
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    PayPalCheckoutView(
        orderId: "test-order-id",
        onSuccess: { print("Success") },
        onCancel: { print("Cancel") },
        onError: { error in print("Error: \(error)") }
    )
}
