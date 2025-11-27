import json
from _Lib import Database

def get_buyer_info(buyer_id, session_id):
    """
    Get buyer information for seller review (photo, rating, transaction history)
    
    Args:
        buyer_id: ID of the buyer
        session_id: Seller's session ID
    
    Returns:
        JSON response with buyer details
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
        
        # Get buyer details
        cursor.execute("""
            SELECT 
                UserId,
                FirstName,
                LastName,
                Rating,
                TotalExchanges,
                DateCreated
            FROM users
            WHERE UserId = %s
        """, (buyer_id,))
        
        buyer = cursor.fetchone()
        
        if not buyer:
            return json.dumps({
                'success': False,
                'error': 'Buyer not found'
            })
        
        # Get buyer's recent transaction history (completed exchanges)
        cursor.execute("""
            SELECT 
                ExchangeDate,
                Currency,
                Amount,
                Rating
            FROM exchange_history
            WHERE UserId = %s
            ORDER BY ExchangeDate DESC
            LIMIT 10
        """, (buyer_id,))
        
        transaction_history = cursor.fetchall()
        
        # Format transaction history
        history_list = []
        for txn in transaction_history:
            history_list.append({
                'date': txn['ExchangeDate'].isoformat() if txn['ExchangeDate'] else None,
                'currency': txn['Currency'],
                'amount': float(txn['Amount']) if txn['Amount'] else 0,
                'rating': txn['Rating']
            })
        
        # Get buyer's ratings received
        cursor.execute("""
            SELECT 
                rating,
                review,
                created_at
            FROM user_ratings
            WHERE user_id = %s
            ORDER BY created_at DESC
            LIMIT 5
        """, (buyer_id,))
        
        ratings = cursor.fetchall()
        
        # Format ratings
        ratings_list = []
        for rating in ratings:
            ratings_list.append({
                'rating': rating['rating'],
                'review': rating['review'],
                'date': rating['created_at'].isoformat() if rating['created_at'] else None
            })
        
        # Calculate stats
        avg_rating = float(buyer['Rating']) if buyer['Rating'] else 0
        total_exchanges = buyer['TotalExchanges'] if buyer['TotalExchanges'] else 0
        
        # Member since
        member_since = buyer['DateCreated'].isoformat() if buyer['DateCreated'] else None
        
        response = {
            'success': True,
            'buyer': {
                'userId': buyer['UserId'],
                'firstName': buyer['FirstName'],
                'lastName': buyer['LastName'],
                'rating': avg_rating,
                'totalExchanges': total_exchanges,
                'memberSince': member_since,
                'transactionHistory': history_list,
                'recentRatings': ratings_list
            }
        }
        
        return json.dumps(response)
        
    except Exception as e:
        print(f"[Negotiations] GetBuyerInfo error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to get buyer information'
        })
    
    finally:
        cursor.close()
        connection.close()
