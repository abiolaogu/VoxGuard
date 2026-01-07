# SOC Analyst Manual
## Anti-Call Masking System

### 1. Understanding Alerts

#### 1.1 Alert Format
When the system detects a masking attack, it generates an alert with the following data:
*   **B-Number**: The victim number receiving the calls.
*   **Call Count**: How many distinct A-numbers called in the last window.
*   **Timestamp**: Time of detection.
*   **A-Numbers**: List of the suspicious caller IDs.

#### 1.2 Severity Levels
*   **Medium (5-7 calls)**: Potential masking or legitimate busy line (e.g., radio contest).
*   **High (8-15 calls)**: Probable masking attack / CLI spoofing.
*   **Critical (15+ calls)**: Confirmed automated attack (Botnet/Simbox).

### 2. Investigation Workflow

1.  **Receive Alert**: Monitoring dashboard shows "Masking Attack Detected".
2.  **Verify**: Check the B-Number. Is it a known business (Bank, Call Center)?
    *   If **Yes**: Might be false positive (whitelist candidate).
    *   If **No**: Likely a personal number being targeted.
3.  **Action**:
    *   **Block**: Add A-number ranges to the Voice Switch blacklist.
    *   **Report**: Export call logs from ClickHouse for regulatory reporting.

### 3. Querying History
You can query ClickHouse for historical data using SQL:
```sql
-- Find top targeted numbers today
SELECT b_number, count() as hits 
FROM calls 
WHERE timestamp > today()
GROUP BY b_number 
ORDER BY hits DESC 
LIMIT 10;
```
