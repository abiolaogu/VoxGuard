// switch_adapter.q - Voice switch integration adapter
// Anti-Call Masking Detection System
// ===================================
// Handles connection, event parsing, and command sending for various switch types

\d .fraud

// ============================================================================
// CONNECTION STATE
// ============================================================================
switch.connection:0Ni;              // Current connection handle
switch.connected:0b;                // Connection status
switch.reconnectAttempts:0;         // Current reconnect attempts
switch.lastEventTime:.z.P;          // Last event received
switch.eventBuffer:"";              // Buffer for incomplete messages

// ============================================================================
// SEND DISCONNECT COMMAND
// Primary interface for disconnecting calls
// ============================================================================
switch.sendDisconnect:{[callId]
    if[not switch.connected;
        .log.warn "Switch not connected, cannot disconnect: ", string callId;
        :0b
    ];

    protocol: config.switch`protocol;

    // Send disconnect based on protocol
    result: $[
        protocol = `freeswitch; switch.disconnectFreeSWITCH[callId];
        protocol = `kamailio;   switch.disconnectKamailio[callId];
        protocol = `simulation; 1b;  // Simulation always succeeds
        switch.disconnectGeneric[callId]
    ];

    result
 };

switch.disconnectFreeSWITCH:{[callId]
    cmd: "api uuid_kill ", string[callId], " CALL_REJECTED\n\n";
    @[{neg[switch.connection] x; 1b}; cmd; {.log.error "ESL send failed: ", x; 0b}]
 };

switch.disconnectKamailio:{[callId]
    jsonCmd: "{\"jsonrpc\":\"2.0\",\"method\":\"dlg.end_dlg\",\"params\":{\"callid\":\"",
             string[callId], "\"},\"id\":1}";
    @[{neg[switch.connection] x; 1b}; jsonCmd; {.log.error "Kamailio send failed: ", x; 0b}]
 };

switch.disconnectGeneric:{[callId]
    cmd: "DISCONNECT ", string[callId], "\n";
    @[{neg[switch.connection] x; 1b}; cmd; {.log.error "Generic send failed: ", x; 0b}]
 };

// ============================================================================
// CONNECTION MANAGEMENT
// ============================================================================
switch.connect:{[]
    host:config.switch`host;
    port:config.switch`port;

    0N!"[SWITCH] Connecting to ",host,":",string port,"...";

    // Attempt connection
    handle:@[hopen;`$"::",host,":",string port;{`error}];

    if[handle~`error;
        0N!"[ERROR] Failed to connect to switch";
        switch.scheduleReconnect[];
        :0b
    ];

    switch.connection:handle;
    switch.connected:1b;
    switch.reconnectAttempts:0;

    // Authenticate based on protocol
    protocol:config.switch`protocol;
    authResult:$[
        protocol=`freeswitch;switch.authFreeSWITCH[];
        protocol=`kamailio;switch.authKamailio[];
        1b  // Generic needs no auth
    ];

    if[not authResult;
        switch.disconnect[];
        :0b
    ];

    // Register connection in table
    `.fraud.connections upsert (switch.connection;`primary;`$host;port;protocol;
                                 `connected;.z.P;.z.P;0;0);

    // Start event listener
    switch.startListener[];

    0N!"[SWITCH] Connected successfully";
    1b
 };

switch.disconnect:{[]
    if[switch.connected;
        @[hclose;switch.connection;{}];
        update status:`disconnected from `.fraud.connections where conn_id=switch.connection;
        switch.connection:0Ni;
        switch.connected:0b;
        0N!"[SWITCH] Disconnected";
    ];
 };

switch.reconnect:{[]
    switch.disconnect[];
    maxAttempts:config.switch`reconnect_max_attempts;
    backoff:config.switch`reconnect_backoff_ms;

    if[switch.reconnectAttempts>=maxAttempts;
        0N!"[ERROR] Max reconnection attempts reached";
        :0b
    ];

    // Exponential backoff
    waitTime:backoff * `long$xexp[2;switch.reconnectAttempts];
    0N!"[SWITCH] Reconnecting in ",string[waitTime],"ms (attempt ",
       string[switch.reconnectAttempts+1],"/",string[maxAttempts],")";

    switch.reconnectAttempts+:1;

    // Schedule reconnection (using timer)
    system "t ",string waitTime;
    .z.ts:{system "t 0";.fraud.switch.connect[];};
 };

switch.scheduleReconnect:{[]
    switch.reconnect[];
 };

switch.getConnection:{[]
    if[not switch.connected;:0Ni];
    switch.connection
 };

// ============================================================================
// AUTHENTICATION
// ============================================================================
switch.authFreeSWITCH:{[]
    // FreeSWITCH ESL authentication
    password:config.switch`auth_password;
    authCmd:"auth ",password,"\n\n";

    result:@[{neg[switch.connection]x;1b};authCmd;{0b}];
    if[not result;
        0N!"[ERROR] FreeSWITCH authentication failed";
        :0b
    ];

    // Subscribe to channel events
    subscribeCmd:"event plain CHANNEL_CREATE CHANNEL_ANSWER CHANNEL_HANGUP\n\n";
    neg[switch.connection]subscribeCmd;

    0N!"[SWITCH] FreeSWITCH authenticated and subscribed to events";
    1b
 };

