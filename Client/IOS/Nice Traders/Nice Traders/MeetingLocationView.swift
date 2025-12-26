//
//  MeetingLocationView.swift
//  Nice Traders
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit

struct MeetingLocationView: View {
    let initialContactData: ContactData
    let initialDisplayStatus: String?
    @ObservedObject var localizationManager = LocalizationManager.shared
    @ObservedObject var locationManager = LocationManager()
    
    @Binding var currentMeeting: CurrentMeeting?
    @Binding var meetingProposals: [MeetingProposal]
    var onBackTapped: (() -> Void)?
    
    @State private var contactData: ContactData
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
    @State private var zoomRetryCount: Int = 0
    @State private var zoomRetryTimer: Timer? = nil
    @State private var showProposeTimeView: Bool = false
    @State private var highlightedProposalId: String? = nil
    @State private var highlightedResultId: String? = nil
    @State private var keyboardHeight: CGFloat = 0
    @State private var hasSelectedItem: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    
    init(contactData: ContactData, initialDisplayStatus: String?, currentMeeting: Binding<CurrentMeeting?>, meetingProposals: Binding<[MeetingProposal]>, onBackTapped: (() -> Void)? = nil) {
        self.initialContactData = contactData
        self.initialDisplayStatus = initialDisplayStatus
        self._contactData = State(initialValue: contactData)
        self._currentMeeting = currentMeeting
        self._meetingProposals = meetingProposals
        self.onBackTapped = onBackTapped
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Map at the top - shows unless search field is focused
                Group {
                    if !isSearchFieldFocused {
                        ZStack {
                        if mapIsReady {
                            let locationProposals = meetingProposals.filter { !$0.proposedLocation.isEmpty }
                            let hasConfirmedLocation = locationProposals.contains { $0.status == "accepted" && !$0.proposedLocation.isEmpty }
                            
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
                                        Button(action: {
                                            highlightedProposalId = proposedLocation.proposalId
                                            highlightedResultId = nil
                                            scrollToProposal(proposedLocation.proposalId)
                                        }) {
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
                                }
                                
                                // Search result pins
                                ForEach(searchResults, id: \.id) { result in
                                    Annotation("", coordinate: result.coordinate) {
                                        Button(action: {
                                            highlightedResultId = result.id
                                            highlightedProposalId = nil
                                            scrollToResult(result.id)
                                        }) {
                                            VStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .font(.title2)
                                                    .foregroundColor(selectedResultId == result.id || highlightedResultId == result.id ? .orange : .purple)
                                                Text(result.name)
                                                    .font(.caption2)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                    }
                                }
                            }
                            .mapStyle(.standard)
                            .frame(height: 200)
                            .onAppear {
                                print("[DEBUG MLV] Map appeared")
                            }
                        } else {
                            Color(hex: "e2e8f0")
                                .frame(height: 200)
                                .onAppear {
                                    print("[DEBUG MLV] Map initializing...")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        mapIsReady = true
                                    }
                                }
                        }
                        
                        // Zoom controls
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
                }
                }
                .frame(height: 200)
                
                // Directions button
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
                
                // Search section - ALWAYS visible
                VStack(alignment: .leading, spacing: 12) {
                    let hasAcceptedLocation = locationProposals.contains { $0.status == "accepted" }
                    
                    if !hasAcceptedLocation {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search locations in area...", text: $searchText)
                                .focused($isSearchFieldFocused)
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
                                    hasSelectedItem = false
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
                        
                        if isSearching {
                            HStack {
                                ProgressView()
                                Text("Searching...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                        
                        // Results section - ALWAYS visible when there are results
                        if !searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Results (\(searchResults.count))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 8) {
                                        ForEach(searchResults, id: \.id) { result in
                                            SearchResultRow(
                                                result: result,
                                                displayStatus: displayStatus,
                                                isSelected: selectedResultId == result.id,
                                                onTap: {
                                                    selectedResultId = result.id
                                                    hasSelectedItem = true
                                                    isSearchFieldFocused = false
                                                    centerMapOnResult(result)
                                                },
                                                onProposeLocation: {
                                                    selectedLocationForProposal = result
                                                    if let latestProposal = meetingProposals.first {
                                                        currentMeetingTime = latestProposal.proposedTime
                                                    }
                                                    showLocationProposalConfirm = true
                                                }
                                            )
                                        }
                                    }
                                    .frame(maxWidth: 500, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(hex: "f0f9ff"))
                
                // Bottom content area - scrollable (proposals only)
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            let locationProposals = meetingProposals.filter { !$0.proposedLocation.isEmpty }
                            
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
                                            isHighlighted: highlightedProposalId == proposal.proposalId,
                                            onAccept: {
                                                respondToProposal(proposalId: proposal.proposalId, response: "accepted")
                                            },
                                            onReject: {
                                                respondToProposal(proposalId: proposal.proposalId, response: "rejected")
                                            },
                                            onCounterPropose: {
                                                showProposeTimeView = true
                                            }
                                        )
                                        .id(proposal.proposalId)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(16)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                    withAnimation {
                        keyboardHeight = keyboardSize.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation {
                    keyboardHeight = 0
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
            
            // Propose Time View Sheet
            if showProposeTimeView {
                ProposeTimeView(
                    listingId: contactData.listing.listingId,
                    currency: contactData.listing.currency,
                    amount: contactData.listing.amount,
                    acceptCurrency: contactData.listing.acceptCurrency ?? "USD",
                    sellerName: contactData.otherUser.firstName,
                    willRoundToNearestDollar: contactData.listing.willRoundToNearestDollar ?? false,
                    navigateToDashboard: $showProposeTimeView
                )
            }
        }
        .onAppear {
            print("[DEBUG MLV] MeetingLocationView appeared")
            if displayStatus == nil {
                displayStatus = initialDisplayStatus
            }
            print("[DEBUG MLV] displayStatus: \(displayStatus ?? "nil")")
            print("[DEBUG MLV] Listing: \(contactData.listing.latitude), \(contactData.listing.longitude)")
            print("[DEBUG MLV] Radius: \(contactData.listing.radius)")
            print("[DEBUG MLV] Meeting proposals count: \(meetingProposals.count)")
            
            refreshListingData()
            refreshDisplayStatus()
            
            if let meetingTime = currentMeeting?.time {
                startCountdownTimer(meetingTime: meetingTime)
            }
            
            zoomToShowUserAndMeeting()
            
            for (i, proposal) in meetingProposals.enumerated() {
                print("[DEBUG MLV] Proposal \(i): id=\(proposal.proposalId), location='\(proposal.proposedLocation)', status=\(proposal.status)")
            }
            
            if contactData.listing.latitude == 0 && contactData.listing.longitude == 0 {
                print("[DEBUG MLV] WARNING: Listing coordinates are 0,0!")
            }
        }
        .onDisappear {
            countdownTimer?.invalidate()
            zoomRetryTimer?.invalidate()
        }
        .onChange(of: meetingProposals.count) {
            print("[DEBUG MLV] meetingProposals count changed - re-zooming map")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                zoomToShowUserAndMeeting()
            }
        }
    }
}

// MARK: - Models

struct MapSearchResult: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    let distance: Double?
}

struct RespondToProposalResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
}

// MARK: - Subviews

struct SearchResultRow: View {
    let result: MapSearchResult
    let displayStatus: String?
    let isSelected: Bool
    let onTap: () -> Void
    let onProposeLocation: () -> Void
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    var body: some View {
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
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            
            if isSelected && (displayStatus?.contains("Action: Propose Location") ?? false) {
                Button(action: onProposeLocation) {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                        Text(localizationManager.localize("PROPOSE_LOCATION"))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .foregroundColor(.white)
                    .background(Color(hex: "667eea"))
                    .cornerRadius(6)
                }
            }
        }
        .padding(8)
        .background(isSelected ? Color(hex: "dbeafe") : Color.white)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.blue : Color(hex: "e2e8f0"), lineWidth: 1)
        )
    }
}

