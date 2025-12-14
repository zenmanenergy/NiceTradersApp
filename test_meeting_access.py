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

# Check the session
session_id = 'SES108a7b27-8159-44c6-94ba-19ba954ce70b'
cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
session_result = cursor.fetchone()
print(f"Session {session_id}:")
print(f"  User ID: {session_result['user_id'] if session_result else 'NOT FOUND'}")

if session_result:
    user_id = session_result['user_id']
    
    # Check the listing
    listing_id = '3e7cfcfe-1f30-4662-babe-884b60c9a53a'
    cursor.execute("""
        SELECT user_id, buyer_id, status FROM listings WHERE listing_id = %s
    """, (listing_id,))
    listing_result = cursor.fetchone()
    print(f"\nListing {listing_id}:")
    if listing_result:
        print(f"  Owner: {listing_result['user_id']}")
        print(f"  Buyer: {listing_result['buyer_id']}")
        print(f"  Status: {listing_result['status']}")
    else:
        print(f"  NOT FOUND")
    
    # Check if user has any listings or purchases
    print(f"\nUser {user_id}:")
    cursor.execute("SELECT COUNT(*) as count FROM listings WHERE user_id = %s", (user_id,))
    result = cursor.fetchone()
    print(f"  Owns {result['count']} listings")
    
    cursor.execute("SELECT COUNT(*) as count FROM listings WHERE buyer_id = %s", (user_id,))
    result = cursor.fetchone()
    print(f"  Is buyer on {result['count']} listings")

db.close()
