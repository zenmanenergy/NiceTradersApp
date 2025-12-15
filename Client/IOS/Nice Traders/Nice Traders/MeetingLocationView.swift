//
//  MeetingLocationView.swift
//  Nice Traders
//

import SwiftUI
import MapKit
import CoreLocation

struct MeetingLocationView: View {
    let contactData: ContactData
    let initialDisplayStatus: String?
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var locationManager = LocationManager()
    
    @Binding var currentMeeting: CurrentMeeting?
    @Binding var meetingProposals: [MeetingProposal]
    var onBackTapped: (() -> Void)?
    
    @State private var displayStatus: String?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var searchText: String = ""
    @State private var searchResults: [MapSearchResult] = []
    @State private var isSearching: Bool = false
    @State private var selectedResultId: String?
    @State private var currentMapSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    @State private var mapIsReady: Bool = false
    @State private var showLocationProposalConfirm: Bool = false
    @State private var selectedLocationForProposal: MapSearchResult?
    @State private var currentMeetingTime: String?
    @State private var showSuccessMessage: Bool = false
    @State private var successMessageText: String = ""
    @State private var countdownText: String = ""
    @State private var countdownTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Map at the top
                ZStack {
                    if mapIsReady {
                        let locationProposals = meetingProposals.filter { !$0.proposedLocation.isEmpty }
                        let hasConfirmedLocation = locationProposals.contains { $0.status == "accepted" }
                        
                        Map(position: $cameraPosition) {
                            

                            // Listing location circle - only show if location not yet confirmed
                            if !hasConfirmedLocation {
                                MapCircle(
                                    center: CLLocationCoordinate2D(
                                        latitude: contactData.listing.latitude,
                                        longitude: contactData.listing.longitude
                                    ),
                                    radius: CLLocationDistance(Double(contactData.listing.radius) * 1609.34)
                                )
                                .foregroundStyle(Color.blue.opacity(0.2))
                                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
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
                            
                            // Proposed location pin
                            let locationProposals = meetingProposals.filter { !$0.proposedLocation.isEmpty }
                            if let proposedLocation = locationProposals.first,
                               let lat = proposedLocation.latitude,
                               let lng = proposedLocation.longitude {
                                Annotation("", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                                    VStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.green)
                                        Text("Proposed")
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
                            print("[DEBUG MLV] Map appeared - centering on listing")
                            print("[DEBUG MLV] Listing lat: \(contactData.listing.latitude), lng: \(contactData.listing.longitude)")
                            centerMapOnListing()
                        }
                    } else {
                        Color(hex: "e2e8f0")
                            .frame(height: 300)
                            .onAppear {
                                print("[DEBUG MLV] Map initializing...")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    mapIsReady = true
                                }
                            }
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
                
                // Directions button - show under map if location accepted
                let locationProposals = meetingProposals.filter { !$0.proposedLocation.isEmpty }
                let acceptedProposal = locationProposals.first { $0.status == "accepted" }
                if let accepted = acceptedProposal,
                   let lat = accepted.latitude,
                   let lng = accepted.longitude {
                    Button(action: {
                        openAppleDirections(latitude: lat, longitude: lng, name: accepted.proposedLocation)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 14))
                            Text("Get Directions")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .foregroundColor(.white)
                        .background(Color(hex: "667eea"))
                        .cornerRadius(8)
                    }
                    .padding(16)
                }
                
                // Search section
                VStack(alignment: .leading, spacing: 12) {
                // Search box and results - hide if location accepted
                let hasAcceptedLocation = locationProposals.contains { $0.status == "accepted" }
                
                if !hasAcceptedLocation {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search locations in area...", text: $searchText)
                            .onChange(of: searchText) {
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
                    
                    // Search results - only show if searching
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
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(searchResults, id: \.id) { result in
                                    SearchResultRow(
                                        result: result,
                                        displayStatus: displayStatus,
                                        isSelected: selectedResultId == result.id,
                                        onTap: {
                                            selectedResultId = result.id
                                            centerMapOnResult(result)
                                        },
                                        onProposeLocation: {
                                            selectedLocationForProposal = result
                                            // Load current meeting time from proposals if available
                                            if let latestProposal = meetingProposals.first {
                                                currentMeetingTime = latestProposal.proposedTime
                                            }
                                            showLocationProposalConfirm = true
                                        }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                }
                .padding(16)
                .background(Color(hex: "f0f9ff"))
                
                // Bottom content area
                ScrollView {
                    VStack(spacing: 12) {
                        let locationProposals = meetingProposals.filter { !$0.proposedLocation.isEmpty }
                        
                        // Countdown timer
                        if !countdownText.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "hourglass.tophalf.fill")
                                    .foregroundColor(Color(hex: "f97316"))
                                    .font(.system(size: 14))
                                
                                Text(countdownText)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "f97316"))
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(hex: "fff7ed"))
                            .cornerRadius(8)
                        }
                        
                        if !locationProposals.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(localizationManager.localize("MEETING_PROPOSALS"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                ForEach(locationProposals, id: \.proposalId) { proposal in
                                    LocationProposalCard(
                                        proposal: proposal,
                                        displayStatus: displayStatus,
                                        meetingTime: currentMeeting?.time,
                                        onAccept: {
                                            respondToProposal(proposalId: proposal.proposalId, response: "accepted")
                                        },
                                        onReject: {
                                            respondToProposal(proposalId: proposal.proposalId, response: "rejected")
                                        },
                                        onCounterPropose: {
                                            selectedLocationForProposal = nil
                                            searchText = ""
                                            searchResults = []
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            
            // Success Message Toast
            if showSuccessMessage {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18))
                        
                        Text(successMessageText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(hex: "dcfce7"))
                    .cornerRadius(8)
                    .padding(16)
                    
                    Spacer()
                }
            }
            
            // Location Proposal Confirmation Modal
            if showLocationProposalConfirm, let location = selectedLocationForProposal {
                LocationProposalConfirmView(
                    location: location,
                    meetingTime: currentMeetingTime,
                    contactData: contactData,
                    isPresented: $showLocationProposalConfirm,
                    onConfirm: { message in
                        proposeLocation(location: location, message: message)
                    }
                )
            }
        }
        .onAppear {
            print("[DEBUG MLV] MeetingLocationView appeared")
            // Initialize displayStatus with initial value
            if displayStatus == nil {
                displayStatus = initialDisplayStatus
            }
            print("[DEBUG MLV] displayStatus: \(displayStatus ?? "nil")")
            print("[DEBUG MLV] Listing: \(contactData.listing.latitude), \(contactData.listing.longitude)")
            print("[DEBUG MLV] Radius: \(contactData.listing.radius)")
            print("[DEBUG MLV] Meeting proposals count: \(meetingProposals.count)")
            
            // Refresh displayStatus from server
            refreshDisplayStatus()
            
            // Start countdown timer
            if let meetingTime = currentMeeting?.time {
                startCountdownTimer(meetingTime: meetingTime)
            }
            
            // Zoom map to show user and meeting location
            zoomToShowUserAndMeeting()
            
            for (i, proposal) in meetingProposals.enumerated() {
                print("[DEBUG MLV] Proposal \(i): id=\(proposal.proposalId), location='\(proposal.proposedLocation)', status=\(proposal.status), type=location?\(!proposal.proposedLocation.isEmpty)")
            }
            
            if contactData.listing.latitude == 0 && contactData.listing.longitude == 0 {
                print("[DEBUG MLV] WARNING: Listing coordinates are 0,0!")
            }
        }
        .onDisappear {
            countdownTimer?.invalidate()
        }
    }
    
    private func startCountdownTimer(meetingTime: String?) {
        guard let meetingTime = meetingTime else { return }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let meetingDate = isoFormatter.date(from: meetingTime) else { return }
        
        countdownTimer?.invalidate()
        
        updateCountdown(meetingDate: meetingDate)
        
        // Update every 60 seconds (1 minute)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            updateCountdown(meetingDate: meetingDate)
        }
    }
    
    private func updateCountdown(meetingDate: Date) {
        let now = Date()
        let timeInterval = meetingDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            countdownText = "Meeting time is now!"
            countdownTimer?.invalidate()
            return
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        let hourText = hours == 1 ? "hour" : "hours"
        let minuteText = minutes == 1 ? "minute" : "minutes"
        
        if hours > 0 && minutes > 0 {
            countdownText = "\(hours) \(hourText) \(minutes) \(minuteText) until meeting"
        } else if hours > 0 {
            countdownText = "\(hours) \(hourText) until meeting"
        } else if minutes > 0 {
            countdownText = "\(minutes) \(minuteText) until meeting"
        } else {
            countdownText = "Less than a minute until meeting"
        }
    }
    
    private func zoomToShowUserAndMeeting() {
        guard let userCoord = locationManager.location?.coordinate else { return }
        
        // Center on user's current location with a good zoom level
        cameraPosition = .region(
            MKCoordinateRegion(
                center: userCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        )
    }
    
    private func openAppleDirections(latitude: Double, longitude: Double, name: String) {
        let destinationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let mapItem = MKMapItem(
            placemark: MKPlacemark(coordinate: destinationCoordinate)
        )
        mapItem.name = name
        
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }

    
    private func refreshDisplayStatus() {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("[DEBUG MLV refreshDisplayStatus] ERROR: No session ID available")
            return
        }
        
        print("[DEBUG MLV refreshDisplayStatus] Starting refresh...")
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Meeting/GetMeetingProposals")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId)
        ]
        
        guard let url = components.url else {
            print("[DEBUG MLV refreshDisplayStatus] ERROR: Failed to construct URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("[DEBUG MLV refreshDisplayStatus] ERROR: Network error - \(error?.localizedDescription ?? "unknown")")
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    if let newDisplayStatus = json["displayStatus"] as? String {
                        print("[DEBUG MLV refreshDisplayStatus] Updated displayStatus: \(newDisplayStatus)")
                        self.displayStatus = newDisplayStatus
                    } else {
                        print("[DEBUG MLV refreshDisplayStatus] WARNING: displayStatus not in response")
                    }
                } else {
                    print("[DEBUG MLV refreshDisplayStatus] ERROR: Failed to parse response")
                }
            }
        }.resume()
    }
    
