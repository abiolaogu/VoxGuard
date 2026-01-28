-- ============================================================================
-- Marketplace Bounded Context Schema
-- Diaspora Services Marketplace
-- ============================================================================

-- ============================================================================
-- Service Categories
-- ============================================================================

CREATE TABLE service_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    parent_id UUID REFERENCES service_categories(id),
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO service_categories (code, name, description, display_order) VALUES
    ('PROPERTY', 'Property Management', 'Property management, rentals, and real estate services', 1),
    ('LEGAL', 'Legal Services', 'Legal representation, documentation, and advisory', 2),
    ('FINANCIAL', 'Financial Services', 'Banking, investments, and financial planning', 3),
    ('LOGISTICS', 'Logistics & Shipping', 'Cargo, shipping, and delivery services', 4),
    ('HEALTHCARE', 'Healthcare', 'Medical tourism, consultations, and health services', 5),
    ('EDUCATION', 'Education', 'School enrollment, tutoring, and educational services', 6),
    ('CONSTRUCTION', 'Construction', 'Building, renovation, and construction projects', 7),
    ('AUTOMOTIVE', 'Automotive', 'Vehicle purchase, maintenance, and repairs', 8),
    ('EVENTS', 'Events & Occasions', 'Event planning, catering, and venue services', 9),
    ('CONCIERGE', 'Concierge Services', 'Personal assistance and errand services', 10);

-- ============================================================================
-- Nigerian States Reference
-- ============================================================================

