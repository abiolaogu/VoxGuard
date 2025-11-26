// test_voiceswitch_integration.q - Voice Switch Integration Tests
// Anti-Call Masking Detection System
// ===================================
// Tests for Voice Switch API integration

\d .test

// ============================================================================
// TEST CONFIGURATION
// ============================================================================
voiceSwitch.totalTests: 0;
voiceSwitch.passedTests: 0;
voiceSwitch.failedTests: 0;

// Test assertion helpers
voiceSwitch.assert:{[desc; condition]
    voiceSwitch.totalTests+: 1;
    $[condition;
        [voiceSwitch.passedTests+: 1; -1 "  [PASS] ", desc];
        [voiceSwitch.failedTests+: 1; -1 "  [FAIL] ", desc]]
 };

voiceSwitch.assertEqual:{[desc; expected; actual]
    voiceSwitch.assert[desc, " (expected: ", (-3!expected), ", got: ", (-3!actual), ")"; expected ~ actual]
 };

// ============================================================================
// MOCK HTTP SERVER TESTS
// ============================================================================
voiceSwitch.testHttpParsing:{[]
    -1 "";
    -1 "Testing HTTP Request Parsing...";
    -1 "-----------------------------";

    // Test basic GET request parsing
    getReq: "GET /health HTTP/1.1\r\nHost: localhost\r\n\r\n";
    parsed: .http.parseRequest[getReq];
    voiceSwitch.assertEqual["GET method parsed"; "GET"; parsed`method];
    voiceSwitch.assertEqual["Path parsed"; "/health"; parsed`path];

    // Test POST request with body
    postReq: "POST /event HTTP/1.1\r\nHost: localhost\r\nContent-Type: application/json\r\n\r\n{\"call_id\":\"test123\",\"a_number\":\"A001\",\"b_number\":\"B999\"}";
    parsed: .http.parseRequest[postReq];
    voiceSwitch.assertEqual["POST method parsed"; "POST"; parsed`method];
    voiceSwitch.assertEqual["POST path parsed"; "/event"; parsed`path];
    voiceSwitch.assert["POST body contains call_id"; parsed[`body] like "*call_id*"];

    // Test query string parsing
    getWithQuery: "GET /threat?b_number=B123 HTTP/1.1\r\nHost: localhost\r\n\r\n";
    parsed: .http.parseRequest[getWithQuery];
    voiceSwitch.assertEqual["Query string path"; "/threat"; parsed`path];
 };

// ============================================================================
// EVENT PROCESSING TESTS
// ============================================================================
voiceSwitch.testEventProcessing:{[]
    -1 "";
    -1 "Testing Event Processing...";
    -1 "-----------------------------";

    // Clear existing data
    delete from `.fraud.calls;
    delete from `.fraud.fraud_alerts;

    // Test single event processing
    event1: `call_id`a_number`b_number`ts`status`switch_id`raw_call_id!(
        `test001; `A001; `B999; .z.P; `active; `voiceswitch; `test001
    );

    result1: .fraud.processCall[event1];
    voiceSwitch.assert["Event processed without error"; not `error ~ first result1];
    voiceSwitch.assertEqual["No detection on single call"; 0b; result1 0];

    // Verify call was recorded
    callCount: count select from .fraud.calls where b_number = `B999;
    voiceSwitch.assertEqual["Call recorded in table"; 1; callCount];

    // Add more calls from different A-numbers
    events: {
        `call_id`a_number`b_number`ts`status`switch_id`raw_call_id!(
            `$"test00",string x;
            `$"A00",string x;
            `B999;
            .z.P;
            `active;
            `voiceswitch;
            `$"test00",string x
        )
    } each 2 3 4 5;

    results: .fraud.processCall each events;

    // Check that detection triggers at threshold
    detections: sum results[;0];
    voiceSwitch.assert["Detection triggered at threshold"; detections > 0];

    // Verify alert was created
    alertCount: count select from .fraud.fraud_alerts where b_number = `B999;
    voiceSwitch.assert["Alert created"; alertCount > 0];
 };

// ============================================================================
// BATCH PROCESSING TESTS
// ============================================================================
voiceSwitch.testBatchProcessing:{[]
    -1 "";
    -1 "Testing Batch Processing...";
    -1 "-----------------------------";

    // Clear existing data
    delete from `.fraud.calls;
    delete from `.fraud.fraud_alerts;

    // Create batch of events
    batchEvents: {
        `call_id`a_number`b_number`ts`status`switch_id`raw_call_id!(
            `$"batch",string x;
            `$"A",string x;
            `B888;
            .z.P;
            `active;
            `voiceswitch;
            `$"batch",string x
        )
    } each til 10;

    // Process batch
    results: .fraud.detection.processBatch[batchEvents];

    voiceSwitch.assertEqual["Batch size processed"; 10; count results];
    voiceSwitch.assert["Some detections in batch"; (sum results[;0]) > 0];
 };

