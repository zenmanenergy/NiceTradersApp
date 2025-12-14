#!/usr/bin/env python3
"""
Comprehensive server-side test for all 7 dashboard status situations.
Tests that the backend's calculate_negotiation_status() returns correct values.
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

import pymysql
import pymysql.cursors
from datetime import datetime, timedelta
from Dashboard.GetUserDashboard import calculate_negotiation_status

# Test data constants
LISTING_ID = '3e7cfcfe-1f30-4662-babe-884b60c9a53a'
SELLER_ID = 'USR53a3c642-4914-4de8-8217-03ee3da42224'
BUYER_ID = 'USR387e9549-3339-4ea1-b0d2-f6a66c25c390'

def connect_db():
    return pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders',
        cursorclass=pymysql.cursors.DictCursor
    )

def cleanup_test_data(db):
    cursor = db.cursor()
    try:
        cursor.execute("DELETE FROM listing_payments WHERE listing_id = %s", (LISTING_ID,))
        cursor.execute("DELETE FROM listing_meeting_location WHERE listing_id = %s", (LISTING_ID,))
        cursor.execute("DELETE FROM listing_meeting_time WHERE listing_id = %s", (LISTING_ID,))
        cursor.execute("DELETE FROM listings WHERE listing_id = %s", (LISTING_ID,))
        db.commit()
        print("✅ Cleaned up test data")
    except Exception as e:
        print(f"⚠️  Cleanup warning: {e}")
        db.rollback()
    finally:
        cursor.close()

def setup_listing(db):
    cursor = db.cursor()
    try:
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
        print(f"❌ Error: {e}")
        db.rollback()
        raise
    finally:
        cursor.close()

def create_time_proposal(db, proposed_by, meeting_time=None, accepted_at=None):
    """Create or update time proposal"""
    cursor = db.cursor()
    try:
        if meeting_time is None:
            meeting_time = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d 10:00:00')
        
        # Check if it exists
        cursor.execute("SELECT 1 FROM listing_meeting_time WHERE listing_id = %s", (LISTING_ID,))
        exists = cursor.fetchone()
        
        if exists:
            cursor.execute("""
                UPDATE listing_meeting_time 
                SET proposed_by = %s, meeting_time = %s, accepted_at = %s
                WHERE listing_id = %s
            """, (proposed_by, meeting_time, accepted_at, LISTING_ID))
        else:
            cursor.execute("""
                INSERT INTO listing_meeting_time (
                    time_negotiation_id, listing_id, buyer_id, proposed_by,
                    meeting_time, accepted_at, rejected_at
                )
                VALUES (UUID(), %s, %s, %s, %s, %s, NULL)
            """, (LISTING_ID, BUYER_ID, proposed_by, meeting_time, accepted_at))
        
        db.commit()
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        raise
    finally:
        cursor.close()

def create_location_proposal(db, proposed_by, location='San Francisco, CA', accepted_at=None):
    """Create or update location proposal"""
    cursor = db.cursor()
    try:
        cursor.execute("""
            INSERT INTO listing_meeting_location (
                location_negotiation_id, listing_id, buyer_id, proposed_by,
                meeting_location_lat, meeting_location_lng, meeting_location_name, accepted_at
            )
            VALUES (UUID(), %s, %s, %s, %s, %s, %s, %s)
        """, (LISTING_ID, BUYER_ID, proposed_by, 37.7749, -122.4194, location, accepted_at))
        db.commit()
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        raise
    finally:
        cursor.close()

def set_payments(db, buyer_paid=None, seller_paid=None):
    """Set payment statuses"""
    cursor = db.cursor()
    try:
        # Check if payment record exists
        cursor.execute("SELECT 1 FROM listing_payments WHERE listing_id = %s", (LISTING_ID,))
        exists = cursor.fetchone()
        
        if exists:
            cursor.execute("""
                UPDATE listing_payments 
                SET buyer_paid_at = %s, seller_paid_at = %s
                WHERE listing_id = %s
            """, (buyer_paid, seller_paid, LISTING_ID))
        else:
            cursor.execute("""
                INSERT INTO listing_payments (payment_id, listing_id, buyer_id, buyer_paid_at, seller_paid_at)
                VALUES (UUID(), %s, %s, %s, %s)
            """, (LISTING_ID, BUYER_ID, buyer_paid, seller_paid))
        
        db.commit()
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
        raise
    finally:
        cursor.close()

def get_exchange_data(db):
    """Get full exchange data for status calculation"""
    cursor = db.cursor()
    try:
        query = """
            SELECT l.listing_id, l.currency, l.amount, l.accept_currency, l.location, 
                   l.latitude, l.longitude, l.location_radius,
                   l.status, l.created_at, l.available_until, l.will_round_to_nearest_dollar,
                   lmt.buyer_id, l.user_id as seller_id,
                   lmt.proposed_by, lmt.meeting_time, lmt.accepted_at, lmt.rejected_at,
                   lp.buyer_paid_at, lp.seller_paid_at,
                   CASE WHEN lml.location_negotiation_id IS NOT NULL THEN 1 ELSE 0 END as has_location_proposal,
                   lml.proposed_by as location_proposed_by,
                   lml.accepted_at as location_accepted_at
            FROM listings l
            JOIN listing_meeting_time lmt ON l.listing_id = lmt.listing_id
            LEFT JOIN listing_payments lp ON l.listing_id = lp.listing_id
            LEFT JOIN listing_meeting_location lml ON l.listing_id = lml.listing_id
            WHERE l.listing_id = %s
        """
        cursor.execute(query, (LISTING_ID,))
        return cursor.fetchone()
    finally:
        cursor.close()

def test_situation(db, situation_num, setup_fn, expected_buyer_status, expected_seller_status):
    """Test a single situation"""
    print(f"\n{'='*70}")
    print(f"SITUATION {situation_num}")
    print(f"{'='*70}")
    
    try:
        # Setup
        cleanup_test_data(db)
        setup_listing(db)
        setup_fn(db)
        
        # Get exchange data
        exchange = get_exchange_data(db)
        
        # Calculate statuses
        buyer_status = calculate_negotiation_status(exchange, BUYER_ID)
        seller_status = calculate_negotiation_status(exchange, SELLER_ID)
        
        # Verify
        buyer_ok = buyer_status == expected_buyer_status
        seller_ok = seller_status == expected_seller_status
        
        print(f"\nBUYER Status:")
        print(f"  Expected: {expected_buyer_status}")
        print(f"  Got:      {buyer_status}")
        print(f"  Result:   {'✅ PASS' if buyer_ok else '❌ FAIL'}")
        
        print(f"\nSELLER Status:")
        print(f"  Expected: {expected_seller_status}")
        print(f"  Got:      {seller_status}")
        print(f"  Result:   {'✅ PASS' if seller_ok else '❌ FAIL'}")
        
        return buyer_ok and seller_ok
        
    except Exception as e:
        print(f"❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False

# Setup functions for each situation
def setup_sit1(db):
    """Situation 1: Buyer proposes time, seller not yet responded"""
    create_time_proposal(db, BUYER_ID)

def setup_sit2(db):
    """Situation 2: Seller accepts time proposal"""
    create_time_proposal(db, BUYER_ID, accepted_at=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

def setup_sit3(db):
    """Situation 3: Both paid, no location yet"""
    create_time_proposal(db, BUYER_ID, accepted_at=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    set_payments(db, 
                 buyer_paid=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                 seller_paid=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

def setup_sit4(db):
    """Situation 4: Both paid, buyer proposes location"""
    create_time_proposal(db, BUYER_ID, accepted_at=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    set_payments(db, 
                 buyer_paid=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                 seller_paid=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    create_location_proposal(db, BUYER_ID)

def setup_sit5(db):
    """Situation 5: Both paid, seller proposes location"""
    create_time_proposal(db, BUYER_ID, accepted_at=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    set_payments(db, 
                 buyer_paid=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                 seller_paid=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    create_location_proposal(db, SELLER_ID)

def setup_sit6(db):
    """Situation 6: Both location and time accepted, ready to meet"""
    create_time_proposal(db, BUYER_ID, accepted_at=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    set_payments(db, 
                 buyer_paid=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                 seller_paid=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    create_location_proposal(db, BUYER_ID, accepted_at=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

def setup_sit7(db):
    """Situation 7: Completed and rated"""
    create_time_proposal(db, BUYER_ID, accepted_at=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    set_payments(db, 
                 buyer_paid=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
                 seller_paid=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    create_location_proposal(db, BUYER_ID, accepted_at=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

if __name__ == '__main__':
    db = connect_db()
    
    try:
        results = []
        
        # Situation 1: Buyer proposes time
        results.append(test_situation(
            db, 1, setup_sit1,
            expected_buyer_status="⏳ Waiting for Acceptance",
            expected_seller_status="🎯 Action: Acceptance"
        ))
        
        # Situation 2: Time accepted
        results.append(test_situation(
            db, 2, setup_sit2,
            expected_buyer_status="🎯 Action: Payment",
            expected_seller_status="🎯 Action: Payment"
        ))
        
        # Situation 3: Both paid, no location
        results.append(test_situation(
            db, 3, setup_sit3,
            expected_buyer_status="🎯 Action: Propose Location",
            expected_seller_status="🎯 Action: Propose Location"
        ))
        
        # Situation 4: Buyer proposes location
        results.append(test_situation(
            db, 4, setup_sit4,
            expected_buyer_status="⏳ Waiting for Acceptance",
            expected_seller_status="🎯 Action: Acceptance"
        ))
        
        # Situation 5: Seller proposes location
        results.append(test_situation(
            db, 5, setup_sit5,
            expected_buyer_status="🎯 Action: Acceptance",
            expected_seller_status="⏳ Waiting for Acceptance"
        ))
        
        # Situation 6: Both accepted, ready to meet
        results.append(test_situation(
            db, 6, setup_sit6,
            expected_buyer_status="✅ Meeting confirmed",
            expected_seller_status="✅ Meeting confirmed"
        ))
        
        # Situation 7: Completed
        results.append(test_situation(
            db, 7, setup_sit7,
            expected_buyer_status="✅ Meeting confirmed",
            expected_seller_status="✅ Meeting confirmed"
        ))
        
        # Summary
        print(f"\n{'='*70}")
        print("TEST SUMMARY")
        print(f"{'='*70}")
        passed = sum(results)
        total = len(results)
        print(f"Passed: {passed}/{total}")
        
        if passed == total:
            print("✅ ALL TESTS PASSED")
        else:
            print(f"❌ {total - passed} TESTS FAILED")
        
    finally:
        db.close()
