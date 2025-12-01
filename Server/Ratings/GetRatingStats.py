from _Lib import Database
import json

def get_rating_stats(UserId):
    """
    Get comprehensive rating statistics for a user
    
    Args:
        UserId: User ID to get stats for
    
    Returns: JSON response with detailed rating statistics
    """
    try:
        if not UserId:
            return json.dumps({
                'success': False,
                'error': 'User ID is required'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Get user info
        user_query = """
            SELECT UserId, FirstName, LastName, Rating, TotalExchanges 
            FROM users 
            WHERE UserId = %s
        """
        cursor.execute(user_query, (UserId,))
        user = cursor.fetchone()
        
        if not user:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'User not found'
            })
        
        # Get detailed stats
        stats_query = """
            SELECT 
                COUNT(*) as total_ratings,
                AVG(rating) as average_rating,
                MIN(rating) as lowest_rating,
                MAX(rating) as highest_rating,
                STDDEV(rating) as rating_stddev,
                SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) as five_star_count,
                SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END) as four_star_count,
                SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END) as three_star_count,
                SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END) as two_star_count,
                SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) as one_star_count,
                COUNT(DISTINCT rater_id) as total_raters,
                COUNT(DISTINCT DATE(created_at)) as days_with_ratings,
                MAX(created_at) as most_recent_rating,
                MIN(created_at) as oldest_rating
            FROM user_ratings 
            WHERE user_id = %s
        """
        cursor.execute(stats_query, (UserId,))
        stats = cursor.fetchone()
        
        # Get recent ratings summary
        recent_query = """
            SELECT 
                DATE_TRUNC(created_at, MONTH) as period,
                COUNT(*) as count,
                AVG(rating) as avg_rating
            FROM user_ratings 
            WHERE user_id = %s 
                AND created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
            GROUP BY period
            ORDER BY period DESC
        """
        
        try:
            cursor.execute(recent_query, (UserId,))
            recent_ratings = cursor.fetchall()
        except:
            # Fallback if DATE_TRUNC not available
            recent_query = """
                SELECT 
                    DATE_FORMAT(created_at, '%Y-%m') as period,
                    COUNT(*) as count,
                    AVG(rating) as avg_rating
                FROM user_ratings 
                WHERE user_id = %s 
                    AND created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
                GROUP BY DATE_FORMAT(created_at, '%Y-%m')
                ORDER BY period DESC
            """
            cursor.execute(recent_query, (UserId,))
            recent_ratings = cursor.fetchall()
        
        # Get trustworthiness score based on multiple factors
        trustworthiness_score = calculate_trustworthiness_score(stats)
        
        connection.close()
        
        # Build response
        total = stats['total_ratings'] or 0
        distribution = {}
        if total > 0:
            distribution = {
                'fiveStar': {
                    'count': stats['five_star_count'] or 0,
                    'percentage': round((stats['five_star_count'] or 0) / total * 100, 1)
                },
                'fourStar': {
                    'count': stats['four_star_count'] or 0,
                    'percentage': round((stats['four_star_count'] or 0) / total * 100, 1)
                },
                'threeStar': {
                    'count': stats['three_star_count'] or 0,
                    'percentage': round((stats['three_star_count'] or 0) / total * 100, 1)
                },
                'twoStar': {
                    'count': stats['two_star_count'] or 0,
                    'percentage': round((stats['two_star_count'] or 0) / total * 100, 1)
                },
                'oneStar': {
                    'count': stats['one_star_count'] or 0,
                    'percentage': round((stats['one_star_count'] or 0) / total * 100, 1)
                }
            }
        
        return json.dumps({
            'success': True,
            'user': {
                'userId': user['UserId'],
                'firstName': user['FirstName'],
                'lastName': user['LastName'],
                'totalExchanges': user['TotalExchanges']
            },
            'stats': {
                'totalRatings': total,
                'averageRating': float(stats['average_rating']) if stats['average_rating'] else 0,
                'lowestRating': stats['lowest_rating'],
                'highestRating': stats['highest_rating'],
                'standardDeviation': float(stats['rating_stddev']) if stats['rating_stddev'] else 0,
                'totalRaters': stats['total_raters'] or 0,
                'daysWithRatings': stats['days_with_ratings'] or 0,
                'mostRecentRating': str(stats['most_recent_rating']) if stats['most_recent_rating'] else None,
                'oldestRating': str(stats['oldest_rating']) if stats['oldest_rating'] else None,
                'trustworthinessScore': trustworthiness_score,
                'distribution': distribution,
                'recentRatings': [
                    {
                        'period': str(r['period']),
                        'count': r['count'],
                        'averageRating': float(r['avg_rating']) if r['avg_rating'] else 0
                    } for r in recent_ratings
                ]
            }
        })
        
    except Exception as e:
        print(f"[GetRatingStats] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to get rating stats: {str(e)}'
        })

def calculate_trustworthiness_score(stats):
    """
    Calculate a trustworthiness score from 0-100 based on:
    - Average rating (0-50 points)
    - Number of ratings (0-30 points)
    - Consistency (low stddev) (0-20 points)
    """
    score = 0
    
    # Average rating component (max 50 points)
    avg_rating = stats['average_rating'] or 0
    rating_score = (avg_rating / 5.0) * 50
    score += rating_score
    
    # Volume component (max 30 points) - more ratings = more trustworthy
    total_ratings = stats['total_ratings'] or 0
    volume_score = min(total_ratings / 10, 30)  # Max 30 at 10+ ratings
    score += volume_score
    
    # Consistency component (max 20 points) - lower stddev = more consistent
    stddev = stats['rating_stddev'] or 0
    if stddev == 0 or stddev is None:
        consistency_score = 20
    else:
        consistency_score = max(0, 20 - (stddev * 10))
    score += consistency_score
    
    return round(min(score, 100), 1)
