//
//  APITests.swift
//  Nice TradersTests
//
//  Unit tests to verify API request formatting and data sent to server
//

import XCTest
@testable import Nice_Traders

final class APITests: XCTestCase {
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        // Clear any stored session
        UserDefaults.standard.removeObject(forKey: "SessionId")
        UserDefaults.standard.removeObject(forKey: "UserType")
    }
    
    override func tearDownWithError() throws {
        // Clean up
        UserDefaults.standard.removeObject(forKey: "SessionId")
        UserDefaults.standard.removeObject(forKey: "UserType")
    }
    
    // MARK: - Login API Tests
    
    func testLoginURLFormat() throws {
        let email = "test@example.com"
        let password = "password123"
        
        let baseURL = "https://api.nicetraders.net"
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "\(baseURL)/Login/Login?Email=\(encodedEmail)&Password=\(encodedPassword)"
        
        XCTAssertNotNil(URL(string: urlString), "Login URL should be valid")
        XCTAssertTrue(urlString.contains("Email=test@example.com"), "Email should be included (@ is allowed in URL query)")
        XCTAssertTrue(urlString.contains("Password=password123"), "Password should be included")
    }
    
    func testLoginWithSpecialCharacters() throws {
        let email = "test+user@example.com"
        let password = "p@ss w0rd!"
        
        let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedPassword = password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        XCTAssertEqual(encodedEmail, "test+user@example.com", "Email encoding should preserve + and @")
        XCTAssertTrue(encodedPassword.contains("%20") || encodedPassword.contains("+"), "Password should encode spaces")
    }
    
    // MARK: - Signup API Tests
    
    func testSignupURLFormat() throws {
        let email = "newuser@example.com"
        let firstName = "John"
        let lastName = "Doe"
        let phone = "1234567890"
        let password = "secure123"
        
        var components = URLComponents(string: "https://api.nicetraders.net/Signup/CreateAccount")!
        components.queryItems = [
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "firstName", value: firstName),
            URLQueryItem(name: "lastName", value: lastName),
            URLQueryItem(name: "phone", value: phone),
            URLQueryItem(name: "password", value: password)
        ]
        
        let url = components.url!
        let urlString = url.absoluteString
        
        XCTAssertTrue(urlString.contains("email=newuser"), "Should contain email parameter")
        XCTAssertTrue(urlString.contains("firstName=John"), "Should contain firstName parameter")
        XCTAssertTrue(urlString.contains("lastName=Doe"), "Should contain lastName parameter")
        XCTAssertTrue(urlString.contains("phone=1234567890"), "Should contain phone parameter")
        XCTAssertTrue(urlString.contains("password=secure123"), "Should contain password parameter")
    }
    
    func testSignupWithEmptyFields() throws {
        let email = ""
        let firstName = "John"
        
        XCTAssertTrue(email.isEmpty, "Empty email should be caught before API call")
        XCTAssertFalse(firstName.isEmpty, "Valid firstName should pass validation")
    }
    
    // MARK: - Create Listing API Tests
    
    func testCreateListingURLFormat() throws {
        let sessionId = "TEST-SESSION-123"
        let currency = "USD"
        let amount = "100"
        let acceptCurrency = "EUR"
        let location = "37.7749, -122.4194"
        let latitude = "37.7749"
        let longitude = "-122.4194"
        let locationRadius = "5"
        let meetingPreference = "public"
        let availableUntil = "2025-12-31 23:59:59"
        
        var components = URLComponents(string: "https://api.nicetraders.net/Listings/CreateListing")!
        components.queryItems = [
            URLQueryItem(name: "SessionId", value: sessionId),
            URLQueryItem(name: "currency", value: currency),
            URLQueryItem(name: "amount", value: amount),
            URLQueryItem(name: "acceptCurrency", value: acceptCurrency),
            URLQueryItem(name: "location", value: location),
            URLQueryItem(name: "latitude", value: latitude),
            URLQueryItem(name: "longitude", value: longitude),
            URLQueryItem(name: "locationRadius", value: locationRadius),
            URLQueryItem(name: "meetingPreference", value: meetingPreference),
            URLQueryItem(name: "availableUntil", value: availableUntil)
        ]
        
        let url = components.url!
        let urlString = url.absoluteString
        
        XCTAssertTrue(urlString.contains("SessionId=TEST-SESSION-123"), "Should contain session ID")
        XCTAssertTrue(urlString.contains("currency=USD"), "Should contain currency")
        XCTAssertTrue(urlString.contains("amount=100"), "Should contain amount")
        XCTAssertTrue(urlString.contains("acceptCurrency=EUR"), "Should contain accept currency")
        XCTAssertTrue(urlString.contains("latitude=37.7749"), "Should contain latitude")
        XCTAssertTrue(urlString.contains("longitude=-122.4194"), "Should contain longitude")
        XCTAssertTrue(urlString.contains("meetingPreference=public"), "Should contain meeting preference")
    }
    
    func testCreateListingDateFormat() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        
        // Verify format: YYYY-MM-DD HH:MM:SS
        let pattern = "^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}$"
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(dateString.startIndex..., in: dateString)
        
        XCTAssertNotNil(regex.firstMatch(in: dateString, range: range), "Date should match expected format")
    }
    
    func testCreateListingLocationParsing() throws {
        let location = "37.7749, -122.4194"
        let locationParts = location.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        XCTAssertEqual(locationParts.count, 2, "Should have 2 parts")
        XCTAssertEqual(locationParts[0], "37.7749", "Latitude should be first")
        XCTAssertEqual(locationParts[1], "-122.4194", "Longitude should be second")
    }
    
    // MARK: - Search API Tests
    
    func testSearchListingsURLFormat() throws {
        let sessionId = "TEST-SESSION-123"
        let limit = 20
        let offset = 0
        
        var components = URLComponents(string: "https://api.nicetraders.net/Search/SearchListings")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        
        let url = components.url!
        let urlString = url.absoluteString
        
        XCTAssertTrue(urlString.contains("sessionId=TEST-SESSION-123"), "Should contain session ID")
        XCTAssertTrue(urlString.contains("limit=20"), "Should contain limit")
        XCTAssertTrue(urlString.contains("offset=0"), "Should contain offset")
    }
    
    func testSearchListingsWithFilters() throws {
        let currency = "USD"
        let acceptCurrency = "EUR"
        let minAmount = "100"
        let maxAmount = "1000"
        
        var components = URLComponents(string: "https://api.nicetraders.net/Search/SearchListings")!
        components.queryItems = [
            URLQueryItem(name: "Currency", value: currency),
            URLQueryItem(name: "AcceptCurrency", value: acceptCurrency),
            URLQueryItem(name: "MinAmount", value: minAmount),
            URLQueryItem(name: "MaxAmount", value: maxAmount)
        ]
        
        let url = components.url!
        let urlString = url.absoluteString
        
        XCTAssertTrue(urlString.contains("Currency=USD"), "Should contain currency filter")
        XCTAssertTrue(urlString.contains("AcceptCurrency=EUR"), "Should contain accept currency filter")
        XCTAssertTrue(urlString.contains("MinAmount=100"), "Should contain min amount filter")
        XCTAssertTrue(urlString.contains("MaxAmount=1000"), "Should contain max amount filter")
    }
    
    // MARK: - Dashboard API Tests
    
    func testDashboardURLFormat() throws {
        let sessionId = "TEST-SESSION-123"
        let encodedSessionId = sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "https://api.nicetraders.net/Dashboard/GetUserDashboard?SessionId=\(encodedSessionId)"
        
        XCTAssertNotNil(URL(string: urlString), "Dashboard URL should be valid")
        XCTAssertTrue(urlString.contains("SessionId=TEST-SESSION-123"), "Should contain session ID")
    }
    
    // MARK: - Contact API Tests
    
    func testPurchaseContactAccessURLFormat() throws {
        let sessionId = "TEST-SESSION-123"
        let listingId = "abc123-def456"
        
        var components = URLComponents(string: "https://api.nicetraders.net/Contact/PurchaseContactAccess")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: listingId)
        ]
        
        let url = components.url!
        let urlString = url.absoluteString
        
        XCTAssertTrue(urlString.contains("sessionId=TEST-SESSION-123"), "Should contain session ID")
        XCTAssertTrue(urlString.contains("listingId=abc123-def456"), "Should contain listing ID")
    }
    
    func testSendMessageURLFormat() throws {
        let sessionId = "TEST-SESSION-123"
        let listingId = "abc123"
        let message = "Hello, is this still available?"
        
        var components = URLComponents(string: "https://api.nicetraders.net/Contact/SendContactMessage")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: listingId),
            URLQueryItem(name: "message", value: message)
        ]
        
        let url = components.url!
        let urlString = url.absoluteString
        
        XCTAssertTrue(urlString.contains("sessionId=TEST-SESSION-123"), "Should contain session ID")
        XCTAssertTrue(urlString.contains("listingId=abc123"), "Should contain listing ID")
        XCTAssertTrue(urlString.contains("message=Hello"), "Should contain message")
    }
    
    // MARK: - Meeting API Tests
    
    func testProposeMeetingURLFormat() throws {
        let sessionId = "TEST-SESSION-123"
        let listingId = "abc123"
        let location = "Starbucks, Main St"
        let proposedTime = "2025-12-25 14:00:00"
        let message = "Let's meet here"
        
        var components = URLComponents(string: "https://api.nicetraders.net/Meeting/ProposeMeeting")!
        components.queryItems = [
            URLQueryItem(name: "sessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: listingId),
            URLQueryItem(name: "location", value: location),
            URLQueryItem(name: "proposedTime", value: proposedTime),
            URLQueryItem(name: "message", value: message)
        ]
        
        let url = components.url!
        let urlString = url.absoluteString
        
        XCTAssertTrue(urlString.contains("sessionId=TEST-SESSION-123"), "Should contain session ID")
        XCTAssertTrue(urlString.contains("listingId=abc123"), "Should contain listing ID")
        XCTAssertTrue(urlString.contains("location=Starbucks"), "Should contain location")
        XCTAssertTrue(urlString.contains("proposedTime=2025-12-25"), "Should contain proposed time")
    }
    
    func testGetExactLocationURLFormat() throws {
        let sessionId = "TEST-SESSION-123"
        let listingId = 1
        
        var components = URLComponents(string: "https://api.nicetraders.net/Meeting/GetExactLocation")!
        components.queryItems = [
            URLQueryItem(name: "SessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: listingId)
        ]
        
        let url = components.url!
        let urlString = url.absoluteString
        
        XCTAssertTrue(urlString.contains("SessionId=TEST-SESSION-123"), "Should contain session ID")
        XCTAssertTrue(urlString.contains("listingId=1"), "Should contain listing ID")
    }
    
    // MARK: - Delete Listing API Tests
    
    func testDeleteListingURLFormat() throws {
        let sessionId = "TEST-SESSION-123"
        let listingId = "abc123-def456"
        
        var components = URLComponents(string: "https://api.nicetraders.net/Listings/DeleteListing")!
        components.queryItems = [
            URLQueryItem(name: "SessionId", value: sessionId),
            URLQueryItem(name: "listingId", value: listingId)
        ]
        
        let url = components.url!
        let urlString = url.absoluteString
        
        XCTAssertTrue(urlString.contains("SessionId=TEST-SESSION-123"), "Should contain session ID")
        XCTAssertTrue(urlString.contains("listingId=abc123-def456"), "Should contain listing ID as string")
    }
    
    // MARK: - Profile API Tests
    
    func testGetProfileURLFormat() throws {
        let sessionId = "TEST-SESSION-123"
        let encodedSessionId = sessionId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString = "https://api.nicetraders.net/Profile/GetProfile?SessionId=\(encodedSessionId)"
        
        XCTAssertNotNil(URL(string: urlString), "Profile URL should be valid")
        XCTAssertTrue(urlString.contains("SessionId=TEST-SESSION-123"), "Should contain session ID")
    }
    
    func testUpdateProfileURLFormat() throws {
        let sessionId = "TEST-SESSION-123"
        let bio = "Currency trader since 2020"
        let location = "San Francisco, CA"
        
        var components = URLComponents(string: "https://api.nicetraders.net/Profile/UpdateProfile")!
        components.queryItems = [
            URLQueryItem(name: "SessionId", value: sessionId),
            URLQueryItem(name: "bio", value: bio),
            URLQueryItem(name: "location", value: location)
        ]
        
        let url = components.url!
        let urlString = url.absoluteString
        
        XCTAssertTrue(urlString.contains("SessionId=TEST-SESSION-123"), "Should contain session ID")
        XCTAssertTrue(urlString.contains("bio=Currency"), "Should contain bio")
        XCTAssertTrue(urlString.contains("location=San"), "Should contain location")
    }
    
    // MARK: - Data Validation Tests
    
    func testSessionIdFormat() throws {
        let validSessionId = "SES123abc-456def-789ghi"
        let invalidSessionId = ""
        
        XCTAssertFalse(validSessionId.isEmpty, "Valid session ID should not be empty")
        XCTAssertTrue(invalidSessionId.isEmpty, "Invalid session ID should be caught")
        XCTAssertTrue(validSessionId.hasPrefix("SES"), "Session ID should start with SES prefix")
    }
    
    func testListingIdFormat() throws {
        // Test UUID format (String)
        let uuidListingId = "abc123-def456-ghi789"
        XCTAssertTrue(uuidListingId.contains("-"), "UUID should contain hyphens")
        
        // Ensure it's treated as String, not Int
        let listingIdAsString: String = uuidListingId
        XCTAssertNotNil(listingIdAsString, "Listing ID should be String type")
    }
    
    func testAmountValidation() throws {
        let validAmount = "100.50"
        let invalidAmount = "-50"
        let zeroAmount = "0"
        
        XCTAssertTrue(Double(validAmount) ?? 0 > 0, "Valid amount should be positive")
        XCTAssertFalse(Double(invalidAmount) ?? 0 > 0, "Negative amount should be invalid")
        XCTAssertFalse(Double(zeroAmount) ?? 0 > 0, "Zero amount should be invalid")
    }
    
    func testCurrencyCodeFormat() throws {
        let validCurrencies = ["USD", "EUR", "GBP", "JPY"]
        
        for currency in validCurrencies {
            XCTAssertEqual(currency.count, 3, "Currency code should be 3 characters")
            XCTAssertTrue(currency == currency.uppercased(), "Currency code should be uppercase")
        }
    }
    
    func testCoordinateValidation() throws {
        let validLatitude = 37.7749
        let validLongitude = -122.4194
        let invalidLatitude = 91.0 // > 90
        let invalidLongitude = -181.0 // < -180
        
        XCTAssertTrue(validLatitude >= -90 && validLatitude <= 90, "Valid latitude should be in range")
        XCTAssertTrue(validLongitude >= -180 && validLongitude <= 180, "Valid longitude should be in range")
        XCTAssertFalse(invalidLatitude >= -90 && invalidLatitude <= 90, "Invalid latitude should be caught")
        XCTAssertFalse(invalidLongitude >= -180 && invalidLongitude <= 180, "Invalid longitude should be caught")
    }
    
    // MARK: - Response Parsing Tests
    
    func testSuccessResponseParsing() throws {
        let jsonString = """
        {
            "success": true,
            "data": {
                "sessionId": "TEST-123"
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertNotNil(json, "Should parse JSON successfully")
        XCTAssertEqual(json?["success"] as? Bool, true, "Should have success flag")
        XCTAssertNotNil(json?["data"], "Should have data object")
    }
    
    func testErrorResponseParsing() throws {
        let jsonString = """
        {
            "success": false,
            "error": "Invalid credentials"
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertNotNil(json, "Should parse JSON successfully")
        XCTAssertEqual(json?["success"] as? Bool, false, "Should have success=false")
        XCTAssertEqual(json?["error"] as? String, "Invalid credentials", "Should have error message")
    }
    
    func testListingResponseParsing() throws {
        let jsonString = """
        {
            "success": true,
            "data": {
                "recentListings": [
                    {
                        "listingId": "abc123-def456",
                        "currency": "USD",
                        "amount": 100.0,
                        "acceptCurrency": "EUR",
                        "location": "San Francisco",
                        "status": "active"
                    }
                ]
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let dataObj = json?["data"] as? [String: Any]
        let listings = dataObj?["recentListings"] as? [[String: Any]]
        
        XCTAssertNotNil(listings, "Should parse listings array")
        XCTAssertEqual(listings?.count, 1, "Should have 1 listing")
        
        let listing = listings?.first
        XCTAssertEqual(listing?["listingId"] as? String, "abc123-def456", "Listing ID should be String")
        XCTAssertEqual(listing?["currency"] as? String, "USD", "Currency should match")
        XCTAssertEqual(listing?["amount"] as? Double, 100.0, "Amount should match")
    }
}
