import json
from _Lib import Database
from datetime import timezone

def get_negotiation(negotiation_id, session_id):
    """
    Get negotiation details including buyer/seller info from negotiation_history
    
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
        
        # Get negotiation details from negotiation_history table
        cursor.execute("""
            SELECT 
                negotiation_id,
                listing_id,
                action,
                proposed_time,
                accepted_time,
                proposed_location,
                accepted_location,
                proposed_by,
                created_at,
                proposed_latitude,
                proposed_longitude,
                accepted_latitude,
                accepted_longitude,
                notes
            FROM negotiation_history
            WHERE negotiation_id = %s
            ORDER BY created_at ASC
        """, (negotiation_id,))
        
        history_records = cursor.fetchall()
        
        if not history_records:
            print(f"[Negotiations] GetNegotiation: No records found for negotiation_id {negotiation_id}")
            return json.dumps({
                'success': False,
                'error': 'Negotiation not found'
            })
        
        # Get listing_id and basic info from first record
        listing_id = history_records[0]['listing_id']
        
        # Get listing details
        cursor.execute("""
            SELECT l.currency, l.amount, l.accept_currency, l.location, l.will_round_to_nearest_dollar, l.user_id
            FROM listings l
            WHERE l.listing_id = %s
        """, (listing_id,))
        
        listing = cursor.fetchone()
        if not listing:
            print(f"[Negotiations] GetNegotiation: Listing not found for listing_id {listing_id}")
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        seller_id = listing['user_id']
        
        # Get all participants (proposers) in negotiation
        cursor.execute("""
            SELECT DISTINCT proposed_by FROM negotiation_history
            WHERE negotiation_id = %s
        """, (negotiation_id,))
        
        participants = cursor.fetchall()
        participant_ids = [p['proposed_by'] for p in participants]
        
        # The buyer is the one who is NOT the seller
        buyer_id = next((p for p in participant_ids if p != seller_id), None)
        
        if not buyer_id:
            print(f"[Negotiations] GetNegotiation: Could not determine buyer_id")
            return json.dumps({
                'success': False,
                'error': 'Invalid negotiation state'
            })
        
        # Verify user is either buyer or seller
        if user_id not in (buyer_id, seller_id):
            print(f"[Negotiations] GetNegotiation: User {user_id} not authorized for negotiation between {buyer_id} and {seller_id}")
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
        
        # Format history from records
        history_formatted = []
        current_proposed_time = None
        proposed_by = None
        
        for h in history_records:
            proposed_time = h['proposed_time']
            if proposed_time and proposed_time.tzinfo is None:
                proposed_time = proposed_time.replace(tzinfo=timezone.utc)
            
            # Track the current proposed time (most recent proposal)
            if h['action'] in ('initial_proposal', 'time_proposal', 'counter_proposal', 'location_proposal'):
                current_proposed_time = proposed_time
                proposed_by = h['proposed_by']
            
            history_formatted.append({
                'action': h['action'],
                'proposedTime': proposed_time.isoformat() if proposed_time else None,
                'proposedLocation': h['proposed_location'],
                'timestamp': h['created_at'].isoformat() if h['created_at'] else None,
                'proposedBy': h['proposed_by'],
                'notes': h['notes']
            })
        
        # Determine current status based on latest action
        latest_action = history_records[-1]['action'] if history_records else 'initial_proposal'
        
        status_mapping = {
            'initial_proposal': 'proposed',
            'time_proposal': 'proposed',
            'location_proposal': 'proposed',
            'counter_proposal': 'countered',
            'accepted': 'agreed',
            'accepted_time': 'agreed',
            'accepted_location': 'agreed',
            'rejected': 'rejected',
            'buyer_paid': 'paid_partial',
            'seller_paid': 'paid_partial',
        }
        ios_status = status_mapping.get(latest_action, latest_action)
        
        # Check if both have paid
        has_buyer_paid = any(h['action'] == 'buyer_paid' for h in history_records)
        has_seller_paid = any(h['action'] == 'seller_paid' for h in history_records)
        
        if has_buyer_paid and has_seller_paid:
            ios_status = 'paid_complete'
        
        # Find the most recent accepted location (if any)
        accepted_location = None
        accepted_time = None
        for h in reversed(history_records):
            if h['action'] == 'accepted_location':
                accepted_location = h['accepted_location']
                break
        
        # Get last accepted time
        for h in reversed(history_records):
            if h['action'] in ('accepted_time', 'accepted_location'):
                if h['accepted_time']:
                    accepted_time = h['accepted_time']
                    break
        
        # Build response
        response = {
            'success': True,
            'negotiation': {
                'negotiationId': negotiation_id,
                'listingId': listing_id,
                'status': ios_status,
                'currentProposedTime': current_proposed_time.isoformat() if current_proposed_time else None,
                'proposedBy': proposed_by,
                'buyerPaid': has_buyer_paid,
                'sellerPaid': has_seller_paid,
                'agreementReachedAt': None,  # Not tracked in negotiation_history yet
                'paymentDeadline': None,  # Not tracked in negotiation_history yet
                'createdAt': history_records[0]['created_at'].isoformat() if history_records[0]['created_at'] else None,
                'updatedAt': history_records[-1]['created_at'].isoformat() if history_records[-1]['created_at'] else None
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
        
        print(f"[Negotiations] GetNegotiation success: negotiation_id={negotiation_id}, status={ios_status}, user_role={user_role}")
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
