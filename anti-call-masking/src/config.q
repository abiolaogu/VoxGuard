// config.q - Configuration parameters for fraud detection system
// Anti-Call Masking Detection System
// ===================================

\d .fraud

// Detection Configuration
config.detection:`window_seconds`min_distinct_a`cooldown_seconds`max_window_calls!(
    5;          // Sliding window duration in seconds
    5;          // Minimum distinct A-numbers to trigger alert
    60;         // Cooldown period per B-number (prevent alert spam)
    10000       // Maximum calls to keep in window (memory limit)
);

// Action Configuration
config.actions:`auto_disconnect`disconnect_delay_ms`notify_enabled`block_duration_seconds!(
    1b;         // Automatically disconnect flagged calls
    0;          // Delay before disconnect (0 = immediate)
    1b;         // Send notifications on detection
    3600        // Duration to block detected patterns (1 hour)
);

// Whitelist Configuration (exempt from detection)
config.whitelist:`b_numbers`a_number_prefixes`call_centers!(
    `symbol$();                     // Specific B-numbers to exempt
    `symbol$();                     // A-number prefixes to exempt (e.g., `$"+1800")
    `symbol$()                      // Known call center identifiers
);

// Switch Connection Configuration
config.switch:`host`port`protocol`auth_password`reconnect_max_attempts`reconnect_backoff_ms`api_url!(
    "127.0.0.1";                    // Switch event stream host
    8021i;                          // Switch event stream port (FreeSWITCH ESL default)
    `freeswitch;                    // Protocol: `freeswitch`kamailio`voiceswitch`generic
    "ClueCon";                      // Authentication password
    10;                             // Max reconnection attempts
    1000;                           // Initial backoff in ms (doubles each attempt)
    ""                              // Voice Switch API URL (for voiceswitch protocol)
);

// HTTP Server Configuration (for Voice Switch integration)
config.http:`enabled`port`cors_enabled`webhook_url`webhook_secret!(
    1b;                             // Enable HTTP server
    5000i;                          // HTTP server port
    1b;                             // Enable CORS
    "";                             // Webhook URL for sending alerts
    ""                              // Webhook secret for authentication
);

// IPC Server Configuration
config.ipc:`port`admin_port`max_connections!(
    5012i;                          // Main detection service port
    5013i;                          // Admin/monitoring port
    100i                            // Maximum concurrent connections
);

// Logging Configuration
config.logging:`level`file`rotate_size_mb`retain_days!(
    `INFO;                          // Log level: `DEBUG`INFO`WARN`ERROR
    ":logs/fraud_detection.log";    // Log file path (: prefix for kdb+ file handle)
    100;                            // Rotate log when it reaches this size
    30                              // Retain logs for this many days
);

// Performance Tuning
config.performance:`gc_interval_ms`batch_size`async_writes!(
    1000;                           // Garbage collection interval
    100;                            // Batch size for bulk operations
    1b                              // Use async writes to disk
);

// Metrics Configuration
config.metrics:`enabled`export_interval_seconds`prometheus_port!(
    1b;                             // Enable metrics collection
    10;                             // Export metrics every N seconds
    9090i                           // Prometheus metrics port
);

\d .

// Helper functions for configuration
.fraud.getConfig:{[section;key]
    cfg:`.fraud.config,section;
    $[key in key value cfg;(value cfg)key;
      [0N!"[WARN] Config key not found: ",string[section],".",string key;`]
    ]
 };

.fraud.setConfig:{[section;key;val]
    cfg:`.fraud.config,section;
    if[key in key value cfg;
        @[cfg;key;:;val];
        0N!"[INFO] Config updated: ",string[section],".",string[key]," = ",(-3!val);
        :1b
    ];
    0N!"[WARN] Config key not found: ",string[section],".",string key;
    0b
 };

.fraud.showConfig:{[]
    sections:`detection`actions`whitelist`switch`ipc`logging`performance`metrics;
    {0N!string[x]," = ",(-3!value `.fraud.config,x)} each sections;
 };

// Validate configuration on load
.fraud.validateConfig:{[]
    errors:();

    // Check detection window is reasonable (1-60 seconds)
    if[not .fraud.config.detection[`window_seconds] within 1 60;
        errors,:enlist"window_seconds must be between 1 and 60"];

    // Check threshold is reasonable (2-100)
    if[not .fraud.config.detection[`min_distinct_a] within 2 100;
        errors,:enlist"min_distinct_a must be between 2 and 100"];

    // Check port ranges
    if[not .fraud.config.ipc[`port] within 1024 65535;
        errors,:enlist"ipc.port must be between 1024 and 65535"];

    if[count errors;
        0N!"[ERROR] Configuration validation failed:";
        {0N!"  - ",x} each errors;
        :0b
    ];

    0N!"[INFO] Configuration validated successfully";
    1b
 };

// Run validation
.fraud.validateConfig[];

// ============================================================================
// ENVIRONMENT VARIABLE OVERRIDES
// Allow configuration via environment variables for Docker/Kubernetes
// ============================================================================
.fraud.loadEnvConfig:{[]
    // Detection settings
    if[count getenv`DETECTION_WINDOW_SEC;
        config.detection[`window_seconds]: "I"$getenv`DETECTION_WINDOW_SEC];
    if[count getenv`DETECTION_THRESHOLD;
        config.detection[`min_distinct_a]: "I"$getenv`DETECTION_THRESHOLD];

    // Switch settings
    if[count getenv`SWITCH_PROTOCOL;
        config.switch[`protocol]: `$getenv`SWITCH_PROTOCOL];
    if[count getenv`SWITCH_HOST;
        config.switch[`host]: getenv`SWITCH_HOST];
    if[count getenv`SWITCH_PORT;
        config.switch[`port]: "I"$getenv`SWITCH_PORT];
    if[count getenv`VOICE_SWITCH_API_URL;
        config.switch[`api_url]: getenv`VOICE_SWITCH_API_URL];

    // HTTP server settings
    if[count getenv`HTTP_PORT;
        config.http[`port]: "I"$getenv`HTTP_PORT];
    if[count getenv`WEBHOOK_URL;
        config.http[`webhook_url]: getenv`WEBHOOK_URL];
    if[count getenv`WEBHOOK_SECRET;
        config.http[`webhook_secret]: getenv`WEBHOOK_SECRET];

    // Metrics settings
    if[count getenv`PROMETHEUS_PORT;
        config.metrics[`prometheus_port]: "I"$getenv`PROMETHEUS_PORT];
    if[count getenv`METRICS_ENABLED;
        config.metrics[`enabled]: "B"$getenv`METRICS_ENABLED];

    // Logging settings
    if[count getenv`LOG_LEVEL;
        config.logging[`level]: `$upper getenv`LOG_LEVEL];

    0N!"[INFO] Environment configuration loaded";
 };

// Load environment overrides
.fraud.loadEnvConfig[];

0N!"[INFO] config.q loaded successfully";
