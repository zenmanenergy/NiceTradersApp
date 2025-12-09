-- Migration 012: Negotiation System Refactor
-- Refactor from append-only negotiation_history to normalized listing_* tables
-- Status will be derived from timestamps, not stored

-- 1. Add buyer_id to listings table to track winning buyer
ALTER TABLE listings ADD COLUMN buyer_id CHAR(39) NULL DEFAULT NULL;
ALTER TABLE listings ADD FOREIGN KEY (buyer_id) REFERENCES users(UserId);
ALTER TABLE listings ADD INDEX idx_buyer (buyer_id);

-- 2. Create listing_meeting_time table - Time proposal/counter/accept/reject lifecycle
CREATE TABLE listing_meeting_time (
  time_negotiation_id CHAR(39) PRIMARY KEY,
  listing_id CHAR(39) NOT NULL UNIQUE,
  buyer_id CHAR(39) NOT NULL,
  proposed_by CHAR(39) NOT NULL,
  meeting_time DATETIME NOT NULL,
  accepted_at TIMESTAMP NULL,
  rejected_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (listing_id) REFERENCES listings(listing_id),
  FOREIGN KEY (buyer_id) REFERENCES users(UserId),
  FOREIGN KEY (proposed_by) REFERENCES users(UserId),
  INDEX idx_listing (listing_id),
  INDEX idx_buyer (buyer_id),
  INDEX idx_status (accepted_at, rejected_at)
);

-- 3. Create listing_meeting_location table - Location proposal/counter/accept/reject lifecycle
CREATE TABLE listing_meeting_location (
  location_negotiation_id CHAR(39) PRIMARY KEY,
  listing_id CHAR(39) NOT NULL UNIQUE,
  buyer_id CHAR(39) NOT NULL,
  proposed_by CHAR(39) NOT NULL,
  meeting_location_lat DECIMAL(10, 8) NOT NULL,
  meeting_location_lng DECIMAL(11, 8) NOT NULL,
  meeting_location_name VARCHAR(255),
  accepted_at TIMESTAMP NULL,
  rejected_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (listing_id) REFERENCES listings(listing_id),
  FOREIGN KEY (buyer_id) REFERENCES users(UserId),
  FOREIGN KEY (proposed_by) REFERENCES users(UserId),
  INDEX idx_listing (listing_id),
  INDEX idx_buyer (buyer_id),
  INDEX idx_status (accepted_at, rejected_at)
);

-- 4. Create listing_payments table - Payment status tracking
CREATE TABLE listing_payments (
  payment_id CHAR(39) PRIMARY KEY,
  listing_id CHAR(39) NOT NULL UNIQUE,
  buyer_id CHAR(39) NOT NULL,
  buyer_paid_at TIMESTAMP NULL,
  seller_paid_at TIMESTAMP NULL,
  buyer_transaction_id CHAR(39),
  seller_transaction_id CHAR(39),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (listing_id) REFERENCES listings(listing_id),
  FOREIGN KEY (buyer_id) REFERENCES users(UserId),
  INDEX idx_listing (listing_id),
  INDEX idx_buyer (buyer_id),
  INDEX idx_payment_status (buyer_paid_at, seller_paid_at)
);
