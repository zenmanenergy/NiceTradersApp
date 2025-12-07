import json
from _Lib import Database

def get_my_negotiations(session_id):
    """
    Get user's active negotiations (as buyer or seller)
    
    Args:
        session_id: User's session ID
    
    Returns:
        JSON response with list of active negotiations
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
        print(f"[GetMyNegotiations] Processing request for user: {user_id}")
        
        # Get all active negotiations where user is participant
        cursor.execute("""
            SELECT DISTINCT nh.negotiation_id, nh.listing_id, nh.created_at
            FROM negotiation_history nh
            WHERE nh.proposed_by = %s
            OR nh.listing_id IN (
                SELECT listing_id FROM listings WHERE user_id = %s
            )
            AND nh.action NOT IN ('rejected')
            ORDER BY nh.created_at DESC
        """, (user_id, user_id))
        
        negotiation_ids = cursor.fetchall()
        print(f"[GetMyNegotiations] Found {len(negotiation_ids)} negotiations for user {user_id}")
        
        # Format negotiations
        negotiations_list = []
        
        for neg in negotiation_ids:
            negotiation_id = neg['negotiation_id']
            listing_id = neg['listing_id']
            print(f"[GetMyNegotiations] Processing negotiation {negotiation_id} for listing {listing_id}")
            
            # Get listing info
            cursor.execute("""
                SELECT l.currency, l.amount, l.accept_currency, l.location, 
                       l.will_round_to_nearest_dollar, l.user_id
                FROM listings l
                WHERE l.listing_id = %s
            """, (listing_id,))
            
            listing = cursor.fetchone()
            if not listing:
                print(f"[GetMyNegotiations] Listing {listing_id} not found, skipping")
                continue
            print(f"[GetMyNegotiations] Found listing: {listing['currency']} {listing['amount']}")
            
            seller_id = listing['user_id']
            is_buyer = (user_id != seller_id)
            
            # Get all participants
            cursor.execute("""
                SELECT DISTINCT proposed_by FROM negotiation_history
                WHERE negotiation_id = %s
            """, (negotiation_id,))
            
            participants = cursor.fetchall()
            participant_ids = [p['proposed_by'] for p in participants]
            
            # Skip if user not involved
            if user_id not in participant_ids and user_id != seller_id:
                continue
            
            buyer_id = participant_ids[0] if participant_ids else None
            
            # Get last action to determine status
            cursor.execute("""
                SELECT action, proposed_time, created_at FROM negotiation_history
                WHERE negotiation_id = %s
                ORDER BY created_at DESC
                LIMIT 1
            """, (negotiation_id,))
            
            last_action = cursor.fetchone()
            action = last_action['action'] if last_action else 'proposed'
            
            # Map action names to standardized status names for iOS compatibility
            status_mapping = {
                'time_proposal': 'proposed',
                'counter_proposal': 'countered',
                'accepted_time': 'agreed',
                'accepted_location': 'agreed',
                'location_proposal': 'proposed',
                'rejected': 'rejected',
                'buyer_paid': 'paid_partial',
                'seller_paid': 'paid_partial',
                'proposed': 'proposed',
                'countered': 'countered',
                'agreed': 'agreed'
            }
            
            status = status_mapping.get(action, action)
            if last_action:
                print(f"[GetMyNegotiations] Last action: {action} -> status: {status}, proposed_time: {last_action['proposed_time']}")
            else:
                print(f"[GetMyNegotiations] No last action found")
            
            # Get other user info
            other_user_id = seller_id if is_buyer else buyer_id
            cursor.execute("""
                SELECT FirstName, LastName, Rating FROM users WHERE UserId = %s
            """, (other_user_id,))
            
            other_user = cursor.fetchone()
            
            # Get payment status
            cursor.execute("""
                SELECT COUNT(CASE WHEN action = 'buyer_paid' THEN 1 END) as buyer_paid_count,
                       COUNT(CASE WHEN action = 'seller_paid' THEN 1 END) as seller_paid_count
                FROM negotiation_history
                WHERE negotiation_id = %s
            """, (negotiation_id,))
            
            payment_check = cursor.fetchone()
            buyer_paid = payment_check['buyer_paid_count'] > 0
            seller_paid = payment_check['seller_paid_count'] > 0
            
            neg_dict = {
                'negotiationId': negotiation_id,
                'listingId': listing_id,
                'status': status,
                'currentProposedTime': last_action['proposed_time'].isoformat() if last_action and last_action['proposed_time'] else None,
                'buyerPaid': buyer_paid,
                'sellerPaid': seller_paid,
                'createdAt': last_action['created_at'].isoformat() if last_action else None,
                'updatedAt': last_action['created_at'].isoformat() if last_action else None,
                'listing': {
                    'currency': listing['currency'],
                    'amount': float(listing['amount']),
                    'acceptCurrency': listing['accept_currency'],
                    'location': listing['location'],
                    'willRoundToNearestDollar': bool(listing['will_round_to_nearest_dollar']) if listing['will_round_to_nearest_dollar'] is not None else False
                },
                'userRole': 'buyer' if is_buyer else 'seller',
                'otherUser': {
                    'userId': other_user_id,
                    'name': f"{other_user['FirstName']} {other_user['LastName']}" if other_user else 'Unknown',
                    'rating': float(other_user['Rating']) if other_user and other_user['Rating'] else 0
                }
            }
            negotiations_list.append(neg_dict)
            print(f"[GetMyNegotiations] Added negotiation {negotiation_id} to list, proposedTime: {neg_dict['currentProposedTime']}")
        
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