switch.authKamailio:{[]
    // Kamailio MI doesn't typically require authentication
    // but we can send a ping to verify connection
    0N!"[SWITCH] Kamailio connection established";
    1b
 };

// ============================================================================
// EVENT LISTENER
// ============================================================================
switch.startListener:{[]
    // Set up async message handler
    .z.pg:{switch.handleMessage x};      // Sync queries
    .z.ps:{switch.handleMessage x};      // Async messages

    0N!"[SWITCH] Event listener started";
 };

switch.handleMessage:{[msg]
    // Buffer incomplete messages
    switch.eventBuffer,:msg;

    // Parse based on protocol
    protocol:config.switch`protocol;
    events:$[
        protocol=`freeswitch;switch.parseFreeSWITCH[];
        protocol=`kamailio;switch.parseKamailio[];
        switch.parseGeneric[]
    ];

    // Process each parsed event
    {switch.processEvent x} each events;
 };

// ============================================================================
// PROTOCOL-SPECIFIC PARSERS
// ============================================================================

// FreeSWITCH Event Socket Layer parser
switch.parseFreeSWITCH:{[]
    events:();
    buffer:switch.eventBuffer;

    // FreeSWITCH events are separated by double newlines
    // and formatted as key: value pairs
    while["\n\n" in buffer;
        idx:buffer ss "\n\n";
        if[0<count idx;
            eventStr:(first idx) # buffer;
            buffer:(first idx + 2) _ buffer;

            event:switch.parseESLEvent eventStr;
            if[count event;events,:enlist event];
        ];
    ];

    switch.eventBuffer:buffer;
    events
 };

switch.parseESLEvent:{[eventStr]
    // Parse key: value format
    lines:"\n" vs eventStr;
    pairs:{x:(": " ss x);(x[0]#y;(x[0]+2)_y)}[;] each lines where 0<count each lines;

    if[0=count pairs;:()];

    dict:(!). flip pairs;

    // Map to standard format
    eventName:dict`$"Event-Name";
    if[null eventName;:()];

    // Only process call events
    if[not eventName in ("CHANNEL_CREATE";"CHANNEL_ANSWER";"CHANNEL_HANGUP");:()];

    callId:dict`$"Unique-ID";
    aNumber:dict`$"Caller-Caller-ID-Number";
    bNumber:dict`$"Caller-Destination-Number";
    tsStr:dict`$"Event-Date-Timestamp";

    // Convert timestamp (microseconds since epoch)
    ts:$[count tsStr;"P"$10#tsStr;.z.P];

    // Map event type
    status:$[
        eventName~"CHANNEL_CREATE";`ringing;
        eventName~"CHANNEL_ANSWER";`active;
        eventName~"CHANNEL_HANGUP";`completed;
        `unknown
    ];

    `call_id`a_number`b_number`ts`status`raw_call_id`switch_id!(
        `$callId;`$aNumber;`$bNumber;ts;status;`$callId;`freeswitch
    )
 };

// Kamailio parser (JSON format)
switch.parseKamailio:{[]
    events:();
    buffer:switch.eventBuffer;

    // Kamailio sends JSON-RPC notifications, one per line
    while["\n" in buffer;
        idx:buffer ss "\n";
        if[0<count idx;
            eventStr:(first idx) # buffer;
            buffer:(first idx + 1) _ buffer;

            event:switch.parseKamailioEvent eventStr;
            if[count event;events,:enlist event];
        ];
    ];

    switch.eventBuffer:buffer;
    events
 };

switch.parseKamailioEvent:{[eventStr]
    // Parse JSON
    json:@[.j.k;eventStr;{()}];
    if[not count json;:()];

    // Extract call info from JSON-RPC notification
    if[not `params in key json;:()];
    params:json`params;

    callId:params`callid;
    if[null callId;:()];

    aNumber:$[`from_tag in key params;params`from_user;params`caller];
    bNumber:$[`to_tag in key params;params`to_user;params`callee];
    method:$[`method in key params;params`method;`unknown];

    status:$[
        method in (`INVITE;`$"INVITE");`ringing;
        method in (`ACK;`$"ACK");`active;
        method in (`BYE;`$"BYE";`CANCEL;`$"CANCEL");`completed;
        `unknown
    ];

    `call_id`a_number`b_number`ts`status`raw_call_id`switch_id!(
        `$callId;`$aNumber;`$bNumber;.z.P;status;`$callId;`kamailio
    )
 };

