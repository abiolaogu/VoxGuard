# ADR 003: Hasura for the GraphQL API Layer

## Metadata

| Field      | Value                                  |
|------------|----------------------------------------|
| **Title**  | Use Hasura as the GraphQL API Layer    |
| **Date**   | 2026-01-12                             |
| **Status** | Accepted                               |
| **Authors**| VoxGuard Architecture Team             |

---

## Context

VoxGuard's frontend (`packages/web`) and external integrations require a flexible, performant API layer to access operational data stored in YugabyteDB. The platform must support:

1. **Real-time subscriptions:** The dashboard, case management, and KPI pages require live-updating data. Operators monitoring active fraud cases need to see status changes, new alerts, and metric updates in real time without manual page refreshes.

2. **Role-based access control (RBAC):** VoxGuard serves multiple user roles (operators, analysts, administrators, auditors, NCC compliance officers) with different data access requirements. The API layer must enforce granular, row-level and column-level permissions based on the authenticated user's role.

3. **Rapid iteration:** The VoxGuard frontend is under active development with frequent additions of new pages and data views. The API layer must support rapid schema evolution without requiring hand-written resolvers for every CRUD operation.

4. **NCC compliance:** Audit logging of all data access is required for NCC regulatory compliance. The API layer must provide hooks for logging who accessed what data and when.

### Requirements

