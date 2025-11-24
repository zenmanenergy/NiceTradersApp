from flask import Blueprint, request
from flask_cors import cross_origin
from _Lib.Debugger import Debugger
from Meeting.ProposeMeeting import propose_meeting
from Meeting.RespondToMeeting import respond_to_meeting
from Meeting.GetMeetingProposals import get_meeting_proposals
from Meeting.GetExactLocation import get_exact_location
from Meeting.LocationTrackingService import LocationTrackingService

blueprint = Blueprint('meeting', __name__)

@blueprint.route("/Meeting/ProposeMeeting", methods=['GET', 'POST'])
@cross_origin()
def ProposeMeeting():
    try:
        if request.method == 'POST':
            request_data = request.get_json()
        else:
            request_data = request.args.to_dict()
        
        session_id = request_data.get('sessionId')
        listing_id = request_data.get('listingId')
        proposed_location = request_data.get('proposedLocation')
        proposed_time = request_data.get('proposedTime')
        message = request_data.get('message', '')
        
        result = propose_meeting(session_id, listing_id, proposed_location, proposed_time, message)
        return result
    except Exception as e:
        return Debugger(e)

@blueprint.route("/Meeting/RespondToMeeting", methods=['GET', 'POST'])
@cross_origin()
def RespondToMeeting():
    try:
        if request.method == 'POST':
            request_data = request.get_json()
        else:
            request_data = request.args.to_dict()
        
        session_id = request_data.get('sessionId')
        proposal_id = request_data.get('proposalId')
        response = request_data.get('response')  # 'accepted' or 'rejected'
        
        result = respond_to_meeting(session_id, proposal_id, response)
        return result
    except Exception as e:
        return Debugger(e)

@blueprint.route("/Meeting/GetMeetingProposals", methods=['GET'])
@cross_origin()
def GetMeetingProposals():
    try:
        request_data = request.args.to_dict()
        
        session_id = request_data.get('sessionId')
        listing_id = request_data.get('listingId')
        
        result = get_meeting_proposals(session_id, listing_id)
        return result
    except Exception as e:
        return Debugger(e)

@blueprint.route("/Meeting/GetExactLocation", methods=['GET'])
@cross_origin()
def GetExactLocation():
    try:
        request_data = request.args.to_dict()
        
        session_id = request_data.get('sessionId')
        listing_id = request_data.get('listingId')
        
        result = get_exact_location(session_id, listing_id)
        return result
    except Exception as e:
        return Debugger(e)

@blueprint.route("/Meeting/Location/Update", methods=['POST'])
@cross_origin()
def UpdateLocation():
    """
    Update user's location during an active exchange
    POST data: proposalId, latitude, longitude, sessionId
    """
    try:
        request_data = request.get_json()
        
        session_id = request_data.get('sessionId')
        proposal_id = request_data.get('proposalId')
        latitude = float(request_data.get('latitude'))
        longitude = float(request_data.get('longitude'))
        
        # Verify session and get user ID
        from _Lib.Database import Database
        cursor, connection = Database.ConnectToDatabase()
        
        session_query = "SELECT UserId FROM sessions WHERE SessionId = %s AND ExpiresAt > NOW()"
        cursor.execute(session_query, (session_id,))
        session_result = cursor.fetchone()
        connection.close()
        
        if not session_result:
            return {"success": False, "error": "Invalid or expired session"}
        
        user_id = session_result['UserId']
        
        # Update location
        result = LocationTrackingService.update_user_location(proposal_id, user_id, latitude, longitude)
        return result
    except ValueError:
        return {"success": False, "error": "Invalid latitude or longitude"}
    except Exception as e:
        return Debugger(e)

@blueprint.route("/Meeting/Location/Get", methods=['GET'])
@cross_origin()
def GetOtherUserLocation():
    """
    Get the other user's location in an active exchange
    GET params: proposalId, sessionId
    """
    try:
        request_data = request.args.to_dict()
        
        session_id = request_data.get('sessionId')
        proposal_id = request_data.get('proposalId')
        
        # Verify session and get user ID
        from _Lib.Database import Database
        cursor, connection = Database.ConnectToDatabase()
        
        session_query = "SELECT UserId FROM sessions WHERE SessionId = %s AND ExpiresAt > NOW()"
        cursor.execute(session_query, (session_id,))
        session_result = cursor.fetchone()
        connection.close()
        
        if not session_result:
            return {"success": False, "error": "Invalid or expired session"}
        
        user_id = session_result['UserId']
        
        # Get other user's location
        result = LocationTrackingService.get_other_user_location(proposal_id, user_id)
        return result
    except Exception as e:
        return Debugger(e)

@blueprint.route("/Meeting/Location/Status", methods=['GET'])
@cross_origin()
def GetTrackingStatus():
    """
    Check if location tracking is currently enabled for an exchange
    GET params: proposalId, sessionId
    """
    try:
        request_data = request.args.to_dict()
        
        session_id = request_data.get('sessionId')
        proposal_id = request_data.get('proposalId')
        
        # Verify session and get user ID
        from _Lib.Database import Database
        cursor, connection = Database.ConnectToDatabase()
        
        session_query = "SELECT UserId FROM sessions WHERE SessionId = %s AND ExpiresAt > NOW()"
        cursor.execute(session_query, (session_id,))
        session_result = cursor.fetchone()
        connection.close()
        
        if not session_result:
            return {"success": False, "error": "Invalid or expired session"}
        
        user_id = session_result['UserId']
        
        # Get tracking status
        result = LocationTrackingService.get_tracking_status(proposal_id, user_id)
        return result
    except Exception as e:
        return Debugger(e)