from flask import Blueprint, request
from .GetUserDashboard import get_user_dashboard
from .GetUserStatistics import get_user_statistics

# Create Dashboard blueprint
dashboard_bp = Blueprint('dashboard', __name__)

@dashboard_bp.route('/Dashboard/GetUserDashboard')
def GetUserDashboard():
    """Get user dashboard data"""
    try:
        # Get parameters from query string
        session_id = request.args.get('SessionId')
        
        if not session_id:
            return {
                'success': False,
                'error': 'SessionId parameter is required'
            }
        
        # Call the dashboard function
        result = get_user_dashboard(session_id)
        return result
        
    except Exception as e:
        return {
            'success': False,
            'error': f'Dashboard endpoint error: {str(e)}'
        }

@dashboard_bp.route('/Dashboard/GetUserStatistics')
def GetUserStatistics():
    """Get user statistics for dashboard"""
    try:
        # Get parameters from query string
        session_id = request.args.get('SessionId')
        
        if not session_id:
            return {
                'success': False,
                'error': 'SessionId parameter is required'
            }
        
        # Call the statistics function
        result = get_user_statistics(session_id)
        return result
        
    except Exception as e:
        return {
            'success': False,
            'error': f'Statistics endpoint error: {str(e)}'
        }