    private func centerMapOnListing() {
        let listingCoord = CLLocationCoordinate2D(
            latitude: contactData.listing.latitude,
            longitude: contactData.listing.longitude
        )
        
        print("[DEBUG MLV centerMapOnListing] Starting...")
        print("[DEBUG MLV centerMapOnListing] Listing coordinate: \(listingCoord.latitude), \(listingCoord.longitude)")
        print("[DEBUG MLV centerMapOnListing] Radius: \(contactData.listing.radius) miles")
        
        // Check for invalid coordinates
        if listingCoord.latitude == 0 && listingCoord.longitude == 0 {
            print("[DEBUG MLV centerMapOnListing] ERROR: Listing coordinates are 0,0 (ocean)!")
        }
        
        let radiusKm = Double(contactData.listing.radius) * 1.60934
        let latitudeDelta = max(0.01, (radiusKm * 2.2) / 111.0)
        let longitudeDelta = latitudeDelta
        
        print("[DEBUG MLV centerMapOnListing] Calculated radius in km: \(radiusKm)")
        print("[DEBUG MLV centerMapOnListing] Latitude delta: \(latitudeDelta), Longitude delta: \(longitudeDelta)")
        
        currentMapSpan = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
        let region = MKCoordinateRegion(
            center: listingCoord,
            span: currentMapSpan
        )
        
        print("[DEBUG MLV centerMapOnListing] Setting camera position to region: center=(\(region.center.latitude), \(region.center.longitude)), span=(\(region.span.latitudeDelta), \(region.span.longitudeDelta))")
        
        cameraPosition = .region(region)
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
    
    private func centerMapOnProposedLocation() {
        // Get the proposed location from meetingProposals
        let locationProposals = meetingProposals.filter { !$0.proposedLocation.isEmpty }
        guard let proposedLocation = locationProposals.first,
              let lat = proposedLocation.latitude,
              let lng = proposedLocation.longitude else {
            print("[DEBUG MLV] No proposed location to center on")
            return
        }
        
        let proposedCoord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        // If we have user location, calculate region to show both
        if let userCoord = locationManager.location?.coordinate {
            // Calculate center between user and proposed location
            let centerLat = (userCoord.latitude + proposedCoord.latitude) / 2
            let centerLng = (userCoord.longitude + proposedCoord.longitude) / 2
            let centerCoord = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
            
            // Calculate distance between points to determine appropriate span
            let latDiff = abs(userCoord.latitude - proposedCoord.latitude)
            let lngDiff = abs(userCoord.longitude - proposedCoord.longitude)
            
            // Add padding (30% extra)
            let span = MKCoordinateSpan(latitudeDelta: latDiff * 1.3, longitudeDelta: lngDiff * 1.3)
            
            print("[DEBUG MLV] Centering map on both user and proposed location")
            cameraPosition = .region(MKCoordinateRegion(center: centerCoord, span: span))
        } else {
            // Just center on proposed location
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            cameraPosition = .region(MKCoordinateRegion(center: proposedCoord, span: span))
        }
    }
    
    private func searchLocations() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        print("[DEBUG MLV searchLocations] Starting search for: '\(searchText)'")
        
        isSearching = true
        searchResults = []
        
        let listingCoord = CLLocationCoordinate2D(
            latitude: contactData.listing.latitude,
            longitude: contactData.listing.longitude
        )
        
        print("[DEBUG MLV searchLocations] Search center: \(listingCoord.latitude), \(listingCoord.longitude)")
        print("[DEBUG MLV searchLocations] Radius: \(contactData.listing.radius) miles")
        
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
                
                if let error = error {
                    print("[DEBUG MLV searchLocations] Search error: \(error.localizedDescription)")
                    return
                }
                
                guard let response = response else {
                    print("[DEBUG MLV searchLocations] No response from search")
                    return
                }
                
                print("[DEBUG MLV searchLocations] Found \(response.mapItems.count) total results")
                
                // Filter results to only those within the radius
                let filteredResults = response.mapItems.enumerated().compactMap { index, mapItem -> MapSearchResult? in
                    let distance = haversineDistance(
                        lat1: listingCoord.latitude,
                        lon1: listingCoord.longitude,
                        lat2: mapItem.placemark.coordinate.latitude,
                        lon2: mapItem.placemark.coordinate.longitude
                    )
                    
                    print("[DEBUG MLV searchLocations] Result \(index): '\(mapItem.name ?? "Unknown")' at \(mapItem.placemark.coordinate.latitude), \(mapItem.placemark.coordinate.longitude) - distance: \(distance) miles")
                    
                    // Only include if within radius (convert km to miles)
                    if distance <= Double(contactData.listing.radius) {
                        print("[DEBUG MLV searchLocations]   ✓ Within radius")
                        return MapSearchResult(
                            id: "\(index)",
                            name: mapItem.name ?? "Unknown",
                            coordinate: mapItem.placemark.coordinate,
                            address: mapItem.placemark.title ?? "",
                            distance: distance
                        )
                    } else {
                        print("[DEBUG MLV searchLocations]   ✗ Outside radius")
                    }
                    return nil
                }
                
                print("[DEBUG MLV searchLocations] Filtered to \(filteredResults.count) results within radius")
                searchResults = filteredResults
            }
        }
    }
    
    private func respondToProposal(proposalId: String, response: String) {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("ERROR: No session ID available")
            return
        }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/RespondToMeeting")!
        let queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "proposalId", value: proposalId),
            URLQueryItem(name: "response", value: response)
        ]
        components.queryItems = queryItems
        
        guard let url = components.url else {
            print("ERROR: Failed to construct URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("ERROR: Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("ERROR: No data received")
                return
            }
            
            do {
                let result = try JSONDecoder().decode(RespondToProposalResponse.self, from: data)
                if result.success {
                    print("✓ Responded to proposal: \(response)")
                    
                    DispatchQueue.main.async {
                        // Reload proposals to reflect the change
                        // This would need to be called from parent view to reload
                    }
                } else {
                    if let error = result.error {
                        print("ERROR: Server error: \(error)")
                    }
                }
            } catch {
                print("ERROR: Failed to parse response: \(error)")
            }
        }.resume()
    }
    
    private func proposeLocation(location: MapSearchResult, message: String?) {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("🔴 [MLV-PROPOSE] ERROR: No session ID available")
            return
        }
        
        print("🟠 [MLV-PROPOSE] ===== START PROPOSE LOCATION =====")
        print("🟠 [MLV-PROPOSE] Location name: '\(location.name)'")
        print("🟠 [MLV-PROPOSE] Coordinates: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("🟠 [MLV-PROPOSE] Listing ID: \(contactData.listing.listingId)")
        
        // Get the meeting time from either current meeting or latest proposal
        var meetingTimeToSend: String? = nil
        if let latestProposal = meetingProposals.first {
            meetingTimeToSend = latestProposal.proposedTime
            print("🟠 [MLV-PROPOSE] Using meeting time from latest proposal: \(meetingTimeToSend ?? "nil")")
        } else if let currentMeeting = currentMeeting {
            // If no proposals yet, use the current meeting time
            meetingTimeToSend = currentMeeting.time
            print("🟠 [MLV-PROPOSE] Using meeting time from current meeting: \(meetingTimeToSend ?? "nil")")
        } else if let currentTime = currentMeetingTime {
            meetingTimeToSend = currentTime
            print("🟠 [MLV-PROPOSE] Using meeting time from currentMeetingTime: \(meetingTimeToSend ?? "nil")")
        }
        
        print("🟠 [MLV-PROPOSE] Final meeting time to send: \(meetingTimeToSend ?? "nil")")
        
        // Location-only proposals are allowed without a time
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/ProposeMeeting")!
        var queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId),
            URLQueryItem(name: "proposedLocation", value: location.name),
            URLQueryItem(name: "proposedLatitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "proposedLongitude", value: String(location.coordinate.longitude))
        ]
        
        // Only add time if available
        if let timeToSend = meetingTimeToSend, !timeToSend.isEmpty {
            queryItems.append(URLQueryItem(name: "proposedTime", value: timeToSend))
        }
        
        if let msg = message, !msg.isEmpty {
            queryItems.append(URLQueryItem(name: "message", value: msg))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            print("🔴 [MLV-PROPOSE] ERROR: Failed to construct URL")
            return
        }
        
        print("🟠 [MLV-PROPOSE] Sending request to: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            print("🟠 [MLV-PROPOSE] Response received from server")
            
            if let error = error {
                print("🔴 [MLV-PROPOSE] Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    successMessageText = "❌ Network error: \(error.localizedDescription)"
                    showSuccessMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showSuccessMessage = false
                    }
                }
                return
            }
            
            guard let data = data else {
                print("🔴 [MLV-PROPOSE] No data received from server")
                return
            }
            
            let responseStr = String(data: data, encoding: .utf8) ?? "no data"
            print("🟠 [MLV-PROPOSE] Response data: \(responseStr)")
            
            do {
                let result = try JSONDecoder().decode(LocationProposalResponse.self, from: data)
                print("🟠 [MLV-PROPOSE] Response decoded - success: \(result.success)")
                
                if result.success {
                    print("✅ [MLV-PROPOSE] Location proposal sent successfully")
                    print("✅ [MLV-PROPOSE] Proposal ID: \(result.proposal_id ?? "unknown")")
                    
                    DispatchQueue.main.async {
                        print("🟠 [MLV-PROPOSE] Updating UI - showing success message")
                        successMessageText = "📍 \(location.name) proposed!"
                        showSuccessMessage = true
                        
                        // Clear the form
                        selectedLocationForProposal = nil
                        searchText = ""
                        searchResults = []
                        selectedResultId = nil
                        showLocationProposalConfirm = false
                        
                        print("🟠 [MLV-PROPOSE] Reloading meeting proposals from server...")
                        // NOW reload proposals from server
                        reloadMeetingProposals()
                        
                        // Center map on proposed location and user location
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            centerMapOnProposedLocation()
                        }
                        
                        // Hide success message after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            showSuccessMessage = false
                        }
                    }
                } else {
                    let errorMsg = result.error ?? "Unknown error"
                    print("🔴 [MLV-PROPOSE] Server error: \(errorMsg)")
                    DispatchQueue.main.async {
                        successMessageText = "❌ Error: \(errorMsg)"
                        showSuccessMessage = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            showSuccessMessage = false
                        }
                    }
                }
            } catch {
                print("🔴 [MLV-PROPOSE] Failed to parse response: \(error)")
                DispatchQueue.main.async {
                    successMessageText = "❌ Parse error: \(error.localizedDescription)"
                    showSuccessMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showSuccessMessage = false
                    }
                }
            }
            
            print("🟠 [MLV-PROPOSE] ===== END PROPOSE LOCATION =====")
        }.resume()
    }
    
    private func reloadMeetingProposals() {
        guard let sessionId = SessionManager.shared.sessionId else {
            print("🔴 [MLV-RELOAD] ERROR: No session ID available")
            return
        }
        
        print("🟠 [MLV-RELOAD] ===== START RELOAD PROPOSALS =====")
        print("🟠 [MLV-RELOAD] Listing ID: \(contactData.listing.listingId)")
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Meeting/GetMeetingProposals")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: String(contactData.listing.listingId))
        ]
        
        guard let url = components.url else {
            print("🔴 [MLV-RELOAD] ERROR: Failed to construct URL")
            return
        }
        
        print("🟠 [MLV-RELOAD] Fetching from: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                print("🟠 [MLV-RELOAD] Response received from server")
                
                guard let data = data, error == nil else {
                    print("🔴 [MLV-RELOAD] ERROR: Network error - \(error?.localizedDescription ?? "unknown")")
                    return
                }
                
                let responseStr = String(data: data, encoding: .utf8) ?? "no data"
                print("🟠 [MLV-RELOAD] Raw response: \(responseStr.prefix(200))...")
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    print("✅ [MLV-RELOAD] Response successful")
                    
                    // Parse proposals
                    if let proposalsData = json["proposals"] as? [[String: Any]] {
                        print("🟠 [MLV-RELOAD] Found \(proposalsData.count) proposals")
                        
                        let newProposals = proposalsData.compactMap { dict -> MeetingProposal? in
                            guard let proposalId = dict["proposal_id"] as? String,
                                  let status = dict["status"] as? String else {
                                print("🔴 [MLV-RELOAD] Skipping proposal - missing required fields")
                                return nil
                            }
                            
                            let proposedLocation = dict["proposed_location"] as? String ?? ""
                            let proposedTime = dict["proposed_time"] as? String ?? ""
                            let type = dict["type"] as? String ?? "unknown"
                            
                            print("🟠 [MLV-RELOAD] Parsed proposal: id=\(proposalId), type=\(type), status=\(status), location=\(proposedLocation), time=\(proposedTime)")
                            
                            return MeetingProposal(
                                proposalId: proposalId,
                                proposedLocation: proposedLocation,
                                proposedTime: proposedTime,
                                message: dict["message"] as? String,
                                status: status,
                                isFromMe: dict["is_from_me"] as? Bool ?? false,
                                proposer: ProposerInfo(firstName: dict["proposed_by_name"] as? String ?? (dict["proposer"] as? [String: Any])?["first_name"] as? String ?? "Unknown"),
                                latitude: dict["latitude"] as? Double,
                                longitude: dict["longitude"] as? Double
                            )
                        }
                        
                        print("✅ [MLV-RELOAD] Updated meetingProposals: \(newProposals.count) items")
                        self.meetingProposals = newProposals
                    } else {
                        print("🟠 [MLV-RELOAD] No proposals found in response")
                        self.meetingProposals = []
                    }
                    
                    // Update current meeting if available
                    if let meetingData = json["current_meeting"] as? [String: Any] {
                        print("🟠 [MLV-RELOAD] Parsing current_meeting...")
                        if let time = meetingData["time"] as? String {
                            self.currentMeeting = CurrentMeeting(
                                location: meetingData["location"] as? String,
                                latitude: meetingData["latitude"] as? Double,
                                longitude: meetingData["longitude"] as? Double,
                                time: time,
                                message: meetingData["message"] as? String,
                                agreedAt: (meetingData["agreed_at"] as? String) ?? "",
                                acceptedAt: meetingData["timeAcceptedAt"] as? String,
                                locationAcceptedAt: meetingData["locationAcceptedAt"] as? String
                            )
                            print("✅ [MLV-RELOAD] Updated current meeting")
                        }
                    }
                } else {
                    print("🔴 [MLV-RELOAD] ERROR: Response indicates failure")
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("🔴 [MLV-RELOAD] Error: \(json["error"] as? String ?? "unknown")")
                    }
                }
                
                print("🟠 [MLV-RELOAD] ===== END RELOAD PROPOSALS =====")
            }
        }.resume()
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
    let displayStatus: String?
    let isSelected: Bool
    let onTap: () -> Void
    let onProposeLocation: () -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var body: some View {
        let _ = print("[DEBUG SRR] Row render - result: \(result.name), isSelected: \(isSelected), displayStatus: \(displayStatus ?? "nil"), shouldShowButton: \(isSelected && (displayStatus?.contains("Action: Propose Location") ?? false))")
        VStack(alignment: .leading, spacing: 8) {
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
            
            if isSelected && (displayStatus?.contains("Action: Propose Location") ?? false) {
                Button(action: onProposeLocation) {
                    HStack {
                        Image(systemName: "checkmark.square")
                            .font(.system(size: 12))
                        Text(localizationManager.localize("PROPOSE_LOCATION"))
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .foregroundColor(.white)
                    .background(Color(hex: "667eea"))
                    .cornerRadius(6)
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

// MARK: - API Response Models

struct LocationProposalResponse: Codable {
    let success: Bool
    let proposal_id: String?
    let message: String?
    let error: String?
}

struct RespondToProposalResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}
