-- Add distinct action types for time and location proposals
ALTER TABLE negotiation_history 
MODIFY COLUMN action ENUM(
  'initial_proposal',
  'time_proposal',
  'location_proposal',
  'counter_proposal',
  'accepted',
  'accepted_time',
  'accepted_location',
  'rejected',
  'cancelled',
  'buyer_paid',
  'seller_paid',
  'expired'
);
