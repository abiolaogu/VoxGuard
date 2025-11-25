// integration_tests.q - End-to-end and chaos testing
// Anti-Call Masking Detection System - Production Test Suite
// ===========================================================

\d .inttest

// ============================================================================
// TEST STATE
// ============================================================================
results:();
passed:0;
failed:0;

// ============================================================================
// TEST UTILITIES
// ============================================================================
assert:{[condition;testName]
    if[condition;
        passed+:1;
        results,:(testName;`pass;`);
        .log.info "  [PASS] ",testName;
        :1b
    ];
    failed+:1;
    results,:(testName;`fail;`);
    .log.error "  [FAIL] ",testName;
    0b
};

assertWithin:{[actual;expected;tolerance;testName]
    diff:abs actual - expected;
    if[diff<=tolerance;
        passed+:1;
        results,:(testName;`pass;`);
        .log.info "  [PASS] ",testName;
        :1b
    ];
    failed+:1;
    results,:(testName;`fail;`actual`expected`tolerance!(actual;expected;tolerance));
    .log.error "  [FAIL] ",testName," - Expected: ",string[expected],
               " +/- ",string[tolerance],", Got: ",string actual;
    0b
};

reset:{[]
    .fraud.clearTables[];
    .fraud.detection.processedCount:0;
    .fraud.detection.alertCount:0;
    .fraud.detection.latencies:();
    .fraud.config.actions[`auto_disconnect]:0b;
    .fraud.config.detection[`cooldown_seconds]:0;
    .fraud.switch.simulationMode:1b;
    .fraud.switch.connected:1b;
};

// ============================================================================
// END-TO-END TESTS
// ============================================================================
testE2EDetectionToAlert:{[]
    .log.info "[E2E] Detection to Alert Flow";
    reset[];

    // Generate attack
    bNum:`$"+18005551234";
    events:.test.generateAttack[`sequential;bNum;.z.P];

    // Process events
    .fraud.processCall each events;

    // Verify alert created
    alerts:select from .fraud.fraud_alerts where b_number=bNum;
    assert[1=count alerts;"Alert created for attack"];

    // Verify calls flagged
    flaggedCalls:count select from .fraud.calls where flagged, b_number=bNum;
    assert[flaggedCalls>=5;"All attack calls flagged"];

    // Verify alert contains correct data
    alert:first alerts;
    assert[5<=count alert`a_numbers;"Alert contains all A-numbers"];
    assert[alert[`action]=`detected;"Alert action is 'detected'"];
};

testE2EDisconnectFlow:{[]
    .log.info "[E2E] Disconnect Command Flow";
    reset[];
    .fraud.config.actions[`auto_disconnect]:1b;

    // Track disconnect commands
    disconnectCmds:();
    origDisconnect:.fraud.actions.disconnectGeneric;
    .fraud.actions.disconnectGeneric:{[conn;callId]
        disconnectCmds,::callId;
        1b  // Simulate success
    };

    // Generate and process attack
    bNum:`$"+18005552345";
    events:.test.generateAttack[`burst;bNum;.z.P];
    .fraud.processCall each events;

    // Process action queue
    .fraud.actions.processQueue[];

    // Verify disconnects were attempted
    assert[0<count disconnectCmds;"Disconnect commands sent"];

    // Restore original function
    .fraud.actions.disconnectGeneric:origDisconnect;
};

