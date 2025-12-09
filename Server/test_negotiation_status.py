"""
Unit tests for NegotiationStatus.py status calculation functions

Tests all timestamp combinations and workflow sequences to ensure
status calculation is correct and deterministic.
"""

import unittest
from datetime import datetime
from _Lib.NegotiationStatus import (
    get_time_negotiation_status,
    get_location_negotiation_status,
    get_payment_status,
    get_negotiation_overall_status,
    action_required_for_user
)


class TestGetTimeNegotiationStatus(unittest.TestCase):
    """Test get_time_negotiation_status() - All timestamp combinations"""
    
    def test_none_when_no_time_negotiation(self):
        """Returns None when time_negotiation is None"""
        result = get_time_negotiation_status(None)
        self.assertIsNone(result)
    
    def test_proposed_when_both_timestamps_null(self):
        """Returns 'proposed' when both accepted_at and rejected_at are NULL"""
        time_neg = {
            'accepted_at': None,
            'rejected_at': None
        }
        result = get_time_negotiation_status(time_neg)
        self.assertEqual(result, 'proposed')
    
    def test_accepted_when_accepted_at_set(self):
        """Returns 'accepted' when accepted_at is set and rejected_at is NULL"""
        time_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None
        }
        result = get_time_negotiation_status(time_neg)
        self.assertEqual(result, 'accepted')
    
    def test_rejected_when_rejected_at_set(self):
        """Returns 'rejected' when rejected_at is set (regardless of accepted_at)"""
        time_neg = {
            'accepted_at': None,
            'rejected_at': datetime.now()
        }
        result = get_time_negotiation_status(time_neg)
        self.assertEqual(result, 'rejected')
    
    def test_rejected_takes_priority_over_accepted(self):
        """Returns 'rejected' when both timestamps are set (rejected takes priority)"""
        time_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': datetime.now()
        }
        result = get_time_negotiation_status(time_neg)
        self.assertEqual(result, 'rejected')


class TestGetLocationNegotiationStatus(unittest.TestCase):
    """Test get_location_negotiation_status() - All timestamp combinations"""
    
    def test_none_when_no_location_negotiation(self):
        """Returns None when location_negotiation is None"""
        result = get_location_negotiation_status(None)
        self.assertIsNone(result)
    
    def test_proposed_when_both_timestamps_null(self):
        """Returns 'proposed' when both accepted_at and rejected_at are NULL"""
        location_neg = {
            'accepted_at': None,
            'rejected_at': None
        }
        result = get_location_negotiation_status(location_neg)
        self.assertEqual(result, 'proposed')
    
    def test_accepted_when_accepted_at_set(self):
        """Returns 'accepted' when accepted_at is set and rejected_at is NULL"""
        location_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None
        }
        result = get_location_negotiation_status(location_neg)
        self.assertEqual(result, 'accepted')
    
    def test_rejected_when_rejected_at_set(self):
        """Returns 'rejected' when rejected_at is set"""
        location_neg = {
            'accepted_at': None,
            'rejected_at': datetime.now()
        }
        result = get_location_negotiation_status(location_neg)
        self.assertEqual(result, 'rejected')
    
    def test_rejected_takes_priority_over_accepted(self):
        """Returns 'rejected' when both timestamps are set"""
        location_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': datetime.now()
        }
        result = get_location_negotiation_status(location_neg)
        self.assertEqual(result, 'rejected')


