-- Migration: Add password_reset_tokens table
-- Purpose: Store password reset tokens for forgot password functionality

CREATE TABLE IF NOT EXISTS password_reset_tokens (
    TokenId CHAR(39) PRIMARY KEY DEFAULT (UUID()),
    UserId CHAR(39) NOT NULL,
    ResetToken VARCHAR(255) NOT NULL UNIQUE,
    TokenExpires DATETIME NOT NULL,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserId) REFERENCES users(UserId) ON DELETE CASCADE,
    INDEX idx_reset_token (ResetToken),
    INDEX idx_user_id (UserId),
    INDEX idx_expires (TokenExpires)
);
