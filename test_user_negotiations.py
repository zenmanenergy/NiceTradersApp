#!/usr/bin/env python3
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

# Get the current user
session_id = 'SES108a7b27-8159-44c6-94ba-19ba954ce70b'
cursor.execute("SELECT user_id FROM user_sessions WHERE session_id = %s", (session_id,))
session_result = cursor.fetchone()
user_id = session_result['user_id']

print(f"Current user: {user_id}\n")

# Check active negotiations for this user (as owner or buyer)
print("=== Active Negotiations (as owner) ===")
cursor.execute("""
    SELECT l.listing_id, l.user_id as owner_id, l.buyer_id, n.negotiation_id, n.status
    FROM listings l
    LEFT JOIN negotiations n ON l.listing_id = n.listing_id
    WHERE l.user_id = %s AND l.status = 'active'
""", (user_id,))
results = cursor.fetchall()
for row in results:
    print(f"  Listing: {row['listing_id']}")
    print(f"    Buyer: {row['buyer_id']}")
    print(f"    Negotiation ID: {row['negotiation_id']}")
    print(f"    Status: {row['status']}")

print("\n=== Active Negotiations (as buyer) ===")
cursor.execute("""
    SELECT l.listing_id, l.user_id as owner_id, l.buyer_id, n.negotiation_id, n.status
    FROM listings l
    LEFT JOIN negotiations n ON l.listing_id = n.listing_id
    WHERE l.buyer_id = %s AND l.status = 'active'
""", (user_id,))
results = cursor.fetchall()
for row in results:
    print(f"  Listing: {row['listing_id']}")
    print(f"    Owner: {row['owner_id']}")
    print(f"    Negotiation ID: {row['negotiation_id']}")
    print(f"    Status: {row['status']}")

# Check what negotiations exist at all
print("\n=== All negotiations (first 5) ===")
cursor.execute("""
    SELECT n.negotiation_id, n.listing_id, l.user_id, l.buyer_id, n.status
    FROM negotiations n
    JOIN listings l ON n.listing_id = l.listing_id
    LIMIT 5
""")
results = cursor.fetchall()
for row in results:
    print(f"  Neg: {row['negotiation_id']}")
    print(f"    Listing: {row['listing_id']}")
    print(f"    Owner: {row['user_id']}, Buyer: {row['buyer_id']}")
    print(f"    Status: {row['status']}")

db.close()
