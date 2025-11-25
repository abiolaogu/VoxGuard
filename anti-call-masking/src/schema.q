// schema.q - Table definitions for fraud detection system
// Anti-Call Masking Detection System
// ===================================

\d .fraud

// ============================================================================
// REAL-TIME CALL EVENTS TABLE
// In-memory rolling window table for active monitoring
// ============================================================================
calls:([]
    call_id:`guid$();           // Unique call identifier (SIP Call-ID mapped to GUID)
    a_number:`symbol$();        // Calling party number (normalized E.164)
    b_number:`symbol$();        // Called party number (normalized E.164)
    ts:`timestamp$();           // Call setup timestamp
    status:`symbol$();          // Call status: `active`ringing`completed`disconnected`failed
    flagged:`boolean$();        // Whether this call has been flagged as fraudulent
    alert_id:`guid$();          // Associated fraud alert ID (null guid if not flagged)
    switch_id:`symbol$();       // Source switch identifier
    raw_call_id:`symbol$()      // Original call ID from switch (for disconnect commands)
);

// Apply sorted attribute on timestamp for time-series performance
// This enables efficient window queries
`ts xasc `calls;

// ============================================================================
// FRAUD ALERTS TABLE
// Stores detected fraud patterns and their resolution status
// ============================================================================
fraud_alerts:([]
    alert_id:`guid$();          // Unique alert identifier
    b_number:`symbol$();        // Target B-number under attack
    a_numbers:();               // List of distinct A-numbers involved
    call_ids:();                // List of call GUIDs involved
    raw_call_ids:();            // List of original call IDs (for disconnect)
    call_count:`int$();         // Total number of calls in pattern
    window_start:`timestamp$(); // Start of detection window
    window_end:`timestamp$();   // End of detection window (when detected)
    action:`symbol$();          // Action status: `detected`disconnecting`completed`failed
    disconnect_count:`int$();   // Number of calls successfully disconnected
    created_at:`timestamp$();   // Alert creation timestamp
    updated_at:`timestamp$();   // Last update timestamp
    resolved_at:`timestamp$();  // Resolution timestamp (null if pending)
    notes:`symbol$()            // Additional notes/error messages
);

// ============================================================================
// BLOCKED PATTERNS TABLE
// Temporary blocks on detected fraud patterns
// ============================================================================
blocked_patterns:([]
    block_id:`guid$();          // Unique block identifier
    b_number:`symbol$();        // Blocked B-number
    a_numbers:();               // List of blocked A-number combinations
    alert_id:`guid$();          // Source alert ID
    created_at:`timestamp$();   // Block start time
    expires_at:`timestamp$();   // Block expiration time
    active:`boolean$()          // Whether block is currently active
);

// ============================================================================
// COOLDOWN TRACKING TABLE
// Prevents alert spam for same B-number
// ============================================================================
cooldowns:([]
    b_number:`symbol$();        // B-number in cooldown
    last_alert_at:`timestamp$();// Timestamp of last alert
    alert_count:`int$()         // Number of alerts in current period
);

// Create unique index on b_number for fast lookups
`b_number xkey `cooldowns;

// ============================================================================
// STATISTICS TABLE
// Aggregated metrics for monitoring and reporting
// ============================================================================
stats:([]
    ts:`timestamp$();           // Measurement timestamp
    calls_processed:`long$();   // Total calls processed in period
    alerts_generated:`int$();   // Fraud alerts generated
    calls_disconnected:`int$(); // Calls disconnected
    avg_detection_ms:`float$(); // Average detection latency
    max_detection_ms:`float$(); // Maximum detection latency
    active_calls:`int$();       // Current active calls in window
    memory_mb:`float$()         // Memory usage in MB
);

// ============================================================================
// CONNECTION STATE TABLE
// Tracks switch connections
// ============================================================================
connections:([]
    conn_id:`int$();            // Connection handle
    switch_id:`symbol$();       // Switch identifier
    host:`symbol$();            // Switch host
    port:`int$();               // Switch port
    protocol:`symbol$();        // Protocol type
    status:`symbol$();          // `connected`disconnected`reconnecting
    connected_at:`timestamp$(); // Connection established time
    last_event_at:`timestamp$();// Last event received time
    events_received:`long$();   // Total events received
    errors:`int$()              // Error count
);

