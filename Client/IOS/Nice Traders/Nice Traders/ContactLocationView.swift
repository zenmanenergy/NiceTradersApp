//
//  ContactLocationView.swift
//  Nice Traders
//

import SwiftUI
import MapKit
import CoreLocation

struct ContactLocationView: View {
    let contactData: ContactData
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var locationManager = LocationManager()
    
    @Binding var currentMeeting: CurrentMeeting?
    @Binding var meetingProposals: [MeetingProposal]
    var onBackTapped: (() -> Void)?
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var searchText: String = ""
    @State private var searchResults: [MapSearchResult] = []
    @State private var isSearching: Bool = false
    @State private var selectedResultId: String?
    @State private var currentMapSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    
    var body: some View {
        VStack(spacing: 0) {
            // Map at the top
            ZStack {
                Map(position: $cameraPosition) {
                    

                    // Listing location circle
                    MapCircle(
                        center: CLLocationCoordinate2D(
                            latitude: contactData.listing.latitude,
                            longitude: contactData.listing.longitude
                        ),
                        radius: CLLocationDistance(Double(contactData.listing.radius) * 1609.34)
                    )
                    .foregroundStyle(Color.blue.opacity(0.2))
                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                    
                    // Listing pin
                    Annotation("", coordinate: CLLocationCoordinate2D(
                        latitude: contactData.listing.latitude,
                        longitude: contactData.listing.longitude
                    )) {
                        VStack {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                            Text("Listing")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    // User location pin
                    if let userCoord = locationManager.location?.coordinate {
                        Annotation("", coordinate: userCoord) {
                            VStack {
                                Image(systemName: "location.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("You")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    
                    // Search result pins
                    ForEach(searchResults, id: \.id) { result in
                        Annotation("", coordinate: result.coordinate) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(selectedResultId == result.id ? .orange : .purple)
                                Text(result.name)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .frame(height: 300)
                .onAppear {
                    centerMapOnListing()
                }
                
                // Zoom controls - bottom right corner
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        Spacer()
                        VStack(spacing: 8) {
                            Button(action: { zoomIn() }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                            }
                            
                            Button(action: { zoomOut() }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                            }
                        }
                        .padding(12)
                    }
                }
            }
            
            // Search section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search locations in area...", text: $searchText)
                        .onChange(of: searchText) { _ in
                            if !searchText.isEmpty {
                                searchLocations()
                            } else {
                                searchResults = []
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                            selectedResultId = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(Color(hex: "f7fafc"))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "cbd5e0"), lineWidth: 1))
                
                // Search results
                if isSearching {
                    HStack {
                        ProgressView()
                        Text("Searching...")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else if !searchResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Results (\(searchResults.count))")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(searchResults, id: \.id) { result in
                                    SearchResultRow(
                                        result: result,
                                        isSelected: selectedResultId == result.id,
                                        onTap: {
                                            selectedResultId = result.id
                                            centerMapOnResult(result)
                                        }
                                    )
                                }
                            }
                        }
                        .frame(maxHeight: 250)
                    }
                }
            }
            .padding(16)
            .background(Color(hex: "f0f9ff"))
            
            // Bottom content area
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !meetingProposals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Meeting Proposals")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ForEach(meetingProposals, id: \.id) { proposal in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(proposal.proposedLocation)
                                        .fontWeight(.semibold)
                                    Text(proposal.proposedTime)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    if let message = proposal.message {
                                        Text(message)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color(hex: "f7fafc"))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }
    
    private func centerMapOnListing() {
        let listingCoord = CLLocationCoordinate2D(
            latitude: contactData.listing.latitude,
            longitude: contactData.listing.longitude
        )
        
        let radiusKm = Double(contactData.listing.radius) * 1.60934
        let latitudeDelta = max(0.01, (radiusKm * 2.2) / 111.0)
        let longitudeDelta = latitudeDelta
        currentMapSpan = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
        cameraPosition = .region(MKCoordinateRegion(
            center: listingCoord,
            span: currentMapSpan
        ))
    }
    
    private func zoomIn() {
        let listingCoord = CLLocationCoordinate2D(
            latitude: contactData.listing.latitude,
            longitude: contactData.listing.longitude
        )
        var newSpan = currentMapSpan
        newSpan.latitudeDelta *= 0.6
        newSpan.longitudeDelta *= 0.6
        currentMapSpan = newSpan
        cameraPosition = .region(MKCoordinateRegion(center: listingCoord, span: newSpan))
    }
    
    private func zoomOut() {
        let listingCoord = CLLocationCoordinate2D(
            latitude: contactData.listing.latitude,
            longitude: contactData.listing.longitude
        )
        var newSpan = currentMapSpan
        newSpan.latitudeDelta *= 1.5
        newSpan.longitudeDelta *= 1.5
        currentMapSpan = newSpan
        cameraPosition = .region(MKCoordinateRegion(center: listingCoord, span: newSpan))
    }
    
    private func centerMapOnResult(_ result: MapSearchResult) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        cameraPosition = .region(MKCoordinateRegion(center: result.coordinate, span: span))
    }
    
    private func searchLocations() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        searchResults = []
        
        let listingCoord = CLLocationCoordinate2D(
            latitude: contactData.listing.latitude,
            longitude: contactData.listing.longitude
        )
        
        let radiusKm = Double(contactData.listing.radius) * 1.60934
        let region = MKCoordinateRegion(
            center: listingCoord,
            span: MKCoordinateSpan(
                latitudeDelta: (radiusKm * 2) / 111.0,
                longitudeDelta: (radiusKm * 2) / 111.0
            )
        )
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        searchRequest.region = region
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                guard let response = response else { return }
                
                // Filter results to only those within the radius
                let filteredResults = response.mapItems.enumerated().compactMap { index, mapItem -> MapSearchResult? in
                    let distance = haversineDistance(
                        lat1: listingCoord.latitude,
                        lon1: listingCoord.longitude,
                        lat2: mapItem.placemark.coordinate.latitude,
                        lon2: mapItem.placemark.coordinate.longitude
                    )
                    
                    // Only include if within radius (convert km to miles)
                    if distance <= Double(contactData.listing.radius) {
                        return MapSearchResult(
                            id: "\(index)",
                            name: mapItem.name ?? "Unknown",
                            coordinate: mapItem.placemark.coordinate,
                            address: mapItem.placemark.title ?? "",
                            distance: distance
                        )
                    }
                    return nil
                }
                
                searchResults = filteredResults
            }
        }
    }
    
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 3959.0 // Earth's radius in miles
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }
}

struct MapSearchResult: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    let distance: Double?
}

struct SearchResultRow: View {
    let result: MapSearchResult
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    if !result.address.isEmpty {
                        Text(result.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if let distance = result.distance {
                        Text(String(format: "%.1f mi", distance))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(10)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.white)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(
            isSelected ? Color.blue : Color(hex: "e2e8f0"),
            lineWidth: isSelected ? 2 : 1
        ))
        .cornerRadius(8)
        .onTapGesture(perform: onTap)
    }
}
