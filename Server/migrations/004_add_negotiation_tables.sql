-- Migration 004: Add negotiation system for buyer-seller time coordination
-- This migration adds tables for the negotiation workflow before payment

-- Create exchange_negotiations table
CREATE TABLE IF NOT EXISTS exchange_negotiations (
    negotiation_id CHAR(39) PRIMARY KEY,
    listing_id CHAR(39) NOT NULL,
    buyer_id CHAR(39) NOT NULL,
    seller_id CHAR(39) NOT NULL,
    status ENUM('proposed', 'countered', 'agreed', 'rejected', 'expired', 'cancelled', 'paid_partial', 'paid_complete') DEFAULT 'proposed',
    current_proposed_time DATETIME NOT NULL,
    proposed_by CHAR(39) NOT NULL, -- UserId of who made current proposal
    buyer_paid TINYINT DEFAULT 0,
    seller_paid TINYINT DEFAULT 0,
    buyer_paid_at TIMESTAMP NULL,
    seller_paid_at TIMESTAMP NULL,
    buyer_payment_transaction_id CHAR(39) NULL,
    seller_payment_transaction_id CHAR(39) NULL,
    agreement_reached_at TIMESTAMP NULL, -- When both parties agreed (starts 2hr payment window)
    payment_deadline TIMESTAMP NULL, -- agreement_reached_at + 2 hours
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_listing_id (listing_id),
    INDEX idx_buyer_id (buyer_id),
    INDEX idx_seller_id (seller_id),
    INDEX idx_status (status),
    INDEX idx_proposed_time (current_proposed_time),
    INDEX idx_payment_deadline (payment_deadline),
    INDEX idx_created_at (created_at),
    INDEX idx_agreement_reached (agreement_reached_at),
    
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE,
    FOREIGN KEY (buyer_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (seller_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (proposed_by) REFERENCES users(UserId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create negotiation_history table for audit trail
CREATE TABLE IF NOT EXISTS negotiation_history (
    history_id CHAR(39) PRIMARY KEY,
    negotiation_id CHAR(39) NOT NULL,
    action ENUM('initial_proposal', 'counter_proposal', 'accepted', 'rejected', 'cancelled', 'buyer_paid', 'seller_paid', 'expired') NOT NULL,
    proposed_time DATETIME NULL, -- Time that was proposed in this action
    proposed_by CHAR(39) NULL, -- UserId who took this action
    notes TEXT NULL, -- Additional context or reason
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_negotiation_id (negotiation_id),
    INDEX idx_action (action),
    INDEX idx_proposed_by (proposed_by),
    INDEX idx_created_at (created_at),
    
    FOREIGN KEY (negotiation_id) REFERENCES exchange_negotiations(negotiation_id) ON DELETE CASCADE,
    FOREIGN KEY (proposed_by) REFERENCES users(UserId) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create user_credits table for tracking $2 credits when partner fails to pay
CREATE TABLE IF NOT EXISTS user_credits (
    credit_id CHAR(39) PRIMARY KEY,
    user_id CHAR(39) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    reason ENUM('partner_no_payment', 'system_refund', 'promotion', 'other') DEFAULT 'partner_no_payment',
    negotiation_id CHAR(39) NULL, -- Reference to related negotiation if applicable
    transaction_id CHAR(39) NULL, -- Reference to original payment transaction
    status ENUM('available', 'applied', 'expired', 'cancelled') DEFAULT 'available',
    applied_to_negotiation_id CHAR(39) NULL, -- Which negotiation this credit was applied to
    applied_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL, -- Optional expiration date
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_negotiation_id (negotiation_id),
    INDEX idx_applied_to (applied_to_negotiation_id),
    INDEX idx_expires_at (expires_at),
    INDEX idx_created_at (created_at),
    
    FOREIGN KEY (user_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (negotiation_id) REFERENCES exchange_negotiations(negotiation_id) ON DELETE SET NULL,
    FOREIGN KEY (applied_to_negotiation_id) REFERENCES exchange_negotiations(negotiation_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add column to transactions table for linking negotiation payments
-- Check if column exists first to make migration idempotent
SET @col_exists = (SELECT COUNT(*) 
                   FROM INFORMATION_SCHEMA.COLUMNS 
                   WHERE TABLE_SCHEMA = 'nicetraders' 
                   AND TABLE_NAME = 'transactions' 
                   AND COLUMN_NAME = 'negotiation_id');

SET @sql = IF(@col_exists = 0,
              'ALTER TABLE transactions ADD COLUMN negotiation_id CHAR(39) NULL AFTER listing_id',
              'SELECT "Column negotiation_id already exists" AS status');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add index if it doesn't exist
SET @idx_exists = (SELECT COUNT(*) 
                   FROM INFORMATION_SCHEMA.STATISTICS 
                   WHERE TABLE_SCHEMA = 'nicetraders' 
                   AND TABLE_NAME = 'transactions' 
                   AND INDEX_NAME = 'idx_negotiation_id');

SET @sql = IF(@idx_exists = 0,
              'ALTER TABLE transactions ADD INDEX idx_negotiation_id (negotiation_id)',
              'SELECT "Index idx_negotiation_id already exists" AS status');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SELECT 'Migration 004 completed: Negotiation system tables created successfully!' as status;
