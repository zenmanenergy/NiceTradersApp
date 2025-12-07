-- Remove foreign key constraint from negotiation_history
-- This allows location-only proposals that don't require exchange_negotiations records

ALTER TABLE negotiation_history
DROP FOREIGN KEY negotiation_history_ibfk_1;
