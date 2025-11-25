// detection.q - Core fraud detection algorithm
// Anti-Call Masking Detection System
// ===================================
// Implements sliding window detection for multicall masking attacks

\d .fraud

// ============================================================================
// CORE CONFIGURATION (nanosecond precision)
// ============================================================================
windowNs: 5 * 1000000000;   // 5 seconds in nanoseconds
threshold: 5;                // Minimum distinct A-numbers to trigger

// ============================================================================
// INTERNAL STATE
// ============================================================================
detection.lastGC:.z.P;          // Last garbage collection time
detection.processedCount:0;     // Total calls processed
detection.alertCount:0;         // Total alerts generated
detection.latencies:();         // Recent detection latencies for metrics

// ============================================================================
// CORE DETECTION FUNCTION
// Check if B-number is under masking attack
// Returns: (isMasking; involvedANumbers)
// ============================================================================
checkMasking:{[bNum; currentTs]
    windowStart: currentTs - windowNs;

    // Get recent unflagged calls to this B-number
    recent: select from calls
        where b_number = bNum,
              ts within (windowStart; currentTs),
              not flagged;

    // Count distinct A-numbers
    distinctA: distinct recent`a_number;

    // Return (isMasking; involvedANumbers)
    $[threshold <= count distinctA;
        (1b; distinctA);
        (0b; `symbol$())]
 };

// ============================================================================
// PROCESS INCOMING CALL EVENT
// Main entry point for call processing
// ============================================================================
processCall:{[event]
    startTime:.z.P;

    // Validate required fields
    if[not all `a_number`b_number in key event;
        .log.error "Missing required fields in event";
        :(0b; 0Ng)
    ];

    // Extract and normalize fields
    callId: $[`call_id in key event; event`call_id; first 1?0Ng];
    aNum: `$detection.normalizeNumber event`a_number;
    bNum: `$detection.normalizeNumber event`b_number;
    ts: $[`ts in key event; event`ts; .z.P];

    // Check whitelist first
    if[detection.isWhitelisted[bNum; aNum];
        :(0b; 0Ng)
    ];

    // Check if pattern is already blocked
    if[detection.isBlocked[bNum; aNum];
        :(1b; 0Ng)  // Blocked - reject call
    ];

    // Get optional fields
    switchId: $[`switch_id in key event; event`switch_id; `default];
    rawCallId: $[`raw_call_id in key event; event`raw_call_id; `$string callId];

    // Insert call into calls table
    `calls insert (callId; aNum; bNum; ts; `active; 0b; 0Ng; switchId; rawCallId);

    // Check for masking attack
    result: checkMasking[bNum; ts];

    if[result 0;
        // MASKING DETECTED - check cooldown first
        if[not detection.inCooldown bNum;
            alertId: first 1?0Ng;
            involvedA: result 1;
            windowStart: ts - windowNs;

            // Get call IDs to disconnect
            toFlag: select call_id, raw_call_id from calls
                where b_number = bNum,
                      a_number in involvedA,
                      ts >= windowStart,
                      not flagged;

            // Create alert
            `fraud_alerts insert (
                alertId; bNum; involvedA; toFlag`call_id; toFlag`raw_call_id;
                count toFlag; windowStart; ts;
                `detected; 0i; .z.P; .z.P; 0Np; `$"");

            // Flag calls
            update flagged:1b, alert_id:alertId from `calls
                where call_id in toFlag`call_id;

            // Set cooldown
            detection.setCooldown bNum;

            // Update counters
            detection.alertCount+:1;

            // Log alert
            .log.alert[alertId; bNum; involvedA; `detected];

            // Disconnect via switch (if auto-disconnect enabled)
            if[config.actions`auto_disconnect;
                actions.disconnect[toFlag`raw_call_id; alertId]
            ];
        ];
    ];

    // Track latency
    latency: `float$((.z.P - startTime) % 1000000);  // milliseconds
    detection.latencies,: latency;
    if[100 < count detection.latencies;
        detection.latencies: -100#detection.latencies];

    // Update counters
    detection.processedCount+:1;

    // Periodic cleanup
    detection.maybeCleanup[];

    // Return (detected; alertId or null)
    (result 0; $[result 0; alertId; 0Ng])
 };

// ============================================================================
// MAINTENANCE: Expire old records
// Run periodically (every 30 seconds recommended)
// ============================================================================
cleanup:{[]
    cutoff: .z.P - 0D00:00:30;
    delete from `calls where ts < cutoff, not flagged;

    // Also expire old blocks
    update active:0b from `blocked_patterns where expires_at < .z.P;
 };

detection.maybeCleanup:{[]
    gcInterval: config.performance`gc_interval_ms;
    if[.z.P > detection.lastGC + `ms$gcInterval;
        cleanup[];
        detection.lastGC: .z.P;
    ];
 };

// ============================================================================
// NUMBER NORMALIZATION
// ============================================================================
detection.normalizeNumber:{[num]
    numStr: $[-11h = type num; num; string num];
    // Remove common formatting characters
    numStr: ssr[numStr; " "; ""];
    numStr: ssr[numStr; "-"; ""];
    numStr: ssr[numStr; "("; ""];
    numStr: ssr[numStr; ")"; ""];
    numStr: ssr[numStr; "."; ""];
    numStr
 };

// ============================================================================
// WHITELIST CHECKING
// ============================================================================
detection.isWhitelisted:{[bNum; aNum]
    // Check B-number whitelist
    if[bNum in config.whitelist`b_numbers; :1b];

    // Check A-number prefix whitelist
    aStr: string aNum;
    prefixes: config.whitelist`a_number_prefixes;
    if[any {x like y,"*"}[aStr] each string prefixes; :1b];

    0b
 };

// ============================================================================
// BLOCK CHECKING
// ============================================================================
detection.isBlocked:{[bNum; aNum]
    blocks: select from blocked_patterns
        where b_number = bNum, active, expires_at > .z.P;
    count[blocks] > 0
 };

// ============================================================================
// COOLDOWN MANAGEMENT
// ============================================================================
detection.inCooldown:{[bNum]
    cooldownSecs: config.detection`cooldown_seconds;
    cutoff: .z.P - `second$cooldownSecs;

    cd: cooldowns bNum;
    if[null cd; :0b];

    cd[`last_alert_at] > cutoff
 };

