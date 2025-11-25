// metrics.q - Real-time metrics and monitoring
// Anti-Call Masking Detection System
// ===================================

\d .metrics

// ============================================================================
// METRICS STORAGE
// ============================================================================
current:`calls_per_second`alerts_per_minute`detection_latency_p50`detection_latency_p95`detection_latency_p99`false_positive_rate`active_calls`memory_used_mb`switch_connection_status`uptime_seconds`processed_total`alerts_total`disconnects_total`blocked_patterns!(
    0f;0f;0f;0f;0f;0f;0;0f;`disconnected;0f;0;0;0;0
);

// Historical metrics (ring buffer)
history:();
historyMaxSize:3600;  // 1 hour at 1-second intervals

// Latency tracking
latencyWindow:();
latencyWindowSize:1000;

// ============================================================================
// METRIC COLLECTION
// ============================================================================
collect:{[]
    now:.z.P;

    // Calls per second (last second)
    cps:count select from .fraud.calls where ts > now - 0D00:00:01;
    current[`calls_per_second]::cps;

    // Alerts per minute (last minute)
    apm:count select from .fraud.fraud_alerts where created_at > now - 0D00:01;
    current[`alerts_per_minute]::apm;

    // Detection latencies
    lats:.fraud.detection.latencies;
    if[count lats;
        sorted:asc lats;
        n:count sorted;
        current[`detection_latency_p50]::sorted `long$0.50*n;
        current[`detection_latency_p95]::sorted `long$0.95*n;
        current[`detection_latency_p99]::sorted `long$0.99*n;
    ];

    // Active calls in window
    windowSecs:.fraud.config.detection`window_seconds;
    activeCalls:count select from .fraud.calls where
        ts > now - `second$windowSecs,
        status in `active`ringing;
    current[`active_calls]::activeCalls;

    // Memory usage
    memBytes:-22!.fraud.calls;
    memMb:memBytes % 1048576;
    current[`memory_used_mb]::memMb;

    // Switch connection
    current[`switch_connection_status]::$[.fraud.switch.connected;`connected;`disconnected];

    // Totals
    current[`processed_total]::.fraud.detection.processedCount;
    current[`alerts_total]::.fraud.detection.alertCount;
    current[`disconnects_total]::.fraud.actions.disconnectCount;
    current[`blocked_patterns]::count select from .fraud.blocked_patterns where active;

    // Uptime
    if[`startTime in key `.startup;
        current[`uptime_seconds]::(`long$(now - .startup.startTime)) % 1000000000
    ];

    // Store in history
    historyEntry:current,enlist[`timestamp]!enlist now;
    history::$[historyMaxSize<count history;
        1_history,enlist historyEntry;
        history,enlist historyEntry
    ];

    current
};

// ============================================================================
// METRIC QUERIES
// ============================================================================
get:{[]current};

getHistory:{[minutes]
    cutoff:.z.P - `minute$minutes;
    select from history where timestamp>cutoff
};

getSummary:{[minutes]
    h:getHistory minutes;
    if[0=count h;:current];

    `avg_cps`max_cps`avg_latency_p99`max_latency_p99`total_alerts`avg_memory_mb!(
        avg h`calls_per_second;
        max h`calls_per_second;
        avg h`detection_latency_p99;
        max h`detection_latency_p99;
        sum h`alerts_per_minute;
        avg h`memory_used_mb
    )
};

