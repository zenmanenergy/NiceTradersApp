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
        
        # Get all active negotiations where user is buyer or seller
        cursor.execute("""
            SELECT 
                n.negotiation_id,
                n.listing_id,
                n.status,
                n.current_proposed_time,
                n.proposed_by,
                n.buyer_paid,
                n.seller_paid,
                n.agreement_reached_at,
                n.payment_deadline,
                n.created_at,
                n.updated_at,
                l.currency,
                l.amount,
                l.accept_currency,
                l.location,
                CASE 
                    WHEN n.buyer_id = %s THEN 'buyer'
                    ELSE 'seller'
                END as user_role,
                CASE 
                    WHEN n.buyer_id = %s THEN n.seller_id
                    ELSE n.buyer_id
                END as other_user_id,
                CASE 
                    WHEN n.buyer_id = %s THEN CONCAT(seller.FirstName, ' ', seller.LastName)
                    ELSE CONCAT(buyer.FirstName, ' ', buyer.LastName)
                END as other_user_name,
                CASE 
                    WHEN n.buyer_id = %s THEN seller.Rating
                    ELSE buyer.Rating
                END as other_user_rating
            FROM exchange_negotiations n
            JOIN listings l ON n.listing_id = l.listing_id
            JOIN users buyer ON n.buyer_id = buyer.UserId
            JOIN users seller ON n.seller_id = seller.UserId
            WHERE (n.buyer_id = %s OR n.seller_id = %s)
            AND n.status IN ('proposed', 'countered', 'agreed', 'paid_partial', 'paid_complete')
            ORDER BY n.updated_at DESC
        """, (user_id, user_id, user_id, user_id, user_id, user_id))
        
        negotiations = cursor.fetchall()
        
        # Format negotiations
        negotiations_list = []
        for n in negotiations:
            negotiations_list.append({
                'negotiationId': n['negotiation_id'],
                'listingId': n['listing_id'],
                'status': n['status'],
                'currentProposedTime': n['current_proposed_time'].isoformat() if n['current_proposed_time'] else None,
                'proposedBy': n['proposed_by'],
                'buyerPaid': bool(n['buyer_paid']),
                'sellerPaid': bool(n['seller_paid']),
                'agreementReachedAt': n['agreement_reached_at'].isoformat() if n['agreement_reached_at'] else None,
                'paymentDeadline': n['payment_deadline'].isoformat() if n['payment_deadline'] else None,
                'createdAt': n['created_at'].isoformat() if n['created_at'] else None,
                'updatedAt': n['updated_at'].isoformat() if n['updated_at'] else None,
                'listing': {
                    'currency': n['currency'],
                    'amount': float(n['amount']),
                    'acceptCurrency': n['accept_currency'],
                    'location': n['location']
                },
                'userRole': n['user_role'],
                'otherUser': {
                    'userId': n['other_user_id'],
                    'name': n['other_user_name'],
                    'rating': float(n['other_user_rating']) if n['other_user_rating'] else 0
                }
            })
        
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
