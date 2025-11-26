import SwiftUI
import MapKit
import CoreLocation

struct ExchangeMapView: View {
    @ObservedObject var sessionManager: SessionManager
    @ObservedObject var locationManager: UserLocationManager
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    let proposalId: String
    let meetingLat: Double
    let meetingLon: Double
    let sessionId: String
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var otherUserLocation: CLLocation? = nil
    @State private var isLoadingOtherUser = true
    
    var body: some View {
        ZStack {
            // Map View
            Map(position: $cameraPosition) {
                // User's current location
                if let userLocation = locationManager.location {
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 44, height: 44)
                            
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 50, height: 50)
                            
                            Text(localizationManager.localize("YOU"))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Other user's location
                if let otherLocation = otherUserLocation {
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: otherLocation.coordinate.latitude, longitude: otherLocation.coordinate.longitude)) {
                        ZStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 44, height: 44)
                            
                            Circle()
                                .stroke(Color.orange, lineWidth: 2)
                                .frame(width: 50, height: 50)
                        }
                    }
                }
                
                // Meeting point
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: meetingLat, longitude: meetingLon)) {
                    VStack {
                        Image(systemName: "location.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        Text(localizationManager.localize("MEETING_POINT"))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            .mapStyle(.standard)
            .onAppear {
                setInitialCamera()
                fetchOtherUserLocation()
            }
            
            // Loading indicator
            if isLoadingOtherUser {
                VStack {
                    ProgressView()
                    Text(localizationManager.localize("FINDING_OTHER_USER"))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .padding()
            }
        }
        .navigationTitle(localizationManager.localize("LOADING_MAP"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func setInitialCamera() {
        let meetingPoint = CLLocationCoordinate2D(latitude: meetingLat, longitude: meetingLon)
        cameraPosition = .region(MKCoordinateRegion(
            center: meetingPoint,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
    
    private func fetchOtherUserLocation() {
        let url = URL(string: "\(Settings.shared.baseURL)/Meeting/Location/Get?proposalId=\(proposalId)&sessionId=\(sessionId)")!
        var request = URLRequest(url: url)
        request.setValue(sessionId, forHTTPHeaderField: "Session-ID")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                defer { isLoadingOtherUser = false }
                
                guard let data = data, error == nil else {
                    print("Error fetching other user location: \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let latitude = json["latitude"] as? Double,
                       let longitude = json["longitude"] as? Double {
                        otherUserLocation = CLLocation(latitude: latitude, longitude: longitude)
                    }
                } catch {
                    print("Error parsing location: \(error)")
                }
            }
        }.resume()
    }
}

#Preview {
    ExchangeMapView(
        sessionManager: SessionManager.shared,
        locationManager: UserLocationManager(),
        proposalId: "prop-123",
        meetingLat: 40.7128,
        meetingLon: -74.0060,
        sessionId: "sess-456"
    )
}
