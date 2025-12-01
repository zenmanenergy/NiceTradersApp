# Migration Comparison Report

## Summary
Compared all SQL migration files against `database_schema.sql` and identified missing base schema.

## Findings

### ✅ Migrations Found
1. **000_create_base_schema.sql** (NEW - Created)
   - Creates all core tables: users, listings, exchange_offers, transactions, etc.
   - Establishes all foreign key relationships
   - Creates all necessary indexes

2. **001_add_user_devices_table.sql**
   - Creates `user_devices` table for iOS/Android device tokens
   - Creates `apn_logs` table for push notification tracking

3. **002_add_language_support.sql**
   - Adds `preferred_language` column to users table
   - Creates index on language field

4. **003_add_loginview_translations.sql**
   - Inserts translations for LoginView screen
   - Covers: English, Japanese, Spanish, French, German, Arabic, Hindi, Portuguese, Russian, Slovak, Chinese

5. **004_add_negotiation_tables.sql**
   - Creates `exchange_negotiations` table for buyer-seller negotiation
   - Creates `negotiation_history` table for audit trail
   - Creates `user_credits` table for tracking partner payment failures
   - Adds `negotiation_id` column to transactions table

6. **004_password_reset_tokens.sql**
   - Creates `password_reset_tokens` table for forgot password functionality

7. **007_add_rounding_preference.sql**
   - Adds `will_round_to_nearest_dollar` column to listings table
   - Creates index for rounding preference filtering

8. **008_add_geocoding_cache.sql**
   - Creates `geocoding_cache` table for reverse geocoding results
   - Adds geocoding columns to listings table
   - Adds geocoding columns to meeting_proposals table
   - Creates indexes for performance

### ⚠️ Additional Migrations to Consider
1. **add_preferred_language.sql** (Duplicate)
   - Redundant with 002_add_language_support.sql - adds same column
   - Should be removed or merged

2. **create_translations_table.sql** (Duplicate)
   - Creates translations table - also created in database_schema.sql
   - Should be checked if this is the authoritative migration

## Missing Tables
None - All tables from `database_schema.sql` are now covered by migrations

## Table Coverage by Migration
| Table | Migration | Status |
|-------|-----------|--------|
| users | 000 | ✅ |
| user_settings | 000 | ✅ |
| usersessions | 000 | ✅ |
| history | 000 | ✅ |
| listings | 000 | ✅ |
| exchange_offers | 000 | ✅ |
| exchange_transactions | 000 | ✅ |
| user_favorites | 000 | ✅ |
| contact_access | 000 | ✅ |
| messages | 000 | ✅ |
| notifications | 000 | ✅ |
| listing_reports | 000 | ✅ |
| admin_notifications | 000 | ✅ |
| transactions | 000 | ✅ |
| user_ratings | 000 | ✅ |
| exchange_rates | 000 | ✅ |
| meeting_proposals | 000 | ✅ |
| exchange_rate_logs | 000 | ✅ |
| exchange_history | 000 | ✅ |
| user_devices | 001 | ✅ |
| apn_logs | 001 | ✅ |
| password_reset_tokens | 004_password_reset_tokens | ✅ |
| exchange_negotiations | 004_add_negotiation_tables | ✅ |
| negotiation_history | 004_add_negotiation_tables | ✅ |
| user_credits | 004_add_negotiation_tables | ✅ |
| geocoding_cache | 008_add_geocoding_cache | ✅ |
| translations | create_translations_table | ✅ |

## Recommendations
1. ✅ Created `000_create_base_schema.sql` - Run this first to establish all core tables
2. Review and possibly consolidate duplicate language support migrations (002 vs add_preferred_language)
3. Consolidate duplicate translation table creation (create_translations_table vs 003)
4. Verify migration execution order to ensure forward compatibility
