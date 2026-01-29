-- Rollback Nigerian Remittance & Marketplace Schema

-- Drop triggers first
DROP TRIGGER IF EXISTS tr_transaction_reference ON remittance.transactions;
DROP TRIGGER IF EXISTS tr_listings_updated ON marketplace.listings;
DROP TRIGGER IF EXISTS tr_recipients_updated ON remittance.recipients;
DROP TRIGGER IF EXISTS tr_transactions_updated ON remittance.transactions;
DROP TRIGGER IF EXISTS tr_corridors_updated ON remittance.corridors;

-- Drop functions
DROP FUNCTION IF EXISTS generate_transaction_reference();
DROP FUNCTION IF EXISTS update_updated_at();

-- Drop indexes
DROP INDEX IF EXISTS marketplace.idx_listings_search;
DROP INDEX IF EXISTS marketplace.idx_listings_price;
DROP INDEX IF EXISTS marketplace.idx_listings_created;
DROP INDEX IF EXISTS marketplace.idx_listings_diaspora;
DROP INDEX IF EXISTS marketplace.idx_listings_status;
DROP INDEX IF EXISTS marketplace.idx_listings_state;
DROP INDEX IF EXISTS marketplace.idx_listings_seller;
DROP INDEX IF EXISTS marketplace.idx_listings_category;
DROP INDEX IF EXISTS remittance.idx_exchange_rates_currency;
DROP INDEX IF EXISTS remittance.idx_recipients_user;
DROP INDEX IF EXISTS remittance.idx_transactions_created;
DROP INDEX IF EXISTS remittance.idx_transactions_status;
DROP INDEX IF EXISTS remittance.idx_transactions_recipient;
DROP INDEX IF EXISTS remittance.idx_transactions_sender;

-- Drop tables (in reverse dependency order)
DROP TABLE IF EXISTS marketplace.inquiries;
DROP TABLE IF EXISTS marketplace.favorites;
DROP TABLE IF EXISTS marketplace.listings;
DROP TABLE IF EXISTS marketplace.categories;
DROP TABLE IF EXISTS reference.nigerian_banks;
DROP TABLE IF EXISTS reference.nigerian_states;
DROP TABLE IF EXISTS remittance.transactions;
DROP TABLE IF EXISTS remittance.recipients;
DROP TABLE IF EXISTS remittance.exchange_rates;
DROP TABLE IF EXISTS remittance.corridors;
