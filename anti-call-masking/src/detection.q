// detection.q - Core fraud detection algorithm
// Anti-Call Masking Detection System
// ===================================
// Implements sliding window detection for multicall masking attacks

\d .fraud

// ============================================================================
// INTERNAL STATE
// ============================================================================
detection.lastGC:.z.P;          // Last garbage collection time
detection.processedCount:0;     // Total calls processed
detection.alertCount:0;         // Total alerts generated
detection.latencies:();         // Recent detection latencies for metrics

// ============================================================================
// CORE DETECTION FUNCTION
// Main entry point for processing call events
// ============================================================================
// Input: Dictionary with keys: call_id, a_number, b_number, ts, switch_id, raw_call_id
// Output: Dictionary with keys: detected (boolean), alert_id (guid or null)
processCall:{[event]
    startTime:.z.P;

    // Validate required fields
    required:`a_number`b_number;
    if[not all required in key event;
        0N!"[ERROR] Missing required fields: ",", " sv string required except key event;
        :([]detected:0b;alert_id:0Ng;error:`missing_fields)
    ];

    // Generate call_id if not provided
    callId:$[`call_id in key event;event`call_id;first 1?0Ng];

    // Get current timestamp
    ts:$[`ts in key event;event`ts;.z.P];

    // Normalize numbers (remove any formatting)
    aNum:`$detection.normalizeNumber event`a_number;
    bNum:`$detection.normalizeNumber event`b_number;

    // Check whitelist
    if[detection.isWhitelisted[bNum;aNum];
        :([]detected:0b;alert_id:0Ng;reason:`whitelisted)
    ];

    // Check if pattern is already blocked
    if[detection.isBlocked[bNum;aNum];
        // Auto-reject if blocked
        :([]detected:1b;alert_id:0Ng;reason:`blocked;action:`reject)
    ];

    // Get switch info
    switchId:$[`switch_id in key event;event`switch_id;`default];
    rawCallId:$[`raw_call_id in key event;event`raw_call_id;`$string callId];

    // Insert call into calls table
    `.fraud.calls upsert (callId;aNum;bNum;ts;`active;0b;0Ng;switchId;rawCallId);

    // Run detection algorithm
    result:detection.checkThreshold[bNum;ts];

    // Track latency
    latency:`float$((.z.P - startTime)%1000000);  // Convert to milliseconds
    detection.latencies,:latency;
    if[100<count detection.latencies;detection.latencies:(-100)#detection.latencies];

    // Update counters
    detection.processedCount+:1;

    // Run periodic garbage collection
    detection.maybeGC[];

    result
 };

// ============================================================================
// THRESHOLD DETECTION
// Check if B-number exceeds distinct A-number threshold in window
// ============================================================================
detection.checkThreshold:{[bNum;ts]
    // Get configuration
    windowSecs:config.detection`window_seconds;
    threshold:config.detection`min_distinct_a;

    // Calculate window boundaries
    windowStart:ts - `second$windowSecs;
    windowEnd:ts;

    // Query calls for this B-number in window
    // Using sorted attribute on ts for efficiency
    windowCalls:select from calls where
        b_number=bNum,
        ts within (windowStart;windowEnd),
        status in `active`ringing;

    // Count distinct A-numbers
    distinctANumbers:distinct windowCalls`a_number;
    distinctCount:count distinctANumbers;

    // Check threshold
    if[distinctCount>=threshold;
        // Check cooldown first
        if[detection.inCooldown bNum;
            :([]detected:1b;alert_id:0Ng;reason:`cooldown;distinct_a:distinctCount)
        ];

        // Generate alert
        alertId:first 1?0Ng;
        callIds:windowCalls`call_id;
        rawCallIds:windowCalls`raw_call_id;

        // Create fraud alert record
        alert:(alertId;bNum;distinctANumbers;callIds;rawCallIds;count windowCalls;
               windowStart;windowEnd;`detected;0i;.z.P;.z.P;0Np;`$"");
        `.fraud.fraud_alerts upsert alert;

        // Flag all involved calls
        update flagged:1b, alert_id:alertId from `.fraud.calls where call_id in callIds;

        // Update cooldown
        detection.setCooldown bNum;

        // Increment alert counter
        detection.alertCount+:1;

        // Log alert
        0N!"[ALERT] Multicall masking detected! B-number: ",string[bNum],
           ", Distinct A-numbers: ",string[distinctCount],
           ", Calls: ",string[count windowCalls];

        // Trigger action if auto-disconnect enabled
        if[config.actions`auto_disconnect;
            .fraud.actions.triggerDisconnect[alertId]
        ];

        :([]detected:1b;alert_id:alertId;distinct_a:distinctCount;call_count:count windowCalls)
    ];

    // No fraud detected
    ([]detected:0b;alert_id:0Ng;distinct_a:distinctCount;call_count:count windowCalls)
 };

// ============================================================================
// NUMBER NORMALIZATION
// Normalize phone numbers to E.164 format
// ============================================================================
detection.normalizeNumber:{[num]
    numStr:$[-11h=type num;num;string num];

    // Remove common formatting characters
    numStr:ssr[numStr;" ";""];
    numStr:ssr[numStr;"-";""];
    numStr:ssr[numStr;"(";""];
    numStr:ssr[numStr;")";""];
    numStr:ssr[numStr;".";""];

    // Ensure starts with + for international format
    // If no +, assume it's already normalized
    numStr
 };

// ============================================================================
// WHITELIST CHECKING
// ============================================================================
detection.isWhitelisted:{[bNum;aNum]
    // Check B-number whitelist
    if[bNum in config.whitelist`b_numbers;:1b];

    // Check A-number prefix whitelist
    aStr:string aNum;
    prefixes:config.whitelist`a_number_prefixes;
    if[any {x like y,"*"}[aStr] each string prefixes;:1b];

    0b
 };

// ============================================================================
// BLOCK CHECKING
// ============================================================================
detection.isBlocked:{[bNum;aNum]
    // Check if B-number has active block
    blocks:select from blocked_patterns where b_number=bNum, active, expires_at>.z.P;
    count[blocks]>0
 };

// ============================================================================
// COOLDOWN MANAGEMENT
// ============================================================================
detection.inCooldown:{[bNum]
    cooldownSecs:config.detection`cooldown_seconds;
    cutoff:.z.P - `second$cooldownSecs;

    cd:cooldowns bNum;
    if[null cd;:0b];

    cd[`last_alert_at]>cutoff
 };