class TestGetPaymentStatus(unittest.TestCase):
    """Test get_payment_status() - All payment combinations"""
    
    def test_unpaid_when_no_payment(self):
        """Returns 'unpaid' when payment is None"""
        result = get_payment_status(None)
        self.assertEqual(result, 'unpaid')
    
    def test_unpaid_when_both_null(self):
        """Returns 'unpaid' when both buyer_paid_at and seller_paid_at are NULL"""
        payment = {
            'buyer_paid_at': None,
            'seller_paid_at': None
        }
        result = get_payment_status(payment)
        self.assertEqual(result, 'unpaid')
    
    def test_paid_partial_when_only_buyer_paid(self):
        """Returns 'paid_partial' when only buyer_paid_at is set"""
        payment = {
            'buyer_paid_at': datetime.now(),
            'seller_paid_at': None
        }
        result = get_payment_status(payment)
        self.assertEqual(result, 'paid_partial')
    
    def test_paid_partial_when_only_seller_paid(self):
        """Returns 'paid_partial' when only seller_paid_at is set"""
        payment = {
            'buyer_paid_at': None,
            'seller_paid_at': datetime.now()
        }
        result = get_payment_status(payment)
        self.assertEqual(result, 'paid_partial')
    
    def test_paid_complete_when_both_paid(self):
        """Returns 'paid_complete' when both buyer_paid_at and seller_paid_at are set"""
        payment = {
            'buyer_paid_at': datetime.now(),
            'seller_paid_at': datetime.now()
        }
        result = get_payment_status(payment)
        self.assertEqual(result, 'paid_complete')


class TestGetNegotiationOverallStatus(unittest.TestCase):
    """Test get_negotiation_overall_status() - Complete workflow sequences"""
    
    def test_rejected_when_time_negotiation_rejected(self):
        """Returns 'rejected' when time negotiation is rejected"""
        time_neg = {
            'accepted_at': None,
            'rejected_at': datetime.now()
        }
        location_neg = None
        payment = None
        
        result = get_negotiation_overall_status(time_neg, location_neg, payment)
        self.assertEqual(result, 'rejected')
    
    def test_negotiating_when_time_not_accepted(self):
        """Returns 'negotiating' when time negotiation is proposed (not yet accepted)"""
        time_neg = {
            'accepted_at': None,
            'rejected_at': None
        }
        location_neg = None
        payment = None
        
        result = get_negotiation_overall_status(time_neg, location_neg, payment)
        self.assertEqual(result, 'negotiating')
    
    def test_negotiating_when_time_accepted_but_location_proposed(self):
        """Returns 'negotiating' when time accepted but location still in proposed state"""
        time_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None
        }
        location_neg = {
            'accepted_at': None,
            'rejected_at': None
        }
        payment = None
        
        result = get_negotiation_overall_status(time_neg, location_neg, payment)
        self.assertEqual(result, 'negotiating')
    
    def test_rejected_when_location_negotiation_rejected(self):
        """Returns 'rejected' when location negotiation is rejected (time was accepted)"""
        time_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None
        }
        location_neg = {
            'accepted_at': None,
            'rejected_at': datetime.now()
        }
        payment = None
        
        result = get_negotiation_overall_status(time_neg, location_neg, payment)
        self.assertEqual(result, 'rejected')
    
    def test_agreed_when_time_and_location_accepted_no_payment(self):
        """Returns 'agreed' when time and location accepted but no payment yet"""
        time_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None
        }
        location_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None
        }
        payment = {
            'buyer_paid_at': None,
            'seller_paid_at': None
        }
        
        result = get_negotiation_overall_status(time_neg, location_neg, payment)
        self.assertEqual(result, 'agreed')
    
    def test_paid_partial_when_time_location_accepted_one_party_paid(self):
        """Returns 'paid_partial' when time and location accepted, one party paid"""
        time_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None
        }
        location_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None
        }
        payment = {
            'buyer_paid_at': datetime.now(),
            'seller_paid_at': None
        }
        
        result = get_negotiation_overall_status(time_neg, location_neg, payment)
        self.assertEqual(result, 'paid_partial')
    
    def test_paid_complete_when_both_time_location_payment_done(self):
        """Returns 'paid_complete' when time, location accepted and both parties paid"""
        time_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None
        }
        location_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None
        }
        payment = {
            'buyer_paid_at': datetime.now(),
            'seller_paid_at': datetime.now()
        }
        
        result = get_negotiation_overall_status(time_neg, location_neg, payment)
        self.assertEqual(result, 'paid_complete')
    
    def test_negotiating_when_time_accepted_location_none(self):
        """Returns 'negotiating' when time accepted but location_negotiation is None"""
        time_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None
        }
        location_neg = None
        payment = None
        
        result = get_negotiation_overall_status(time_neg, location_neg, payment)
        self.assertEqual(result, 'negotiating')
    
    def test_full_workflow_sequence(self):
        """Tests complete workflow: propose → counter → accept time → propose location → accept location → pay"""
        now = datetime.now()
        
        # Step 1: Buyer proposes time
        time_neg = {'accepted_at': None, 'rejected_at': None}
        result = get_negotiation_overall_status(time_neg, None, None)
        self.assertEqual(result, 'negotiating')
        
        # Step 2: Seller accepts time
        time_neg = {'accepted_at': now, 'rejected_at': None}
        result = get_negotiation_overall_status(time_neg, None, None)
        self.assertEqual(result, 'negotiating')
        
        # Step 3: Buyer proposes location
        location_neg = {'accepted_at': None, 'rejected_at': None}
        result = get_negotiation_overall_status(time_neg, location_neg, None)
        self.assertEqual(result, 'negotiating')
        
        # Step 4: Seller accepts location
        location_neg = {'accepted_at': now, 'rejected_at': None}
        result = get_negotiation_overall_status(time_neg, location_neg, None)
        self.assertEqual(result, 'agreed')
        
        # Step 5: Buyer pays
        payment = {'buyer_paid_at': now, 'seller_paid_at': None}
        result = get_negotiation_overall_status(time_neg, location_neg, payment)
        self.assertEqual(result, 'paid_partial')
        
        # Step 6: Seller pays
        payment = {'buyer_paid_at': now, 'seller_paid_at': now}
        result = get_negotiation_overall_status(time_neg, location_neg, payment)
        self.assertEqual(result, 'paid_complete')


