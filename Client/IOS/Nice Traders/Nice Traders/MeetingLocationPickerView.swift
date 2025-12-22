import SwiftUI
import MapKit
import CoreLocation

// Helper struct for search results
struct LocationSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}

struct MeetingLocationPickerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var locationManager = UserLocationManager()
    
    let listingLocation: String  // City/state of the listing
    let listingLatitude: Double
    let listingLongitude: Double
    let radiusKm: Double  // Radius from listing in km
    @Binding var selectedLocation: String
    @Binding var selectedLat: Double?
    @Binding var selectedLng: Double?
    
    @State private var searchText: String = ""
    @State private var searchResults: [LocationSearchResult] = []
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var isSearching: Bool = false
    @State private var selectedPlaceName: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // DEBUG INFO AT TOP
            VStack(alignment: .leading, spacing: 4) {
                Text("DEBUG: selectedCoordinate = \(selectedCoordinate != nil ? "SET" : "NIL")")
                    .font(.caption)
                Text("DEBUG: isSearching = \(isSearching)")
                    .font(.caption)
                Text("DEBUG: searchResults.count = \(searchResults.count)")
                    .font(.caption)
                Text("DEBUG: listingLatitude = \(listingLatitude), listingLongitude = \(listingLongitude)")
                    .font(.caption)
            }
            .padding(8)
            .background(Color.yellow.opacity(0.3))
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Header
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                    
                    Text(localizationManager.localize("SELECT_MEETING_LOCATION"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
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
                
                // Search Bar
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color(hex: "a0aec0"))
                        
                        TextField(
                            localizationManager.localize("SEARCH_LOCATION"),
                            text: $searchText,
                            onEditingChanged: { editing in
                                isSearching = editing
                            }
                        )
                        .onChange(of: searchText) { _ in
                            performSearch()
                        }
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color(hex: "cbd5e0"))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "f7fafc"))
                    .cornerRadius(8)
                    
                    // Info about radius
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "667eea"))
                        
                        Text(String(format: localizationManager.localize("MEETING_WITHIN_RADIUS"), Int(radiusKm)))
                            .font(.caption)
                            .foregroundColor(Color(hex: "667eea"))
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(hex: "f8fafc"))
            }
            
            ZStack {
                // Map View
                if let coordinate = selectedCoordinate {
                    Map(position: $cameraPosition) {
                        // Listing location marker
                        Annotation(
                            localizationManager.localize("LISTING_LOCATION"),
                            coordinate: CLLocationCoordinate2D(latitude: listingLatitude, longitude: listingLongitude)
                        ) {
                            VStack {
                                Image(systemName: "location.fill")
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "667eea"))
                                
                                Text(localizationManager.localize("LISTING"))
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color(hex: "667eea"))
                                    .cornerRadius(4)
                            }
                        }
                        
                        // Search result marker
                        Annotation(
                            selectedPlaceName,
                            coordinate: coordinate
                        ) {
                            VStack {
                                Image(systemName: "location.fill")
                                    .font(.title2)
                                    .foregroundColor(.red)
                                
                                Text(localizationManager.localize("SELECTED"))
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(.red)
                                    .cornerRadius(4)
                            }
                        }
                        
                        // Distance circle (visual representation)
                        MapCircle(
                            center: CLLocationCoordinate2D(latitude: listingLatitude, longitude: listingLongitude),
                            radius: radiusKm * 1000  // Convert km to meters
                        )
                        .stroke(Color.blue, lineWidth: 2)
                    }
                    .mapStyle(.standard)
                    .onAppear {
                        setInitialCamera()
                    }
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "cbd5e0"))
                        
                        Text(localizationManager.localize("SEARCH_FOR_LOCATION"))
                            .font(.headline)
                            .foregroundColor(Color(hex: "4a5568"))
                        
                        Text(localizationManager.localize("SEARCH_HELPS_FIND_MEETING_SPOT"))
                            .font(.caption)
                            .foregroundColor(Color(hex: "a0aec0"))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                // Search Results Overlay
                if isSearching && !searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        List(searchResults) { result in
                            Button(action: {
                                selectPlace(result)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    if !result.subtitle.isEmpty {
                                        Text(result.subtitle)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                    .frame(maxHeight: 300)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .padding()
                    .padding(.bottom, 200)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.keyboard)
            
            // Confirm Button
            if selectedCoordinate != nil {
                Button(action: confirmSelection) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text(localizationManager.localize("CONFIRM_LOCATION"))
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding()
                .background(Color(hex: "f8fafc"))
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            print("DEBUG: MeetingLocationPickerView appeared")
            print("DEBUG: listingLatitude = \(listingLatitude), listingLongitude = \(listingLongitude)")
            print("DEBUG: selectedCoordinate = \(selectedCoordinate != nil ? "SET" : "NIL")")
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            print("DEBUG: Search cleared - searchText is empty")
            return
        }
        
        print("DEBUG: Starting search for '\(searchText)'")
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        // Bias search results to the listing location
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: listingLatitude, longitude: listingLongitude),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("DEBUG: MKLocalSearch error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    searchResults = []
                }
            } else if let response = response {
                print("DEBUG: MKLocalSearch found \(response.mapItems.count) results")
                DispatchQueue.main.async {
                    searchResults = response.mapItems.map { item in
                        print("DEBUG: Result - \(item.name ?? "NO NAME") | \(item.placemark.title ?? "NO TITLE")")
                        return LocationSearchResult(
                            title: item.name ?? "",
                            subtitle: item.placemark.title ?? ""
                        )
                    }
                    print("DEBUG: Updated searchResults to \(searchResults.count) items")
                }
            }
        }
    }
    
    private func selectPlace(_ result: LocationSearchResult) {
        print("DEBUG: selectPlace called with \(result.title)")
        selectedPlaceName = result.title
        isSearching = false
        
        // Geocode the selected place to get coordinates
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(result.title + " " + result.subtitle) { placemarks, error in
            if let error = error {
                print("DEBUG: Geocoding error: \(error.localizedDescription)")
            } else if let placemark = placemarks?.first,
               let location = placemark.location {
                print("DEBUG: Geocoding succeeded - got coordinate \(location.coordinate)")
                DispatchQueue.main.async {
                    selectedCoordinate = location.coordinate
                    selectedLat = location.coordinate.latitude
                    selectedLng = location.coordinate.longitude
                    cameraPosition = .region(MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                    print("DEBUG: Updated selectedCoordinate to \(location.coordinate)")
                }
            } else {
                print("DEBUG: Geocoding returned no placemarks")
            }
        }
    }
    
    private func setInitialCamera() {
        print("DEBUG: setInitialCamera called - listing at \(listingLatitude), \(listingLongitude)")
        let listing = CLLocationCoordinate2D(latitude: listingLatitude, longitude: listingLongitude)
        cameraPosition = .region(MKCoordinateRegion(
            center: listing,
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        ))
    }
    
    private func confirmSelection() {
        if let coordinate = selectedCoordinate, !selectedPlaceName.isEmpty {
            selectedLocation = selectedPlaceName
            selectedLat = coordinate.latitude
            selectedLng = coordinate.longitude
            dismiss()
        }
    }
}

#Preview {
    @State var selectedLocation = ""
    @State var selectedLat: Double? = nil
    @State var selectedLng: Double? = nil
    
    return MeetingLocationPickerView(
        listingLocation: "San Francisco, California",
        listingLatitude: 37.7749,
        listingLongitude: -122.4194,
        radiusKm: 10,
        selectedLocation: $selectedLocation,
        selectedLat: $selectedLat,
        selectedLng: $selectedLng
    )
}
