#!/usr/bin/env python3
"""
Debug script to check listing status
Run this to see what happened to your listings
"""

import sys
import os

# Add the server directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from _Lib import Database
from datetime import datetime

def debug_listings():
    try:
        cursor, connection = Database.ConnectToDatabase()
        
        print("=== DEBUGGING LISTINGS ===")
        print(f"Current time: {datetime.now()}")
        print()
        
        # Check all listings
        cursor.execute("SELECT COUNT(*) as total FROM listings")
        total_count = cursor.fetchone()['total']
        print(f"Total listings in database: {total_count}")
        
        # Check by status
        cursor.execute("SELECT status, COUNT(*) as count FROM listings GROUP BY status")
        status_results = cursor.fetchall()
        print("\nListings by status:")
        for row in status_results:
            print(f"  {row['status']}: {row['count']}")
        
        # Check recent listings
        cursor.execute("""
            SELECT listing_id, user_id, currency, amount, accept_currency, 
                   status, created_at, available_until
            FROM listings 
            ORDER BY created_at DESC 
            LIMIT 10
        """)
        recent_listings = cursor.fetchall()
        
        print(f"\nMost recent 10 listings:")
        for listing in recent_listings:
            expired = "EXPIRED" if listing['available_until'] < datetime.now() else "ACTIVE"
            print(f"  ID: {listing['listing_id'][:8]}... | Status: {listing['status']} | Available: {listing['available_until']} ({expired})")
        
        # Check users table
        cursor.execute("SELECT COUNT(*) as total FROM users")
        users_count = cursor.fetchone()['total']
        print(f"\nTotal users: {users_count}")
        
        # Check sessions
        cursor.execute("SELECT COUNT(*) as total FROM usersessions")
        sessions_count = cursor.fetchone()['total']
        print(f"Active sessions: {sessions_count}")
        
        connection.close()
        
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    debug_listings()