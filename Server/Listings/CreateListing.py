from _Lib import Database
from _Lib.Geocoding import GeocodingService
import uuid
from datetime import datetime
import json

def create_listing(SessionId, Currency, Amount, AcceptCurrency, Location, Latitude, Longitude, LocationRadius, MeetingPreference, AvailableUntil, WillRoundToNearestDollar=False):
    """Create a new currency exchange listing"""
    try:
        # Parameters are passed directly from the blueprint
        session_id = SessionId
        currency = Currency
        amount = Amount
        accept_currency = AcceptCurrency
        location = Location
        latitude = Latitude
        longitude = Longitude
        location_radius = LocationRadius or '5'
        meeting_preference = MeetingPreference or 'public'
        available_until = AvailableUntil
        will_round_to_nearest_dollar = WillRoundToNearestDollar
        
        print(f"[CreateListing] Creating listing for session: {session_id}")
        print(f"[CreateListing] WillRound value: {will_round_to_nearest_dollar} (type: {type(will_round_to_nearest_dollar)})")
        print(f"[CreateListing] Amount before rounding: {amount}")
        
        # Validate required parameters
        if not all([session_id, currency, amount, accept_currency, location, available_until]):
            return json.dumps({
                'success': False,
                'error': 'Missing required parameters'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get user ID
        session_query = """
            SELECT user_id FROM usersessions 
            WHERE SessionId = %s
        """
        cursor.execute(session_query, (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        print(f"[CreateListing] Retrieved user_id: {user_id} (type: {type(user_id)})")
        
        # Generate unique listing ID
        listing_id = str(uuid.uuid4())
        
        # Parse amount to float for validation
        try:
            amount_float = float(amount)
            print(f"[CreateListing] Amount as float: {amount_float}")
            if amount_float <= 0:
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'Amount must be greater than 0'
                })
            
            # Apply rounding if user opted in
            if will_round_to_nearest_dollar:
                print(f"[CreateListing] Rounding enabled. Rounding {amount_float} to nearest dollar")
                amount_float = int(amount_float + 0.5)
                print(f"[CreateListing] Rounded amount: {amount_float}")
            else:
                print(f"[CreateListing] Rounding disabled. Using amount as-is: {amount_float}")
        except ValueError:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid amount format'
            })
        
        # Parse coordinates if provided
        lat_value = None
        lng_value = None
        final_location = location
        
        if latitude and longitude:
            try:
                lat_value = float(latitude)
                lng_value = float(longitude)
                
                # Try to reverse geocode the coordinates to get city/state
                print(f"[CreateListing] Reverse geocoding coordinates: {lat_value}, {lng_value}")
                geocoded_location = GeocodingService.reverse_geocode(lat_value, lng_value)
                
                if geocoded_location:
                    final_location = geocoded_location
                    print(f"[CreateListing] Reverse geocoding successful: {final_location}")
                else:
                    print(f"[CreateListing] Reverse geocoding failed, using provided location: {location}")
                    final_location = location
                    
            except (ValueError, TypeError):
                # Invalid coordinates - just log and continue without them
                print(f"[CreateListing] Warning: Invalid coordinates lat={latitude}, lng={longitude}")
                final_location = location
        
        # Insert new listing
        insert_query = """
            INSERT INTO listings (
                listing_id, user_id, currency, amount, accept_currency, 
                location, latitude, longitude, location_radius, meeting_preference, will_round_to_nearest_dollar, available_until, 
                geocoded_location, geocoding_updated_at,
                status, created_at, updated_at
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW(), 'active', NOW(), NOW()
            )
        """
        
        # Store geocoded_location if we have coordinates and geocoding worked
        geocoded_location = None
        if lat_value is not None and lng_value is not None:
            geocoded_location = final_location if final_location != location else None
        
        cursor.execute(insert_query, (
            listing_id, user_id, currency, amount_float, accept_currency,
            final_location, lat_value, lng_value, int(location_radius), meeting_preference, will_round_to_nearest_dollar, available_until,
            geocoded_location
        ))
        connection.commit()
        connection.close()
        
        print(f"[CreateListing] Successfully created listing {listing_id} for user {user_id}")
        
        return json.dumps({
            'success': True,
            'message': 'Listing created successfully',
            'listingId': listing_id
        })
        
    except Exception as e:
        print(f"[CreateListing] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to create listing'
        })