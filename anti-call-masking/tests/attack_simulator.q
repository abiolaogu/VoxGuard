// attack_simulator.q - Comprehensive attack pattern simulator
// Anti-Call Masking Detection System - Production Test Suite
// ===========================================================

\d .test

// ============================================================================
// ATTACK PATTERN DEFINITIONS
// ============================================================================
patterns:([]
    name:`sequential`burst`distributed`slowdrip`rotating`staggered`mixed`evasion;
    description:(
        "A1,A2,A3,A4,A5 -> B sequential (100ms apart)";
        "All 5 A-numbers hit B simultaneously (<10ms)";
        "5 calls spread evenly across 4.9 seconds";
        "4 calls early, 5th just before window expires";
        "Different B-numbers, rotating A-number pools";
        "Calls arrive in waves with gaps";
        "Mix of legitimate and attack traffic interleaved";
        "Attempts to evade detection (4 calls, pause, 4 more)"
    );
    threshold:(5;5;5;5;5;5;5;4);
    window_ms:(500;50;4900;4900;5000;3000;2500;6000)
);

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================
// Generate unique phone numbers
genANumber:{[seed] `$"+1",string 3000000000 + seed mod 7000000000};
genBNumber:{[seed] `$"+1",string 8000000000 + seed mod 1000000000};

// Generate unique call ID
genCallId:{first 1?0Ng};

// Create a single call event
createEvent:{[aNum;bNum;ts]
    `call_id`a_number`b_number`ts`status`raw_call_id`switch_id!(
        genCallId[];aNum;bNum;ts;`active;`$string genCallId[];`simulator
    )
};

// ============================================================================
// ATTACK PATTERN GENERATORS
// ============================================================================

// Sequential: A1,A2,A3,A4,A5 -> B with 100ms gaps
generateSequential:{[bNum;baseTs;numCallers]
    aNumbers:genANumber each til numCallers;
    timestamps:baseTs + `ms$100 * til numCallers;
    createEvent'[aNumbers;numCallers#bNum;timestamps]
};

// Burst: All calls within 10ms
generateBurst:{[bNum;baseTs;numCallers]
    aNumbers:genANumber each 1000 + til numCallers;
    timestamps:baseTs + `ms$(numCallers?10);  // Random 0-10ms offsets
    createEvent'[aNumbers;numCallers#bNum;timestamps]
};

// Distributed: Spread across 4.9 seconds
generateDistributed:{[bNum;baseTs;numCallers]
    aNumbers:genANumber each 2000 + til numCallers;
    // Evenly distribute across 4900ms
    gaps:`int$4900 % numCallers - 1;
    timestamps:baseTs + `ms$gaps * til numCallers;
    createEvent'[aNumbers;numCallers#bNum;timestamps]
};

// Slow drip: 4 calls early, 5th just before window expires
generateSlowdrip:{[bNum;baseTs;numCallers]
    aNumbers:genANumber each 3000 + til numCallers;
    // First 4 calls in first second, last call at 4.9s
    timestamps:baseTs + `ms$(0 200 400 600 4900)[til numCallers];
    createEvent'[aNumbers;numCallers#bNum;timestamps]
};

// Rotating: Different B-numbers with overlapping A-number pools
generateRotating:{[bNum;baseTs;numCallers]
    // Creates attacks against multiple B-numbers
    bNumbers:genBNumber each 100 + til 3;  // 3 different targets
    results:();
    {[bN;bt;nc]
        aNumbers:genANumber each (1000*x) + til nc;
        timestamps:bt + `ms$100 * til nc;
        results,,:createEvent'[aNumbers;nc#bN;timestamps];
    }[;baseTs;numCallers] each bNumbers;
    results
};

