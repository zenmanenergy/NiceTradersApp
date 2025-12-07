-- Add location fields to negotiation_history table
-- This consolidates time and location negotiation in one place

ALTER TABLE negotiation_history
ADD COLUMN proposed_location VARCHAR(255) NULL AFTER proposed_time,
ADD COLUMN proposed_latitude DECIMAL(10, 8) NULL AFTER proposed_location,
ADD COLUMN proposed_longitude DECIMAL(11, 8) NULL AFTER proposed_latitude,
ADD INDEX idx_location (proposed_latitude, proposed_longitude);
