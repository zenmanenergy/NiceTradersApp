import json
import uuid
from datetime import datetime
from _Lib import Database

def propose_meeting_location(listing_id, session_id, latitude, longitude, location_name):
    """
    Propose a meeting location (only after time negotiation is accepted)
    
    Args:
        listing_id: ID of the listing
        session_id: User's session ID
        latitude: Proposed latitude
        longitude: Proposed longitude
        location_name: Location name/description
    
    Returns:
        JSON response with location proposal details
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Verify session and get user_id
        cursor.execute("SELECT user_id FROM user_sessions WHERE session_id = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        
        # Get time negotiation to verify it's accepted
        cursor.execute("""
            SELECT time_negotiation_id, buyer_id, accepted_at, rejected_at
            FROM listing_meeting_time
            WHERE listing_id = %s
        """, (listing_id,))
        
        time_neg = cursor.fetchone()
        
        if not time_neg:
            return json.dumps({
                'success': False,
                'error': 'No time proposal found for this listing'
            })
        
        # Time must be accepted before proposing location
        if time_neg['accepted_at'] is None:
            return json.dumps({
                'success': False,
                'error': 'Time negotiation must be accepted before proposing location'
            })
        
        if time_neg['rejected_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'Time negotiation has been rejected'
            })
        
        # Check if both parties have paid
        cursor.execute("""
            SELECT payment_id, buyer_paid_at, seller_paid_at
            FROM listing_payments
            WHERE listing_id = %s
        """, (listing_id,))
        
        payment = cursor.fetchone()
        
        if not payment or not payment['buyer_paid_at'] or not payment['seller_paid_at']:
            return json.dumps({
                'success': False,
                'error': 'Both parties must pay the $2 fee before proposing location'
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
        if user_id != seller_id and user_id != time_neg['buyer_id']:
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Check if location negotiation already exists
        cursor.execute("""
            SELECT location_negotiation_id, rejected_at
            FROM listing_meeting_location
            WHERE listing_id = %s
        """, (listing_id,))
        
        existing_location = cursor.fetchone()
        
        # Clear rejected_at if exists (allow re-proposal after rejection)
        if existing_location and existing_location['rejected_at'] is not None:
            cursor.execute("""
                UPDATE listing_meeting_location
                SET rejected_at = NULL, updated_at = NOW()
                WHERE listing_id = %s
            """, (listing_id,))
        elif existing_location:
            # If exists and not rejected, another proposal is in progress
            return json.dumps({
                'success': False,
                'error': 'A location proposal already exists for this listing'
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
        
        # Create location negotiation
        location_negotiation_id = str(uuid.uuid4())
        
        cursor.execute("""
            INSERT INTO listing_meeting_location (
                location_negotiation_id, listing_id, buyer_id, proposed_by, 
                meeting_location_lat, meeting_location_lng, meeting_location_name, 
                created_at, updated_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
        """, (location_negotiation_id, listing_id, time_neg['buyer_id'], user_id, 
              lat, lng, location_name))
        
        connection.commit()
        
        print(f"[Negotiations] ProposeMeetingLocation success: listing_id={listing_id}, location_negotiation_id={location_negotiation_id}")
        
        return json.dumps({
            'success': True,
            'locationNegotiationId': location_negotiation_id,
            'status': 'proposed',
            'proposedLocation': {
                'latitude': lat,
                'longitude': lng,
                'name': location_name
            },
            'message': 'Location proposal sent successfully'
        })
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        print(f"[Negotiations] ProposeMeetingLocation error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': f'Failed to propose location: {str(e)}'
        })
    
    finally:
        cursor.close()
        connection.close()
