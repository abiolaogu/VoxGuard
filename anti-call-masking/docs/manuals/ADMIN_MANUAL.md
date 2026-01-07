# Administrator Manual
## Anti-Call Masking System

### 1. System Management

#### 1.1 Deployment
To deploy the system to Kubernetes:
```bash
kubectl apply -f k8s/
```
Ensure you have updated the `configmap.yaml` with your environment-specific settings.

#### 1.2 Configuration
The system is configured via Environment Variables in the Kubernetes ConfigMap.
*   **DETECTION_WINDOW_SECONDS**: Time window to check for multiple calls (Default: 5s).
*   **DETECTION_THRESHOLD**: Number of distinct A-numbers to trigger an alert (Default: 5).

### 2. Monitoring & Observability

#### 2.1 Health Checks
*   **Rust API**: `http://<service-ip>:8080/health`
*   **K8s Probes**: Configured automatically in `deployment.yaml`.

#### 2.2 Logs
View logs for the detection service:
```bash
kubectl logs -f deployment/detection-service -n fraud-detection --tail=100
```
Search for "FRAUD DETECTED" to see alert generation logs.

### 3. Troubleshooting

#### "High Latency" Alerts
*   **Check DragonflyDB**: Ensure it is running and accessible. `kubectl get pods -n fraud-detection`.
*   **Network**: Verify 10Gbps link between nodes if possible.

#### "ClickHouse Connection Refused"
*   **Check Storage**: Verify Persistent Volumes are mounted.
*   **Restart**: `kubectl rollout restart statefulset/clickhouse -n fraud-detection`.
