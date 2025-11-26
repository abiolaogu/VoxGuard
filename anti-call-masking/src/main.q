// main.q - Entry point for Anti-Call Masking Detection System
// ===================================
// Load all modules and start the detection service

// ============================================================================
// STARTUP BANNER
// ============================================================================
show "====================================================================";
show "  Anti-Call Masking Detection System";
show "  Real-time fraud detection using kdb+/q";
show "====================================================================";
show "";

// ============================================================================
// LOAD MODULES
// ============================================================================
srcDir:first ` vs hsym .z.f;
if[srcDir~`;srcDir:`:.];

show "[STARTUP] Loading modules from: ",string srcDir;

// Load in dependency order
\l config.q
\l schema.q
\l logging.q
\l detection.q
\l actions.q
\l switch_adapter.q
\l http_server.q

show "";
show "[STARTUP] All modules loaded successfully";

// ============================================================================
// COMMAND LINE ARGUMENTS
// ============================================================================
// Parse command line args: -port 5012 -switch_host 127.0.0.1 -switch_port 8021
.startup.parseArgs:{[]
    args:.z.x;
    if[0=count args;:()];

    i:0;
    while[i<count args;
        arg:args i;
        if[arg like "-*";
            key:`$1_arg;
            if[(i+1)<count args;
                val:args i+1;
                // Try to parse as number
                numVal:@["J"$;val;val];
                .startup.args[key]:$[numVal~0N;val;numVal];
                i+:1;
            ];
        ];
        i+:1;
    ];
 };

.startup.args:()!();
.startup.parseArgs[];

// Apply command line overrides
if[`port in key .startup.args;
    .fraud.config.ipc[`port]:.startup.args`port];
if[`switch_host in key .startup.args;
    .fraud.config.switch[`host]:.startup.args`switch_host];
if[`switch_port in key .startup.args;
    .fraud.config.switch[`port]:.startup.args`switch_port];
if[`window in key .startup.args;
    .fraud.config.detection[`window_seconds]:.startup.args`window];
if[`threshold in key .startup.args;
    .fraud.config.detection[`min_distinct_a]:.startup.args`threshold];

// ============================================================================
// IPC SERVER SETUP
// ============================================================================
.startup.startIPCServer:{[]
    port:.fraud.config.ipc`port;
    show "[STARTUP] Starting IPC server on port ",string port;

    // Open port
    result:@[system;"p ",string port;{show "[ERROR] Failed to start IPC: ",x;0b}];

    if[result~0b;:0b];

    // Set up handlers
    .z.pw:{[user;pass]1b};  // Authentication (customize for production)

    .z.po:{[h]
        show "[IPC] Client connected: ",string h;
    };

    .z.pc:{[h]
        show "[IPC] Client disconnected: ",string h;
    };

    .z.pg:{[msg]
        // Handle sync queries
        .startup.handleQuery msg
    };

    .z.ps:{[msg]
        // Handle async messages
        .startup.handleQuery msg
    };

    show "[STARTUP] IPC server started successfully";
    1b
 };

// ============================================================================
// QUERY HANDLER
// ============================================================================
.startup.handleQuery:{[msg]
    // msg can be:
    // - Function call: `.fraud.processCall[event]
    // - String command: "status"
    // - Dictionary: `cmd`data!(`process;eventDict)

    if[10h=type msg;
        // String command
        :.startup.handleCommand msg
    ];

    if[99h=type msg;
        // Dictionary command
        cmd:msg`cmd;
        data:msg`data;
        :$[
            cmd=`process;.fraud.processCall data;
            cmd=`status;.startup.getStatus[];
            cmd=`stats;.fraud.detection.getStats[];
            cmd=`alerts;.fraud.detection.getRecentAlerts data;
            cmd=`disconnect;.fraud.actions.manualDisconnect data;
            cmd=`whitelist_add;.fraud.actions.addToWhitelist data;
            cmd=`whitelist_remove;.fraud.actions.removeFromWhitelist data;
            `error`message!(`unknown_command;"Unknown command: ",string cmd)
        ]
    ];

    // Execute as q expression
    @[value;msg;{`error`message!(`execution_error;x)}]
 };

.startup.handleCommand:{[cmd]
    $[
        cmd~"status";.startup.getStatus[];
        cmd~"stats";.fraud.detection.getStats[];
        cmd~"health";.startup.healthCheck[];
        cmd~"help";.startup.showHelp[];
        cmd~"tables";.fraud.tableSizes[];
        cmd~"memory";.fraud.memoryUsage[];
        cmd~"config";.fraud.showConfig[];
        cmd like "alerts*";.fraud.detection.getRecentAlerts "J"$5_cmd;
        `error`message!(`unknown_command;"Unknown command. Try 'help'")
    ]
 };

