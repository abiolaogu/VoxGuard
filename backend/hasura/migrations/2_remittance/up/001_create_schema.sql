-- ============================================================================
-- Remittance Bounded Context Schema
-- Nigerian Cross-Border Transfers
-- ============================================================================

-- ============================================================================
-- Remittance Corridors
-- ============================================================================

CREATE TABLE remittance_corridors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_country VARCHAR(3) NOT NULL,
    destination_country VARCHAR(3) NOT NULL DEFAULT 'NGA',
    source_currency VARCHAR(3) NOT NULL,
    destination_currency VARCHAR(3) NOT NULL DEFAULT 'NGN',
    exchange_rate DECIMAL(18,8) NOT NULL,
    rate_margin_percent DECIMAL(5,4) DEFAULT 0.0,
    fee_structure JSONB NOT NULL DEFAULT '{
        "flat_fee": 0,
        "percentage_fee": 0.01,
        "min_fee": 0,
        "max_fee": null
    }',
    min_amount DECIMAL(18,2) DEFAULT 10.00,
    max_amount DECIMAL(18,2) DEFAULT 50000.00,
    daily_limit DECIMAL(18,2) DEFAULT 10000.00,
    monthly_limit DECIMAL(18,2) DEFAULT 50000.00,
    processing_time_hours INTEGER DEFAULT 24,
    is_active BOOLEAN DEFAULT TRUE,
    rate_updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(source_country, destination_country, source_currency, destination_currency)
);

-- Insert common corridors to Nigeria
INSERT INTO remittance_corridors (source_country, source_currency, exchange_rate, fee_structure) VALUES
    ('USA', 'USD', 1550.00, '{"flat_fee": 2.99, "percentage_fee": 0.005, "min_fee": 2.99, "max_fee": 25.00}'),
    ('GBR', 'GBP', 1950.00, '{"flat_fee": 2.49, "percentage_fee": 0.005, "min_fee": 2.49, "max_fee": 20.00}'),
    ('CAN', 'CAD', 1150.00, '{"flat_fee": 3.99, "percentage_fee": 0.006, "min_fee": 3.99, "max_fee": 30.00}'),
    ('DEU', 'EUR', 1680.00, '{"flat_fee": 2.99, "percentage_fee": 0.005, "min_fee": 2.99, "max_fee": 25.00}');

-- ============================================================================
-- Nigerian Banks Reference
-- ============================================================================

CREATE TABLE nigerian_banks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    short_name VARCHAR(50),
    nip_code VARCHAR(10),
    nuban_prefix VARCHAR(3),
    is_active BOOLEAN DEFAULT TRUE,
    supports_instant_transfer BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert major Nigerian banks
INSERT INTO nigerian_banks (code, name, short_name, nip_code) VALUES
    ('044', 'Access Bank', 'Access', '044'),
    ('023', 'Citibank Nigeria', 'Citibank', '023'),
    ('050', 'Ecobank Nigeria', 'Ecobank', '050'),
    ('070', 'Fidelity Bank', 'Fidelity', '070'),
    ('011', 'First Bank of Nigeria', 'FirstBank', '011'),
    ('214', 'First City Monument Bank', 'FCMB', '214'),
    ('058', 'Guaranty Trust Bank', 'GTBank', '058'),
    ('030', 'Heritage Bank', 'Heritage', '030'),
    ('301', 'Jaiz Bank', 'Jaiz', '301'),
    ('082', 'Keystone Bank', 'Keystone', '082'),
    ('076', 'Polaris Bank', 'Polaris', '076'),
    ('101', 'Providus Bank', 'Providus', '101'),
    ('221', 'Stanbic IBTC Bank', 'Stanbic', '221'),
    ('068', 'Standard Chartered', 'StanChart', '068'),
    ('232', 'Sterling Bank', 'Sterling', '232'),
    ('032', 'Union Bank of Nigeria', 'Union', '032'),
    ('033', 'United Bank for Africa', 'UBA', '033'),
    ('215', 'Unity Bank', 'Unity', '215'),
    ('035', 'Wema Bank', 'Wema', '035'),
    ('057', 'Zenith Bank', 'Zenith', '057'),
    ('999', 'Kuda Bank', 'Kuda', '999'),
    ('998', 'OPay', 'OPay', '998'),
    ('997', 'PalmPay', 'PalmPay', '997');

-- ============================================================================
-- Beneficiaries
-- ============================================================================

