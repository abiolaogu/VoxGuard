-- ============================================================================
-- Identity Bounded Context Schema
-- Authentication, Users, and KYC
-- ============================================================================

-- ============================================================================
-- Users
-- ============================================================================

CREATE TYPE user_role AS ENUM ('USER', 'PROVIDER', 'ANALYST', 'ADMIN', 'SUPER_ADMIN');
CREATE TYPE user_status AS ENUM ('PENDING', 'ACTIVE', 'SUSPENDED', 'DEACTIVATED');
CREATE TYPE kyc_level AS ENUM ('NONE', 'BASIC', 'INTERMEDIATE', 'FULL');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Authentication
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    email_verified_at TIMESTAMPTZ,
    phone VARCHAR(20) UNIQUE,
    phone_verified BOOLEAN DEFAULT FALSE,
    phone_verified_at TIMESTAMPTZ,
    password_hash TEXT NOT NULL,
    
    -- Profile
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    display_name VARCHAR(100),
    avatar_url TEXT,
    date_of_birth DATE,
    gender VARCHAR(10),
    
    -- Location
    country VARCHAR(3) DEFAULT 'NGA',
    state VARCHAR(50),
    city VARCHAR(100),
    timezone VARCHAR(50) DEFAULT 'Africa/Lagos',
    
    -- Status
    role user_role NOT NULL DEFAULT 'USER',
    status user_status NOT NULL DEFAULT 'PENDING',
    kyc_level kyc_level NOT NULL DEFAULT 'NONE',
    
    -- Preferences
    language VARCHAR(10) DEFAULT 'en',
    notifications_email BOOLEAN DEFAULT TRUE,
    notifications_push BOOLEAN DEFAULT TRUE,
    notifications_sms BOOLEAN DEFAULT FALSE,
    
    -- Security
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret TEXT,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMPTZ,
    password_changed_at TIMESTAMPTZ,
    
    -- Timestamps
    last_login_at TIMESTAMPTZ,
    last_active_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role, status);
CREATE INDEX idx_users_status ON users(status);

-- ============================================================================
-- Authentication Sessions
-- ============================================================================

CREATE TYPE device_platform AS ENUM ('WEB', 'ANDROID', 'IOS', 'UNKNOWN');

CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    
    -- Token
    refresh_token_hash TEXT NOT NULL,
    
    -- Device info
    device_id VARCHAR(100),
    device_platform device_platform DEFAULT 'UNKNOWN',
    device_name VARCHAR(200),
    app_version VARCHAR(20),
    os_version VARCHAR(50),
    
    -- Network
    ip_address INET,
    user_agent TEXT,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    revoked_at TIMESTAMPTZ,
    revoked_reason VARCHAR(100),
    
    -- Timestamps
    last_activity_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sessions_user ON sessions(user_id, is_active);
CREATE INDEX idx_sessions_token ON sessions(refresh_token_hash);
CREATE INDEX idx_sessions_expires ON sessions(expires_at) WHERE is_active = TRUE;

-- ============================================================================
-- Email Verification Tokens
-- ============================================================================

CREATE TABLE email_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    email VARCHAR(255) NOT NULL,
    token_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_email_verify_token ON email_verifications(token_hash);
CREATE INDEX idx_email_verify_user ON email_verifications(user_id);

-- ============================================================================
-- Password Reset Tokens
-- ============================================================================

CREATE TABLE password_resets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    token_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_password_reset_token ON password_resets(token_hash);

-- ============================================================================
-- KYC Verifications
-- ============================================================================

CREATE TYPE id_type AS ENUM ('NIN', 'BVN', 'PASSPORT', 'DRIVERS_LICENSE', 'VOTERS_CARD');
CREATE TYPE kyc_status AS ENUM ('PENDING', 'IN_REVIEW', 'APPROVED', 'REJECTED', 'EXPIRED');

CREATE TABLE kyc_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    target_level kyc_level NOT NULL,
    status kyc_status NOT NULL DEFAULT 'PENDING',
    
    -- Documents
    id_type id_type,
    id_number VARCHAR(50),
    id_document_url TEXT,
    selfie_url TEXT,
    proof_of_address_url TEXT,
    
    -- Extracted data
    extracted_first_name VARCHAR(100),
    extracted_last_name VARCHAR(100),
    extracted_dob DATE,
    verification_provider VARCHAR(50),
    verification_reference VARCHAR(100),
    
    -- Review
    reviewed_by VARCHAR(100),
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    
    -- Validity
    expires_at TIMESTAMPTZ,
    
    -- Timestamps
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_kyc_user ON kyc_verifications(user_id, status);
CREATE INDEX idx_kyc_status ON kyc_verifications(status);

-- ============================================================================
-- User Notifications
-- ============================================================================

CREATE TYPE notification_type AS ENUM (
    'SYSTEM',
    'ALERT',
    'REMITTANCE',
    'MARKETPLACE',
    'SECURITY',
    'PROMOTION'
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    notification_type notification_type NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    action_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, is_read, created_at);

-- ============================================================================
-- Push Notification Tokens
-- ============================================================================

CREATE TABLE push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    token TEXT NOT NULL UNIQUE,
    platform device_platform NOT NULL,
    device_id VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_push_tokens_user ON push_tokens(user_id, is_active);

-- ============================================================================
-- Activity Log
-- ============================================================================

CREATE TABLE user_activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    activity_type VARCHAR(100) NOT NULL,
    description TEXT,
    ip_address INET,
    user_agent TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activity_user ON user_activity_log(user_id, created_at);
CREATE INDEX idx_activity_type ON user_activity_log(activity_type, created_at);

-- ============================================================================
-- Update Triggers
-- ============================================================================

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_kyc_updated_at BEFORE UPDATE ON kyc_verifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_push_tokens_updated_at BEFORE UPDATE ON push_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
