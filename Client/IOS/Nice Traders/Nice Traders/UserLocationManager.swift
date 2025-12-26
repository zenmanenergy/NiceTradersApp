import Foundation
import CoreLocation
import Combine

class UserLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = UserLocationManager()
    
    @Published var location: CLLocation?
    @Published var isTracking = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private let locationManager = CLLocationManager()
    private var updateTimer: Timer?
    private let locationUpdateInterval: TimeInterval = 30 // Update every 30 seconds
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Location Permissions
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation() {
        requestLocationPermission()
    }
    
    // MARK: - Tracking
    
    func startTracking(proposalId: String, session_id: String, meetingLat: Double, meetingLon: Double) {
        isTracking = true
        locationManager.startUpdatingLocation()
        
        // Set up periodic updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: locationUpdateInterval, repeats: true) { [weak self] _ in
            self?.sendLocationUpdate(proposalId: proposalId, session_id: session_id)
        }
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Location Updates
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    
    // MARK: - Backend Communication
    
    private func sendLocationUpdate(proposalId: String, session_id: String) {
        guard let location = location else { return }
        
        let url = URL(string: "\(Settings.shared.baseURL)/Meeting/Location/Update")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "proposal_id": proposalId,
            "session_id": session_id,
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            URLSession.shared.dataTask(with: request).resume()
        } catch {
        }
    }
    
    // MARK: - Helper Methods
    
    func distanceTo(latitude: Double, longitude: Double) -> CLLocationDistance? {
        guard let currentLocation = location else { return nil }
        let targetLocation = CLLocation(latitude: latitude, longitude: longitude)
        return currentLocation.distance(from: targetLocation)
    }
    
    func distanceInMiles(to latitude: Double, longitude: Double) -> Double? {
        guard let distance = distanceTo(latitude: latitude, longitude: longitude) else { return nil }
        return distance / 1609.34 // Convert meters to miles
    }
}
