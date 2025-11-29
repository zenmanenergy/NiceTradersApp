-- Migration: Add willRoundToNearestDollar preference to listings table
-- Purpose: Track whether listing owners are willing to round to nearest whole dollar
-- Date: 2024

ALTER TABLE listings 
ADD COLUMN will_round_to_nearest_dollar BOOLEAN DEFAULT FALSE AFTER meeting_preference;

-- Add index for filtering listings by rounding preference
CREATE INDEX idx_will_round_to_nearest_dollar ON listings(will_round_to_nearest_dollar);
