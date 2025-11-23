# iOS Info.plist Requirements for MapKit Integration

## Required Privacy Keys

To enable MapKit and location services in the Nice Traders iOS app, you need to add the following keys to your `Info.plist` file:

### Location Permissions

Add these keys to request location access:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Nice Traders needs your location to show nearby currency exchange listings on the map and calculate distances to traders.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Nice Traders needs your location to show nearby currency exchange listings on the map and calculate distances to traders.</string>
```

## How to Add to Xcode

1. Open the Xcode project: `Nice Traders.xcodeproj`
2. Select the project in the navigator
3. Select the "Nice Traders" target
4. Go to the "Info" tab
5. Hover over any row and click the "+" button
6. Add the keys above with their descriptions

Alternatively, you can:
1. Right-click on the project in Xcode
2. Select "Show in Finder"
3. Right-click on `Info.plist` and open with a text editor
4. Add the XML keys above before the closing `</dict>` tag

## MapKit Capabilities

MapKit should work automatically on iOS without additional entitlements, but ensure:

1. MapKit framework is imported in files that use it (`import MapKit`)
2. The app has location permissions as described above
3. The device/simulator has location services enabled in Settings

## Testing Location Services

### In Simulator:
- Go to Features → Location in the simulator menu
- Choose a preset location (e.g., "Apple", "City Run", "Custom Location")
- Or use Debug → Simulate Location in Xcode

### On Device:
- Grant location permission when prompted
- Ensure Location Services are enabled in Settings → Privacy → Location Services
- Check that Nice Traders has "While Using the App" permission

## Features Implemented

✅ Map view toggle in search interface
✅ Custom map pins showing listing amounts
✅ User location display on map
✅ Distance calculations from user to listings
✅ Distance display in listing cards
✅ Sort by distance functionality
✅ "Find Near Me" button (10km radius)
✅ Map automatically zooms to show all listings and user location
✅ Callout views for selected listings on map
✅ Smooth transitions between map and list views

## Next Steps (Optional Enhancements)

- [ ] Implement pin clustering for better performance with many listings
- [ ] Add location search/geocoding for listings without coordinates
- [ ] Add route directions to listing location
- [ ] Add ability to filter by custom distance radius
- [ ] Add heat map for listing density
- [ ] Save favorite locations
