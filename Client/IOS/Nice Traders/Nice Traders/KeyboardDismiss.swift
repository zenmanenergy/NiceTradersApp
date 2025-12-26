//
//  KeyboardDismiss.swift
//  Nice Traders
//
//  Global keyboard dismissal extension for all views
//

import SwiftUI

#if canImport(UIKit)
import UIKit

extension View {
    /// Adds keyboard dismissal on tap anywhere outside input fields
    func dismissKeyboardOnTap() -> some View {
        self
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension UIApplication {
    /// Hide keyboard when user taps outside an input field
    func hideKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
