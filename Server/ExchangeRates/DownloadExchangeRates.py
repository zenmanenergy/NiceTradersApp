from _Lib import Database
import json
import requests
from datetime import datetime, timezone

def download_and_save_exchange_rates():
    """Download USD-based exchange rates and save to database"""
    try:
        print(f"[DownloadExchangeRates] Starting exchange rate download")
        
        # Download rates from ExchangeRate-API (USD base)
        url = "https://api.exchangerate-api.com/v4/latest/USD"
        
        print(f"[DownloadExchangeRates] Fetching rates from: {url}")
        response = requests.get(url, timeout=30)
        
        if response.status_code != 200:
            raise Exception(f"API request failed with status {response.status_code}")
        
        data = response.json()
        
        if 'rates' not in data:
            raise Exception("Invalid API response - no rates found")
        
        rates = data['rates']
        update_time = data.get('date', datetime.now().strftime('%Y-%m-%d'))
        
        print(f"[DownloadExchangeRates] Retrieved {len(rates)} exchange rates for {update_time}")
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Create exchange_rates table if it doesn't exist
        create_table_query = """
        CREATE TABLE IF NOT EXISTS exchange_rates (
            id INT AUTO_INCREMENT PRIMARY KEY,
            currency_code VARCHAR(3) NOT NULL,
            rate_to_usd DECIMAL(15,8) NOT NULL,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            date_retrieved DATE NOT NULL,
            UNIQUE KEY unique_currency_date (currency_code, date_retrieved),
            INDEX idx_currency (currency_code),
            INDEX idx_date (date_retrieved)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """
        
        cursor.execute(create_table_query)
        connection.commit()
        print(f"[DownloadExchangeRates] Exchange rates table created/verified")
        
        # Clear today's rates first (in case we're updating)
        today = datetime.now().strftime('%Y-%m-%d')
        cursor.execute("DELETE FROM exchange_rates WHERE date_retrieved = %s", (today,))
        print(f"[DownloadExchangeRates] Cleared existing rates for {today}")
        
        # Add USD as base currency (rate = 1.0)
        rates['USD'] = 1.0
        
        # Insert new rates
        insert_query = """
        INSERT INTO exchange_rates (currency_code, rate_to_usd, date_retrieved) 
        VALUES (%s, %s, %s)
        """
        
        rates_inserted = 0
        for currency, rate in rates.items():
            try:
                # Convert rate to USD base (API gives USD to other currency)
                # For USD base, we want: 1 USD = X of other currency
                rate_to_usd = float(rate)
                
                cursor.execute(insert_query, (currency, rate_to_usd, today))
                rates_inserted += 1
                
            except Exception as rate_error:
                print(f"[DownloadExchangeRates] Error inserting rate for {currency}: {str(rate_error)}")
                continue
        
        connection.commit()
        
        print(f"[DownloadExchangeRates] Successfully inserted {rates_inserted} exchange rates")
        
        # Close database connection
        cursor.close()
        connection.close()
        
        return json.dumps({
            'success': True,
            'message': f'Successfully downloaded and saved {rates_inserted} exchange rates',
            'rates_count': rates_inserted,
            'update_date': today
        })
        
    except requests.exceptions.RequestException as e:
        print(f"[DownloadExchangeRates] Network error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Network error: {str(e)}'
        })
        
    except Exception as e:
        print(f"[DownloadExchangeRates] Error: {str(e)}")
        import traceback
        print(f"[DownloadExchangeRates] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': f'Failed to download exchange rates: {str(e)}'
        })

def get_latest_rates_date():
    """Get the date of the most recent exchange rates in database"""
    try:
        cursor, connection = Database.ConnectToDatabase()
        
        cursor.execute("SELECT MAX(date_retrieved) as latest_date FROM exchange_rates")
        result = cursor.fetchone()
        
        cursor.close()
        connection.close()
        
        if result and result['latest_date']:
            return result['latest_date'].strftime('%Y-%m-%d')
        else:
            return None
            
    except Exception as e:
        print(f"[DownloadExchangeRates] Error getting latest rates date: {str(e)}")
        return None