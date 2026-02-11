# VoxGuard Web Dashboard

Enterprise-grade fraud detection and monitoring dashboard for VoxGuard Anti-Call Masking platform.

## Overview

The VoxGuard Web Dashboard is a React-based single-page application (SPA) that provides real-time monitoring, investigation, and management capabilities for fraud analysts, NOC engineers, and compliance officers.

### Key Features

- **Real-Time Monitoring**: Live alert counts and updates via GraphQL subscriptions
- **Alert Management**: Complete CRUD operations for fraud alerts with severity classification
- **Gateway Management**: Configure and manage voice gateways with blacklisting capabilities
- **User Management**: Role-based user administration
- **Analytics Dashboard**: Visual insights with charts and trends
- **System Health**: Quick access to external monitoring tools (Grafana, Prometheus, etc.)
- **Dark/Light Theme**: User-preference-based theme switching with persistence
- **Responsive Design**: Mobile-friendly interface for on-the-go monitoring

## Technology Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| React | 18.2+ | UI framework |
| TypeScript | 5.3+ | Type safety |
| Vite | 5.0+ | Build tool and dev server |
| Refine | 4.50+ | Admin panel framework |
| Ant Design | 5.12+ | UI component library |
| Apollo Client | 3.8+ | GraphQL client |
| React Router | 6.20+ | Routing |
| Vitest | 1.0+ | Unit testing |
| GraphQL Codegen | 5.0+ | Type generation |

## Project Structure

```
packages/web/
├── src/
│   ├── App.tsx                    # Main application component
│   ├── main.tsx                   # Application entry point
│   ├── pages/
│   │   ├── dashboard/             # Dashboard page with charts
│   │   │   ├── index.tsx
│   │   │   ├── components/        # Dashboard-specific components
│   │   │   └── __tests__/         # Dashboard tests
│   │   └── login/                 # Authentication page
│   ├── resources/                 # Resource CRUD pages (Refine resources)
│   │   ├── alerts/                # Alert management
│   │   ├── gateways/              # Gateway management
│   │   ├── users/                 # User management
│   │   ├── analytics/             # Analytics page
│   │   └── settings/              # Settings page
│   ├── components/
│   │   ├── charts/                # Reusable chart components
│   │   ├── common/                # Shared UI components
│   │   └── layout/                # Layout components (Header, Footer, Title)
│   ├── graphql/
│   │   ├── queries/               # GraphQL queries
│   │   ├── mutations/             # GraphQL mutations
│   │   └── subscriptions/         # Real-time subscriptions
│   ├── providers/                 # Refine providers
│   │   ├── auth-provider.ts       # Authentication logic
│   │   ├── data-provider.ts       # Data fetching logic
│   │   ├── live-provider.ts       # Real-time updates
│   │   └── access-control.ts      # Permission management
│   ├── config/
│   │   ├── refine.ts              # Refine framework config
│   │   ├── graphql.ts             # Apollo Client config
│   │   ├── antd-theme.ts          # Ant Design theme
│   │   └── external-services.ts   # External tool links
│   ├── hooks/                     # Custom React hooks
│   └── styles/
│       └── global.css             # Global styles and CSS variables
├── public/                        # Static assets
├── index.html                     # HTML entry point
├── vite.config.ts                 # Vite configuration
├── tsconfig.json                  # TypeScript configuration
├── codegen.ts                     # GraphQL Codegen config
├── package.json                   # Dependencies
├── Dockerfile                     # Production Docker image
└── nginx.conf                     # Production nginx config
```

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- Hasura GraphQL Engine running on http://localhost:8082
- Management API running on http://localhost:8081
- Detection Engine running on http://localhost:8080

### Installation

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.example .env.local
   ```

   Edit `.env.local` with your configuration:
   ```env
   VITE_HASURA_ENDPOINT=http://localhost:8082/v1/graphql
   VITE_HASURA_WS_ENDPOINT=ws://localhost:8082/v1/graphql
   VITE_HASURA_ADMIN_SECRET=your_hasura_admin_secret
   VITE_API_BASE_URL=http://localhost:8081
   VITE_ACM_ENGINE_URL=http://localhost:8080
   ```

3. **Generate GraphQL types** (optional, for type safety):
   ```bash
   npm run codegen
   ```

### Development

Start the development server:

```bash
npm run dev
```

The dashboard will be available at http://localhost:5173

**Features during development:**
- Hot Module Replacement (HMR)
- TypeScript error checking
- ESLint for code quality
- Fast refresh for React components

### Testing

Run unit tests:

```bash
npm test
```

Run tests in watch mode:

```bash
npm test -- --watch
```

Run tests with coverage:

```bash
npm test -- --coverage
```

### Building for Production

Build the production bundle:

```bash
npm run build
```

Preview production build locally:

```bash
npm run preview
```

### Docker Deployment

Build the Docker image:

```bash
docker build -t voxguard-web:latest .
```

Run the container:

```bash
docker run -p 8080:80 voxguard-web:latest
```

The dashboard will be available at http://localhost:8080

## Architecture

### Data Flow

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│  React + Refine     │
│  (State Management) │
└──────┬──────────────┘
       │
       ├─────────────────┐
       │                 │
       ▼                 ▼
┌──────────────┐  ┌──────────────┐
│ Apollo Client│  │  Auth Provider│
│  (GraphQL)   │  │  (JWT)        │
└──────┬───────┘  └───────────────┘
       │
       ▼
┌──────────────────────┐
│  Hasura GraphQL      │
│  (Real-time & CRUD)  │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  PostgreSQL/Yugabyte │
│  (Database)          │
└──────────────────────┘
```

