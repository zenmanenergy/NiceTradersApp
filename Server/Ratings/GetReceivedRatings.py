from _Lib import Database
import json

def get_received_ratings(SessionId, Limit=10, Offset=0):
    """
    Get ratings received by the current user
    
    Args:
        SessionId: User session ID
        Limit: Number of ratings to return (default 10)
        Offset: Pagination offset (default 0)
    
    Returns: JSON response with ratings received
    """
    try:
        if not SessionId:
            return json.dumps({
                'success': False,
                'error': 'Session ID is required'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get user ID
        session_query = """
            SELECT user_id FROM usersessions 
            WHERE SessionId = %s
        """
        cursor.execute(session_query, (SessionId,))
        session_result = cursor.fetchone()
        
        if not session_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        
        # Get ratings received by this user
        ratings_query = """
            SELECT 
                ur.rating_id,
                ur.rating,
                ur.review,
                ur.created_at,
                u.user_id as rater_user_id,
                u.FirstName as rater_first_name,
                u.LastName as rater_last_name,
                u.Rating as rater_average_rating,
                t.transaction_id,
                t.amount,
                t.currency
            FROM user_ratings ur
            JOIN users u ON ur.rater_id = u.user_id
            LEFT JOIN transactions t ON ur.transaction_id = t.transaction_id
            WHERE ur.user_id = %s
            ORDER BY ur.created_at DESC
            LIMIT %s OFFSET %s
        """
        
        cursor.execute(ratings_query, (user_id, Limit, Offset))
        ratings = cursor.fetchall()
        
        # Get count
        count_query = """
            SELECT COUNT(*) as total_count FROM user_ratings 
            WHERE user_id = %s
        """
        cursor.execute(count_query, (user_id,))
        count_result = cursor.fetchone()
        total_ratings = count_result['total_count'] if count_result else 0
        
        # Get summary stats for received ratings
        stats_query = """
            SELECT 
                AVG(rating) as average_rating,
                COUNT(*) as total_ratings,
                SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) as five_star,
                SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END) as four_star,
                SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END) as three_star,
                SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END) as two_star,
                SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) as one_star
            FROM user_ratings 
            WHERE user_id = %s
        """
        cursor.execute(stats_query, (user_id,))
        stats = cursor.fetchone()
        
        connection.close()
        
        # Format ratings
        formatted_ratings = []
        for rating in ratings:
            formatted_ratings.append({
                'ratingId': rating['rating_id'],
                'rating': rating['rating'],
                'review': rating['review'],
                'createdAt': str(rating['created_at']),
                'rater': {
                    'user_id': rating['rater_user_id'],
                    'firstName': rating['rater_first_name'],
                    'lastName': rating['rater_last_name'],
                    'averageRating': float(rating['rater_average_rating']) if rating['rater_average_rating'] else 0
                },
                'transaction': {
                    'transactionId': rating['transaction_id'],
                    'amount': float(rating['amount']) if rating['amount'] else None,
                    'currency': rating['currency']
                } if rating['transaction_id'] else None
            })
        
        return json.dumps({
            'success': True,
            'ratings': formatted_ratings,
            'summary': {
                'averageRating': float(stats['average_rating']) if stats['average_rating'] else 0,
                'totalRatings': stats['total_ratings'] or 0,
                'distribution': {
                    'fiveStar': stats['five_star'] or 0,
                    'fourStar': stats['four_star'] or 0,
                    'threeStar': stats['three_star'] or 0,
                    'twoStar': stats['two_star'] or 0,
                    'oneStar': stats['one_star'] or 0
                }
            },
            'pagination': {
                'limit': Limit,
                'offset': Offset,
                'total': total_ratings
            }
        })
        
    except Exception as e:
        print(f"[GetReceivedRatings] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to get ratings: {str(e)}'
        })
