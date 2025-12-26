# Ratings module for NiceTradersApp
from flask import Blueprint, request
from .SubmitRating import submit_rating
from .GetUserRatings import get_user_ratings
from .GetRatingStats import get_rating_stats

ratings_bp = Blueprint('ratings', __name__, url_prefix='/Ratings')

@ratings_bp.route('/SubmitRating', methods=['GET', 'POST'])
def submit_rating_endpoint():
    """Submit a rating for a user after a transaction"""
    session_id = request.args.get('session_id')
    user_id = request.args.get('user_id')
    rating = request.args.get('Rating')
    review = request.args.get('Review', '')
    transaction_id = request.args.get('TransactionId')
    
    return submit_rating(session_id, user_id, rating, review, transaction_id)

@ratings_bp.route('/GetUserRatings', methods=['GET'])
def get_user_ratings_endpoint():
    """Get all ratings for a user"""
    user_id = request.args.get('user_id')
    limit = request.args.get('Limit', 10, type=int)
    offset = request.args.get('Offset', 0, type=int)
    
    return get_user_ratings(user_id, limit, offset)

@ratings_bp.route('/GetRatingStats', methods=['GET'])
def get_rating_stats_endpoint():
    """Get rating statistics for a user"""
    user_id = request.args.get('user_id')
    
    return get_rating_stats(user_id)

@ratings_bp.route('/GetMyRatings', methods=['GET'])
def get_my_ratings_endpoint():
    """Get ratings given by current user"""
    session_id = request.args.get('session_id')
    limit = request.args.get('Limit', 10, type=int)
    offset = request.args.get('Offset', 0, type=int)
    
    from .GetMyRatings import get_my_ratings
    return get_my_ratings(session_id, limit, offset)

@ratings_bp.route('/GetReceivedRatings', methods=['GET'])
def get_received_ratings_endpoint():
    """Get ratings received by current user"""
    session_id = request.args.get('session_id')
    limit = request.args.get('Limit', 10, type=int)
    offset = request.args.get('Offset', 0, type=int)
    
    from .GetReceivedRatings import get_received_ratings
    return get_received_ratings(session_id, limit, offset)