- Real-time data subscriptions over WebSocket
- Declarative, role-based row-level and column-level access control
- Automatic CRUD API generation from the database schema
- Support for custom business logic via event triggers, actions, and remote schemas
- PostgreSQL (and YugabyteDB YSQL) compatibility
- GraphQL as the primary query language (the frontend team has standardized on Refine's GraphQL data provider)

### Alternatives Evaluated

1. **Custom GraphQL server (e.g., Apollo Server, async-graphql in Rust, gqlgen in Go):**
   - **Pros:** Full control over resolvers, schema design, and execution.
   - **Cons:** Requires writing and maintaining resolvers for every entity and relationship. At VoxGuard's current schema size (40+ tables with complex relationships), this represents significant ongoing development effort. Real-time subscriptions require additional infrastructure (e.g., Redis pub/sub, WebSocket server). RBAC must be implemented manually in every resolver. Development velocity would be significantly slower.

2. **PostGraphile:**
   - **Pros:** Auto-generates a GraphQL API from PostgreSQL, similar to Hasura. Strong plugin system.
   - **Cons:** Subscriptions are less mature than Hasura's. RBAC is implemented via PostgreSQL Row-Level Security (RLS) policies, which are powerful but harder to manage and audit than Hasura's declarative permission system. The operational model (Node.js process) adds another runtime to manage. Smaller commercial ecosystem.

3. **REST API (hand-written in Go):**
   - **Pros:** The Go management API already exists. Simple, well-understood architecture.
   - **Cons:** REST lacks the flexibility of GraphQL for the frontend. The dashboard and data-heavy pages require fetching data from multiple related entities, leading to either over-fetching, under-fetching, or excessive endpoint proliferation. Real-time updates would require implementing WebSocket or SSE infrastructure from scratch. The frontend team would need to maintain a large number of API client functions.

---

## Decision

We will use **Hasura GraphQL Engine** as the primary API layer between the frontend and YugabyteDB.

### Configuration

- **Hasura** connects to YugabyteDB via its YSQL (PostgreSQL-compatible) interface.
- **Metadata as code:** All Hasura metadata (tracked tables, relationships, permissions, event triggers) is stored in the `hasura/` directory and applied via the Hasura CLI during deployment. This ensures the API configuration is version-controlled and reproducible.
- **Role-based permissions:** Permissions are defined per table, per role, per operation (select, insert, update, delete) with row-level and column-level granularity. Permissions are expressed declaratively in Hasura metadata YAML files.
- **Real-time subscriptions:** Hasura's built-in subscription engine is used for live-updating dashboard data, alert feeds, and case status changes. Subscriptions use WebSocket transport.
- **Event triggers:** Database events (inserts, updates, deletes on specific tables) trigger webhooks to the Go management API and Python ML pipeline for asynchronous processing (e.g., sending notifications, updating ML features, generating audit log entries).
- **Actions:** Custom business logic that cannot be expressed as CRUD (e.g., complex report generation, multi-step workflows) is implemented as Hasura Actions, which delegate to the Go management API.
- **Remote schemas:** The Python ML pipeline's FastAPI GraphQL endpoint is stitched into the Hasura schema as a remote schema, providing a unified GraphQL API for the frontend.

### Frontend Integration

The frontend uses Refine's `graphql` data provider configured to connect to the Hasura endpoint. This provides:
- Automatic query/mutation generation for CRUD operations
- Built-in pagination, sorting, and filtering
- Subscription support for real-time data
- Type-safe operations via GraphQL code generation

---

## Consequences

### Positive

- **Rapid API development:** New tables tracked in Hasura immediately become available as GraphQL queries, mutations, and subscriptions. Adding a new entity to the API takes minutes instead of hours of resolver writing.
- **Declarative RBAC:** Permissions are defined in YAML files, version-controlled alongside the application code, and auditable. Adding a new role or modifying permissions does not require code changes to resolvers.
- **Built-in real-time subscriptions:** Hasura's subscription engine uses database polling (configurable interval) to detect changes and push updates over WebSocket. No additional pub/sub infrastructure is needed for the frontend's real-time requirements.
- **Schema consistency:** The GraphQL schema is automatically derived from the database schema, eliminating drift between the database, API, and frontend type definitions.
- **Audit trail:** Hasura's event triggers provide a mechanism to log all data mutations for NCC compliance without modifying application code.
- **Unified API surface:** By stitching the ML pipeline's GraphQL API as a remote schema, the frontend has a single GraphQL endpoint for all data needs.

### Negative

- **Vendor coupling:** Adopting Hasura introduces a dependency on a specific product. While Hasura is open-source (Apache 2.0 for the core engine), migrating away from it would require building custom resolvers, subscription infrastructure, and permission logic.
- **Limited custom resolver flexibility:** While Hasura Actions and Remote Schemas provide escape hatches for custom logic, complex query patterns (e.g., multi-step aggregations, cross-service joins) can be awkward to express. Some queries may require restructuring to fit Hasura's model.
- **Subscription scalability:** Hasura's subscription engine polls the database. At very high subscription counts or very low polling intervals, this can place significant load on YugabyteDB. Monitoring and tuning will be required as the user base grows.
- **Additional infrastructure component:** Hasura is another service to deploy, monitor, and maintain. It introduces a dependency on its runtime (Haskell-based binary) and its own set of configuration, versioning, and upgrade concerns.
- **Learning curve:** Developers must learn Hasura's metadata model, permission system, and event trigger configuration in addition to GraphQL itself. The Hasura console, while useful, can lead to configuration drift if used directly in production instead of the CLI-based metadata workflow.

### Mitigations

- Enforce a strict **metadata-as-code** workflow: all Hasura configuration changes must go through the `hasura/` directory and be applied via CI/CD. Direct console modifications in production are prohibited.
- Monitor YugabyteDB load from Hasura subscriptions and adjust polling intervals or subscription multiplexing as needed.
- Document Hasura-specific patterns and anti-patterns in the developer guide to reduce the learning curve.
- Keep the Go management API capable of serving critical endpoints independently, so that Hasura is not a single point of failure for all API access.

---

## References

- [Hasura GraphQL Engine Documentation](https://hasura.io/docs/latest/)
- [Hasura Authorization (Permissions)](https://hasura.io/docs/latest/auth/authorization/)
- [Hasura Subscriptions Architecture](https://hasura.io/docs/latest/subscriptions/postgres/)
- [Hasura Event Triggers](https://hasura.io/docs/latest/event-triggers/overview/)
- [Refine GraphQL Data Provider](https://refine.dev/docs/data/packages/graphql/)
