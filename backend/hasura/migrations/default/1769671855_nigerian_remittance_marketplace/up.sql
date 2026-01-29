-- ============================================================
-- Nigerian Remittance & Marketplace Schema
-- Anti-Call Masking Platform
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- REMITTANCE DOMAIN
-- ============================================================

-- Remittance Corridors (Country-to-Country Routes)
CREATE TABLE remittance.corridors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_country VARCHAR(3) NOT NULL,  -- ISO 3166-1 alpha-3
    target_country VARCHAR(3) NOT NULL DEFAULT 'NGA',
    source_currency VARCHAR(3) NOT NULL,  -- ISO 4217
    target_currency VARCHAR(3) NOT NULL DEFAULT 'NGN',
    
    -- Pricing
    base_fee_percentage DECIMAL(5, 4) NOT NULL DEFAULT 0.015,  -- 1.5%
    flat_fee DECIMAL(12, 2) NOT NULL DEFAULT 2.99,
    fx_spread_percentage DECIMAL(5, 4) NOT NULL DEFAULT 0.005,  -- 0.5%
    
    -- Limits
    min_amount DECIMAL(15, 2) NOT NULL DEFAULT 10.00,
    max_amount DECIMAL(15, 2) NOT NULL DEFAULT 10000.00,
    daily_limit DECIMAL(15, 2) DEFAULT 25000.00,
    monthly_limit DECIMAL(15, 2) DEFAULT 100000.00,
    
    -- Operational
    settlement_time_minutes INTEGER NOT NULL DEFAULT 30,
    is_active BOOLEAN NOT NULL DEFAULT true,
    requires_kyc_level INTEGER NOT NULL DEFAULT 1,
    
    -- Metadata
    display_name VARCHAR(100),
    description TEXT,
    
    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(source_country, target_country, source_currency, target_currency)
);

-- Insert supported corridors
INSERT INTO remittance.corridors (source_country, target_country, source_currency, target_currency, display_name, base_fee_percentage, flat_fee) VALUES
    ('USA', 'NGA', 'USD', 'NGN', 'United States to Nigeria', 0.015, 2.99),
    ('GBR', 'NGA', 'GBP', 'NGN', 'United Kingdom to Nigeria', 0.015, 2.49),
    ('CAN', 'NGA', 'CAD', 'NGN', 'Canada to Nigeria', 0.015, 3.49),
    ('DEU', 'NGA', 'EUR', 'NGN', 'Germany to Nigeria', 0.015, 2.49),
    ('FRA', 'NGA', 'EUR', 'NGN', 'France to Nigeria', 0.015, 2.49),
    ('ZAF', 'NGA', 'ZAR', 'NGN', 'South Africa to Nigeria', 0.02, 4.99),
    ('ARE', 'NGA', 'AED', 'NGN', 'UAE to Nigeria', 0.02, 3.99);

-- Exchange Rates (Cached, updated frequently)
CREATE TABLE remittance.exchange_rates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_currency VARCHAR(3) NOT NULL,
    target_currency VARCHAR(3) NOT NULL DEFAULT 'NGN',
    
    -- Rates
    mid_market_rate DECIMAL(18, 8) NOT NULL,
    buy_rate DECIMAL(18, 8) NOT NULL,
    sell_rate DECIMAL(18, 8) NOT NULL,
    
    -- Provider rates
    provider_name VARCHAR(50),
    provider_rate DECIMAL(18, 8),
    
    -- Validity
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '5 minutes',
    
    -- Metadata
    fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(source_currency, target_currency, valid_from)
);

