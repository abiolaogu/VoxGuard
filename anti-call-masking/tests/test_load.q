// test_load.q - Performance and load tests
// Anti-Call Masking Detection System
// ===================================
// Tests throughput, latency, and detection accuracy under load

// ============================================================================
// LOAD TEST FRAMEWORK
// ============================================================================
\d .loadtest

// Test configuration
config:`target_cps`duration_seconds`attack_ratio`b_number_pool`a_number_pool!(
    10000;      // Target calls per second
    10;         // Test duration in seconds
    0.01;       // 1% of calls are part of attacks
    1000;       // Number of unique B-numbers
    100000      // Number of unique A-numbers
);

// Results storage
results:();

// ============================================================================
// TEST DATA GENERATORS
// ============================================================================

// Generate random phone number
genANumber:{`$"+1",string[1000000000+x mod 9000000000]};
genBNumber:{`$"+1",string[2000000000+x mod 1000]};

// Generate normal call event (random A -> random B)
genNormalCall:{
    aNum:genANumber rand config`a_number_pool;
    bNum:genBNumber rand config`b_number_pool;
    `a_number`b_number`ts!(aNum;bNum;.z.P)
 };

// Generate attack call (specific B-number under attack)
genAttackCall:{[targetB;attackerPool]
    aNum:genANumber attackerPool?rand count attackerPool;
    `a_number`b_number`ts!(aNum;targetB;.z.P)
 };

// ============================================================================
// THROUGHPUT TEST
// ============================================================================
runThroughputTest:{[targetCPS;durationSec]
    0N!"";
    0N!"=================================================";
    0N!"  Throughput Test";
    0N!"  Target: ",string[targetCPS]," calls/second";
    0N!"  Duration: ",string[durationSec]," seconds";
    0N!"=================================================";

    // Reset state
    .fraud.clearTables[];
    .fraud.detection.processedCount:0;
    .fraud.detection.alertCount:0;
    .fraud.config.actions[`auto_disconnect]:0b;

    // Generate test events
    totalCalls:targetCPS * durationSec;
    0N!"[LOAD] Generating ",string[totalCalls]," test events...";

    events:genNormalCall each til totalCalls;

    // Process events and measure time
    0N!"[LOAD] Processing events...";
    startTime:.z.P;

    // Process in batches for better memory management
    batchSize:10000;
    batches:0N batchSize # events;
    {.fraud.processCall each x} each batches;

    endTime:.z.P;

    // Calculate metrics
    elapsed:(`float$(endTime - startTime))%1e9;  // seconds
    actualCPS:totalCalls % elapsed;
    avgLatency:avg .fraud.detection.latencies;
    maxLatency:max .fraud.detection.latencies;
    p99Latency:(.fraud.detection.latencies) 99*count[.fraud.detection.latencies]%100;

    result:`test`target_cps`actual_cps`duration_sec`total_calls`avg_latency_ms`max_latency_ms`p99_latency_ms!(
        `throughput;
        targetCPS;
        `long$actualCPS;
        elapsed;
        totalCalls;
        avgLatency;
        maxLatency;
        p99Latency
    );

    results,:enlist result;

    0N!"";
    0N!"[RESULTS]";
    0N!"  Actual CPS: ",string[`long$actualCPS];
    0N!"  Avg Latency: ",string[avgLatency]," ms";
    0N!"  Max Latency: ",string[maxLatency]," ms";
    0N!"  P99 Latency: ",string[p99Latency]," ms";
    0N!"  Memory Used: ",string[(-22!.fraud.calls)%1048576]," MB";

    result
 };

