// recovery.q - State persistence and recovery
// Anti-Call Masking Detection System
// ===================================

\d .recovery

// ============================================================================
// CONFIGURATION
// ============================================================================
config:`checkpointDir`checkpointInterval`maxCheckpoints`enableAutoSave!(
    `:checkpoints;         // Directory for checkpoints
    300;                   // Checkpoint every 5 minutes
    10;                    // Keep last 10 checkpoints
    1b                     // Auto-save enabled
);

// State tracking
lastCheckpoint:.z.P;
checkpointCount:0;

// ============================================================================
// CHECKPOINT FUNCTIONS
// ============================================================================

// Save current state to checkpoint
saveCheckpoint:{[]
    ts:`long$.z.P;
    dir:config`checkpointDir;

    // Create checkpoint directory
    @[system;"mkdir -p ",string dir;{}];

    // Build checkpoint filename
    filename:`$string[dir],"/checkpoint_",string[ts];

    // Save tables
    tables:`fraud_alerts`blocked_patterns`cooldowns`stats;
    {[fn;t]
        path:`$string[fn],"_",string t;
        data:value `.fraud,t;
        @[path set;data;{.log.error "Checkpoint save failed for ",string[y],": ",x}[;t]]
    }[filename] each tables;

    // Save config
    configPath:`$string[filename],"_config";
    @[configPath set;.fraud.config;{.log.error "Config save failed: ",x}];

    // Save metrics
    metricsPath:`$string[filename],"_metrics";
    @[metricsPath set;.metrics.current;{.log.error "Metrics save failed: ",x}];

    // Update state
    lastCheckpoint::.z.P;
    checkpointCount+:1;

    // Cleanup old checkpoints
    cleanupOldCheckpoints[];

    .log.info "Checkpoint saved: ",string filename;
    filename
};

// List available checkpoints
listCheckpoints:{[]
    dir:string config`checkpointDir;
    files:@[system;"ls -1 ",dir," 2>/dev/null | grep checkpoint_ | sort -r";()];
    if[10h<>type files;:()];

    // Parse checkpoint info
    checkpoints:{
        parts:"_" vs x;
        if[2>count parts;:()];
        ts:"J"$last parts;
        `filename`timestamp`age_minutes!(
            `$x;
            "P"$string ts;
            `long$(.z.P - "P"$string ts) % 60000000000
        )
    } each files;

    checkpoints where 0<count each checkpoints
};

// Load checkpoint
loadCheckpoint:{[checkpointName]
    dir:config`checkpointDir;

    if[null checkpointName;
        // Load latest
        cps:listCheckpoints[];
        if[0=count cps;
            .log.warn "No checkpoints found";
            :0b
        ];
        checkpointName:first cps`filename
    ];

    .log.info "Loading checkpoint: ",string checkpointName;

    basePath:`$string[dir],"/",string checkpointName;

    // Load tables
    tables:`fraud_alerts`blocked_patterns`cooldowns`stats;
    {[bp;t]
        path:`$string[bp],"_",string t;
        data:@[get;path;()];
        if[count data;
            // Clear and reload
            delete from `.fraud,t;
            `.fraud,t upsert data;
            .log.info "  Loaded ",string[t],": ",string[count data]," rows"
        ]
    }[basePath] each tables;

    // Load config (optional - may want to keep current config)
    configPath:`$string[basePath],"_config";
    savedConfig:@[get;configPath;()];
    if[99h=type savedConfig;
        .log.info "  Config available in checkpoint (not auto-applied)"
    ];

    .log.info "Checkpoint loaded successfully";
    1b
};

// Cleanup old checkpoints
cleanupOldCheckpoints:{[]
    cps:listCheckpoints[];
    if[count[cps]<=config`maxCheckpoints;:()];

    toDelete:(config`maxCheckpoints) _ cps;
    {
        dir:string config`checkpointDir;
        pattern:string[x`filename],"*";
        @[system;"rm -f ",dir,"/",pattern;{}];
        .log.debug "Deleted checkpoint: ",string x`filename
    } each toDelete
};