// ============================================================================
// STATUS AND HEALTH
// ============================================================================
.startup.getStatus:{[]
    `status`uptime`calls_processed`alerts_generated`switch_connected`active_calls!(
        `running;
        .z.P - .startup.startTime;
        .fraud.detection.processedCount;
        .fraud.detection.alertCount;
        .fraud.switch.connected;
        count select from .fraud.calls where status in `active`ringing
    )
 };

.startup.healthCheck:{[]
    switchHealth:.fraud.switch.healthCheck[];
    detectionStats:.fraud.detection.getStats[];
    actionStats:.fraud.actions.getStats[];

    checks:`ipc`switch`detection`memory!(1b;switchHealth`status=`connected;1b;1b);

    // Memory check
    memMb:first exec mb from .fraud.memoryUsage[] where table=`TOTAL;
    if[memMb>3000;checks[`memory]:0b];

    overall:all value checks;

    `healthy`checks`detection`actions`switch!(
        overall;checks;detectionStats;actionStats;switchHealth
    )
 };

// ============================================================================
// HELP
// ============================================================================
.startup.showHelp:{[]
    help:(
        "Anti-Call Masking Detection System - Commands";
        "==============================================";
        "";
        "IPC Commands (send as string or dictionary):";
        "  status         - Get system status";
        "  stats          - Get detection statistics";
        "  health         - Full health check";
        "  tables         - Get table sizes";
        "  memory         - Get memory usage";
        "  config         - Show configuration";
        "  alerts N       - Get alerts from last N minutes";
        "  help           - Show this help";
        "";
        "Dictionary Commands:";
        "  `cmd`data!(`process;eventDict)      - Process call event";
        "  `cmd`data!(`disconnect;rawCallId)   - Manual disconnect";
        "  `cmd`data!(`whitelist_add;bNum)     - Add to whitelist";
        "";
        "Direct Function Calls:";
        "  .fraud.processCall[event]           - Process call event";
        "  .fraud.detection.getThreatLevel[bNum]   - Get threat level";
        "  .fraud.switch.simulateCall[aNum;bNum]   - Simulate call";
        ""
    );
    "\n" sv help
 };

// ============================================================================
// PERIODIC TASKS
// ============================================================================
.startup.setupTimers:{[]
    // Stats recording (every 10 seconds)
    .z.ts:{
        .fraud.detection.recordStats[];
        .fraud.detection.runGC[];
    };
    system "t 10000";

    show "[STARTUP] Periodic tasks configured";
 };

// ============================================================================
// GRACEFUL SHUTDOWN
// ============================================================================
.startup.shutdown:{[]
    show "";
    show "[SHUTDOWN] Initiating graceful shutdown...";

    // Disconnect from switch
    .fraud.switch.disconnect[];

    // Record final stats
    .fraud.detection.recordStats[];

    show "[SHUTDOWN] Shutdown complete";
    exit 0;
 };

// Register shutdown handler
.z.exit:{.startup.shutdown[]};

// ============================================================================
// MAIN STARTUP
// ============================================================================
.startup.main:{[]
    .startup.startTime:.z.P;

    // Create required directories
    @[system;"mkdir -p logs";{}];
    @[system;"mkdir -p archive";{}];
    @[system;"mkdir -p data";{}];

    // Start IPC server
    if[not .startup.startIPCServer[];
        show "[ERROR] Failed to start IPC server. Exiting.";
        exit 1;
    ];

    // Start HTTP server for Voice Switch integration
    if[.fraud.config.http`enabled;
        show "[STARTUP] Starting HTTP server for Voice Switch integration...";
        httpPort: .fraud.config.http`port;
        if[.http.start[httpPort];
            show "[STARTUP] HTTP server started on port ", string httpPort;
        ;
            show "[WARN] Failed to start HTTP server. Voice Switch integration disabled.";
        ];
    ];

    // Setup periodic tasks
    .startup.setupTimers[];

    // Connect to switch (if configured and not using voiceswitch protocol)
    switchProtocol: .fraud.config.switch`protocol;
    if[not "-noswitch" in .z.x;
        if[not switchProtocol = `voiceswitch;
            // For voiceswitch protocol, calls come via HTTP - no active connection needed
            show "[STARTUP] Connecting to voice switch...";
            connected:.fraud.switch.connect[];
            if[not connected;
                show "[WARN] Failed to connect to switch. Running in standalone mode.";
                show "       Use simulation mode for testing: .fraud.switch.enableSimulation[]";
            ];
        ;
            show "[STARTUP] Voice Switch protocol enabled - waiting for HTTP events";
            .fraud.switch.connected: 1b;  // Mark as connected for voiceswitch protocol
        ];
    ];

    show "";
    show "====================================================================";
    show "  System Ready";
    show "  IPC Port: ",string .fraud.config.ipc`port;
    show "  HTTP Port: ",string .fraud.config.http`port;
    show "  Protocol: ",string .fraud.config.switch`protocol;
    show "  Detection Window: ",string[.fraud.config.detection`window_seconds]," seconds";
    show "  Threshold: ",string[.fraud.config.detection`min_distinct_a]," distinct A-numbers";
    show "====================================================================";
    show "";
    show "Quick Start:";
    show "  .fraud.switch.enableSimulation[]           // Enable test mode";
    show "  .fraud.switch.simulateAttack[\"B123\";5;0]   // Simulate attack";
    show "  .fraud.detection.getStats[]                // View statistics";
    show "";
    show "HTTP API Endpoints:";
    show "  POST /event         - Submit call event";
    show "  POST /events/batch  - Submit batch of events";
    show "  GET  /alerts        - Get fraud alerts";
    show "  GET  /stats         - Get detection statistics";
    show "  GET  /health        - Health check";
    show "";
 };

// Run main
.startup.main[];
