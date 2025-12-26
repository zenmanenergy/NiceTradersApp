from _Lib import Database
import json

def get_user_statistics(session_id):
    """Get detailed statistics for user dashboard"""
    try:
        session_id = session_id
        
        if not session_id:
            return json.dumps({
                'success': False,
                'error': 'Session ID is required'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get user ID
        session_query = """
            SELECT user_id FROM user_sessions 
            WHERE session_id = %s
        """
        cursor.execute(session_query, (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        
        # Get listings statistics by status
        listings_stats_query = """
            SELECT status, COUNT(*) as count
            FROM listings 
            WHERE user_id = %s 
            GROUP BY status
        """
        cursor.execute(listings_stats_query, (user_id,))
        listings_stats = cursor.fetchall()
        
        # Placeholder for transaction statistics (exchange_transactions table is not being used)
        transaction_stats = []
        
        # Placeholder for volume data
        volume_data = {
            'sold_volume': 0,
            'bought_volume': 0,
            'times_sold': 0,
            'times_bought': 0
        }
        
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
        
        return json.dumps({
            'success': True,
            'data': statistics_data
        })
        
    except Exception as e:
        return json.dumps({
            'success': False,
            'error': 'Failed to retrieve statistics'
        })