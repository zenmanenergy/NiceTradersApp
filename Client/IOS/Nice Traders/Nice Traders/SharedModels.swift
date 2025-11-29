//
//  SharedModels.swift
//  Nice Traders
//
//  Shared data models and extensions used across the app
//

import SwiftUI
import UIKit
import CoreLocation
import Combine

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Location Manager

import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var placemark: CLPlacemark?
    private let geocoder = CLGeocoder()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Start location updates immediately
        manager.requestWhenInUseAuthorization()
        #if targetEnvironment(simulator)
        // In simulator, start continuous updates to pick up simulated locations from Xcode
        manager.startUpdatingLocation()
        print("[LocationManager] Started continuous location updates (simulator)")
        #else
        // On real devices, also start continuous updates
        manager.startUpdatingLocation()
        print("[LocationManager] Started continuous location updates (device)")
        #endif
    }
    
    func requestLocation() {
        #if targetEnvironment(simulator)
        // Already updating continuously in simulator
        #else
        manager.requestLocation()
        #endif
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
        print("[LocationManager] Location updated: \(location?.coordinate.latitude ?? 0), \(location?.coordinate.longitude ?? 0)")
        
        // Reverse geocode to get city name
        if let location = location {
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                if let placemark = placemarks?.first {
                    DispatchQueue.main.async {
                        self?.placemark = placemark
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Location error: \(error.localizedDescription)")
        // Don't use hardcoded fallback locations - let the app handle no location gracefully
    }
}

// MARK: - Search Models

struct SearchListing: Identifiable, Codable, Equatable {
    let id: String
    let listingId: String
    let currency: String
    let amount: Double
    let acceptCurrency: String
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let meetingPreference: String
    let availableUntil: String?
    let status: String
    let createdAt: String?
    let user: ListingUser
    
    // Calculate approximate distance (coordinates are already randomized for privacy)
    func approximateDistance(from userLocation: CLLocation?) -> Double? {
        guard let userLoc = userLocation,
              let lat = latitude,
              let lon = longitude else {
            return nil
        }
        
        let listingLocation = CLLocation(latitude: lat, longitude: lon)
        return userLoc.distance(from: listingLocation) / 1000.0 // Convert to km
    }
    
    func approximateDistanceString(from userLocation: CLLocation?) -> String {
        guard let dist = approximateDistance(from: userLocation) else {
            return ""
        }
        
        // Round to nearest km for approximate display
        if dist < 1 {
            return "< 1 km away"
        } else {
            return "~\(Int(dist)) km away"
        }
    }
    
    struct ListingUser: Codable, Equatable {
        let firstName: String
        let lastName: String?
        let rating: Double?
        let trades: Int?
        let verified: Bool?
    }
}