\d .

// ============================================================================
// SCHEMA HELPER FUNCTIONS
// ============================================================================

// Clear all tables (for testing/reset)
.fraud.clearTables:{[]
    delete from `.fraud.calls;
    delete from `.fraud.fraud_alerts;
    delete from `.fraud.blocked_patterns;
    delete from `.fraud.cooldowns;
    delete from `.fraud.stats;
    delete from `.fraud.connections;
    0N!"[INFO] All tables cleared";
 };

// Get table sizes
.fraud.tableSizes:{[]
    tabs:`calls`fraud_alerts`blocked_patterns`cooldowns`stats`connections;
    ([]table:tabs;rows:{count value `.fraud,x} each tabs)
 };

// Estimate memory usage (rough estimate)
.fraud.memoryUsage:{[]
    tabs:`calls`fraud_alerts`blocked_patterns`cooldowns`stats`connections;
    sizes:{-22!value `.fraud,x} each tabs;
    total:sum sizes;
    ([]table:tabs,`TOTAL;bytes:sizes,total;mb:(sizes,total)%1024*1024)
 };

// Expire old records from calls table (garbage collection)
.fraud.expireCalls:{[windowSeconds]
    cutoff:.z.P - `second$windowSeconds;
    before:count .fraud.calls;
    // Keep only calls within window or flagged calls
    delete from `.fraud.calls where ts<cutoff, not flagged;
    after:count .fraud.calls;
    expired:before - after;
    if[expired>0;0N!"[INFO] Expired ",string[expired]," old call records"];
    expired
 };

// Expire old blocked patterns
.fraud.expireBlocks:{[]
    now:.z.P;
    before:count .fraud.blocked_patterns;
    update active:0b from `.fraud.blocked_patterns where expires_at<now;
    delete from `.fraud.blocked_patterns where not active;
    after:count .fraud.blocked_patterns;
    expired:before - after;
    if[expired>0;0N!"[INFO] Expired ",string[expired]," block patterns"];
    expired
 };

// Archive old alerts (move to disk)
.fraud.archiveAlerts:{[daysOld]
    cutoff:.z.P - `day$daysOld;
    toArchive:select from .fraud.fraud_alerts where created_at<cutoff, action=`completed;
    if[count toArchive;
        // Append to archive file
        archiveFile:`:archive/alerts_,string[`date$.z.D];
        archiveFile upsert toArchive;
        // Remove from memory
        delete from `.fraud.fraud_alerts where alert_id in toArchive`alert_id;
        0N!"[INFO] Archived ",string[count toArchive]," old alerts";
    ];
    count toArchive
 };

// Create indexes for performance
.fraud.createIndexes:{[]
    // Calls table: sorted by timestamp for window queries
    `ts xasc `.fraud.calls;

    // Index on b_number for fast lookups
    @[`.fraud.calls;`b_number;`g#];

    0N!"[INFO] Indexes created";
 };

// Validate schema integrity
.fraud.validateSchema:{[]
    errors:();

    // Check calls table columns
    expectedCols:`call_id`a_number`b_number`ts`status`flagged`alert_id`switch_id`raw_call_id;
    actualCols:cols .fraud.calls;
    if[not expectedCols~actualCols;
        errors,:enlist"calls table schema mismatch"];

    // Check fraud_alerts table columns
    expectedCols:`alert_id`b_number`a_numbers`call_ids`raw_call_ids`call_count`window_start`window_end`action`disconnect_count`created_at`updated_at`resolved_at`notes;
    actualCols:cols .fraud.fraud_alerts;
    if[not expectedCols~actualCols;
        errors,:enlist"fraud_alerts table schema mismatch"];

    if[count errors;
        0N!"[ERROR] Schema validation failed:";
        {0N!"  - ",x} each errors;
        :0b
    ];

    0N!"[INFO] Schema validated successfully";
    1b
 };

// Initialize schema
.fraud.validateSchema[];

0N!"[INFO] schema.q loaded successfully";
