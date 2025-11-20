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
        
        # Update contact_access record with locked exchange rate
        today = datetime.now().strftime('%Y-%m-%d')
        
        cursor.execute("""
            UPDATE contact_access 
            SET exchange_rate = %s, 
                locked_amount = %s, 
                rate_calculation_date = %s,
                from_currency = %s,
                to_currency = %s,
                usd_rate_from = %s,
                usd_rate_to = %s
            WHERE user_id = %s AND listing_id = %s AND status = 'active'
        """, (
            exchange_rate, locked_amount, today, 
            from_currency, to_currency, 
            usd_rate_from, usd_rate_to,
            user_id, listing_id
        ))
        
        if cursor.rowcount == 0:
            cursor.close()
            connection.close()
            return {
                'success': False,
                'error': 'No active contact access found to update'
            }
        
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
    """Get the locked exchange rate for a specific contact access"""
    try:
        print(f"[GetLockedRate] Getting locked rate for user {user_id}, listing {listing_id}")
        
        cursor, connection = Database.ConnectToDatabase()
        
        cursor.execute("""
            SELECT ca.exchange_rate, ca.locked_amount, ca.rate_calculation_date,
                   ca.from_currency, ca.to_currency, ca.usd_rate_from, ca.usd_rate_to,
                   l.amount as listing_amount, l.currency, l.accept_currency
            FROM contact_access ca
            JOIN listings l ON ca.listing_id = l.listing_id
            WHERE ca.user_id = %s AND ca.listing_id = %s AND ca.status = 'active'
        """, (user_id, listing_id))
        
        result = cursor.fetchone()
        cursor.close()
        connection.close()
        
        if not result:
            return {
                'success': False,
                'error': 'No active contact access found'
            }
        
        if not result['exchange_rate']:
            return {
                'success': False,
                'error': 'Exchange rate not calculated yet'
            }
        
        return {
            'success': True,
            'exchange_rate': float(result['exchange_rate']),
            'locked_amount': float(result['locked_amount']),
            'from_currency': result['from_currency'],
            'to_currency': result['to_currency'],
            'listing_amount': float(result['listing_amount']),
            'rate_calculation_date': result['rate_calculation_date'].strftime('%Y-%m-%d') if result['rate_calculation_date'] else None,
            'calculation': f"{result['listing_amount']} {result['from_currency']} × {result['exchange_rate']} = {result['locked_amount']} {result['to_currency']}"
        }
        
    except Exception as e:
        print(f"[GetLockedRate] Error: {str(e)}")
        return {
            'success': False,
            'error': f'Failed to get locked exchange rate: {str(e)}'
        }