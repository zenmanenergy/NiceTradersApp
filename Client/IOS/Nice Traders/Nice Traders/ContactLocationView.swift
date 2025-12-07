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
        let latitudeDelta = max(0.01, (radiusKm * 3) / 111.0)
        let longitudeDelta = latitudeDelta
        
        cameraPosition = .region(MKCoordinateRegion(
            center: listingCoord,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        ))
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
                
                searchResults = response.mapItems.enumerated().map { index, mapItem in
                    MapSearchResult(
                        id: "\(index)",
                        name: mapItem.name ?? "Unknown",
                        coordinate: mapItem.placemark.coordinate,
                        address: mapItem.placemark.title ?? ""
                    )
                }
            }
        }
    }
}

struct MapSearchResult: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
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
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
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