### Authentication

The dashboard uses a JWT-based authentication system:

1. User logs in via `/login` page
2. Credentials sent to Management API
3. API returns JWT token
4. Token stored in localStorage
5. Token included in all GraphQL requests via Apollo Link
6. Protected routes check for valid token

### Real-Time Updates

Real-time features use GraphQL subscriptions over WebSocket:

- **Alert Counts**: Live updates on dashboard
- **New Alerts**: Instant notifications
- **System Status**: Real-time health monitoring

### Theming

The dashboard supports dark and light themes:

- Theme preference stored in localStorage
- CSS variables for dynamic theme switching
- Ant Design ConfigProvider for component theming
- Custom global styles in `src/styles/global.css`

## GraphQL API

### Key Queries

- `GET_RECENT_ALERTS`: Fetch recent fraud alerts
- `GET_ALERT_BY_ID`: Get alert details
- `GET_GATEWAYS`: List all gateways
- `GET_USERS`: List all users

### Key Mutations

- `UPDATE_ALERT_STATUS`: Change alert investigation status
- `CREATE_GATEWAY`: Add new gateway
- `UPDATE_GATEWAY`: Modify gateway configuration
- `BLACKLIST_GATEWAY`: Block fraudulent gateway

### Key Subscriptions

- `UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION`: Real-time alert counts
- `NEW_ALERTS_SUBSCRIPTION`: Live alert stream

## Configuration

### External Services

Configure links to external monitoring tools in `.env.local`:

```env
VITE_GRAFANA_URL=http://localhost:3001
VITE_PROMETHEUS_URL=http://localhost:9091
VITE_HASURA_CONSOLE_URL=http://localhost:8082/console
VITE_YUGABYTE_URL=http://localhost:9005
VITE_CLICKHOUSE_URL=http://localhost:8123/play
VITE_QUESTDB_URL=http://localhost:9002
VITE_HOMER_URL=http://localhost:9080
```

### Refine Resources

Resources are configured in `src/config/refine.ts`:

```typescript
export const resources = [
  {
    name: 'dashboard',
    list: '/',
    meta: { icon: <DashboardOutlined />, label: 'Dashboard' },
  },
  {
    name: 'alerts',
    list: '/alerts',
    show: '/alerts/show/:id',
    edit: '/alerts/edit/:id',
    meta: { icon: <AlertOutlined />, label: 'Alerts' },
  },
  // ... more resources
];
```

## Troubleshooting

### Common Issues

**GraphQL Connection Errors:**
- Check Hasura is running on correct port
- Verify `VITE_HASURA_ENDPOINT` in `.env.local`
- Check CORS settings in Hasura console

**Authentication Failures:**
- Verify Management API is accessible
- Check JWT token expiration
- Clear localStorage and re-login

**Build Errors:**
- Delete `node_modules` and reinstall: `rm -rf node_modules && npm install`
- Clear Vite cache: `rm -rf node_modules/.vite`

**WebSocket Connection Issues:**
- Check `VITE_HASURA_WS_ENDPOINT` uses `ws://` or `wss://`
- Verify firewall allows WebSocket connections
- Check Hasura WebSocket settings

## Performance Optimization

### Implemented Optimizations

- **Code Splitting**: Routes are lazy-loaded
- **Tree Shaking**: Unused code eliminated in production
- **Minification**: JavaScript and CSS minified
- **Gzip Compression**: nginx configuration includes gzip
- **CDN-Ready**: Static assets cacheable
- **Polling Optimization**: Smart polling intervals for queries

### Future Optimizations

- Implement React Query for advanced caching
- Add service worker for offline support
- Optimize bundle size with dynamic imports
- Implement virtual scrolling for large tables

## Contributing

### Code Style

- **TypeScript**: Strict mode enabled
- **ESLint**: Run `npm run lint` before committing
- **Formatting**: Use Prettier (configured in `.prettierrc`)
- **Naming**: camelCase for variables, PascalCase for components

### Testing Guidelines

- Write tests for all new components
- Aim for >80% code coverage
- Mock external dependencies (Apollo, Ant Design)
- Test user interactions and edge cases

## Security

### Best Practices

- **Authentication**: JWT tokens with expiration
- **Authorization**: Role-based access control
- **XSS Prevention**: React's built-in escaping
- **CSRF Protection**: Token-based authentication
- **Secure Storage**: Sensitive data not in localStorage
- **HTTPS**: Always use TLS in production

### Environment Variables

Never commit `.env.local` or secrets to version control. Use environment-specific configuration for different environments.

## Deployment

### Production Checklist

- [ ] Set `NODE_ENV=production`
- [ ] Configure production API endpoints
- [ ] Enable HTTPS
- [ ] Set up proper CORS policies
- [ ] Configure CDN for static assets
- [ ] Enable gzip compression
- [ ] Set up monitoring (Sentry, LogRocket)
- [ ] Configure backup strategies
- [ ] Test on target browsers
- [ ] Run security audit: `npm audit`

## Support

For issues and questions:
- Check documentation in `docs/` directory
- Review `docs/DASHBOARD.md` for detailed dashboard guide
- Check Factory Protocol in `CLAUDE.md`
- Create issue in repository

## License

Proprietary - BillyRonks Global

---

**Version:** 2.0.0
**Last Updated:** 2026-02-03
**Maintained by:** Factory Autonomous System
