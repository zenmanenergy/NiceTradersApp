import SwiftUI
import MapKit
import CoreLocation

struct ListingRadiusMapView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    let listingLocation: String
    let listingLatitude: Double
    let listingLongitude: Double
    let radiusKm: Double
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    
    var body: some View {
        ZStack {
            // Map View with radius circle
            Map(position: $cameraPosition) {
                // Listing center point
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: listingLatitude, longitude: listingLongitude)) {
                    VStack {
                        Image(systemName: "location.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        Text(localizationManager.localize("LISTING_LOCATION"))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            .mapStyle(.standard)
            .onAppear {
                setInitialCamera()
            }
            
            // Header
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localize("MEETING_AREA"))
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(String(format: localizationManager.localize("WITHIN_RADIUS_KM"), Int(radiusKm)))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
    
    private func setInitialCamera() {
        let listingCoord = CLLocationCoordinate2D(latitude: listingLatitude, longitude: listingLongitude)
        
        // Calculate span based on radius
        // 1 km ≈ 0.009 degrees latitude
        let latitudeDelta = (radiusKm / 111.0) * 2.5
        let longitudeDelta = latitudeDelta
        
        cameraPosition = .region(MKCoordinateRegion(
            center: listingCoord,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        ))
    }
}

#Preview {
    ListingRadiusMapView(
        listingLocation: "San Francisco, CA",
        listingLatitude: 37.7749,
        listingLongitude: -122.4194,
        radiusKm: 25
    )
}
