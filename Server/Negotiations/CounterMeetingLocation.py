import json
import uuid
from datetime import datetime
from _Lib import Database

def counter_meeting_location(listing_id, session_id, latitude, longitude, location_name):
    """
    Counter-propose a meeting location
    
    Args:
        listing_id: ID of the listing
        session_id: User's session ID
        latitude: Proposed latitude
        longitude: Proposed longitude
        location_name: Location name/description
    
    Returns:
        JSON response with updated location proposal
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Verify session and get user_id
        cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        
        # Get location negotiation for this listing
        cursor.execute("""
            SELECT location_negotiation_id, buyer_id, proposed_by, accepted_at, rejected_at
            FROM listing_meeting_location
            WHERE listing_id = %s
        """, (listing_id,))
        
        location_neg = cursor.fetchone()
        
        if not location_neg:
            return json.dumps({
                'success': False,
                'error': 'No location proposal found for this listing'
            })
        
        # Cannot counter if already accepted or rejected
        if location_neg['accepted_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'This location proposal has already been accepted'
            })
        
        if location_neg['rejected_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'This location proposal has been rejected'
            })
        
        # Get listing to verify access
        cursor.execute("""
            SELECT user_id FROM listings WHERE listing_id = %s
        """, (listing_id,))
        
        listing = cursor.fetchone()
        if not listing:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        seller_id = listing['user_id']
        
        # Verify user is part of this negotiation
        if user_id != seller_id and user_id != location_neg['buyer_id']:
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Cannot counter your own proposal
        if user_id == location_neg['proposed_by']:
            return json.dumps({
                'success': False,
                'error': 'You cannot counter your own proposal'
            })
        
        # Validate coordinates
        try:
            lat = float(latitude)
            lng = float(longitude)
            if lat < -90 or lat > 90 or lng < -180 or lng > 180:
                raise ValueError("Invalid coordinate range")
        except (ValueError, TypeError):
            return json.dumps({
                'success': False,
                'error': 'Invalid latitude/longitude values'
            })
        
        # Update location negotiation with new proposal
        cursor.execute("""
            UPDATE listing_meeting_location
            SET meeting_location_lat = %s, meeting_location_lng = %s, 
                meeting_location_name = %s, proposed_by = %s, accepted_at = NULL, updated_at = NOW()
            WHERE listing_id = %s
        """, (lat, lng, location_name, user_id, listing_id))
        
        connection.commit()
        
        print(f"[Negotiations] CounterMeetingLocation success: listing_id={listing_id}, user_id={user_id}")
        
        return json.dumps({
            'success': True,
            'status': 'proposed',
            'proposedLocation': {
                'latitude': lat,
                'longitude': lng,
                'name': location_name
            },
            'message': 'Counter-location proposal sent'
        })
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        print(f"[Negotiations] CounterMeetingLocation error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to submit counter-location proposal'
        })
    
    finally:
        cursor.close()
        connection.close()
