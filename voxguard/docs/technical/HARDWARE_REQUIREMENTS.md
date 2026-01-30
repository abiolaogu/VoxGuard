# Hardware Requirements
## Anti-Call Masking System

### 1. General Guidelines
The system is designed for horizontal scalability. Performance depends heavily on **CPU speed** (for Rust logic) and **Memory bandwidth** (for DragonflyDB/ClickHouse).

### 2. Deployment Profiles

#### 2.1 Proof of Concept / Dev (Docker Compose)
*   **CPU**: 4 vCPUs
*   **RAM**: 8 GB
*   **Disk**: 50 GB SSD
*   **Throughput**: ~1,000 calls/sec

#### 2.2 Production (Kubernetes Cluster)
*   **Node Pool (General)**:
    *   3 Nodes
    *   **CPU**: 8 vCPUs each
    *   **RAM**: 32 GB each
*   **Throughput**: ~50,000 calls/sec

#### 2.3 Hyperscale (ISP / Carrier Grade)
*   **Rust Services**:
    *   Autoscaling Group (20+ Replicas)
    *   Compute Optimized Instances (AWS c5.large equivalent)
*   **DragonflyDB**:
    *   Memory Optimized Instance (AWS r6g.xlarge equivalent)
    *   64 GB+ RAM
*   **ClickHouse**:
    *   Storage Optimized Instances (AWS i3.xlarge equivalent)
    *   NVMe SSDs are critical for ingestion speed
*   **Throughput**: >1,000,000 calls/sec

### 3. Network Requirements
*   **Internal Network**: 10 Gbps (Low latency required between Rust service and DragonflyDB)
*   **Internet Access**: Outbound only (for updates/alerts), Inbound restricted to Voice Switch IPs.
