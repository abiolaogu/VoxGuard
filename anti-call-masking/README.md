# Anti-Call Masking Detection System

Real-time fraud detection system using kdb+/q to identify and prevent call masking attacks in VoIP networks.

## Overview

Call masking fraud occurs when attackers use multiple originating phone numbers (A-numbers) to obscure the true source of calls to a target number (B-number). This system detects **multicall masking attacks** where 5+ distinct callers contact the same recipient within a 5-second window.

### Detection Rule

| Parameter | Value | Description |
|-----------|-------|-------------|
| Window | 5 seconds | Sliding time window |
| Threshold | 5 | Minimum distinct A-numbers |
| Action | Disconnect | Terminate all flagged calls |

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   SIP Clients   │────>│  Voice Switch    │────>│  kdb+ Fraud     │
│                 │     │  (FreeSWITCH/    │     │  Detection      │
│                 │<────│   Kamailio)      │<────│  Engine         │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                        Call Events (ESL)        Disconnect Commands
```

## Quick Start

### Prerequisites

- **kdb+ 4.0+** (64-bit) with valid license
- **Docker & Docker Compose** (for containerized deployment)
- **Python 3.8+** (optional, for simulator)

### Installation

```bash
# Clone the repository
git clone https://github.com/abiolaogu/Anti_Call-Masking.git
cd Anti_Call-Masking/anti-call-masking

# Start with Docker
docker-compose up -d

# Or run locally with kdb+
cd src
q main.q -p 5012
```

### Verify Installation

```q
// In the q console
.fraud.detection.getStats[]
// Should show: processed_total, alerts_total, etc.

// Enable simulation mode
.fraud.switch.enableSimulation[]

// Simulate an attack (5 callers to B123)
.fraud.switch.simulateAttack["B123";5;0]

// Check alerts
.fraud.detection.getRecentAlerts[5]
```

## Directory Structure

```
anti-call-masking/
├── src/
│   ├── config.q          # Configuration parameters
│   ├── schema.q          # Table definitions
│   ├── detection.q       # Core detection algorithm
│   ├── actions.q         # Disconnect/block handlers
│   ├── switch_adapter.q  # Switch integration layer
│   └── main.q            # Application entry point
├── tests/
│   ├── test_detection.q  # Unit tests
│   └── test_load.q       # Performance tests
├── config/
│   └── prometheus.yml    # Metrics configuration
├── docker-compose.yml    # Container orchestration
└── README.md
```

## Configuration

### Detection Settings (`config.q`)

```q
.fraud.config.detection:`window_seconds`min_distinct_a`cooldown_seconds`max_window_calls!(
    5;          // Sliding window (1-60 seconds)
    5;          // Threshold (2-100 distinct A-numbers)
    60;         // Alert cooldown period
    10000       // Max calls in window (memory limit)
);
```

### Switch Connection

```q
.fraud.config.switch:`host`port`protocol`auth_password!(
    "127.0.0.1";    // Switch hostname
    8021i;          // ESL port (FreeSWITCH default)
    `freeswitch;    // Protocol: `freeswitch`kamailio`generic
    "ClueCon"       // Authentication
);
```

### Command Line Arguments

```bash
q main.q -port 5012 -switch_host 10.0.0.1 -switch_port 8021 -window 5 -threshold 5
```

## API Reference

### IPC Commands

Connect via kdb+ IPC on port 5012:

```q
// Status check
h:hopen `:localhost:5012
h "status"

// Get statistics
h "stats"

// Get recent alerts
h "alerts 10"  // Last 10 minutes

// Dictionary commands
h `cmd`data!(`process;`a_number`b_number!(`A001;`B001))
h `cmd`data!(`disconnect;`rawCallId123)
h `cmd`data!(`whitelist_add;`B_SAFE)
```

### Direct Function Calls

```q
// Process a call event
.fraud.processCall[`a_number`b_number!(`A001;`B001)]

// Get threat level for a B-number
.fraud.detection.getThreatLevel[`B001]

// Get elevated threats
.fraud.detection.getElevatedThreats[]

// Manual disconnect
.fraud.actions.manualDisconnect[`callId123]

// Whitelist management
.fraud.actions.addToWhitelist[`B_SAFE]
.fraud.actions.removeFromWhitelist[`B_SAFE]
```

### Simulation Mode

```q
// Enable simulation (no real switch connection)
.fraud.switch.enableSimulation[]

// Simulate single call
.fraud.switch.simulateCall["A123";"B456"]

// Simulate attack pattern
.fraud.switch.simulateAttack["B789";5;100]  // 5 callers, 100ms delay
```

## Testing

### Unit Tests

```bash
cd tests
q test_detection.q

