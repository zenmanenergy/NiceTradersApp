from flask import Blueprint, request
from flask_cors import cross_origin
import json
from _Lib.Debugger import Debugger
from Meeting.ProposeMeeting import propose_meeting
from Meeting.RespondToMeeting import respond_to_meeting
from Meeting.GetMeetingProposals import get_meeting_proposals
from Meeting.GetExactLocation import get_exact_location
from Meeting.LocationTrackingService import LocationTrackingService
from Meeting.CancelMeetingTime import cancel_meeting_time
from Meeting.CancelLocation import cancel_location

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
        proposed_latitude = request_data.get('proposedLatitude')
        proposed_longitude = request_data.get('proposedLongitude')
        message = request_data.get('message', '')
        
        # Convert latitude and longitude to float if provided
        try:
            proposed_latitude = float(proposed_latitude) if proposed_latitude else None
            proposed_longitude = float(proposed_longitude) if proposed_longitude else None
        except (ValueError, TypeError):
            proposed_latitude = None
            proposed_longitude = None
        
        result = propose_meeting(session_id, listing_id, proposed_location, proposed_time, proposed_latitude, proposed_longitude, message)
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
        
        # Determine proposal type from proposal_id prefix
        if proposal_id.startswith('LOC-'):
            proposal_type = 'location'
        elif proposal_id.startswith('TIME-'):
            proposal_type = 'time'
        else:
            return json.dumps({'success': False, 'error': 'Invalid proposal ID format'})
        
        result = respond_to_meeting(session_id, proposal_type, proposal_id, response)
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
        from _Lib.Database import ConnectToDatabase
        cursor, connection = ConnectToDatabase()
        
        session_query = "SELECT user_id FROM user_sessions WHERE session_id = %s"
        cursor.execute(session_query, (session_id,))
        session_result = cursor.fetchone()
        connection.close()
        
        if not session_result:
            return {"success": False, "error": "Invalid or expired session"}
        
        user_id = session_result['user_id']
        
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
        from _Lib.Database import ConnectToDatabase
        cursor, connection = ConnectToDatabase()
        
        session_query = "SELECT user_id FROM user_sessions WHERE session_id = %s"
        cursor.execute(session_query, (session_id,))
        session_result = cursor.fetchone()
        connection.close()
        
        if not session_result:
            return {"success": False, "error": "Invalid or expired session"}
        
        user_id = session_result['user_id']
        
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
        from _Lib.Database import ConnectToDatabase
        cursor, connection = ConnectToDatabase()
        
        session_query = "SELECT user_id FROM user_sessions WHERE session_id = %s"
        cursor.execute(session_query, (session_id,))
        session_result = cursor.fetchone()
        connection.close()
        
        if not session_result:
            return {"success": False, "error": "Invalid or expired session"}
        
        user_id = session_result['user_id']
        
        # Get tracking status
        result = LocationTrackingService.get_tracking_status(proposal_id, user_id)
        return result
    except Exception as e:
        return Debugger(e)

@blueprint.route("/Meeting/CancelMeetingTime", methods=['GET', 'POST'])
@cross_origin()
def CancelMeetingTime():
    try:
        if request.method == 'POST':
            request_data = request.get_json()
        else:
            request_data = request.args.to_dict()
        
        session_id = request_data.get('sessionId')
        listing_id = request_data.get('listingId')
        
        result = cancel_meeting_time(session_id, listing_id)
        return result
    except Exception as e:
        return Debugger(e)

@blueprint.route("/Meeting/CancelLocation", methods=['GET', 'POST'])
@cross_origin()
def CancelLocation():
    try:
        if request.method == 'POST':
            request_data = request.get_json()
        else:
            request_data = request.args.to_dict()
        
        session_id = request_data.get('sessionId')
        listing_id = request_data.get('listingId')
        
        print(f"[CancelLocation] Received request - sessionId={session_id}, listingId={listing_id}")
        
        result = cancel_location(session_id, listing_id)
        print(f"[CancelLocation] Result from cancel_location: {result}")
        
        if result.get('success'):
            print(f"[CancelLocation] Returning 200 success response")
            return result, 200
        else:
            print(f"[CancelLocation] Returning 400 error response: {result}")
            return result, 400
    except Exception as e:
        print(f"[CancelLocation] Exception: {str(e)}")
        return Debugger(e)
