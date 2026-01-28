/**
 * DragonflyDB Caching Strategies
 * 
 * Key Naming Convention: {context}:{entity}:{identifier}
 * 
 * Contexts:
 * - acm: Anti-Call Masking
 * - remit: Remittance
 * - mkt: Marketplace
 * - auth: Authentication
 */

export const CacheConfig = {
    // ============================================================================
    // Call Verification Cache (High frequency, short TTL)
    // ============================================================================
    callVerification: {
        keyPattern: 'acm:call:{b_number}',
        ttlSeconds: 300, // 5 minutes
        description: 'Sliding window detection cache for B-numbers',

        // Sorted set for distinct caller tracking
        distinctCallers: {
            keyPattern: 'acm:callers:{b_number}',
            ttlSeconds: 5, // Detection window
            type: 'sorted_set',
            scoreField: 'timestamp',
        },

        // Call metadata
        callMetadata: {
            keyPattern: 'acm:call:meta:{call_id}',
            ttlSeconds: 600, // 10 minutes
            type: 'hash',
        },
    },

    // ============================================================================
    // Blacklist Cache (Medium frequency, longer TTL)
    // ============================================================================
    blacklist: {
        keyPattern: 'acm:blacklist:{type}:{value}',
        ttlSeconds: 3600, // 1 hour
        types: ['MSISDN', 'IP', 'GATEWAY', 'IMEI', 'IMSI'],

        // Bloom filter for quick negative lookups
        bloomFilter: {
            keyPattern: 'acm:blacklist:bloom:{type}',
            size: 1000000,
            errorRate: 0.01,
        },
    },

    // ============================================================================
    // MNP Lookup Cache
    // ============================================================================
    mnpLookup: {
        keyPattern: 'acm:mnp:{msisdn}',
        ttlSeconds: 86400, // 24 hours
        type: 'hash',
        fields: ['original_carrier', 'current_carrier', 'routing_number', 'is_ported'],
    },

    // ============================================================================
    // Gateway Status Cache
    // ============================================================================
    gatewayStatus: {
        keyPattern: 'acm:gateway:{gateway_id}',
        ttlSeconds: 60, // 1 minute
        type: 'hash',
        fields: ['is_active', 'is_blacklisted', 'fraud_threshold', 'call_count'],
    },

    // ============================================================================
    // Exchange Rate Cache (Medium frequency)
    // ============================================================================
    exchangeRate: {
        keyPattern: 'remit:rate:{source_currency}:{target_currency}',
        ttlSeconds: 3600, // 1 hour
        type: 'hash',
        fields: ['rate', 'margin', 'updated_at', 'source'],

        // All rates for a source currency
        allRates: {
            keyPattern: 'remit:rates:{source_currency}',
            ttlSeconds: 3600,
            type: 'hash',
        },
    },

    // ============================================================================
    // Bank Verification Cache
    // ============================================================================
    bankVerification: {
        keyPattern: 'remit:bank:{bank_code}:{account_number}',
        ttlSeconds: 86400, // 24 hours
        type: 'hash',
        fields: ['account_name', 'verified_at', 'status'],
    },

    // ============================================================================
    // Transfer Status Cache
    // ============================================================================
    transferStatus: {
        keyPattern: 'remit:transfer:{reference}',
        ttlSeconds: 3600, // 1 hour
        type: 'string',
        description: 'Quick status lookups for pending transfers',
    },

    // ============================================================================
    // User Session Cache
    // ============================================================================
    session: {
        keyPattern: 'auth:session:{session_id}',
        ttlSeconds: 86400, // 24 hours
        type: 'hash',
        fields: ['user_id', 'role', 'device_id', 'created_at', 'last_activity'],

        // User's active sessions
        userSessions: {
            keyPattern: 'auth:user:sessions:{user_id}',
            ttlSeconds: 86400,
            type: 'set',
        },
    },

    // ============================================================================
    // Rate Limiting
    // ============================================================================
    rateLimit: {
        // API rate limiting
        api: {
            keyPattern: 'rate:api:{user_id}:{endpoint}',
            ttlSeconds: 60,
            type: 'string',
            maxRequests: 100,
        },

        // Login attempt limiting
        login: {
            keyPattern: 'rate:login:{email}',
            ttlSeconds: 900, // 15 minutes
            type: 'string',
            maxAttempts: 5,
        },

        // SMS/OTP rate limiting
        otp: {
            keyPattern: 'rate:otp:{phone}',
            ttlSeconds: 3600, // 1 hour
            type: 'string',
            maxAttempts: 3,
        },
    },

    // ============================================================================
    // Marketplace Caching
    // ============================================================================
    marketplace: {
        // Featured listings
        featuredListings: {
            keyPattern: 'mkt:featured:{category_id}',
            ttlSeconds: 300, // 5 minutes
            type: 'list',
        },

        // Category listings
        categoryListings: {
            keyPattern: 'mkt:category:{category_id}:page:{page}',
            ttlSeconds: 300,
            type: 'string',
        },

        // Provider profile
        providerProfile: {
            keyPattern: 'mkt:provider:{provider_id}',
            ttlSeconds: 600, // 10 minutes
            type: 'hash',
        },
    },
};

/**
 * Cache Helper Functions
 */
export const CacheHelpers = {
    /**
     * Build cache key from pattern
     */
    buildKey: (pattern: string, params: Record<string, string>): string => {
        let key = pattern;
        for (const [name, value] of Object.entries(params)) {
            key = key.replace(`{${name}}`, value);
        }
        return key;
    },

    /**
     * Get sliding window key for detection
     */
    getSliderWindowKey: (bNumber: string): string => {
        return `acm:callers:${bNumber}`;
    },

    /**
     * Get blacklist check key
     */
    getBlacklistKey: (type: string, value: string): string => {
        return `acm:blacklist:${type}:${value}`;
    },

    /**
     * Get session key
     */
    getSessionKey: (sessionId: string): string => {
        return `auth:session:${sessionId}`;
    },

    /**
     * Get exchange rate key
     */
    getExchangeRateKey: (sourceCurrency: string, targetCurrency: string): string => {
        return `remit:rate:${sourceCurrency}:${targetCurrency}`;
    },
};
