//
//  RatingModalView.swift
//  Nice Traders
//
//  Modal view for rating a trading partner after completing an exchange
//

import SwiftUI

struct RatingModalView: View {
    @Binding var isPresented: Bool
    let partnerName: String
    let onSubmitRating: (Int, String) -> Void
    
    @State private var selectedRating: Int = 0
    @State private var ratingMessage: String = ""
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("Rate Your Experience")
                    .font(.system(size: 20, weight: .bold))
                Text("How was your exchange with \(partnerName)?")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Star Rating
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { rating in
                        Button(action: {
                            selectedRating = rating
                        }) {
                            Image(systemName: rating <= selectedRating ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundColor(rating <= selectedRating ? Color(hex: "FFD700") : Color.gray.opacity(0.4))
                        }
                    }
                }
                
                if selectedRating > 0 {
                    let ratingText = ["Poor", "Fair", "Good", "Very Good", "Excellent"][selectedRating - 1]
                    Text(ratingText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "667eea"))
                }
            }
            .frame(maxWidth: .infinity)
            
            // Optional Message
            VStack(alignment: .leading, spacing: 8) {
                Text("Optional Feedback")
                    .font(.system(size: 14, weight: .semibold))
                
                TextEditor(text: $ratingMessage)
                    .font(.system(size: 14))
                    .frame(height: 100)
                    .padding(12)
                    .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: submitRating) {
                    Text("Submit Rating")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .foregroundColor(.white)
                        .background(selectedRating > 0 ? Color(hex: "10b981") : Color.gray.opacity(0.4))
                        .cornerRadius(8)
                }
                .disabled(selectedRating == 0)
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Skip for Now")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .foregroundColor(Color(hex: "667eea"))
                        .background(Color(hex: "667eea").opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(24)
        .presentationDetents([.medium])
    }
    
    private func submitRating() {
        onSubmitRating(selectedRating, ratingMessage)
        isPresented = false
    }
}

struct RatingModalView_Previews: PreviewProvider {
    static var previews: some View {
        RatingModalView(
            isPresented: .constant(true),
            partnerName: "John Doe",
            onSubmitRating: { _, _ in }
        )
    }
}