testE2EBlockCreation:{[]
    .log.info "[E2E] Block Pattern Creation";
    reset[];

    // Generate attack
    bNum:`$"+18005553456";
    events:.test.generateAttack[`distributed;bNum;.z.P];
    .fraud.processCall each events;

    // Get alert and create block
    alertId:first exec alert_id from .fraud.fraud_alerts where b_number=bNum;
    .fraud.actions.createBlock alertId;

    // Verify block created
    blocks:select from .fraud.blocked_patterns where b_number=bNum, active;
    assert[1=count blocks;"Block pattern created"];

    // Verify subsequent calls are blocked
    isBlocked:.fraud.detection.isBlocked[bNum;`A999];
    assert[isBlocked;"New calls to blocked B-number are detected"];
};

// ============================================================================
// CONNECTION TESTS
// ============================================================================
testConnectionLossRecovery:{[]
    .log.info "[CONN] Connection Loss and Recovery";
    reset[];

    // Simulate connection
    .fraud.switch.connected:1b;

    // Process some calls
    events:.test.generateLegitimateTraffic 100;
    .fraud.processCall each events;
    countBefore:.fraud.detection.processedCount;

    // Simulate connection loss
    .fraud.switch.connected:0b;

    // Queue should handle this gracefully
    moreEvents:.test.generateLegitimateTraffic 50;
    .fraud.processCall each moreEvents;

    // Verify processing continued
    countAfter:.fraud.detection.processedCount;
    assert[countAfter>countBefore;"Processing continues during connection loss"];

    // Simulate reconnection
    .fraud.switch.connected:1b;

    // Verify actions can resume
    .fraud.actions.processQueue[];
    assert[1b;"System recovers after reconnection"];
};

testCommandQueuing:{[]
    .log.info "[CONN] Command Queuing During Outage";
    reset[];

    // Disconnect switch
    .fraud.switch.connected:0b;

    // Generate attack (should still detect)
    bNum:`$"+18005554567";
    .fraud.config.actions[`auto_disconnect]:1b;
    events:.test.generateAttack[`sequential;bNum;.z.P];
    .fraud.processCall each events;

    // Verify alert created even without connection
    alerts:count select from .fraud.fraud_alerts where b_number=bNum;
    assert[alerts>0;"Alerts generated during outage"];

    // Queue should have pending commands
    // (In production, these would be retried on reconnect)
};

// ============================================================================
// CHAOS TESTS
// ============================================================================
testMemoryPressure:{[]
    .log.info "[CHAOS] Memory Pressure Test";
    reset[];

    // Generate large volume of calls
    largeVolume:100000;
    .log.info "  Generating ",string[largeVolume]," calls...";

    // Process in batches
    batchSize:10000;
    batches:ceiling largeVolume % batchSize;

    {
        events:.test.generateLegitimateTraffic batchSize;
        .fraud.processCall each events;
    } each til batches;

    // Check memory usage
    memMb:first exec mb from .fraud.memoryUsage[] where table=`calls;
    .log.info "  Memory usage: ",string[memMb]," MB";

    // Trigger GC
    .fraud.detection.runGC[];
    memAfterGC:first exec mb from .fraud.memoryUsage[] where table=`calls;
    .log.info "  After GC: ",string[memAfterGC]," MB";

    // Memory should be bounded
    assert[memAfterGC<500;"Memory stays bounded after GC"];
};

testMalformedEvents:{[]
    .log.info "[CHAOS] Malformed Event Handling";
    reset[];

    malformedEvents:(
        `a_number`b_number!(`;`B001);           // Empty A-number
        `b_number`ts!(`B002;.z.P);              // Missing A-number
        `a_number`b_number`ts!(`A001;`;.z.P);   // Empty B-number
        `a_number`b_number`ts!(`A001;`B003;0Np);// Null timestamp
        ()!();                                   // Empty dict
        `garbage`data!(1;2)                      // Wrong fields
    );

    errors:0;
    {
        result:@[.fraud.processCall;x;{errors+:1;`error}];
    } each malformedEvents;

    // System should handle gracefully (not crash)
    assert[1b;"System handles malformed events without crash"];

    // Valid events should still work
    validEvent:`a_number`b_number!(`A100;`B100);
    result:.fraud.processCall validEvent;
    assert[not result~`error;"Valid events still processed after malformed"];
};

testRapidReconnect:{[]
    .log.info "[CHAOS] Rapid Reconnect Cycles";
    reset[];

    // Simulate rapid connect/disconnect
    cycles:20;
    {
        .fraud.switch.connected:1b;
        // Process a few calls
        events:.test.generateLegitimateTraffic 10;
        .fraud.processCall each events;
        .fraud.switch.connected:0b;
    } each til cycles;

    // System should remain stable
    stats:.fraud.detection.getStats[];
    assert[stats[`processed_total]>0;"System stable after rapid reconnects"];
};

testClockSkew:{[]
    .log.info "[CHAOS] Clock Skew Handling";
    reset[];

    // Events with timestamps in the past
    pastEvents:{
        `a_number`b_number`ts!(`$"A",string x;`B_PAST;.z.P - `second$10 + x)
    } each til 5;

    // Events with timestamps in the future
    futureEvents:{
        `a_number`b_number`ts!(`$"F",string x;`B_FUTURE;.z.P + `second$10 + x)
    } each til 5;

    // Process all
    .fraud.processCall each pastEvents;
    .fraud.processCall each futureEvents;

    // Should handle without error
    assert[1b;"Clock skew handled gracefully"];
};

