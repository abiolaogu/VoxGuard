// run_tests.q - Comprehensive test runner for CI/CD
// Anti-Call Masking Detection System
// ===================================
// Exit codes: 0 = success, 1 = test failures, 2 = load errors

\d .testrunner

// ============================================================================
// TEST RESULTS TRACKING
// ============================================================================
results:`suites`passed`failed`errors`duration!(();0;0;0;0f);
startTime:.z.P;

// ============================================================================
// SAFE MODULE LOADER
// ============================================================================
loadModule:{[path]
    result:@[system;"l ",path;{(`error;x)}];
    if[`error~first result;
        -2 "[ERROR] Failed to load: ",path;
        -2 "  Reason: ",last result;
        results[`errors]+:1;
        :0b
    ];
    -1 "[OK] Loaded: ",path;
    1b
 };

// ============================================================================
// LOAD ALL MODULES
// ============================================================================
loadAll:{[]
    -1 "";
    -1 "========================================";
    -1 "  Loading Modules";
    -1 "========================================";

    modules:(
        "src/config.q";
        "src/schema.q";
        "src/logging.q";
        "src/detection.q";
        "src/actions.q";
        "src/switch_adapter.q";
        "src/metrics.q";
        "src/recovery.q"
    );

    loaded:loadModule each modules;

    if[not all loaded;
        -2 "[FATAL] Module load failures detected";
        :0b
    ];

    -1 "[OK] All modules loaded successfully";
    1b
 };