-- Remittance Transactions
CREATE TABLE remittance.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reference VARCHAR(20) NOT NULL UNIQUE,
    
    -- Sender
    sender_id UUID NOT NULL REFERENCES identity.users(id),
    sender_name VARCHAR(255) NOT NULL,
    sender_country VARCHAR(3) NOT NULL,
    
    -- Recipient
    recipient_id UUID NOT NULL REFERENCES remittance.recipients(id),
    recipient_name VARCHAR(255) NOT NULL,
    recipient_phone VARCHAR(20),
    recipient_state VARCHAR(50),
    
    -- Financial
    source_currency VARCHAR(3) NOT NULL,
    target_currency VARCHAR(3) NOT NULL DEFAULT 'NGN',
    source_amount DECIMAL(15, 2) NOT NULL,
    target_amount DECIMAL(15, 2) NOT NULL,
    exchange_rate DECIMAL(18, 8) NOT NULL,
    fee_amount DECIMAL(15, 2) NOT NULL,
    total_charged DECIMAL(15, 2) NOT NULL,
    
    -- Corridor
    corridor_id UUID REFERENCES remittance.corridors(id),
    
    -- Delivery
    delivery_method VARCHAR(50) NOT NULL DEFAULT 'bank_transfer',
    bank_code VARCHAR(10),
    account_number VARCHAR(20),
    mobile_wallet_provider VARCHAR(50),
    mobile_wallet_number VARCHAR(20),
    
    -- Status
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    status_history JSONB NOT NULL DEFAULT '[]',
    
    -- Compliance
    kyc_verified BOOLEAN NOT NULL DEFAULT false,
    aml_cleared BOOLEAN NOT NULL DEFAULT false,
    sanctions_checked BOOLEAN NOT NULL DEFAULT false,
    
    -- Metadata
    purpose VARCHAR(100),
    notes TEXT,
    
    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    CONSTRAINT valid_status CHECK (status IN (
        'pending', 'processing', 'awaiting_funds', 
        'funded', 'sending', 'delivered', 
        'completed', 'failed', 'cancelled', 'refunded'
    ))
);

-- Recipients (Saved beneficiaries)
CREATE TABLE remittance.recipients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES identity.users(id),
    
    -- Personal
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    
    -- Location
    state_code VARCHAR(10),
    lga VARCHAR(100),
    address TEXT,
    
    -- Banking
    bank_code VARCHAR(10),
    bank_name VARCHAR(100),
    account_number VARCHAR(20),
    account_name VARCHAR(255),
    
    -- Mobile Money
    mobile_wallet_provider VARCHAR(50),
    mobile_wallet_number VARCHAR(20),
    
    -- Verification
    bvn_verified BOOLEAN NOT NULL DEFAULT false,
    account_verified BOOLEAN NOT NULL DEFAULT false,
    
    -- Metadata
    is_favorite BOOLEAN NOT NULL DEFAULT false,
    nickname VARCHAR(50),
    relationship VARCHAR(50),
    
    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_used_at TIMESTAMPTZ
);

-- ============================================================
-- NIGERIAN REFERENCE DATA
-- ============================================================

-- Nigerian States
CREATE TABLE reference.nigerian_states (
    code VARCHAR(3) PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    capital VARCHAR(50) NOT NULL,
    geopolitical_zone VARCHAR(20) NOT NULL,
    latitude DECIMAL(9, 6),
    longitude DECIMAL(9, 6),
    
    CONSTRAINT valid_zone CHECK (geopolitical_zone IN (
        'North Central', 'North East', 'North West',
        'South East', 'South South', 'South West'
    ))
);