// ============================================================================
// AUTO-SAVE TIMER
// ============================================================================
maybeCheckpoint:{[]
    if[not config`enableAutoSave;:()];

    intervalNs:`long$config[`checkpointInterval] * 1000000000;
    if[(.z.P - lastCheckpoint) > intervalNs;
        saveCheckpoint[]
    ]
};

// ============================================================================
// RECOVERY ON STARTUP
// ============================================================================
recover:{[]
    .log.info "Starting recovery process...";

    // Check for checkpoints
    cps:listCheckpoints[];
    if[0=count cps;
        .log.info "No checkpoints found, starting fresh";
        :1b
    ];

    latest:first cps;
    .log.info "Found ",string[count cps]," checkpoints, latest: ",string latest`filename;
    .log.info "  Age: ",string[latest`age_minutes]," minutes";

    // Prompt for recovery (in production, this would be automatic or configured)
    // For now, auto-recover if checkpoint is less than 1 hour old
    if[latest[`age_minutes]<60;
        .log.info "Auto-recovering from recent checkpoint...";
        loadCheckpoint latest`filename;
        :1b
    ];

    .log.warn "Checkpoint is ",string[latest`age_minutes]," minutes old";
    .log.warn "Call .recovery.loadCheckpoint[] to manually recover";
    0b
};

// ============================================================================
// GRACEFUL SHUTDOWN
// ============================================================================
prepareShutdown:{[]
    .log.info "Preparing for shutdown...";

    // Save final checkpoint
    saveCheckpoint[];

    // Flush any pending actions
    .fraud.actions.processQueue[];

    // Close connections
    .fraud.switch.disconnect[];

    // Final log
    .log.info "Shutdown preparation complete";
};

// Register shutdown handler
registerShutdownHandler:{[]
    origExit:.z.exit;
    .z.exit:{
        prepareShutdown[];
        // Call original handler if exists
        if[not null origExit;origExit[]];
        exit 0
    };
    .log.info "Shutdown handler registered"
};

// ============================================================================
// HOT CONFIG RELOAD
// ============================================================================
reloadConfig:{[]
    .log.info "Reloading configuration...";

    // Store current config
    oldConfig:.fraud.config;

    // Re-read config file
    configFile:`:src/config.q;
    result:@[system;"l ",string configFile;{`error}];

    if[result~`error;
        .log.error "Failed to reload config file";
        :0b
    ];

    // Validate new config
    if[not .fraud.validateConfig[];
        .log.error "Config validation failed, reverting";
        .fraud.config::oldConfig;
        :0b
    ];

    // Log changes
    newConfig:.fraud.config;
    {[section]
        old:oldConfig section;
        new:newConfig section;
        if[not old~new;
            changes:key[new] where not (value new)~'old value new;
            {[s;k]
                .log.configChange[s;k;oldConfig[s;k];newConfig[s;k]]
            }[section] each changes
        ]
    } each `detection`actions`whitelist`switch;

    .log.info "Configuration reloaded successfully";
    1b
};

// Update specific config value
updateConfig:{[section;key;value]
    cfg:`.fraud.config,section;
    if[not key in key value cfg;
        .log.error "Invalid config key: ",string[section],".",string key;
        :0b
    ];

    oldValue:(value cfg) key;
    @[cfg;key;:;value];

    .log.configChange[section;key;oldValue;value];
    1b
};

// ============================================================================
// RATE LIMITING & BACKPRESSURE
// ============================================================================
backpressure:`enabled`queueThreshold`dropRate`currentlyActive!(
    1b;         // Enable backpressure
    10000;      // Queue size threshold
    0.1;        // Drop 10% of calls when overloaded
    0b          // Currently in backpressure mode
);

checkBackpressure:{[]
    if[not backpressure`enabled;:0b];

    // Check queue size (pending actions)
    queueSize:count .fraud.actions.queue;
    if[queueSize>backpressure`queueThreshold;
        if[not backpressure`currentlyActive;
            .log.warn "Backpressure activated, queue size: ",string queueSize;
            backpressure[`currentlyActive]::1b
        ];
        :1b
    ];

    if[backpressure`currentlyActive;
        .log.info "Backpressure deactivated";
        backpressure[`currentlyActive]::0b
    ];
    0b
};

shouldDropCall:{[]
    if[not backpressure`currentlyActive;:0b];
    // Randomly drop based on drop rate
    (rand 1.0) < backpressure`dropRate
};

// ============================================================================
// CIRCUIT BREAKER
// ============================================================================
circuitBreaker:`state`failures`threshold`resetAfter`lastFailure!(
    `closed;    // closed, open, half-open
    0;          // Current failure count
    5;          // Failures before opening
    30;         // Seconds before trying half-open
    .z.P        // Last failure time
);

recordSuccess:{[]
    if[circuitBreaker[`state]=`half_open;
        circuitBreaker[`state]::`closed;
        circuitBreaker[`failures]::0;
        .log.info "Circuit breaker closed"
    ]
};

recordFailure:{[]
    circuitBreaker[`failures]+:1;
    circuitBreaker[`lastFailure]::.z.P;

    if[circuitBreaker[`failures]>=circuitBreaker`threshold;
        if[circuitBreaker[`state]<>`open;
            circuitBreaker[`state]::`open;
            .log.warn "Circuit breaker opened after ",string[circuitBreaker`failures]," failures"
        ]
    ]
};

isCircuitOpen:{[]
    if[circuitBreaker[`state]=`closed;:0b];

    if[circuitBreaker[`state]=`open;
        // Check if we should try half-open
        elapsed:(`long$(.z.P - circuitBreaker`lastFailure)) % 1000000000;
        if[elapsed>circuitBreaker`resetAfter;
            circuitBreaker[`state]::`half_open;
            .log.info "Circuit breaker half-open, testing...";
            :0b
        ];
        :1b
    ];

    0b  // half-open allows requests
};

\d .

// Register shutdown handler on load
.recovery.registerShutdownHandler[];

0N!"[INFO] recovery.q loaded successfully";
