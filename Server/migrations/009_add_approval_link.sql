-- Add approval_link column to paypal_orders table
ALTER TABLE `paypal_orders` 
ADD COLUMN `approval_link` VARCHAR(1000) DEFAULT NULL AFTER `currency`;