// Staggered: Waves of calls with gaps
generateStaggered:{[bNum;baseTs;numCallers]
    aNumbers:genANumber each 4000 + til numCallers;
    // 2 calls, gap, 2 calls, gap, 1 call
    timestamps:baseTs + `ms$(0 100 1500 1600 3000)[til numCallers];
    createEvent'[aNumbers;numCallers#bNum;timestamps]
};

// Mixed: Interleave legitimate and attack traffic
generateMixed:{[bNum;baseTs;numCallers]
    attackANumbers:genANumber each 5000 + til numCallers;
    legitANumbers:genANumber each 9000 + til 10;  // 10 legitimate callers
    legitBNumbers:genBNumber each 500 + til 10;

    // Attack events
    attackTs:baseTs + `ms$200 * til numCallers;
    attackEvents:createEvent'[attackANumbers;numCallers#bNum;attackTs];

    // Legitimate events (scattered)
    legitTs:baseTs + `ms$50 * til 10;
    legitEvents:createEvent'[legitANumbers;legitBNumbers;legitTs];

    // Interleave
    attackEvents,legitEvents
};

// Evasion: Attempt to stay under threshold
generateEvasion:{[bNum;baseTs;numCallers]
    // 4 calls (under threshold), wait for window to slide, 4 more
    aNumbers1:genANumber each 6000 + til 4;
    aNumbers2:genANumber each 6100 + til 4;

    ts1:baseTs + `ms$100 * til 4;
    ts2:baseTs + `ms$5500 + 100 * til 4;  // After 5s window

    events1:createEvent'[aNumbers1;4#bNum;ts1];
    events2:createEvent'[aNumbers2;4#bNum;ts2];

    events1,events2
};

// ============================================================================
// MAIN ATTACK GENERATOR
// ============================================================================
generateAttack:{[patternName;bNumber;timestamp]
    pattern:exec first description from patterns where name=patternName;
    numCallers:5;  // Default threshold

    $[
        patternName=`sequential;  generateSequential[bNumber;timestamp;numCallers];
        patternName=`burst;       generateBurst[bNumber;timestamp;numCallers];
        patternName=`distributed; generateDistributed[bNumber;timestamp;numCallers];
        patternName=`slowdrip;    generateSlowdrip[bNumber;timestamp;numCallers];
        patternName=`rotating;    generateRotating[bNumber;timestamp;numCallers];
        patternName=`staggered;   generateStaggered[bNumber;timestamp;numCallers];
        patternName=`mixed;       generateMixed[bNumber;timestamp;numCallers];
        patternName=`evasion;     generateEvasion[bNumber;timestamp;numCallers];
        // Default to sequential
        generateSequential[bNumber;timestamp;numCallers]
    ]
};

// ============================================================================
// LEGITIMATE TRAFFIC GENERATOR
// ============================================================================
generateLegitimateCall:{[]
    aNum:genANumber rand 1000000;
    bNum:genBNumber rand 100000;
    createEvent[aNum;bNum;.z.P]
};

generateLegitimateTraffic:{[count]
    generateLegitimateCall each til count
};

// ============================================================================
// FULL SIMULATION RUNNER
// ============================================================================
// Runs a complete simulation with mixed traffic
// cps: calls per second
// duration: seconds to run
// attackRate: fraction of traffic that's attacks (0.0 - 1.0)
runSimulation:{[cps;duration;attackRate]
    .log.info "Starting simulation: ",string[cps]," CPS, ",string[duration],"s, ",
              string[100*attackRate],"% attacks";

    // Reset state
    .fraud.clearTables[];
    .fraud.detection.processedCount:0;
    .fraud.detection.alertCount:0;
    .fraud.config.actions[`auto_disconnect]:0b;

    // Calculate totals
    totalCalls:`long$cps * duration;
    attackCalls:`long$totalCalls * attackRate;
    legitimateCalls:totalCalls - attackCalls;

    // Track injected attacks
    attacksInjected:0;
    attackPatterns:`sequential`burst`distributed`slowdrip`staggered;

    // Generate attack events
    attackEvents:();
    if[attackCalls>0;
        attacksPerPattern:`long$attackCalls % 5;  // 5 calls per attack
        numAttacks:`long$attacksPerPattern % count attackPatterns;

        {[pat;num]
            bNumbers:genBNumber each 10000 + til num;
            baseTs:.z.P + `ms$1000?`int$duration*1000;  // Random times
            attacks:raze generateAttack[pat;;]'[bNumbers;baseTs];
            attackEvents,::attacks;
            attacksInjected::attacksInjected + num;
        }'[attackPatterns;numAttacks];
    ];

    // Generate legitimate events
    legitEvents:generateLegitimateTraffic legitimateCalls;

    // Combine and shuffle
    allEvents:attackEvents,legitEvents;
    allEvents:neg[count allEvents]?allEvents;  // Shuffle

    // Process events
    startTime:.z.P;
    results:.fraud.processCall each allEvents;
    endTime:.z.P;

    // Calculate metrics
    elapsed:(`float$(endTime - startTime)) % 1e9;
    alertsGenerated:.fraud.detection.alertCount;
    detectionRate:$[attacksInjected>0;alertsGenerated % attacksInjected;0f];
    avgLatency:avg .fraud.detection.latencies;
    p99Latency:$[count .fraud.detection.latencies;
                 .fraud.detection.latencies `long$0.99*count .fraud.detection.latencies;
                 0f];

    // False positive analysis
    legitAlerts:count select from .fraud.fraud_alerts where
        not any each (a_numbers in\: distinct attackEvents`a_number);

    result:`alerts_generated`attacks_injected`detection_rate`avg_latency_ms`p99_latency_ms`elapsed_seconds`false_positives`total_calls!(
        alertsGenerated;
        attacksInjected;
        detectionRate;
        avgLatency;
        p99Latency;
        elapsed;
        legitAlerts;
        count allEvents
    );

    .log.info "Simulation complete: ",(-3!result);
    result
};

