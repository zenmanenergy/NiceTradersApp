-- Update negotiation_history action enum and migrate data
-- First expand enum to include new values
ALTER TABLE negotiation_history
MODIFY action ENUM('initial_proposal','counter_proposal','accepted','accepted_time','accepted_location','rejected','cancelled','buyer_paid','seller_paid','expired');

-- Update existing accepted records that have accepted_time populated to use accepted_time action
UPDATE negotiation_history
SET action = 'accepted_time'
WHERE action = 'accepted' AND accepted_time IS NOT NULL;

-- Update existing accepted records that have accepted_location populated (but no time) to use accepted_location action
UPDATE negotiation_history
SET action = 'accepted_location'
WHERE action = 'accepted' AND accepted_time IS NULL AND accepted_location IS NOT NULL;
