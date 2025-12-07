#!/usr/bin/env python3
"""Verify database state for location proposals"""

import pymysql
import pymysql.cursors

db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)
cursor = db.cursor()

listing_id = '684e682e-cd15-4084-b92b-3b5c3ab8e639'

print("\n=== DEBUGGING DATABASE STATE ===\n")

print(f"Listing ID: {listing_id}\n")

# Check exchange_negotiations
print("1. EXCHANGE_NEGOTIATIONS:")
cursor.execute("""
    SELECT negotiation_id, current_proposed_time, status 
    FROM exchange_negotiations 
    WHERE listing_id = %s
""", (listing_id,))
exchange_results = cursor.fetchall()
print(f"   Found {len(exchange_results)} records")
for row in exchange_results:
    print(f"   - {row['negotiation_id']}: time={row['current_proposed_time']}, status={row['status']}")

# Check negotiation_history
print("\n2. NEGOTIATION_HISTORY:")
cursor.execute("""
    SELECT DISTINCT negotiation_id FROM negotiation_history 
    WHERE listing_id = %s
""", (listing_id,))
location_results = cursor.fetchall()
print(f"   Found {len(location_results)} distinct negotiation_ids")

for neg_row in location_results:
    neg_id = neg_row['negotiation_id']
    print(f"\n   Negotiation ID: {neg_id}")
    
    cursor.execute("""
        SELECT history_id, action, proposed_location, proposed_latitude, proposed_longitude, 
               proposed_by, created_at
        FROM negotiation_history
        WHERE negotiation_id = %s
        ORDER BY created_at DESC
    """, (neg_id,))
    
    history_records = cursor.fetchall()
    print(f"   History records: {len(history_records)}")
    
    for hist in history_records:
        print(f"     - {hist['history_id']}: action={hist['action']}, location={hist['proposed_location']}")
        print(f"       coords=({hist['proposed_latitude']}, {hist['proposed_longitude']})")
        print(f"       by={hist['proposed_by']}, at={hist['created_at']}")

# Check for accepted_location specifically
print("\n3. ACCEPTED LOCATIONS:")
cursor.execute("""
    SELECT negotiation_id, history_id, proposed_location, action
    FROM negotiation_history
    WHERE listing_id = %s AND action = 'accepted_location'
""", (listing_id,))
accepted = cursor.fetchall()
print(f"   Found {len(accepted)} accepted_location records")
for row in accepted:
    print(f"   - {row['history_id']}: {row['proposed_location']}")

db.close()
