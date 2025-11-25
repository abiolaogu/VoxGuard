# Anti-Call Masking Detection System - Operations Runbook

## Table of Contents
1. [System Overview](#system-overview)
2. [Common Operations](#common-operations)
3. [Incident Response](#incident-response)
4. [Troubleshooting](#troubleshooting)
5. [Maintenance Procedures](#maintenance-procedures)
6. [Performance Tuning](#performance-tuning)

---

## System Overview

### Architecture
```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   SIP Clients   │────>│  Voice Switch    │────>│  kdb+ Fraud     │
│                 │     │  (ESL/MI)        │     │  Detection      │
│                 │<────│                  │<────│  (port 5012)    │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

### Key Ports
| Port | Service | Protocol |
|------|---------|----------|
| 5012 | Detection IPC | kdb+ |
| 5013 | Admin API | kdb+ |
| 8021 | FreeSWITCH ESL | TCP |
| 9090 | Prometheus metrics | HTTP |

### Critical Thresholds
| Metric | Warning | Critical |
|--------|---------|----------|
| P99 Latency | 50ms | 100ms |
| Memory | 2GB | 3GB |
| Switch Disconnect | 10s | 30s |
| Alert Rate | 10/min | 50/min |

---

## Common Operations

### Starting the System

```bash
# Docker deployment
docker-compose up -d fraud-detection

# Local deployment
cd anti-call-masking/src
q main.q -p 5012

# With custom config
q main.q -p 5012 -switch_host 10.0.0.1 -threshold 5
```

### Stopping the System

```bash
# Graceful shutdown (saves checkpoint)
# Connect to IPC port and run:
h:hopen `:localhost:5012
h ".recovery.prepareShutdown[]"
h "exit 0"

# Docker
docker-compose down
```

### Checking System Status

```q
// Connect to system
h:hopen `:localhost:5012

// Get status
h "status"

// Get detailed stats
h ".fraud.detection.getStats[]"

// Check switch connection
h ".fraud.switch.healthCheck[]"

// View recent alerts
h ".fraud.detection.getRecentAlerts[10]"
```

### Managing Whitelist

```q
// Add B-number to whitelist (exempt from detection)
h ".fraud.actions.addToWhitelist[`$\"+18005551234\"]"

// Remove from whitelist
h ".fraud.actions.removeFromWhitelist[`$\"+18005551234\"]"

// View current whitelist
h ".fraud.config.whitelist"
```

### Manual Intervention

```q
// Manually flag and disconnect all calls to a B-number
h ".fraud.actions.manualFlagBNumber[`B123;\"operator_request\"]"

// Disconnect specific call
h ".fraud.actions.manualDisconnect[`call_id_here]"

// Clear a block pattern
h ".fraud.actions.removeBlock[blockId]"
```

### Configuration Changes

```q
// View current config
h ".fraud.showConfig[]"

// Update detection window (live)
h ".recovery.updateConfig[`detection;`window_seconds;10]"

// Update threshold (live)
h ".recovery.updateConfig[`detection;`min_distinct_a;7]"

// Full config reload from file
h ".recovery.reloadConfig[]"
```

---

## Incident Response

### INC-001: High Detection Latency

**Symptoms:**
- P99 latency > 100ms
- Alert: "P99 latency exceeds threshold"
- Grafana shows latency spike

**Diagnosis:**
```q
// Check current latency
h ".metrics.current"

// Check call volume
h "count .fraud.calls"

// Check memory
h ".fraud.memoryUsage[]"
```

**Resolution:**
1. If memory high, trigger garbage collection:
   ```q
   h ".fraud.detection.runGC[]"
   ```
2. If call volume unusually high, check for attack:
   ```q
   h ".fraud.detection.getElevatedThreats[]"
   ```
3. Consider increasing GC frequency:
   ```q
   h ".recovery.updateConfig[`performance;`gc_interval_ms;500]"
   ```

### INC-002: Switch Connection Lost

**Symptoms:**
- Alert: "Switch disconnected"
- Grafana shows connection status = 0
- No new events being processed

**Diagnosis:**
```q
// Check connection state
h ".fraud.switch.healthCheck[]"

// Check connection errors
h ".fraud.connections"
```

**Resolution:**
1. Verify switch is accessible:
   ```bash
   telnet <switch_host> 8021
   ```
2. Force reconnection:
   ```q
   h ".fraud.switch.reconnect[]"
   ```
3. If switch is down, system will queue detections. Monitor queue:
   ```q
   h "count .fraud.actions.queue"
   ```

### INC-003: High Alert Volume

**Symptoms:**
- Alerts/minute > 50
- Possible mass attack or false positive storm

**Diagnosis:**
```q
// Get recent alerts
h ".fraud.detection.getRecentAlerts[30]"

// Analyze B-numbers under attack
h "select count i, first a_numbers by b_number from .fraud.fraud_alerts where created_at > .z.P - 00:30"
```

**Resolution:**
1. If legitimate attack, let system handle automatically
2. If false positives (e.g., call center):
   ```q
   // Add to whitelist
   h ".fraud.actions.addToWhitelist[`$\"call_center_number\"]"
   ```
3. If threshold too sensitive:
   ```q
   h ".recovery.updateConfig[`detection;`min_distinct_a;7]"
   ```

### INC-004: Memory Critical

**Symptoms:**
- Memory > 3GB
- System slowdown
- Possible OOM risk

**Resolution:**
1. Immediate GC:
   ```q
   h ".fraud.detection.runGC[]"
   ```
2. Force expire old data:
   ```q
   h ".fraud.expireCalls[1]"  // Keep only 1 second
   ```
3. Archive old alerts:
   ```q
   h ".fraud.archiveAlerts[1]"  // Archive alerts > 1 day old
   ```
4. If persistent, reduce window size:
   ```q
   h ".recovery.updateConfig[`detection;`window_seconds;3]"
   ```

### INC-005: System Unresponsive

**Symptoms:**
- IPC connections timeout
- No metrics updates
- Process appears hung

**Resolution:**
1. Check process is running:
   ```bash
   ps aux | grep "q main.q"
   ```
2. Check for core dump or OOM kill:
   ```bash
   dmesg | grep -i "killed process"
   ```
3. If process running but unresponsive, may need restart:
   ```bash
   # Graceful (if possible)
   echo ".recovery.prepareShutdown[]" | nc localhost 5012

   # Force restart
   docker-compose restart fraud-detection
   ```
4. On restart, system will auto-recover from checkpoint

---

## Troubleshooting

### No Alerts Generated

1. Check detection is enabled:
   ```q
   h ".fraud.config.detection"
   ```
2. Check events are being received:
   ```q
   h ".fraud.detection.processedCount"
   // Wait 10 seconds and check again
   ```
3. Check threshold settings:
   ```q
   // min_distinct_a should be 5 for standard detection
   h ".fraud.config.detection`min_distinct_a"
   ```
4. Check whitelist isn't blocking:
   ```q
   h ".fraud.config.whitelist`b_numbers"
   ```
5. Test with simulation:
   ```q
   h ".fraud.switch.enableSimulation[]"
   h ".fraud.switch.simulateAttack[\"B123\";5;0]"
   ```

### False Positives

1. Identify patterns:
   ```q
   h "select count i, first a_numbers by b_number from .fraud.fraud_alerts where created_at > .z.P - 01:00"
   ```
2. Check if legitimate call centers:
   - High volume to single B-number
   - Same A-number prefixes
3. Add to whitelist or adjust threshold

### Disconnect Commands Failing

1. Check switch connection:
   ```q
   h ".fraud.switch.connected"
   ```
2. Check action queue:
   ```q
   h ".fraud.actions.queue"
   h ".fraud.actions.failedCount"
   ```
3. Check switch logs for rejection reasons
4. Verify call IDs are valid

---

## Maintenance Procedures

### Daily Health Check

```q
// Connect and run
h:hopen `:localhost:5012

// Basic health
h ".startup.healthCheck[]"

// Key metrics
h ".metrics.get[]"

// Recent alerts (should review any new ones)
h ".fraud.detection.getRecentAlerts[1440]"  // Last 24 hours

// Memory trend
h "select avg memory_used_mb by `minute$timestamp from .metrics.history"
```

### Weekly Maintenance

1. **Review and prune old data:**
   ```q
   h ".fraud.archiveAlerts[7]"
   ```

2. **Review blocked patterns:**
   ```q
   h "select from .fraud.blocked_patterns where active"
   // Remove stale blocks if needed
   ```

3. **Check checkpoint health:**
   ```q
   h ".recovery.listCheckpoints[]"
   ```

4. **Review detection accuracy:**
   ```q
   // Run test suite
   h "\\l tests/integration_tests.q"
   h "runIntegrationTests[]"
   ```

### Monthly Maintenance

1. **Rotate logs:**
   ```q
   h ".log.rotate[]"
   ```

2. **Full system test:**
   ```bash
   # In test environment
   q tests/test_load.q
   .loadtest.runStressTest[]
   ```

3. **Review and update thresholds based on traffic patterns**

### Backup Procedures

1. **Create manual checkpoint:**
   ```q
   h ".recovery.saveCheckpoint[]"
   ```

2. **Backup checkpoint directory:**
   ```bash
   tar -czf backup_$(date +%Y%m%d).tar.gz checkpoints/
   ```

3. **Backup configuration:**
   ```bash
   cp src/config.q config_backup_$(date +%Y%m%d).q
   ```

### Recovery Procedures

1. **From checkpoint:**
   ```q
   // List available checkpoints
   h ".recovery.listCheckpoints[]"

   // Load specific checkpoint
   h ".recovery.loadCheckpoint[`checkpoint_1699999999]"

   // Or load latest
   h ".recovery.loadCheckpoint[]"
   ```

2. **Full restore:**
   ```bash
   # Stop system
   docker-compose down

   # Restore checkpoint
   tar -xzf backup_20231101.tar.gz -C anti-call-masking/

   # Start system (will auto-recover)
   docker-compose up -d
   ```

---

## Performance Tuning

### For Higher Throughput

```q
// Reduce GC frequency (more memory, less CPU)
h ".recovery.updateConfig[`performance;`gc_interval_ms;5000]"

// Increase batch size
h ".recovery.updateConfig[`performance;`batch_size;500]"

// Shorter detection window (less data to search)
h ".recovery.updateConfig[`detection;`window_seconds;3]"
```

### For Lower Latency

```q
// More frequent GC (smaller tables)
h ".recovery.updateConfig[`performance;`gc_interval_ms;500]"

// Smaller batch size
h ".recovery.updateConfig[`performance;`batch_size;50]"
```

### For Lower Memory

```q
// Shorter detection window
h ".recovery.updateConfig[`detection;`window_seconds;3]"

// More aggressive GC
h ".recovery.updateConfig[`performance;`gc_interval_ms;500]"

// Reduce max window calls
h ".recovery.updateConfig[`detection;`max_window_calls;5000]"
```

### Scaling Considerations

| CPS | Recommended Config |
|-----|-------------------|
| <10K | Default settings |
| 10K-50K | window=3s, gc=1000ms |
| 50K-100K | window=3s, gc=500ms, batch=200 |
| >100K | Consider sharding by B-number prefix |

---

## Appendix: Quick Reference

### IPC Commands
```
status         - System status
stats          - Detection statistics
health         - Full health check
alerts N       - Recent alerts (N minutes)
tables         - Table sizes
memory         - Memory usage
config         - Configuration
```

### Key Functions
```q
.fraud.processCall[event]              // Process call
.fraud.detection.getStats[]            // Get stats
.fraud.detection.getThreatLevel[bNum]  // Threat level
.fraud.actions.addToWhitelist[bNum]    // Whitelist
.fraud.switch.healthCheck[]            // Switch health
.recovery.saveCheckpoint[]             // Save state
.recovery.loadCheckpoint[]             // Restore state
.recovery.updateConfig[s;k;v]          // Update config
.metrics.get[]                         // Current metrics
```

### Emergency Contacts
- On-call: [Configure in deployment]
- Escalation: [Configure in deployment]
- Switch NOC: [Configure in deployment]
