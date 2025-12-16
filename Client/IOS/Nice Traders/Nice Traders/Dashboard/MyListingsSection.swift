import SwiftUI

struct MyListingsSection: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    let listings: [Listing]
    @Binding var navigateToCreateListing: Bool
    var onRefresh: (() -> Void)?
    
    var totalPendingProposals: Int {
        listings.reduce(0) { $0 + $1.pendingLocationProposals }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(localizationManager.localize("MY_ACTIVE_LISTINGS")) (\(listings.count))")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.28))
                
                Spacer()
                
                if totalPendingProposals > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 14))
                        Text("\(totalPendingProposals)")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(10)
                }
            }
            
            if listings.isEmpty {
                EmptyListingsView(navigateToCreateListing: $navigateToCreateListing)
            } else {
                ForEach(listings) { listing in
                    ListingCard(listing: listing, onDelete: {
                        onRefresh?()
                    })
                }
            }
        }
    }
}

struct EmptyListingsView: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    @Binding var navigateToCreateListing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📝")
                .font(.system(size: 48))
            
            Text(localizationManager.localize("NO_ACTIVE_LISTINGS"))
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Button(localizationManager.localize("CREATE_FIRST_LISTING")) {
                navigateToCreateListing = true
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(red: 0.4, green: 0.49, blue: 0.92))
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 2)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
        )
    }
}

struct ListingCard: View {
    @ObservedObject var localizationManager = LocalizationManager.shared
    let listing: Listing
    @State private var showEditListing = false
    @State private var convertedAmount: Double? = nil
    var onDelete: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("\(listing.haveAmount, specifier: "%.0f") \(listing.haveCurrency)")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("→")
                        .foregroundColor(Color(red: 0.4, green: 0.49, blue: 0.92))
                    
                    if let converted = convertedAmount {
                        if listing.willRoundToNearestDollar {
                            Text("\(String(format: "%.0f", converted)) \(listing.wantCurrency)")
                                .font(.system(size: 14, weight: .semibold))
                        } else {
                            Text("\(String(format: "%.2f", converted)) \(listing.wantCurrency)")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    } else {
                        Text(listing.wantCurrency)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                
                Spacer()
                
                VStack(spacing: 6) {
                    Text(localizationManager.localize("ACTIVE"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(12)
                    
                    if listing.pendingLocationProposals > 0 {
                        Text("📍 \(listing.pendingLocationProposals) Proposal\(listing.pendingLocationProposals != 1 ? "s" : "")")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                }
            }
            
            HStack(spacing: 16) {
                Label("\(listing.viewCount)", systemImage: "eye.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Label("\(listing.contactCount)", systemImage: "message.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Label("\(listing.radius)mi", systemImage: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(red: 0.97, green: 0.98, blue: 0.99))
            .cornerRadius(8)
            
            Button(action: {
                showEditListing = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                    Text(localizationManager.localize("EDIT_LISTING"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 0.4, green: 0.49, blue: 0.92))
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
                .cornerRadius(8)
            }
            .opacity(listing.isPaid || listing.hasBuyer ? 0.5 : 1.0)
            .disabled(listing.isPaid || listing.hasBuyer)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.89, green: 0.91, blue: 0.94), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        .sheet(isPresented: $showEditListing) {
            NavigationView {
                EditListingView(listingId: listing.id)
            }
            .onDisappear {
                onDelete?()
            }
        }
        .onAppear {
            convertedAmount = ExchangeRatesAPI.shared.convertAmountSync(listing.haveAmount, from: listing.haveCurrency, to: listing.wantCurrency)
        }
    }
}
