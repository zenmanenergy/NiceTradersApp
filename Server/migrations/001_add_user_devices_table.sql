-- Migration: Add user_devices table for storing iOS/Android device tokens
-- This table stores push notification device tokens for all user devices

CREATE TABLE IF NOT EXISTS user_devices (
    device_id CHAR(39) PRIMARY KEY,
    UserId CHAR(39) NOT NULL,
    device_type ENUM('ios', 'android', 'web') NOT NULL,
    device_token VARCHAR(500) NOT NULL UNIQUE, -- Apple's device token is up to 200 chars, Firebase tokens are longer
    device_name VARCHAR(255), -- e.g., "iPhone 14", "Samsung Galaxy S23"
    app_version VARCHAR(50), -- Version of the app that registered this device
    os_version VARCHAR(50), -- OS version (e.g., "17.1.2")
    is_active TINYINT DEFAULT 1,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_user_id (UserId),
    INDEX idx_device_type (device_type),
    INDEX idx_is_active (is_active),
    INDEX idx_registered_at (registered_at),
    FOREIGN KEY (UserId) REFERENCES users(UserId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Create APN logs table for tracking push notifications sent
CREATE TABLE IF NOT EXISTS apn_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    UserId CHAR(39) NOT NULL,
    notification_title VARCHAR(255),
    notification_body TEXT,
    device_count INT DEFAULT 0,
    failed_count INT DEFAULT 0,
    metadata JSON, -- Store additional data about the notification
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_user_id (UserId),
    INDEX idx_sent_at (sent_at),
    FOREIGN KEY (UserId) REFERENCES users(UserId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Show migration status
SELECT 'user_devices table created successfully!' as status;
SELECT 'apn_logs table created successfully!' as status2;
