import json
from _Lib import Database
from _Lib.NegotiationStatus import (
    get_time_negotiation_status,
    get_location_negotiation_status,
    get_payment_status,
    get_negotiation_overall_status,
    action_required_for_user
)

def get_my_negotiations(session_id):
    """
    Get user's active negotiations (as buyer or seller) from new tables
    
    Args:
        session_id: User's session ID
    
    Returns:
        JSON response with list of active negotiations
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
        print(f"[GetMyNegotiations] Processing request for user: {user_id}")
        
        # Get all time negotiations where user is buyer or seller
        # Query: buyer_id = user_id OR seller (via listing.user_id) = user_id
        cursor.execute("""
            SELECT DISTINCT lmt.time_negotiation_id, lmt.listing_id, lmt.buyer_id, lmt.proposed_by,
                   lmt.meeting_time, lmt.accepted_at, lmt.rejected_at, 
                   lmt.created_at, lmt.updated_at, l.user_id
            FROM listing_meeting_time lmt
            JOIN listings l ON lmt.listing_id = l.listing_id
            WHERE lmt.buyer_id = %s OR l.user_id = %s
            ORDER BY lmt.updated_at DESC
        """, (user_id, user_id))
        
        time_negotiations = cursor.fetchall()
        print(f"[GetMyNegotiations] Found {len(time_negotiations)} negotiations for user {user_id}")
        
        # Format negotiations
        negotiations_list = []
        
        for time_neg in time_negotiations:
            listing_id = time_neg['listing_id']
            buyer_id = time_neg['buyer_id']
            seller_id = time_neg['user_id']
            
            print(f"[GetMyNegotiations] Processing listing {listing_id}")
            
            # Get listing info
            cursor.execute("""
                SELECT currency, amount, accept_currency, location, will_round_to_nearest_dollar
                FROM listings
                WHERE listing_id = %s
            """, (listing_id,))
            
            listing = cursor.fetchone()
            if not listing:
                print(f"[GetMyNegotiations] Listing {listing_id} not found, skipping")
                continue
            
            # Determine user role
            is_buyer = (user_id == buyer_id)
            other_user_id = seller_id if is_buyer else buyer_id
            
            # Get location negotiation if exists
            cursor.execute("""
                SELECT location_negotiation_id, proposed_by, meeting_location_lat, 
                       meeting_location_lng, meeting_location_name, accepted_at, rejected_at
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
            
            # Calculate statuses using NegotiationStatus functions
            time_status = get_time_negotiation_status(time_neg)
            location_status = get_location_negotiation_status(location_neg)
            payment_status = get_payment_status(payment)
            overall_status = get_negotiation_overall_status(time_neg, location_neg, payment)
            
            # Only show negotiations that are not fully rejected/completed (filter for active)
            if overall_status in ('rejected',):
                continue  # Skip rejected negotiations
            
            # Check if action required
            action_req = action_required_for_user(user_id, time_neg)
            
            # Get other user info
            cursor.execute("""
                SELECT FirstName, LastName, Rating FROM users WHERE user_id = %s
            """, (other_user_id,))
            
            other_user = cursor.fetchone()
            
            # Build location object if exists
            location_obj = None
            if location_neg:
                location_obj = {
                    'latitude': float(location_neg['meeting_location_lat']),
                    'longitude': float(location_neg['meeting_location_lng']),
                    'name': location_neg['meeting_location_name'],
                    'proposedBy': location_neg['proposed_by'],
                    'status': location_status
                }
            
            neg_dict = {
                'timeNegotiationId': time_neg['time_negotiation_id'],
                'listingId': listing_id,
                'status': overall_status,
                'currentProposedTime': time_neg['meeting_time'].isoformat() if time_neg['meeting_time'] else None,
                'proposedBy': time_neg.get('proposed_by'),  # Last who proposed
                'actionRequired': action_req,
                'buyerPaid': payment['buyer_paid_at'] is not None if payment else False,
                'sellerPaid': payment['seller_paid_at'] is not None if payment else False,
                'createdAt': time_neg['created_at'].isoformat() if time_neg['created_at'] else None,
                'updatedAt': time_neg['updated_at'].isoformat() if time_neg['updated_at'] else None,
                'listing': {
                    'currency': listing['currency'],
                    'amount': float(listing['amount']),
                    'acceptCurrency': listing['accept_currency'],
                    'location': listing['location'],
                    'willRoundToNearestDollar': bool(listing['will_round_to_nearest_dollar']) if listing['will_round_to_nearest_dollar'] is not None else False
                },
                'location': location_obj,
                'userRole': 'buyer' if is_buyer else 'seller',
                'otherUser': {
                    'user_id': other_user_id,
                    'name': f"{other_user['FirstName']} {other_user['LastName']}" if other_user else 'Unknown',
                    'rating': float(other_user['Rating']) if other_user and other_user['Rating'] else 0.0
                }
            }
            negotiations_list.append(neg_dict)
            print(f"[GetMyNegotiations] Added listing {listing_id}, status: {overall_status}")
        
        print(f"[GetMyNegotiations] Returning {len(negotiations_list)} negotiations")
        return json.dumps({
            'success': True,
            'negotiations': negotiations_list,
            'count': len(negotiations_list)
        })
        
    except Exception as e:
        print(f"[Negotiations] GetMyNegotiations error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to get negotiations'
        })
    
    finally:
        cursor.close()
        connection.close()
