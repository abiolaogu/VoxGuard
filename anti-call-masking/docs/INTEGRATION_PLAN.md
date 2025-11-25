# Voice Switch Integration Plan

## Repository Analysis Summary

Since the Voice-Switch-IM repository was unavailable, this integration is designed based on industry-standard VoIP softswitch patterns, supporting:
- **FreeSWITCH** (Event Socket Layer)
- **Kamailio** (MI/RPC interface)
- **Generic SIP** (RFC 3261 compliant)

## 1. Call Event Interface

### Event Sources
| Switch Type | Protocol | Port | Event Format |
|-------------|----------|------|--------------|
| FreeSWITCH ESL | TCP | 8021 | JSON/XML |
| Kamailio MI | TCP/Unix | 8080 | JSON-RPC |
| Generic SIP | UDP/TCP | 5060 | SIP Messages |

### Call Event Fields (Normalized Schema)
```
call_id     - Unique call identifier (SIP Call-ID or UUID)
a_number    - Calling party number (From header)
b_number    - Called party number (To header/RURI)
timestamp   - Event timestamp (epoch milliseconds)
event_type  - INVITE|RINGING|ANSWER|BYE|CANCEL
status      - active|ringing|completed|failed
direction   - inbound|outbound
```

### FreeSWITCH Event Example
```json
{
  "Event-Name": "CHANNEL_CREATE",
  "Unique-ID": "abc123-def456-...",
  "Caller-Caller-ID-Number": "+14155551234",
  "Caller-Destination-Number": "+14155559999",
  "Event-Date-Timestamp": "1700000000000000",
  "Call-Direction": "inbound"
}
```

## 2. Call Control API

### Disconnect Methods

#### FreeSWITCH (ESL)
```
Command: uuid_kill <uuid> [cause]
Example: uuid_kill abc123-def456 CALL_REJECTED
```

#### Kamailio (MI)
```json
{"jsonrpc": "2.0", "method": "dlg.end_dlg", "params": {"callid": "..."}}
```

#### SIP BYE
```
BYE sip:user@host SIP/2.0
Call-ID: abc123@host
Reason: Q.850;cause=21;text="Call Rejected - Fraud Detected"
```

### Response Codes for Rejection
| Code | Meaning | Use Case |
|------|---------|----------|
| 403 | Forbidden | Fraud detected |
| 603 | Decline | Call rejected by policy |
| 488 | Not Acceptable | Media/codec rejection |

## 3. Integration Points

### TCP Event Stream (Primary)
- **Port**: Configurable (default 8021 for ESL, 5555 for custom)
- **Protocol**: Line-delimited JSON
- **Authentication**: Password-based or certificate
- **Reconnection**: Exponential backoff (1s, 2s, 4s, 8s, max 30s)

### IPC Mechanism
- kdb+ IPC for high-performance internal communication
- Default port: 5012 (detection engine)
- Handles: `.fraud.processCall`, `.fraud.query`, `.fraud.stats`

### Message Queue (Optional)
- Kafka topic: `call-events`
- Format: JSON with Avro schema
- Consumer group: `fraud-detection`

## 4. Architecture

```
                    +-----------------+
                    |   SIP Clients   |
                    +--------+--------+
                             |
                    +--------v--------+
                    |  Class 5 Switch |  (End-user services)
                    |   (FreeSWITCH)  |
                    +--------+--------+
                             |
              +--------------+--------------+
              |                             |
    +---------v---------+         +---------v---------+
    |  Class 4 Switch   |         |   Event Stream    |
    |    (Kamailio)     |         |    (ESL/JSON)     |
    +---------+---------+         +---------+---------+
              |                             |
              |                    +--------v--------+
              |                    |  kdb+ Fraud     |
              +--------------------+  Detection      |
                   Disconnect      |  Engine         |
                   Commands        +-----------------+
                                          |
                                   +------v------+
                                   |   Alerts    |
                                   |   & Logs    |
                                   +-------------+
```

## 5. Class 4 vs Class 5 Event Differences

| Aspect | Class 4 | Class 5 |
|--------|---------|---------|
| Event Volume | Very High (100K+ CPS) | Moderate (10K CPS) |
| Call Duration | Short (routing only) | Full call lifecycle |
| A-Number Format | E.164 normalized | May include extensions |
| B-Number Format | E.164 normalized | Local/extension formats |
| CDR Fields | Minimal routing info | Full feature usage |

## 6. Detection Algorithm Flow

```
1. EVENT RECEIVED (call setup)
   |
2. PARSE & NORMALIZE
   |-- Extract: call_id, a_number, b_number, timestamp
   |-- Normalize: E.164 format, strip prefixes
   |
3. INSERT INTO calls TABLE
   |
4. QUERY: Count distinct A-numbers for B-number in 5s window
   |
5. THRESHOLD CHECK (>=5 distinct A-numbers?)
   |
   +-- NO  --> Return, continue monitoring
   |
   +-- YES --> 6. CREATE FRAUD ALERT
               |
               7. FLAG ALL INVOLVED CALLS
               |
               8. SEND DISCONNECT COMMANDS
               |
               9. LOG & NOTIFY
```

## 7. Performance Requirements

| Metric | Target | Notes |
|--------|--------|-------|
| Detection Latency | <50ms | From event receipt to alert |
| Throughput | 100K+ CPS | Calls per second processed |
| Memory Usage | <4GB | For 5-minute rolling window |
| False Positive Rate | <0.1% | Legitimate call centers exempt |
| Detection Rate | >99.9% | For multicall masking attacks |

## 8. Deployment Topology

### Single Node (Development)
```
kdb+ Process (port 5012)
  |-- Event listener (port 5555)
  |-- Switch connector (port 8021)
  |-- Admin API (port 5013)
```

### Multi-Node (Production)
```
Load Balancer
  |
  +-- Detection Node 1 (partition: A-M)
  +-- Detection Node 2 (partition: N-Z)
  |
Aggregator Node
  |-- Consolidated alerts
  |-- Cross-partition detection
```
