from _Lib import Database
import json
from datetime import datetime

def get_exchange_rates(date=None):
    """Get all exchange rates from database for a specific date (default: latest)"""
    try:
        print(f"[GetExchangeRates] Getting exchange rates for date: {date or 'latest'}")
        
        cursor, connection = Database.ConnectToDatabase()
        
        if date:
            # Get rates for specific date
            query = """
            SELECT currency_code, rate_to_usd, last_updated, date_retrieved 
            FROM exchange_rates 
            WHERE date_retrieved = %s 
            ORDER BY currency_code
            """
            cursor.execute(query, (date,))
        else:
            # Get latest rates
            query = """
            SELECT currency_code, rate_to_usd, last_updated, date_retrieved 
            FROM exchange_rates 
            WHERE date_retrieved = (SELECT MAX(date_retrieved) FROM exchange_rates)
            ORDER BY currency_code
            """
            cursor.execute(query)
        
        results = cursor.fetchall()
        
        if not results:
            cursor.close()
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'No exchange rates found for the specified date'
            })
        
        # Format rates data
        rates = {}
        latest_date = None
        
        for row in results:
            rates[row['currency_code']] = {
                'rate': float(row['rate_to_usd']),
                'last_updated': row['last_updated'].isoformat() if row['last_updated'] else None
            }
            if not latest_date:
                latest_date = row['date_retrieved'].strftime('%Y-%m-%d') if row['date_retrieved'] else None
        
        cursor.close()
        connection.close()
        
        return json.dumps({
            'success': True,
            'rates': rates,
            'base_currency': 'USD',
            'date': latest_date,
            'count': len(rates)
        })
        
    except Exception as e:
        print(f"[GetExchangeRates] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to get exchange rates: {str(e)}'
        })

def get_exchange_rate(from_currency, to_currency):
    """Get exchange rate between two specific currencies"""
    try:
        print(f"[GetExchangeRate] Getting rate from {from_currency} to {to_currency}")
        
        cursor, connection = Database.ConnectToDatabase()
        
        # Get latest rates for both currencies
        query = """
        SELECT currency_code, rate_to_usd 
        FROM exchange_rates 
        WHERE currency_code IN (%s, %s) 
        AND date_retrieved = (SELECT MAX(date_retrieved) FROM exchange_rates)
        """
        
        cursor.execute(query, (from_currency, to_currency))
        results = cursor.fetchall()
        
        if len(results) != 2:
            cursor.close()
            connection.close()
            return json.dumps({
                'success': False,
                'error': f'Exchange rates not found for {from_currency} or {to_currency}'
            })
        
        # Calculate conversion rate
        rates = {row['currency_code']: float(row['rate_to_usd']) for row in results}
        
        # Convert: from_currency -> USD -> to_currency
        if from_currency == 'USD':
            conversion_rate = rates[to_currency]
        elif to_currency == 'USD':
            conversion_rate = 1.0 / rates[from_currency]
        else:
            # Convert through USD: (1 / from_rate) * to_rate
            conversion_rate = rates[to_currency] / rates[from_currency]
        
        cursor.close()
        connection.close()
        
        return json.dumps({
            'success': True,
            'from_currency': from_currency,
            'to_currency': to_currency,
            'rate': round(conversion_rate, 6),
            'calculation': f'1 {from_currency} = {round(conversion_rate, 6)} {to_currency}'
        })
        
    except Exception as e:
        print(f"[GetExchangeRate] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to get exchange rate: {str(e)}'
        })

def convert_amount(amount, from_currency, to_currency):
    """Convert an amount from one currency to another"""
    try:
        print(f"[ConvertAmount] Converting {amount} {from_currency} to {to_currency}")
        
        # Get the exchange rate
        rate_response = json.loads(get_exchange_rate(from_currency, to_currency))
        
        if not rate_response['success']:
            return json.dumps(rate_response)
        
        rate = rate_response['rate']
        converted_amount = float(amount) * rate
        
        return json.dumps({
            'success': True,
            'original_amount': float(amount),
            'original_currency': from_currency,
            'converted_amount': round(converted_amount, 2),
            'converted_currency': to_currency,
            'exchange_rate': rate
        })
        
    except Exception as e:
        print(f"[ConvertAmount] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to convert amount: {str(e)}'
        })