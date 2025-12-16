from _Lib import Database
import json
from datetime import datetime
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from ExchangeRates.GetExchangeRates import get_exchange_rate

def calculate_and_lock_exchange_rate(listing_id, user_id):
    """Calculate exchange rate for a listing purchase and lock it in"""
    try:
        print(f"[CalculateExchangeRate] Calculating rate for listing {listing_id}, user {user_id}")
        
        cursor, connection = Database.ConnectToDatabase()
        
        # Get listing details
        cursor.execute("""
            SELECT currency, amount, accept_currency 
            FROM listings 
            WHERE listing_id = %s
        """, (listing_id,))
        
        listing_result = cursor.fetchone()
        if not listing_result:
            cursor.close()
            connection.close()
            return {
                'success': False,
                'error': 'Listing not found'
            }
        
        from_currency = listing_result['currency']  # What seller has
        to_currency = listing_result['accept_currency']  # What buyer will pay
        listing_amount = float(listing_result['amount'])
        
        print(f"[CalculateExchangeRate] Converting {listing_amount} {from_currency} to {to_currency}")
        
        # Get current exchange rate
        rate_response = json.loads(get_exchange_rate(from_currency, to_currency))
        
        if not rate_response['success']:
            cursor.close()
            connection.close()
            return {
                'success': False,
                'error': f'Failed to get exchange rate: {rate_response.get("error", "Unknown error")}'
            }
        
        exchange_rate = rate_response['rate']
        locked_amount = round(listing_amount * exchange_rate, 2)
        
        # Get individual USD rates for audit trail
        from_usd_response = json.loads(get_exchange_rate('USD', from_currency))
        to_usd_response = json.loads(get_exchange_rate('USD', to_currency))
        
        usd_rate_from = from_usd_response['rate'] if from_usd_response['success'] else None
        usd_rate_to = to_usd_response['rate'] if to_usd_response['success'] else None
        
        connection.commit()
        cursor.close()
        connection.close()
        
        print(f"[CalculateExchangeRate] Locked rate: 1 {from_currency} = {exchange_rate} {to_currency}")
        print(f"[CalculateExchangeRate] Buyer will pay: {locked_amount} {to_currency}")
        
        return {
            'success': True,
            'exchange_rate': exchange_rate,
            'locked_amount': locked_amount,
            'from_currency': from_currency,
            'to_currency': to_currency,
            'listing_amount': listing_amount,
            'calculation_date': today,
            'calculation': f'{listing_amount} {from_currency} × {exchange_rate} = {locked_amount} {to_currency}'
        }
        
    except Exception as e:
        print(f"[CalculateExchangeRate] Error: {str(e)}")
        import traceback
        print(f"[CalculateExchangeRate] Traceback: {traceback.format_exc()}")
        return {
            'success': False,
            'error': f'Failed to calculate exchange rate: {str(e)}'
        }

def get_locked_exchange_rate(user_id, listing_id):
    """Get the exchange rate for a negotiation"""
    try:
        print(f"[GetLockedRate] Getting rate for user {user_id}, listing {listing_id}")
        
        cursor, connection = Database.ConnectToDatabase()
        
        # Get listing info
        cursor.execute("""
            SELECT l.amount as listing_amount, l.currency, l.accept_currency
            FROM listings l
            WHERE l.listing_id = %s
        """, (listing_id,))
        
        result = cursor.fetchone()
        cursor.close()
        connection.close()
        
        if not result:
            return {
                'success': False,
                'error': 'Listing not found'
            }
        
        # Calculate rate dynamically instead of storing it
        from Listings.GetExchangeRate import get_exchange_rate
        
        rate_result = get_exchange_rate(
            result['currency'],
            result['accept_currency']
        )
        
        if not rate_result or not rate_result.get('success'):
            return {
                'success': False,
                'error': 'Exchange rate not calculated yet'
            }
        
        return {
            'success': True,
            'exchange_rate': float(rate_result.get('exchange_rate', 0)),
            'from_currency': result['currency'],
            'to_currency': result['accept_currency'],
            'listing_amount': float(result['listing_amount']),
            'calculation': f"{result['listing_amount']} {result['currency']} → {result['accept_currency']}"
        }
        
    except Exception as e:
        print(f"[GetLockedRate] Error: {str(e)}")
        return {
            'success': False,
            'error': f'Failed to get locked exchange rate: {str(e)}'
        }