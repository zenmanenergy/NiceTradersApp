//
//  ListingMapView.swift
//  Nice Traders
//
//  MapKit integration for displaying currency listings on a map
//  NOTE: Shows approximate locations only - exact locations revealed after purchase
//

import SwiftUI
import MapKit

// MARK: - Listing Identifiable Location
struct ListingLocation: Identifiable {
    let id: String
    let listing: SearchListing
    let coordinate: CLLocationCoordinate2D
    let isApproximate: Bool
    
    init(listing: SearchListing, showExactLocation: Bool = false) {
        self.id = listing.id
        self.listing = listing
        
        // Use exact or approximate coordinates based on meeting time
        if let lat = listing.latitude, let lon = listing.longitude {
            if showExactLocation {
                // Show exact location (within 1 hour of meeting)
                self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                self.isApproximate = false
            } else {
                // Add random offset for approximate location (±0.01 degrees ≈ ±1km)
                let latOffset = Double.random(in: -0.01...0.01)
                let lonOffset = Double.random(in: -0.01...0.01)
                
                self.coordinate = CLLocationCoordinate2D(
                    latitude: lat + latOffset,
                    longitude: lon + lonOffset
                )
                self.isApproximate = true
            }
        } else {
            // Default to 0,0 if no coordinates (should be filtered out before display)
            self.coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            self.isApproximate = true
        }
    }
    
    var isValid: Bool {
        return listing.latitude != nil && listing.longitude != nil
    }
}

// MARK: - Map View
struct ListingMapView: View {
    var listings: [SearchListing]
    var userLocation: CLLocation?
    var showUserLocation: Bool
    @Binding var selectedListing: SearchListing?
    var onListingTapped: ((SearchListing) -> Void)?
    var showExactLocations: Bool = false  // Set to true when within meeting window
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to SF
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    private var listingLocations: [ListingLocation] {
        listings.map { ListingLocation(listing: $0, showExactLocation: showExactLocations) }.filter { $0.isValid }
    }
    
    var body: some View {
        ZStack {
            mapView
            
            // Selected listing callout
            if let selected = selectedListing {
                VStack {
                    Spacer()
                    ListingCalloutView(listing: selected, showExactLocations: showExactLocations)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            updateRegion()
        }
        .onChange(of: listings) {
            updateRegion()
        }
        .onChange(of: userLocation) {
            updateRegion()
        }
    }
    
    private var mapView: some View {
        Map(coordinateRegion: $region,
            showsUserLocation: showUserLocation,
            annotationItems: listingLocations) { location in
            MapAnnotation(coordinate: location.coordinate) {
                ListingMapPin(
                    listing: location.listing,
                    isSelected: selectedListing?.id == location.listing.id,
                    isApproximate: location.isApproximate
                )
                .onTapGesture {
                    withAnimation {
                        selectedListing = location.listing
                    }
                    onListingTapped?(location.listing)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func updateRegion() {
        let validLocations = listingLocations
        guard !validLocations.isEmpty else {
            // If no listings, center on user location
            if let userLoc = userLocation {
                region = MKCoordinateRegion(
                    center: userLoc.coordinate,
                    latitudinalMeters: 5000,
                    longitudinalMeters: 5000
                )
            }
            return
        }
        
        var allCoords = validLocations.map { $0.coordinate }
        
        // Include user location
        if let userLoc = userLocation {
            allCoords.append(userLoc.coordinate)
        }
        
        var minLat = allCoords[0].latitude
        var maxLat = allCoords[0].latitude
        var minLon = allCoords[0].longitude
        var maxLon = allCoords[0].longitude
        
        for coord in allCoords {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let latDelta = max((maxLat - minLat) * 1.3, 0.01) // Add 30% padding
        let lonDelta = max((maxLon - minLon) * 1.3, 0.01)
        
        withAnimation {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
        }
    }
}

// MARK: - Map Pin View
struct ListingMapPin: View {
    let listing: SearchListing
    let isSelected: Bool
    let isApproximate: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Show "~" symbol for approximate locations
            HStack(spacing: 2) {
                if isApproximate {
                    Text("~")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                Text("\(Int(listing.amount))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "764ba2") : Color(hex: "667eea"))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
            
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundColor(isSelected ? Color(hex: "764ba2") : Color(hex: "667eea"))
                .offset(y: -2)
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Callout View
struct ListingCalloutView: View {
    let listing: SearchListing
    var showExactLocations: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(listing.amount)) \(listing.currency)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    Text("Wants \(listing.acceptCurrency)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "667eea"))
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack(spacing: 8) {
                Text("\(listing.user.firstName) \(listing.user.lastName)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "2d3748"))
                
                if listing.user.verified == true {
                    Circle()
                        .fill(Color(hex: "48bb78"))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("⭐")
                        .font(.system(size: 12))
                    Text(String(format: "%.1f", listing.user.rating ?? 0))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "f6ad55"))
                }
            }
            
            // Show approximate location warning (unless showing exact)
            if !showExactLocations {
                HStack(spacing: 8) {
                    Image(systemName: "location.circle")
                        .foregroundColor(Color(hex: "f6ad55"))
                    Text("Approximate area - exact location shared after purchase")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "718096"))
                        .italic()
                }
                .padding(8)
                .background(Color(hex: "fffbeb"))
                .cornerRadius(8)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "48bb78"))
                    Text("Exact location - meeting time confirmed")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "2d3748"))
                        .fontWeight(.medium)
                }
                .padding(8)
                .background(Color(hex: "f0fdf4"))
                .cornerRadius(8)
            }
            
            NavigationLink(destination: ContactPurchaseView(listingId: listing.id)) {
                Text("Contact Trader")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Preview
#Preview {
    ListingMapView(
        listings: [],
        userLocation: CLLocation(latitude: 37.7749, longitude: -122.4194),
        showUserLocation: true,
        selectedListing: .constant(nil as SearchListing?)
    )
    .environmentObject(LocationManager())
}
