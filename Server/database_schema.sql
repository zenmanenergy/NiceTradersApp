-- Database Schema Export
-- Exported: 2025-12-19 09:13:26

CREATE TABLE `admin_notifications` (
  `notification_id` char(39) NOT NULL,
  `type` varchar(50) NOT NULL,
  `priority` enum('low','medium','high','urgent') DEFAULT 'medium',
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `related_id` char(39) DEFAULT NULL,
  `status` enum('unread','read','dismissed') DEFAULT 'unread',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `read_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`notification_id`),
  KEY `idx_type` (`type`),
  KEY `idx_priority` (`priority`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `apn_logs` (
  `log_id` int NOT NULL AUTO_INCREMENT,
  `user_id` char(39) DEFAULT NULL,
  `notification_title` varchar(255) DEFAULT NULL,
  `notification_body` text,
  `device_count` int DEFAULT '0',
  `failed_count` int DEFAULT '0',
  `metadata` json DEFAULT NULL,
  `sent_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_sent_at` (`sent_at`),
  CONSTRAINT `apn_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `exchange_rate_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `download_timestamp` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `success` tinyint(1) NOT NULL,
  `rates_downloaded` int DEFAULT '0',
  `error_message` text,
  PRIMARY KEY (`id`),
  KEY `idx_timestamp` (`download_timestamp`),
  KEY `idx_success` (`success`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `exchange_rates` (
  `id` int NOT NULL AUTO_INCREMENT,
  `currency_code` varchar(3) NOT NULL,
  `rate_to_usd` decimal(15,8) NOT NULL,
  `last_updated` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `date_retrieved` date NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_currency_date` (`currency_code`,`date_retrieved`),
  KEY `idx_currency` (`currency_code`),
  KEY `idx_date` (`date_retrieved`)
) ENGINE=InnoDB AUTO_INCREMENT=997 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `geocoding_cache` (
  `cache_id` char(39) NOT NULL,
  `latitude` decimal(10,8) NOT NULL,
  `longitude` decimal(11,8) NOT NULL,
  `geocoded_location` varchar(255) NOT NULL COMMENT 'City, State or similar human-readable location',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `accessed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `access_count` int DEFAULT '1' COMMENT 'Track how often this cache is used for optimization',
  PRIMARY KEY (`cache_id`),
  UNIQUE KEY `unique_coordinates` (`latitude`,`longitude`),
  KEY `idx_coordinates` (`latitude`,`longitude`),
  KEY `idx_accessed_at` (`accessed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Centralized cache for reverse geocoding results to avoid repeated API calls';

CREATE TABLE `history` (
  `historyId` char(39) NOT NULL,
  `TableName` varchar(100) NOT NULL,
  `KeyName` varchar(100) NOT NULL,
  `KeyValue` varchar(255) DEFAULT NULL,
  `user_id` char(39) DEFAULT NULL,
  `Data` text,
  `DateAdded` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`historyId`),
  KEY `idx_table_key` (`TableName`,`KeyName`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_date_added` (`DateAdded`),
  CONSTRAINT `history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `listing_meeting_location` (
  `location_negotiation_id` char(39) NOT NULL,
  `listing_id` char(39) NOT NULL,
  `buyer_id` char(39) NOT NULL,
  `proposed_by` char(39) NOT NULL,
  `meeting_location_lat` decimal(10,8) NOT NULL,
  `meeting_location_lng` decimal(11,8) NOT NULL,
  `meeting_location_name` varchar(255) DEFAULT NULL,
  `accepted_at` timestamp NULL DEFAULT NULL,
  `rejected_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`location_negotiation_id`),
  UNIQUE KEY `listing_id` (`listing_id`),
  KEY `idx_listing` (`listing_id`),
  KEY `idx_buyer` (`buyer_id`),
  KEY `idx_status` (`accepted_at`,`rejected_at`),
  KEY `listing_meeting_location_ibfk_3` (`proposed_by`),
  CONSTRAINT `listing_meeting_location_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`listing_id`),
  CONSTRAINT `listing_meeting_location_ibfk_2` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `listing_meeting_location_ibfk_3` FOREIGN KEY (`proposed_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `listing_meeting_time` (
  `time_negotiation_id` char(39) NOT NULL,
  `listing_id` char(39) NOT NULL,
  `buyer_id` char(39) NOT NULL,
  `proposed_by` char(39) NOT NULL,
  `meeting_time` datetime NOT NULL,
  `accepted_at` timestamp NULL DEFAULT NULL,
  `rejected_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`time_negotiation_id`),
  UNIQUE KEY `listing_id` (`listing_id`),
  KEY `idx_listing` (`listing_id`),
  KEY `idx_buyer` (`buyer_id`),
  KEY `idx_status` (`accepted_at`,`rejected_at`),
  KEY `listing_meeting_time_ibfk_3` (`proposed_by`),
  CONSTRAINT `listing_meeting_time_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`listing_id`),
  CONSTRAINT `listing_meeting_time_ibfk_2` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `listing_meeting_time_ibfk_3` FOREIGN KEY (`proposed_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `listing_payments` (
  `payment_id` char(39) NOT NULL,
  `listing_id` char(39) NOT NULL,
  `buyer_id` char(39) NOT NULL,
  `buyer_paid_at` timestamp NULL DEFAULT NULL,
  `seller_paid_at` timestamp NULL DEFAULT NULL,
  `buyer_transaction_id` char(39) DEFAULT NULL,
  `seller_transaction_id` char(39) DEFAULT NULL,
  `payment_method` varchar(50) DEFAULT 'paypal',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`payment_id`),
  UNIQUE KEY `listing_id` (`listing_id`),
  KEY `idx_listing` (`listing_id`),
  KEY `idx_buyer` (`buyer_id`),
  KEY `idx_payment_status` (`buyer_paid_at`,`seller_paid_at`),
  KEY `idx_payment_method` (`payment_method`),
  CONSTRAINT `listing_payments_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`listing_id`),
  CONSTRAINT `listing_payments_ibfk_2` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `listing_reports` (
  `report_id` char(39) NOT NULL,
  `listing_id` char(39) NOT NULL,
  `reporter_id` char(39) NOT NULL,
  `reported_user_id` char(39) NOT NULL,
  `reason` enum('spam','fraud','inappropriate_content','fake_listing','abusive_behavior','misleading_information','other') NOT NULL,
  `description` text,
  `status` enum('pending','reviewing','resolved','dismissed') DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `reviewed_by` char(39) DEFAULT NULL,
  `resolution` text,
  PRIMARY KEY (`report_id`),
  KEY `idx_listing_id` (`listing_id`),
  KEY `idx_reporter_id` (`reporter_id`),
  KEY `idx_reported_user_id` (`reported_user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  KEY `listing_reports_ibfk_4` (`reviewed_by`),
  CONSTRAINT `listing_reports_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`listing_id`) ON DELETE CASCADE,
  CONSTRAINT `listing_reports_ibfk_2` FOREIGN KEY (`reporter_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `listing_reports_ibfk_3` FOREIGN KEY (`reported_user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `listing_reports_ibfk_4` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `listings` (
  `listing_id` char(39) NOT NULL,
  `user_id` char(39) NOT NULL,
  `currency` varchar(10) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `accept_currency` varchar(10) NOT NULL,
  `location` text NOT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `location_radius` int DEFAULT '5',
  `meeting_preference` enum('public','private','online','flexible') DEFAULT 'public',
  `will_round_to_nearest_dollar` tinyint(1) DEFAULT '0',
  `available_until` datetime NOT NULL,
  `status` enum('active','inactive','completed','expired') DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `geocoded_location` varchar(255) DEFAULT NULL,
  `geocoding_updated_at` timestamp NULL DEFAULT NULL,
  `buyer_id` char(39) DEFAULT NULL,
  PRIMARY KEY (`listing_id`),
  KEY `idx_currency` (`currency`),
  KEY `idx_accept_currency` (`accept_currency`),
  KEY `idx_location` (`location`(255)),
  KEY `idx_coordinates` (`latitude`,`longitude`),
  KEY `idx_status` (`status`),
  KEY `idx_available_until` (`available_until`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_will_round_to_nearest_dollar` (`will_round_to_nearest_dollar`),
  KEY `idx_buyer` (`buyer_id`),
  CONSTRAINT `listings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `listings_ibfk_2` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `messages` (
  `message_id` char(39) NOT NULL,
  `listing_id` char(39) NOT NULL,
  `sender_id` char(39) NOT NULL,
  `recipient_id` char(39) NOT NULL,
  `message_type` enum('interest','reply','system') DEFAULT 'interest',
  `message_text` text,
  `availability_preferences` json DEFAULT NULL,
  `status` enum('sent','read','replied') DEFAULT 'sent',
  `sent_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `read_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`message_id`),
  KEY `idx_listing_id` (`listing_id`),
  KEY `idx_sender_id` (`sender_id`),
  KEY `idx_recipient_id` (`recipient_id`),
  KEY `idx_status` (`status`),
  KEY `idx_sent_at` (`sent_at`),
  CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`listing_id`) ON DELETE CASCADE,
  CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `messages_ibfk_3` FOREIGN KEY (`recipient_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `notifications` (
  `notification_id` char(39) NOT NULL,
  `user_id` char(39) NOT NULL,
  `type` varchar(50) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `related_id` char(39) DEFAULT NULL,
  `status` enum('unread','read','dismissed') DEFAULT 'unread',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `read_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`notification_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_type` (`type`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `password_reset_tokens` (
  `TokenId` char(39) NOT NULL DEFAULT (uuid()),
  `user_id` char(39) NOT NULL,
  `ResetToken` varchar(255) NOT NULL,
  `TokenExpires` datetime NOT NULL,
  `CreatedAt` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`TokenId`),
  UNIQUE KEY `ResetToken` (`ResetToken`),
  KEY `idx_reset_token` (`ResetToken`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_expires` (`TokenExpires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `paypal_orders` (
  `order_id` varchar(255) NOT NULL,
  `user_id` char(39) NOT NULL,
  `listing_id` char(39) NOT NULL,
  `transaction_id` varchar(255) DEFAULT NULL,
  `status` enum('CREATED','APPROVED','VOIDED','COMPLETED','FAILED','CANCELLED') DEFAULT 'CREATED',
  `payer_email` varchar(255) DEFAULT NULL,
  `payer_name` varchar(255) DEFAULT NULL,
  `amount` decimal(15,2) DEFAULT NULL,
  `currency` varchar(10) DEFAULT 'USD',
  `approval_link` varchar(1000) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_listing_id` (`listing_id`),
  KEY `idx_status` (`status`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `paypal_orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `paypal_orders_ibfk_2` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`listing_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `translations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `translation_key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `language_code` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `translation_value` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_key_language` (`translation_key`,`language_code`),
  KEY `idx_language_code` (`language_code`),
  KEY `idx_updated_at` (`updated_at`)
) ENGINE=InnoDB AUTO_INCREMENT=6112 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `user_credits` (
  `credit_id` char(39) NOT NULL,
  `user_id` char(39) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `currency` varchar(10) DEFAULT 'USD',
  `reason` enum('partner_no_payment','system_refund','promotion','other') DEFAULT 'partner_no_payment',
  `negotiation_id` char(39) DEFAULT NULL,
  `transaction_id` char(39) DEFAULT NULL,
  `status` enum('available','applied','expired','cancelled') DEFAULT 'available',
  `applied_to_negotiation_id` char(39) DEFAULT NULL,
  `applied_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`credit_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_status` (`status`),
  KEY `idx_negotiation_id` (`negotiation_id`),
  KEY `idx_applied_to` (`applied_to_negotiation_id`),
  KEY `idx_expires_at` (`expires_at`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `user_credits_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `user_devices` (
  `device_id` char(39) NOT NULL,
  `user_id` char(39) NOT NULL,
  `device_type` enum('ios','android','web') NOT NULL,
  `device_token` varchar(500) DEFAULT NULL,
  `device_name` varchar(255) DEFAULT NULL,
  `app_version` varchar(50) DEFAULT NULL,
  `os_version` varchar(50) DEFAULT NULL,
  `is_active` tinyint DEFAULT '1',
  `registered_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`device_id`),
  UNIQUE KEY `device_token` (`device_token`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_device_type` (`device_type`),
  KEY `idx_is_active` (`is_active`),
  KEY `idx_registered_at` (`registered_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `user_ratings` (
  `rating_id` char(39) NOT NULL,
  `user_id` char(39) NOT NULL,
  `rater_id` char(39) NOT NULL,
  `transaction_id` char(39) DEFAULT NULL,
  `rating` tinyint NOT NULL,
  `review` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`rating_id`),
  UNIQUE KEY `unique_rating` (`rater_id`,`transaction_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_rater_id` (`rater_id`),
  KEY `idx_rating` (`rating`),
  KEY `idx_created_at` (`created_at`),
  KEY `transaction_id` (`transaction_id`),
  CONSTRAINT `user_ratings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_ratings_ibfk_2` FOREIGN KEY (`rater_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_ratings_chk_1` CHECK (((`rating` >= 1) and (`rating` <= 5)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `user_settings` (
  `user_id` char(39) NOT NULL,
  `SettingsJson` text,
  PRIMARY KEY (`user_id`),
  CONSTRAINT `user_settings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `users` (
  `user_id` char(39) NOT NULL,
  `FirstName` varchar(100) DEFAULT NULL,
  `LastName` varchar(100) DEFAULT NULL,
  `Email` varchar(255) NOT NULL,
  `Phone` varchar(20) DEFAULT NULL,
  `Password` varchar(255) NOT NULL,
  `UserType` varchar(50) DEFAULT 'standard',
  `DateCreated` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `IsActive` tinyint DEFAULT '1',
  `Location` text,
  `Bio` text,
  `PreferredLanguage` varchar(10) DEFAULT 'en',
  `Rating` decimal(3,2) DEFAULT '0.00',
  `TotalExchanges` int DEFAULT '0',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `Email` (`Email`),
  KEY `idx_email` (`Email`),
  KEY `idx_is_active` (`IsActive`),
  KEY `idx_preferred_language` (`PreferredLanguage`),
  KEY `idx_rating` (`Rating`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `usersessions` (
  `SessionId` char(39) NOT NULL,
  `user_id` char(39) NOT NULL,
  `DateAdded` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`SessionId`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

