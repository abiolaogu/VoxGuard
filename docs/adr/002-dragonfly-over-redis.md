# ADR 002: DragonflyDB over Redis

## Metadata

| Field      | Value                              |
|------------|------------------------------------|
| **Title**  | Use DragonflyDB Instead of Redis   |
| **Date**   | 2026-01-10                         |
| **Status** | Accepted                           |
| **Authors**| VoxGuard Architecture Team         |

---

## Context

VoxGuard requires a high-throughput, low-latency in-memory data store for several critical functions:

1. **Detection rule caching:** The Rust detection engine must load and evaluate detection rules against every incoming call. Rules are stored in the operational database (YugabyteDB) but must be cached in memory for sub-millisecond access. At 150K+ CPS, every microsecond of cache access latency matters.

2. **Session and rate limiting state:** The platform enforces per-caller and per-trunk rate limits to detect fraud patterns (e.g., rapid sequential dialing). This requires atomic counters and expiring keys with high write throughput.

3. **Real-time feature store:** The Python ML pipeline requires low-latency access to pre-computed features (call velocity, geographic spread, time-of-day patterns) for real-time inference. These features are updated continuously and read on every inference request.

4. **Pub/Sub for event distribution:** Detection events must be broadcast to multiple downstream consumers (case management, alerting, analytics) with minimal latency.

### Requirements

- **Throughput:** Must sustain 500K+ operations per second with a mix of reads and writes.
- **Latency:** P99 latency for cache reads must be < 100 microseconds.
- **Compatibility:** Must support the Redis protocol and data structures (strings, hashes, sorted sets, streams) to leverage the mature Redis client ecosystem across Rust, Go, and Python.
- **Operational simplicity:** Must be straightforward to deploy and manage, ideally as a single-binary process without complex clustering requirements for the initial deployment scale.

### Alternatives Evaluated

1. **Redis (open source):** The industry standard for in-memory caching. Redis is single-threaded for command execution, which limits vertical scalability. At VoxGuard's required throughput (500K+ ops/sec), a single Redis instance would be operating near its ceiling, requiring Redis Cluster for horizontal scaling. Redis Cluster adds significant operational complexity (slot management, resharding, client-side routing) that we want to avoid in the initial deployment. Additionally, recent Redis licensing changes (SSPL for Redis 7.4+) introduce concerns for our deployment model.

2. **KeyDB:** A multi-threaded Redis fork that addresses Redis's single-threaded limitation. However, KeyDB's development pace has slowed, and its community is smaller. Long-term maintenance viability was a concern.

3. **Memcached:** High-performance caching but lacks the rich data structures (sorted sets, streams, pub/sub) required for VoxGuard's use cases. Would require supplementing with additional systems for pub/sub and complex data types.

4. **Hazelcast / Apache Ignite:** JVM-based distributed caches with rich feature sets but significantly higher memory overhead and operational complexity. The JVM dependency was undesirable for an infrastructure component.

---

## Decision

We will use **DragonflyDB** as VoxGuard's in-memory data store, replacing Redis in all use cases.

### Key Reasons

- **Multi-threaded architecture:** DragonflyDB is designed from the ground up as a multi-threaded, shared-nothing architecture. It utilizes all available CPU cores without the single-threaded bottleneck of Redis. In benchmarks, DragonflyDB achieves up to 25x the throughput of a single Redis instance on the same hardware.

- **Full Redis compatibility:** DragonflyDB implements the Redis protocol and supports all Redis data structures and commands used by VoxGuard (strings, hashes, sorted sets, lists, streams, pub/sub). Existing Redis client libraries in Rust (`redis-rs`), Go (`go-redis`), and Python (`redis-py`) work without modification.

- **Single-binary deployment:** DragonflyDB runs as a single process that scales vertically across all cores, eliminating the need for Redis Cluster at VoxGuard's current scale. This dramatically reduces operational complexity.

- **Memory efficiency:** DragonflyDB uses a novel memory management approach (dashtable) that is more memory-efficient than Redis's hash table implementation, reducing infrastructure costs.

- **Open-source licensing:** DragonflyDB is licensed under BSL 1.1, which is permissive for our use case and avoids the SSPL concerns associated with recent Redis versions.

---

## Consequences

### Positive

- **Simplified operations:** A single DragonflyDB instance replaces what would otherwise be a multi-node Redis Cluster, reducing deployment complexity, monitoring overhead, and failure modes.
- **Higher throughput headroom:** DragonflyDB's multi-threaded architecture provides significant throughput headroom beyond VoxGuard's current requirements, accommodating future growth without architectural changes.
- **Drop-in migration path:** Full Redis protocol compatibility means all existing Redis client code, libraries, and tooling work unchanged. If we ever need to switch back to Redis (or another Redis-compatible store), the migration cost is minimal.
- **Lower memory footprint:** DragonflyDB's memory efficiency reduces the instance size (and cost) required for a given dataset compared to Redis.
- **Consistent latency:** The shared-nothing threading model avoids lock contention, providing more consistent latency under high concurrency compared to Redis's single-threaded event loop under saturation.

### Negative

- **Smaller community:** DragonflyDB's community and ecosystem are significantly smaller than Redis's. Fewer third-party tools, fewer StackOverflow answers, and fewer production deployment case studies are available.
- **Younger project:** DragonflyDB is a newer project than Redis, with a shorter production track record. There may be edge cases or stability issues that have not yet been discovered and addressed.
- **Feature parity gaps:** While DragonflyDB covers the Redis commands VoxGuard uses, some advanced Redis features (e.g., Redis Modules, certain Lua scripting edge cases) may not be fully supported. This has not impacted VoxGuard but could limit future use cases.
- **Vendor concentration risk:** DragonflyDB is primarily developed by a single company (Dragonfly Inc.). If the company changes direction or ceases operations, the project's future is less certain than Redis's, which has a broader contributor base.

### Mitigations

- Maintain Redis protocol compatibility as a hard requirement so that switching to Redis or another compatible store remains low-cost.
- Monitor the DragonflyDB project health (release cadence, issue resolution, community activity) as part of quarterly dependency reviews.
- Run DragonflyDB in a configuration that allows data persistence (snapshots) so that cache state survives restarts without a full warm-up cycle.
- Contribute bug reports and, where possible, fixes back to the DragonflyDB project to support its health.

---

## References

- [DragonflyDB Documentation](https://www.dragonflydb.io/docs)
- [DragonflyDB vs Redis Benchmarks](https://www.dragonflydb.io/benchmarks)
- [DragonflyDB Architecture Overview](https://www.dragonflydb.io/docs/architecture)
- [Redis Licensing Changes (SSPL)](https://redis.io/blog/redis-adopts-dual-source-available-licensing/)