-- Insert all 36 states + FCT
INSERT INTO reference.nigerian_states (code, name, capital, geopolitical_zone) VALUES
    ('ABI', 'Abia', 'Umuahia', 'South East'),
    ('ADA', 'Adamawa', 'Yola', 'North East'),
    ('AKW', 'Akwa Ibom', 'Uyo', 'South South'),
    ('ANA', 'Anambra', 'Awka', 'South East'),
    ('BAU', 'Bauchi', 'Bauchi', 'North East'),
    ('BAY', 'Bayelsa', 'Yenagoa', 'South South'),
    ('BEN', 'Benue', 'Makurdi', 'North Central'),
    ('BOR', 'Borno', 'Maiduguri', 'North East'),
    ('CRO', 'Cross River', 'Calabar', 'South South'),
    ('DEL', 'Delta', 'Asaba', 'South South'),
    ('EBO', 'Ebonyi', 'Abakaliki', 'South East'),
    ('EDO', 'Edo', 'Benin City', 'South South'),
    ('EKI', 'Ekiti', 'Ado-Ekiti', 'South West'),
    ('ENU', 'Enugu', 'Enugu', 'South East'),
    ('FCT', 'Federal Capital Territory', 'Abuja', 'North Central'),
    ('GOM', 'Gombe', 'Gombe', 'North East'),
    ('IMO', 'Imo', 'Owerri', 'South East'),
    ('JIG', 'Jigawa', 'Dutse', 'North West'),
    ('KAD', 'Kaduna', 'Kaduna', 'North West'),
    ('KAN', 'Kano', 'Kano', 'North West'),
    ('KAT', 'Katsina', 'Katsina', 'North West'),
    ('KEB', 'Kebbi', 'Birnin Kebbi', 'North West'),
    ('KOG', 'Kogi', 'Lokoja', 'North Central'),
    ('KWA', 'Kwara', 'Ilorin', 'North Central'),
    ('LAG', 'Lagos', 'Ikeja', 'South West'),
    ('NAS', 'Nasarawa', 'Lafia', 'North Central'),
    ('NIG', 'Niger', 'Minna', 'North Central'),
    ('OGU', 'Ogun', 'Abeokuta', 'South West'),
    ('OND', 'Ondo', 'Akure', 'South West'),
    ('OSU', 'Osun', 'Osogbo', 'South West'),
    ('OYO', 'Oyo', 'Ibadan', 'South West'),
    ('PLA', 'Plateau', 'Jos', 'North Central'),
    ('RIV', 'Rivers', 'Port Harcourt', 'South South'),
    ('SOK', 'Sokoto', 'Sokoto', 'North West'),
    ('TAR', 'Taraba', 'Jalingo', 'North East'),
    ('YOB', 'Yobe', 'Damaturu', 'North East'),
    ('ZAM', 'Zamfara', 'Gusau', 'North West');

-- Nigerian Banks
CREATE TABLE reference.nigerian_banks (
    code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    short_name VARCHAR(50) NOT NULL,
    bank_type VARCHAR(30) NOT NULL DEFAULT 'commercial',
    nibss_code VARCHAR(10),
    nip_code VARCHAR(10),
    swift_code VARCHAR(15),
    logo_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    supports_instant_transfer BOOLEAN NOT NULL DEFAULT true,
    
    CONSTRAINT valid_bank_type CHECK (bank_type IN (
        'commercial', 'microfinance', 'digital', 'mortgage', 'merchant'
    ))
);