struct LocationProposalCard: View {
    let proposal: MeetingProposal
    let displayStatus: String?
    let meetingTime: String?
    let isHighlighted: Bool
    var onAccept: () -> Void
    var onReject: () -> Void
    var onCounterPropose: () -> Void
    
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var countdownText: String = ""
    @State private var countdownTimer: Timer?
    
    var statusColor: Color {
        switch proposal.status {
        case "pending":
            return Color(hex: "f97316")
        case "accepted":
            return Color(hex: "10b981")
        case "rejected":
            return Color(hex: "ef4444")
        default:
            return Color.gray
        }
    }
    
    var statusText: String {
        switch proposal.status {
        case "pending":
            return localizationManager.localize("AWAITING_LOCATION_RESPONSE")
        case "accepted":
            return localizationManager.localize("LOCATION_ACCEPTED")
        case "rejected":
            return localizationManager.localize("REJECT_LOCATION")
        default:
            return proposal.status
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(proposal.proposedLocation)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "2d3748"))
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        
                        Text(statusText)
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localizationManager.localize("MEETING_TIME"))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            
                            if let time = meetingTime {
                                Text(DateFormatters.formatCompact(time))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "2d3748"))
                            } else {
                                Text(DateFormatters.formatCompact(proposal.proposedTime))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "2d3748"))
                            }
                        }
                        
                        Spacer()
                    }
                    
                    if !countdownText.isEmpty && proposal.status == "accepted" {
                        HStack(spacing: 8) {
                            Image(systemName: "hourglass.bottomhalf.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "f97316"))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(localizationManager.localize("TIME_UNTIL_MEETING"))
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "f97316"))
                                    .textCase(.uppercase)
                                
                                Text(countdownText)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "f97316"))
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                if !proposal.proposer.firstName.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "person")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localizationManager.localize("PROPOSED_BY"))
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textCase(.uppercase)
                            
                            Text(proposal.proposer.firstName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "2d3748"))
                        }
                        
                        Spacer()
                    }
                }
                
                if let message = proposal.message, !message.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MESSAGE")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                        
                        Text(message)
                            .font(.caption)
                            .foregroundColor(Color(hex: "4a5568"))
                            .italic()
                    }
                    .padding(8)
                    .background(Color(hex: "f0f9ff"))
                    .cornerRadius(6)
                }
                
                if proposal.status == "pending" {
                    if !proposal.isFromMe && (displayStatus?.contains("Proposed a") ?? false) {
                        HStack(spacing: 8) {
                            Button(action: onReject) {
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 12))
                                    Text(localizationManager.localize("REJECT_LOCATION"))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .foregroundColor(.white)
                                .background(Color(hex: "ef4444"))
                                .cornerRadius(6)
                            }
                            
                            Button(action: onAccept) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 12))
                                    Text(localizationManager.localize("ACCEPT_LOCATION"))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(8)
                                .foregroundColor(.white)
                                .background(Color(hex: "10b981"))
                                .cornerRadius(6)
                            }
                        }
                        
                        Button(action: onCounterPropose) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.2.squarepath")
                                    .font(.system(size: 12))
                                Text(localizationManager.localize("COUNTER_PROPOSE_LOCATION"))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .foregroundColor(Color(hex: "667eea"))
                            .background(Color(hex: "f0f4ff"))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(isHighlighted ? Color(hex: "fef3c7") : Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(
                isHighlighted ? Color(hex: "f59e0b") : statusColor.opacity(0.3),
                lineWidth: isHighlighted ? 2 : 1
            )
        )
        .cornerRadius(8)
        .onAppear {
            startCountdownTimer()
        }
        .onDisappear {
            countdownTimer?.invalidate()
            countdownTimer = nil
        }
    }
    
    private func startCountdownTimer() {
        let timeString = meetingTime ?? proposal.proposedTime
        guard let meetingDate = DateFormatters.parseISO8601(timeString) else {
            return
        }
        
        updateCountdown(meetingDate: meetingDate)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            updateCountdown(meetingDate: meetingDate)
        }
    }
    
    private func updateCountdown(meetingDate: Date) {
        let now = Date()
        let timeInterval = meetingDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            countdownText = "Meeting time has arrived"
            return
        }
        
        let totalSeconds = Int(timeInterval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        let hourText = hours == 1 ? "hour" : "hours"
        let minuteText = minutes == 1 ? "minute" : "minutes"
        
        if hours > 0 {
            countdownText = "\(hours) \(hourText) \(minutes) \(minuteText) until meeting"
        } else {
            countdownText = "\(minutes) \(minuteText) until meeting"
        }
    }
}

