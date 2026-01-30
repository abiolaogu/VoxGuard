// anti_call_masking.q - Multicall Masking Attack Detection
// Voice Switch kdb+ Analytics Engine
// ===================================
// Detects when multiple distinct A-numbers call the same B-number within a short window

\d .acm

// ===========================================
// Configuration
// ===========================================
windowNs: 5 * 1000000000;   // 5 seconds in nanoseconds
threshold: 5;                // Minimum distinct A-numbers to trigger
cooldownSecs: 60;            // Cooldown per B-number to prevent alert spam

// ===========================================
// State Tables
// ===========================================

// Recent calls for masking detection (sliding window)
calls:([]
    time:`timestamp$();       // Timestamp (nanosecond precision)
    callId:`symbol$();        // Call ID
    aNumber:`symbol$();       // Source number (A-number)
    bNumber:`symbol$();       // Destination number (B-number)
    sourceIp:`int$();         // Source IP address
    flagged:`boolean$();      // Whether flagged for fraud
    alertId:`guid$()          // Associated alert ID
);

// Cooldown tracking per B-number
cooldowns:([bNumber:`symbol$()] lastAlert:`timestamp$();alertCount:`int$());

// Blocked patterns
blocked:([]
    bNumber:`symbol$();       // Targeted B-number
    aNumbers:`symbol$();      // Source A-numbers involved
    createdAt:`timestamp$();  // When blocked
    expiresAt:`timestamp$();  // When block expires
    alertId:`guid$()          // Associated alert
);

// ===========================================
// Core Detection Function
// Returns: (isMasking; involvedANumbers)
// ===========================================
checkMasking:{[bNum;currentTs]
    windowStart: currentTs - windowNs;

    // Get recent unflagged calls to this B-number
    recent: select from calls
        where bNumber = bNum,
              time within (windowStart; currentTs),
              not flagged;

    // Count distinct A-numbers
    distinctA: distinct recent`aNumber;

    // Return tuple: (detected; list of A-numbers)
    $[threshold <= count distinctA;
        (1b; distinctA);
        (0b; `symbol$())]
 };

// ===========================================
// Process Incoming Call
// Called from main CDR processing
// ===========================================
processCall:{[rec]
    startTime:.z.p;

    // Extract fields
    aNum: `$string rec`sourceNumber;
    bNum: `$string rec`destNumber;
    ts: rec`time;
    callId: `$string rec`callId;
    sourceIp: rec`sourceIp;

    // Check if B-number in cooldown
    if[inCooldown bNum; :(0b; 0Ng)];

    // Insert into sliding window
    `calls insert (ts; callId; aNum; bNum; sourceIp; 0b; 0Ng);

    // Check for masking attack
    result: checkMasking[bNum; ts];

    if[result 0;
        // MASKING DETECTED!
        alertId: first 1?0Ng;
        involvedA: result 1;
        windowStart: ts - windowNs;

        // Get call IDs to flag
        toFlag: select callId from calls
            where bNumber = bNum,
                  aNumber in involvedA,
                  time >= windowStart,
                  not flagged;

        // Flag calls
        update flagged:1b, alertId:alertId from `calls
            where callId in toFlag`callId;

        // Create fraud alert
        raiseAlert[rec; alertId; involvedA];

        // Set cooldown
        `cooldowns upsert (bNum; .z.p; 1i);

        // Return detection result
        :(1b; alertId)
    ];

    // No detection
    (0b; 0Ng)
 };

// ===========================================
// Raise Alert
// ===========================================
raiseAlert:{[rec;alertId;involvedA]
    alert:(
        .z.p;                               // time
        alertId;                            // alertId
        $[`accountId in key rec; rec`accountId; 0Ng];  // accountId
        0Ng;                                // ruleId
        `MULTICALL_MASKING;                 // ruleType
        `CRITICAL;                          // severity
        $[`sourceIp in key rec; rec`sourceIp; 0i]; // sourceIp
        $[`destNumber in key rec; rec`destNumber; `]; // destNumber
        count involvedA;                    // callCount
        `$"Multicall masking: ",string[count involvedA]," distinct callers to same B-number"; // description
        `NEW                                // status
    );

    // Insert into main fraud alert table
    `..fraudAlert insert alert;

    // Log the alert
    -1 "ANTI-CALL MASKING ALERT: ",string[count involvedA]," distinct A-numbers calling ",string rec`destNumber;
    -1 "  A-Numbers: "," " sv string involvedA;
    -1 "  Alert ID: ",string alertId;

    // Send webhook notification if configured
    if[count .cfg.webhookUrl;
        sendWebhook[alertId; rec`destNumber; involvedA]
    ];
 };

// ===========================================
// Cooldown Management
// ===========================================
inCooldown:{[bNum]
    cd: cooldowns bNum;
    if[null cd; :0b];
    cd[`lastAlert] > .z.p - `second$cooldownSecs
 };

// ===========================================
// Cleanup (run periodically)
// ===========================================
cleanup:{[]
    cutoff: .z.p - 0D00:00:30;  // Keep 30 seconds of data
    delete from `calls where time < cutoff, not flagged;

    // Expire old blocks
    delete from `blocked where expiresAt < .z.p;
 };

// ===========================================
// Query Functions
// ===========================================

// Get threat level for B-number
getThreatLevel:{[bNum]
    windowStart: .z.p - windowNs;
    recent: select from calls
        where bNumber = bNum,
              time > windowStart;

    distinctCount: count distinct recent`aNumber;

    level: $[distinctCount >= threshold; `CRITICAL;
             distinctCount >= threshold - 1; `HIGH;
             distinctCount >= threshold - 2; `MEDIUM;
             `LOW];

    `bNumber`distinctA`threshold`level`callCount!(
        bNum; distinctCount; threshold; level; count recent)
 };

// Get elevated threats
getElevatedThreats:{[]
    windowStart: .z.p - windowNs;
    threats: select distinctA: count distinct aNumber,
                    callCount: count i
             by bNumber from calls
             where time > windowStart;

    threats: select from threats where distinctA >= threshold - 2;
    update level: {$[x >= y; `CRITICAL; x >= y-1; `HIGH; `MEDIUM]}[distinctA; threshold]
        from threats
 };

