-- Add location coordinates to meeting_proposals table
ALTER TABLE meeting_proposals 
ADD COLUMN proposed_latitude DECIMAL(10, 8) NULL AFTER proposed_location,
ADD COLUMN proposed_longitude DECIMAL(11, 8) NULL AFTER proposed_latitude;

-- Create index for location-based queries
CREATE INDEX idx_proposed_location ON meeting_proposals(proposed_latitude, proposed_longitude);