CREATE TABLE nigerian_states (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(5) UNIQUE NOT NULL,
    name VARCHAR(50) NOT NULL,
    capital VARCHAR(50),
    region VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO nigerian_states (code, name, capital, region) VALUES
    ('LAG', 'Lagos', 'Ikeja', 'South West'),
    ('ABJ', 'FCT Abuja', 'Abuja', 'North Central'),
    ('KAN', 'Kano', 'Kano', 'North West'),
    ('RIV', 'Rivers', 'Port Harcourt', 'South South'),
    ('OYO', 'Oyo', 'Ibadan', 'South West'),
    ('KAD', 'Kaduna', 'Kaduna', 'North West'),
    ('ANB', 'Anambra', 'Awka', 'South East'),
    ('DEL', 'Delta', 'Asaba', 'South South'),
    ('OGU', 'Ogun', 'Abeokuta', 'South West'),
    ('EDO', 'Edo', 'Benin City', 'South South'),
    ('ENY', 'Enugu', 'Enugu', 'South East'),
    ('IMO', 'Imo', 'Owerri', 'South East'),
    ('ABY', 'Abia', 'Umuahia', 'South East'),
    ('OSU', 'Osun', 'Osogbo', 'South West'),
    ('KWA', 'Kwara', 'Ilorin', 'North Central'),
    ('OND', 'Ondo', 'Akure', 'South West'),
    ('EKI', 'Ekiti', 'Ado-Ekiti', 'South West'),
    ('PLT', 'Plateau', 'Jos', 'North Central'),
    ('CRS', 'Cross River', 'Calabar', 'South South'),
    ('AKS', 'Akwa Ibom', 'Uyo', 'South South');

-- ============================================================================
-- Provider Profiles
-- ============================================================================

CREATE TYPE verification_status AS ENUM ('PENDING', 'IN_REVIEW', 'VERIFIED', 'REJECTED', 'EXPIRED');
CREATE TYPE provider_tier AS ENUM ('BASIC', 'VERIFIED', 'PREMIUM', 'ENTERPRISE');

CREATE TABLE provider_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    business_name VARCHAR(200) NOT NULL,
    business_type VARCHAR(100),
    description TEXT,
    logo_url TEXT,
    cover_image_url TEXT,
    
    -- Location
    state_id UUID REFERENCES nigerian_states(id),
    city VARCHAR(100),
    address TEXT,
    coordinates POINT,
    
    -- Contact
    phone_primary VARCHAR(20),
    phone_secondary VARCHAR(20),
    email VARCHAR(255),
    website TEXT,
    
    -- Social
    instagram VARCHAR(100),
    facebook VARCHAR(100),
    twitter VARCHAR(100),
    whatsapp VARCHAR(20),
    
    -- Verification
    verification_status verification_status DEFAULT 'PENDING',
    tier provider_tier DEFAULT 'BASIC',
    cac_number VARCHAR(50),
    tin_number VARCHAR(50),
    verified_at TIMESTAMPTZ,
    verified_by VARCHAR(100),
    
    -- Ratings
    total_reviews INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    response_rate DECIMAL(5,2) DEFAULT 0.00,
    response_time_hours INTEGER,
    
    -- Stats
    total_orders INTEGER DEFAULT 0,
    completed_orders INTEGER DEFAULT 0,
    total_earnings DECIMAL(18,2) DEFAULT 0.00,
    
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_providers_state ON provider_profiles(state_id, is_active);
CREATE INDEX idx_providers_rating ON provider_profiles(average_rating DESC, total_reviews DESC);
CREATE INDEX idx_providers_verified ON provider_profiles(verification_status, tier);

-- ============================================================================
-- Provider Categories (Many-to-Many)
-- ============================================================================

CREATE TABLE provider_categories (
    provider_id UUID REFERENCES provider_profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES service_categories(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (provider_id, category_id)
);

-- ============================================================================
-- Service Listings
-- ============================================================================

CREATE TYPE listing_status AS ENUM ('DRAFT', 'ACTIVE', 'PAUSED', 'SOLD', 'EXPIRED');
CREATE TYPE pricing_type AS ENUM ('FIXED', 'HOURLY', 'DAILY', 'NEGOTIABLE', 'QUOTE');

CREATE TABLE marketplace_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID REFERENCES provider_profiles(id) NOT NULL,
    category_id UUID REFERENCES service_categories(id) NOT NULL,
    
    -- Basic info
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(250) UNIQUE,
    description TEXT NOT NULL,
    features TEXT[] DEFAULT '{}',
    
    -- Pricing
    pricing_type pricing_type NOT NULL DEFAULT 'FIXED',
    price_ngn DECIMAL(18,2),
    price_min_ngn DECIMAL(18,2),
    price_max_ngn DECIMAL(18,2),
    price_usd DECIMAL(18,2),
    
    -- Location
    state_id UUID REFERENCES nigerian_states(id),
    city VARCHAR(100),
    is_remote_available BOOLEAN DEFAULT FALSE,
    is_diaspora_friendly BOOLEAN DEFAULT TRUE,
    
    -- Media
    images TEXT[] DEFAULT '{}',
    videos TEXT[] DEFAULT '{}',
    documents TEXT[] DEFAULT '{}',
    
    -- Status
    status listing_status NOT NULL DEFAULT 'DRAFT',
    is_featured BOOLEAN DEFAULT FALSE,
    is_promoted BOOLEAN DEFAULT FALSE,
    promoted_until TIMESTAMPTZ,
    
    -- Stats
    view_count INTEGER DEFAULT 0,
    inquiry_count INTEGER DEFAULT 0,
    order_count INTEGER DEFAULT 0,
    favorite_count INTEGER DEFAULT 0,
    
    -- SEO
    meta_title VARCHAR(200),
    meta_description TEXT,
    
    -- Tags
    tags VARCHAR[] DEFAULT '{}',
    
    published_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_listings_provider ON marketplace_listings(provider_id, status);
CREATE INDEX idx_listings_category ON marketplace_listings(category_id, status);
CREATE INDEX idx_listings_state ON marketplace_listings(state_id, status);
CREATE INDEX idx_listings_featured ON marketplace_listings(is_featured, status) WHERE is_featured = TRUE;
CREATE INDEX idx_listings_search ON marketplace_listings USING gin(to_tsvector('english', title || ' ' || description));

-- Generate slug
CREATE OR REPLACE FUNCTION generate_listing_slug()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.slug IS NULL THEN
        NEW.slug := LOWER(REGEXP_REPLACE(NEW.title, '[^a-zA-Z0-9]+', '-', 'g')) || 
                    '-' || SUBSTRING(NEW.id::TEXT, 1, 8);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_listing_slug BEFORE INSERT ON marketplace_listings
    FOR EACH ROW EXECUTE FUNCTION generate_listing_slug();

-- ============================================================================
-- Service Orders
-- ============================================================================

CREATE TYPE order_status AS ENUM (
    'INQUIRY',
    'QUOTED',
    'PENDING_PAYMENT',
    'PAID',
    'IN_PROGRESS',
    'DELIVERED',
    'COMPLETED',
    'DISPUTED',
    'CANCELLED',
    'REFUNDED'
);

CREATE TABLE marketplace_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reference VARCHAR(20) UNIQUE NOT NULL,
    listing_id UUID REFERENCES marketplace_listings(id),
    provider_id UUID REFERENCES provider_profiles(id) NOT NULL,
    customer_id UUID NOT NULL,
    
    -- Details
    status order_status NOT NULL DEFAULT 'INQUIRY',
    requirements TEXT,
    quoted_amount DECIMAL(18,2),
    agreed_amount DECIMAL(18,2),
    currency VARCHAR(3) DEFAULT 'NGN',
    
    -- Delivery
    delivery_date DATE,
    delivered_at TIMESTAMPTZ,
    delivery_notes TEXT,
    
    -- Payment
    payment_status VARCHAR(50) DEFAULT 'PENDING',
    payment_reference VARCHAR(100),
    paid_at TIMESTAMPTZ,
    
    -- Review
    customer_rating INTEGER CHECK (customer_rating >= 1 AND customer_rating <= 5),
    customer_review TEXT,
    reviewed_at TIMESTAMPTZ,
    
    -- Communication
    last_message_at TIMESTAMPTZ,
    message_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_orders_provider ON marketplace_orders(provider_id, status);
CREATE INDEX idx_orders_customer ON marketplace_orders(customer_id, status);
CREATE INDEX idx_orders_listing ON marketplace_orders(listing_id);

-- Generate order reference
CREATE OR REPLACE FUNCTION generate_order_reference()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reference IS NULL THEN
        NEW.reference := 'ORD' || TO_CHAR(NOW(), 'YYMMDD') || 
                         LPAD(FLOOR(RANDOM() * 999999)::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_order_reference BEFORE INSERT ON marketplace_orders
    FOR EACH ROW EXECUTE FUNCTION generate_order_reference();

-- Update triggers
CREATE TRIGGER update_provider_profiles_updated_at BEFORE UPDATE ON provider_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_listings_updated_at BEFORE UPDATE ON marketplace_listings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON marketplace_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
