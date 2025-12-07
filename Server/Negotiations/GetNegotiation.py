import json
from _Lib import Database

def get_negotiation(negotiation_id, session_id):
    """
    Get negotiation details including buyer/seller info
    
    Args:
        negotiation_id: ID of the negotiation
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
        
        # Get negotiation details from history
        cursor.execute("""
            SELECT DISTINCT nh.negotiation_id, nh.listing_id
            FROM negotiation_history nh
            WHERE nh.negotiation_id = %s
            LIMIT 1
        """, (negotiation_id,))
        
        negotiation_base = cursor.fetchone()
        
        if not negotiation_base:
            return json.dumps({
                'success': False,
                'error': 'Negotiation not found'
            })
        
        # Get listing details
        cursor.execute("""
            SELECT l.currency, l.amount, l.accept_currency, l.location, l.will_round_to_nearest_dollar, l.created_by
            FROM listings l
            WHERE l.ListingId = %s
        """, (negotiation_base['listing_id'],))
        
        listing = cursor.fetchone()
        if not listing:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        seller_id = listing['created_by']
        
        # Get all participants in negotiation
        cursor.execute("""
            SELECT DISTINCT proposed_by FROM negotiation_history
            WHERE negotiation_id = %s
        """, (negotiation_id,))
        
        participants = cursor.fetchall()
        buyer_id = participants[0]['proposed_by'] if participants else None
        
        # Verify user is either buyer or seller
        if user_id not in (buyer_id, seller_id):
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Get buyer and seller user info
        cursor.execute("""
            SELECT u.UserId, u.FirstName, u.LastName, u.Rating, u.TotalExchanges
            FROM users u
            WHERE u.UserId IN (%s, %s)
        """, (buyer_id, seller_id))
        
        users = cursor.fetchall()
        buyer_info = next((u for u in users if u['UserId'] == buyer_id), None)
        seller_info = next((u for u in users if u['UserId'] == seller_id), None)
        
        # Determine user's role
        user_role = 'buyer' if user_id == buyer_id else 'seller'
        
        # Get negotiation history
        cursor.execute("""
            SELECT 
                h.action,
                h.proposed_time,
                h.created_at,
                u.FirstName,
                u.LastName
            FROM negotiation_history h
            JOIN users u ON h.proposed_by = u.UserId
            WHERE h.negotiation_id = %s
            ORDER BY h.created_at ASC
        """, (negotiation_id,))
        
        history = cursor.fetchall()
        
        # Format history
        history_formatted = []
        for h in history:
            history_formatted.append({
                'action': h['action'],
                'proposedTime': h['proposed_time'].isoformat() if h['proposed_time'] else None,
                'timestamp': h['created_at'].isoformat() if h['created_at'] else None,
                'userName': f"{h['FirstName']} {h['LastName']}"
            })
        
        # Build response
        response = {
            'success': True,
            'negotiation': {
                'negotiationId': negotiation_base['negotiation_id'],
                'listingId': negotiation_base['listing_id']
            },
            'listing': {
                'currency': listing['currency'],
                'amount': float(listing['amount']),
                'acceptCurrency': listing['accept_currency'],
                'location': listing['location'],
                'willRoundToNearestDollar': bool(listing['will_round_to_nearest_dollar']) if listing['will_round_to_nearest_dollar'] is not None else False
            },
            'buyer': {
                'userId': buyer_id,
                'firstName': buyer_info['FirstName'] if buyer_info else 'Unknown',
                'lastName': buyer_info['LastName'] if buyer_info else 'Unknown',
                'rating': float(buyer_info['Rating']) if buyer_info and buyer_info['Rating'] else 0,
                'totalExchanges': buyer_info['TotalExchanges'] if buyer_info else 0
            },
            'seller': {
                'userId': seller_id,
                'firstName': seller_info['FirstName'] if seller_info else 'Unknown',
                'lastName': seller_info['LastName'] if seller_info else 'Unknown',
                'rating': float(seller_info['Rating']) if seller_info and seller_info['Rating'] else 0,
                'totalExchanges': seller_info['TotalExchanges'] if seller_info else 0
            },
            'userRole': user_role,
            'history': history_formatted
        }
        
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
