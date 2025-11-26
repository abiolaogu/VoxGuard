// http_server.q - HTTP API Server for Voice Switch Integration
// Anti-Call Masking Detection System
// ===================================
// Exposes REST API for call events and fraud detection status

\d .http

// ============================================================================
// SERVER CONFIGURATION
// ============================================================================
server.port: 5000;
server.host: "";  // Bind to all interfaces
server.running: 0b;

// ============================================================================
// HTTP RESPONSE HELPERS
// ============================================================================

// JSON response with status code
response:{[status; body]
    statusText: $[
        status = 200; "OK";
        status = 201; "Created";
        status = 202; "Accepted";
        status = 204; "No Content";
        status = 400; "Bad Request";
        status = 404; "Not Found";
        status = 500; "Internal Server Error";
        "Unknown"];

    headers: "HTTP/1.1 ", string[status], " ", statusText, "\r\n",
             "Content-Type: application/json\r\n",
             "Access-Control-Allow-Origin: *\r\n",
             "Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS\r\n",
             "Access-Control-Allow-Headers: Content-Type, Authorization\r\n",
             "Connection: close\r\n",
             "Content-Length: ", string[count body], "\r\n\r\n";

    headers, body
 };

jsonResponse:{[status; data]
    response[status; .j.j data]
 };

// ============================================================================
// REQUEST PARSING
// ============================================================================

// Parse HTTP request
parseRequest:{[req]
    lines: "\r\n" vs req;
    if[0 = count lines; :`error`empty_request];

    // Parse request line
    parts: " " vs first lines;
    if[3 > count parts; :`error`invalid_request];

    method: parts 0;
    pathQuery: parts 1;

    // Split path and query string
    qIdx: pathQuery ? "?";
    path: $[qIdx < count pathQuery; qIdx # pathQuery; pathQuery];
    query: $[qIdx < count pathQuery; parseQuery (qIdx + 1) _ pathQuery; ()!()];

    // Find body (after empty line)
    bodyIdx: lines ? "";
    body: $[bodyIdx < count lines - 1;
            "\r\n" sv (bodyIdx + 1) _ lines;
            ""];

    `method`path`query`body!(method; path; query; body)
 };

// Parse query string
parseQuery:{[qs]
    if[0 = count qs; :()!()];
    pairs: "&" vs qs;
    dict: ()!();
    {
        kv: "=" vs x;
        if[2 = count kv;
            dict[`$kv 0]: kv 1];
    } each pairs;
    dict
 };

// Parse JSON body safely
parseBody:{[body]
    if[0 = count body; :()!()];
    @[.j.k; body; {`error`parse_error}]
 };

// ============================================================================
// ROUTE HANDLERS
// ============================================================================

// Health check
handleHealth:{[req]
    jsonResponse[200; `status`timestamp`version!(
        "healthy";
        .z.P;
        "1.0.0")]
 };

// Call event endpoint - receives events from Voice Switch
handleEvent:{[req]
    body: parseBody req`body;
    if[`error`parse_error ~ body;
        :jsonResponse[400; `error`"Invalid JSON body"]
    ];

    // Validate required fields
    if[not all `call_id`a_number`b_number in key body;
        :jsonResponse[400; `error`"Missing required fields: call_id, a_number, b_number"]
    ];

    // Process the call event
    event: `call_id`a_number`b_number`ts`status`switch_id`raw_call_id!(
        `$body`call_id;
        body`a_number;
        body`b_number;
        $[`timestamp in key body; "P"$body`timestamp; .z.P];
        $[`status in key body; `$body`status; `active];
        $[`switch_id in key body; `$body`switch_id; `voiceswitch];
        $[`call_id in key body; `$body`call_id; `$first 1?0Ng]
    );

    result: @[.fraud.processCall; event; {`error, x}];

    if[`error ~ first result;
        :jsonResponse[500; `error`"Processing failed", `details, last result]
    ];

    jsonResponse[200; `status`detected`alert_id!(
        "processed";
        result 0;
        $[result 0; string result 1; ""])]
 };

// Batch events endpoint
handleEventBatch:{[req]
    body: parseBody req`body;
    if[`error`parse_error ~ body;
        :jsonResponse[400; `error`"Invalid JSON body"]
    ];

    events: $[`events in key body; body`events; body];
    if[not 99h = type events;
        if[not 0h = type events;
            :jsonResponse[400; `error`"Expected array of events"]]
    ];

    processed: 0;
    detected: 0;

    processOne: {[e]
        event: `call_id`a_number`b_number`ts`status`switch_id`raw_call_id!(
            `$e`call_id;
            e`a_number;
            e`b_number;
            $[`timestamp in key e; "P"$e`timestamp; .z.P];
            $[`status in key e; `$e`status; `active];
            $[`switch_id in key e; `$e`switch_id; `voiceswitch];
            $[`call_id in key e; `$e`call_id; `$first 1?0Ng]
        );
        .fraud.processCall event
    };

    results: processOne each events;
    processed: count results;
    detected: sum results[;0];

    jsonResponse[200; `status`processed`detected!(
        "batch_processed";
        processed;
        detected)]
 };