class TestActionRequiredForUser(unittest.TestCase):
    """Test action_required_for_user() - All user/action combinations"""
    
    def test_false_when_no_time_negotiation(self):
        """Returns False when time_negotiation is None"""
        result = action_required_for_user('USER123', None)
        self.assertFalse(result)
    
    def test_false_when_time_accepted(self):
        """Returns False when time negotiation is accepted (no action needed)"""
        time_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None,
            'proposed_by': 'USER456'
        }
        result = action_required_for_user('USER123', time_neg)
        self.assertFalse(result)
    
    def test_false_when_time_rejected(self):
        """Returns False when time negotiation is rejected (no action possible)"""
        time_neg = {
            'accepted_at': None,
            'rejected_at': datetime.now(),
            'proposed_by': 'USER456'
        }
        result = action_required_for_user('USER123', time_neg)
        self.assertFalse(result)
    
    def test_false_when_user_made_proposal(self):
        """Returns False when user is the one who made the proposal (waiting for response)"""
        time_neg = {
            'accepted_at': None,
            'rejected_at': None,
            'proposed_by': 'USER123'
        }
        result = action_required_for_user('USER123', time_neg)
        self.assertFalse(result)
    
    def test_true_when_other_user_proposed_and_pending(self):
        """Returns True when another user made proposal and negotiation is pending"""
        time_neg = {
            'accepted_at': None,
            'rejected_at': None,
            'proposed_by': 'USER456'
        }
        result = action_required_for_user('USER123', time_neg)
        self.assertTrue(result)
    
    def test_action_required_workflow(self):
        """Tests action flow: buyer proposes → seller can act → seller accepts → no more action"""
        buyer_id = 'BUYER123'
        seller_id = 'SELLER456'
        
        # Step 1: Buyer proposes - buyer waits for seller
        time_neg = {
            'accepted_at': None,
            'rejected_at': None,
            'proposed_by': buyer_id
        }
        self.assertFalse(action_required_for_user(buyer_id, time_neg))
        self.assertTrue(action_required_for_user(seller_id, time_neg))
        
        # Step 2: Seller counters - seller waits for buyer
        time_neg = {
            'accepted_at': None,
            'rejected_at': None,
            'proposed_by': seller_id
        }
        self.assertTrue(action_required_for_user(buyer_id, time_neg))
        self.assertFalse(action_required_for_user(seller_id, time_neg))
        
        # Step 3: Buyer accepts - no more action required
        time_neg = {
            'accepted_at': datetime.now(),
            'rejected_at': None,
            'proposed_by': seller_id
        }
        self.assertFalse(action_required_for_user(buyer_id, time_neg))
        self.assertFalse(action_required_for_user(seller_id, time_neg))


if __name__ == '__main__':
    unittest.main()
