-- Add preferred_language column to users table
ALTER TABLE users 
ADD COLUMN PreferredLanguage VARCHAR(10) DEFAULT 'en' AFTER Bio;

-- Add index for performance
CREATE INDEX idx_preferred_language ON users(PreferredLanguage);