// ============================================================================
// DETECTION ACCURACY TEST
// ============================================================================
runAccuracyTest:{[numAttacks;callersPerAttack]
    0N!"";
    0N!"=================================================";
    0N!"  Detection Accuracy Test";
    0N!"  Attacks: ",string[numAttacks];
    0N!"  Callers per attack: ",string[callersPerAttack];
    0N!"=================================================";

    // Reset state
    .fraud.clearTables[];
    .fraud.detection.processedCount:0;
    .fraud.detection.alertCount:0;
    .fraud.config.actions[`auto_disconnect]:0b;
    .fraud.config.detection[`cooldown_seconds]:0;  // Disable cooldown for accuracy test

    // Generate attacks
    0N!"[LOAD] Generating attack scenarios...";

    attacksGenerated:0;
    attacksDetected:0;

    // For each attack, generate calls to same B-number from different A-numbers
    {
        targetB:genBNumber x;
        attackers:genANumber each til callersPerAttack;

        // Generate calls for this attack
        events:{`a_number`b_number`ts!(x;y;.z.P)}[;targetB] each attackers;

        // Process calls
        results:.fraud.processCall each events;

        // Check if detected
        if[any results[;`detected];attacksDetected::attacksDetected+1];
        attacksGenerated::attacksGenerated+1;
    } each til numAttacks;

    // Add noise (normal calls that should NOT trigger)
    0N!"[LOAD] Adding noise calls...";
    noiseCalls:genNormalCall each til numAttacks*10;
    falsePositives:sum (.fraud.processCall each noiseCalls)[;`detected];

    // Calculate metrics
    detectionRate:(attacksDetected % attacksGenerated) * 100;
    falsePositiveRate:(falsePositives % count noiseCalls) * 100;

    result:`test`attacks_generated`attacks_detected`detection_rate`noise_calls`false_positives`fp_rate!(
        `accuracy;
        attacksGenerated;
        attacksDetected;
        detectionRate;
        count noiseCalls;
        falsePositives;
        falsePositiveRate
    );

    results,:enlist result;

    0N!"";
    0N!"[RESULTS]";
    0N!"  Attacks Generated: ",string attacksGenerated;
    0N!"  Attacks Detected: ",string attacksDetected;
    0N!"  Detection Rate: ",string[detectionRate],"%";
    0N!"  Noise Calls: ",string count noiseCalls;
    0N!"  False Positives: ",string falsePositives;
    0N!"  False Positive Rate: ",string[falsePositiveRate],"%";

    result
 };

// ============================================================================
// LATENCY TEST
// ============================================================================
runLatencyTest:{[iterations]
    0N!"";
    0N!"=================================================";
    0N!"  Latency Distribution Test";
    0N!"  Iterations: ",string iterations;
    0N!"=================================================";

    // Reset state
    .fraud.clearTables[];
    .fraud.detection.latencies:();

    // Process calls and collect latencies
    0N!"[LOAD] Measuring latencies...";

    events:genNormalCall each til iterations;
    .fraud.processCall each events;

    latencies:.fraud.detection.latencies;

    // Calculate percentiles
    sorted:asc latencies;
    p50:sorted `long$0.50*count sorted;
    p90:sorted `long$0.90*count sorted;
    p95:sorted `long$0.95*count sorted;
    p99:sorted `long$0.99*count sorted;

    result:`test`iterations`min`max`avg`p50`p90`p95`p99!(
        `latency;
        iterations;
        min latencies;
        max latencies;
        avg latencies;
        p50;p90;p95;p99
    );

    results,:enlist result;

    0N!"";
    0N!"[RESULTS] Latency Distribution (ms)";
    0N!"  Min: ",string min latencies;
    0N!"  Max: ",string max latencies;
    0N!"  Avg: ",string avg latencies;
    0N!"  P50: ",string p50;
    0N!"  P90: ",string p90;
    0N!"  P95: ",string p95;
    0N!"  P99: ",string p99;

    result
 };

// ============================================================================
// MEMORY TEST
// ============================================================================
runMemoryTest:{[numCalls]
    0N!"";
    0N!"=================================================";
    0N!"  Memory Usage Test";
    0N!"  Calls: ",string numCalls;
    0N!"=================================================";

    // Reset state
    .fraud.clearTables[];

    // Measure initial memory
    initialMem:-22!`.fraud.calls;

    // Generate and process calls
    0N!"[LOAD] Processing calls...";
    events:genNormalCall each til numCalls;
    .fraud.processCall each events;

    // Measure memory after
    afterMem:-22!`.fraud.calls;
    memUsed:(afterMem - initialMem) % 1048576;  // MB

    // Run GC
    .fraud.detection.runGC[];
    afterGCMem:-22!`.fraud.calls;
    memAfterGC:(afterGCMem - initialMem) % 1048576;

    result:`test`calls_processed`mem_before_mb`mem_after_mb`mem_after_gc_mb`calls_retained!(
        `memory;
        numCalls;
        initialMem%1048576;
        afterMem%1048576;
        afterGCMem%1048576;
        count .fraud.calls
    );

    results,:enlist result;

    0N!"";
    0N!"[RESULTS]";
    0N!"  Calls Processed: ",string numCalls;
    0N!"  Memory Before: ",string[initialMem%1048576]," MB";
    0N!"  Memory After: ",string[afterMem%1048576]," MB";
    0N!"  Memory After GC: ",string[afterGCMem%1048576]," MB";
    0N!"  Calls Retained: ",string count .fraud.calls;

    result
 };

// ============================================================================
// STRESS TEST (Combined)
// ============================================================================
runStressTest:{[]
    0N!"";
    0N!"#################################################";
    0N!"#          STRESS TEST SUITE                    #";
    0N!"#################################################";

    // Run all tests
    runThroughputTest[1000;5];      // 1K CPS for 5 seconds
    runAccuracyTest[100;5];          // 100 attacks with 5 callers each
    runLatencyTest[10000];           // 10K iterations for latency
    runMemoryTest[50000];            // 50K calls for memory test

    0N!"";
    0N!"#################################################";
    0N!"#          STRESS TEST COMPLETE                 #";
    0N!"#################################################";

    // Summary
    0N!"";
    0N!"Summary:";
    show results;

    results
 };

// ============================================================================
// HIGH LOAD TEST
// ============================================================================
runHighLoadTest:{[]
    0N!"";
    0N!"#################################################";
    0N!"#          HIGH LOAD TEST (100K CPS Target)     #";
    0N!"#################################################";

    // This test attempts to push the system to 100K CPS
    // Results will vary based on hardware

    results::();

    // Warm up
    0N!"[WARMUP] Running warm-up...";
    .fraud.clearTables[];
    warmupEvents:genNormalCall each til 10000;
    .fraud.processCall each warmupEvents;
    .fraud.clearTables[];

    // Increasing load test
    loads:1000 5000 10000 25000 50000 100000;
    {
        .fraud.clearTables[];
        .fraud.detection.latencies:();

        events:genNormalCall each til x;

        startTime:.z.P;
        .fraud.processCall each events;
        endTime:.z.P;

        elapsed:(`float$(endTime - startTime))%1e9;
        actualCPS:x % elapsed;

        results,,:([]load:x;elapsed;cps:`long$actualCPS;avg_lat:avg .fraud.detection.latencies);

        0N!"  Load ",string[x],": ",string[`long$actualCPS]," CPS, avg lat: ",
           string[avg .fraud.detection.latencies],"ms";
    } each loads;

    0N!"";
    0N!"[RESULTS] Load vs Throughput:";
    show results;

    results
 };

\d .

// ============================================================================
// LOAD MODULES
// ============================================================================
srcDir:first ` vs hsym .z.f;
if[srcDir~`;srcDir:`:.];
system "cd ",1_string srcDir;
system "cd ..";

\l src/config.q
\l src/schema.q
\l src/detection.q
\l src/actions.q

// Enable simulation mode
.fraud.switch.connected:1b;
.fraud.switch.simulationMode:1b;

// Disable auto-disconnect for testing
.fraud.config.actions[`auto_disconnect]:0b;

// Run if loaded directly
if[.z.f like "*test_load.q";
    0N!"";
    0N!"Load Test Module Loaded";
    0N!"Available tests:";
    0N!"  .loadtest.runThroughputTest[cps;seconds]";
    0N!"  .loadtest.runAccuracyTest[attacks;callersPerAttack]";
    0N!"  .loadtest.runLatencyTest[iterations]";
    0N!"  .loadtest.runMemoryTest[numCalls]";
    0N!"  .loadtest.runStressTest[]";
    0N!"  .loadtest.runHighLoadTest[]";
    0N!"";
];
