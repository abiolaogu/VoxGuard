# API Developer Manual
## Anti-Call Masking System

### 1. Integration Overview
The Fraud Detection Engine exposes a stateless REST API via HTTP. Your Voice Switch (e.g., Kamailio, Asterisk, or Custom Gateway) should asynchronously POST call events to this API.

### 2. API Reference

#### Endpoint: `POST /event`
**Description**: Submit start-of-call event.
**Latency Goal**: < 2ms network RTT.

**Headers**:
*   `Content-Type: application/json`

**Payload**:
```json
{
  "call_id": "unique-uuid-string",
  "a_number": "+15550001",
  "b_number": "+15550002",
  "timestamp": "2023-10-27T12:00:00Z" 
}
```

**Response**:
*   `200 OK`: Data received. Check body for alert status.
    ```json
    {
      "status": "alert",
      "alert": {
          "description": "Masking Attack Detected",
          "call_count": 12
      }
    }
    ```

### 3. Integration Patterns

#### 3.1 Synchronous (Blocking)
*   **Flow**: Switch -> API -> Verdict -> Connect Call.
*   **Pros**: STOPS fraud before connection.
*   **Cons**: Add latency to call setup. Requires 99.999% API uptime.

#### 3.2 Asynchronous (Non-Blocking)
*   **Flow**: Switch -> Connect Call; Switch -> Fork -> API.
*   **Pros**: Zero impact on call setup time.
*   **Cons**: Fraudulent call connects for a few seconds before remedial action can be taken (e.g., tear down).

**Recommendation**: Use **Synchronous** if your network latency to the Detection Service is < 10ms. Use **Asynchronous** otherwise.
