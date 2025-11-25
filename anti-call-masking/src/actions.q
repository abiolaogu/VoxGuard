// actions.q - Call disconnect and block handlers
// Anti-Call Masking Detection System
// ===================================
// Handles automated responses to detected fraud

\d .fraud

// ============================================================================
// ACTION QUEUE
// Async queue for disconnect commands
// ============================================================================
actions.queue:();                   // Pending disconnect commands
actions.inProgress:0b;              // Whether processing is in progress
actions.disconnectCount:0;          // Total disconnects executed
actions.failedCount:0;              // Failed disconnect attempts

// ============================================================================
// DIRECT DISCONNECT (Reference Implementation Style)
// Disconnect calls and update alert
// ============================================================================
actions.disconnect:{[callIds; alertId]
    // Update alert status
    update action:`disconnecting, updated_at:.z.P from `fraud_alerts
        where alert_id = alertId;

    // Send disconnect to each call via switch
    results: {[cid; aid]
        success: switch.sendDisconnect[cid];
        if[success;
            update status:`disconnected from `calls where raw_call_id = cid;
            actions.disconnectCount+: 1;
            .log.disconnect[aid; cid; 1b]
        ];
        success
    }[; alertId] each callIds;

    // Update alert with disconnect count
    update disconnect_count: sum results,
           action: `completed,
           resolved_at: .z.P,
           updated_at: .z.P
        from `fraud_alerts where alert_id = alertId;

    // Create block pattern
    actions.createBlock[alertId];

    sum results
 };

// ============================================================================
// TRIGGER DISCONNECT (Legacy/Queue-based)
// Entry point to disconnect all calls associated with an alert
// ============================================================================
actions.triggerDisconnect:{[alertId]
    // Get alert details
    alert: exec from fraud_alerts where alert_id = alertId;
    if[0 = count alert;
        .log.error "Alert not found: ", string alertId;
        :0b
    ];

    // Get call IDs to disconnect
    rawCallIds: first alert`raw_call_ids;
    if[0 = count rawCallIds;
        .log.warn "No calls to disconnect for alert: ", string alertId;
        :0b
    ];

    // Use direct disconnect
    actions.disconnect[rawCallIds; alertId]
 };

// ============================================================================
// QUEUE MANAGEMENT
// ============================================================================
actions.queueDisconnect:{[rawCallId;alertId;bNum]
    cmd:`rawCallId`alertId`bNum`timestamp`attempts`status!(
        rawCallId;alertId;bNum;.z.P;0i;`pending
    );
    actions.queue,:enlist cmd;
 };

