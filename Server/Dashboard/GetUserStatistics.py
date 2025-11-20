from _Lib import Database
import json

def get_user_statistics(SessionId):
    """Get detailed statistics for user dashboard"""
    try:
        session_id = SessionId
        
        print(f"[GetUserStatistics] Getting statistics for session: {session_id}")
        
        if not session_id:
            return json.dumps({
                'success': False,
                'error': 'Session ID is required'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get user ID
        session_query = """
            SELECT UserId FROM usersessions 
            WHERE SessionId = %s
        """
        cursor.execute(session_query, (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['UserId']
        
        # Get listings statistics by status
        listings_stats_query = """
            SELECT status, COUNT(*) as count
            FROM listings 
            WHERE user_id = %s 
            GROUP BY status
        """
        cursor.execute(listings_stats_query, (user_id,))
        listings_stats = cursor.fetchall()
        
        # Get transaction statistics by status
        transaction_stats_query = """
            SELECT status, COUNT(*) as count
            FROM exchange_transactions 
            WHERE seller_id = %s OR buyer_id = %s
            GROUP BY status
        """
        cursor.execute(transaction_stats_query, (user_id, user_id))
        transaction_stats = cursor.fetchall()
        
        # Get total volume traded
        volume_query = """
            SELECT 
                SUM(CASE WHEN seller_id = %s THEN amount_sold ELSE 0 END) as sold_volume,
                SUM(CASE WHEN buyer_id = %s THEN amount_bought ELSE 0 END) as bought_volume,
                COUNT(CASE WHEN seller_id = %s THEN 1 END) as times_sold,
                COUNT(CASE WHEN buyer_id = %s THEN 1 END) as times_bought
            FROM exchange_transactions 
            WHERE (seller_id = %s OR buyer_id = %s) AND status = 'completed'
        """
        cursor.execute(volume_query, (user_id, user_id, user_id, user_id, user_id, user_id))
        volume_data = cursor.fetchone()
        
        # Get most traded currencies
        currency_stats_query = """
            SELECT currency, COUNT(*) as listing_count
            FROM listings 
            WHERE user_id = %s 
            GROUP BY currency 
            ORDER BY listing_count DESC 
            LIMIT 5
        """
        cursor.execute(currency_stats_query, (user_id,))
        currency_stats = cursor.fetchall()
        
        connection.close()
        
        # Format statistics data
        statistics_data = {
            'listingsByStatus': {
                stat['status']: stat['count'] for stat in listings_stats
            },
            'transactionsByStatus': {
                stat['status']: stat['count'] for stat in transaction_stats
            },
            'tradingVolume': {
                'totalSold': float(volume_data['sold_volume'] or 0),
                'totalBought': float(volume_data['bought_volume'] or 0),
                'timesSold': volume_data['times_sold'] or 0,
                'timesBought': volume_data['times_bought'] or 0
            },
            'topCurrencies': [
                {
                    'currency': stat['currency'],
                    'listingCount': stat['listing_count']
                }
                for stat in currency_stats
            ]
        }
        
        print(f"[GetUserStatistics] Successfully retrieved statistics for user {user_id}")
        
        return json.dumps({
            'success': True,
            'data': statistics_data
        })
        
    except Exception as e:
        print(f"[GetUserStatistics] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to retrieve statistics'
        })