# Meeting Location View - Debug Logging

## What Was Added

Added comprehensive debugging to `MeetingLocationView.swift` to track:
1. Listing coordinates (latitude/longitude)
2. Map initialization and centering
3. Radius calculations
4. Search location results
5. Location proposal coordinates

## Debug Output Locations

### 1. **Visual Debug Banner** (top of map view)
- Shows listing latitude/longitude with 4 decimal places
- Shows radius in miles
- Yellow background for easy visibility
- Displays at the top of the Meeting Location tab

```
[DEBUG] Listing Location: 37.7749, -122.4194
[DEBUG] Radius: 5 miles
```

### 2. **Console Debug Prints**

When the Meeting Location view appears:
```
[DEBUG MLV] MeetingLocationView appeared
[DEBUG MLV] Listing: 37.7749, -122.4194
[DEBUG MLV] Radius: 5
[DEBUG MLV] WARNING: Listing coordinates are 0,0!  // <-- If coordinates are invalid
```

When the map initializes:
```
[DEBUG MLV] Map initializing...
[DEBUG MLV] Map appeared - centering on listing
[DEBUG MLV] Listing lat: 37.7749, lng: -122.4194
```

When centering on listing:
```
[DEBUG MLV centerMapOnListing] Starting...
[DEBUG MLV centerMapOnListing] Listing coordinate: 37.7749, -122.4194
[DEBUG MLV centerMapOnListing] Radius: 5 miles
[DEBUG MLV centerMapOnListing] Calculated radius in km: 8.0467
[DEBUG MLV centerMapOnListing] Latitude delta: 0.145, Longitude delta: 0.145
[DEBUG MLV centerMapOnListing] Setting camera position to region: center=(37.7749, -122.4194), span=(0.145, 0.145)
```

When searching locations:
```
[DEBUG MLV searchLocations] Starting search for: 'coffee'
[DEBUG MLV searchLocations] Search center: 37.7749, -122.4194
[DEBUG MLV searchLocations] Radius: 5 miles
[DEBUG MLV searchLocations] Found 15 total results
[DEBUG MLV searchLocations] Result 0: 'Blue Bottle Coffee' at 37.7761, -122.4179 - distance: 0.15 miles
[DEBUG MLV searchLocations]   ✓ Within radius
[DEBUG MLV searchLocations] Result 1: 'Starbucks' at 37.7680, -122.4295 - distance: 1.23 miles
[DEBUG MLV searchLocations]   ✓ Within radius
[DEBUG MLV searchLocations] Filtered to 10 results within radius
```

When proposing a location:
```
[DEBUG MLV proposeLocation] Proposing location: 'Blue Bottle Coffee'
[DEBUG MLV proposeLocation] Coordinates: 37.7761, -122.4179
[DEBUG MLV proposeLocation] Meeting time: 2025-12-12T14:30:00Z
[DEBUG MLV proposeLocation] Sending request to: https://api.example.com/Meeting/ProposeMeeting?...
[DEBUG MLV proposeLocation] Response: {"success": true, "proposal_id": "12345"}
```

## What to Look For

### If coordinates are 0,0 (middle of ocean):
1. **Yellow debug banner** will show: `[DEBUG] Listing Location: 0.0000, 0.0000`
2. **Console will show**: `[DEBUG MLV] WARNING: Listing coordinates are 0,0!`
3. **This indicates**: The listing data wasn't loaded properly from the backend

### If map doesn't center properly:
1. Check the debug prints for `centerMapOnListing`
2. Verify latitude/longitude delta values are reasonable
3. Check if camera position is being set correctly

### If search results are wrong:
1. Check the console for "Found X total results"
2. Check the filter output showing which results are within radius
3. Verify the distance calculations match expectations

## Testing

To see the debug output:
1. Run the iOS app
2. Open a contact's details
3. Tap the "📍 Location" tab
4. Open Xcode's Console (View → Debug Area → Show Debug Area)
5. Filter by "MLV" to see Meeting Location View logs

## When to Remove

Keep these debug prints until you've verified:
- [ ] Listing coordinates are correct (not 0,0)
- [ ] Map centers on San Francisco (or correct location)
- [ ] Circle displays with correct radius
- [ ] Search results are filtered correctly
- [ ] Location proposals send correct coordinates

Then remove the yellow debug banner and console prints.