// Or run programmatically
\l test_detection.q
.test.runAll[]
```

Expected output:
```
[TEST SUITE] Threshold Detection Tests
  [PASS] Exactly 5 distinct A-numbers triggers 1 alert
  [PASS] 4 distinct A-numbers does not trigger alert
  [PASS] 6 calls triggers only 1 alert (cooldown)
  ...
```

### Load Tests

```q
\l test_load.q

// Throughput test
.loadtest.runThroughputTest[10000;5]  // 10K CPS for 5 seconds

// Accuracy test
.loadtest.runAccuracyTest[100;5]       // 100 attacks, 5 callers each

// Full stress test
.loadtest.runStressTest[]
```

### Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| Detection Latency | <50ms | P99 |
| Throughput | 100K+ CPS | Single node |
| Memory | <4GB | 5-minute window |
| Detection Rate | >99.9% | True positives |
| False Positive Rate | <0.1% | |

## Docker Deployment

### Basic (Detection Only)

```bash
docker-compose up -d fraud-detection
```

### With FreeSWITCH Simulator

```bash
docker-compose --profile with-simulator up -d
```

### With Monitoring Stack

```bash
docker-compose --profile monitoring up -d
# Access Grafana at http://localhost:3000 (admin/admin)
```

### Full Stack

```bash
docker-compose --profile with-simulator --profile monitoring up -d
```

## Switch Integration

### FreeSWITCH (ESL)

The system connects to FreeSWITCH via the Event Socket Layer:

```bash
# FreeSWITCH event_socket.conf.xml
<configuration name="event_socket.conf">
  <settings>
    <param name="listen-ip" value="0.0.0.0"/>
    <param name="listen-port" value="8021"/>
    <param name="password" value="ClueCon"/>
  </settings>
</configuration>
```

Events subscribed:
- `CHANNEL_CREATE` - Call setup
- `CHANNEL_ANSWER` - Call answered
- `CHANNEL_HANGUP` - Call terminated

Disconnect command: `uuid_kill <uuid> CALL_REJECTED`

### Kamailio (MI)

JSON-RPC over TCP:

```json
{"jsonrpc":"2.0","method":"dlg.end_dlg","params":{"callid":"..."},"id":1}
```

### Generic/Custom

Implement custom parser in `switch_adapter.q`:

```q
switch.parseGenericEvent:{[eventStr]
    // Your custom parsing logic
    json:.j.k eventStr;
    // Return normalized event dictionary
}
```

## Monitoring

### Built-in Statistics

```q
.fraud.detection.getStats[]
// Returns: processed_total, alerts_total, active_calls, latency metrics

.fraud.tableSizes[]
// Returns: row counts for all tables

.fraud.memoryUsage[]
// Returns: memory usage per table in MB
```

### Prometheus Metrics (Port 9090)

- `fraud_calls_processed_total`
- `fraud_alerts_generated_total`
- `fraud_detection_latency_ms`
- `fraud_active_calls`
- `fraud_disconnects_total`

### Health Check

```q
.startup.healthCheck[]
// Returns: healthy, checks (ipc, switch, detection, memory), stats
```

## Troubleshooting

### Common Issues

**No alerts generated:**
1. Check threshold: `.fraud.config.detection`min_distinct_a`
2. Verify window: `.fraud.config.detection`window_seconds`
3. Check whitelist: `.fraud.config.whitelist`b_numbers`
4. Review cooldown: `.fraud.detection.inCooldown[`B001]`

**High latency:**
1. Reduce window size
2. Enable more aggressive GC: `.fraud.config.performance`gc_interval_ms`
3. Check memory: `.fraud.memoryUsage[]`

**Switch connection fails:**
1. Verify host/port: `.fraud.config.switch`
2. Check authentication password
3. Ensure switch allows external connections
4. Use simulation mode for testing

### Debug Mode

```q
// Enable verbose logging
.fraud.config.logging[`level]:`DEBUG

// View recent events
select from .fraud.calls where ts > .z.P - 00:01

// Check connection status
.fraud.switch.healthCheck[]
```

## Security Considerations

- **Network Isolation**: Run detection engine in isolated network segment
- **Authentication**: Use strong ESL passwords; consider TLS
- **Access Control**: Restrict IPC port access
- **Audit Logging**: All actions logged with timestamps
- **Data Retention**: Configure `archiveAlerts` for compliance

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `q tests/test_detection.q`
4. Submit pull request

## License

MIT License - See LICENSE file

## References

- [kdb+ Documentation](https://code.kx.com/q/)
- [FreeSWITCH ESL](https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Client-and-Developer-Interfaces/Event-Socket-Library/)
- [Kamailio MI](https://www.kamailio.org/docs/modules/stable/modules/mi_fifo.html)
- [SIP RFC 3261](https://tools.ietf.org/html/rfc3261)