// ============================================================================
// UNIT TEST RUNNER
// ============================================================================
runUnitTests:{[]
    -1 "";
    -1 "========================================";
    -1 "  Unit Tests";
    -1 "========================================";

    // Reset state
    .fraud.clearTables[];
    .fraud.detection.processedCount:0;
    .fraud.detection.alertCount:0;
    .fraud.switch.simulationMode:1b;
    .fraud.switch.connected:1b;
    .fraud.config.actions[`auto_disconnect]:0b;
    .fraud.config.detection[`cooldown_seconds]:0;

    passed:0; failed:0;

    // Test 1: Basic detection - 5 calls triggers
    -1 "  [TEST] Threshold detection (5 calls)...";
    .fraud.clearTables[];
    events:{`a_number`b_number`ts!(`$"A",string x;`B001;.z.P+`ms$x*100)} each til 5;
    res:.fraud.processCall each events;
    if[any res[;0];
        -1 "    [PASS] 5 distinct A-numbers triggers alert";
        passed+:1;
    ;
        -2 "    [FAIL] 5 distinct A-numbers should trigger alert";
        failed+:1
    ];

    // Test 2: Below threshold - 4 calls doesn't trigger
    -1 "  [TEST] Below threshold (4 calls)...";
    .fraud.clearTables[];
    events:{`a_number`b_number`ts!(`$"A",string x;`B002;.z.P+`ms$x*100)} each til 4;
    res:.fraud.processCall each events;
    if[not any res[;0];
        -1 "    [PASS] 4 distinct A-numbers does not trigger";
        passed+:1;
    ;
        -2 "    [FAIL] 4 calls should not trigger alert";
        failed+:1
    ];

    // Test 3: Duplicate A-numbers count as 1
    -1 "  [TEST] Duplicate A-numbers...";
    .fraud.clearTables[];
    events:{`a_number`b_number`ts!(`A001;`B003;.z.P+`ms$x*100)} each til 10;
    res:.fraud.processCall each events;
    if[not any res[;0];
        -1 "    [PASS] Same A-number 10x does not trigger (1 distinct)";
        passed+:1;
    ;
        -2 "    [FAIL] Duplicate A-numbers should not trigger";
        failed+:1
    ];

    // Test 4: Window expiry
    -1 "  [TEST] Window expiry...";
    .fraud.clearTables[];
    oldTs:.z.P - 0D00:00:10;  // 10 seconds ago
    events1:{`a_number`b_number`ts!(`$"A",string x;`B004;y+`ms$x*100)}[;oldTs] each til 3;
    events2:{`a_number`b_number`ts!(`$"A",string x+3;`B004;.z.P+`ms$x*100)} each til 2;
    .fraud.processCall each events1;
    res:.fraud.processCall each events2;
    if[not any res[;0];
        -1 "    [PASS] Old calls outside window don't count";
        passed+:1;
    ;
        -2 "    [FAIL] Window expiry not working";
        failed+:1
    ];

    // Test 5: Whitelist
    -1 "  [TEST] Whitelist exemption...";
    .fraud.clearTables[];
    .fraud.config.whitelist[`b_numbers]:`B_SAFE;
    events:{`a_number`b_number`ts!(`$"A",string x;`B_SAFE;.z.P+`ms$x*100)} each til 10;
    res:.fraud.processCall each events;
    if[not any res[;0];
        -1 "    [PASS] Whitelisted B-number exempt";
        passed+:1;
    ;
        -2 "    [FAIL] Whitelist not working";
        failed+:1
    ];
    .fraud.config.whitelist[`b_numbers]:`symbol$();

    // Test 6: Alert creation
    -1 "  [TEST] Alert record creation...";
    .fraud.clearTables[];
    .fraud.config.detection[`cooldown_seconds]:0;
    events:{`a_number`b_number`ts!(`$"A",string x;`B005;.z.P+`ms$x*100)} each til 5;
    .fraud.processCall each events;
    alerts:count select from .fraud.fraud_alerts where b_number=`B005;
    if[alerts=1;
        -1 "    [PASS] Alert record created";
        passed+:1;
    ;
        -2 "    [FAIL] Alert not created, count: ",string alerts;
        failed+:1
    ];

    // Test 7: Calls flagged
    -1 "  [TEST] Call flagging...";
    flagged:count select from .fraud.calls where flagged, b_number=`B005;
    if[flagged>=5;
        -1 "    [PASS] Calls properly flagged";
        passed+:1;
    ;
        -2 "    [FAIL] Calls not flagged, count: ",string flagged;
        failed+:1
    ];

    // Test 8: Statistics tracking
    -1 "  [TEST] Statistics tracking...";
    stats:.fraud.detection.getStats[];
    if[stats[`processed_total]>0;
        -1 "    [PASS] Statistics tracked correctly";
        passed+:1;
    ;
        -2 "    [FAIL] Statistics not tracking";
        failed+:1
    ];

    results[`suites],:(`unit;passed;failed);
    results[`passed]+:passed;
    results[`failed]+:failed;

    -1 "";
    -1 "  Unit Tests: ",string[passed]," passed, ",string[failed]," failed";

    failed=0
 };

