import SwiftUI
import MapKit

struct ExchangeMapView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var locationManager: UserLocationManager
    @State private var otherUserLocation: CLLocationCoordinate2D?
    @State private var otherUserName: String = "Other User"
    @State private var updateError: String?
    @State private var isLoadingOtherLocation = false
    @State private var region: MKCoordinateRegion?
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var mapScale: Double = 0.05 // in degrees, about 5 miles
    
    let proposalId: String
    let meetingLat: Double
    let meetingLon: Double
    let session_id: String
    
    private let localizationManager = LocalizationManager.shared
    private let fetchInterval: TimeInterval = 3 // Fetch other user location every 3 seconds
    @State private var locationFetchTimer: Timer?
    
    var body: some View {
        ZStack {
            // Map View
            if let region = region {
                Map(position: $mapPosition) {
                    // Meeting point marker (blue pin)
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: meetingLat, longitude: meetingLon)) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .shadow(radius: 2)
                            Text(localizationManager.localize("meeting_point"))
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Current user location (green pin)
                    if let userLocation = locationManager.currentLocation {
                        Annotation("", coordinate: userLocation) {
                            VStack {
                                Image(systemName: "location.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                    .shadow(radius: 2)
                                Text(localizationManager.localize("you"))
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    // Other user location (red pin)
                    if let otherLocation = otherUserLocation {
                        Annotation("", coordinate: otherLocation) {
                            VStack {
                                Image(systemName: "location.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .shadow(radius: 2)
                                Text(otherUserName)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Draw 1-mile radius circle around meeting point
                    MapCircle(center: CLLocationCoordinate2D(latitude: meetingLat, longitude: meetingLon), radius: 1609.34) // 1 mile in meters
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .foregroundStyle(Color.blue.opacity(0.1))
                }
                .mapStyle(.standard)
                .onAppear {
                    setupInitialMap()
                }
            } else {
                VStack {
                    ProgressView()
                    Text(localizationManager.localize("loading_map"))
                        .font(.caption)
                }
                .onAppear {
                    setupInitialMap()
                }
            }
            
            // Overlay cards
            VStack {
                // Status card at top
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                            Text(localizationManager.localize("meeting_point"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let distance = locationManager.distanceFromMeeting {
                            HStack {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.green)
                                Text(String(format: "%.2f %s", distance, localizationManager.localize("miles")))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if let error = locationManager.locationError {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption2)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: centerOnMeeting) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 2)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
                .padding()
                
                Spacer()
                
                // Other user location card at bottom
                if let otherLocation = otherUserLocation {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                Text(otherUserName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            
                            if let yourDistance = locationManager.distanceFromMeeting {
                                let meetingPoint = CLLocation(latitude: meetingLat, longitude: meetingLon)
                                let otherUserLoc = CLLocation(latitude: otherLocation.latitude, longitude: otherLocation.longitude)
                                let distanceToOther = meetingPoint.distance(from: otherUserLoc) * 0.000621371
                                
                                HStack {
                                    Image(systemName: "person.2")
                                        .font(.system(size: 12))
                                        .foregroundColor(.purple)
                                    Text(String(format: "%.2f %s away", distanceToOther, localizationManager.localize("miles")))
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if isLoadingOtherLocation {
                            ProgressView()
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .padding()
                } else if isLoadingOtherLocation {
                    HStack {
                        ProgressView()
                        Text(localizationManager.localize("finding_other_user"))
                            .font(.caption)
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .padding()
                }
            }
            
            // Error overlay
            if let error = updateError {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.caption)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            // Request location permission
            locationManager.requestLocationPermission()
            
            // Start tracking
            locationManager.startTracking(
                proposalId: proposalId,
                session_id: session_id,
                meetingLat: meetingLat,
                meetingLon: meetingLon
            )
            
            // Start fetching other user's location
            startFetchingOtherUserLocation()
        }
        .onDisappear {
            locationManager.stopTracking()
            locationFetchTimer?.invalidate()
        }
    }
    
    private func setupInitialMap() {
        let initialRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: meetingLat, longitude: meetingLon),
            span: MKCoordinateSpan(latitudeDelta: mapScale, longitudeDelta: mapScale)
        )
        region = initialRegion
        mapPosition = .region(initialRegion)
    }
    
    private func centerOnMeeting() {
        let meetingRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: meetingLat, longitude: meetingLon),
            span: MKCoordinateSpan(latitudeDelta: mapScale, longitudeDelta: mapScale)
        )
        mapPosition = .region(meetingRegion)
    }
    
    private func startFetchingOtherUserLocation() {
        locationFetchTimer = Timer.scheduledTimer(withTimeInterval: fetchInterval, repeats: true) { _ in
            fetchOtherUserLocation()
        }
        // Fetch immediately
        fetchOtherUserLocation()
    }
    
    private func fetchOtherUserLocation() {
        isLoadingOtherLocation = true
        
        let endpoint = "http://localhost:5000/Meeting/Location/Get?proposalId=\(proposalId)&session_id=\(session_id)"
        
        guard let url = URL(string: endpoint) else {
            updateError = "Invalid endpoint"
            isLoadingOtherLocation = false
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoadingOtherLocation = false
                
                if let error = error {
                    self?.updateError = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.updateError = "No data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let success = json["success"] as? Bool, success {
                            if let lat = json["latitude"] as? Double,
                               let lon = json["longitude"] as? Double,
                               let name = json["name"] as? String {
                                self?.otherUserLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                self?.otherUserName = name
                                self?.updateError = nil
                            }
                        } else if let error = json["error"] as? String {
                            self?.updateError = error
                        }
                    }
                } catch {
                    self?.updateError = "Failed to parse response"
                }
            }
        }
        
        task.resume()
    }
}

#Preview {
    ExchangeMapView(
        sessionManager: SessionManager(),
        locationManager: UserLocationManager(),
        proposalId: "test-proposal",
        meetingLat: 40.7128,
        meetingLon: -74.0060,
        session_id: "test-session"
    )
}
