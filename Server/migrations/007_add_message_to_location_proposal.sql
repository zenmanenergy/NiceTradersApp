-- Migration: Add message column to location proposals
-- Date: 2025-12-24
-- Description: Adds message/notes field to listing_meeting_location table to store location proposal notes

ALTER TABLE listing_meeting_location 
ADD COLUMN message TEXT DEFAULT NULL AFTER meeting_location_name;
