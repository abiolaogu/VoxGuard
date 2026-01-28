package fraud_test

import (
	"context"
	"testing"
	"time"

	"github.com/billyronks/acm-management-api/internal/domain/fraud/entity"
	"github.com/billyronks/acm-management-api/internal/domain/fraud/repository"
	"github.com/billyronks/acm-management-api/internal/domain/fraud/service"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// MockAlertRepository implements AlertRepository for testing
type MockAlertRepository struct {
	alerts map[string]*entity.FraudAlert
}

func NewMockAlertRepository() *MockAlertRepository {
	return &MockAlertRepository{
		alerts: make(map[string]*entity.FraudAlert),
	}
}

func (m *MockAlertRepository) Save(ctx context.Context, alert *entity.FraudAlert) error {
	m.alerts[alert.ID()] = alert
	return nil
}

func (m *MockAlertRepository) FindByID(ctx context.Context, id string) (*entity.FraudAlert, error) {
	return m.alerts[id], nil
}

func (m *MockAlertRepository) FindAll(ctx context.Context, filter repository.AlertFilter, page, pageSize int) ([]*entity.FraudAlert, int, error) {
	result := make([]*entity.FraudAlert, 0, len(m.alerts))
	for _, alert := range m.alerts {
		result = append(result, alert)
	}
	return result, len(result), nil
}

func (m *MockAlertRepository) FindPending(ctx context.Context) ([]*entity.FraudAlert, error) {
	result := []*entity.FraudAlert{}
	for _, alert := range m.alerts {
		if alert.IsPending() {
			result = append(result, alert)
		}
	}
	return result, nil
}

func (m *MockAlertRepository) FindBySeverity(ctx context.Context, severity entity.Severity) ([]*entity.FraudAlert, error) {
	result := []*entity.FraudAlert{}
	for _, alert := range m.alerts {
		if alert.Severity() == severity {
			result = append(result, alert)
		}
	}
	return result, nil
}

func (m *MockAlertRepository) CountPending(ctx context.Context) (int64, error) {
	count := int64(0)
	for _, alert := range m.alerts {
		if alert.IsPending() {
			count++
		}
	}
	return count, nil
}

func (m *MockAlertRepository) CountBySeverity(ctx context.Context) (map[entity.Severity]int64, error) {
	result := make(map[entity.Severity]int64)
	for _, alert := range m.alerts {
		result[alert.Severity()]++
	}
	return result, nil
}

// MockBlacklistRepository implements BlacklistRepository for testing
type MockBlacklistRepository struct {
	entries map[string]*entity.Blacklist
}

func NewMockBlacklistRepository() *MockBlacklistRepository {
	return &MockBlacklistRepository{
		entries: make(map[string]*entity.Blacklist),
	}
}

func (m *MockBlacklistRepository) Save(ctx context.Context, entry *entity.Blacklist) error {
	m.entries[entry.ID] = entry
	return nil
}

func (m *MockBlacklistRepository) FindByValue(ctx context.Context, value string) (*entity.Blacklist, error) {
	for _, entry := range m.entries {
		if entry.Value == value {
			return entry, nil
		}
	}
	return nil, nil
}

func (m *MockBlacklistRepository) FindAll(ctx context.Context, entryType string, page, pageSize int) ([]*entity.Blacklist, int, error) {
	result := make([]*entity.Blacklist, 0)
	for _, e := range m.entries {
		if entryType == "" || e.EntryType == entryType {
			result = append(result, e)
		}
	}
	return result, len(result), nil
}

func (m *MockBlacklistRepository) Delete(ctx context.Context, id string) error {
	delete(m.entries, id)
	return nil
}

func (m *MockBlacklistRepository) IsBlacklisted(ctx context.Context, value string) (bool, error) {
	for _, entry := range m.entries {
		if entry.Value == value && !entry.IsExpired() {
			return true, nil
		}
	}
	return false, nil
}

func (m *MockBlacklistRepository) CleanupExpired(ctx context.Context) (int, error) {
	count := 0
	for id, entry := range m.entries {
		if entry.IsExpired() {
			delete(m.entries, id)
			count++
		}
	}
	return count, nil
}

// MockFraudAnalyticsRepository implements FraudAnalyticsRepository for testing
type MockFraudAnalyticsRepository struct{}

func (m *MockFraudAnalyticsRepository) GetDashboardSummary(ctx context.Context) (*repository.DashboardSummary, error) {
	return &repository.DashboardSummary{
		TotalAlerts24h:    100,
		CriticalAlerts:    5,
		PendingAlerts:     25,
		ResolvedAlerts24h: 75,
		FalsePositiveRate: 0.05,
	}, nil
}

func (m *MockFraudAnalyticsRepository) GetFraudTrends(ctx context.Context, days int) ([]*repository.FraudTrend, error) {
	return []*repository.FraudTrend{}, nil
}

func (m *MockFraudAnalyticsRepository) GetHotspots(ctx context.Context, hours int) ([]*repository.FraudHotspot, error) {
	return []*repository.FraudHotspot{}, nil
}

func (m *MockFraudAnalyticsRepository) GetPatternAnalysis(ctx context.Context) ([]*repository.PatternSummary, error) {
	return []*repository.PatternSummary{}, nil
}

// === Entity Tests ===

func TestAlertCreation(t *testing.T) {
	alert := entity.NewFraudAlert(
		"call-001",
		"CLI_MASKING",
		"+2348012345678",
		"+2348098765432",
		"192.168.1.1",
		"gw-001",
		0.85,
		"sliding_window",
		[]string{"pattern-1"},
	)

	assert.NotEmpty(t, alert.ID())
	assert.Equal(t, "CLI_MASKING", alert.EventType())
	assert.Equal(t, entity.AlertStatusPending, alert.Status())
	assert.True(t, alert.IsPending())
	assert.False(t, alert.IsResolved())
}

func TestAlertSeverityCalculation(t *testing.T) {
	testCases := []struct {
		confidence float64
		expected   entity.Severity
	}{
		{0.95, entity.SeverityCritical},
		{0.80, entity.SeverityHigh},
		{0.60, entity.SeverityMedium},
		{0.30, entity.SeverityLow},
	}

	for _, tc := range testCases {
		alert := entity.NewFraudAlert(
			"call-001", "TEST", "+2348012345678", "+2348098765432",
			"192.168.1.1", "gw-001", tc.confidence, "test", nil,
		)
		assert.Equal(t, tc.expected, alert.Severity())
	}
}

func TestAlertWorkflow(t *testing.T) {
	alert := entity.NewFraudAlert(
		"call-001", "CLI_MASKING", "+2348012345678", "+2348098765432",
		"192.168.1.1", "gw-001", 0.85, "sliding_window", nil,
	)

	// Acknowledge
	err := alert.Acknowledge("analyst-1")
	require.NoError(t, err)
	assert.Equal(t, entity.AlertStatusAcknowledged, alert.Status())

	// Start investigation
	err = alert.StartInvestigation()
	require.NoError(t, err)
	assert.Equal(t, entity.AlertStatusInvestigating, alert.Status())

	// Resolve
	err = alert.Resolve("analyst-1", entity.ResolutionConfirmedFraud, "Verified attack")
	require.NoError(t, err)
	assert.True(t, alert.IsResolved())
}

func TestAlertAutoEscalation(t *testing.T) {
	// High confidence critical alert should auto-escalate
	alert := entity.NewFraudAlert(
		"call-001", "CLI_MASKING", "+2348012345678", "+2348098765432",
		"192.168.1.1", "gw-001", 0.95, "sliding_window", nil,
	)

	assert.True(t, alert.ShouldAutoEscalate())

	// Lower confidence should not auto-escalate
	alert2 := entity.NewFraudAlert(
		"call-002", "CLI_MASKING", "+2348012345678", "+2348098765432",
		"192.168.1.1", "gw-001", 0.80, "sliding_window", nil,
	)

	assert.False(t, alert2.ShouldAutoEscalate())
}

// === Blacklist Tests ===

func TestBlacklistCreation(t *testing.T) {
	entry := entity.NewBlacklistEntry(
		"msisdn",
		"+2348012345678",
		"Fraud detected",
		"manual",
		"admin",
		nil,
	)

	assert.NotEmpty(t, entry.ID)
	assert.Equal(t, "msisdn", entry.EntryType)
	assert.Equal(t, "+2348012345678", entry.Value)
	assert.False(t, entry.IsExpired())
}

func TestBlacklistExpiration(t *testing.T) {
	expiry := time.Now().Add(-1 * time.Hour)
	entry := entity.NewBlacklistEntry(
		"msisdn",
		"+2348012345678",
		"Temporary block",
		"auto",
		"system",
		&expiry,
	)

	assert.True(t, entry.IsExpired())
}

// === Service Tests ===

func TestFraudServiceAcknowledge(t *testing.T) {
	alertRepo := NewMockAlertRepository()
	blacklistRepo := NewMockBlacklistRepository()
	analyticsRepo := &MockFraudAnalyticsRepository{}
	svc := service.NewFraudService(alertRepo, blacklistRepo, analyticsRepo)

	// Create an alert manually
	alert := entity.NewFraudAlert(
		"call-001", "CLI_MASKING", "+2348012345678", "+2348098765432",
		"192.168.1.1", "gw-001", 0.85, "sliding_window", nil,
	)
	alertRepo.Save(context.Background(), alert)

	// Acknowledge
	result, err := svc.AcknowledgeAlert(context.Background(), alert.ID(), "analyst-1")
	require.NoError(t, err)
	assert.Equal(t, entity.AlertStatusAcknowledged, result.Status())
}

func TestFraudServiceGetDashboard(t *testing.T) {
	alertRepo := NewMockAlertRepository()
	blacklistRepo := NewMockBlacklistRepository()
	analyticsRepo := &MockFraudAnalyticsRepository{}
	svc := service.NewFraudService(alertRepo, blacklistRepo, analyticsRepo)

	summary, err := svc.GetDashboardSummary(context.Background())
	require.NoError(t, err)
	assert.Equal(t, int64(100), summary.TotalAlerts24h)
	assert.Equal(t, int64(5), summary.CriticalAlerts)
}

func TestFraudServiceBlacklist(t *testing.T) {
	alertRepo := NewMockAlertRepository()
	blacklistRepo := NewMockBlacklistRepository()
	analyticsRepo := &MockFraudAnalyticsRepository{}
	svc := service.NewFraudService(alertRepo, blacklistRepo, analyticsRepo)

	// Add to blacklist
	err := svc.AddToBlacklist(context.Background(), "msisdn", "+2348012345678", "Fraud", "admin")
	require.NoError(t, err)

	// Verify blacklisted
	isBlacklisted, err := svc.IsBlacklisted(context.Background(), "+2348012345678")
	require.NoError(t, err)
	assert.True(t, isBlacklisted)

	// Adding duplicate should fail
	err = svc.AddToBlacklist(context.Background(), "msisdn", "+2348012345678", "Duplicate", "admin")
	assert.Error(t, err)
}
