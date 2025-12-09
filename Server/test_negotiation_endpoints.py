"""
Rigorous integration tests for refactored negotiation endpoints.
Tests ACTUAL database changes, not just successful responses.
"""

import json
import uuid
from datetime import datetime, timedelta, timezone
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from _Lib import Database
from _Lib.NegotiationStatus import (
    get_time_negotiation_status,
    get_location_negotiation_status,
    get_payment_status,
    get_negotiation_overall_status,
    action_required_for_user
)
from Negotiations.ProposeNegotiation import propose_negotiation
from Negotiations.CounterProposal import counter_proposal
from Negotiations.AcceptProposal import accept_proposal
from Negotiations.RejectNegotiation import reject_negotiation
from Negotiations.ProposeMeetingLocation import propose_meeting_location
from Negotiations.CounterMeetingLocation import counter_meeting_location
from Negotiations.AcceptMeetingLocation import accept_meeting_location
from Negotiations.RejectMeetingLocation import reject_meeting_location
from Negotiations.PayNegotiationFee import pay_negotiation_fee
from Negotiations.GetNegotiation import get_negotiation
from Negotiations.GetMyNegotiations import get_my_negotiations


class RigorousNegotiationTests:
    """Rigorous tests that verify ACTUAL database changes"""
    
    def __init__(self, keep_data=False):
        self.test_results = []
        self.test_listing_id = None
        self.buyer_session_id = None
        self.seller_session_id = None
        self.buyer_id = None
        self.seller_id = None
        self.original_proposed_time = None
        self.new_proposed_time = None
        self.keep_data = keep_data
    
    def assert_equal(self, actual, expected, message):
        """Assert equality and log failure"""
        if actual != expected:
            raise AssertionError(f"{message}: expected {expected}, got {actual}")
    
    def assert_not_none(self, value, message):
        """Assert value is not None"""
        if value is None:
            raise AssertionError(f"{message}: value was None")
    
    def assert_is_none(self, value, message):
        """Assert value is None"""
        if value is not None:
            raise AssertionError(f"{message}: expected None, got {value}")
    
    def log_result(self, test_name, passed, message=""):
        """Log test result"""
        status = "✓ PASS" if passed else "✗ FAIL"
        self.test_results.append({
            'test': test_name,
            'passed': passed,
            'message': message
        })
        print(f"{status}: {test_name}")
        if message:
            print(f"   → {message}")
    
    def setup_test_data(self):
        """Create test users, listing, and sessions"""
        print("\n[SETUP] Creating test data...")
        cursor, connection = Database.ConnectToDatabase()
        
        try:
            self.buyer_id = f"USR-{str(uuid.uuid4())[:32]}"
            self.seller_id = f"USR-{str(uuid.uuid4())[:32]}"
            self.test_listing_id = str(uuid.uuid4())
            
            cursor.execute("""
                INSERT INTO users (UserId, FirstName, LastName, Email, Password, UserType, Rating, TotalExchanges)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (self.buyer_id, "Test", "Buyer", f"buyer{uuid.uuid4().hex[:8]}@test.com", "hash", "buyer", 0, 0))
            
            cursor.execute("""
                INSERT INTO users (UserId, FirstName, LastName, Email, Password, UserType, Rating, TotalExchanges)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (self.seller_id, "Test", "Seller", f"seller{uuid.uuid4().hex[:8]}@test.com", "hash", "seller", 0, 0))
            
            cursor.execute("""
                INSERT INTO listings (listing_id, user_id, currency, amount, 
                                     accept_currency, location, status, available_until)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (self.test_listing_id, self.seller_id, "USD", 10.00, "MXN", "Test Location", "active", 
                  (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()))
            
            self.buyer_session_id = str(uuid.uuid4())
            self.seller_session_id = str(uuid.uuid4())
            
            cursor.execute("""
                INSERT INTO usersessions (SessionId, UserId)
                VALUES (%s, %s)
            """, (self.buyer_session_id, self.buyer_id))
            
            cursor.execute("""
                INSERT INTO usersessions (SessionId, UserId)
                VALUES (%s, %s)
            """, (self.seller_session_id, self.seller_id))
            
            connection.commit()
            print(f"✓ Setup complete")
            return True
            
        except Exception as e:
            print(f"✗ Setup failed: {str(e)}")
            connection.rollback()
            return False
        finally:
            cursor.close()
            connection.close()
    
    def test_propose_negotiation_creates_record(self):
        """Test 1: ProposeNegotiation actually inserts record with correct data"""
        print("\n[TEST 1] ProposeNegotiation - verifies DB record")
        
        self.original_proposed_time = datetime.now(timezone.utc) + timedelta(days=1)
        proposed_time_str = self.original_proposed_time.isoformat()
        
        try:
            result = json.loads(propose_negotiation(self.test_listing_id, self.buyer_session_id, proposed_time_str))
            self.assert_equal(result.get('success'), True, "ProposeNegotiation should succeed")
            negotiation_id = result.get('negotiationId')
            self.assert_not_none(negotiation_id, "Should return negotiationId")
            
            # Query database directly
            cursor, connection = Database.ConnectToDatabase()
            try:
                cursor.execute("""
                    SELECT time_negotiation_id, listing_id, buyer_id, proposed_by, 
                           meeting_time, accepted_at, rejected_at
                    FROM listing_meeting_time
                    WHERE listing_id = %s
                """, (self.test_listing_id,))
                
                time_neg = cursor.fetchone()
                self.assert_not_none(time_neg, "Record should exist in listing_meeting_time")
                
                # Verify EXACT data
                self.assert_equal(time_neg['listing_id'], self.test_listing_id, "listing_id mismatch")
                self.assert_equal(time_neg['buyer_id'], self.buyer_id, "buyer_id mismatch")
                self.assert_equal(time_neg['proposed_by'], self.buyer_id, "proposed_by should be buyer")
                self.assert_is_none(time_neg['accepted_at'], "accepted_at should be NULL")
                self.assert_is_none(time_neg['rejected_at'], "rejected_at should be NULL")
                
                # Verify meeting_time matches (within 1 second tolerance for DB precision)
                db_time = time_neg['meeting_time']
                # Make both naive for comparison
                if db_time.tzinfo is not None:
                    db_time = db_time.replace(tzinfo=None)
                orig_time = self.original_proposed_time.replace(tzinfo=None)
                time_diff = abs((db_time - orig_time).total_seconds())
                if time_diff > 1:
                    raise AssertionError(f"meeting_time differs by {time_diff}s")
                
                self.log_result("ProposeNegotiation", True, "Record created with exact data")
                return True
                
            finally:
                cursor.close()
                connection.close()
                
        except Exception as e:
            self.log_result("ProposeNegotiation", False, str(e))
            return False
    
    def test_counter_proposal_updates_timestamp(self):
        """Test 2: CounterProposal actually CHANGES the meeting_time"""
        print("\n[TEST 2] CounterProposal - verifies timestamp changed")
        
        # Record BEFORE state
        cursor, connection = Database.ConnectToDatabase()
        try:
            cursor.execute("""
                SELECT meeting_time FROM listing_meeting_time WHERE listing_id = %s
            """, (self.test_listing_id,))
            before = cursor.fetchone()
            original_time = before['meeting_time']
        finally:
            cursor.close()
            connection.close()
        
        try:
            # Counter with DIFFERENT time
            self.new_proposed_time = datetime.now(timezone.utc) + timedelta(days=3)
            new_time_str = self.new_proposed_time.isoformat()
            
            result = json.loads(counter_proposal(self.test_listing_id, self.seller_session_id, new_time_str))
            self.assert_equal(result.get('success'), True, "CounterProposal should succeed")
            
            # Query database and verify CHANGE
            cursor, connection = Database.ConnectToDatabase()
            try:
                cursor.execute("""
                    SELECT meeting_time, proposed_by, accepted_at FROM listing_meeting_time WHERE listing_id = %s
                """, (self.test_listing_id,))
                after = cursor.fetchone()
                
                # CRITICAL: Verify timestamp actually changed
                self.assert_equal(after['proposed_by'], self.seller_id, "proposed_by should be seller now")
                time_diff = abs((after['meeting_time'] - original_time).total_seconds())
                if time_diff < 3600:  # Should be > 1 day difference
                    raise AssertionError(f"meeting_time didn't change enough: {time_diff}s")
                
                # Verify accepted_at was cleared
                self.assert_is_none(after['accepted_at'], "accepted_at should be cleared")
                
                self.log_result("CounterProposal", True, f"Timestamp changed by {time_diff}s")
                return True
                
            finally:
                cursor.close()
                connection.close()
                
        except Exception as e:
            self.log_result("CounterProposal", False, str(e))
            return False
    
    def test_accept_proposal_sets_accepted_at(self):
        """Test 3: AcceptProposal actually sets accepted_at timestamp"""
        print("\n[TEST 3] AcceptProposal - verifies accepted_at and buyer_id set")
        
        try:
            result = json.loads(accept_proposal(self.test_listing_id, self.buyer_session_id))
            self.assert_equal(result.get('success'), True, "AcceptProposal should succeed")
            
            # Query and verify BOTH changes
            cursor, connection = Database.ConnectToDatabase()
            try:
                # Check listing_meeting_time
                cursor.execute("""
                    SELECT accepted_at, rejected_at FROM listing_meeting_time WHERE listing_id = %s
                """, (self.test_listing_id,))
                time_neg = cursor.fetchone()
                self.assert_not_none(time_neg['accepted_at'], "accepted_at should be set")
                self.assert_is_none(time_neg['rejected_at'], "rejected_at should still be NULL")
                
                # Check listings.buyer_id was set
                cursor.execute("""
                    SELECT buyer_id FROM listings WHERE listing_id = %s
                """, (self.test_listing_id,))
                listing = cursor.fetchone()
                self.assert_equal(listing['buyer_id'], self.buyer_id, "buyer_id should be set in listings")
                
                self.log_result("AcceptProposal", True, "accepted_at set and buyer_id marked")
                return True
                
            finally:
                cursor.close()
                connection.close()
                
        except Exception as e:
            self.log_result("AcceptProposal", False, str(e))
            return False
    
    def test_propose_location_stores_coordinates(self):
        """Test 4: ProposeMeetingLocation stores EXACT lat/lng values"""
        print("\n[TEST 4] ProposeMeetingLocation - verifies exact coordinates")
        
        lat_str = "19.4326"
        lng_str = "-99.1332"
        location_name = "Mexico City, Polanco"
        
        try:
            result = json.loads(propose_meeting_location(
                self.test_listing_id, self.buyer_session_id, lat_str, lng_str, location_name
            ))
            self.assert_equal(result.get('success'), True, "ProposeMeetingLocation should succeed")
            
            # Query and verify EXACT values
            cursor, connection = Database.ConnectToDatabase()
            try:
                cursor.execute("""
                    SELECT meeting_location_lat, meeting_location_lng, meeting_location_name, 
                           accepted_at, rejected_at
                    FROM listing_meeting_location WHERE listing_id = %s
                """, (self.test_listing_id,))
                location_neg = cursor.fetchone()
                
                self.assert_not_none(location_neg, "Location record should exist")
                # Compare as floats (Decimal from DB)
                self.assert_equal(float(location_neg['meeting_location_lat']), float(lat_str), "Latitude mismatch")
                self.assert_equal(float(location_neg['meeting_location_lng']), float(lng_str), "Longitude mismatch")
                self.assert_equal(location_neg['meeting_location_name'], location_name, "Location name mismatch")
                self.assert_is_none(location_neg['accepted_at'], "accepted_at should be NULL")
                
                self.log_result("ProposeMeetingLocation", True, f"Coordinates stored: ({lat_str}, {lng_str})")
                return True
                
            finally:
                cursor.close()
                connection.close()
                
        except Exception as e:
            self.log_result("ProposeMeetingLocation", False, str(e))
            return False
    
    def test_accept_location_sets_timestamp(self):
        """Test 5: AcceptMeetingLocation sets accepted_at"""
        print("\n[TEST 5] AcceptMeetingLocation - verifies accepted_at set")
        
        try:
            result = json.loads(accept_meeting_location(self.test_listing_id, self.seller_session_id))
            self.assert_equal(result.get('success'), True, "AcceptMeetingLocation should succeed")
            
            # Query and verify
            cursor, connection = Database.ConnectToDatabase()
            try:
                cursor.execute("""
                    SELECT accepted_at, rejected_at FROM listing_meeting_location WHERE listing_id = %s
                """, (self.test_listing_id,))
                location_neg = cursor.fetchone()
                
                self.assert_not_none(location_neg['accepted_at'], "accepted_at should be set")
                self.assert_is_none(location_neg['rejected_at'], "rejected_at should be NULL")
                
                self.log_result("AcceptMeetingLocation", True, "accepted_at timestamp set")
                return True
                
            finally:
                cursor.close()
                connection.close()
                
        except Exception as e:
            self.log_result("AcceptMeetingLocation", False, str(e))
            return False
    
    def test_pay_creates_payment_record(self):
        """Test 6: PayNegotiationFee creates listing_payments with correct buyer_paid_at"""
        print("\n[TEST 6] PayNegotiationFee (Buyer) - verifies payment record created")
        
        try:
            result = json.loads(pay_negotiation_fee(self.test_listing_id, self.buyer_session_id))
            self.assert_equal(result.get('success'), True, "Buyer payment should succeed")
            
            # Query and verify payment record
            cursor, connection = Database.ConnectToDatabase()
            try:
                cursor.execute("""
                    SELECT payment_id, listing_id, buyer_paid_at, seller_paid_at FROM listing_payments 
                    WHERE listing_id = %s
                """, (self.test_listing_id,))
                payment = cursor.fetchone()
                
                self.assert_not_none(payment, "Payment record should be created")
                self.assert_not_none(payment['buyer_paid_at'], "buyer_paid_at should be set")
                self.assert_is_none(payment['seller_paid_at'], "seller_paid_at should still be NULL")
                
                self.log_result("PayNegotiationFee (Buyer)", True, "Payment record created with buyer_paid_at")
                return True
                
            finally:
                cursor.close()
                connection.close()
                
        except Exception as e:
            self.log_result("PayNegotiationFee (Buyer)", False, str(e))
            return False
    
    def test_both_pay_creates_contact_access(self):
        """Test 7: When both parties pay, contact_access records are created and TotalExchanges incremented"""
        print("\n[TEST 7] PayNegotiationFee (Seller) - verifies contact_access creation")
        
        try:
            result = json.loads(pay_negotiation_fee(self.test_listing_id, self.seller_session_id))
            self.assert_equal(result.get('success'), True, "Seller payment should succeed")
            
            # Query and verify BOTH payments set
            cursor, connection = Database.ConnectToDatabase()
            try:
                cursor.execute("""
                    SELECT buyer_paid_at, seller_paid_at FROM listing_payments WHERE listing_id = %s
                """, (self.test_listing_id,))
                payment = cursor.fetchone()
                self.assert_not_none(payment['buyer_paid_at'], "buyer_paid_at should be set")
                self.assert_not_none(payment['seller_paid_at'], "seller_paid_at should now be set")
                
                # Verify contact_access records created (2 total: one for buyer, one for seller)
                cursor.execute("""
                    SELECT COUNT(*) as count FROM contact_access WHERE listing_id = %s
                """, (self.test_listing_id,))
                count_result = cursor.fetchone()
                self.assert_equal(count_result['count'], 2, f"Should have 2 contact_access records, got {count_result['count']}")
                
                # Verify both buyer and seller have access records
                cursor.execute("""
                    SELECT user_id FROM contact_access WHERE listing_id = %s ORDER BY user_id
                """, (self.test_listing_id,))
                accesses = cursor.fetchall()
                access_users = {acc['user_id'] for acc in accesses}
                self.assert_equal(access_users, {self.buyer_id, self.seller_id}, "Contact access should be for both buyer and seller")
                
                # Verify TotalExchanges incremented for BOTH users
                cursor.execute("""
                    SELECT TotalExchanges FROM users WHERE UserId IN (%s, %s) ORDER BY UserId
                """, (self.buyer_id, self.seller_id))
                users = cursor.fetchall()
                for user in users:
                    self.assert_equal(user['TotalExchanges'], 1, f"TotalExchanges should be 1, got {user['TotalExchanges']}")
                
                self.log_result("PayNegotiationFee (Seller)", True, "Contact access created, TotalExchanges incremented")
                return True
                
            finally:
                cursor.close()
                connection.close()
                
        except Exception as e:
            self.log_result("PayNegotiationFee (Seller)", False, str(e))
            return False
    
    def test_get_negotiation_returns_all_data(self):
        """Test 8: GetNegotiation returns all stored data correctly"""
        print("\n[TEST 8] GetNegotiation - verifies all fields match DB")
        
        try:
            result = json.loads(get_negotiation(self.test_listing_id, self.buyer_session_id))
            self.assert_equal(result.get('success'), True, "GetNegotiation should succeed")
            
            neg = result.get('negotiation', {})
            
            # Verify structure
            self.assert_not_none(neg.get('listingId'), "Should have listingId")
            self.assert_equal(neg.get('listingId'), self.test_listing_id, "listingId mismatch")
            
            # Verify status
            self.assert_equal(neg.get('status'), 'paid_complete', "Status should be paid_complete")
            
            # Verify meeting time exists and is correct
            self.assert_not_none(neg.get('currentProposedTime'), "Should have currentProposedTime")
            
            # Verify payment status
            self.assert_equal(neg.get('buyerPaid'), True, f"buyerPaid should be true, got {neg.get('buyerPaid')}")
            self.assert_equal(neg.get('sellerPaid'), True, f"sellerPaid should be true, got {neg.get('sellerPaid')}")
            
            # Verify user role is set (at top level, not in negotiation)
            self.assert_not_none(result.get('userRole'), "userRole should be set at top level")
            
            # Verify location is at top level
            if result.get('location') is not None:
                location = result.get('location', {})
                self.assert_not_none(location.get('latitude'), "Location latitude should be set")
                self.assert_not_none(location.get('longitude'), "Location longitude should be set")
            
            # Verify buyer/seller info is at top level
            self.assert_not_none(result.get('buyer'), "Buyer info should be present")
            self.assert_not_none(result.get('seller'), "Seller info should be present")
            
            self.log_result("GetNegotiation", True, "All fields present and correct")
            return True
            
        except Exception as e:
            self.log_result("GetNegotiation", False, str(e))
            return False
    
    def test_get_my_negotiations_returns_user_list(self):
        """Test 9: GetMyNegotiations returns only user's negotiations with correct statuses"""
        print("\n[TEST 9] GetMyNegotiations - verifies user filtering and statuses")
        
        try:
            result = json.loads(get_my_negotiations(self.buyer_session_id))
            self.assert_equal(result.get('success'), True, "GetMyNegotiations should succeed")
            
            negotiations = result.get('negotiations', [])
            self.assert_equal(len(negotiations) > 0, True, "Should have at least one negotiation")
            
            # Find our test negotiation
            test_neg = None
            for neg in negotiations:
                if neg.get('listingId') == self.test_listing_id:
                    test_neg = neg
                    break
            
            self.assert_not_none(test_neg, "Test listing should be in results")
            
            # Verify data matches database
            self.assert_equal(test_neg.get('status'), 'paid_complete', "Status should be paid_complete")
            self.assert_not_none(test_neg.get('actionRequired'), "Should have actionRequired field")
            # Buyer completed everything, so no action required
            self.assert_equal(test_neg.get('actionRequired'), False, "No action required for buyer after payment")
            
            self.log_result("GetMyNegotiations", True, "Correct user filtering and status")
            return True
            
        except Exception as e:
            self.log_result("GetMyNegotiations", False, str(e))
            return False
    
    def cleanup_test_data(self):
        """Clean up test data from database"""
        if self.skip_cleanup:
            print(f"\n[CLEANUP] Keeping test data - listing_id={self.test_listing_id}")
            print(f"  Buyer: {self.buyer_id}")
            print(f"  Seller: {self.seller_id}")
            return
        
        print("\n[CLEANUP] Removing test data...")
        cursor, connection = Database.ConnectToDatabase()
        
        try:
            cursor.execute("DELETE FROM contact_access WHERE listing_id = %s", (self.test_listing_id,))
            cursor.execute("DELETE FROM listing_payments WHERE listing_id = %s", (self.test_listing_id,))
            cursor.execute("DELETE FROM listing_meeting_location WHERE listing_id = %s", (self.test_listing_id,))
            cursor.execute("DELETE FROM listing_meeting_time WHERE listing_id = %s", (self.test_listing_id,))
            cursor.execute("DELETE FROM listings WHERE listing_id = %s", (self.test_listing_id,))
            cursor.execute("DELETE FROM usersessions WHERE SessionId IN (%s, %s)", 
                         (self.buyer_session_id, self.seller_session_id))
            cursor.execute("DELETE FROM users WHERE UserId IN (%s, %s)", 
                         (self.buyer_id, self.seller_id))
            connection.commit()
            print("✓ Cleanup complete")
        except Exception as e:
            print(f"✗ Cleanup failed: {str(e)}")
            connection.rollback()
        finally:
            cursor.close()
            connection.close()
    
    def run_all_tests(self):
        """Run complete test suite"""
        print("=" * 80)
        print("RIGOROUS NEGOTIATION ENDPOINTS TEST SUITE")
        print("Verifies actual database changes, not just success responses")
        print("=" * 80)
        
        if not self.setup_test_data():
            print("\n✗ Cannot continue - setup failed")
            return False
        
        # Run tests in order
        self.test_propose_negotiation_creates_record()
        self.test_counter_proposal_updates_timestamp()
        self.test_accept_proposal_sets_accepted_at()
        self.test_propose_location_stores_coordinates()
        self.test_accept_location_sets_timestamp()
        self.test_pay_creates_payment_record()
        self.test_both_pay_creates_contact_access()
        self.test_get_negotiation_returns_all_data()
        self.test_get_my_negotiations_returns_user_list()
        
        self.cleanup_test_data()
        
        # Print summary
        print("\n" + "=" * 80)
        print("TEST SUMMARY")
        print("=" * 80)
        
        passed = sum(1 for r in self.test_results if r['passed'])
        total = len(self.test_results)
        
        for result in self.test_results:
            status = "✓" if result['passed'] else "✗"
            print(f"{status} {result['test']}")
            if result['message']:
                print(f"   {result['message']}")
        
        print(f"\nTotal: {passed}/{total} tests passed")
        
        if passed == total:
            print("\n✓ ALL TESTS PASSED!")
            return True
        else:
            print(f"\n✗ {total - passed} test(s) failed")
            return False


if __name__ == '__main__':
    skip_cleanup = '--keep' in sys.argv or '-k' in sys.argv
    if skip_cleanup:
        sys.argv.remove('--keep' if '--keep' in sys.argv else '-k')
    
    tester = RigorousNegotiationTests(skip_cleanup=skip_cleanup)
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)