// Get alerts
handleAlerts:{[req]
    minutes: $[`minutes in key req`query;
               "I"$req[`query]`minutes;
               60];

    alerts: .fraud.detection.getRecentAlerts[minutes];

    // Convert to JSON-friendly format
    alertList: {
        `alert_id`b_number`a_numbers`call_count`severity`action`detected_at!(
            string x`alert_id;
            string x`b_number;
            string each x`a_numbers;
            x`call_count;
            $[x`call_count >= 10; "critical"; x`call_count >= 7; "high"; "medium"];
            string x`action;
            string x`created_at)
    } each alerts;

    jsonResponse[200; alertList]
 };

// Get detection stats
handleStats:{[req]
    stats: .fraud.detection.getStats[];
    jsonResponse[200; stats]
 };

// Get elevated threats
handleThreats:{[req]
    threats: .fraud.detection.getElevatedThreats[];
    jsonResponse[200; 0!threats]
 };

// Get threat level for specific B-number
handleThreatLevel:{[req]
    bNum: $[`b_number in key req`query;
            `$req[`query]`b_number;
            `];

    if[null bNum;
        :jsonResponse[400; `error`"Missing required parameter: b_number"]
    ];

    level: .fraud.detection.getThreatLevel[bNum];
    jsonResponse[200; level]
 };

// Configuration endpoint
handleConfig:{[req]
    if[req[`method] ~ "GET";
        :jsonResponse[200; `window_seconds`threshold`auto_disconnect!(
            .fraud.windowNs % 1000000000;
            .fraud.threshold;
            .fraud.config.actions`auto_disconnect)]
    ];

    if[req[`method] ~ "POST";
        body: parseBody req`body;

        if[`window_seconds in key body;
            .fraud.setWindow["I"$body`window_seconds]];

        if[`threshold in key body;
            .fraud.setThreshold["I"$body`threshold]];

        if[`auto_disconnect in key body;
            .fraud.config.actions[`auto_disconnect]: body`auto_disconnect];

        :jsonResponse[200; `status`"config_updated"]
    ];

    jsonResponse[400; `error`"Method not allowed"]
 };

// Active calls endpoint
handleActiveCalls:{[req]
    windowStart: .z.P - .fraud.windowNs;
    active: select from .fraud.calls
        where ts > windowStart, status in `active`ringing;

    callList: {
        `call_id`a_number`b_number`timestamp`status!(
            string x`call_id;
            string x`a_number;
            string x`b_number;
            string x`ts;
            string x`status)
    } each active;

    jsonResponse[200; `active_calls`count!(callList; count active)]
 };

// ============================================================================
// ROUTING
// ============================================================================

route:{[req]
    path: req`path;
    method: req`method;

    // Handle CORS preflight
    if[method ~ "OPTIONS";
        :response[204; ""]
    ];

    // Route to handlers
    $[
        path ~ "/health";      handleHealth[req];
        path ~ "/event";       handleEvent[req];
        path ~ "/events/batch"; handleEventBatch[req];
        path ~ "/alerts";      handleAlerts[req];
        path ~ "/stats";       handleStats[req];
        path ~ "/threats";     handleThreats[req];
        path ~ "/threat";      handleThreatLevel[req];
        path ~ "/config";      handleConfig[req];
        path ~ "/calls/active"; handleActiveCalls[req];
        // Default: 404
        jsonResponse[404; `error`"Not found"]
    ]
 };

// ============================================================================
// TCP SERVER
// ============================================================================

// Handle incoming HTTP connection
handleConnection:{[h]
    // Set handler for this connection
    .z.pg:{[x] .http.handleRequest[.z.w; x]};
 };

handleRequest:{[h; req]
    parsed: parseRequest req;
    if[`error ~ first parsed;
        :response[400; .j.j `error`"Invalid request"]
    ];

    result: @[route; parsed; {response[500; .j.j `error, x]}];
    result
 };

// Start the HTTP server
start:{[port]
    if[server.running;
        .log.warn "Server already running";
        :0b
    ];

    // Get port from env or parameter
    p: $[null port;
         $[count getenv`HTTP_PORT; "I"$getenv`HTTP_PORT; server.port];
         port];

    // Set up TCP listener
    system "p ", string p;

    // Set up connection handler
    .z.po: {.log.info "Connection from ", string .z.a};
    .z.pc: {.log.info "Connection closed: ", string x};
    .z.pg: {.http.handleRequest[.z.w; x]};
    .z.ph: {.http.handleRequest[.z.w; x]};

    server.port: p;
    server.running: 1b;

    .log.info "HTTP server started on port ", string p;
    1b
 };

// Stop the HTTP server
stop:{[]
    if[not server.running;
        .log.warn "Server not running";
        :0b
    ];

    system "p 0";
    server.running: 0b;

    .log.info "HTTP server stopped";
    1b
 };

// ============================================================================
// WEBHOOK CLIENT
// Send alerts to Voice Switch
// ============================================================================

webhook.url: "";
webhook.secret: "";

webhook.init:{[]
    webhook.url:: getenv`WEBHOOK_URL;
    webhook.secret:: getenv`WEBHOOK_SECRET;
    if[count webhook.url;
        .log.info "Webhook configured: ", webhook.url];
 };

webhook.sendAlert:{[alert]
    if[0 = count webhook.url; :0b];

    payload: .j.j `event_type`alert!("fraud_detected"; alert);

    cmd: "curl -s -X POST -H 'Content-Type: application/json'",
         $[count webhook.secret; " -H 'X-Webhook-Secret: ", webhook.secret, "'"; ""],
         " -d '", payload, "' '", webhook.url, "'";

    result: @[system; cmd; {"error"}];

    if["error" ~ result;
        .log.error "Failed to send webhook";
        :0b
    ];

    .log.info "Alert webhook sent";
    1b
 };

\d .

// ============================================================================
// INITIALIZE ON LOAD
// ============================================================================
.http.webhook.init[];

0N!"[INFO] http_server.q loaded successfully";