// MARK: - Scroll Helper Methods

extension MeetingLocationView {
    func scrollToProposal(_ proposalId: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            highlightedProposalId = proposalId
        }
    }
    
    func scrollToResult(_ resultId: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            highlightedResultId = resultId
            selectedResultId = resultId
        }
    }
}

// MARK: - API Methods Extension

extension MeetingLocationView {
    func refreshDisplayStatus() {
        guard let session_id = SessionManager.shared.session_id else {
            print("[DEBUG MLV refreshDisplayStatus] ERROR: No session ID available")
            return
        }
        
        print("[DEBUG MLV refreshDisplayStatus] Starting refresh...")
        
        let baseURL = Settings.shared.baseURL
        var components = URLComponents(string: "\(baseURL)/Meeting/GetMeetingProposals")!
        components.queryItems = [
            URLQueryItem(name: "session_id", value: session_id),
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
    
    func refreshListingData() {
        guard let session_id = SessionManager.shared.session_id else {
            print("[DEBUG MLV refreshListingData] ERROR: No session ID available")
            return
        }
        
        print("[DEBUG MLV refreshListingData] Starting refresh of listing data...")
        
        let baseURL = Settings.shared.baseURL
        let urlString = "\(baseURL)/Dashboard/GetUserDashboard?session_id=\(session_id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            print("[DEBUG MLV refreshListingData] ERROR: Failed to construct URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("[DEBUG MLV refreshListingData] ERROR: Network error - \(error?.localizedDescription ?? "unknown")")
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success,
                   let dashboardData = json["data"] as? [String: Any],
                   let activeExchanges = dashboardData["activeExchanges"] as? [[String: Any]] {
                    
                    print("[DEBUG MLV refreshListingData] Found \(activeExchanges.count) active exchanges in response")
                    for exchange in activeExchanges {
                        if let lid = exchange["listingId"] as? String {
                            print("[DEBUG MLV refreshListingData]   - Exchange listing ID: \(lid)")
                        }
                    }
                    
                    if let matchingExchange = activeExchanges.first(where: { ($0["listingId"] as? String) == self.contactData.listing.listingId }) {
                        if let listingData = matchingExchange["listing"] as? [String: Any] {
                            let radius = (listingData["radius"] as? Int) ?? self.contactData.listing.radius
                            let latitude = (listingData["latitude"] as? Double) ?? self.contactData.listing.latitude
                            let longitude = (listingData["longitude"] as? Double) ?? self.contactData.listing.longitude
                            
                            print("[DEBUG MLV refreshListingData] Updated listing data - radius: \(radius), lat: \(latitude), lng: \(longitude)")
                            
                            let updatedListing = ContactListing(
                                listingId: self.contactData.listing.listingId,
                                currency: self.contactData.listing.currency,
                                amount: self.contactData.listing.amount,
                                acceptCurrency: self.contactData.listing.acceptCurrency,
                                preferredCurrency: self.contactData.listing.preferredCurrency,
                                meetingPreference: self.contactData.listing.meetingPreference,
                                location: self.contactData.listing.location,
                                latitude: latitude,
                                longitude: longitude,
                                radius: radius,
                                willRoundToNearestDollar: self.contactData.listing.willRoundToNearestDollar
                            )
                            
                            self.contactData = ContactData(
                                listing: updatedListing,
                                otherUser: self.contactData.otherUser,
                                lockedAmount: self.contactData.lockedAmount,
                                exchangeRate: self.contactData.exchangeRate,
                                fromCurrency: self.contactData.fromCurrency,
                                toCurrency: self.contactData.toCurrency,
                                purchasedAt: self.contactData.purchasedAt
                            )
                        }
                    } else {
                        print("[DEBUG MLV refreshListingData] WARNING: Could not find matching exchange for listing \(self.contactData.listing.listingId)")
                    }
                } else {
                    print("[DEBUG MLV refreshListingData] ERROR: Failed to parse response or invalid data")
                }
            }
        }.resume()
    }
    
