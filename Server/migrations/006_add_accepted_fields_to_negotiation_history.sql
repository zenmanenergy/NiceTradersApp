-- Add accepted_time and accepted_location fields to negotiation_history
-- These store the final agreed-upon time and location

ALTER TABLE negotiation_history
ADD COLUMN accepted_time DATETIME NULL AFTER proposed_time,
ADD COLUMN accepted_location VARCHAR(255) NULL AFTER proposed_location,
ADD COLUMN accepted_latitude DECIMAL(10, 8) NULL AFTER accepted_location,
ADD COLUMN accepted_longitude DECIMAL(11, 8) NULL AFTER accepted_latitude;
