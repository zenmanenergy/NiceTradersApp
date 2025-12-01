from _Lib import Database
import json
from datetime import datetime
import uuid

def submit_rating(SessionId, UserId, Rating, Review="", TransactionId=None):
    """
    Submit a rating for a user after a transaction
    
    Args:
        SessionId: User session ID (rater)
        UserId: User ID being rated
        Rating: Rating from 1-5
        Review: Optional review text
        TransactionId: Optional transaction ID related to the rating
    
    Returns: JSON response
    """
    try:
        if not all([SessionId, UserId, Rating]):
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
            SELECT UserId FROM usersessions 
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
        
        rater_id = session_result['UserId']
        
        # Prevent self-rating
        if rater_id == UserId:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'You cannot rate yourself'
            })
        
        # Verify the user being rated exists
        user_query = """
            SELECT UserId FROM users 
            WHERE UserId = %s
        """
        cursor.execute(user_query, (UserId,))
        user_result = cursor.fetchone()
        
        if not user_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'User not found'
            })
        
        # Check if a transaction is provided and verify it exists
        if TransactionId:
            transaction_query = """
                SELECT transaction_id FROM transactions 
                WHERE transaction_id = %s
            """
            cursor.execute(transaction_query, (TransactionId,))
            transaction_result = cursor.fetchone()
            
            if not transaction_result:
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'Transaction not found'
                })
        else:
            TransactionId = None
        
        # Check if this rating already exists
        existing_query = """
            SELECT rating_id FROM user_ratings 
            WHERE rater_id = %s 
            AND user_id = %s 
            AND transaction_id <=> %s
        """
        cursor.execute(existing_query, (rater_id, UserId, TransactionId))
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
            cursor.execute(insert_query, (rating_id, UserId, rater_id, TransactionId, rating_value, Review or None))
            action = "submitted"
        
        # Update user's overall rating in users table
        update_user_query = """
            UPDATE users 
            SET Rating = (
                SELECT AVG(rating) FROM user_ratings WHERE user_id = %s
            )
            WHERE UserId = %s
        """
        cursor.execute(update_user_query, (UserId, UserId))
        
        connection.commit()
        connection.close()
        
        print(f"[SubmitRating] Rating {action}: {rating_value} stars from {rater_id} to {UserId}")
        
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