    func respondToProposal(proposalId: String, response: String) {
        guard let session_id = SessionManager.shared.session_id else {
            print("ERROR: No session ID available")
            return
        }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/RespondToMeeting")!
        let queryItems = [
            URLQueryItem(name: "session_id", value: session_id),
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
                DispatchQueue.main.async {
                    if result.success {
                        print("✓ Responded to proposal: \(response)")
                    }
                }
            } catch {
                print("ERROR: Failed to parse response: \(error)")
            }
        }.resume()
    }
    
    func proposeLocation(location: MapSearchResult, message: String?) {
        guard let session_id = SessionManager.shared.session_id else {
            print("🔴 [MLV-PROPOSE] ERROR: No session ID available")
            return
        }
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/ProposeMeeting")!
        let queryItems = [
            URLQueryItem(name: "session_id", value: session_id),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId),
            URLQueryItem(name: "proposedLatitude", value: "\(location.coordinate.latitude)"),
            URLQueryItem(name: "proposedLongitude", value: "\(location.coordinate.longitude)"),
            URLQueryItem(name: "proposedLocation", value: location.name),
            URLQueryItem(name: "message", value: message ?? "")
        ]
        components.queryItems = queryItems
        
        guard let url = components.url else {
            print("🔴 ERROR: Failed to construct URL")
            return
        }
        
        print("🟡 [MLV-PROPOSE] Making request to: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("🔴 [MLV-PROPOSE] Network error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("🔴 [MLV-PROPOSE] No data received")
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let success = json["success"] as? Bool {
                    if success {
                        print("🟢 [MLV-PROPOSE] SUCCESS: Location proposal sent")
                        DispatchQueue.main.async {
                            self.successMessageText = localizationManager.localize("LOCATION_PROPOSAL_SENT")
                            self.showSuccessMessage = true
                            self.searchText = ""
                            self.searchResults = []
                            self.selectedResultId = nil
                            self.showLocationProposalConfirm = false
                            self.selectedLocationForProposal = nil
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.reloadMeetingProposals()
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                self.showSuccessMessage = false
                            }
                        }
                    } else {
                        let errorMsg = json["error"] as? String ?? "Unknown error"
                        print("🔴 [MLV-PROPOSE] Server error: \(errorMsg)")
                    }
                }
            } else {
                print("🔴 [MLV-PROPOSE] Failed to parse response")
            }
        }.resume()
    }
    
    func reloadMeetingProposals() {
        guard let session_id = SessionManager.shared.session_id else {
            print("[DEBUG MLV reloadMeetingProposals] ERROR: No session ID")
            return
        }
        
        print("[DEBUG MLV reloadMeetingProposals] Starting reload...")
        
        var components = URLComponents(string: "\(Settings.shared.baseURL)/Meeting/GetMeetingProposals")!
        components.queryItems = [
            URLQueryItem(name: "session_id", value: session_id),
            URLQueryItem(name: "listingId", value: contactData.listing.listingId)
        ]
        
        guard let url = components.url else {
            print("[DEBUG MLV reloadMeetingProposals] ERROR: Failed to construct URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("[DEBUG MLV reloadMeetingProposals] ERROR: Network error")
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool, success {
                    
                    if let proposalsData = json["data"] as? [[String: Any]] {
                        let newProposals = proposalsData.compactMap { dict -> MeetingProposal? in
                            guard let proposalId = dict["proposal_id"] as? String,
                                  let status = dict["status"] as? String,
                                  let proposedLocation = dict["proposed_location"] as? String else {
                                return nil
                            }
                            
                            let proposedTime = dict["proposed_time"] as? String ?? ""
                            let message = dict["message"] as? String
                            let isFromMe = dict["is_from_me"] as? Bool ?? false
                            let latitude = dict["proposed_latitude"] as? Double
                            let longitude = dict["proposed_longitude"] as? Double
                            
                            return MeetingProposal(
                                proposalId: proposalId,
                                proposedLocation: proposedLocation,
                                proposedTime: proposedTime,
                                message: message,
                                status: status,
                                isFromMe: isFromMe,
                                proposer: ProposerInfo(firstName: dict["proposed_by_name"] as? String ?? (dict["proposer"] as? [String: Any])?["first_name"] as? String ?? "Unknown"),
                                latitude: latitude,
                                longitude: longitude
                            )
                        }
                        
                        print("[DEBUG MLV reloadMeetingProposals] Loaded \(newProposals.count) proposals")
                        self.meetingProposals = newProposals
                        
                        if let acceptedProposal = newProposals.first(where: { $0.status == "accepted" }) {
                            self.currentMeeting = CurrentMeeting(
                                location: acceptedProposal.proposedLocation,
                                latitude: acceptedProposal.latitude,
                                longitude: acceptedProposal.longitude,
                                time: acceptedProposal.proposedTime,
                                message: acceptedProposal.message,
                                agreedAt: "",
                                acceptedAt: "",
                                locationAcceptedAt: ""
                            )
                        }
                    }
                } else {
                    print("[DEBUG MLV reloadMeetingProposals] ERROR: Failed to parse response")
                }
            }
        }.resume()
    }
}