// Get recent alerts (from main fraudAlert table)
getRecentAlerts:{[minutes]
    cutoff: .z.p - `minute$minutes;
    select from ..fraudAlert
        where time > cutoff, ruleType = `MULTICALL_MASKING
 };

// Get statistics
getStats:{[]
    windowStart: .z.p - windowNs;
    activeCalls: count select from calls where time > windowStart;
    totalAlerts: count select from ..fraudAlert where ruleType = `MULTICALL_MASKING;

    `activeCalls`totalAlerts`windowSeconds`threshold`callsInTable!(
        activeCalls;
        totalAlerts;
        windowNs div 1000000000;
        threshold;
        count calls)
 };

// ===========================================
// Runtime Configuration
// ===========================================
setThreshold:{[n]
    if[not n within 2 100;
        -1 "Error: Threshold must be between 2 and 100";
        :0b];
    threshold:: n;
    -1 "Anti-call masking threshold set to ", string n;
    1b
 };

setWindow:{[secs]
    if[not secs within 1 60;
        -1 "Error: Window must be between 1 and 60 seconds";
        :0b];
    windowNs:: secs * 1000000000;
    -1 "Anti-call masking window set to ", string[secs], " seconds";
    1b
 };

// ===========================================
// Webhook Notification
// ===========================================
.cfg.webhookUrl:"";
.cfg.webhookSecret:"";

sendWebhook:{[alertId;bNumber;aNumbers]
    if[0 = count .cfg.webhookUrl; :0b];

    payload:.j.j `event_type`alert!(
        "fraud_detected";
        `alert_id`alert_type`b_number`a_numbers`call_count`severity`detected_at!(
            string alertId;
            "multicall_masking";
            string bNumber;
            string each aNumbers;
            count aNumbers;
            "critical";
            string .z.p
        )
    );

    cmd:"curl -s -X POST -H 'Content-Type: application/json' ",
        $[count .cfg.webhookSecret; "-H 'X-Webhook-Secret: ",.cfg.webhookSecret,"' "; ""],
        "-d '",payload,"' '", .cfg.webhookUrl,"'";

    @[system; cmd; {-1 "Webhook error: ",x}];
    1b
 };

// ===========================================
// Timer for Cleanup
// ===========================================
// Set up periodic cleanup (every 10 seconds)
.acm.timer:{cleanup[]};

\d .

// ===========================================
// Integration with Main CDR Processing
// ===========================================
// Hook into the main .cdr.insert function
.fraud.checkCallMasking:.acm.processCall;

// ===========================================
// Initialize
// ===========================================
-1 "Anti-Call Masking Detection loaded";
-1 "  Window: ",string[.acm.windowNs div 1000000000]," seconds";
-1 "  Threshold: ",string[.acm.threshold]," distinct A-numbers";
-1 "";
-1 "Usage:";
-1 "  .acm.processCall[cdrRecord]     - Process a call for masking detection";
-1 "  .acm.getThreatLevel[`B12345]    - Get threat level for B-number";
-1 "  .acm.getElevatedThreats[]       - Get all elevated threats";
-1 "  .acm.getStats[]                 - Get detection statistics";
-1 "  .acm.setThreshold[5]            - Set detection threshold";
-1 "  .acm.setWindow[5]               - Set window in seconds";
