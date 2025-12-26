from _Lib.Debugger import Debugger
from flask import Blueprint
from flask_cors import cross_origin
from .ProposeNegotiation import propose_negotiation
from .GetNegotiation import get_negotiation
from .AcceptProposal import accept_proposal
from .RejectNegotiation import reject_negotiation
from .CounterProposal import counter_proposal
from .PayNegotiationFee import pay_negotiation_fee
from .GetMyNegotiations import get_my_negotiations
from .GetBuyerInfo import get_buyer_info
from .ProposeMeetingLocation import propose_meeting_location
from .CounterMeetingLocation import counter_meeting_location
from .AcceptMeetingLocation import accept_meeting_location
from .RejectMeetingLocation import reject_meeting_location
from .CompleteExchange import complete_exchange

# Create the Negotiations blueprint
negotiations_bp = Blueprint('negotiations', __name__)

@negotiations_bp.route('/Negotiations/Propose', methods=['GET'])
@cross_origin()
def ProposeNegotiation():
    """Buyer proposes initial meeting time for a listing"""
    try:
        from flask import request
        listing_id = request.args.get('listingId')
        session_id = request.args.get('session_id')
        proposed_time = request.args.get('proposedTime')
        
        if not all([listing_id, session_id, proposed_time]):
            import json
            return json.dumps({
                'success': False,
                'error': 'listingId, session_id, and proposedTime are required'
            })
        
        result = propose_negotiation(listing_id, session_id, proposed_time)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/MeetingTime/Propose', methods=['GET'])
@cross_origin()
def ProposeMeetingTime():
    """Buyer proposes initial meeting time for a listing (refactored)"""
    try:
        from flask import request
        listing_id = request.args.get('listingId')
        session_id = request.args.get('session_id')
        proposed_time = request.args.get('proposedTime')
        
        if not all([listing_id, session_id, proposed_time]):
            import json
            return json.dumps({
                'success': False,
                'error': 'listingId, session_id, and proposedTime are required'
            })
        
        result = propose_negotiation(listing_id, session_id, proposed_time)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/Negotiations/Get', methods=['GET'])
