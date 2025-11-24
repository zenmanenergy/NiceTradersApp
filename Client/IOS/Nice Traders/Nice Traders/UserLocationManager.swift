import Foundation
import CoreLocation
import Combine

class UserLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var isTracking = false
    
    private let locationManager = CLLocationManager()
    private var updateTimer: Timer?
    private let locationUpdateInterval: TimeInterval = 30 // Update every 30 seconds
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: - Location Permissions
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Tracking
    
    func startTracking(proposalId: String, sessionId: String, meetingLat: Double, meetingLon: Double) {
        isTracking = true
        locationManager.startUpdatingLocation()
        
        // Set up periodic updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: locationUpdateInterval, repeats: true) { [weak self] _ in
            self?.sendLocationUpdate(proposalId: proposalId, sessionId: sessionId)
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
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    // MARK: - Backend Communication
    
    private func sendLocationUpdate(proposalId: String, sessionId: String) {
        guard let location = location else { return }
        
        let url = URL(string: "http://localhost:5000/api/meeting/update-location")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "proposal_id": proposalId,
            "session_id": sessionId,
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            URLSession.shared.dataTask(with: request).resume()
        } catch {
            print("Error sending location: \(error)")
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
