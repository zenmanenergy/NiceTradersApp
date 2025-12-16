from _Lib import Database
import json

def get_my_ratings(SessionId, Limit=10, Offset=0):
    """
    Get ratings given by the current user
    
    Args:
        SessionId: User session ID
        Limit: Number of ratings to return (default 10)
        Offset: Pagination offset (default 0)
    
    Returns: JSON response with ratings given
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
        
        # Get ratings given by this user
        ratings_query = """
            SELECT 
                ur.rating_id,
                ur.rating,
                ur.review,
                ur.created_at,
                u.user_id as rated_user_id,
                u.FirstName as rated_user_first_name,
                u.LastName as rated_user_last_name,
                u.Rating as rated_user_average_rating
            FROM user_ratings ur
            JOIN users u ON ur.user_id = u.user_id
            WHERE ur.rater_id = %s
            ORDER BY ur.created_at DESC
            LIMIT %s OFFSET %s
        """
        
        cursor.execute(ratings_query, (user_id, Limit, Offset))
        ratings = cursor.fetchall()
        
        # Get count
        count_query = """
            SELECT COUNT(*) as total_count FROM user_ratings 
            WHERE rater_id = %s
        """
        cursor.execute(count_query, (user_id,))
        count_result = cursor.fetchone()
        total_ratings = count_result['total_count'] if count_result else 0
        
        connection.close()
        
        # Format ratings
        formatted_ratings = []
        for rating in ratings:
            formatted_ratings.append({
                'ratingId': rating['rating_id'],
                'rating': rating['rating'],
                'review': rating['review'],
                'createdAt': str(rating['created_at']),
                'ratedUser': {
                    'user_id': rating['rated_user_id'],
                    'firstName': rating['rated_user_first_name'],
                    'lastName': rating['rated_user_last_name'],
                    'averageRating': float(rating['rated_user_average_rating']) if rating['rated_user_average_rating'] else 0
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
            'pagination': {
                'limit': Limit,
                'offset': Offset,
                'total': total_ratings
            }
        })
        
    except Exception as e:
        print(f"[GetMyRatings] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to get ratings: {str(e)}'
        })