// Generic parser (simple line-delimited format)
switch.parseGeneric:{[]
    events:();
    buffer:switch.eventBuffer;

    // Generic format: JSON objects, one per line
    while["\n" in buffer;
        idx:buffer ss "\n";
        if[0<count idx;
            eventStr:(first idx) # buffer;
            buffer:(first idx + 1) _ buffer;

            event:switch.parseGenericEvent eventStr;
            if[count event;events,:enlist event];
        ];
    ];

    switch.eventBuffer:buffer;
    events
 };

switch.parseGenericEvent:{[eventStr]
    // Try JSON parse
    json:@[.j.k;eventStr;{()}];
    if[not count json;:()];

    // Map standard fields
    callId:$[`call_id in key json;json`call_id;
             `callId in key json;json`callId;
             `uuid in key json;json`uuid;""];
    if[0=count callId;:()];

    aNumber:$[`a_number in key json;json`a_number;
              `from in key json;json`from;
              `caller in key json;json`caller;""];
    bNumber:$[`b_number in key json;json`b_number;
              `to in key json;json`to;
              `callee in key json;json`callee;""];

    status:$[`status in key json;`$json`status;
             `event in key json;`$json`event;`active];

    `call_id`a_number`b_number`ts`status`raw_call_id`switch_id!(
        `$callId;`$aNumber;`$bNumber;.z.P;status;`$callId;`generic
    )
 };

// ============================================================================
// EVENT PROCESSING
// ============================================================================
switch.processEvent:{[event]
    // Update last event time
    switch.lastEventTime:.z.P;

    // Update connection stats
    update events_received:events_received+1, last_event_at:.z.P
        from `.fraud.connections where conn_id=switch.connection;

    // Handle based on status
    status:event`status;

    $[
        status in `ringing`active;[
            // New call - run detection
            .fraud.processCall event
        ];
        status=`completed;[
            // Call ended - update status
            update status:`completed from `.fraud.calls where raw_call_id=event`raw_call_id
        ];
        // Unknown status - log and skip
        0N!"[WARN] Unknown event status: ",string status
    ]
 };

// ============================================================================
// HEALTH CHECK
// ============================================================================
switch.healthCheck:{[]
    if[not switch.connected;
        :`status`message!(`disconnected;"Not connected to switch")
    ];

    // Check last event time
    staleThreshold:30;  // seconds
    if[((.z.P - switch.lastEventTime)%1000000000)>staleThreshold;
        0N!"[WARN] No events received in ",string[staleThreshold]," seconds";
    ];

    // Get connection info
    connInfo:exec from connections where conn_id=switch.connection;

    `status`message`events_received`last_event!(
        `connected;
        "Connection healthy";
        first connInfo`events_received;
        switch.lastEventTime
    )
 };

// ============================================================================
// SIMULATION MODE
// For testing without a real switch
// ============================================================================
switch.simulationMode:0b;

switch.enableSimulation:{[]
    switch.simulationMode:1b;
    switch.connected:1b;
    0N!"[SWITCH] Simulation mode enabled";
 };

switch.disableSimulation:{[]
    switch.simulationMode:0b;
    switch.connected:0b;
    0N!"[SWITCH] Simulation mode disabled";
 };

// Simulate an incoming call event
switch.simulateCall:{[aNum;bNum]
    if[not switch.simulationMode;
        0N!"[ERROR] Simulation mode not enabled";
        :()
    ];

    callId:first 1?0Ng;
    event:`call_id`a_number`b_number`ts`status`raw_call_id`switch_id!(
        callId;`$aNum;`$bNum;.z.P;`active;`$string callId;`simulation
    );

    // Process the simulated event
    result:.fraud.processCall event;
    `event`result!(event;result)
 };

// Simulate a multicall masking attack
switch.simulateAttack:{[targetBNumber;numCallers;delayMs]
    if[not switch.simulationMode;
        0N!"[ERROR] Simulation mode not enabled";
        :()
    ];

    0N!"[SIM] Starting attack simulation: ",string[numCallers]," callers to ",targetBNumber;

    // Generate unique A-numbers
    aNumbers:{"A",string x} each til numCallers;

    // Simulate calls with delay
    results:{
        result:switch.simulateCall[x;y];
        if[z>0;system "sleep 0.",string z];
        result
    }[;targetBNumber;delayMs] each aNumbers;

    detections:sum results[;`result;`detected];
    0N!"[SIM] Attack complete. Detections: ",string detections;

    results
 };

\d .

0N!"[INFO] switch_adapter.q loaded successfully";
