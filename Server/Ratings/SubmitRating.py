from _Lib import Database
import json
from datetime import datetime
import uuid

def submit_rating(SessionId, user_id, Rating, Review="", TransactionId=None):
    """
    Submit a rating for a user after a transaction
    
    Args:
        SessionId: User session ID (rater)
        user_id: User ID being rated
        Rating: Rating from 1-5
        Review: Optional review text
        TransactionId: Optional transaction ID related to the rating
    
    Returns: JSON response
    """
    try:
        if not all([SessionId, user_id, Rating]):
            return json.dumps({
                'success': False,
                'error': 'Session ID, User ID, and Rating are required'
            })
        
        # Validate rating is 1-5
        try:
            rating_value = int(Rating)
            if rating_value < 1 or rating_value > 5:
                return json.dumps({
                    'success': False,
                    'error': 'Rating must be between 1 and 5'
                })
        except ValueError:
            return json.dumps({
                'success': False,
                'error': 'Rating must be a valid number'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get rater user ID
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
        
        rater_id = session_result['user_id']
        
        # Prevent self-rating
        if rater_id == user_id:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'You cannot rate yourself'
            })
        
        # Verify the user being rated exists
        user_query = """
            SELECT user_id FROM users 
            WHERE user_id = %s
        """
        cursor.execute(user_query, (user_id,))
        user_result = cursor.fetchone()
        
        if not user_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'User not found'
            })
        
        # TransactionId parameter is optional (kept for backward compatibility)
        # but not used since we removed the transactions table
        TransactionId = None
        
        # Check if this rating already exists
        existing_query = """
            SELECT rating_id FROM user_ratings 
            WHERE rater_id = %s 
            AND user_id = %s 
            AND transaction_id <=> %s
        """
        cursor.execute(existing_query, (rater_id, user_id, TransactionId))
        existing_rating = cursor.fetchone()
        
        if existing_rating:
            # Update existing rating
            rating_id = existing_rating['rating_id']
            update_query = """
                UPDATE user_ratings 
                SET rating = %s, review = %s
                WHERE rating_id = %s
            """
            cursor.execute(update_query, (rating_value, Review or None, rating_id))
            action = "updated"
        else:
            # Create new rating
            rating_id = str(uuid.uuid4())
            insert_query = """
                INSERT INTO user_ratings 
                (rating_id, user_id, rater_id, transaction_id, rating, review, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, NOW())
            """
            cursor.execute(insert_query, (rating_id, user_id, rater_id, TransactionId, rating_value, Review or None))
            action = "submitted"
        
        # Update user's overall rating in users table
        update_user_query = """
            UPDATE users 
            SET Rating = (
                SELECT AVG(rating) FROM user_ratings WHERE user_id = %s
            )
            WHERE user_id = %s
        """
        cursor.execute(update_user_query, (user_id, user_id))
        
        connection.commit()
        connection.close()
        
        print(f"[SubmitRating] Rating {action}: {rating_value} stars from {rater_id} to {user_id}")
        
        return json.dumps({
            'success': True,
            'message': f'Rating {action} successfully',
            'ratingId': rating_id
        })
        
    except Exception as e:
        print(f"[SubmitRating] Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return json.dumps({
            'success': False,
            'error': f'Failed to submit rating: {str(e)}'
        })
