//
//  MeetingLocationView+Map.swift
//  Nice Traders
//
//  Map utilities and calculations for MeetingLocationView

import SwiftUI
import MapKit

extension MeetingLocationView {
    func startCountdownTimer(meetingTime: String?) {
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
            print("[DEBUG MLV] zoomToShowUserAndMeeting: No user location available - will retry")
            print("[DEBUG MLV] locationManager.location: \(String(describing: locationManager.location))")
            print("[DEBUG MLV] Retry count: \(zoomRetryCount)")
            
            // Retry up to 5 times with 1 second delay
            if zoomRetryCount < 5 {
                zoomRetryCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("[DEBUG MLV] Retrying zoom (attempt \(self.zoomRetryCount))...")
                    self.zoomToShowUserAndMeeting()
                }
            } else {
                print("[DEBUG MLV] FAILED: Could not get user location after 5 retries")
            }
            return
        }
        
        print("[DEBUG MLV] zoomToShowUserAndMeeting: SUCCESS - Got user location: \(userCoord.latitude), \(userCoord.longitude)")
        print("[DEBUG MLV] zoomToShowUserAndMeeting: Total meetingProposals: \(meetingProposals.count)")
        zoomRetryCount = 0  // Reset retry count on success
        
        // Get proposed location if it exists
        let locationProposals = meetingProposals.filter { !$0.proposedLocation.isEmpty }
        print("[DEBUG MLV] zoomToShowUserAndMeeting: Location proposals with proposedLocation: \(locationProposals.count)")
        
        if let proposedLocation = locationProposals.first,
           let proposedLat = proposedLocation.latitude,
           let proposedLng = proposedLocation.longitude {
            
            print("[DEBUG MLV] zoomToShowUserAndMeeting: Found proposed location: \(proposedLat), \(proposedLng)")
            
            // Calculate region that fits both user location and proposed location
            let proposedCoord = CLLocationCoordinate2D(latitude: proposedLat, longitude: proposedLng)
            
            // Calculate center point between the two locations
            let centerLat = (userCoord.latitude + proposedCoord.latitude) / 2
            let centerLng = (userCoord.longitude + proposedCoord.longitude) / 2
            let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
            
            // Calculate the span to fit both points with some padding
            let latDelta = abs(userCoord.latitude - proposedCoord.latitude) * 1.2
            let lngDelta = abs(userCoord.longitude - proposedCoord.longitude) * 1.2
            
            print("[DEBUG MLV] Calculated latDelta: \(latDelta), lngDelta: \(lngDelta)")
            
            // Maximum zoom level (minimum span) for close distances
            let maxZoomSpan = 0.004
            let span = MKCoordinateSpan(
                latitudeDelta: max(maxZoomSpan, latDelta),
                longitudeDelta: max(maxZoomSpan, lngDelta)
            )
            
            print("[DEBUG MLV] Final span: latitudeDelta=\(span.latitudeDelta), longitudeDelta=\(span.longitudeDelta)")
            print("[DEBUG MLV] Setting camera to center=(\(center.latitude), \(center.longitude))")
            
            let region = MKCoordinateRegion(center: center, span: span)
            print("[DEBUG MLV] Camera position region: \(region)")
            
            cameraPosition = .region(region)
            print("[DEBUG MLV] ✅ Camera position set successfully")
        } else {
            print("[DEBUG MLV] zoomToShowUserAndMeeting: No proposed location found, centering on user")
            print("[DEBUG MLV] Default zoom span: 0.01 x 0.01")
            // No proposed location yet, center on user with more zoom
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: userCoord,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
            print("[DEBUG MLV] ✅ Camera position set to user location")
        }
    }
    
    func openAppleDirections(latitude: Double, longitude: Double, name: String) {
        let destinationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let mapItem = MKMapItem(
            location: CLLocationCoordinate2DMake(destinationCoordinate.latitude, destinationCoordinate.longitude)
        )
        mapItem.name = name
        
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    func centerMapOnListing() {
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
    
    func searchLocations() {
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
    
    func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 3959.0  // Earth's radius in miles
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
