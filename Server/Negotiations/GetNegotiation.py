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
        
        # Get negotiation details with buyer and seller info
        cursor.execute("""
            SELECT 
                n.*,
                l.currency, l.amount, l.accept_currency, l.location,
                buyer.FirstName as buyer_first_name,
                buyer.LastName as buyer_last_name,
                buyer.Rating as buyer_rating,
                buyer.TotalExchanges as buyer_total_exchanges,
                seller.FirstName as seller_first_name,
                seller.LastName as seller_last_name,
                seller.Rating as seller_rating,
                seller.TotalExchanges as seller_total_exchanges
            FROM exchange_negotiations n
            JOIN listings l ON n.listing_id = l.listing_id
            JOIN users buyer ON n.buyer_id = buyer.UserId
            JOIN users seller ON n.seller_id = seller.UserId
            WHERE n.negotiation_id = %s
        """, (negotiation_id,))
        
        negotiation = cursor.fetchone()
        
        if not negotiation:
            return json.dumps({
                'success': False,
                'error': 'Negotiation not found'
            })
        
        # Verify user is either buyer or seller
        if user_id not in (negotiation['buyer_id'], negotiation['seller_id']):
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Determine user's role
        user_role = 'buyer' if user_id == negotiation['buyer_id'] else 'seller'
        other_user_id = negotiation['seller_id'] if user_role == 'buyer' else negotiation['buyer_id']
        
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
                'negotiationId': negotiation['negotiation_id'],
                'listingId': negotiation['listing_id'],
                'status': negotiation['status'],
                'currentProposedTime': negotiation['current_proposed_time'].isoformat() if negotiation['current_proposed_time'] else None,
                'proposedBy': negotiation['proposed_by'],
                'buyerPaid': bool(negotiation['buyer_paid']),
                'sellerPaid': bool(negotiation['seller_paid']),
                'agreementReachedAt': negotiation['agreement_reached_at'].isoformat() if negotiation['agreement_reached_at'] else None,
                'paymentDeadline': negotiation['payment_deadline'].isoformat() if negotiation['payment_deadline'] else None,
                'createdAt': negotiation['created_at'].isoformat() if negotiation['created_at'] else None,
                'updatedAt': negotiation['updated_at'].isoformat() if negotiation['updated_at'] else None
            },
            'listing': {
                'currency': negotiation['currency'],
                'amount': float(negotiation['amount']),
                'acceptCurrency': negotiation['accept_currency'],
                'location': negotiation['location']
            },
            'buyer': {
                'userId': negotiation['buyer_id'],
                'firstName': negotiation['buyer_first_name'],
                'lastName': negotiation['buyer_last_name'],
                'rating': float(negotiation['buyer_rating']) if negotiation['buyer_rating'] else 0,
                'totalExchanges': negotiation['buyer_total_exchanges']
            },
            'seller': {
                'userId': negotiation['seller_id'],
                'firstName': negotiation['seller_first_name'],
                'lastName': negotiation['seller_last_name'],
                'rating': float(negotiation['seller_rating']) if negotiation['seller_rating'] else 0,
                'totalExchanges': negotiation['seller_total_exchanges']
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