// MARK: - Map Methods Extension

extension MeetingLocationView {
    func startCountdownTimer(meetingTime: String?) {
        guard let meetingTime = meetingTime else { return }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let meetingDate = isoFormatter.date(from: meetingTime) else { return }
        
        countdownTimer?.invalidate()
        
        updateCountdown(meetingDate: meetingDate)
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            updateCountdown(meetingDate: meetingDate)
        }
    }
    
    func updateCountdown(meetingDate: Date) {
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
    
    func zoomToShowUserAndMeeting() {
        guard let userCoord = locationManager.location?.coordinate else {
            if zoomRetryCount < 5 {
                zoomRetryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.zoomToShowUserAndMeeting()
                }
            }
            return
        }
        
        zoomRetryCount = 0
        
        let locationProposals = meetingProposals.filter { !$0.proposedLocation.isEmpty }
        
        if let proposedLocation = locationProposals.first,
           let proposedLat = proposedLocation.latitude,
           let proposedLng = proposedLocation.longitude {
            
            let proposedCoord = CLLocationCoordinate2D(latitude: proposedLat, longitude: proposedLng)
            
            let centerLat = (userCoord.latitude + proposedCoord.latitude) / 2
            let centerLng = (userCoord.longitude + proposedCoord.longitude) / 2
            let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
            
            let latDelta = abs(userCoord.latitude - proposedCoord.latitude) * 1.2
            let lngDelta = abs(userCoord.longitude - proposedCoord.longitude) * 1.2
            
            let maxZoomSpan = 0.004
            let span = MKCoordinateSpan(
                latitudeDelta: max(maxZoomSpan, latDelta),
                longitudeDelta: max(maxZoomSpan, lngDelta)
            )
            
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        } else {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: userCoord,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
    }
    
    func openAppleDirections(latitude: Double, longitude: Double, name: String) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    func centerMapOnListing() {
        let listingCoord = CLLocationCoordinate2D(
            latitude: contactData.listing.latitude,
            longitude: contactData.listing.longitude
        )
        
        let radiusKm = Double(contactData.listing.radius) * 1.60934
        let latitudeDelta = max(0.01, (radiusKm * 2.2) / 111.0)
        let longitudeDelta = latitudeDelta
        
        currentMapSpan = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
        let region = MKCoordinateRegion(
            center: listingCoord,
            span: currentMapSpan
        )
        
        cameraPosition = .region(region)
    }
    
    func zoomIn() {
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
    
    func zoomOut() {
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
    
    func centerMapOnResult(_ result: MapSearchResult) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        cameraPosition = .region(MKCoordinateRegion(center: result.coordinate, span: span))
    }
    
    func centerMapOnProposedLocation() {
        let locationProposals = meetingProposals.filter { !$0.proposedLocation.isEmpty }
        guard let proposedLocation = locationProposals.first,
              let lat = proposedLocation.latitude,
              let lng = proposedLocation.longitude else {
            return
        }
        
        let proposedCoord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        
        if let userCoord = locationManager.location?.coordinate {
            let centerLat = (userCoord.latitude + proposedCoord.latitude) / 2
            let centerLng = (userCoord.longitude + proposedCoord.longitude) / 2
            let centerCoord = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
            
            let latDiff = abs(userCoord.latitude - proposedCoord.latitude)
            let lngDiff = abs(userCoord.longitude - proposedCoord.longitude)
            
            let span = MKCoordinateSpan(latitudeDelta: latDiff * 1.3, longitudeDelta: lngDiff * 1.3)
            
            cameraPosition = .region(MKCoordinateRegion(center: centerCoord, span: span))
        } else {
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            cameraPosition = .region(MKCoordinateRegion(center: proposedCoord, span: span))
        }
    }
    
    func searchLocations() {
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
                
                if let error = error {
                    return
                }
                
                guard let response = response else {
                    return
                }
                
                let filteredResults = response.mapItems.enumerated().compactMap { index, mapItem -> MapSearchResult? in
                    let distance = haversineDistance(
                        lat1: listingCoord.latitude,
                        lon1: listingCoord.longitude,
                        lat2: mapItem.placemark.coordinate.latitude,
                        lon2: mapItem.placemark.coordinate.longitude
                    )
                    
                    if distance <= Double(contactData.listing.radius) {
                        let address = mapItem.placemark.title ?? mapItem.placemark.thoroughfare ?? ""
                        return MapSearchResult(
                            id: "\(index)",
                            name: mapItem.name ?? "Unknown",
                            coordinate: mapItem.placemark.coordinate,
                            address: address,
                            distance: distance
                        )
                    }
                    return nil
                }
                
                searchResults = filteredResults
            }
        }
    }
    
    func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 3959.0
        let dLat = (lat2 - lat1).toRadians
        let dLon = (lon2 - lon1).toRadians
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1.toRadians) * cos(lat2.toRadians) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }
}

extension Double {
    fileprivate var toRadians: Double {
        self * .pi / 180
    }
}
