from flask import Blueprint, request
from flask_cors import cross_origin
from _Lib.Debugger import Debugger
from Meeting.ProposeMeeting import propose_meeting
from Meeting.RespondToMeeting import respond_to_meeting
from Meeting.GetMeetingProposals import get_meeting_proposals
from Meeting.GetExactLocation import get_exact_location

blueprint = Blueprint('meeting', __name__)

@blueprint.route("/Meeting/ProposeMeeting", methods=['POST'])
@cross_origin()
def ProposeMeeting():
    try:
        request_data = request.get_json()
        
        session_id = request_data.get('sessionId')
        listing_id = request_data.get('listingId')
        proposed_location = request_data.get('proposedLocation')
        proposed_time = request_data.get('proposedTime')
        message = request_data.get('message')
        
        result = propose_meeting(session_id, listing_id, proposed_location, proposed_time, message)
        return result
    except Exception as e:
        return Debugger(e)

@blueprint.route("/Meeting/RespondToMeeting", methods=['POST'])
@cross_origin()
def RespondToMeeting():
    try:
        request_data = request.get_json()
        
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