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

# Create the Negotiations blueprint
negotiations_bp = Blueprint('negotiations', __name__)

@negotiations_bp.route('/Negotiations/Propose', methods=['GET'])
@cross_origin()
def ProposeNegotiation():
    """Buyer proposes initial meeting time for a listing"""
    try:
        from flask import request
        listing_id = request.args.get('listingId')
        session_id = request.args.get('sessionId')
        proposed_time = request.args.get('proposedTime')
        
        if not all([listing_id, session_id, proposed_time]):
            import json
            return json.dumps({
                'success': False,
                'error': 'listingId, sessionId, and proposedTime are required'
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
        session_id = request.args.get('sessionId')
        
        if not all([negotiation_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'negotiationId and sessionId are required'
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
        session_id = request.args.get('sessionId')
        
        if not all([negotiation_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'negotiationId and sessionId are required'
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
        session_id = request.args.get('sessionId')
        
        if not all([negotiation_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'negotiationId and sessionId are required'
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
        session_id = request.args.get('sessionId')
        proposed_time = request.args.get('proposedTime')
        
        if not all([negotiation_id, session_id, proposed_time]):
            import json
            return json.dumps({
                'success': False,
                'error': 'negotiationId, sessionId, and proposedTime are required'
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
        session_id = request.args.get('sessionId')
        
        if not all([negotiation_id, session_id]):
            return Response(
                json.dumps({
                    'success': False,
                    'error': 'negotiationId and sessionId are required'
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
        session_id = request.args.get('sessionId')
        
        if not session_id:
            import json
            return json.dumps({
                'success': False,
                'error': 'sessionId is required'
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
        session_id = request.args.get('sessionId')
        
        if not all([buyer_id, session_id]):
            import json
            return json.dumps({
                'success': False,
                'error': 'buyerId and sessionId are required'
            })
        
        result = get_buyer_info(buyer_id, session_id)
        return result
        
    except Exception as e:
        return Debugger(e)