actions.processQueue:{[]
    if[actions.inProgress;:0N];
    if[0=count actions.queue;:0N];

    actions.inProgress:1b;

    // Process each pending command
    pending:actions.queue where actions.queue[;`status]=`pending;
    {actions.executeDisconnect x} each pending;

    // Remove completed/failed items (keep for a short time for monitoring)
    actions.queue:actions.queue where actions.queue[;`status]=`pending;

    actions.inProgress:0b;
 };

// ============================================================================
// EXECUTE DISCONNECT
// Send disconnect command to switch
// ============================================================================
actions.executeDisconnect:{[cmd]
    rawCallId:cmd`rawCallId;
    alertId:cmd`alertId;

    // Get switch connection
    switchConn:.fraud.switch.getConnection[];

    if[null switchConn;
        0N!"[ERROR] No switch connection available";
        // Update command status
        actions.updateQueueItem[rawCallId;`failed];
        actions.failedCount+:1;
        :0b
    ];

    // Send disconnect based on protocol
    protocol:config.switch`protocol;
    result:$[
        protocol=`freeswitch;actions.disconnectFreeSWITCH[switchConn;rawCallId];
        protocol=`kamailio;actions.disconnectKamailio[switchConn;rawCallId];
        protocol=`generic;actions.disconnectGeneric[switchConn;rawCallId];
        actions.disconnectGeneric[switchConn;rawCallId]
    ];

    if[result;
        // Success - update statuses
        actions.updateQueueItem[rawCallId;`completed];
        update status:`disconnected, updated_at:.z.P from `.fraud.calls
            where raw_call_id=rawCallId;

        // Update alert disconnect count
        update disconnect_count:disconnect_count+1i, updated_at:.z.P
            from `.fraud.fraud_alerts where alert_id=alertId;

        actions.disconnectCount+:1;
        0N!"[ACTION] Disconnected call: ",string rawCallId;
        :1b
    ];

    // Failed
    actions.updateQueueItem[rawCallId;`failed];
    actions.failedCount+:1;
    0N!"[ERROR] Failed to disconnect call: ",string rawCallId;
    0b
 };

actions.updateQueueItem:{[rawCallId;newStatus]
    idx:first where actions.queue[;`rawCallId]=rawCallId;
    if[not null idx;
        actions.queue[idx;`status]:newStatus;
        actions.queue[idx;`attempts]+:1i;
    ];
 };

// ============================================================================
// PROTOCOL-SPECIFIC DISCONNECT IMPLEMENTATIONS
// ============================================================================

// FreeSWITCH Event Socket Layer
actions.disconnectFreeSWITCH:{[conn;rawCallId]
    // uuid_kill command
    cmd:"api uuid_kill ",string[rawCallId]," CALL_REJECTED\n\n";

    result:@[{neg[x]y;1b};(conn;cmd);{0N!"[ERROR] ESL send failed: ",x;0b}];
    result
 };

// Kamailio MI/RPC
actions.disconnectKamailio:{[conn;rawCallId]
    // JSON-RPC dlg.end_dlg command
    jsonCmd:"{\"jsonrpc\":\"2.0\",\"method\":\"dlg.end_dlg\",\"params\":{\"callid\":\"",
             string[rawCallId],"\"},\"id\":1}";

    result:@[{neg[x]y;1b};(conn;jsonCmd);{0N!"[ERROR] Kamailio send failed: ",x;0b}];
    result
 };

// Generic SIP BYE
actions.disconnectGeneric:{[conn;rawCallId]
    // This would typically be handled by a SIP stack
    // For now, send a simple command format
    cmd:"DISCONNECT ",string[rawCallId],"\n";

    result:@[{neg[x]y;1b};(conn;cmd);{0N!"[ERROR] Generic send failed: ",x;0b}];
    result
 };

// ============================================================================
// BLOCK PATTERN MANAGEMENT
// ============================================================================
actions.createBlock:{[alertId]
    // Get alert details
    alert:exec from fraud_alerts where alert_id=alertId;
    if[0=count alert;:0b];

    bNum:first alert`b_number;
    aNumbers:first alert`a_numbers;
    blockDuration:config.actions`block_duration_seconds;

    blockId:first 1?0Ng;
    expiresAt:.z.P + `second$blockDuration;

    `.fraud.blocked_patterns upsert (blockId;bNum;aNumbers;alertId;.z.P;expiresAt;1b);

    0N!"[ACTION] Created block pattern for B-number: ",string[bNum],
       ", expires: ",string expiresAt;
    1b
 };

actions.removeBlock:{[blockId]
    update active:0b from `.fraud.blocked_patterns where block_id=blockId;
    0N!"[ACTION] Removed block: ",string blockId;
    1b
 };

actions.extendBlock:{[blockId;additionalSeconds]
    update expires_at:expires_at+`second$additionalSeconds from `.fraud.blocked_patterns
        where block_id=blockId;
    0N!"[ACTION] Extended block: ",string[blockId]," by ",string[additionalSeconds]," seconds";
    1b
 };

// ============================================================================
// MANUAL ACTIONS
// For operator intervention
// ============================================================================

// Manually disconnect a specific call
actions.manualDisconnect:{[rawCallId]
    switchConn:.fraud.switch.getConnection[];
    if[null switchConn;
        0N!"[ERROR] No switch connection for manual disconnect";
        :0b
    ];

    protocol:config.switch`protocol;
    result:$[
        protocol=`freeswitch;actions.disconnectFreeSWITCH[switchConn;rawCallId];
        protocol=`kamailio;actions.disconnectKamailio[switchConn;rawCallId];
        actions.disconnectGeneric[switchConn;rawCallId]
    ];

    if[result;
        update status:`disconnected from `.fraud.calls where raw_call_id=rawCallId;
        0N!"[ACTION] Manual disconnect successful: ",string rawCallId;
    ];

    result
 };

// Manually flag and disconnect all calls to a B-number
actions.manualFlagBNumber:{[bNum;reason]
    // Get active calls
    activeCalls:select from calls where b_number=bNum, status in `active`ringing;
    if[0=count activeCalls;
        0N!"[WARN] No active calls found for B-number: ",string bNum;
        :0b
    ];

    // Create manual alert
    alertId:first 1?0Ng;
    callIds:activeCalls`call_id;
    rawCallIds:activeCalls`raw_call_id;
    aNumbers:distinct activeCalls`a_number;

    alert:(alertId;bNum;aNumbers;callIds;rawCallIds;count activeCalls;
           min activeCalls`ts;.z.P;`detected;0i;.z.P;.z.P;0Np;`$"manual:",reason);
    `.fraud.fraud_alerts upsert alert;

    // Flag calls
    update flagged:1b, alert_id:alertId from `.fraud.calls where call_id in callIds;

    // Trigger disconnect
    actions.triggerDisconnect alertId;

    0N!"[ACTION] Manual flag created for B-number: ",string[bNum],
       ", calls: ",string count activeCalls;
    alertId
 };

// Add B-number to whitelist
actions.addToWhitelist:{[bNum]
    current:config.whitelist`b_numbers;
    if[bNum in current;
        0N!"[WARN] B-number already whitelisted: ",string bNum;
        :0b
    ];

    .fraud.config.whitelist[`b_numbers],:bNum;
    0N!"[ACTION] Added to whitelist: ",string bNum;
    1b
 };

// Remove B-number from whitelist
actions.removeFromWhitelist:{[bNum]
    current:config.whitelist`b_numbers;
    if[not bNum in current;
        0N!"[WARN] B-number not in whitelist: ",string bNum;
        :0b
    ];

    .fraud.config.whitelist[`b_numbers]:current except bNum;
    0N!"[ACTION] Removed from whitelist: ",string bNum;
    1b
 };

// ============================================================================
// NOTIFICATION HANDLERS
// ============================================================================
actions.sendNotification:{[alertId;notificationType]
    if[not config.actions`notify_enabled;:0N];

    alert:exec from fraud_alerts where alert_id=alertId;
    if[0=count alert;:0N];

    // Build notification message
    msg:`alertId`type`b_number`a_numbers`call_count`timestamp!(
        alertId;
        notificationType;
        first alert`b_number;
        first alert`a_numbers;
        first alert`call_count;
        .z.P
    );

    // Log notification (in production, this would go to external system)
    0N!"[NOTIFY] ",notificationType,": ",-3!msg;

    // Could integrate with:
    // - Email via SMTP
    // - Slack/Teams webhook
    // - PagerDuty
    // - SMS gateway
    // - SNMP trap
 };

// ============================================================================
// ALERT LIFECYCLE MANAGEMENT
// ============================================================================
actions.completeAlert:{[alertId]
    update action:`completed, resolved_at:.z.P, updated_at:.z.P
        from `.fraud.fraud_alerts where alert_id=alertId;

    // Send completion notification
    actions.sendNotification[alertId;`completed];

    0N!"[ACTION] Alert completed: ",string alertId;
    1b
 };

actions.failAlert:{[alertId;reason]
    update action:`failed, notes:`$reason, updated_at:.z.P
        from `.fraud.fraud_alerts where alert_id=alertId;

    actions.sendNotification[alertId;`failed];

    0N!"[ACTION] Alert failed: ",string[alertId]," - ",reason;
    1b
 };

// ============================================================================
// STATISTICS
// ============================================================================
actions.getStats:{[]
    pending:count actions.queue where actions.queue[;`status]=`pending;
    ([]
        total_disconnects:actions.disconnectCount;
        failed_disconnects:actions.failedCount;
        queue_pending:pending;
        blocks_active:count select from blocked_patterns where active
    )
 };

\d .

0N!"[INFO] actions.q loaded successfully";