-- Insert Nigerian banks
INSERT INTO reference.nigerian_banks (code, name, short_name, bank_type, nibss_code, supports_instant_transfer) VALUES
    ('044', 'Access Bank', 'Access', 'commercial', '044', true),
    ('063', 'Access Bank (Diamond)', 'Access Diamond', 'commercial', '063', true),
    ('023', 'Citibank Nigeria', 'Citibank', 'commercial', '023', true),
    ('050', 'Ecobank Nigeria', 'Ecobank', 'commercial', '050', true),
    ('084', 'Enterprise Bank', 'Enterprise', 'commercial', '084', false),
    ('070', 'Fidelity Bank', 'Fidelity', 'commercial', '070', true),
    ('011', 'First Bank of Nigeria', 'First Bank', 'commercial', '011', true),
    ('214', 'First City Monument Bank', 'FCMB', 'commercial', '214', true),
    ('058', 'Guaranty Trust Bank', 'GTBank', 'commercial', '058', true),
    ('030', 'Heritage Bank', 'Heritage', 'commercial', '030', true),
    ('301', 'Jaiz Bank', 'Jaiz', 'commercial', '301', true),
    ('082', 'Keystone Bank', 'Keystone', 'commercial', '082', true),
    ('101', 'Providus Bank', 'Providus', 'commercial', '101', true),
    ('076', 'Polaris Bank', 'Polaris', 'commercial', '076', true),
    ('221', 'Stanbic IBTC Bank', 'Stanbic', 'commercial', '221', true),
    ('068', 'Standard Chartered Bank', 'StanChart', 'commercial', '068', true),
    ('232', 'Sterling Bank', 'Sterling', 'commercial', '232', true),
    ('100', 'SunTrust Bank', 'SunTrust', 'commercial', '100', false),
    ('032', 'Union Bank of Nigeria', 'Union Bank', 'commercial', '032', true),
    ('033', 'United Bank for Africa', 'UBA', 'commercial', '033', true),
    ('215', 'Unity Bank', 'Unity', 'commercial', '215', true),
    ('035', 'Wema Bank', 'Wema', 'commercial', '035', true),
    ('057', 'Zenith Bank', 'Zenith', 'commercial', '057', true),
    -- Digital banks
    ('999992', 'Kuda Bank', 'Kuda', 'digital', '999992', true),
    ('999991', 'OPay', 'OPay', 'digital', '999991', true),
    ('999990', 'PalmPay', 'PalmPay', 'digital', '999990', true),
    ('999989', 'Moniepoint', 'Moniepoint', 'digital', '999989', true),
    ('999988', 'Carbon', 'Carbon', 'digital', '999988', true),
    ('999987', 'Sparkle', 'Sparkle', 'digital', '999987', true),
    ('999986', 'VFD Microfinance Bank', 'VBank', 'microfinance', '999986', true);

-- ============================================================
-- MARKETPLACE DOMAIN
-- ============================================================

-- Marketplace Categories
CREATE TABLE marketplace.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon_name VARCHAR(50),
    parent_id UUID REFERENCES marketplace.categories(id),
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_diaspora_focused BOOLEAN NOT NULL DEFAULT false,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert marketplace categories
INSERT INTO marketplace.categories (name, slug, icon_name, is_diaspora_focused) VALUES
    ('Bill Payment', 'bill-payment', 'receipt', true),
    ('School Fees', 'school-fees', 'school', true),
    ('Rent Payment', 'rent-payment', 'home', true),
    ('Food & Groceries', 'food-groceries', 'shopping-basket', true),
    ('Electronics', 'electronics', 'smartphone', false),
    ('Vehicles', 'vehicles', 'car', false),
    ('Property', 'property', 'building', true),
    ('Fashion', 'fashion', 'shirt', false),
    ('Home Services', 'home-services', 'wrench', true),
    ('Healthcare', 'healthcare', 'heart', true),
    ('Agriculture', 'agriculture', 'leaf', false),
    ('Money Transfer', 'money-transfer', 'send', true);

