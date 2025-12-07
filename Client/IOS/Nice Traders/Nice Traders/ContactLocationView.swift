//
//  ContactLocationView.swift
//  Nice Traders
//
//  Location and meeting coordination view for contacts
//

import SwiftUI
import MapKit
import CoreLocation

struct ContactLocationView: View {
    let contactData: ContactData
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var locationManager = LocationManager()
    
    // Bindings from parent view
    @Binding var currentMeeting: CurrentMeeting?
    @Binding var meetingProposals: [MeetingProposal]
    var onBackTapped: (() -> Void)?
    
    @State var showProposeForm: Bool = false
    @State var proposedLocation: String = ""
    @State var proposedLocationLat: Double? = nil
    @State var proposedLocationLng: Double? = nil
    @State var proposedDate: Date = Date()
    @State var proposedTime: Date = Date()
    @State var proposalMessage: String = ""
    @State var isLoading: Bool = false
    @State var errorMessage: String?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var noCameraPosition: MapCameraPosition = .automatic
    @State private var currentMainMapSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    @State private var currentMeetingMapSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    
    // Search functionality
    @State private var searchText: String = ""
    @State private var nearbyListings: [NearbyListing] = []
    @State private var selectedListingId: String? = nil
    @State private var isSearching: Bool = false
    @State private var searchError: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Map showing listing location
            ZStack {
                Map(position: $cameraPosition) {
                    // Radius circle around listing
                    MapCircle(center: CLLocationCoordinate2D(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude), radius: CLLocationDistance(Double(contactData.listing.radius) * 1609.34))
                        .foregroundStyle(Color.blue.opacity(0.2))
                        .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                    
                    // Listing location pin
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude)) {
                        VStack {
                            Image(systemName: "location.fill")
                                .font(.title)
                                .foregroundColor(.red)
                            
                            Text(localizationManager.localize("LISTING_LOCATION"))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    // User current location
                    if let userLocation = locationManager.location?.coordinate {
                        Annotation("", coordinate: userLocation) {
                            VStack {
                                Image(systemName: "location.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                
                                Text(localizationManager.localize("YOUR_LOCATION"))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .frame(height: 250)
                .cornerRadius(0)
                .onAppear {
                    setInitialCamera()
                }
                
                // Zoom controls - bottom right corner
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        Spacer()
                        VStack(spacing: 8) {
                            Button(action: { zoomInOnMainMap() }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                            }
                            
                            Button(action: { zoomOutOnMainMap() }) {
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
            .padding(.bottom, 16)
            
            // Content wrapper with padding
            VStack(alignment: .leading, spacing: 16) {
                // Current Meeting box removed - giving full space to search results
                
                // Map showing meeting radius and user location
                ZStack {
                            Map(position: $noCameraPosition) {
                                // Radius circle around listing
                                MapCircle(center: CLLocationCoordinate2D(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude), radius: CLLocationDistance(Double(contactData.listing.radius) * 1609.34))
                                    .foregroundStyle(Color.blue.opacity(0.2))
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                                
                                // Listing location pin
                                Annotation("", coordinate: CLLocationCoordinate2D(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude)) {
                                    VStack {
                                        Image(systemName: "location.fill")
                                            .font(.title2)
                                            .foregroundColor(.red)
                                        
                                        Text(localizationManager.localize("LISTING_LOCATION"))
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                    }
                                }
                                
                                // User current location
                                if let userLocation = locationManager.location?.coordinate {
                                    Annotation("", coordinate: userLocation) {
                                        VStack {
                                            Image(systemName: "location.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.blue)
                                            
                                            Text(localizationManager.localize("YOUR_LOCATION"))
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                }
                                
                                // Search result pins
                                ForEach(nearbyListings) { listing in
                                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: listing.latitude, longitude: listing.longitude)) {
                                        VStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(selectedListingId == listing.id ? .orange : .purple)
                                            
                                            Text(listing.title)
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                        }
                                        .onTapGesture {
                                            selectedListingId = listing.id
                                        }
                                    }
                                }
                            }
                            .mapStyle(.standard)
                            
                            // Zoom controls - bottom right corner
                            VStack(spacing: 0) {
                                Spacer()
                                HStack(spacing: 0) {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Button(action: { zoomInOnMeetingAreaMap() }) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(width: 36, height: 36)
                                                .background(Color.blue)
                                                .cornerRadius(6)
                                        }
                                        
                                        Button(action: { zoomOutOnMeetingAreaMap() }) {
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
                        .frame(height: 200)
                        .cornerRadius(0)
                        .onAppear {
                            setInitialCameraForMeetingArea()
                        }
                        .onReceive(locationManager.$location) { _ in
                            setInitialCameraForMeetingArea()
                        }
                        
                        NavigationLink(destination: ListingRadiusMapView(
                            listingLocation: contactData.listing.location,
                            listingLatitude: contactData.listing.latitude,
                            listingLongitude: contactData.listing.longitude,
                            radiusKm: Double(contactData.listing.radius)
                        )) {
                            HStack(spacing: 8) {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 14))
                                Text("VIEW MEETING AREA")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color(hex: "667eea"))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(hex: "fee2e2"))
                    .cornerRadius(12)
                
                // Search Listings in Radius - Show if location not agreed
                if (currentMeeting?.location ?? "").isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔍 Search in Area")
                            .font(.headline)
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search listings...", text: $searchText)
                                .onChange(of: searchText) { _ in
                                    searchNearbyListings()
                                }
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    searchText = ""
                                    nearbyListings = []
                                    selectedListingId = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(hex: "f7fafc"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "cbd5e0"), lineWidth: 1)
                        )
                        
                        if let error = searchError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        if isSearching {
                            HStack {
                                ProgressView()
                                Text("Searching...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        } else if !nearbyListings.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Found \(nearbyListings.count) listings")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(nearbyListings.prefix(5)) { listing in
                                            NearbyListingRow(
                                                listing: listing,
                                                isSelected: selectedListingId == listing.id,
                                                onTap: {
                                                    selectedListingId = listing.id
                                                    centerMapOnListing(listing)
                                                }
                                            )
                                            .onTapGesture {
                                                selectedListingId = listing.id
                                                centerMapOnListing(listing)
                                            }
                                        }
                                    }
                                }
                                .frame(maxHeight: 200)
                            }
                        }
                    }
                    .padding()
                    .background(Color(hex: "f0f9ff"))
                    .cornerRadius(12)
                
                // Propose Meeting Button
                if currentMeeting == nil {
                    Button(action: { showProposeForm.toggle() }) {
                        Text("📅 " + localizationManager.localize("PROPOSE_MEETING"))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .cornerRadius(12)
                    }
                    
                    // Propose Meeting Form
                    if showProposeForm {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(localizationManager.localize("PROPOSE_MEETING_DETAILS"))
                                .font(.headline)
                                .foregroundColor(Color(hex: "2d3748"))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.localize("MEETING_LOCATION_REQUIRED"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "4a5568"))
                                
                                HStack(spacing: 8) {
                                    TextField("e.g., Starbucks on 5th Street", text: $proposedLocation)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    NavigationLink(destination: MeetingLocationPickerView(
                                        listingLocation: contactData.listing.location,
                                        listingLatitude: contactData.listing.latitude,
                                        listingLongitude: contactData.listing.longitude,
                                        radiusKm: Double(contactData.listing.radius),
                                        selectedLocation: $proposedLocation,
                                        selectedLat: $proposedLocationLat,
                                        selectedLng: $proposedLocationLng
                                    )) {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color(hex: "667eea"))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localizationManager.localize("DATE_REQUIRED"))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: "4a5568"))
                                    DatePicker("", selection: $proposedDate, in: Date()..., displayedComponents: .date)
                                        .labelsHidden()
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localizationManager.localize("TIME_REQUIRED"))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: "4a5568"))
                                    DatePicker("", selection: $proposedTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(localizationManager.localize("OPTIONAL_MESSAGE"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "4a5568"))
                                TextEditor(text: $proposalMessage)
                                    .frame(height: 80)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: "e2e8f0"), lineWidth: 2)
                                    )
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: { showProposeForm = false }) {
                                    Text(localizationManager.localize("CANCEL"))
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(hex: "4a5568"))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(hex: "e2e8f0"))
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    proposeMeeting()
                                    resetForm()
                                }) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                    } else {
                                        Text(localizationManager.localize("SEND"))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color(hex: "667eea"))
                                            .cornerRadius(8)
                                    }
                                }
                                .disabled(isLoading || proposedLocation.isEmpty)
                            }
                        }
                        .padding()
                        .background(Color(hex: "f7fafc"))
                        .cornerRadius(8)
                    }
                }
                
                // Meeting Proposals List
                if !meetingProposals.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localizationManager.localize("PROPOSED_MEETINGS"))
                            .font(.headline)
                            .foregroundColor(Color(hex: "2d3748"))
                        
                        ForEach(meetingProposals, id: \.id) { proposal in
                            proposalCard(proposal)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .onAppear {
            print("VIEW: ContactLocationView")
        }
    }
    
    // MARK: - Helper Methods
    
    private func proposalCard(_ proposal: MeetingProposal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(proposal.proposedLocation)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "2d3748"))
                    Text(formatDateTime(proposal.proposedTime))
                        .font(.caption)
                        .foregroundColor(Color(hex: "718096"))
                }
                Spacer()
                statusBadge(proposal.status)
            }
            
            Divider()
            
            if let message = proposal.message {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.localize("NOTES") + ":")
                        .font(.caption)
                        .foregroundColor(Color(hex: "718096"))
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "2d3748"))
                }
            }
            
            if proposal.status == "pending" {
                HStack(spacing: 12) {
                    Button(action: { respondToProposal(proposal.proposalId, response: "rejected") }) {
                        Text(localizationManager.localize("REJECT"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(hex: "f56565"))
                            .cornerRadius(8)
                    }
                    
                    Button(action: { respondToProposal(proposal.proposalId, response: "accepted") }) {
                        Text(localizationManager.localize("ACCEPT"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color(hex: "48bb78"))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(backgroundColor(for: proposal.status))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor(for: proposal.status), lineWidth: 2)
        )
        .cornerRadius(12)
    }
    
    private func statusBadge(_ status: String) -> some View {
        let text: String
        let textColor: Color
        
        switch status {
        case "pending":
            text = "⏳ Pending"
            textColor = Color(hex: "d69e2e")
        case "accepted":
            text = "✅ Accepted"
            textColor = Color(hex: "38a169")
        case "rejected":
            text = "❌ Rejected"
            textColor = Color(hex: "e53e3e")
        case "expired":
            text = "⏰ Expired"
            textColor = Color(hex: "a0aec0")
        default:
            text = status
            textColor = Color.gray
        }
        
        return Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(textColor.opacity(0.2))
            .foregroundColor(textColor)
            .cornerRadius(20)
    }
    
    private func backgroundColor(for status: String) -> Color {
        switch status {
        case "accepted": return Color(hex: "f0fff4")
        case "rejected": return Color(hex: "fef5e7")
        case "expired": return Color(hex: "f7fafc").opacity(0.8)
        default: return Color.white
        }
    }
    
    private func borderColor(for status: String) -> Color {
        switch status {
        case "accepted": return Color(hex: "68d391")
        case "rejected": return Color(hex: "fc8181")
        case "expired": return Color(hex: "a0aec0")
        default: return Color(hex: "e2e8f0")
        }
    }
    
    private func resetForm() {
        proposedLocation = ""
        proposedLocationLat = nil
        proposedLocationLng = nil
        proposedDate = Date()
        proposedTime = Date()
        proposalMessage = ""
        showProposeForm = false
    }
    
    private func formatDateTime(_ dateString: String) -> String {
        return DateFormatters.formatCompact(dateString)
    }
    
    private func proposeMeeting() {
        guard !proposedLocation.isEmpty else {
            errorMessage = "Please enter a meeting location"
            return
        }
        
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: proposedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: proposedTime)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = 0
        
        guard let combinedDate = calendar.date(from: combined) else { return }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let proposedDateTime = formatter.string(from: combinedDate)
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/ProposeMeeting")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing.listingId)),
            URLQueryItem(name: "proposedLocation", value: proposedLocation),
            URLQueryItem(name: "proposedTime", value: proposedDateTime),
            URLQueryItem(name: "message", value: proposalMessage)
        ]
        
        guard let url = components.url else { return }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { DispatchQueue.main.async { isLoading = false } }
            
            guard let data = data, error == nil else { return }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                DispatchQueue.main.async {
                    resetForm()
                }
            }
        }.resume()
    }
    
    private func respondToProposal(_ proposalId: String, response: String) {
        guard let sessionId = SessionManager.shared.sessionId else { return }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/RespondToMeeting")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "proposalId", value: proposalId),
            URLQueryItem(name: "response", value: response)
        ]
        
        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                DispatchQueue.main.async { }
            }
        }.resume()
    }
    
    private func zoomInOnMainMap() {
        let listingCoord = CLLocationCoordinate2D(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude)
        var newSpan = currentMainMapSpan
        newSpan.latitudeDelta *= 0.6
        newSpan.longitudeDelta *= 0.6
        currentMainMapSpan = newSpan
        cameraPosition = .region(MKCoordinateRegion(center: listingCoord, span: newSpan))
    }
    
    private func zoomOutOnMainMap() {
        let listingCoord = CLLocationCoordinate2D(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude)
        var newSpan = currentMainMapSpan
        newSpan.latitudeDelta *= 1.5
        newSpan.longitudeDelta *= 1.5
        currentMainMapSpan = newSpan
        cameraPosition = .region(MKCoordinateRegion(center: listingCoord, span: newSpan))
    }
    
    private func zoomInOnMeetingAreaMap() {
        let listingCoord = CLLocationCoordinate2D(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude)
        var newSpan = currentMeetingMapSpan
        newSpan.latitudeDelta *= 0.6
        newSpan.longitudeDelta *= 0.6
        currentMeetingMapSpan = newSpan
        noCameraPosition = .region(MKCoordinateRegion(center: listingCoord, span: newSpan))
    }
    
    private func zoomOutOnMeetingAreaMap() {
        let listingCoord = CLLocationCoordinate2D(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude)
        var newSpan = currentMeetingMapSpan
        newSpan.latitudeDelta *= 1.5
        newSpan.longitudeDelta *= 1.5
        currentMeetingMapSpan = newSpan
        noCameraPosition = .region(MKCoordinateRegion(center: listingCoord, span: newSpan))
    }
    
    private func setInitialCamera() {
        let listingCoord = CLLocationCoordinate2D(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude)
        
        guard CLLocationCoordinate2DIsValid(listingCoord) && contactData.listing.latitude != 0 && contactData.listing.longitude != 0 else {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            ))
            return
        }
        
        let radiusKm = Double(contactData.listing.radius) * 1.60934
        var latitudeDelta = max(0.01, (radiusKm * 2.5) / 111.0)
        var longitudeDelta = latitudeDelta
        
        if let userLocation = locationManager.location?.coordinate {
            let listingLoc = CLLocation(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude)
            let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            let distanceKm = listingLoc.distance(from: userLoc) / 1000.0
            
            if distanceKm > radiusKm {
                let expansionFactor = (distanceKm / radiusKm) * 1.3
                latitudeDelta *= expansionFactor
                longitudeDelta *= expansionFactor
            }
        }
        
        cameraPosition = .region(MKCoordinateRegion(
            center: listingCoord,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        ))
        currentMainMapSpan = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    }
    
    private func searchNearbyListings() {
        guard !searchText.isEmpty else {
            nearbyListings = []
            return
        }
        
        print("\n=== LOCATION SEARCH REQUEST START ===")
        print("MapKit Search called")
        print("  searchText: \(searchText)")
        
        isSearching = true
        searchError = nil
        
        // Use Apple MapKit to search for places
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        
        // Limit search to the meeting area (radius around listing)
        let listingCoord = CLLocationCoordinate2D(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude)
        let radiusKm = Double(contactData.listing.radius) * 1.60934
        let region = MKCoordinateRegion(
            center: listingCoord,
            span: MKCoordinateSpan(latitudeDelta: (radiusKm * 2) / 111.0, longitudeDelta: (radiusKm * 2) / 111.0)
        )
        searchRequest.region = region
        
        print("  Search region center: (\(listingCoord.latitude), \(listingCoord.longitude))")
        print("  Search region radius: \(radiusKm)km")
        
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            DispatchQueue.main.async {
                print("\n=== RESPONSE RECEIVED ===")
                
                if let error = error {
                    print("ERROR: Search failed: \(error.localizedDescription)")
                    self.searchError = "Search failed: \(error.localizedDescription)"
                    self.isSearching = false
                    print("=== LOCATION SEARCH REQUEST COMPLETE ===\n")
                    return
                }
                
                guard let response = response else {
                    print("ERROR: No response from MapKit")
                    self.searchError = "No results found"
                    self.isSearching = false
                    print("=== LOCATION SEARCH REQUEST COMPLETE ===\n")
                    return
                }
                
                let mapItems = response.mapItems
                print("Found \(mapItems.count) places")
                
                // Convert MKMapItem results to NearbyListing objects
                self.nearbyListings = mapItems.enumerated().map { index, mapItem -> NearbyListing in
                    let coord = mapItem.placemark.coordinate
                    
                    // Calculate distance from search center
                    let distance = self.haversineDistance(
                        lat1: listingCoord.latitude,
                        lon1: listingCoord.longitude,
                        lat2: coord.latitude,
                        lon2: coord.longitude
                    )
                    
                    return NearbyListing(
                        id: "\(index)",
                        title: mapItem.name ?? "Unknown Place",
                        currency: "-",
                        amount: 0,
                        location: mapItem.placemark.title ?? "",
                        latitude: coord.latitude,
                        longitude: coord.longitude,
                        distance: distance
                    )
                }
                
                print("Decoded \(self.nearbyListings.count) places")
                self.isSearching = false
                print("=== LOCATION SEARCH REQUEST COMPLETE ===\n")
            }
        }
    }
    
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0 // Earth's radius in kilometers
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c / 1.60934 // Convert to miles
    }
    
    private func centerMapOnListing(_ listing: NearbyListing) {
        let coords = CLLocationCoordinate2D(latitude: listing.latitude, longitude: listing.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        noCameraPosition = .region(MKCoordinateRegion(center: coords, span: span))
    }
    
    private func setInitialCameraForMeetingArea() {
        let listingCoord = CLLocationCoordinate2D(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude)
        
        guard CLLocationCoordinate2DIsValid(listingCoord) && contactData.listing.latitude != 0 && contactData.listing.longitude != 0 else {
            noCameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            ))
            return
        }
        
        let radiusKm = Double(contactData.listing.radius) * 1.60934
        var latitudeDelta = max(0.01, (radiusKm * 2.5) / 111.0)
        var longitudeDelta = latitudeDelta
        
        if let userLocation = locationManager.location?.coordinate {
            let listingLoc = CLLocation(latitude: contactData.listing.latitude, longitude: contactData.listing.longitude)
            let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            let distanceKm = listingLoc.distance(from: userLoc) / 1000.0
            
            if distanceKm > radiusKm {
                let expansionFactor = (distanceKm / radiusKm) * 1.3
                latitudeDelta *= expansionFactor
                longitudeDelta *= expansionFactor
            }
        }
        
        noCameraPosition = .region(MKCoordinateRegion(
            center: listingCoord,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        ))
        currentMeetingMapSpan = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    }
}