detection.setCooldown:{[bNum]
    `cooldowns upsert (bNum; .z.P; 1i);
 };

// ============================================================================
// QUERY FUNCTIONS
// ============================================================================
// Get current threat level for a B-number
detection.getThreatLevel:{[bNum]
    windowStart: .z.P - windowNs;

    recent: select from calls
        where b_number = bNum,
              ts > windowStart,
              status in `active`ringing;

    distinctCount: count distinct recent`a_number;

    level: $[distinctCount >= threshold; `critical;
             distinctCount >= threshold - 1; `high;
             distinctCount >= threshold - 2; `medium;
             `low];

    `b_number`distinct_a`threshold`level`call_count!(
        bNum; distinctCount; threshold; level; count recent)
 };

// Get all B-numbers with elevated threat levels
detection.getElevatedThreats:{[]
    windowStart: .z.P - windowNs;

    recent: select from calls
        where ts > windowStart, status in `active`ringing;

    threats: select distinct_a: count distinct a_number,
                    call_count: count i
             by b_number from recent;

    threats: select from threats where distinct_a >= threshold - 2;

    update level: {$[x >= y; `critical; x >= y-1; `high; `medium]}[distinct_a; threshold]
        from threats
 };

// Get recent alerts
detection.getRecentAlerts:{[minutes]
    cutoff: .z.P - `minute$minutes;
    select from fraud_alerts where created_at > cutoff
 };

// Get alert details
detection.getAlertDetails:{[alertId]
    alert: select from fraud_alerts where alert_id = alertId;
    if[0 = count alert; :`error`alert_not_found];

    associatedCalls: select from calls where alert_id = alertId;

    `alert`calls!(first alert; associatedCalls)
 };

// ============================================================================
// STATISTICS
// ============================================================================
detection.getStats:{[]
    windowStart: .z.P - windowNs;

    activeCalls: count select from calls
        where ts > windowStart, status in `active`ringing;

    avgLatency: avg detection.latencies;
    maxLatency: max detection.latencies;

    `processed_total`alerts_total`active_calls`avg_latency_ms`max_latency_ms`calls_in_table`alerts_in_table!(
        detection.processedCount;
        detection.alertCount;
        activeCalls;
        avgLatency;
        maxLatency;
        count calls;
        count fraud_alerts)
 };

detection.recordStats:{[]
    stats: detection.getStats[];
    `stats insert (
        .z.P;
        detection.processedCount;
        detection.alertCount;
        0i;  // disconnected count
        stats`avg_latency_ms;
        stats`max_latency_ms;
        stats`active_calls;
        (-22!calls) % 1048576);
 };

// ============================================================================
// BATCH PROCESSING
// ============================================================================
detection.processBatch:{[events]
    results: processCall each events;
    detected: sum results[;0];
    .log.info "Batch processed: ", string[count events], " events, ",
              string[detected], " detections";
    results
 };

// ============================================================================
// RUNTIME CONFIG UPDATES
// Update threshold/window without restart
// ============================================================================
setThreshold:{[n]
    if[not n within 2 100;
        .log.error "Threshold must be between 2 and 100";
        :0b];
    threshold:: n;
    config.detection[`min_distinct_a]: n;
    .log.info "Threshold updated to ", string n;
    1b
 };

setWindow:{[seconds]
    if[not seconds within 1 60;
        .log.error "Window must be between 1 and 60 seconds";
        :0b];
    windowNs:: seconds * 1000000000;
    config.detection[`window_seconds]: seconds;
    .log.info "Window updated to ", string[seconds], " seconds";
    1b
 };

\d .

// Export to root namespace
processCall: .fraud.processCall;
checkMasking: .fraud.checkMasking;

0N!"[INFO] detection.q loaded successfully";
