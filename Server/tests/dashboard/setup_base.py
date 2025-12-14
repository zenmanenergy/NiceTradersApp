"""
Shared setup utilities for dashboard tests
"""
import pymysql
import pymysql.cursors
from datetime import datetime, timedelta

# Test data constants
LISTING_ID = '3e7cfcfe-1f30-4662-babe-884b60c9a53a'
SELLER_ID = 'USR53a3c642-4914-4de8-8217-03ee3da42224'
BUYER_ID = 'USR387e9549-3339-4ea1-b0d2-f6a66c25c390'

# Test user data (emails and passwords for reference, not used in scripts)
SELLER_EMAIL = 's@b.com'
SELLER_PASSWORD = 'q'

BUYER_EMAIL = 'b@b.com'
BUYER_PASSWORD = 'q'

def connect_db():
    """Connect to the test database"""
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders',
        cursorclass=pymysql.cursors.DictCursor
    )
    return db

def cleanup_test_data(db):
    """Remove test listing and related data (but preserve users)"""
    cursor = db.cursor()
    try:
        # Delete in order of foreign key dependencies
        # Start with most dependent tables first
        # NOTE: We do NOT delete users - they should be preserved
        cursor.execute("DELETE FROM user_ratings WHERE user_id IN (%s, %s) OR rater_id IN (%s, %s)", (SELLER_ID, BUYER_ID, SELLER_ID, BUYER_ID))
        cursor.execute("DELETE FROM exchange_history WHERE user_id IN (%s, %s)", (SELLER_ID, BUYER_ID))
        cursor.execute("DELETE FROM transactions WHERE listing_id = %s", (LISTING_ID,))
        cursor.execute("DELETE FROM listing_payments WHERE listing_id = %s", (LISTING_ID,))
        cursor.execute("DELETE FROM listing_meeting_location WHERE listing_id = %s", (LISTING_ID,))
        cursor.execute("DELETE FROM listing_meeting_time WHERE listing_id = %s", (LISTING_ID,))
        cursor.execute("DELETE FROM listings WHERE listing_id = %s", (LISTING_ID,))
        db.commit()
        print("✅ Cleaned up existing test listing data")
    except Exception as e:
        print(f"⚠️  Cleanup warning: {e}")
        db.rollback()
    finally:
        cursor.close()

def setup_users_and_listing(db):
    """Create test listing (users should already exist)"""
    cursor = db.cursor()
    try:
        # Create listing only - users are assumed to already exist
        cursor.execute("""
            INSERT IGNORE INTO listings (
                listing_id, user_id, currency, amount, accept_currency,
                location, latitude, longitude, available_until, status
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            LISTING_ID, SELLER_ID, 'USD', 100.00, 'EUR',
            'San Francisco, CA', 37.7749, -122.4194,
            (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d %H:%M:%S'),
            'active'
        ))
        
        db.commit()
        print("✅ Created test listing")
    except Exception as e:
        print(f"❌ Error setting up listing: {e}")
        db.rollback()
        raise
    finally:
        cursor.close()

def display_status(db):
    """Display current state of the listing"""
    cursor = db.cursor()
    
    print("\n" + "="*70)
    print("CURRENT DATABASE STATE")
    print("="*70)
    
    try:
        # Check listing
        cursor.execute("SELECT * FROM listings WHERE listing_id = %s", (LISTING_ID,))
        listing = cursor.fetchone()
        if listing:
            print(f"\n📋 Listing: {listing['listing_id']}")
            print(f"   Status: {listing['status']}")
            print(f"   Seller: {listing['user_id']}")
        
        # Check time negotiation
        cursor.execute("SELECT * FROM listing_meeting_time WHERE listing_id = %s", (LISTING_ID,))
        time_neg = cursor.fetchone()
        if time_neg:
            print(f"\n⏰ Time Negotiation:")
            print(f"   Proposed by: {time_neg['proposed_by']}")
            print(f"   Meeting time: {time_neg['meeting_time']}")
            print(f"   Accepted at: {time_neg['accepted_at']}")
            print(f"   Rejected at: {time_neg['rejected_at']}")
        else:
            print(f"\n⏰ Time Negotiation: NONE")
        
        # Check location negotiation
        cursor.execute("SELECT * FROM listing_meeting_location WHERE listing_id = %s", (LISTING_ID,))
        loc_neg = cursor.fetchone()
        if loc_neg:
            print(f"\n📍 Location Negotiation:")
            print(f"   Proposed by: {loc_neg['proposed_by']}")
            print(f"   Location: {loc_neg['meeting_location_name']}")
            print(f"   Coordinates: ({loc_neg['meeting_location_lat']}, {loc_neg['meeting_location_lng']})")
            print(f"   Accepted at: {loc_neg['accepted_at']}")
            print(f"   Rejected at: {loc_neg['rejected_at']}")
        else:
            print(f"\n📍 Location Negotiation: NONE")
        
        # Check payments
        cursor.execute("SELECT * FROM listing_payments WHERE listing_id = %s", (LISTING_ID,))
        payment = cursor.fetchone()
        if payment:
            print(f"\n💳 Payments:")
            print(f"   Buyer paid at: {payment['buyer_paid_at']}")
            print(f"   Seller paid at: {payment['seller_paid_at']}")
        else:
            print(f"\n💳 Payments: NONE")
        
        print("\n" + "="*70)
    
    except Exception as e:
        print(f"❌ Error displaying status: {e}")
    finally:
        cursor.close()
