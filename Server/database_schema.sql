-- Complete Database Schema for NiceTradersApp
-- This schema includes all tables with CHAR(39) ID columns

-- Disable foreign key checks temporarily during schema creation
SET FOREIGN_KEY_CHECKS = 0;

-- Drop existing tables if they exist to recreate with proper structure
-- Contact module tables (must be dropped first due to foreign key dependencies)
DROP TABLE IF EXISTS user_ratings;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS admin_notifications;
DROP TABLE IF EXISTS listing_reports;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS contact_access;
-- Original tables
DROP TABLE IF EXISTS user_favorites;
DROP TABLE IF EXISTS exchange_transactions;
DROP TABLE IF EXISTS exchange_offers;
DROP TABLE IF EXISTS listings;
DROP TABLE IF EXISTS history;
DROP TABLE IF EXISTS usersessions;
DROP TABLE IF EXISTS user_settings;
DROP TABLE IF EXISTS users;

-- Create users table (matching existing structure exactly)
CREATE TABLE users (
    UserId CHAR(39) PRIMARY KEY,
    FirstName VARCHAR(100),
    LastName VARCHAR(100),
    Email VARCHAR(255) UNIQUE NOT NULL,
    Phone VARCHAR(20),
    Password VARCHAR(255) NOT NULL,
    UserType VARCHAR(50) DEFAULT 'standard',
    DateCreated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    IsActive TINYINT DEFAULT 1,
    Location TEXT,
    Bio TEXT,
    PreferredLanguage VARCHAR(10) DEFAULT 'en',
    Rating DECIMAL(3,2) DEFAULT 0.00,
    TotalExchanges INT DEFAULT 0,
    INDEX idx_email (Email),
    INDEX idx_is_active (IsActive),
    INDEX idx_preferred_language (PreferredLanguage),
    INDEX idx_rating (Rating)
);

-- Create user_settings table (matching existing structure from UpdateSettings.py)
CREATE TABLE user_settings (
    UserId CHAR(39) PRIMARY KEY,
    SettingsJson TEXT,
    FOREIGN KEY (UserId) REFERENCES users(UserId) ON DELETE CASCADE
);

-- Create usersessions table (matching existing structure exactly)
CREATE TABLE usersessions (
    SessionId CHAR(39) PRIMARY KEY,
    UserId CHAR(39) NOT NULL,
    DateAdded TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (UserId),
    FOREIGN KEY (UserId) REFERENCES users(UserId) ON DELETE CASCADE
);

-- Create history table (used by History.py for audit logging)
CREATE TABLE history (
    historyId CHAR(39) PRIMARY KEY,
    TableName VARCHAR(100) NOT NULL,
    KeyName VARCHAR(100) NOT NULL,
    KeyValue VARCHAR(255),
    UserId CHAR(39) NOT NULL,
    Data TEXT,
    DateAdded TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_table_key (TableName, KeyName),
    INDEX idx_user_id (UserId),
    INDEX idx_date_added (DateAdded),
    FOREIGN KEY (UserId) REFERENCES users(UserId) ON DELETE CASCADE
);

-- Create listings table for currency exchange listings
CREATE TABLE listings (
    listing_id CHAR(39) PRIMARY KEY,
    user_id CHAR(39) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    accept_currency VARCHAR(10) NOT NULL,
    location TEXT NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    location_radius INT DEFAULT 5,
    meeting_preference ENUM('public', 'private', 'online', 'flexible') DEFAULT 'public',
    available_until DATETIME NOT NULL,
    status ENUM('active', 'inactive', 'completed', 'expired') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_currency (currency),
    INDEX idx_accept_currency (accept_currency),
    INDEX idx_location (location(255)),
    INDEX idx_coordinates (latitude, longitude),
    INDEX idx_status (status),
    INDEX idx_available_until (available_until),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(UserId) ON DELETE CASCADE
);

-- Create exchange_offers table for offers on listings
CREATE TABLE exchange_offers (
    offer_id CHAR(39) PRIMARY KEY,
    listing_id CHAR(39) NOT NULL,
    user_id CHAR(39) NOT NULL,
    offered_amount DECIMAL(15,2) NOT NULL,
    offered_currency VARCHAR(10) NOT NULL,
    message TEXT,
    status ENUM('pending', 'accepted', 'rejected', 'expired') DEFAULT 'pending',
    expires_at DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_listing_id (listing_id),
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_expires_at (expires_at),
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(UserId) ON DELETE CASCADE
);

