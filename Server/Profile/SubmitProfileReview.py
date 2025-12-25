"""
Profile Review module - Handle user profile reviews/comments
"""
from _Lib import Database
import json
from datetime import datetime
import uuid

def submit_profile_review(session_id, reviewed_user_id, review_text, rating=None):
    """Submit a review/comment on another user's profile"""
    try:
        print(f"[ProfileReview] Submitting review for user {reviewed_user_id}")
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get reviewer user_id
        cursor.execute("SELECT user_id FROM user_sessions WHERE session_id = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        reviewer_id = session_result['user_id']
        
        # Check if reviewing their own profile
        if reviewer_id == reviewed_user_id:
            return json.dumps({
                'success': False,
                'error': 'Cannot review your own profile'
            })
        
        # Check if reviewed user exists
        cursor.execute("SELECT user_id FROM users WHERE user_id = %s", (reviewed_user_id,))
        user_result = cursor.fetchone()
        
        if not user_result:
            return json.dumps({
                'success': False,
                'error': 'User not found'
            })
        
        # Validate review text
        if not review_text or len(review_text.strip()) == 0:
            return json.dumps({
                'success': False,
                'error': 'Review text cannot be empty'
            })
        
        if len(review_text) > 500:
            return json.dumps({
                'success': False,
                'error': 'Review text must be 500 characters or less'
            })
        
        # Create the review
        review_id = str(uuid.uuid4())
        created_at = datetime.now()
        
        review_query = """
            INSERT INTO profile_reviews (
                review_id, reviewed_user_id, reviewer_id,
                review_text, rating, created_at
            ) VALUES (%s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                review_text = %s,
                rating = %s,
                updated_at = NOW()
        """
        
        cursor.execute(review_query, (
            review_id, reviewed_user_id, reviewer_id,
            review_text, rating, created_at,
            review_text, rating
        ))
        
        connection.commit()
        
        # Send APN notification to reviewed user
        try:
            from Admin.NotificationService import notification_service
            
            # Get reviewer name
            cursor.execute("SELECT FirstName, LastName FROM users WHERE user_id = %s", (reviewer_id,))
            reviewer = cursor.fetchone()
            reviewer_name = f"{reviewer['FirstName']} {reviewer['LastName']}" if reviewer else "A user"
            
            notification_service.send_profile_review_notification(
                user_id=reviewed_user_id,
                reviewer_name=reviewer_name,
                review_text=review_text
            )
            print(f"[ProfileReview] Sent notification to user {reviewed_user_id}")
        except Exception as notif_error:
            print(f"[ProfileReview] Warning: Failed to send notification: {str(notif_error)}")
        
        # Close database connection
        cursor.close()
        connection.close()
        
        return json.dumps({
            'success': True,
            'message': 'Review submitted successfully',
            'review_id': review_id,
            'submitted_at': created_at.isoformat()
        })
        
    except Exception as e:
        print(f"[ProfileReview] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to submit review: {str(e)}'
        })


def get_profile_reviews(user_id, limit=10, offset=0):
    """Get reviews for a user's profile"""
    try:
        cursor, connection = Database.ConnectToDatabase()
        
        # Get reviews for the user
        cursor.execute("""
            SELECT pr.review_id, pr.reviewer_id, pr.review_text, pr.rating, pr.created_at,
                   u.FirstName, u.LastName
            FROM profile_reviews pr
            JOIN users u ON pr.reviewer_id = u.user_id
            WHERE pr.reviewed_user_id = %s
            ORDER BY pr.created_at DESC
            LIMIT %s OFFSET %s
        """, (user_id, limit, offset))
        
        reviews = cursor.fetchall()
        
        # Get total count
        cursor.execute("""
            SELECT COUNT(*) as count FROM profile_reviews
            WHERE reviewed_user_id = %s
        """, (user_id,))
        
        count_result = cursor.fetchone()
        total_count = count_result['count'] if count_result else 0
        
        cursor.close()
        connection.close()
        
        reviews_list = []
        for review in reviews:
            reviews_list.append({
                'review_id': review['review_id'],
                'reviewer_name': f"{review['FirstName']} {review['LastName']}",
                'review_text': review['review_text'],
                'rating': review['rating'],
                'created_at': review['created_at'].isoformat() if review['created_at'] else None
            })
        
        return json.dumps({
            'success': True,
            'reviews': reviews_list,
            'total_count': total_count,
            'limit': limit,
            'offset': offset
        })
        
    except Exception as e:
        print(f"[ProfileReview] Error getting reviews: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to get reviews: {str(e)}'
        })
