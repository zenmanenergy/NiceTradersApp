from _Lib import Database
import uuid
from datetime import datetime
import json

def create_listing(SessionId, Currency, Amount, AcceptCurrency, Location, LocationRadius, MeetingPreference, AvailableUntil):
    """Create a new currency exchange listing"""
    try:
        # Parameters are passed directly from the blueprint
        session_id = SessionId
        currency = Currency
        amount = Amount
        accept_currency = AcceptCurrency
        location = Location
        location_radius = LocationRadius or '5'
        meeting_preference = MeetingPreference or 'public'
        available_until = AvailableUntil
        
        print(f"[CreateListing] Creating listing for session: {session_id}")
        
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
            SELECT UserId FROM usersessions 
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
        
        user_id = session_result['UserId']
        print(f"[CreateListing] Retrieved user_id: {user_id} (type: {type(user_id)})")
        
        # Generate unique listing ID
        listing_id = str(uuid.uuid4())
        
        # Parse amount to float for validation
        try:
            amount_float = float(amount)
            if amount_float <= 0:
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'Amount must be greater than 0'
                })
        except ValueError:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid amount format'
            })
        
        # Insert new listing
        insert_query = """
            INSERT INTO listings (
                listing_id, user_id, currency, amount, accept_currency, 
                location, location_radius, meeting_preference, available_until, 
                status, created_at, updated_at
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, 'active', NOW(), NOW()
            )
        """
        
        cursor.execute(insert_query, (
            listing_id, user_id, currency, amount_float, accept_currency,
            location, int(location_radius), meeting_preference, available_until
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