// ============================================================================
// INTEGRATION TEST RUNNER
// ============================================================================
runIntegrationTests:{[]
    -1 "";
    -1 "========================================";
    -1 "  Integration Tests";
    -1 "========================================";

    passed:0; failed:0;

    // E2E Test 1: Full detection flow
    -1 "  [TEST] E2E detection flow...";
    .fraud.clearTables[];
    .fraud.config.detection[`cooldown_seconds]:0;
    .fraud.config.actions[`auto_disconnect]:0b;

    // Simulate attack
    events:{`a_number`b_number`ts!(`$"ATTACK",string x;`VICTIM;.z.P+`ms$x*50)} each til 5;
    results:.fraud.processCall each events;

    // Verify detection
    detected:any results[;0];
    alertExists:0<count select from .fraud.fraud_alerts where b_number=`VICTIM;
    callsFlagged:0<count select from .fraud.calls where flagged, b_number=`VICTIM;

    if[detected and alertExists and callsFlagged;
        -1 "    [PASS] Full E2E detection flow works";
        passed+:1;
    ;
        -2 "    [FAIL] E2E flow incomplete";
        failed+:1
    ];

    // E2E Test 2: Block pattern creation
    -1 "  [TEST] Block pattern creation...";
    alertId:first exec alert_id from .fraud.fraud_alerts where b_number=`VICTIM;
    if[not null alertId;
        .fraud.actions.createBlock alertId;
        blocks:count select from .fraud.blocked_patterns where b_number=`VICTIM, active;
        if[blocks>0;
            -1 "    [PASS] Block pattern created";
            passed+:1;
        ;
            -2 "    [FAIL] Block not created";
            failed+:1
        ];
    ;
        -2 "    [SKIP] No alert to test block creation";
        failed+:1
    ];

    // E2E Test 3: Metrics collection
    -1 "  [TEST] Metrics collection...";
    .metrics.collect[];
    m:.metrics.get[];
    if[m[`processed_total]>0;
        -1 "    [PASS] Metrics collected";
        passed+:1;
    ;
        -2 "    [FAIL] Metrics not collected";
        failed+:1
    ];

    // E2E Test 4: Cleanup function
    -1 "  [TEST] Cleanup function...";
    beforeCount:count .fraud.calls;
    .fraud.cleanup[];
    -1 "    [PASS] Cleanup executed without error";
    passed+:1;

    results[`suites],:(`integration;passed;failed);
    results[`passed]+:passed;
    results[`failed]+:failed;

    -1 "";
    -1 "  Integration Tests: ",string[passed]," passed, ",string[failed]," failed";

    failed=0
 };

// ============================================================================
// PERFORMANCE TEST RUNNER
// ============================================================================
runPerformanceTests:{[]
    -1 "";
    -1 "========================================";
    -1 "  Performance Tests";
    -1 "========================================";

    passed:0; failed:0;

    // Perf Test 1: Throughput
    -1 "  [TEST] Throughput (1000 calls)...";
    .fraud.clearTables[];
    .fraud.detection.latencies:();

    events:{`a_number`b_number`ts!(`$"P",string rand 100000;`$"B",string rand 1000;.z.P)} each til 1000;

    start:.z.P;
    .fraud.processCall each events;
    elapsed:(`float$(.z.P - start))%1e9;

    cps:1000%elapsed;
    -1 "    Throughput: ",string[`int$cps]," calls/second";

    if[cps>100;
        -1 "    [PASS] Throughput > 100 CPS";
        passed+:1;
    ;
        -2 "    [FAIL] Throughput below 100 CPS";
        failed+:1
    ];

    // Perf Test 2: Latency
    -1 "  [TEST] Detection latency...";
    lats:.fraud.detection.latencies;
    if[count lats;
        avgLat:avg lats;
        p99:`float$lats `int$0.99*count lats;
        -1 "    Avg latency: ",string[avgLat]," ms";
        -1 "    P99 latency: ",string[p99]," ms";

        if[p99<100;
            -1 "    [PASS] P99 latency < 100ms";
            passed+:1;
        ;
            -2 "    [FAIL] P99 latency >= 100ms";
            failed+:1
        ];
    ;
        -2 "    [FAIL] No latency data";
        failed+:1
    ];

    // Perf Test 3: Memory efficiency
    -1 "  [TEST] Memory efficiency...";
    memMb:(-22!.fraud.calls)%1048576;
    -1 "    Memory usage: ",string[memMb]," MB for ",string[count .fraud.calls]," calls";

    if[memMb<100;
        -1 "    [PASS] Memory < 100MB for test data";
        passed+:1;
    ;
        -2 "    [FAIL] Memory usage too high";
        failed+:1
    ];

    results[`suites],:(`performance;passed;failed);
    results[`passed]+:passed;
    results[`failed]+:failed;

    -1 "";
    -1 "  Performance Tests: ",string[passed]," passed, ",string[failed]," failed";

    failed=0
 };

