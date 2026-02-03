import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { MockedProvider } from '@apollo/client/testing';
import { BrowserRouter } from 'react-router-dom';
import { DashboardPage } from '../index';
import { UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION } from '../../../graphql/subscriptions';
import { GET_RECENT_ALERTS } from '../../../graphql/queries';

// Mock Ant Design components that cause issues in tests
vi.mock('antd', async () => {
  const actual = await vi.importActual('antd');
  return {
    ...actual,
    Card: ({ children, title, extra }: any) => (
      <div data-testid="card">
        {title && <div data-testid="card-title">{title}</div>}
        {extra && <div data-testid="card-extra">{extra}</div>}
        {children}
      </div>
    ),
    Statistic: ({ title, value, prefix }: any) => (
      <div data-testid="statistic">
        <div data-testid="statistic-title">{title}</div>
        <div data-testid="statistic-value">{value}</div>
        {prefix}
      </div>
    ),
    Table: ({ dataSource, columns }: any) => (
      <div data-testid="table">
        {dataSource?.map((row: any) => (
          <div key={row.id} data-testid="table-row">
            {row.b_number}
          </div>
        ))}
      </div>
    ),
    Badge: ({ children, text }: any) => <span data-testid="badge">{text || children}</span>,
  };
});

// Mock chart components
vi.mock('../components/AlertsTrendChart', () => ({
  AlertsTrendChart: () => <div data-testid="alerts-trend-chart">Alerts Trend Chart</div>,
}));

vi.mock('../components/SeverityPieChart', () => ({
  SeverityPieChart: () => <div data-testid="severity-pie-chart">Severity Pie Chart</div>,
}));

vi.mock('../components/TrafficAreaChart', () => ({
  TrafficAreaChart: () => <div data-testid="traffic-area-chart">Traffic Area Chart</div>,
}));

describe('DashboardPage', () => {
  const mockAlertCounts = {
    request: {
      query: UNRESOLVED_ALERTS_COUNT_SUBSCRIPTION,
    },
    result: {
      data: {
        new_count: { aggregate: { count: 5 } },
        investigating_count: { aggregate: { count: 3 } },
        confirmed_count: { aggregate: { count: 2 } },
        critical_count: { aggregate: { count: 1 } },
      },
    },
  };

  const mockRecentAlerts = {
    request: {
      query: GET_RECENT_ALERTS,
      variables: { limit: 10 },
    },
    result: {
      data: {
        acm_alerts: [
          {
            id: '1',
            b_number: '+2348012345678',
            a_number: '+2349087654321',
            severity: 'HIGH',
            status: 'NEW',
            threat_score: 85,
            carrier_name: 'MTN Nigeria',
            created_at: '2026-02-03T08:00:00Z',
          },
          {
            id: '2',
            b_number: '+2347011111111',
            a_number: '+2348022222222',
            severity: 'CRITICAL',
            status: 'INVESTIGATING',
            threat_score: 95,
            carrier_name: 'Airtel Nigeria',
            created_at: '2026-02-03T07:45:00Z',
          },
        ],
      },
    },
  };

  const renderDashboard = (mocks = [mockAlertCounts, mockRecentAlerts]) => {
    return render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <BrowserRouter>
          <DashboardPage />
        </BrowserRouter>
      </MockedProvider>
    );
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders dashboard title and description', () => {
    renderDashboard();
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Real-time monitoring of call masking detection')).toBeInTheDocument();
  });

  it('displays all alert statistics cards', () => {
    renderDashboard();
    expect(screen.getByText('New Alerts')).toBeInTheDocument();
    expect(screen.getByText('Critical Alerts')).toBeInTheDocument();
    expect(screen.getByText('Investigating')).toBeInTheDocument();
    expect(screen.getByText('Confirmed')).toBeInTheDocument();
  });

  it('shows correct alert counts from subscription', async () => {
    renderDashboard();

    await waitFor(() => {
      // Find all statistic values
      const statisticValues = screen.getAllByTestId('statistic-value');

      // Extract the values (they should be in order: New, Critical, Investigating, Confirmed)
      const values = statisticValues.map(el => el.textContent);

      // Check that we have the correct counts
      expect(values).toContain('5'); // New alerts
      expect(values).toContain('3'); // Investigating
      expect(values).toContain('2'); // Confirmed
      expect(values).toContain('1'); // Critical
    });
  });

  it('renders all dashboard charts', () => {
    renderDashboard();
    expect(screen.getByTestId('alerts-trend-chart')).toBeInTheDocument();
    expect(screen.getByTestId('severity-pie-chart')).toBeInTheDocument();
    expect(screen.getByTestId('traffic-area-chart')).toBeInTheDocument();
  });

  it('displays recent alerts table with correct data', async () => {
    renderDashboard();

    await waitFor(() => {
      expect(screen.getByText('+2348012345678')).toBeInTheDocument();
      expect(screen.getByText('+2347011111111')).toBeInTheDocument();
    });
  });

  it('renders quick access links section', () => {
    renderDashboard();
    expect(screen.getByText(/Quick Access:/)).toBeInTheDocument();
    expect(screen.getByText('Grafana')).toBeInTheDocument();
    expect(screen.getByText('Prometheus')).toBeInTheDocument();
    expect(screen.getByText('QuestDB')).toBeInTheDocument();
  });

  it('displays chart section titles', () => {
    renderDashboard();
    expect(screen.getByText('Alert Trends (24h)')).toBeInTheDocument();
    expect(screen.getByText('Alerts by Severity')).toBeInTheDocument();
    expect(screen.getByText('Traffic Overview')).toBeInTheDocument();
    expect(screen.getByText('Recent Alerts')).toBeInTheDocument();
  });

  it('handles loading state gracefully', () => {
    const emptyMocks = [
      {
        request: mockAlertCounts.request,
        result: { data: null },
      },
      {
        request: mockRecentAlerts.request,
        result: { data: null },
      },
    ];

    renderDashboard(emptyMocks);

    // Dashboard should still render with loading states
    expect(screen.getByText('Dashboard')).toBeInTheDocument();
  });

  it('handles zero alert counts', async () => {
    const zeroCountsMock = {
      request: mockAlertCounts.request,
      result: {
        data: {
          new_count: { aggregate: { count: 0 } },
          investigating_count: { aggregate: { count: 0 } },
          confirmed_count: { aggregate: { count: 0 } },
          critical_count: { aggregate: { count: 0 } },
        },
      },
    };

    const emptyAlertsMock = {
      request: mockRecentAlerts.request,
      result: {
        data: {
          acm_alerts: [],
        },
      },
    };

    renderDashboard([zeroCountsMock, emptyAlertsMock]);

    await waitFor(() => {
      const statisticValues = screen.getAllByTestId('statistic-value');
      const values = statisticValues.map(el => el.textContent);

      // All counts should be 0
      expect(values.every(v => v === '0')).toBe(true);
    });
  });

  it('renders "View All" link for recent alerts', () => {
    renderDashboard();
    const viewAllLink = screen.getByText(/View All/);
    expect(viewAllLink).toBeInTheDocument();
    expect(viewAllLink.closest('a')).toHaveAttribute('href', '/alerts');
  });

  it('applies fade-in animation class', () => {
    const { container } = renderDashboard();
    const mainDiv = container.querySelector('.acm-fade-in');
    expect(mainDiv).toBeInTheDocument();
  });
});
