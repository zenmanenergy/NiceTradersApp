-- Add listing_id to negotiation_history table
-- Allows linking proposals to specific listings for meeting location proposals

ALTER TABLE negotiation_history
ADD COLUMN listing_id CHAR(39) NULL AFTER negotiation_id,
ADD INDEX idx_listing_id (listing_id);
