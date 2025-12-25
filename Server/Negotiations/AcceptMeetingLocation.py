import json
import uuid
from datetime import datetime
from _Lib import Database

def accept_meeting_location(listing_id, session_id):
    """
    Accept the current location proposal
    
    Args:
        listing_id: ID of the listing
        session_id: User's session ID
    
    Returns:
        JSON response with accepted location
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
        
        # Get location negotiation for this listing
        cursor.execute("""
            SELECT location_negotiation_id, buyer_id, meeting_location_lat, 
                   meeting_location_lng, meeting_location_name, accepted_at, rejected_at
            FROM listing_meeting_location
            WHERE listing_id = %s
        """, (listing_id,))
        
        location_neg = cursor.fetchone()
        
        if not location_neg:
            return json.dumps({
                'success': False,
                'error': 'No location proposal found for this listing'
            })
        
        # Verify time negotiation is accepted
        cursor.execute("""
            SELECT accepted_at FROM listing_meeting_time WHERE listing_id = %s
        """, (listing_id,))
        
        time_neg = cursor.fetchone()
        
        if not time_neg or not time_neg['accepted_at']:
            return json.dumps({
                'success': False,
                'error': 'Time negotiation must be accepted before accepting location'
            })
        
        # Check if both parties have paid
        cursor.execute("""
            SELECT buyer_paid_at, seller_paid_at FROM listing_payments WHERE listing_id = %s
        """, (listing_id,))
        
        payment = cursor.fetchone()
        
        if not payment or not payment['buyer_paid_at'] or not payment['seller_paid_at']:
            return json.dumps({
                'success': False,
                'error': 'Both parties must pay the $2 fee before accepting location'
            })
        
        # Check if already accepted or rejected
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
        
        # Get listing to verify user is part of negotiation
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
        
        # Accept the location proposal
        cursor.execute("""
            UPDATE listing_meeting_location
            SET accepted_at = NOW(), updated_at = NOW()
            WHERE listing_id = %s
        """, (listing_id,))
        
        connection.commit()
        
        print(f"[Negotiations] AcceptMeetingLocation success: listing_id={listing_id}, user_id={user_id}")
        
        return json.dumps({
            'success': True,
            'status': 'agreed',
            'acceptedLocation': {
                'latitude': float(location_neg['meeting_location_lat']) if location_neg['meeting_location_lat'] else None,
                'longitude': float(location_neg['meeting_location_lng']) if location_neg['meeting_location_lng'] else None,
                'name': location_neg['meeting_location_name']
            },
            'message': 'Meeting location accepted. Payment phase begins.'
        })
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        print(f"[Negotiations] AcceptMeetingLocation error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to accept location proposal'
        })
    
    finally:
        cursor.close()
        connection.close()