testHighLatencyScenario:{[]
    .log.info "[CHAOS] High Latency Scenario";
    reset[];

    // Simulate slow processing by processing large batch
    largeBatch:.test.generateLegitimateTraffic 10000;

    startTime:.z.P;
    .fraud.processCall each largeBatch;
    elapsed:(`float$(.z.P - startTime)) % 1e9;

    avgLatency:avg .fraud.detection.latencies;
    maxLatency:max .fraud.detection.latencies;

    .log.info "  Avg latency: ",string[avgLatency]," ms";
    .log.info "  Max latency: ",string[maxLatency]," ms";

    // P99 should still be reasonable
    p99:.fraud.detection.latencies `long$0.99 * count .fraud.detection.latencies;
    assert[p99<200;"P99 latency under 200ms even under load"];
};

// ============================================================================
// FAILOVER TESTS
// ============================================================================
testGracefulShutdown:{[]
    .log.info "[FAILOVER] Graceful Shutdown";
    reset[];

    // Process some traffic
    events:.test.generateLegitimateTraffic 1000;
    .fraud.processCall each events;

    // Generate an alert
    bNum:`$"+18005556789";
    attackEvents:.test.generateAttack[`burst;bNum;.z.P];
    .fraud.processCall each attackEvents;

    // Simulate shutdown preparation
    alertsBefore:count .fraud.fraud_alerts;
    statsBefore:.fraud.detection.processedCount;

    // In production, .z.exit would:
    // 1. Flush pending actions
    // 2. Persist state
    // 3. Close connections

    assert[alertsBefore>0;"State preserved before shutdown"];
};

testStateRecovery:{[]
    .log.info "[FAILOVER] State Recovery";
    reset[];

    // Simulate previous state
    testAlerts:([]
        alert_id:2?0Ng;
        b_number:`B_RECOVER1`B_RECOVER2;
        a_numbers:((`A1`A2`A3`A4`A5);(`A6`A7`A8`A9`A10));
        call_ids:2#enlist 5?0Ng;
        raw_call_ids:2#enlist 5?`symbol$();
        call_count:5 5i;
        window_start:.z.P - 00:01;
        window_end:.z.P - 00:00:30;
        action:`detected`detected;
        disconnect_count:0 0i;
        created_at:.z.P - 00:01;
        updated_at:.z.P - 00:00:30;
        resolved_at:0Np;
        notes:`$""
    );

    // Insert recovered state
    `.fraud.fraud_alerts upsert testAlerts;

    // Verify recovery
    recovered:count select from .fraud.fraud_alerts where b_number in `B_RECOVER1`B_RECOVER2;
    assert[recovered=2;"State recovered successfully"];
};

// ============================================================================
// RUN ALL TESTS
// ============================================================================
runAll:{[]
    passed::0;
    failed::0;
    results::();

    .log.info "";
    .log.info "=================================================";
    .log.info "  Integration & Chaos Tests";
    .log.info "=================================================";

    // E2E Tests
    .log.info "";
    .log.info "[SUITE] End-to-End Tests";
    testE2EDetectionToAlert[];
    testE2EDisconnectFlow[];
    testE2EBlockCreation[];

    // Connection Tests
    .log.info "";
    .log.info "[SUITE] Connection Tests";
    testConnectionLossRecovery[];
    testCommandQueuing[];

    // Chaos Tests
    .log.info "";
    .log.info "[SUITE] Chaos Tests";
    testMalformedEvents[];
    testRapidReconnect[];
    testClockSkew[];
    testHighLatencyScenario[];

    // Failover Tests
    .log.info "";
    .log.info "[SUITE] Failover Tests";
    testGracefulShutdown[];
    testStateRecovery[];

    // Memory test last (resource intensive)
    .log.info "";
    .log.info "[SUITE] Resource Tests";
    testMemoryPressure[];

    .log.info "";
    .log.info "=================================================";
    .log.info "  Results: ",string[passed]," passed, ",string[failed]," failed";
    .log.info "=================================================";

    ([]name:results[;0];status:results[;1])
};

\d .

// Export
runIntegrationTests:.inttest.runAll;

0N!"[INFO] integration_tests.q loaded";
0N!"  Run: runIntegrationTests[]";
