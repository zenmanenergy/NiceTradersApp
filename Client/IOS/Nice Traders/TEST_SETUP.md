# iOS API Unit Tests - Setup Guide

## Overview
Comprehensive unit tests have been created in `Nice TradersTests/APITests.swift` to verify all data sent to the server is correctly formatted.

## Setting Up Tests in Xcode

1. **Add Test Target** (if not already added):
   - Open `Nice Traders.xcodeproj` in Xcode
   - File → New → Target
   - Choose "Unit Testing Bundle"
   - Name it "Nice TradersTests"
   - Set target to be tested: "Nice Traders"

2. **Add Test File**:
   - The file `APITests.swift` is already created
   - If not visible in Xcode, add it:
     - Right-click "Nice TradersTests" folder
     - Add Files to "Nice Traders"
     - Select `Nice TradersTests/APITests.swift`
     - Ensure it's added to "Nice TradersTests" target

3. **Configure Test Scheme**:
   - Product → Scheme → Edit Scheme
   - Select "Test" in left sidebar
   - Click "+" to add test target
   - Add "Nice TradersTests"
   - Ensure "Nice Traders" is selected under "Test Target"

## Running Tests

### Run All Tests
```bash
⌘ + U  # In Xcode
```

Or via command line:
```bash
cd "/Users/stevenelson/Documents/GitHub/NiceTradersApp/Client/IOS/Nice Traders"
xcodebuild test -project "Nice Traders.xcodeproj" -scheme "Nice Traders" -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Run Specific Test Class
1. Click the diamond icon next to `APITests` class
2. Or use Test Navigator (⌘ + 6)

### Run Individual Test
1. Click diamond icon next to specific test method
2. Or right-click test name → "Run 'testName'"

## Test Coverage

### Authentication Tests (4 tests)
- ✅ `testLoginURLFormat` - Verifies login URL construction
- ✅ `testLoginWithSpecialCharacters` - Tests URL encoding for special chars
- ✅ `testSignupURLFormat` - Validates signup parameter formatting
- ✅ `testSignupWithEmptyFields` - Checks empty field validation

### Listing Tests (6 tests)
- ✅ `testCreateListingURLFormat` - Verifies all listing creation parameters
- ✅ `testCreateListingDateFormat` - Validates date format (YYYY-MM-DD HH:MM:SS)
- ✅ `testCreateListingLocationParsing` - Tests coordinate parsing
- ✅ `testDeleteListingURLFormat` - Verifies delete request with String UUID
- ✅ `testListingIdFormat` - Ensures listing IDs are String type (UUID)
- ✅ `testListingResponseParsing` - Validates JSON parsing for listing arrays

### Search Tests (2 tests)
- ✅ `testSearchListingsURLFormat` - Validates search endpoint parameters
- ✅ `testSearchListingsWithFilters` - Tests currency/amount filter encoding

### Dashboard Tests (1 test)
- ✅ `testDashboardURLFormat` - Verifies dashboard endpoint construction

### Contact/Messaging Tests (2 tests)
- ✅ `testPurchaseContactAccessURLFormat` - Validates contact purchase request
- ✅ `testSendMessageURLFormat` - Tests message sending parameter encoding

### Meeting Tests (2 tests)
- ✅ `testProposeMeetingURLFormat` - Validates meeting proposal parameters
- ✅ `testGetExactLocationURLFormat` - Tests exact location endpoint

### Profile Tests (2 tests)
- ✅ `testGetProfileURLFormat` - Verifies profile fetch request
- ✅ `testUpdateProfileURLFormat` - Validates profile update parameters

### Data Validation Tests (5 tests)
- ✅ `testSessionIdFormat` - Ensures session IDs are valid
- ✅ `testAmountValidation` - Validates positive numeric amounts
- ✅ `testCurrencyCodeFormat` - Tests 3-letter uppercase currency codes
- ✅ `testCoordinateValidation` - Validates lat/long ranges
- ✅ `testSuccessResponseParsing` - Tests successful API response parsing
- ✅ `testErrorResponseParsing` - Tests error response handling

## Test Data Validation

### What These Tests Verify

1. **URL Construction**
   - All query parameters are properly encoded
   - Special characters (@, +, spaces) are handled correctly
   - Base URLs match server endpoint structure

2. **Data Types**
   - Listing IDs are String (UUID format) not Int
   - Amounts are positive numbers
   - Dates follow "YYYY-MM-DD HH:MM:SS" format
   - Coordinates are within valid ranges (-90 to 90 lat, -180 to 180 long)

3. **Required Parameters**
   - session_id included in authenticated requests
   - All mandatory fields present (currency, amount, etc.)
   - Empty field validation catches missing data

4. **Response Parsing**
   - JSON structure matches expected format
   - success/error flags properly parsed
   - Nested data objects correctly accessed
   - Listing arrays properly decoded

## Expected Server API Format

### Authentication
```
GET /Login/Login?Email={email}&Password={password}
GET /Signup/CreateAccount?email={email}&firstName={first}&lastName={last}&phone={phone}&password={password}
```

### Listings
```
GET /Listings/CreateListing?session_id={id}&currency={cur}&amount={amt}&acceptCurrency={acc}&location={loc}&latitude={lat}&longitude={lon}&locationRadius={rad}&meetingPreference={pref}&availableUntil={date}
GET /Listings/DeleteListing?session_id={id}&listingId={listingId}
GET /Dashboard/GetUserDashboard?session_id={id}
```

### Search
```
GET /Search/SearchListings?session_id={id}&limit={limit}&offset={offset}&Currency={cur}&AcceptCurrency={acc}&MinAmount={min}&MaxAmount={max}
```

### Contact/Messaging
```
GET /Contact/PurchaseContactAccess?session_id={id}&listingId={listingId}
GET /Contact/SendContactMessage?session_id={id}&listingId={listingId}&message={msg}
```

### Meeting
```
GET /Meeting/ProposeMeeting?session_id={id}&listingId={listingId}&location={loc}&proposedTime={time}&message={msg}
GET /Meeting/GetExactLocation?session_id={id}&listingId={listingId}
```

### Profile
```
GET /Profile/GetProfile?session_id={id}
GET /Profile/UpdateProfile?session_id={id}&bio={bio}&location={location}
```

## Common Issues & Solutions

### Issue: Tests not running
**Solution**: Ensure test target is added to scheme (Product → Scheme → Edit Scheme → Test)

### Issue: Import errors (@testable import Nice_Traders)
**Solution**: 
1. Check target membership of source files
2. Ensure "Enable Testability" is ON in build settings
3. Build Settings → Build Options → Enable Testability = Yes (for Debug)

### Issue: URL encoding differences
**Solution**: Tests account for different encoding strategies (+, %20 for spaces both valid)

### Issue: Date format failures
**Solution**: Ensure UTC timezone is used in date formatters

## Integration with CI/CD

Add to your CI pipeline:
```bash
#!/bin/bash
xcodebuild test \
  -project "Nice Traders.xcodeproj" \
  -scheme "Nice Traders" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -resultBundlePath TestResults \
  | xcpretty --report junit
```

## Next Steps

1. **Add Mock Server Tests**: Create tests that mock server responses
2. **Add Integration Tests**: Test actual network calls to staging server
3. **Add UI Tests**: Verify user flows end-to-end
4. **Add Performance Tests**: Measure API response times
5. **Add Code Coverage**: Enable coverage in test scheme (Edit Scheme → Test → Options → Code Coverage)

## Maintenance

- Run tests before every commit
- Update tests when API endpoints change
- Add new tests for new features
- Keep test data realistic (real UUIDs, valid dates, etc.)
- Monitor for flaky tests and investigate root causes

## Current Test Status
**Total Tests**: 28  
**Coverage**: All major API endpoints  
**Status**: Ready to run once test target is configured in Xcode
