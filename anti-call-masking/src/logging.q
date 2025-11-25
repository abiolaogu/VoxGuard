// logging.q - Structured logging for production
// Anti-Call Masking Detection System
// ===================================

\d .log

// ============================================================================
// CONFIGURATION
// ============================================================================
level:`INFO;                        // DEBUG, INFO, WARN, ERROR
levels:`DEBUG`INFO`WARN`ERROR;      // Level hierarchy
levelPriority:`DEBUG`INFO`WARN`ERROR!0 1 2 3;

// Output configuration
config:`console`file`structured`maxFileSize`rotateCount`includeTimestamp`includeLevel`includeCaller!(
    1b;                             // Log to console
    1b;                             // Log to file
    1b;                             // Use structured JSON format
    104857600;                      // 100MB max file size
    5;                              // Keep 5 rotated files
    1b;                             // Include timestamp
    1b;                             // Include level
    0b                              // Include caller (expensive)
);

// File handle
fileHandle:0i;
filePath:`:logs/fraud_detection.log;
currentFileSize:0;

// ============================================================================
// INITIALIZATION
// ============================================================================
init:{[]
    // Create logs directory
    @[system;"mkdir -p logs";{}];

    // Open log file
    if[config`file;
        fileHandle::@[hopen;filePath;0i];
        if[fileHandle>0;
            -1 "[LOG] File logging enabled: ",string filePath
        ];
    ];
};

// ============================================================================
// CORE LOGGING FUNCTIONS
// ============================================================================
shouldLog:{[msgLevel]
    levelPriority[msgLevel] >= levelPriority[level]
};

formatTimestamp:{[]
    ts:.z.P;
    // ISO 8601 format
    "20",string[`date$ts],"T",string[`time$ts],"Z"
};

formatStructured:{[lvl;msg;context]
    d:`timestamp`level`message!(formatTimestamp[];string lvl;msg);
    if[99h=type context;d:d,context];
    .j.j d
};

formatPlain:{[lvl;msg]
    parts:();
    if[config`includeTimestamp;parts,:enlist formatTimestamp[]];
    if[config`includeLevel;parts,:enlist "[",string[lvl],"]"];
    parts,:enlist msg;
    " " sv parts
};

write:{[lvl;msg;context]
    if[not shouldLog lvl;:()];

    formatted:$[config`structured;
        formatStructured[lvl;msg;context];
        formatPlain[lvl;msg]
    ];

    // Console output
    if[config`console;
        -1 formatted
    ];

    // File output
    if[config`file;
        if[fileHandle>0;
            fileHandle formatted;
            currentFileSize+:count formatted;
            if[currentFileSize>config`maxFileSize;
                rotate[]
            ]
        ]
    ];
};

// ============================================================================
// PUBLIC LOGGING INTERFACE
// ============================================================================
debug:{[msg] write[`DEBUG;msg;()!()]};
debugCtx:{[msg;ctx] write[`DEBUG;msg;ctx]};

info:{[msg] write[`INFO;msg;()!()]};
infoCtx:{[msg;ctx] write[`INFO;msg;ctx]};

warn:{[msg] write[`WARN;msg;()!()]};
warnCtx:{[msg;ctx] write[`WARN;msg;ctx]};

error:{[msg] write[`ERROR;msg;()!()]};
errorCtx:{[msg;ctx] write[`ERROR;msg;ctx]};

// ============================================================================
// SPECIALIZED LOGGERS
// ============================================================================

// Log fraud detection event
detection:{[bNumber;aNumbers;callCount;detected;latencyMs]
    ctx:`b_number`a_number_count`call_count`detected`latency_ms!(
        string bNumber;
        count aNumbers;
        callCount;
        detected;
        latencyMs
    );
    write[`INFO;"Detection check";ctx]
};

// Log alert creation
alert:{[alertId;bNumber;aNumbers;action]
    ctx:`alert_id`b_number`a_numbers`action!(
        string alertId;
        string bNumber;
        string each aNumbers;
        string action
    );
    write[`WARN;"FRAUD ALERT";ctx]
};

// Log disconnect action
disconnect:{[alertId;callId;success]
    ctx:`alert_id`call_id`success!(
        string alertId;
        string callId;
        success
    );
    lvl:$[success;`INFO;`ERROR];
    write[lvl;"Disconnect action";ctx]
};

// Log switch connection event
connection:{[event;host;port;details]
    ctx:`event`host`port`details!(event;host;port;details);
    lvl:$[event in `connected`reconnected;`INFO;`WARN];
    write[lvl;"Switch connection";ctx]
};

// Log metrics snapshot
metrics:{[metricsDict]
    write[`DEBUG;"Metrics snapshot";metricsDict]
};

// Log configuration change
configChange:{[section;key;oldVal;newVal]
    ctx:`section`key`old_value`new_value!(
        string section;
        string key;
        -3!oldVal;
        -3!newVal
    );
    write[`INFO;"Configuration changed";ctx]
};

// ============================================================================
// FILE ROTATION
// ============================================================================
rotate:{[]
    if[fileHandle>0;
        hclose fileHandle;
        fileHandle::0i
    ];

    // Rotate existing files
    i:config`rotateCount;
    while[i>0;
        oldPath:string[filePath],".",string i-1;
        newPath:string[filePath],".",string i;
        @[system;"mv ",oldPath," ",newPath," 2>/dev/null";{}];
        i-:1
    ];

    // Rename current to .0
    @[system;"mv ",string[filePath]," ",string[filePath],".0 2>/dev/null";{}];

    // Reopen
    fileHandle::@[hopen;filePath;0i];
    currentFileSize::0;

    info "Log file rotated"
};

// ============================================================================
// AUDIT LOG
// For compliance/security events
// ============================================================================
auditPath:`:logs/audit.log;
auditHandle:0i;

initAudit:{[]
    auditHandle::@[hopen;auditPath;0i]
};

audit:{[action;user;details]
    if[auditHandle<=0;:()];

    entry:.j.j `timestamp`action`user`details!(
        formatTimestamp[];
        action;
        user;
        details
    );

    auditHandle entry
};

// ============================================================================
// QUERY LOGS
// ============================================================================
tail:{[n]
    if[not config`file;:"File logging not enabled"];
    cmd:"tail -n ",string[n]," ",string filePath;
    system cmd
};

search:{[pattern;n]
    if[not config`file;:"File logging not enabled"];
    cmd:"grep '",pattern,"' ",string[filePath]," | tail -n ",string n;
    system cmd
};

// ============================================================================
// STATISTICS
// ============================================================================
stats:`debug`info`warn`error!0 0 0 0;

getStats:{[]stats};
resetStats:{[]stats::`debug`info`warn`error!0 0 0 0};

\d .

// Initialize logging
.log.init[];

0N!"[INFO] logging.q loaded successfully";
