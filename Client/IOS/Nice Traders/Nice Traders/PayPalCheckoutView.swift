//
//  PayPalCheckoutView.swift
//  Nice Traders
//
//  Native PayPal Checkout UI using PayPal Checkout SDK
//

import SwiftUI
import PayPalWebPayments
import CorePayments

struct PayPalCheckoutView: View {
    let orderId: String
    let onSuccess: () -> Void
    let onCancel: () -> Void
    let onError: (String) -> Void
    
    @Environment(\.dismiss) var dismiss: DismissAction
    @State var checkoutViewController: PayPalWebCheckoutViewController?
    
    var body: some View {
        ZStack {
            PayPalCheckoutViewControllerRepresentable(
                orderId: orderId,
                onSuccess: {
                    dismiss()
                    onSuccess()
                },
                onCancel: {
                    dismiss()
                    onCancel()
                },
                onError: { error in
                    dismiss()
                    onError(error)
                }
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - UIViewControllerRepresentable for PayPal Checkout

struct PayPalCheckoutViewControllerRepresentable: UIViewControllerRepresentable {
    let orderId: String
    let onSuccess: () -> Void
    let onCancel: () -> Void
    let onError: (String) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let checkoutController = PayPalWebCheckoutViewController(
            orderID: orderId,
            fundingSource: .paypal,
            createOrderCallback: nil,
            onApprove: { approval in
                print("[PayPal] Order approved: \(approval.orderID)")
                onSuccess()
            },
            onShippingChange: nil,
            onError: { error in
                print("[PayPal] Checkout error: \(error.description)")
                onError(error.description)
            },
            onCancel: {
                print("[PayPal] Checkout cancelled")
                onCancel()
            }
        )
        
        return checkoutController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    PayPalCheckoutView(
        orderId: "test-order-id",
        onSuccess: { print("Success") },
        onCancel: { print("Cancel") },
        onError: { error in print("Error: \(error)") }
    )
}
