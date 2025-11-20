from _Lib import Database
import json
import schedule
import time
import threading
from datetime import datetime
from .DownloadExchangeRates import download_and_save_exchange_rates, get_latest_rates_date

class ExchangeRateScheduler:
    """Scheduler for automatic exchange rate updates"""
    
    def __init__(self):
        self.scheduler_running = False
        self.scheduler_thread = None
    
    def start_scheduler(self):
        """Start the background scheduler for exchange rate updates"""
        if self.scheduler_running:
            print("[ExchangeRateScheduler] Scheduler already running")
            return
        
        print("[ExchangeRateScheduler] Starting exchange rate scheduler")
        
        # Schedule daily download at 6 AM UTC (after ECB updates)
        schedule.every().day.at("06:00").do(self.scheduled_download)
        
        # Also check on startup if we need rates for today
        self.check_and_download_if_needed()
        
        self.scheduler_running = True
        self.scheduler_thread = threading.Thread(target=self._run_scheduler, daemon=True)
        self.scheduler_thread.start()
        
        print("[ExchangeRateScheduler] Scheduler started successfully")
    
    def stop_scheduler(self):
        """Stop the background scheduler"""
        print("[ExchangeRateScheduler] Stopping scheduler")
        self.scheduler_running = False
        schedule.clear()
    
    def _run_scheduler(self):
        """Background thread to run the scheduler"""
        while self.scheduler_running:
            schedule.run_pending()
            time.sleep(60)  # Check every minute
    
    def scheduled_download(self):
        """Function called by scheduler to download rates"""
        print(f"[ExchangeRateScheduler] Scheduled download triggered at {datetime.now()}")
        try:
            result = download_and_save_exchange_rates()
            result_data = json.loads(result)
            
            if result_data['success']:
                print(f"[ExchangeRateScheduler] Successfully downloaded {result_data.get('rates_count', 0)} rates")
                self.log_download_event(True, result_data.get('rates_count', 0))
            else:
                print(f"[ExchangeRateScheduler] Download failed: {result_data.get('error', 'Unknown error')}")
                self.log_download_event(False, 0, result_data.get('error'))
                
        except Exception as e:
            print(f"[ExchangeRateScheduler] Scheduled download error: {str(e)}")
            self.log_download_event(False, 0, str(e))
    
    def check_and_download_if_needed(self):
        """Check if we have today's rates, download if not"""
        try:
            latest_date = get_latest_rates_date()
            today = datetime.now().strftime('%Y-%m-%d')
            
            if latest_date != today:
                print(f"[ExchangeRateScheduler] No rates for today ({today}), downloading...")
                self.scheduled_download()
            else:
                print(f"[ExchangeRateScheduler] Rates for today ({today}) already exist")
                
        except Exception as e:
            print(f"[ExchangeRateScheduler] Error checking rates: {str(e)}")
    
    def manual_download(self):
        """Manually trigger a download (for testing or admin use)"""
        print("[ExchangeRateScheduler] Manual download triggered")
        return self.scheduled_download()
    
    def log_download_event(self, success, rates_count=0, error_message=None):
        """Log download events to database for monitoring"""
        try:
            cursor, connection = Database.ConnectToDatabase()
            
            # Create log table if it doesn't exist
            create_log_table = """
            CREATE TABLE IF NOT EXISTS exchange_rate_logs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                download_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                success BOOLEAN NOT NULL,
                rates_downloaded INT DEFAULT 0,
                error_message TEXT,
                INDEX idx_timestamp (download_timestamp),
                INDEX idx_success (success)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """
            
            cursor.execute(create_log_table)
            
            # Insert log entry
            cursor.execute("""
                INSERT INTO exchange_rate_logs (success, rates_downloaded, error_message) 
                VALUES (%s, %s, %s)
            """, (success, rates_count, error_message))
            
            connection.commit()
            cursor.close()
            connection.close()
            
        except Exception as e:
            print(f"[ExchangeRateScheduler] Error logging download event: {str(e)}")

# Global scheduler instance
scheduler = ExchangeRateScheduler()

def start_exchange_rate_scheduler():
    """Start the global exchange rate scheduler"""
    scheduler.start_scheduler()

def stop_exchange_rate_scheduler():
    """Stop the global exchange rate scheduler"""
    scheduler.stop_scheduler()

def manual_download_rates():
    """Manually download exchange rates"""
    return scheduler.manual_download()