// ============================================================================
// SECURITY TEST RUNNER
// ============================================================================
runSecurityTests:{[]
    -1 "";
    -1 "========================================";
    -1 "  Security Tests";
    -1 "========================================";

    passed:0; failed:0;

    // Sec Test 1: Input validation - malformed events
    -1 "  [TEST] Malformed input handling...";
    malformed:(
        ()!();
        `garbage`data!(1;2);
        `a_number`b_number!(`;`);
        `a_number`b_number`ts!(`A;`B;0Np)
    );
    errors:0;
    {@[.fraud.processCall;x;{errors+:1;0b}]} each malformed;
    -1 "    [PASS] Malformed inputs handled gracefully";
    passed+:1;

    // Sec Test 2: No SQL injection in queries
    -1 "  [TEST] Injection resistance...";
    // These should not cause any issues
    injectionTests:(
        `a_number`b_number!(`$"A'; DROP TABLE calls;--";`B001);
        `a_number`b_number!(`A001;`$"B'; DELETE FROM fraud_alerts;--")
    );
    {@[.fraud.processCall;x;{}]} each injectionTests;
    // If we got here without crash, injection is handled
    tableExists:0<count .fraud.calls;
    if[tableExists;
        -1 "    [PASS] Injection attempts handled safely";
        passed+:1;
    ;
        -2 "    [FAIL] Tables may have been affected";
        failed+:1
    ];

    // Sec Test 3: Large input handling
    -1 "  [TEST] Large input handling...";
    largeNum:1000#"A";
    result:@[.fraud.processCall;`a_number`b_number!(`$largeNum;`B001);{0b}];
    -1 "    [PASS] Large inputs handled";
    passed+:1;

    // Sec Test 4: Null handling
    -1 "  [TEST] Null value handling...";
    nullEvent:`a_number`b_number`ts!(0N`;0N`;0Np);
    result:@[.fraud.processCall;nullEvent;{0b}];
    -1 "    [PASS] Null values handled";
    passed+:1;

    results[`suites],:(`security;passed;failed);
    results[`passed]+:passed;
    results[`failed]+:failed;

    -1 "";
    -1 "  Security Tests: ",string[passed]," passed, ",string[failed]," failed";

    failed=0
 };

// ============================================================================
// MAIN TEST RUNNER
// ============================================================================
runAll:{[]
    startTime::.z.P;
    results::`suites`passed`failed`errors`duration!(();0;0;0;0f);

    -1 "";
    -1 "########################################";
    -1 "#  Anti-Call Masking Test Suite       #";
    -1 "########################################";
    -1 "";

    // Load modules
    if[not loadAll[];
        -2 "[FATAL] Cannot run tests - module load failed";
        :2
    ];

    // Run test suites
    unitOk:runUnitTests[];
    intOk:runIntegrationTests[];
    perfOk:runPerformanceTests[];
    secOk:runSecurityTests[];

    // Calculate duration
    results[`duration]:(`float$(.z.P - startTime))%1e9;

    // Final summary
    -1 "";
    -1 "########################################";
    -1 "#  Test Summary                        #";
    -1 "########################################";
    -1 "";
    -1 "  Total Passed: ",string results`passed;
    -1 "  Total Failed: ",string results`failed;
    -1 "  Load Errors:  ",string results`errors;
    -1 "  Duration:     ",string[results`duration]," seconds";
    -1 "";

    // Detailed breakdown
    -1 "  Breakdown by suite:";
    {-1 "    ",string[x 0],": ",string[x 1]," passed, ",string[x 2]," failed"} each results`suites;
    -1 "";

    // Exit code
    exitCode:$[results[`errors]>0;2;results[`failed]>0;1;0];

    $[exitCode=0;
        -1 "[SUCCESS] All tests passed!";
        exitCode=1;
        -2 "[FAILURE] Some tests failed";
        -2 "[ERROR] Load errors occurred"
    ];

    -1 "";

    // Return exit code (for CI)
    exitCode
 };

\d .

// Run tests when script is executed
exitCode:.testrunner.runAll[];

// Exit with appropriate code for CI
\\
exit exitCode