CREATE TABLE beneficiaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    relationship VARCHAR(50),
    bank_id UUID REFERENCES nigerian_banks(id),
    bank_code VARCHAR(10) NOT NULL,
    account_number VARCHAR(10) NOT NULL,
    account_name VARCHAR(200),
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMPTZ,
    phone_number VARCHAR(20),
    email VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    is_favorite BOOLEAN DEFAULT FALSE,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, bank_code, account_number)
);

CREATE INDEX idx_beneficiaries_user ON beneficiaries(user_id, is_active);

-- ============================================================================
-- Remittance Transactions
-- ============================================================================

CREATE TYPE transfer_status AS ENUM (
    'PENDING',
    'AWAITING_PAYMENT',
    'PAYMENT_RECEIVED',
    'PROCESSING',
    'SENT_TO_BANK',
    'COMPLETED',
    'FAILED',
    'REFUNDED',
    'CANCELLED'
);

CREATE TYPE transfer_purpose AS ENUM (
    'FAMILY_SUPPORT',
    'EDUCATION',
    'MEDICAL',
    'INVESTMENT',
    'PROPERTY',
    'BUSINESS',
    'SAVINGS',
    'OTHER'
);

CREATE TABLE remittance_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reference VARCHAR(20) UNIQUE NOT NULL,
    sender_id UUID NOT NULL,
    beneficiary_id UUID REFERENCES beneficiaries(id),
    corridor_id UUID REFERENCES remittance_corridors(id),
    
    -- Amounts
    amount_sent DECIMAL(18,2) NOT NULL,
    currency_sent VARCHAR(3) NOT NULL,
    amount_received DECIMAL(18,2) NOT NULL,
    currency_received VARCHAR(3) NOT NULL DEFAULT 'NGN',
    exchange_rate DECIMAL(18,8) NOT NULL,
    fee_amount DECIMAL(18,2) NOT NULL,
    total_paid DECIMAL(18,2) NOT NULL,
    
    -- Recipient details (denormalized for audit)
    recipient_bank_code VARCHAR(10) NOT NULL,
    recipient_account_number VARCHAR(10) NOT NULL,
    recipient_account_name VARCHAR(200),
    recipient_phone VARCHAR(20),
    
    -- Status tracking
    status transfer_status NOT NULL DEFAULT 'PENDING',
    purpose transfer_purpose NOT NULL DEFAULT 'FAMILY_SUPPORT',
    narration VARCHAR(100),
    
    -- Payment info
    payment_method VARCHAR(50),
    payment_reference VARCHAR(100),
    payment_received_at TIMESTAMPTZ,
    
    -- Payout info
    payout_reference VARCHAR(100),
    payout_response JSONB,
    
    -- Timestamps
    initiated_at TIMESTAMPTZ DEFAULT NOW(),
    processing_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    failed_at TIMESTAMPTZ,
    failure_reason TEXT,
    
    -- Compliance
    compliance_checked BOOLEAN DEFAULT FALSE,
    compliance_status VARCHAR(50),
    
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_remit_sender ON remittance_transactions(sender_id, created_at);
CREATE INDEX idx_remit_status ON remittance_transactions(status, created_at);
CREATE INDEX idx_remit_reference ON remittance_transactions(reference);
CREATE INDEX idx_remit_beneficiary ON remittance_transactions(beneficiary_id);

-- Generate unique reference
CREATE OR REPLACE FUNCTION generate_remit_reference()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.reference IS NULL THEN
        NEW.reference := 'ACM' || TO_CHAR(NOW(), 'YYMMDD') || 
                         LPAD(FLOOR(RANDOM() * 999999)::TEXT, 6, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_remit_reference BEFORE INSERT ON remittance_transactions
    FOR EACH ROW EXECUTE FUNCTION generate_remit_reference();

-- ============================================================================
-- Exchange Rate History
-- ============================================================================

CREATE TABLE exchange_rate_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    corridor_id UUID REFERENCES remittance_corridors(id),
    rate DECIMAL(18,8) NOT NULL,
    source VARCHAR(50) DEFAULT 'INTERNAL',
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rate_history ON exchange_rate_history(corridor_id, recorded_at);

-- Trigger for rate updates
CREATE TRIGGER update_remit_corridors_updated_at BEFORE UPDATE ON remittance_corridors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_beneficiaries_updated_at BEFORE UPDATE ON beneficiaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_remit_transactions_updated_at BEFORE UPDATE ON remittance_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
