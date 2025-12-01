-- Migration: Add geocoding cache columns
-- Purpose: Store reverse geocoding results to avoid repeated API calls
-- Created: 2025-11-30

-- Create a dedicated geocoding cache table for efficient lookups
CREATE TABLE IF NOT EXISTS geocoding_cache (
    cache_id CHAR(39) PRIMARY KEY,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    geocoded_location VARCHAR(255) NOT NULL COMMENT 'City, State or similar human-readable location',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    access_count INT DEFAULT 1 COMMENT 'Track how often this cache is used for optimization',
    INDEX idx_coordinates (latitude, longitude),
    INDEX idx_accessed_at (accessed_at),
    UNIQUE KEY unique_coordinates (latitude, longitude)
) COMMENT 'Centralized cache for reverse geocoding results to avoid repeated API calls';

-- Add cached reverse geocoding result to listings table
ALTER TABLE listings ADD COLUMN geocoded_location VARCHAR(255) COMMENT 'Cached result of reverse geocoding the coordinates';
ALTER TABLE listings ADD COLUMN geocoding_updated_at TIMESTAMP DEFAULT NULL COMMENT 'When the geocoding cache was last updated';

-- Create index for faster lookups on listings
CREATE INDEX idx_listing_geocoded ON listings(geocoded_location);
CREATE INDEX idx_listing_geocoding_updated ON listings(geocoding_updated_at);

-- Add cached reverse geocoding to meeting_proposals
ALTER TABLE meeting_proposals ADD COLUMN proposed_latitude DECIMAL(10,8) COMMENT 'Latitude of proposed meeting location';
ALTER TABLE meeting_proposals ADD COLUMN proposed_longitude DECIMAL(11,8) COMMENT 'Longitude of proposed meeting location';
ALTER TABLE meeting_proposals ADD COLUMN geocoded_proposed_location VARCHAR(255) COMMENT 'Cached result of reverse geocoding the proposed coordinates';
ALTER TABLE meeting_proposals ADD COLUMN geocoding_updated_at TIMESTAMP DEFAULT NULL COMMENT 'When the geocoding cache was last updated';

-- Create index for faster lookups on meeting_proposals
CREATE INDEX idx_proposal_geocoded ON meeting_proposals(geocoded_proposed_location);
CREATE INDEX idx_proposal_geocoding_updated ON meeting_proposals(geocoding_updated_at);