// ============================================================================
// PROMETHEUS EXPORT
// ============================================================================
// Prometheus text format exporter
prometheus:{[]
    lines:();

    // Helper to format metric
    fmt:{[name;help;type;value]
        ("# HELP ",name," ",help;
         "# TYPE ",name," ",type;
         name," ",string value)
    };

    // Export each metric
    lines,:fmt["fraud_calls_per_second";"Current calls per second";"gauge";current`calls_per_second];
    lines,:fmt["fraud_alerts_per_minute";"Alerts generated per minute";"gauge";current`alerts_per_minute];
    lines,:fmt["fraud_detection_latency_p50_ms";"P50 detection latency";"gauge";current`detection_latency_p50];
    lines,:fmt["fraud_detection_latency_p95_ms";"P95 detection latency";"gauge";current`detection_latency_p95];
    lines,:fmt["fraud_detection_latency_p99_ms";"P99 detection latency";"gauge";current`detection_latency_p99];
    lines,:fmt["fraud_active_calls";"Active calls in detection window";"gauge";current`active_calls];
    lines,:fmt["fraud_memory_used_mb";"Memory usage in MB";"gauge";current`memory_used_mb];
    lines,:fmt["fraud_processed_total";"Total calls processed";"counter";current`processed_total];
    lines,:fmt["fraud_alerts_total";"Total alerts generated";"counter";current`alerts_total];
    lines,:fmt["fraud_disconnects_total";"Total disconnects executed";"counter";current`disconnects_total];
    lines,:fmt["fraud_blocked_patterns";"Active blocked patterns";"gauge";current`blocked_patterns];

    // Connection status (1=connected, 0=disconnected)
    connStatus:$[current[`switch_connection_status]=`connected;1;0];
    lines,:fmt["fraud_switch_connected";"Switch connection status";"gauge";connStatus];

    "\n" sv raze lines
};

// ============================================================================
// ALERTING
// ============================================================================
alertThresholds:`latency_p99_ms`memory_mb`cps_drop_percent`connection_down_seconds!(
    100f;        // Alert if P99 latency > 100ms
    3000f;       // Alert if memory > 3GB
    50f;         // Alert if CPS drops 50% from baseline
    30           // Alert if disconnected > 30 seconds
);

alertState:`latency_alerted`memory_alerted`cps_alerted`connection_alerted!(0b;0b;0b;0b);
lastConnectedTime:.z.P;
baselineCPS:0f;

checkAlerts:{[]
    alerts:();

    // Latency alert
    if[(current[`detection_latency_p99]>alertThresholds`latency_p99_ms) and not alertState`latency_alerted;
        alerts,:enlist `type`message`value!(`high_latency;"P99 latency exceeds threshold";current`detection_latency_p99);
        alertState[`latency_alerted]::1b
    ];
    if[current[`detection_latency_p99]<=alertThresholds`latency_p99_ms;
        alertState[`latency_alerted]::0b
    ];

    // Memory alert
    if[(current[`memory_used_mb]>alertThresholds`memory_mb) and not alertState`memory_alerted;
        alerts,:enlist `type`message`value!(`high_memory;"Memory usage exceeds threshold";current`memory_used_mb);
        alertState[`memory_alerted]::1b
    ];
    if[current[`memory_used_mb]<=alertThresholds`memory_mb;
        alertState[`memory_alerted]::0b
    ];

    // Connection alert
    if[current[`switch_connection_status]=`connected;
        lastConnectedTime::.z.P;
        alertState[`connection_alerted]::0b
    ];
    if[current[`switch_connection_status]=`disconnected;
        downSeconds:(`long$(.z.P - lastConnectedTime)) % 1000000000;
        if[(downSeconds>alertThresholds`connection_down_seconds) and not alertState`connection_alerted;
            alerts,:enlist `type`message`value!(`connection_down;"Switch disconnected";downSeconds);
            alertState[`connection_alerted]::1b
        ]
    ];

    // Send alerts
    if[count alerts;
        sendAlerts alerts
    ];

    alerts
};

// ============================================================================
// ALERT DISPATCH
// ============================================================================
webhookUrl:"";  // Configure for external alerting

sendAlerts:{[alerts]
    {
        .log.warnCtx["Operational alert";x];

        // Send to webhook if configured
        if[0<count webhookUrl;
            payload:.j.j `timestamp`alerts!(.z.P;alerts);
            // Would use HTTP client here
            // .http.post[webhookUrl;payload]
        ]
    } each alerts
};

configureWebhook:{[url]
    webhookUrl::url;
    .log.info "Webhook configured: ",url
};

// ============================================================================
// TIMER INTEGRATION
// ============================================================================
// Call this from main timer
tick:{[]
    collect[];
    checkAlerts[];
};

// ============================================================================
// HTTP ENDPOINTS (if enabled)
// ============================================================================
// These integrate with kdb+ HTTP server

handleMetrics:{[req]
    // GET /metrics - Prometheus format
    (`$"Content-Type: text/plain";prometheus[])
};

handleMetricsJson:{[req]
    // GET /metrics/json - JSON format
    (`$"Content-Type: application/json";.j.j current)
};

handleHealth:{[req]
    health:`status`checks!(
        $[all checks;`healthy;`unhealthy];
        checks:`switch`memory`latency!(
            current[`switch_connection_status]=`connected;
            current[`memory_used_mb]<alertThresholds`memory_mb;
            current[`detection_latency_p99]<alertThresholds`latency_p99_ms
        )
    );
    (`$"Content-Type: application/json";.j.j health)
};

// Register HTTP handlers (if HTTP server enabled)
registerHttpHandlers:{[]
    // .z.ph handler for HTTP GET requests
    // Implementation depends on HTTP library used
    .log.info "HTTP handlers registered"
};

\d .

0N!"[INFO] metrics.q loaded successfully";