// MARK: - Nearby Listing Row View

struct NearbyListingRow: View {
    let listing: NearbyListing
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Label("\(listing.currency) \(String(format: "%.2f", listing.amount))", systemImage: "dollarsign.circle")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Label(String(format: "%.1f mi", listing.distance), systemImage: "mappin.circle")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
        }
        .padding(10)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color(hex: "e2e8f0"), lineWidth: isSelected ? 2 : 1)
        )
        .cornerRadius(8)
    }
}

// MARK: - Data Models

struct NearbyListing: Identifiable {
    let id: String
    let title: String
    let currency: String
    let amount: Double
    let location: String
    let latitude: Double
    let longitude: Double
    let distance: Double
}

#Preview {
    @State var currentMeeting: CurrentMeeting? = nil
    @State var meetingProposals: [MeetingProposal] = []
    
    return ContactLocationView(
        contactData: ContactData(
            listing: ContactListing(
                listingId: "1",
                currency: "USD",
                amount: 100,
                acceptCurrency: "EUR",
                preferredCurrency: "USD",
                meetingPreference: "public",
                location: "New York, NY",
                latitude: 40.7128,
                longitude: -74.0060,
                radius: 50,
                willRoundToNearestDollar: false
            ),
            otherUser: OtherUser(firstName: "John", lastName: "Doe", rating: 4.5, totalTrades: 10),
            lockedAmount: nil,
            exchangeRate: nil,
            fromCurrency: nil,
            toCurrency: nil,
            purchasedAt: nil
        ),
        currentMeeting: $currentMeeting,
        meetingProposals: $meetingProposals,
        onBackTapped: { }
    )
}