detection.setCooldown:{[bNum]
    // Upsert cooldown record
    `.fraud.cooldowns upsert (bNum;.z.P;1i);
 };

// ============================================================================
// GARBAGE COLLECTION
// ============================================================================
detection.maybeGC:{[]
    gcInterval:config.performance`gc_interval_ms;
    if[.z.P > detection.lastGC + `ms$gcInterval;
        detection.runGC[];
    ];
 };

detection.runGC:{[]
    windowSecs:config.detection`window_seconds;
    // Keep 2x window for safety
    .fraud.expireCalls 2*windowSecs;
    .fraud.expireBlocks[];
    detection.lastGC:.z.P;
 };

// ============================================================================
// QUERY FUNCTIONS
// ============================================================================
// Get current threat level for a B-number
detection.getThreatLevel:{[bNum]
    windowSecs:config.detection`window_seconds;
    threshold:config.detection`min_distinct_a;
    windowStart:.z.P - `second$windowSecs;

    windowCalls:select from calls where
        b_number=bNum,
        ts>windowStart,
        status in `active`ringing;

    distinctCount:count distinct windowCalls`a_number;

    level:$[distinctCount>=threshold;`critical;
            distinctCount>=threshold-1;`high;
            distinctCount>=threshold-2;`medium;
            `low];

    ([]b_number:bNum;distinct_a:distinctCount;threshold;level;call_count:count windowCalls)
 };

// Get all B-numbers with elevated threat levels
detection.getElevatedThreats:{[]
    windowSecs:config.detection`window_seconds;
    threshold:config.detection`min_distinct_a;
    windowStart:.z.P - `second$windowSecs;

    windowCalls:select from calls where
        ts>windowStart,
        status in `active`ringing;

    threats:select distinct_a:count distinct a_number, call_count:count i by b_number from windowCalls;
    threats:select from threats where distinct_a>=threshold-2;

    update level:{$[x>=y;`critical;x>=y-1;`high;`medium]}[distinct_a;threshold] from threats
 };

// Get recent alerts
detection.getRecentAlerts:{[minutes]
    cutoff:.z.P - `minute$minutes;
    select from fraud_alerts where created_at>cutoff
 };

// Get alert details
detection.getAlertDetails:{[alertId]
    alert:select from fraud_alerts where alert_id=alertId;
    if[0=count alert;:([]error:`alert_not_found)];

    // Get associated calls
    associatedCalls:select from calls where alert_id=alertId;

    `alert`calls!(first alert;associatedCalls)
 };

// ============================================================================
// STATISTICS
// ============================================================================
detection.getStats:{[]
    windowSecs:config.detection`window_seconds;
    windowStart:.z.P - `second$windowSecs;

    activeCalls:count select from calls where ts>windowStart, status in `active`ringing;
    avgLatency:avg detection.latencies;
    maxLatency:max detection.latencies;

    ([]
        processed_total:detection.processedCount;
        alerts_total:detection.alertCount;
        active_calls:activeCalls;
        avg_latency_ms:avgLatency;
        max_latency_ms:maxLatency;
        calls_in_table:count calls;
        alerts_in_table:count fraud_alerts
    )
 };

detection.recordStats:{[]
    stats:detection.getStats[];
    `.fraud.stats upsert (
        .z.P;
        detection.processedCount;
        detection.alertCount;
        0i;  // disconnected (filled by actions)
        first stats`avg_latency_ms;
        first stats`max_latency_ms;
        first stats`active_calls;
        (-22!.fraud.calls)%1048576
    );
 };

// ============================================================================
// BATCH PROCESSING
// Process multiple events at once (for testing/replay)
// ============================================================================
detection.processBatch:{[events]
    results:processCall each events;
    detected:sum results[`detected];
    0N!"[INFO] Batch processed: ",string[count events]," events, ",string[detected]," detections";
    results
 };

\d .

// Export main function to root namespace
processCall:.fraud.processCall;

0N!"[INFO] detection.q loaded successfully";