@cross_origin()
def GetNegotiation():
    """Get negotiation details"""
    try:
        from flask import request
        negotiation_id = request.args.get('negotiationId')
        session_id = request.args.get('session_id')
        
        if not all([negotiation_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'negotiationId and session_id are required'
            })
        
        result = get_negotiation(negotiation_id, session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/Negotiations/Accept', methods=['GET'])
@cross_origin()
def AcceptProposal():
    """Accept the current proposal and set payment deadline"""
    try:
        from flask import request
        negotiation_id = request.args.get('negotiationId')
        session_id = request.args.get('session_id')
        
        if not all([negotiation_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'negotiationId and session_id are required'
            })
        
        result = accept_proposal(negotiation_id, session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/Negotiations/Reject', methods=['GET'])
@cross_origin()
def RejectNegotiation():
    """Reject negotiation outright"""
    try:
        from flask import request
        negotiation_id = request.args.get('negotiationId')
        session_id = request.args.get('session_id')
        
        if not all([negotiation_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'negotiationId and session_id are required'
            })
        
        result = reject_negotiation(negotiation_id, session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/Negotiations/Counter', methods=['GET'])
@cross_origin()
def CounterProposal():
    """Counter-propose a new meeting time"""
    try:
        from flask import request
        negotiation_id = request.args.get('negotiationId')
        session_id = request.args.get('session_id')
        proposed_time = request.args.get('proposedTime')
        
        if not all([negotiation_id, session_id, proposed_time]):
            import json
            return json.dumps({
                'success': False,
                'error': 'negotiationId, session_id, and proposedTime are required'
            })
        
        result = counter_proposal(negotiation_id, session_id, proposed_time)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/Negotiations/Pay', methods=['GET'])
@cross_origin()
def PayNegotiationFee():
    """Pay $2 negotiation fee (applies credits automatically)"""
    try:
        from flask import request, Response
        import json
        negotiation_id = request.args.get('negotiationId')
        session_id = request.args.get('session_id')
        
        if not all([negotiation_id, session_id]):
            return Response(
                json.dumps({
                    'success': False,
                    'error': 'negotiationId and session_id are required'
                }),
                mimetype='application/json'
            )
        
        result = pay_negotiation_fee(negotiation_id, session_id)
        return Response(result, mimetype='application/json')
        
    except Exception as e:
        import json
        print(f"[Negotiations/Pay] Exception: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response(
            json.dumps({
                'success': False,
                'error': f'Payment processing failed: {str(e)}'
            }),
            mimetype='application/json'
        )

@negotiations_bp.route('/Negotiations/GetMyNegotiations', methods=['GET'])
@cross_origin()
def GetMyNegotiations():
    """Get user's active negotiations"""
    try:
        from flask import request
        session_id = request.args.get('session_id')
        
        if not session_id:
            import json
            return json.dumps({
                'success': False,
                'error': 'session_id is required'
            })
        
        result = get_my_negotiations(session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/Negotiations/GetBuyerInfo', methods=['GET'])
@cross_origin()
def GetBuyerInfo():
    """Get buyer information for seller review"""
    try:
        from flask import request
        buyer_id = request.args.get('buyerId')
        session_id = request.args.get('session_id')
        
        if not all([buyer_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'buyerId and session_id are required'
            })
        
        result = get_buyer_info(buyer_id, session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

# ============================================================================
# NEW REFACTORED ROUTES - Using MeetingTime and MeetingLocation prefixes
# ============================================================================

@negotiations_bp.route('/MeetingTime/Counter', methods=['GET'])
@cross_origin()
def CounterMeetingTime():
    """Counter-propose a new meeting time (refactored)"""
    try:
        from flask import request
        listing_id = request.args.get('listingId')
        session_id = request.args.get('session_id')
        proposed_time = request.args.get('proposedTime')
        
        if not all([listing_id, session_id, proposed_time]):
            import json
            return json.dumps({
                'success': False,
                'error': 'listingId, session_id, and proposedTime are required'
            })
        
        result = counter_proposal(listing_id, session_id, proposed_time)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/MeetingTime/Accept', methods=['GET'])
@cross_origin()
def AcceptMeetingTime():
    """Accept the current meeting time proposal (refactored)"""
    try:
        from flask import request
        listing_id = request.args.get('listingId')
        session_id = request.args.get('session_id')
        
        if not all([listing_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'listingId and session_id are required'
            })
        
        result = accept_proposal(listing_id, session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/MeetingTime/Reject', methods=['GET'])
@cross_origin()
def RejectMeetingTime():
    """Reject meeting time proposal (refactored)"""
    try:
        from flask import request
        listing_id = request.args.get('listingId')
        session_id = request.args.get('session_id')
        
        if not all([listing_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'listingId and session_id are required'
            })
        
        result = reject_negotiation(listing_id, session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/MeetingTime/Get', methods=['GET'])
@cross_origin()
def GetMeetingTimeDetails():
    """Get meeting time negotiation details (refactored)"""
    try:
        from flask import request
        listing_id = request.args.get('listingId')
        session_id = request.args.get('session_id')
        
        if not all([listing_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'listingId and session_id are required'
            })
        
        result = get_negotiation(listing_id, session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/MeetingTime/GetMy', methods=['GET'])
@cross_origin()
def GetMyMeetingTimes():
    """Get user's active meeting time negotiations (refactored)"""
    try:
        from flask import request
        session_id = request.args.get('session_id')
        
        if not session_id:
            import json
            return json.dumps({
                'success': False,
                'error': 'session_id is required'
            })
        
        result = get_my_negotiations(session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/MeetingLocation/Propose', methods=['POST'])
@cross_origin()
def ProposeMeetingLocation():
    """Propose a meeting location (refactored)"""
    try:
        from flask import request
        import json
        
        listing_id = request.args.get('listingId') or (request.json or {}).get('listingId')
        session_id = request.args.get('session_id') or (request.json or {}).get('session_id')
        latitude = request.args.get('latitude') or (request.json or {}).get('latitude')
        longitude = request.args.get('longitude') or (request.json or {}).get('longitude')
        location_name = request.args.get('locationName') or (request.json or {}).get('locationName')
        
        if not all([listing_id, session_id, latitude, longitude]):
            return json.dumps({
                'success': False,
                'error': 'listingId, session_id, latitude, and longitude are required'
            })
        
        result = propose_meeting_location(listing_id, session_id, latitude, longitude, location_name)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/MeetingLocation/Counter', methods=['POST'])
@cross_origin()
def CounterMeetingLocation():
    """Counter-propose a meeting location (refactored)"""
    try:
        from flask import request
        import json
        
        listing_id = request.args.get('listingId') or (request.json or {}).get('listingId')
        session_id = request.args.get('session_id') or (request.json or {}).get('session_id')
        latitude = request.args.get('latitude') or (request.json or {}).get('latitude')
        longitude = request.args.get('longitude') or (request.json or {}).get('longitude')
        location_name = request.args.get('locationName') or (request.json or {}).get('locationName')
        
        if not all([listing_id, session_id, latitude, longitude]):
            return json.dumps({
                'success': False,
                'error': 'listingId, session_id, latitude, and longitude are required'
            })
        
        result = counter_meeting_location(listing_id, session_id, latitude, longitude, location_name)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/MeetingLocation/Accept', methods=['GET'])
@cross_origin()
def AcceptMeetingLocation():
    """Accept meeting location proposal (refactored)"""
    try:
        from flask import request
        listing_id = request.args.get('listingId')
        session_id = request.args.get('session_id')
        
        if not all([listing_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'listingId and session_id are required'
            })
        
        result = accept_meeting_location(listing_id, session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/MeetingLocation/Reject', methods=['GET'])
@cross_origin()
def RejectMeetingLocation():
    """Reject meeting location proposal (refactored)"""
    try:
        from flask import request
        listing_id = request.args.get('listingId')
        session_id = request.args.get('session_id')
        
        if not all([listing_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'listingId and session_id are required'
            })
        
        result = reject_meeting_location(listing_id, session_id)
        return result
        
    except Exception as e:
        return Debugger(e)

@negotiations_bp.route('/ListingPayment/Pay', methods=['GET'])
@cross_origin()
def PayListingFee():
    """Pay $2 listing fee (refactored)"""
    try:
        from flask import request, Response
        import json
        listing_id = request.args.get('listingId')
        session_id = request.args.get('session_id')
        
        if not all([listing_id, session_id]):
            return Response(
                json.dumps({
                    'success': False,
                    'error': 'listingId and session_id are required'
                }),
                mimetype='application/json'
            )
        
        result = pay_negotiation_fee(listing_id, session_id)
        return Response(result, mimetype='application/json')
        
    except Exception as e:
        import json
        print(f"[ListingPayment/Pay] Exception: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response(
            json.dumps({
                'success': False,
                'error': f'Payment processing failed: {str(e)}'
            }),
            mimetype='application/json'
        )

@negotiations_bp.route('/Negotiations/CompleteExchange', methods=['GET'])
@cross_origin()
def CompleteExchange():
    """Mark an exchange as completed and prepare for rating"""
    try:
        from flask import request, Response
        import json
        listing_id = request.args.get('ListingId')
        session_id = request.args.get('session_id')
        negotiation_id = request.args.get('NegotiationId')
        
        print(f"[CompleteExchange] Endpoint called: session_id={session_id}, ListingId={listing_id}, NegotiationId={negotiation_id}")
        
        if not all([session_id]) or not (listing_id or negotiation_id):
            print(f"[CompleteExchange] Missing required parameters")
            return Response(
                json.dumps({
                    'success': False,
                    'error': 'session_id and (ListingId or NegotiationId) are required'
                }),
                mimetype='application/json'
            )
        
        print(f"[CompleteExchange] Calling complete_exchange with: session_id={session_id}, id={negotiation_id or listing_id}")
        result = complete_exchange(session_id, negotiation_id or listing_id)
        print(f"[CompleteExchange] Result: {result}")
        return Response(result, mimetype='application/json')
        
    except Exception as e:
        import json
        print(f"[CompleteExchange] Exception: {str(e)}")
        import traceback
        traceback.print_exc()
        return Response(
            json.dumps({
                'success': False,
                'error': f'Failed to complete exchange: {str(e)}'
            }),
            mimetype='application/json'
        )