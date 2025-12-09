"""
NegotiationStatus.py - Status calculation functions for negotiation workflow

Status is derived from timestamps, not stored. This ensures status is always
consistent with actual data state and cannot become desynchronized.
"""


def get_time_negotiation_status(time_negotiation):
    """
    Returns the current status of a time negotiation.
    
    Status logic:
    - None: No time_negotiation record exists yet (buyer hasn't proposed)
    - 'rejected': rejected_at timestamp is set (either party rejected the time proposal)
    - 'accepted': accepted_at timestamp is set AND rejected_at is NULL (time is locked in)
    - 'proposed': accepted_at is NULL AND rejected_at is NULL (awaiting response)
    
    Returns: 'rejected' | 'accepted' | 'proposed' | None
    """
    if time_negotiation is None:
        return None
    if time_negotiation['rejected_at'] is not None:
        return 'rejected'
    if time_negotiation['accepted_at'] is not None:
        return 'accepted'
    return 'proposed'


def get_location_negotiation_status(location_negotiation):
    """
    Returns the current status of a location negotiation.
    
    Status logic:
    - None: No location_negotiation record exists yet (time not accepted or location not proposed)
    - 'rejected': rejected_at timestamp is set (either party rejected the location proposal)
    - 'accepted': accepted_at timestamp is set AND rejected_at is NULL (location is locked in)
    - 'proposed': accepted_at is NULL AND rejected_at is NULL (awaiting response)
    
    Returns: 'rejected' | 'accepted' | 'proposed' | None
    """
    if location_negotiation is None:
        return None
    if location_negotiation['rejected_at'] is not None:
        return 'rejected'
    if location_negotiation['accepted_at'] is not None:
        return 'accepted'
    return 'proposed'


def get_payment_status(payment):
    """
    Returns the current payment status.
    
    Status logic:
    - 'unpaid': No payment record exists OR both buyer_paid_at and seller_paid_at are NULL
    - 'paid_partial': Either buyer_paid_at OR seller_paid_at is set, but not both
    - 'paid_complete': Both buyer_paid_at AND seller_paid_at are NOT NULL (both parties have paid)
    
    Returns: 'paid_complete' | 'paid_partial' | 'unpaid'
    """
    if payment is None:
        return 'unpaid'
    
    buyer_paid = payment['buyer_paid_at'] is not None
    seller_paid = payment['seller_paid_at'] is not None
    
    if buyer_paid and seller_paid:
        return 'paid_complete'
    elif buyer_paid or seller_paid:
        return 'paid_partial'
    else:
        return 'unpaid'


def get_negotiation_overall_status(time_neg, location_neg, payment):
    """
    Determines the overall negotiation workflow status by combining time, location, and payment states.
    
    Status logic (evaluated in order):
    1. If time_negotiation is 'rejected': Return 'rejected' (negotiation ended, no recovery)
    2. If time_negotiation is not 'accepted': Return 'negotiating' (waiting for time agreement)
    3. If location_negotiation is 'rejected': Return 'rejected' (location phase failed)
    4. If location_negotiation is not 'accepted': Return 'negotiating' (waiting for location agreement, time is done)
    5. If payment_status is 'paid_complete': Return 'paid_complete' (both parties paid, transaction complete)
    6. If payment_status is 'paid_partial': Return 'paid_partial' (one party paid, waiting for other)
    7. Otherwise: Return 'agreed' (time + location agreed, awaiting payment)
    
    Returns: 'negotiating' | 'agreed' | 'paid_partial' | 'paid_complete' | 'rejected'
    
    Workflow sequence:
    - 'negotiating' → 'negotiating' (counters) → 'agreed' (time + location accepted) → 'paid_partial' (one pays) → 'paid_complete' (both pay)
    - 'negotiating' → 'rejected' (if time or location rejected at any point)
    """
    time_status = get_time_negotiation_status(time_neg)
    
    # Time negotiation must be accepted to proceed
    if time_status == 'rejected':
        return 'rejected'
    if time_status != 'accepted':
        return 'negotiating'
    
    location_status = get_location_negotiation_status(location_neg)
    
    # Location negotiation must be accepted to proceed to payment
    if location_status == 'rejected':
        return 'rejected'
    if location_status != 'accepted':
        return 'negotiating'
    
    # Both time and location accepted - check payment status
    payment_status = get_payment_status(payment)
    if payment_status == 'paid_complete':
        return 'paid_complete'
    elif payment_status == 'paid_partial':
        return 'paid_partial'
    else:
        return 'agreed'


def action_required_for_user(user_id, time_neg):
    """
    Determines if a specific user needs to take action (respond to pending proposal).
    
    Returns True if:
    - time_negotiation exists
    - time_negotiation status is 'proposed' (not yet accepted or rejected)
    - user_id is NOT the proposed_by user (someone else made the proposal)
    
    This identifies when it's a user's turn to accept/counter/reject.
    
    Returns: bool
    """
    if time_neg is None:
        return False
    time_status = get_time_negotiation_status(time_neg)
    if time_status != 'proposed':
        return False
    return time_neg['proposed_by'] != user_id
