import json
from _Lib import Database
from _Lib.NegotiationStatus import (
    get_time_negotiation_status,
    get_location_negotiation_status,
    get_payment_status,
    get_negotiation_overall_status
)
from datetime import timezone

def get_negotiation(listing_id, session_id):
    """
    Get negotiation details from new normalized tables
    
    Args:
        listing_id: ID of the listing
        session_id: User's session ID
    
    Returns:
        JSON response with full negotiation details
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Verify session and get user_id
        cursor.execute("SELECT UserId FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['UserId']
        
        # Get listing details
        cursor.execute("""
            SELECT currency, amount, accept_currency, location, will_round_to_nearest_dollar, user_id
            FROM listings
            WHERE listing_id = %s
        """, (listing_id,))
        
        listing = cursor.fetchone()
        if not listing:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        seller_id = listing['user_id']
        
        # Get time negotiation
        cursor.execute("""
            SELECT time_negotiation_id, buyer_id, proposed_by, meeting_time, accepted_at, rejected_at, created_at, updated_at
            FROM listing_meeting_time
            WHERE listing_id = %s
        """, (listing_id,))
        
        time_neg = cursor.fetchone()
        
        if not time_neg:
            return json.dumps({
                'success': False,
                'error': 'No time proposal found for this listing'
            })
        
        buyer_id = time_neg['buyer_id']
        
        # Verify user is either buyer or seller
        if user_id not in (buyer_id, seller_id):
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Get location negotiation (if exists)
        cursor.execute("""
            SELECT location_negotiation_id, proposed_by, meeting_location_lat, meeting_location_lng, 
                   meeting_location_name, accepted_at, rejected_at
            FROM listing_meeting_location
            WHERE listing_id = %s
        """, (listing_id,))
        
        location_neg = cursor.fetchone()
        
        # Get payment status
        cursor.execute("""
            SELECT payment_id, buyer_paid_at, seller_paid_at
            FROM listing_payments
            WHERE listing_id = %s
        """, (listing_id,))
        
        payment = cursor.fetchone()
        
        # Get buyer and seller user info
        cursor.execute("""
            SELECT UserId, FirstName, LastName, Rating, TotalExchanges
            FROM users
            WHERE UserId IN (%s, %s)
        """, (buyer_id, seller_id))
        
        users = cursor.fetchall()
        buyer_info = next((u for u in users if u['UserId'] == buyer_id), None)
        seller_info = next((u for u in users if u['UserId'] == seller_id), None)
        
        # Determine user's role
        user_role = 'buyer' if user_id == buyer_id else 'seller'
        
        # Calculate statuses
        time_status = get_time_negotiation_status(time_neg)
        location_status = get_location_negotiation_status(location_neg)
        payment_status = get_payment_status(payment)
        overall_status = get_negotiation_overall_status(time_neg, location_neg, payment)
        
        # Format meeting time with timezone
        meeting_time = time_neg['meeting_time']
        if meeting_time and meeting_time.tzinfo is None:
            meeting_time = meeting_time.replace(tzinfo=timezone.utc)
        
        # Build location response if exists
        location_response = None
        if location_neg:
            location_response = {
                'latitude': float(location_neg['meeting_location_lat']),
                'longitude': float(location_neg['meeting_location_lng']),
                'name': location_neg['meeting_location_name'],
                'proposedBy': location_neg['proposed_by'],
                'status': location_status
            }
        
        # Build response
        response = {
            'success': True,
            'negotiation': {
                'listingId': listing_id,
                'status': overall_status,
                'currentProposedTime': meeting_time.isoformat() if meeting_time else None,
                'proposedBy': time_neg['proposed_by'],
                'buyerPaid': payment['buyer_paid_at'] is not None if payment else False,
                'sellerPaid': payment['seller_paid_at'] is not None if payment else False,
                'createdAt': time_neg['created_at'].isoformat() if time_neg['created_at'] else None,
                'updatedAt': time_neg['updated_at'].isoformat() if time_neg['updated_at'] else None
            },
            'listing': {
                'currency': listing['currency'],
                'amount': float(listing['amount']),
                'acceptCurrency': listing['accept_currency'],
                'location': listing['location'],
                'willRoundToNearestDollar': bool(listing['will_round_to_nearest_dollar']) if listing['will_round_to_nearest_dollar'] is not None else False
            },
            'location': location_response,
            'buyer': {
                'userId': buyer_id,
                'firstName': buyer_info['FirstName'] if buyer_info else 'Unknown',
                'lastName': buyer_info['LastName'] if buyer_info else 'Unknown',
                'rating': float(buyer_info['Rating']) if buyer_info and buyer_info['Rating'] else 0.0,
                'totalExchanges': buyer_info['TotalExchanges'] if buyer_info else 0
            },
            'seller': {
                'userId': seller_id,
                'firstName': seller_info['FirstName'] if seller_info else 'Unknown',
                'lastName': seller_info['LastName'] if seller_info else 'Unknown',
                'rating': float(seller_info['Rating']) if seller_info and seller_info['Rating'] else 0.0,
                'totalExchanges': seller_info['TotalExchanges'] if seller_info else 0
            },
            'userRole': user_role,
            'history': []
        }
        
        print(f"[Negotiations] GetNegotiation success: listing_id={listing_id}, status={overall_status}, user_role={user_role}")
        return json.dumps(response)
        print(f"[Negotiations] GetNegotiation success: listing_id={listing_id}, status={overall_status}, user_role={user_role}")
        return json.dumps(response)
        
    except Exception as e:
        print(f"[Negotiations] GetNegotiation error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to get negotiation details'
        })
    
    finally:
        cursor.close()
        connection.close()
