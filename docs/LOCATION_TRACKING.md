# Location Tracking System for Real-Time Exchange Tracking

## Overview
Implements Uber-like real-time bilateral location tracking for currency exchange users. Both users can see each other's location within a 1-mile radius of their agreed meeting point, starting 1 hour before the scheduled exchange.

## Architecture

### Backend Services

#### LocationTrackingService.py (Server/Meeting/)
Core Python service handling all location logic:
- **Distance Calculation**: Uses Haversine formula for accurate distance in miles
- **Location Updates**: `update_user_location()` validates location is within 1-mile radius of meeting point
- **Time-Based Activation**: Checks if exchange is within 1-hour window before scheduled time
- **Location Retrieval**: `get_other_user_location()` fetches other participant's current location
- **Tracking Status**: `get_tracking_status()` confirms if tracking is active for a proposal

**Key Constants:**
```python
EARTH_RADIUS_MILES = 3959
TRACKING_RADIUS_MILES = 1.0
TRACKING_WINDOW_HOURS = 1
```

#### API Endpoints (Meeting.py)
Three new REST endpoints added to Flask Meeting blueprint:

1. **POST /Meeting/Location/Update**
   - Updates user's current location during exchange
   - Request: `{proposalId, sessionId, latitude, longitude}`
   - Response: `{success, distance, tracking_radius}` or error
   - Validates session and user participation in proposal

2. **GET /Meeting/Location/Get**
   - Retrieves other user's current location and details
   - Params: `proposalId, sessionId`
   - Response: `{otherUserId, name, latitude, longitude, distance_from_meeting, timestamp}`

3. **GET /Meeting/Location/Status**
   - Checks if tracking is currently enabled for an exchange
   - Params: `proposalId, sessionId`
   - Response: `{tracking_enabled, time_until_exchange_hours, tracking_window_hours, tracking_radius_miles}`

### iOS Services

#### UserLocationManager.swift
`@ObservableObject` singleton managing all location tracking:

**Published Properties:**
- `@Published var currentLocation: CLLocationCoordinate2D?` - User's GPS position
- `@Published var locationError: String?` - Permission/accuracy errors
- `@Published var isTracking: Bool` - Tracking active state
- `@Published var distanceFromMeeting: Double?` - Distance to meeting point in miles

**Key Methods:**
- `startTracking(proposalId, sessionId, meetingLat, meetingLon)` - Begin location updates
- `stopTracking()` - Stop updates and clean up timers
- `requestLocationPermission()` - Request "When In Use" permission
- `sendLocationUpdate()` - Posts location to server every 30 seconds

**Features:**
- Automatic location updates every 30 seconds via Timer
- Immediate first update on acquiring location
- Error handling for denied/unknown permissions
- Automatic distance calculation using CLLocation
- Background execution support

#### ExchangeMapView.swift
SwiftUI view displaying real-time location sharing:

**Map Features:**
- **Three Pin Types:**
  - Blue pin: Meeting point (agreed location)
  - Green pin: Current user's location
  - Red pin: Other user's location
- **Visual Elements:**
  - 1-mile radius circle boundary (blue, semi-transparent)
  - Status card showing your distance from meeting point
  - Other user card showing their name and distance
  - Real-time error messages and loading states

**Refresh Logic:**
- Fetches other user's location every 3 seconds
- Map automatically centers on meeting point
- Both users' positions update in real-time

**Error Handling:**
- Displays permission denial messages
- Shows acquisition errors
- Handles network failures gracefully

### Database Schema

#### user_locations Table
```sql
CREATE TABLE user_locations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id VARCHAR(255) NOT NULL,
    proposal_id VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    distance_from_meeting DECIMAL(10, 4),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_location (user_id, proposal_id),
    FOREIGN KEY (user_id) REFERENCES users(UserId),
    FOREIGN KEY (proposal_id) REFERENCES meeting_proposals(proposal_id),
    INDEX idx_proposal_timestamp (proposal_id, timestamp),
    INDEX idx_user_timestamp (user_id, timestamp)
);
```

#### location_audit_log Table
For privacy and debugging:
```sql
CREATE TABLE location_audit_log (
    id INTEGER PRIMARY KEY,
    user_id VARCHAR(255),
    proposal_id VARCHAR(255),
    action VARCHAR(50),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    distance_from_meeting DECIMAL(10, 4),
    error_message TEXT,
    ip_address VARCHAR(45),
    timestamp DATETIME
);
```

## Usage Flow

### 1. Meeting Acceptance (iOS)
```swift
// When user accepts meeting proposal:
navigationLink(destination: ExchangeMapView(
    sessionManager: sessionManager,
    locationManager: locationManager,
    proposalId: proposal.id,
    meetingLat: proposal.latitude,
    meetingLon: proposal.longitude,
    sessionId: sessionManager.sessionId
))
```

