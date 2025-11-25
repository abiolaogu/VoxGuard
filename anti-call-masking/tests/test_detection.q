// test_detection.q - Unit tests for fraud detection
// Anti-Call Masking Detection System
// ===================================

// ============================================================================
// TEST FRAMEWORK
// ============================================================================
\d .test

passed:0;
failed:0;
results:();

// Test assertion helpers
assert:{[condition;testName]
    if[condition;
        passed+:1;
        results,:(testName;`pass;`);
        0N!"  [PASS] ",testName;
        :1b
    ];
    failed+:1;
    results,:(testName;`fail;`);
    0N!"  [FAIL] ",testName;
    0b
 };

assertEq:{[actual;expected;testName]
    if[actual~expected;
        passed+:1;
        results,:(testName;`pass;`);
        0N!"  [PASS] ",testName;
        :1b
    ];
    failed+:1;
    results,:(testName;`fail;`actual`expected!(actual;expected));
    0N!"  [FAIL] ",testName," - Expected: ",-3!expected," Got: ",-3!actual;
    0b
 };

// Reset test state and tables
reset:{[]
    .fraud.clearTables[];
    .fraud.detection.processedCount:0;
    .fraud.detection.alertCount:0;
    .fraud.detection.latencies:();
    .fraud.config.whitelist[`b_numbers]:`symbol$();
    .fraud.config.detection[`window_seconds]:5;
    .fraud.config.detection[`min_distinct_a]:5;
    .fraud.config.detection[`cooldown_seconds]:60;
    .fraud.config.actions[`auto_disconnect]:0b;  // Disable for testing
 };

// Run all tests
runAll:{[]
    passed::0;
    failed::0;
    results::();

    0N!"";
    0N!"=================================================";
    0N!"  Running Unit Tests";
    0N!"=================================================";
    0N!"";

    // Run each test suite
    testThreshold[];
    testWindow[];
    testNormalization[];
    testWhitelist[];
    testCooldown[];
    testActions[];
    testSchema[];

    0N!"";
    0N!"=================================================";
    0N!"  Test Results";
    0N!"=================================================";
    0N!"  Passed: ",string passed;
    0N!"  Failed: ",string failed;
    0N!"  Total:  ",string passed+failed;
    0N!"=================================================";
    0N!"";

    // Return results table
    ([]name:results[;0];status:results[;1];details:results[;2])
 };

\d .

// ============================================================================
// THRESHOLD TESTS
// ============================================================================
testThreshold:{[]
    0N!"[TEST SUITE] Threshold Detection Tests";

    // Test 1: Exactly 5 calls triggers alert
    .test.reset[];
    baseTs:.z.P;
    events:{`a_number`b_number`ts!(`$"A",string x;`B001;y+`ms$x*100)}[;baseTs] each til 5;
    results:.fraud.processCall each events;

    detected:sum results[;`detected];
    .test.assertEq[detected;1;"Exactly 5 distinct A-numbers triggers 1 alert"];

    // Verify alert was created
    alertCount:count select from .fraud.fraud_alerts where b_number=`B001;
    .test.assertEq[alertCount;1;"Alert record created for B001"];

    // Test 2: 4 calls does NOT trigger
    .test.reset[];
    events:{`a_number`b_number`ts!(`$"A",string x;`B002;.z.P+`ms$x*100)} each til 4;
    results:.fraud.processCall each events;

    detected:sum results[;`detected];
    .test.assertEq[detected;0;"4 distinct A-numbers does not trigger alert"];

    // Test 3: 6 calls triggers exactly 1 alert (not 2)
    .test.reset[];
    events:{`a_number`b_number`ts!(`$"A",string x;`B003;.z.P+`ms$x*100)} each til 6;
    results:.fraud.processCall each events;

    alertCount:count select from .fraud.fraud_alerts where b_number=`B003;
    .test.assertEq[alertCount;1;"6 calls triggers only 1 alert (cooldown)"];

    // Test 4: Same A-number multiple times counts as 1
    .test.reset[];
    events:{`a_number`b_number`ts!(`A001;`B004;.z.P+`ms$x*100)} each til 10;
    results:.fraud.processCall each events;

    detected:sum results[;`detected];
    .test.assertEq[detected;0;"Same A-number 10 times does not trigger (only 1 distinct)"];

    // Test 5: Mixed A-numbers reaching exactly threshold
    .test.reset[];
    // 3 unique + 2 unique + duplicates = 5 unique total
    events:();
    events,:`a_number`b_number`ts!(`A001;`B005;.z.P);
    events,:`a_number`b_number`ts!(`A002;`B005;.z.P+`ms$100);
    events,:`a_number`b_number`ts!(`A003;`B005;.z.P+`ms$200);
    events,:`a_number`b_number`ts!(`A001;`B005;.z.P+`ms$300);  // duplicate
    events,:`a_number`b_number`ts!(`A004;`B005;.z.P+`ms$400);
    events,:`a_number`b_number`ts!(`A002;`B005;.z.P+`ms$500);  // duplicate
    events,:`a_number`b_number`ts!(`A005;`B005;.z.P+`ms$600);  // 5th unique - triggers

    results:.fraud.processCall each events;
    detected:sum results[;`detected];
    .test.assertEq[detected;1;"Duplicates don't count - triggers on 5th unique"];
 };

// ============================================================================
// WINDOW TESTS
// ============================================================================
testWindow:{[]
    0N!"[TEST SUITE] Window Expiry Tests";

    // Test 1: Calls outside window don't count
    .test.reset[];
    .fraud.config.detection[`window_seconds]:5;

    // First 3 calls at T=0
    baseTs:.z.P - `second$10;  // 10 seconds ago
    events1:{`a_number`b_number`ts!(`$"A",string x;`B010;y+`ms$x*100)}[;baseTs] each til 3;
    .fraud.processCall each events1;

    // Next 2 calls at T=6s (outside 5s window from T=0)
    events2:{`a_number`b_number`ts!(`$"A",string x+3;`B010;.z.P+`ms$x*100)} each til 2;
    results:.fraud.processCall each events2;

    // Should not trigger because first 3 are outside window
    detected:sum results[;`detected];
    .test.assertEq[detected;0;"Calls outside window don't count toward threshold"];

    // Test 2: All calls within window triggers
    .test.reset[];
    baseTs:.z.P;
    events:{`a_number`b_number`ts!(`$"A",string x;`B011;y+`ms$x*500)}[;baseTs] each til 5;
    results:.fraud.processCall each events;

    detected:sum results[;`detected];
    .test.assertEq[detected;1;"All calls within 5s window triggers alert"];

    // Test 3: Sliding window works correctly
    .test.reset[];
    .fraud.config.detection[`cooldown_seconds]:0;  // Disable cooldown for this test

    // A1 at T=0, A2 at T=2s, A3 at T=4s
    // Then A4 at T=6s, A5 at T=8s
    // At T=8s, window is [T=3s, T=8s], so A1 (T=0) and maybe A2 (T=2s) are out
    baseTs:.z.P - `second$10;
    e1:`a_number`b_number`ts!(`A001;`B012;baseTs);
    e2:`a_number`b_number`ts!(`A002;`B012;baseTs+`second$2);
    e3:`a_number`b_number`ts!(`A003;`B012;baseTs+`second$4);
    e4:`a_number`b_number`ts!(`A004;`B012;baseTs+`second$6);
    e5:`a_number`b_number`ts!(`A005;`B012;baseTs+`second$8);

    .fraud.processCall each (e1;e2;e3;e4;e5);

    // At T=8s, within 5s window are: A3(T=4s), A4(T=6s), A5(T=8s) = only 3 distinct
    alerts:count select from .fraud.fraud_alerts where b_number=`B012;
    .test.assertEq[alerts;0;"Sliding window correctly expires old calls"];
 };

// ============================================================================
// NUMBER NORMALIZATION TESTS
// ============================================================================
testNormalization:{[]
    0N!"[TEST SUITE] Number Normalization Tests";

    // Test various formats
    .test.assertEq[.fraud.detection.normalizeNumber "+1 (555) 123-4567";"+15551234567";"Normalize US format with spaces"];
    .test.assertEq[.fraud.detection.normalizeNumber "555.123.4567";"5551234567";"Normalize dot format"];
    .test.assertEq[.fraud.detection.normalizeNumber "+44-20-7946-0958";"+442079460958";"Normalize UK format"];
    .test.assertEq[.fraud.detection.normalizeNumber "12345";"12345";"Plain numbers unchanged"];
 };

// ============================================================================
// WHITELIST TESTS
// ============================================================================
testWhitelist:{[]
    0N!"[TEST SUITE] Whitelist Tests";

    // Test 1: Whitelisted B-number is exempt
    .test.reset[];
    .fraud.config.whitelist[`b_numbers]:`B_SAFE;

    events:{`a_number`b_number`ts!(`$"A",string x;`B_SAFE;.z.P+`ms$x*100)} each til 10;
    results:.fraud.processCall each events;

    detected:sum results[;`detected];
    .test.assertEq[detected;0;"Whitelisted B-number does not trigger alert"];

    // Verify reason is whitelist
    reasons:distinct results[;`reason];
    .test.assert[`whitelisted in reasons;"Whitelist reason recorded"];

    // Test 2: Non-whitelisted B-number triggers normally
    .test.reset[];
    .fraud.config.whitelist[`b_numbers]:`B_SAFE;

    events:{`a_number`b_number`ts!(`$"A",string x;`B_UNSAFE;.z.P+`ms$x*100)} each til 5;
    results:.fraud.processCall each events;

    detected:sum results[;`detected];
    .test.assertEq[detected;1;"Non-whitelisted B-number triggers normally"];

    // Test 3: A-number prefix whitelist
    .test.reset[];
    .fraud.config.whitelist[`a_number_prefixes]:`$"+1800";

    // Calls from toll-free numbers
    events:();
    events,:`a_number`b_number`ts!(`$"+18001111111";`B020;.z.P);
    events,:`a_number`b_number`ts!(`$"+18002222222";`B020;.z.P+`ms$100);
    events,:`a_number`b_number`ts!(`$"+18003333333";`B020;.z.P+`ms$200);
    events,:`a_number`b_number`ts!(`$"+18004444444";`B020;.z.P+`ms$300);
    events,:`a_number`b_number`ts!(`$"+18005555555";`B020;.z.P+`ms$400);

    results:.fraud.processCall each events;
    detected:sum results[;`detected];
    .test.assertEq[detected;0;"Whitelisted A-number prefix exempt from detection"];
 };

// ============================================================================
// COOLDOWN TESTS
// ============================================================================
testCooldown:{[]
    0N!"[TEST SUITE] Cooldown Tests";

    // Test 1: Cooldown prevents rapid repeated alerts
    .test.reset[];
    .fraud.config.detection[`cooldown_seconds]:60;

    // First attack - should alert
    events1:{`a_number`b_number`ts!(`$"A",string x;`B030;.z.P+`ms$x*100)} each til 5;
    .fraud.processCall each events1;

    alert1:count select from .fraud.fraud_alerts where b_number=`B030;
    .test.assertEq[alert1;1;"First attack triggers alert"];

    // Second attack within cooldown - should NOT alert
    events2:{`a_number`b_number`ts!(`$"B",string x;`B030;.z.P+`ms$1000+x*100)} each til 5;
    results:.fraud.processCall each events2;

    alert2:count select from .fraud.fraud_alerts where b_number=`B030;
    .test.assertEq[alert2;1;"Second attack within cooldown does not create new alert"];

    // Check cooldown reason
    reasons:distinct results[;`reason];
    .test.assert[`cooldown in reasons;"Cooldown reason recorded"];

    // Test 2: Different B-numbers are independent
    .test.reset[];
    events3:{`a_number`b_number`ts!(`$"A",string x;`B031;.z.P+`ms$x*100)} each til 5;
    events4:{`a_number`b_number`ts!(`$"A",string x;`B032;.z.P+`ms$x*100)} each til 5;

    .fraud.processCall each events3;
    .fraud.processCall each events4;

    alerts:count .fraud.fraud_alerts;
    .test.assertEq[alerts;2;"Different B-numbers alert independently"];
 };

// ============================================================================
// ACTION TESTS
// ============================================================================
testActions:{[]
    0N!"[TEST SUITE] Action Tests";

    // Test 1: Whitelist management
    .test.reset[];

    // Add to whitelist
    result:.fraud.actions.addToWhitelist[`B_NEW];
    .test.assert[`B_NEW in .fraud.config.whitelist`b_numbers;"Add to whitelist works"];

    // Remove from whitelist
    result:.fraud.actions.removeFromWhitelist[`B_NEW];
    .test.assert[not `B_NEW in .fraud.config.whitelist`b_numbers;"Remove from whitelist works"];

    // Test 2: Block pattern creation
    .test.reset[];
    .fraud.config.actions[`auto_disconnect]:0b;

    // Create an alert
    events:{`a_number`b_number`ts!(`$"A",string x;`B040;.z.P+`ms$x*100)} each til 5;
    .fraud.processCall each events;

    alertId:first exec alert_id from .fraud.fraud_alerts where b_number=`B040;

    // Manually create block
    .fraud.actions.createBlock alertId;

    blocks:count select from .fraud.blocked_patterns where b_number=`B040, active;
    .test.assertEq[blocks;1;"Block pattern created for alert"];

    // Test 3: Block detection
    isBlocked:.fraud.detection.isBlocked[`B040;`A000];
    .test.assert[isBlocked;"isBlocked returns true for blocked B-number"];
 };

// ============================================================================
// SCHEMA TESTS
// ============================================================================
testSchema:{[]
    0N!"[TEST SUITE] Schema Tests";

    // Test 1: Schema validation
    valid:.fraud.validateSchema[];
    .test.assert[valid;"Schema validation passes"];

    // Test 2: Table sizes function works
    sizes:.fraud.tableSizes[];
    .test.assertEq[count sizes;6;"tableSizes returns all 6 tables"];

    // Test 3: Memory usage function works
    mem:.fraud.memoryUsage[];
    .test.assert[(last mem`table)=`TOTAL;"memoryUsage includes TOTAL row"];

    // Test 4: Expire functions work without error
    .fraud.expireCalls[10];
    .fraud.expireBlocks[];
    .test.assert[1b;"Expire functions run without error"];
 };

// ============================================================================
// LOAD MODULE AND RUN
// ============================================================================
\d .

// Load the detection system
srcDir:first ` vs hsym .z.f;
if[srcDir~`;srcDir:`:.];
system "cd ",1_string srcDir;
system "cd ..";

\l src/config.q
\l src/schema.q
\l src/detection.q
\l src/actions.q

// Enable simulation mode for testing
.fraud.switch.connected:1b;
.fraud.switch.simulationMode:1b;

// Run tests if loaded directly
if[.z.f like "*test_detection.q";
    .test.runAll[];
];
