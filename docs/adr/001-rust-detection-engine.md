# ADR 001: Rust for the Detection Engine

## Metadata

| Field      | Value                          |
|------------|--------------------------------|
| **Title**  | Use Rust for the Detection Engine |
| **Date**   | 2026-01-10                     |
| **Status** | Accepted                       |
| **Authors**| VoxGuard Architecture Team     |

---

## Context

VoxGuard's core value proposition depends on its ability to detect telecommunications fraud in real time. The detection engine is the most performance-critical component of the platform, sitting in the hot path of every call processed by the system.

### Performance Requirements

- **Throughput:** The engine must sustain processing of **150,000+ calls per second (CPS)** to handle peak traffic from Tier 1 telecommunications carriers.
- **Latency:** The detection pipeline must complete within **< 1 millisecond at P99 latency** to avoid introducing perceptible delay into the call signaling path.
- **Reliability:** The engine must operate continuously with zero downtime. Any crash or pause (including garbage collection pauses) in the detection path can result in missed fraud events or degraded call quality.

### Operational Constraints

- The engine must run efficiently on commodity hardware to keep infrastructure costs manageable at scale.
- Memory usage must be predictable and bounded; unbounded allocations or GC-induced memory spikes are unacceptable.
- The engine must support safe concurrency for parallel rule evaluation across multiple CPU cores.

### Alternatives Evaluated

1. **Go:** Considered for its strong concurrency model (goroutines) and fast compilation. However, Go's garbage collector introduces stop-the-world pauses that, while typically short (sub-millisecond), are unpredictable under high allocation rates. At 150K CPS, the allocation rate is high enough that GC pauses would risk violating the P99 latency SLA. Go was selected for the management API where these constraints are less critical.

2. **C++:** Offers the necessary performance characteristics but lacks memory safety guarantees. Given the security-sensitive nature of fraud detection (processing untrusted CDR data), memory safety vulnerabilities (buffer overflows, use-after-free) represent an unacceptable risk. The development velocity cost of manual memory management was also a concern.

3. **Java/JVM:** JVM-based languages offer mature ecosystems but suffer from GC pauses, high memory overhead, and slower startup times. The JVM's memory footprint would significantly increase infrastructure costs at the required scale.

---

## Decision

We will build the VoxGuard detection engine in **Rust**, using the following core libraries:

- **Actix-Web** as the HTTP framework for the detection engine's API endpoints (health checks, metrics, configuration reload).
- **Tokio** as the asynchronous runtime for non-blocking I/O, connection management, and concurrent rule evaluation.
- **serde** for zero-copy deserialization of CDR payloads.
- Custom detection rule evaluation engine using Rust's pattern matching and trait system.

### Key Design Choices

- The detection pipeline uses a **zero-allocation hot path** where possible, pre-allocating buffers and reusing them across requests.
- Detection rules are compiled to Rust structs at configuration load time, not interpreted at runtime.
- Connection pools to DragonflyDB (for rule caching) and ClickHouse (for CDR logging) use async clients to avoid blocking the detection path.

---

## Consequences

### Positive

- **Performance:** Rust's zero-cost abstractions, lack of garbage collector, and compile-time optimizations enable consistent sub-millisecond P99 latency at 150K+ CPS. Early benchmarks show P99 latency of 0.4ms at 160K CPS on a 16-core machine.
- **Memory safety:** Rust's ownership model and borrow checker eliminate entire classes of memory safety vulnerabilities (buffer overflows, use-after-free, data races) at compile time, which is critical for a system processing untrusted input data.
- **Predictable resource usage:** No garbage collector means no GC pauses, no memory spikes, and deterministic memory consumption. This simplifies capacity planning and resource allocation.
- **Concurrency safety:** Rust's type system enforces thread safety at compile time via `Send` and `Sync` traits, eliminating data races in the concurrent rule evaluation pipeline.
- **Ecosystem maturity:** The Rust async ecosystem (Tokio, Actix-Web) is production-proven at scale by companies like Cloudflare, Discord, and AWS (Firecracker).

### Negative

- **Steeper learning curve:** Rust has a steeper learning curve than Go or Python, particularly around the ownership model, lifetimes, and async patterns. This increases onboarding time for new developers and may slow initial development velocity.
- **Longer compile times:** Rust's compile times are longer than Go's, which can slow the development feedback loop. This is mitigated by using `cargo-watch` for incremental compilation during development and by keeping the detection engine crate modular.
- **Smaller talent pool:** The Rust developer talent pool is smaller than that of Go, Python, or Java. Recruitment may require more effort or investment in training existing team members.
- **Ecosystem gaps:** While the Rust ecosystem is growing rapidly, some niche libraries (e.g., certain telecom protocol parsers) may not have mature Rust implementations, requiring custom development or FFI bindings.

### Mitigations

- Provide Rust training resources and pair programming sessions for team members new to the language.
- Use `cargo-watch` and `mold` (fast linker) to minimize compile-time friction during development.
- Isolate Rust to the detection engine and related high-performance components; use Go and Python for services where development velocity is prioritized over raw performance.
- Maintain comprehensive documentation and code examples within the Rust codebase.

---

## References

- [Rust Performance Book](https://nnethercote.github.io/perf-book/)
- [Actix-Web Documentation](https://actix.rs/docs/)
- [Tokio Tutorial](https://tokio.rs/tokio/tutorial)
- [Discord: Why We Switched from Go to Rust](https://discord.com/blog/why-discord-is-switching-from-go-to-rust)