### 2. Location Permission
```swift
// ExchangeMapView.onAppear:
locationManager.requestLocationPermission()
locationManager.startTracking(proposalId, sessionId, meetingLat, meetingLon)
```

### 3. Periodic Updates (Every 30 Seconds)
```
Client: POST /Meeting/Location/Update
        {proposalId, sessionId, latitude, longitude}
Server: Validates time window (1 hour before)
        Validates distance (<1 mile from meeting point)
        Stores in user_locations table
        Returns: {success, distance}
```

### 4. Real-Time Display (Every 3 Seconds)
```
Client: GET /Meeting/Location/Get?proposalId=X&sessionId=Y
Server: Retrieves other user's latest location
        Returns: {latitude, longitude, name, distance_from_meeting}
Client: Updates map with other user's pin
```

### 5. Automatic Deactivation
- Tracking stops automatically after 1 hour (past meeting time)
- Manual stop when user dismisses map view
- Error state if location permission denied

## Localization

Location tracking strings added to all 11 languages:
- `loading_map` - "Loading map..."
- `meeting_point` - "Meeting Point"
- `miles` - "miles" (or equivalent unit)
- `you` - "You"
- `finding_other_user` - "Finding other user..."

Updated language files:
- en.lproj, es.lproj, fr.lproj, de.lproj, pt.lproj
- ja.lproj, zh-Hans.lproj, ru.lproj, ar.lproj, hi.lproj, sk.lproj

## Security & Privacy

1. **Session Validation**: All endpoints verify valid, non-expired session
2. **User Participation**: Ensures only exchange participants can access locations
3. **Radius Constraint**: Location only stored if within 1-mile radius
4. **Time Window**: Prevents tracking outside 1-hour window before/after meeting
5. **Audit Logging**: All location updates logged for dispute resolution
6. **Automatic Cleanup**: No persistent location history after exchange completes

## Setup Instructions

### 1. Run Database Migration
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
python migrate_location_tracking.py
```

### 2. Update Meeting Acceptance Flow
Modify `Server/Meeting/RespondToMeeting.py` to trigger location tracking notification to iOS client.

### 3. Add MapKit Capability to iOS Project
In Xcode:
- Select project → NiceTradersApp target
- Capabilities → Maps (enabled)

### 4. Add Location Permission in Info.plist
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Nice Traders needs your location to show you and other users during exchanges within 1 mile of the meeting point.</string>
```

### 5. Integrate ExchangeMapView in Proposal Flow
Link to ExchangeMapView when user accepts a meeting proposal.

## Distance Calculation

Uses Haversine formula for great-circle distances:
```
a = sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlon/2)
c = 2 × asin(√a)
d = R × c  (R = Earth's radius in miles = 3959)
```

**Accuracy:** ±0.5% (excellent for 1-mile radius detection)

## Testing Checklist

- [ ] Create test proposals with meeting locations
- [ ] Verify location updates POST endpoint accepts valid coordinates
- [ ] Test distance validation (inside/outside 1-mile radius)
- [ ] Verify time window enforcement (1 hour before/after)
- [ ] Test location retrieval GET endpoint
- [ ] Verify both users see each other on map
- [ ] Test location permission denial handling
- [ ] Verify tracking stops after 1 hour
- [ ] Test error message displays
- [ ] Verify no location history persists after exchange
- [ ] Test in multiple languages
- [ ] Verify audit log entries created

## Future Enhancements

1. **Live Activity** - iOS 16.1+ live updates without fetching
2. **Map Callouts** - Tap to see user details/contact info
3. **ETA Calculation** - Estimated arrival time to meeting point
4. **Traffic Awareness** - Show traffic conditions on route
5. **Geofencing** - Automatic completion when both in meeting location
6. **Safety Features** - Share with trusted contacts during exchange
7. **Replay** - View meeting timeline after completion
8. **Analytics** - Track if users typically arrive early/late

## Files Modified/Created

**New Files:**
- `Server/Meeting/LocationTrackingService.py` (220 lines)
- `Server/migrate_location_tracking.py` (60 lines)
- `Client/IOS/Nice Traders/Nice Traders/UserLocationManager.swift` (180 lines)
- `Client/IOS/Nice Traders/Nice Traders/ExchangeMapView.swift` (350 lines)

**Updated Files:**
- `Server/Meeting/Meeting.py` (added 3 endpoints)
- 11 language Localizable.strings files (added 5 keys each)

**Total LOC:** ~810 lines of new code
