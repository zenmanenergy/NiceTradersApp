#!/usr/bin/env python3
"""
Daily Notification Task Runner
Run this script once daily to send reminder notifications to users
Can be scheduled via cron: 0 9 * * * /path/to/run_daily_notifications.py
"""
import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from Admin.DailyNotificationService import daily_notification_service
from datetime import datetime
import json

def main():
    """Run daily notification checks"""
    print("=" * 70)
    print(f"🔔 Starting Daily Notification Task - {datetime.now().isoformat()}")
    print("=" * 70)
    
    try:
        stats = daily_notification_service.check_and_send_daily_reminders()
        
        print("\n📊 Daily Notification Results:")
        print("-" * 70)
        print(f"✅ Pending Negotiations Reminders: {stats['pending_negotiations_sent']}")
        print(f"✅ Unread Messages Reminders: {stats['unread_messages_sent']}")
        print(f"✅ Pending Approvals Reminders: {stats['pending_approvals_sent']}")
        print(f"📤 Total Reminders Sent: {stats['total_sent']}")
        
        if stats['errors']:
            print(f"\n⚠️  Errors Encountered: {len(stats['errors'])}")
            for error in stats['errors']:
                print(f"   - {error}")
        
        print("\n" + "=" * 70)
        print(f"✅ Daily Notification Task Completed - {datetime.now().isoformat()}")
        print("=" * 70)
        
        return 0
    
    except Exception as e:
        print(f"\n❌ Fatal Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
