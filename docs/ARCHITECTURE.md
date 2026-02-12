# Architecture Overview

> **See Also:** For the comprehensive architecture document, refer to [`docs/technical/SAD.md`](technical/SAD.md) (Solution Architecture Document, 1,450+ lines). This file provides a high-level conceptual overview.

## Design Principles

The Anti-Call Masking Platform is built on these architectural principles:

1. **Domain-Driven Design (DDD)** - Rich domain models with encapsulated behavior
2. **Hexagonal Architecture** - Ports & adapters for infrastructure independence
3. **Event-Driven** - Domain events for cross-context communication
4. **CQRS** - Separated command and query paths for scalability

---

## Bounded Contexts

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           DETECTION CONTEXT (Rust)                           │
│                                                                              │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐     │
│  │    Call     │   │ FraudAlert  │   │   Gateway   │   │ ThreatLevel │     │
│  │  Aggregate  │   │  Aggregate  │   │  Aggregate  │   │  Aggregate  │     │
│  └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘     │
│                                                                              │
│  Value Objects: MSISDN, IPAddress, FraudScore, CallId, DetectionWindow      │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                          MANAGEMENT CONTEXT (Go)                             │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────┐  ┌───────────────┐ │
│  │ Gateway Context │  │  Fraud Context  │  │   MNP    │  │  Compliance   │ │
│  │                 │  │                 │  │ Context  │  │   Context     │ │
│  │ • Gateway       │  │ • FraudAlert    │  │          │  │               │ │
│  │ • Repository    │  │ • Blacklist     │  │ • MNP    │  │ • NCCReport   │ │
│  │ • Service       │  │ • Service       │  │ • Lookup │  │ • Settlement  │ │
│  └─────────────────┘  └─────────────────┘  └──────────┘  └───────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         PROCESSING CONTEXT (Python)                          │
│                                                                              │
│  Domain: value_objects, entities, services, events                          │
│  Infrastructure: SIP processing, CDR parsing, inference                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

```
1. SIP INVITE arrives at OpenSIPS
         │
         ▼
2. OpenSIPS forwards to Detection Engine
         │
         ▼
3. Detection Engine:
   ├── Parses A/B numbers, source IP
   ├── Validates MSISDN format (Nigerian +234)
   ├── Adds to DragonflyDB sliding window
   ├── Checks distinct caller count
   └── If threshold exceeded → Create FraudAlert
         │
         ▼
4. Alert stored in YugabyteDB
   Metrics sent to QuestDB
         │
         ▼
5. Management API exposes alerts
   Analysts acknowledge/resolve
         │
         ▼
6. NCC Compliance reporting
```

---

## Repository Pattern

All data access is abstracted through repository interfaces:

### Rust Ports (Interfaces)
```rust
pub trait CallRepository: Send + Sync {
    async fn save(&self, call: Call) -> Result<(), Error>;
    async fn find_by_id(&self, id: CallId) -> Result<Option<Call>, Error>;
    async fn find_calls_in_window(&self, ...) -> Result<Vec<Call>, Error>;
}

pub trait DetectionCache: Send + Sync {
    async fn add_caller_to_window(&self, ...) -> Result<(), Error>;
    async fn get_distinct_caller_count(&self, b_number: &str) -> Result<u32, Error>;
}
```

### Go Interfaces
```go
type GatewayRepository interface {
    Save(ctx context.Context, gateway *Gateway) error
    FindByID(ctx context.Context, id string) (*Gateway, error)
    FindByIP(ctx context.Context, ip string) (*Gateway, error)
}

type AlertRepository interface {
    Save(ctx context.Context, alert *FraudAlert) error
    FindPending(ctx context.Context) ([]*FraudAlert, error)
}
```

### Python Abstractions
```python
class CallRepository(ABC):
    @abstractmethod
    async def save(self, call: Call) -> None: ...
    
    @abstractmethod
    async def find_calls_in_window(self, b_number: MSISDN, ...) -> List[Call]: ...
```

---

## Infrastructure Adapters

| Adapter | Technology | Purpose |
|---------|------------|---------|
| DragonflyCache | DragonflyDB | Sliding window detection (Redis-compatible) |
| QuestDBStore | QuestDB | Time-series ingestion (1.5M rows/sec) |
| YugabyteRepository | YugabyteDB | Relational data (PostgreSQL-compatible) |
| ClickHouseStore | ClickHouse | Historical analytics |

---

## Domain Events

Cross-context communication via domain events:

| Event | Publisher | Subscribers |
|-------|-----------|-------------|
| `FraudDetectedEvent` | Detection Service | Alert Service, NCC Reporter |
| `CallRegisteredEvent` | Detection Service | Metrics, Analytics |
| `AlertAcknowledgedEvent` | Alert Service | Audit Log |
| `GatewayBlacklistedEvent` | Gateway Service | Detection Cache |
| `NCCReportSubmittedEvent` | Compliance Service | Audit Log |

---

## Deployment Topology

```
Lagos (Primary)             Abuja (Replica)          Asaba (Replica)
┌─────────────────┐        ┌─────────────────┐      ┌─────────────────┐
│ OpenSIPS x3     │        │ OpenSIPS x1     │      │ OpenSIPS x1     │
│ Detection Engine│        │ Detection Engine│      │ Detection Engine│
│ DragonflyDB     │───────▶│ DragonflyDB     │      │ DragonflyDB     │
│   (Primary)     │        │   (Replica)     │      │   (Replica)     │
│ YugabyteDB      │        │                 │      │                 │
│   (Leaders)     │        │                 │      │                 │
└─────────────────┘        └─────────────────┘      └─────────────────┘
```