// ============================================================================
// PATTERN-SPECIFIC TESTS
// ============================================================================
testPattern:{[patternName]
    .log.info "Testing pattern: ",string patternName;

    .fraud.clearTables[];
    .fraud.detection.alertCount:0;
    .fraud.config.detection[`cooldown_seconds]:0;

    bNum:genBNumber rand 99999;
    events:generateAttack[patternName;bNum;.z.P];

    // Sort by timestamp and process
    events:`ts xasc events;
    results:.fraud.processCall each events;

    detected:sum results[;`detected];
    alertCount:.fraud.detection.alertCount;

    result:`pattern`events_generated`detected`alerts!(
        patternName;count events;detected>0;alertCount
    );

    status:$[detected>0;"PASS";"FAIL"];
    .log.info "  Pattern ",string[patternName],": ",status;

    result
};

testAllPatterns:{[]
    .log.info "Testing all attack patterns...";
    pats:`sequential`burst`distributed`slowdrip`staggered`mixed;
    results:testPattern each pats;

    passed:sum results[;`detected];
    total:count pats;

    .log.info "Pattern tests: ",string[passed],"/",string[total]," passed";
    results
};

// ============================================================================
// EVASION DETECTION TESTS
// ============================================================================
testEvasionDetection:{[]
    .log.info "Testing evasion detection...";

    .fraud.clearTables[];
    .fraud.config.detection[`cooldown_seconds]:0;

    // Evasion pattern should NOT trigger (by design)
    bNum:genBNumber 88888;
    events:generateEvasion[bNum;.z.P;5];

    results:.fraud.processCall each events;
    detected:sum results[;`detected];

    // Evasion should not be detected (4 calls, gap, 4 more)
    result:`pattern`events`detected`expected_detection!(
        `evasion;count events;detected>0;0b
    );

    status:$[not detected>0;"PASS (evasion successful)";"FAIL (falsely detected)"];
    .log.info "  Evasion test: ",status;

    result
};

// ============================================================================
// STRESS TEST WITH ATTACKS
// ============================================================================
runStressWithAttacks:{[targetCPS;durationSec;attackPercent]
    .log.info "Stress test with attacks: ",string[targetCPS]," CPS, ",
              string[attackPercent],"% attacks";

    results:();

    // Run simulation
    simResult:runSimulation[targetCPS;durationSec;attackPercent%100];
    results,:enlist simResult;

    // Validate detection rate
    if[simResult[`detection_rate]<0.95;
        .log.warn "Detection rate below 95%: ",string simResult`detection_rate
    ];

    // Validate latency
    if[simResult[`p99_latency_ms]>100;
        .log.warn "P99 latency above 100ms: ",string simResult`p99_latency_ms
    ];

    results
};

\d .

// ============================================================================
// EXPORTS
// ============================================================================
// Main entry points
testAttackPatterns:.test.testAllPatterns;
runAttackSimulation:.test.runSimulation;
generateAttack:.test.generateAttack;

0N!"[INFO] attack_simulator.q loaded";
0N!"  Available functions:";
0N!"    testAttackPatterns[]           - Test all attack patterns";
0N!"    runAttackSimulation[cps;dur;rate] - Full simulation";
0N!"    .test.testPattern[`pattern]   - Test specific pattern";
