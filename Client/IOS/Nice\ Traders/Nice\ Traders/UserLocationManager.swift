import CoreLocation
import Foundation
import Combine

class UserLocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var locationError: String?
    @Published var isTracking = false
    @Published var distanceFromMeeting: Double?
    
    private let locationManager = CLLocationManager()
    private var updateTimer: Timer?
    private let updateInterval: TimeInterval = 30 // Update every 30 seconds
    
    // Configuration
    private var proposalId: String = ""
    private var sessionId: String = ""
    private var meetingCoordinate: CLLocationCoordinate2D?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startTracking(proposalId: String, sessionId: String, meetingLat: Double, meetingLon: Double) {
        self.proposalId = proposalId
        self.sessionId = sessionId
        self.meetingCoordinate = CLLocationCoordinate2D(latitude: meetingLat, longitude: meetingLon)
        
        isTracking = true
        
        // Request location permission if not granted
        let status = CLLocationManager.authorizationStatus()
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
            setupPeriodicUpdates()
        }
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Private Methods
    
    private func setupPeriodicUpdates() {
        // Update server every 30 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.sendLocationUpdate()
        }
    }
    
    private func sendLocationUpdate() {
        guard let location = currentLocation,
              !proposalId.isEmpty,
              !sessionId.isEmpty else {
            return
        }
        
        let endpoint = "http://localhost:5000/Meeting/Location/Update"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "proposalId": proposalId,
            "sessionId": sessionId,
            "latitude": location.latitude,
            "longitude": location.longitude
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.locationError = "Failed to update location: \(error.localizedDescription)"
                    }
                    return
                }
                
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let distance = json["distance"] as? Double {
                            DispatchQueue.main.async {
                                self?.distanceFromMeeting = distance
                                self?.locationError = nil
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self?.locationError = "Invalid server response"
                        }
                    }
                }
            }
            task.resume()
        } catch {
            locationError = "Failed to encode location data"
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
            self.locationError = nil
            
            // Calculate distance to meeting point
            if let meetingCoord = self.meetingCoordinate {
                let meetingLocation = CLLocation(latitude: meetingCoord.latitude, longitude: meetingCoord.longitude)
                let distance = location.distance(from: meetingLocation) * 0.000621371 // Convert meters to miles
                self.distanceFromMeeting = distance
            }
        }
        
        // Send update to server immediately on first location
        if updateTimer == nil && isTracking {
            sendLocationUpdate()
            setupPeriodicUpdates()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = "Location permission denied. Enable in Settings > Nice Traders > Location"
                case .locationUnknown:
                    self.locationError = "Acquiring location..."
                default:
                    self.locationError = "Location error: \(clError.localizedDescription)"
                }
            } else {
                self.locationError = error.localizedDescription
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = CLLocationManager.authorizationStatus()
        DispatchQueue.main.async {
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationError = nil
                if self.isTracking {
                    manager.startUpdatingLocation()
                }
            case .denied, .restricted:
                self.locationError = "Location permission required for real-time exchange tracking"
                self.stopTracking()
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}
