from _Lib.Debugger import Debugger
from flask import Blueprint, request
from flask_cors import cross_origin
import json
from .DownloadExchangeRates import download_and_save_exchange_rates
from .GetExchangeRates import get_exchange_rates, get_exchange_rate, convert_amount

# Create the ExchangeRates blueprint
exchange_rates_bp = Blueprint('exchange_rates', __name__)

@exchange_rates_bp.route('/ExchangeRates/Download', methods=['GET'])
@cross_origin()
def DownloadExchangeRates():
    """Download latest exchange rates and save to database"""
    try:
        result = download_and_save_exchange_rates()
        return result
        
    except Exception as e:
        print(f"[ExchangeRates] DownloadExchangeRates error: {str(e)}")
        import traceback
        print(f"[ExchangeRates] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to download exchange rates'
        })

@exchange_rates_bp.route('/ExchangeRates/GetRates', methods=['GET'])
@cross_origin()
def GetExchangeRates():
    """Get all current exchange rates from database"""
    try:
        result = get_exchange_rates()
        return result
        
    except Exception as e:
        print(f"[ExchangeRates] GetExchangeRates error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to get exchange rates'
        })

@exchange_rates_bp.route('/ExchangeRates/GetRate', methods=['GET'])
@cross_origin()
def GetExchangeRate():
    """Get specific exchange rate between two currencies"""
    try:
        from_currency = request.args.get('fromCurrency')
        to_currency = request.args.get('toCurrency')
        
        if not from_currency or not to_currency:
            return json.dumps({
                'success': False,
                'error': 'Both fromCurrency and toCurrency are required'
            })
        
        result = get_exchange_rate(from_currency, to_currency)
        return result
        
    except Exception as e:
        print(f"[ExchangeRates] GetExchangeRate error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to get exchange rate'
        })

@exchange_rates_bp.route('/ExchangeRates/Convert', methods=['GET'])
@cross_origin()
def ConvertAmount():
    """Convert an amount from one currency to another"""
    try:
        amount = request.args.get('amount')
        from_currency = request.args.get('fromCurrency')
        to_currency = request.args.get('toCurrency')
        
        if not all([amount, from_currency, to_currency]):
            return json.dumps({
                'success': False,
                'error': 'amount, fromCurrency, and toCurrency are all required'
            })
        
        try:
            amount = float(amount)
        except ValueError:
            return json.dumps({
                'success': False,
                'error': 'Invalid amount - must be a number'
            })
        
        result = convert_amount(amount, from_currency, to_currency)
        return result
        
    except Exception as e:
        print(f"[ExchangeRates] ConvertAmount error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to convert amount'
        })