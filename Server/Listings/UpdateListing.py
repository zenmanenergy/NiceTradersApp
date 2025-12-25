from _Lib import Database
from _Lib.Geocoding import GeocodingService
import json

def update_listing(SessionId, ListingId, Currency, Amount, AcceptCurrency, Location, Latitude, Longitude, LocationRadius, MeetingPreference, AvailableUntil, Status, WillRoundToNearestDollar=None):
    """Update an existing listing"""
    try:
        # Parameters are passed directly from the blueprint
        session_id = SessionId
        listing_id = ListingId
        currency = Currency
        amount = Amount
        accept_currency = AcceptCurrency
        location = Location
        latitude = Latitude
        longitude = Longitude
        location_radius = LocationRadius
        meeting_preference = MeetingPreference
        available_until = AvailableUntil
        status = Status
        will_round_to_nearest_dollar = WillRoundToNearestDollar
        
        print(f"[UpdateListing] Updating listing: {listing_id}")
        
        if not all([session_id, listing_id]):
            return json.dumps({
                'success': False,
                'error': 'Session ID and Listing ID are required'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get user ID
        session_query = """
            SELECT user_id FROM user_sessions 
            WHERE session_id = %s
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
        
        # Verify user owns the listing
        ownership_query = """
            SELECT user_id FROM listings WHERE listing_id = %s
        """
        cursor.execute(ownership_query, (listing_id,))
        ownership_result = cursor.fetchone()
        
        if not ownership_result or ownership_result['user_id'] != user_id:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'You can only update your own listings'
            })
        
        # Build dynamic update query
        update_fields = []
        params = []
        
        if currency:
            update_fields.append("currency = %s")
            params.append(currency)
        
        if amount:
            try:
                amount_float = float(amount)
                if amount_float > 0:
                    update_fields.append("amount = %s")
                    params.append(amount_float)
            except ValueError:
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'Invalid amount format'
                })
        
        if accept_currency:
            update_fields.append("accept_currency = %s")
            params.append(accept_currency)
        
        if location:
            update_fields.append("location = %s")
            params.append(location)
        
        # Handle coordinates and geocoding
        geocoded_location = None
        if latitude and longitude:
            try:
                lat_value = float(latitude)
                lng_value = float(longitude)
                update_fields.append("latitude = %s")
                params.append(lat_value)
                update_fields.append("longitude = %s")
                params.append(lng_value)
                
                # Reverse geocode the new coordinates
                print(f"[UpdateListing] Reverse geocoding coordinates: {lat_value}, {lng_value}")
                geocoded = GeocodingService.reverse_geocode(lat_value, lng_value)
                if geocoded and geocoded != location:
                    geocoded_location = geocoded
                    print(f"[UpdateListing] Reverse geocoding successful: {geocoded_location}")
                
                # Always update geocoding_updated_at when coordinates change
                update_fields.append("geocoding_updated_at = NOW()")
                
            except (ValueError, TypeError):
                print(f"[UpdateListing] Warning: Invalid coordinates lat={latitude}, lng={longitude}")
        
        # Store geocoded_location if we have it
        if geocoded_location is not None:
            update_fields.append("geocoded_location = %s")
            params.append(geocoded_location)
        
        if location_radius:
            update_fields.append("location_radius = %s")
            params.append(int(location_radius))
        
        if meeting_preference:
            update_fields.append("meeting_preference = %s")
            params.append(meeting_preference)
        
        if available_until:
            update_fields.append("available_until = %s")
            params.append(available_until)
        
        if status:
            update_fields.append("status = %s")
            params.append(status)
        
        if will_round_to_nearest_dollar is not None:
            update_fields.append("will_round_to_nearest_dollar = %s")
            params.append(will_round_to_nearest_dollar)
        
        if not update_fields:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'No fields to update'
            })
        
        # Add updated_at and listing_id
        update_fields.append("updated_at = NOW()")
        params.append(listing_id)
        
        update_query = f"""
            UPDATE listings 
            SET {', '.join(update_fields)}
            WHERE listing_id = %s
        """
        
        cursor.execute(update_query, params)
        connection.commit()
        connection.close()
        
        print(f"[UpdateListing] Successfully updated listing {listing_id}")
        
        return json.dumps({
            'success': True,
            'message': 'Listing updated successfully'
        })
        
    except Exception as e:
        print(f"[UpdateListing] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to update listing'
        })