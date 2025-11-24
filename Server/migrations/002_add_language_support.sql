-- Migration: Add language preference support
-- This migration adds columns to support multi-language user preferences

-- Add language column to users table for quick access
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'en' AFTER UserType;

-- Add index for language filtering
CREATE INDEX IF NOT EXISTS idx_preferred_language ON users(preferred_language);

-- Migration notes:
-- - Users table now has preferred_language column
-- - User settings JSON can also store language preference
-- - Language codes follow ISO 639-1 standard (en, es, fr, de, pt, ja, zh, ru, ar, hi, sk)
-- - Default language is English ('en')

SELECT 'Internationalization support added successfully!' as status;
