-- Migration: Add vaulted payment methods table
-- Created: 2025-12-21
-- Purpose: Store vaulted PayPal payment methods for faster future payments

CREATE TABLE IF NOT EXISTS `vaulted_payment_methods` (
  `vault_id` char(39) NOT NULL,
  `user_id` char(39) NOT NULL,
  `payment_method_type` enum('paypal','credit_card','bank_account') DEFAULT 'paypal',
  `paypal_vault_id` varchar(255) DEFAULT NULL,
  `paypal_email` varchar(255) DEFAULT NULL,
  `card_last_four` varchar(4) DEFAULT NULL,
  `card_brand` varchar(50) DEFAULT NULL,
  `is_default` boolean DEFAULT false,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `expires_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`vault_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_payment_method_type` (`payment_method_type`),
  KEY `idx_is_default` (`is_default`),
  CONSTRAINT `vaulted_payment_methods_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
