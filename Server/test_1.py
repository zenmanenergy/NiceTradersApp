#!/usr/bin/env python3
"""
Test State 1: Buyer proposes a time
Creates a listing_meeting_time row with accepted_at = NULL
"""

import pymysql
import pymysql.cursors
from datetime import datetime, timedelta, timezone
import uuid

# Test values
listing_id = '1ed56571-d1db-4c68-b487-a05b8ac84b54'
seller_id = 'USR53a3c642-4914-4de8-8217-03ee3da42224'
buyer_id = 'USR387e9549-3339-4ea1-b0d2-f6a66c25c390'

# Connect to database
db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)
cursor = db.cursor()

try:
    # Check if time negotiation already exists
    cursor.execute("""
        SELECT time_negotiation_id FROM listing_meeting_time
        WHERE listing_id = %s
    """, (listing_id,))
    
    existing = cursor.fetchone()
    
    if existing:
        print(f"⚠️  Time negotiation already exists: {existing['time_negotiation_id']}")
        print("Deleting existing negotiation...")
        cursor.execute("""
            DELETE FROM listing_meeting_time WHERE listing_id = %s
        """, (listing_id,))
        db.commit()
    
    # Create time negotiation with buyer proposing
    time_negotiation_id = f"TNL-{uuid.uuid4().hex[:35]}"
    # Store as UTC time - convert current local time to UTC
    proposed_time_utc = datetime.now(timezone.utc) + timedelta(days=2)
    # Remove timezone info for MySQL storage (MySQL will treat it as UTC)
    proposed_time = proposed_time_utc.replace(tzinfo=None)
    
    cursor.execute("""
        INSERT INTO listing_meeting_time
        (time_negotiation_id, listing_id, buyer_id, proposed_by, meeting_time, created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, NOW(), NOW())
    """, (time_negotiation_id, listing_id, buyer_id, buyer_id, proposed_time))
    
    db.commit()
    
    print("✅ Test State 1: Buyer proposes a time")
    print(f"   time_negotiation_id: {time_negotiation_id}")
    print(f"   listing_id: {listing_id}")
    print(f"   buyer_id: {buyer_id}")
    print(f"   proposed_by: {buyer_id}")
    print(f"   meeting_time: {proposed_time}")
    print(f"   accepted_at: NULL")
    print(f"   rejected_at: NULL")
    
except Exception as e:
    print(f"❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
finally:
    cursor.close()
    db.close()