// ============================================================================
// HTTP HANDLER TESTS
// ============================================================================
voiceSwitch.testHttpHandlers:{[]
    -1 "";
    -1 "Testing HTTP Handlers...";
    -1 "-----------------------------";

    // Test health endpoint
    healthReq: `method`path`query`body!("GET"; "/health"; ()!(); "");
    healthResp: .http.handleHealth[healthReq];
    voiceSwitch.assert["Health returns 200"; healthResp like "*200 OK*"];
    voiceSwitch.assert["Health returns healthy status"; healthResp like "*healthy*"];

    // Test stats endpoint
    statsReq: `method`path`query`body!("GET"; "/stats"; ()!(); "");
    statsResp: .http.handleStats[statsReq];
    voiceSwitch.assert["Stats returns 200"; statsResp like "*200 OK*"];
    voiceSwitch.assert["Stats contains processed"; statsResp like "*processed*"];

    // Test alerts endpoint
    alertsReq: `method`path`query`body!("GET"; "/alerts"; `minutes!"60"; "");
    alertsResp: .http.handleAlerts[alertsReq];
    voiceSwitch.assert["Alerts returns 200"; alertsResp like "*200 OK*"];

    // Test active calls endpoint
    activeReq: `method`path`query`body!("GET"; "/calls/active"; ()!(); "");
    activeResp: .http.handleActiveCalls[activeReq];
    voiceSwitch.assert["Active calls returns 200"; activeResp like "*200 OK*"];
 };

// ============================================================================
// VOICE SWITCH DISCONNECT TESTS
// ============================================================================
voiceSwitch.testDisconnect:{[]
    -1 "";
    -1 "Testing Voice Switch Disconnect...";
    -1 "-----------------------------";

    // Test disconnect function exists
    voiceSwitch.assert["Disconnect function exists"; `disconnectVoiceSwitch in key `.fraud.switch];

    // Test disconnect with mock (should fail gracefully without actual API)
    // This tests the error handling path
    result: @[.fraud.switch.disconnectVoiceSwitch; `testcall123; 0b];
    voiceSwitch.assert["Disconnect handles missing API gracefully"; not result];
 };

// ============================================================================
// ROUTING TESTS
// ============================================================================
voiceSwitch.testRouting:{[]
    -1 "";
    -1 "Testing HTTP Routing...";
    -1 "-----------------------------";

    // Test various routes
    routes: (
        ("/health"; "healthy");
        ("/stats"; "processed");
        ("/alerts"; "200");
        ("/config"; "window_seconds");
        ("/calls/active"; "active_calls");
        ("/nonexistent"; "Not found")
    );

    {
        req: `method`path`query`body!("GET"; x 0; ()!(); "");
        resp: .http.route[req];
        .test.voiceSwitch.assert["Route ", x[0], " returns expected"; resp like "*", x[1], "*"]
    } each routes;
 };

// ============================================================================
// CONFIGURATION TESTS
// ============================================================================
voiceSwitch.testConfiguration:{[]
    -1 "";
    -1 "Testing Voice Switch Configuration...";
    -1 "-----------------------------";

    // Test config contains voiceswitch settings
    voiceSwitch.assert["Switch config has api_url"; `api_url in key .fraud.config.switch];
    voiceSwitch.assert["HTTP config exists"; `http in key `.fraud.config];
    voiceSwitch.assert["HTTP config has port"; `port in key .fraud.config.http];

    // Test config update via HTTP
    configReq: `method`path`query`body!("POST"; "/config"; ()!(); "{\"threshold\":7}");
    configResp: .http.handleConfig[configReq];
    voiceSwitch.assert["Config update returns 200"; configResp like "*200 OK*"];
 };

// ============================================================================
// PERFORMANCE TESTS
// ============================================================================
voiceSwitch.testPerformance:{[]
    -1 "";
    -1 "Testing Performance...";
    -1 "-----------------------------";

    // Clear data
    delete from `.fraud.calls;
    delete from `.fraud.fraud_alerts;

    // Generate 1000 events
    eventCount: 1000;
    events: {
        `call_id`a_number`b_number`ts`status`switch_id`raw_call_id!(
            `$"perf",string x;
            `$"A",string x mod 100;  // 100 unique A-numbers
            `$"B",string x mod 50;   // 50 unique B-numbers
            .z.P;
            `active;
            `voiceswitch;
            `$"perf",string x
        )
    } each til eventCount;

    // Time the processing
    start: .z.P;
    results: .fraud.processCall each events;
    elapsed: .z.P - start;

    elapsedMs: `float$elapsed % 1000000;
    eventsPerSec: `float$eventCount * 1000 % elapsedMs;

    -1 "  Processed ", string[eventCount], " events in ", string[`int$elapsedMs], "ms";
    -1 "  Rate: ", string[`int$eventsPerSec], " events/second";

    // Should process at least 100 events per second
    voiceSwitch.assert["Performance > 100 events/sec"; eventsPerSec > 100];
 };

// ============================================================================
// RUN ALL TESTS
// ============================================================================
voiceSwitch.runAll:{[]
    -1 "============================================";
    -1 "  Voice Switch Integration Tests";
    -1 "============================================";

    // Reset counters
    voiceSwitch.totalTests: 0;
    voiceSwitch.passedTests: 0;
    voiceSwitch.failedTests: 0;

    // Run all test suites
    voiceSwitch.testHttpParsing[];
    voiceSwitch.testEventProcessing[];
    voiceSwitch.testBatchProcessing[];
    voiceSwitch.testHttpHandlers[];
    voiceSwitch.testDisconnect[];
    voiceSwitch.testRouting[];
    voiceSwitch.testConfiguration[];
    voiceSwitch.testPerformance[];

    // Summary
    -1 "";
    -1 "============================================";
    -1 "  Test Summary";
    -1 "============================================";
    -1 "  Total:  ", string voiceSwitch.totalTests;
    -1 "  Passed: ", string voiceSwitch.passedTests;
    -1 "  Failed: ", string voiceSwitch.failedTests;
    -1 "";

    if[voiceSwitch.failedTests > 0;
        -1 "  [FAILED] Some tests failed!";
        :0b
    ];

    -1 "  [SUCCESS] All tests passed!";
    1b
 };

\d .

// Export test runner
runVoiceSwitchTests: .test.voiceSwitch.runAll;

0N!"[INFO] test_voiceswitch_integration.q loaded";
0N!"[INFO] Run tests with: runVoiceSwitchTests[]";