-- Marketplace Listings
CREATE TABLE marketplace.listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Basic Info
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    slug VARCHAR(300) NOT NULL UNIQUE,
    
    -- Classification
    category_id UUID NOT NULL REFERENCES marketplace.categories(id),
    
    -- Pricing
    price DECIMAL(18, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'NGN',
    usd_price DECIMAL(18, 2),  -- For diaspora convenience
    is_negotiable BOOLEAN NOT NULL DEFAULT false,
    
    -- Seller
    seller_id UUID NOT NULL REFERENCES identity.users(id),
    seller_name VARCHAR(255) NOT NULL,
    seller_phone VARCHAR(20),
    seller_verified BOOLEAN NOT NULL DEFAULT false,
    
    -- Location
    state_code VARCHAR(3) REFERENCES reference.nigerian_states(code),
    lga VARCHAR(100),
    address TEXT,
    latitude DECIMAL(9, 6),
    longitude DECIMAL(9, 6),
    
    -- Media
    images JSONB NOT NULL DEFAULT '[]',
    thumbnail_url TEXT,
    video_url TEXT,
    
    -- Features
    is_diaspora_friendly BOOLEAN NOT NULL DEFAULT false,
    accepts_usd BOOLEAN NOT NULL DEFAULT false,
    accepts_gbp BOOLEAN NOT NULL DEFAULT false,
    has_delivery BOOLEAN NOT NULL DEFAULT false,
    delivery_fee DECIMAL(12, 2),
    
    -- Engagement
    view_count INTEGER NOT NULL DEFAULT 0,
    favorite_count INTEGER NOT NULL DEFAULT 0,
    inquiry_count INTEGER NOT NULL DEFAULT 0,
    
    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    is_featured BOOLEAN NOT NULL DEFAULT false,
    featured_until TIMESTAMPTZ,
    
    -- Audit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    
    CONSTRAINT valid_listing_status CHECK (status IN (
        'draft', 'pending', 'active', 'sold', 
        'expired', 'suspended', 'deleted'
    ))
);

-- Listing Favorites
CREATE TABLE marketplace.favorites (
    user_id UUID NOT NULL REFERENCES identity.users(id),
    listing_id UUID NOT NULL REFERENCES marketplace.listings(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    PRIMARY KEY (user_id, listing_id)
);

-- Listing Inquiries
CREATE TABLE marketplace.inquiries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES marketplace.listings(id),
    sender_id UUID NOT NULL REFERENCES identity.users(id),
    
    message TEXT NOT NULL,
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    replied_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT valid_inquiry_status CHECK (status IN (
        'pending', 'viewed', 'replied', 'closed'
    ))
);

-- ============================================================
-- INDEXES
-- ============================================================

-- Remittance
CREATE INDEX idx_transactions_sender ON remittance.transactions(sender_id);
CREATE INDEX idx_transactions_recipient ON remittance.transactions(recipient_id);
CREATE INDEX idx_transactions_status ON remittance.transactions(status);
CREATE INDEX idx_transactions_created ON remittance.transactions(created_at DESC);
CREATE INDEX idx_recipients_user ON remittance.recipients(user_id);
CREATE INDEX idx_exchange_rates_currency ON remittance.exchange_rates(source_currency, target_currency, valid_until);

-- Marketplace
CREATE INDEX idx_listings_category ON marketplace.listings(category_id);
CREATE INDEX idx_listings_seller ON marketplace.listings(seller_id);
CREATE INDEX idx_listings_state ON marketplace.listings(state_code);
CREATE INDEX idx_listings_status ON marketplace.listings(status);
CREATE INDEX idx_listings_diaspora ON marketplace.listings(is_diaspora_friendly) WHERE is_diaspora_friendly = true;
CREATE INDEX idx_listings_created ON marketplace.listings(created_at DESC);
CREATE INDEX idx_listings_price ON marketplace.listings(price);

-- Full-text search on listings
CREATE INDEX idx_listings_search ON marketplace.listings 
    USING gin(to_tsvector('english', title || ' ' || COALESCE(description, '')));

-- ============================================================
-- TRIGGERS
-- ============================================================

-- Update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_corridors_updated 
    BEFORE UPDATE ON remittance.corridors 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_transactions_updated 
    BEFORE UPDATE ON remittance.transactions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_recipients_updated 
    BEFORE UPDATE ON remittance.recipients 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_listings_updated 
    BEFORE UPDATE ON marketplace.listings 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-generate reference number
CREATE OR REPLACE FUNCTION generate_transaction_reference()
RETURNS TRIGGER AS $$
BEGIN
    NEW.reference = 'ACM' || TO_CHAR(NOW(), 'YYMMDD') || 
                    LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_transaction_reference 
    BEFORE INSERT ON remittance.transactions 
    FOR EACH ROW EXECUTE FUNCTION generate_transaction_reference();
