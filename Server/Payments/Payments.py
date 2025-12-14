from flask import Blueprint, request, Response
from flask_cors import cross_origin
import json
from Negotiations.PayNegotiationFee import pay_negotiation_fee

payments_bp = Blueprint('payments', __name__)

@payments_bp.route('/Payments/ProcessPayment', methods=['GET', 'POST'])
@cross_origin()
def ProcessPayment():
    """
    Process payment for listing negotiation ($2 fee)
    Maps to the existing PayNegotiationFee functionality
    """
    try:
        if request.method == 'POST':
            request_data = request.get_json()
        else:
            request_data = request.args.to_dict()
        
        listing_id = request_data.get('listingId')
        session_id = request_data.get('sessionId')
        
        if not all([listing_id, session_id]):
            return Response(
                json.dumps({
                    'success': False,
                    'error': 'listingId and sessionId are required'
                }),
                mimetype='application/json'
            )
        
        # Call the existing payment function
        result = pay_negotiation_fee(listing_id, session_id)
        return Response(result, mimetype='application/json')
        
    except Exception as e:
        print(f"[Payments] ProcessPayment error: {str(e)}")
        return Response(
            json.dumps({
                'success': False,
                'error': str(e)
            }),
            mimetype='application/json',
            status=500
        )