-- Create exchange_transactions table to track completed exchanges
CREATE TABLE exchange_transactions (
    transaction_id CHAR(39) PRIMARY KEY,
    listing_id CHAR(39) NOT NULL,
    offer_id CHAR(39),
    seller_id CHAR(39) NOT NULL,
    buyer_id CHAR(39) NOT NULL,
    currency_sold VARCHAR(10) NOT NULL,
    amount_sold DECIMAL(15,2) NOT NULL,
    currency_bought VARCHAR(10) NOT NULL,
    amount_bought DECIMAL(15,2) NOT NULL,
    exchange_rate DECIMAL(10,6) NOT NULL,
    meeting_location TEXT,
    meeting_time DATETIME,
    status ENUM('pending', 'confirmed', 'disputed', 'completed', 'cancelled') DEFAULT 'pending',
    seller_rating TINYINT CHECK (seller_rating >= 1 AND seller_rating <= 5),
    buyer_rating TINYINT CHECK (buyer_rating >= 1 AND buyer_rating <= 5),
    seller_feedback TEXT,
    buyer_feedback TEXT,
    completed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_listing_id (listing_id),
    INDEX idx_seller_id (seller_id),
    INDEX idx_buyer_id (buyer_id),
    INDEX idx_status (status),
    INDEX idx_completed_at (completed_at),
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE,
    FOREIGN KEY (offer_id) REFERENCES exchange_offers(offer_id) ON DELETE SET NULL,
    FOREIGN KEY (seller_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (buyer_id) REFERENCES users(UserId) ON DELETE CASCADE
);

-- Create user_favorites table for users to save favorite listings
CREATE TABLE user_favorites (
    user_id CHAR(39) NOT NULL,
    listing_id CHAR(39) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, listing_id),
    FOREIGN KEY (user_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE
);

-- Create contact_access table for tracking paid contact access
CREATE TABLE contact_access (
    access_id CHAR(39) PRIMARY KEY,
    user_id CHAR(39) NOT NULL,
    listing_id CHAR(39) NOT NULL,
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL, -- NULL means never expires
    status ENUM('active', 'expired', 'revoked') DEFAULT 'active',
    payment_method VARCHAR(50) DEFAULT 'default',
    amount_paid DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    transaction_id VARCHAR(255) NULL, -- PayPal or payment gateway transaction ID
    -- Exchange rate fields (locked in at time of purchase)
    exchange_rate DECIMAL(15,8) NULL, -- Rate from listing currency to accept currency
    locked_amount DECIMAL(15,2) NULL, -- Calculated amount buyer will pay (in accept_currency)
    rate_calculation_date DATE NULL, -- Date rates were retrieved
    from_currency VARCHAR(10) NULL, -- Listing currency (what seller has)
    to_currency VARCHAR(10) NULL, -- Accept currency (what buyer will pay)
    usd_rate_from DECIMAL(15,8) NULL, -- USD rate for listing currency (at time of purchase)
    usd_rate_to DECIMAL(15,8) NULL, -- USD rate for accept currency (at time of purchase)
    INDEX idx_user_listing (user_id, listing_id),
    INDEX idx_status (status),
    INDEX idx_purchased_at (purchased_at),
    INDEX idx_rate_calculation_date (rate_calculation_date),
    FOREIGN KEY (user_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE,
    UNIQUE KEY unique_active_access (user_id, listing_id, status)
);

-- Create messages table for interest messages and communication
CREATE TABLE messages (
    message_id CHAR(39) PRIMARY KEY,
    listing_id CHAR(39) NOT NULL,
    sender_id CHAR(39) NOT NULL,
    recipient_id CHAR(39) NOT NULL,
    message_type ENUM('interest', 'reply', 'system') DEFAULT 'interest',
    message_text TEXT NULL,
    availability_preferences JSON NULL,
    status ENUM('sent', 'read', 'replied') DEFAULT 'sent',
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    INDEX idx_listing_id (listing_id),
    INDEX idx_sender_id (sender_id),
    INDEX idx_recipient_id (recipient_id),
    INDEX idx_status (status),
    INDEX idx_sent_at (sent_at),
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(UserId) ON DELETE CASCADE
);

-- Create notifications table for user notifications
CREATE TABLE notifications (
    notification_id CHAR(39) PRIMARY KEY,
    user_id CHAR(39) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'new_interest', 'new_message', etc.
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_id CHAR(39) NULL, -- listing_id, message_id, etc.
    status ENUM('unread', 'read', 'dismissed') DEFAULT 'unread',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_type (type),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(UserId) ON DELETE CASCADE
);

-- Create listing_reports table for reporting inappropriate listings
CREATE TABLE listing_reports (
    report_id CHAR(39) PRIMARY KEY,
    listing_id CHAR(39) NOT NULL,
    reporter_id CHAR(39) NOT NULL,
    reported_user_id CHAR(39) NOT NULL,
    reason ENUM('spam', 'fraud', 'inappropriate_content', 'fake_listing', 'abusive_behavior', 'misleading_information', 'other') NOT NULL,
    description TEXT NULL,
    status ENUM('pending', 'reviewing', 'resolved', 'dismissed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    reviewed_by CHAR(39) NULL,
    resolution TEXT NULL,
    INDEX idx_listing_id (listing_id),
    INDEX idx_reporter_id (reporter_id),
    INDEX idx_reported_user_id (reported_user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE,
    FOREIGN KEY (reporter_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (reported_user_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (reviewed_by) REFERENCES users(UserId) ON DELETE SET NULL
);

-- Create admin_notifications table for admin alerts
CREATE TABLE admin_notifications (
    notification_id CHAR(39) PRIMARY KEY,
    type VARCHAR(50) NOT NULL, -- 'listing_report', 'user_suspension', etc.
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    related_id CHAR(39) NULL, -- listing_id, user_id, etc.
    status ENUM('unread', 'read', 'dismissed') DEFAULT 'unread',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    INDEX idx_type (type),
    INDEX idx_priority (priority),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- Create transactions table for payment tracking
CREATE TABLE transactions (
    transaction_id CHAR(39) PRIMARY KEY,
    user_id CHAR(39) NOT NULL,
    listing_id CHAR(39) NULL,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    transaction_type ENUM('contact_fee', 'listing_fee', 'withdrawal', 'refund') NOT NULL,
    status ENUM('pending', 'completed', 'failed', 'cancelled', 'refunded') DEFAULT 'pending',
    payment_method VARCHAR(50) NULL,
    gateway_transaction_id VARCHAR(255) NULL,
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_listing_id (listing_id),
    INDEX idx_type (transaction_type),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE SET NULL
);

-- Create user_ratings table for trader ratings
CREATE TABLE user_ratings (
    rating_id CHAR(39) PRIMARY KEY,
    user_id CHAR(39) NOT NULL, -- user being rated
    rater_id CHAR(39) NOT NULL, -- user giving the rating
    transaction_id CHAR(39) NULL, -- related transaction
    rating TINYINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_rater_id (rater_id),
    INDEX idx_rating (rating),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (rater_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE SET NULL,
    UNIQUE KEY unique_rating (rater_id, transaction_id) -- Prevent multiple ratings for same transaction
);

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Insert sample data for testing (optional)
-- You can uncomment these lines to populate with test data

-- INSERT INTO users (UserId, FirstName, LastName, Email, Phone, Password, UserType, DateCreated, IsActive) VALUES
-- ('USR-test-user-1', 'John', 'Doe', 'test1@example.com', '555-0001', '$2b$12$hash1', 'standard', NOW(), 1),
-- ('USR-test-user-2', 'Jane', 'Smith', 'test2@example.com', '555-0002', '$2b$12$hash2', 'standard', NOW(), 1),
-- ('USR-test-user-3', 'Bob', 'Johnson', 'test3@example.com', '555-0003', '$2b$12$hash3', 'standard', NOW(), 1);

-- INSERT INTO user_settings (UserId, SettingsJson) VALUES
-- ('USR-test-user-1', '{"preferredCurrency": "USD", "defaultLocationRadius": 10}'),
-- ('USR-test-user-2', '{"preferredCurrency": "EUR", "defaultLocationRadius": 15}'),
-- ('USR-test-user-3', '{"preferredCurrency": "GBP", "defaultLocationRadius": 5}');

-- INSERT INTO listings (listing_id, user_id, currency, amount, accept_currency, location, available_until) VALUES
-- ('LST-sample-1', 'USR-test-user-1', 'USD', 1000.00, 'EUR', 'San Francisco, CA', '2025-12-15 23:59:59'),
-- ('LST-sample-2', 'USR-test-user-2', 'GBP', 500.00, 'USD', 'London, UK', '2025-12-20 23:59:59'),
-- ('LST-sample-3', 'USR-test-user-3', 'EUR', 750.00, 'JPY', 'Paris, France', '2025-12-25 23:59:59');

-- Create exchange rates table for currency conversion
CREATE TABLE exchange_rates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    currency_code VARCHAR(3) NOT NULL,
    rate_to_usd DECIMAL(15,8) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    date_retrieved DATE NOT NULL,
    UNIQUE KEY unique_currency_date (currency_code, date_retrieved),
    INDEX idx_currency (currency_code),
    INDEX idx_date (date_retrieved)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create meeting proposals table for scheduling meetings
CREATE TABLE meeting_proposals (
    proposal_id CHAR(39) PRIMARY KEY,
    listing_id CHAR(39) NOT NULL,
    proposer_id CHAR(39) NOT NULL,
    recipient_id CHAR(39) NOT NULL,
    proposed_location TEXT NOT NULL,
    proposed_time DATETIME NOT NULL,
    message TEXT NULL,
    status ENUM('pending', 'accepted', 'rejected', 'expired') DEFAULT 'pending',
    proposed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    INDEX idx_listing_id (listing_id),
    INDEX idx_proposer_id (proposer_id),
    INDEX idx_recipient_id (recipient_id),
    INDEX idx_status (status),
    INDEX idx_proposed_time (proposed_time),
    FOREIGN KEY (listing_id) REFERENCES listings(listing_id) ON DELETE CASCADE,
    FOREIGN KEY (proposer_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(UserId) ON DELETE CASCADE
);

-- Create exchange rate download logs table
CREATE TABLE exchange_rate_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    download_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN NOT NULL,
    rates_downloaded INT DEFAULT 0,
    error_message TEXT,
    INDEX idx_timestamp (download_timestamp),
    INDEX idx_success (success)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create exchange history table for user exchange records
CREATE TABLE exchange_history (
    ExchangeId CHAR(39) PRIMARY KEY,
    UserId CHAR(39) NOT NULL,
    ExchangeDate DATETIME NOT NULL,
    Currency VARCHAR(10) NOT NULL,
    Amount DECIMAL(15,2) NOT NULL,
    PartnerName VARCHAR(200),
    Rating TINYINT CHECK (Rating >= 1 AND Rating <= 5),
    Notes TEXT,
    TransactionType ENUM('buy', 'sell') DEFAULT 'sell',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (UserId),
    INDEX idx_exchange_date (ExchangeDate),
    INDEX idx_currency (Currency),
    FOREIGN KEY (UserId) REFERENCES users(UserId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create translations table for managing translations
CREATE TABLE translations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    translation_key VARCHAR(255) NOT NULL,
    language_code VARCHAR(10) NOT NULL,
    translation_value LONGTEXT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_translation_key (translation_key),
    INDEX idx_language_code (language_code),
    UNIQUE KEY unique_translation (translation_key, language_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Show table creation status
SELECT 'Complete NiceTradersApp database schema created successfully!' as status;
SELECT 'All ID columns are CHAR(39) for consistent sizing' as note;
SELECT 'Includes Contact module tables: contact_access, messages, notifications, listing_reports, admin_notifications, transactions, user_ratings' as contact_tables;
SELECT 'Includes Exchange Rates tables: exchange_rates, exchange_rate_logs' as exchange_rate_tables;
SELECT 'Includes exchange_history table for user transaction records' as exchange_history_table;
SELECT 'Ready for use with Flask application and all functionality' as ready;