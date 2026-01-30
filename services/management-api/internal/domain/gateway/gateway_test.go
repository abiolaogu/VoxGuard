package gateway_test

import (
	"context"
	"testing"

	"github.com/billyronks/acm-management-api/internal/domain/gateway/entity"
	"github.com/billyronks/acm-management-api/internal/domain/gateway/repository"
	"github.com/billyronks/acm-management-api/internal/domain/gateway/service"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// MockGatewayRepository implements GatewayRepository for testing
type MockGatewayRepository struct {
	gateways map[string]*entity.Gateway
	ips      map[string]string // ip -> gateway_id
}

func NewMockGatewayRepository() *MockGatewayRepository {
	return &MockGatewayRepository{
		gateways: make(map[string]*entity.Gateway),
		ips:      make(map[string]string),
	}
}

func (m *MockGatewayRepository) Save(ctx context.Context, gateway *entity.Gateway) error {
	m.gateways[gateway.ID()] = gateway
	m.ips[gateway.IPAddress().String()] = gateway.ID()
	return nil
}

func (m *MockGatewayRepository) FindByID(ctx context.Context, id string) (*entity.Gateway, error) {
	return m.gateways[id], nil
}

func (m *MockGatewayRepository) FindByIP(ctx context.Context, ip string) (*entity.Gateway, error) {
	if id, ok := m.ips[ip]; ok {
		return m.gateways[id], nil
	}
	return nil, nil
}

func (m *MockGatewayRepository) FindAll(ctx context.Context, filter repository.GatewayFilter, page repository.Pagination) ([]*entity.Gateway, int, error) {
	result := make([]*entity.Gateway, 0, len(m.gateways))
	for _, gw := range m.gateways {
		result = append(result, gw)
	}
	return result, len(result), nil
}

func (m *MockGatewayRepository) FindActive(ctx context.Context) ([]*entity.Gateway, error) {
	result := []*entity.Gateway{}
	for _, gw := range m.gateways {
		if gw.IsActive() && !gw.IsBlacklisted() {
			result = append(result, gw)
		}
	}
	return result, nil
}

func (m *MockGatewayRepository) FindBlacklisted(ctx context.Context) ([]*entity.Gateway, error) {
	result := []*entity.Gateway{}
	for _, gw := range m.gateways {
		if gw.IsBlacklisted() {
			result = append(result, gw)
		}
	}
	return result, nil
}

func (m *MockGatewayRepository) Delete(ctx context.Context, id string) error {
	if gw, ok := m.gateways[id]; ok {
		delete(m.ips, gw.IPAddress().String())
		delete(m.gateways, id)
	}
	return nil
}

func (m *MockGatewayRepository) Exists(ctx context.Context, id string) (bool, error) {
	_, ok := m.gateways[id]
	return ok, nil
}

func (m *MockGatewayRepository) IPExists(ctx context.Context, ip string) (bool, error) {
	_, ok := m.ips[ip]
	return ok, nil
}

// MockGatewayStatsRepository implements GatewayStatsRepository for testing
type MockGatewayStatsRepository struct{}

func (m *MockGatewayStatsRepository) GetStats(ctx context.Context, gatewayID string, hours int) (*repository.GatewayStats, error) {
	return &repository.GatewayStats{
		GatewayID:  gatewayID,
		TotalCalls: 1000,
		FraudCalls: 50,
		FraudRate:  5.0,
	}, nil
}

func (m *MockGatewayStatsRepository) GetTopGateways(ctx context.Context, limit int) ([]*repository.GatewayStats, error) {
	return []*repository.GatewayStats{}, nil
}

func (m *MockGatewayStatsRepository) GetFraudRating(ctx context.Context) ([]*repository.GatewayFraudRating, error) {
	return []*repository.GatewayFraudRating{}, nil
}

// === Entity Tests ===

func TestGatewayCreation(t *testing.T) {
	gw, err := entity.NewGateway(
		"gw-001",
		"Lagos Gateway 1",
		"192.168.1.1",
		"MTN Nigeria",
		entity.GatewayTypeLocal,
	)

	require.NoError(t, err)
	assert.Equal(t, "gw-001", gw.ID())
	assert.Equal(t, "Lagos Gateway 1", gw.Name())
	assert.Equal(t, "MTN Nigeria", gw.CarrierName())
	assert.True(t, gw.IsActive())
	assert.False(t, gw.IsBlacklisted())
}

func TestGatewayInvalidIP(t *testing.T) {
	_, err := entity.NewGateway(
		"gw-001",
		"Test",
		"not-an-ip",
		"MTN",
		entity.GatewayTypeLocal,
	)

	assert.Error(t, err)
	assert.Equal(t, entity.ErrInvalidIPAddress, err)
}

func TestGatewayThresholdUpdate(t *testing.T) {
	gw, _ := entity.NewGateway("gw-001", "Test", "192.168.1.1", "MTN", entity.GatewayTypeLocal)

	threshold := 0.75
	cpm := 100
	acd := 15.0
	gw.UpdateThresholds(&threshold, &cpm, &acd)

	assert.Equal(t, 0.75, gw.FraudThreshold())
	assert.Equal(t, 100, gw.CPMLimit())
	assert.Equal(t, 15.0, gw.ACDThreshold())
}

func TestGatewayActivation(t *testing.T) {
	gw, _ := entity.NewGateway("gw-001", "Test", "192.168.1.1", "MTN", entity.GatewayTypeLocal)

	// Already active, should fail
	err := gw.Activate()
	assert.Error(t, err)

	// Deactivate and reactivate
	err = gw.Deactivate()
	require.NoError(t, err)
	assert.False(t, gw.IsActive())

	err = gw.Activate()
	require.NoError(t, err)
	assert.True(t, gw.IsActive())
}

func TestGatewayBlacklisting(t *testing.T) {
	gw, _ := entity.NewGateway("gw-001", "Test", "192.168.1.1", "MTN", entity.GatewayTypeLocal)

	gw.Blacklist("Fraud detected", nil)

	assert.True(t, gw.IsBlacklisted())
	assert.False(t, gw.IsActive())
	assert.Equal(t, "Fraud detected", gw.BlacklistReason())

	// Cannot activate while blacklisted
	err := gw.Activate()
	assert.Error(t, err)
}

// === Service Tests ===

func TestGatewayServiceCreate(t *testing.T) {
	repo := NewMockGatewayRepository()
	statsRepo := &MockGatewayStatsRepository{}
	svc := service.NewGatewayService(repo, statsRepo)

	gw, err := svc.CreateGateway(context.Background(), service.CreateGatewayRequest{
		Name:        "Lagos Gateway",
		IPAddress:   "10.0.0.1",
		CarrierName: "MTN Nigeria",
		GatewayType: "local",
	})

	require.NoError(t, err)
	assert.Equal(t, "Lagos Gateway", gw.Name())
	assert.True(t, gw.IsActive())
}

func TestGatewayServiceDuplicateIP(t *testing.T) {
	repo := NewMockGatewayRepository()
	statsRepo := &MockGatewayStatsRepository{}
	svc := service.NewGatewayService(repo, statsRepo)

	// Create first gateway
	_, err := svc.CreateGateway(context.Background(), service.CreateGatewayRequest{
		Name:        "Gateway 1",
		IPAddress:   "10.0.0.1",
		CarrierName: "MTN",
		GatewayType: "local",
	})
	require.NoError(t, err)

	// Try to create duplicate IP
	_, err = svc.CreateGateway(context.Background(), service.CreateGatewayRequest{
		Name:        "Gateway 2",
		IPAddress:   "10.0.0.1",
		CarrierName: "GLO",
		GatewayType: "local",
	})
	assert.Error(t, err)
	assert.Equal(t, service.ErrGatewayAlreadyExists, err)
}

func TestGatewayServiceEnableDisable(t *testing.T) {
	repo := NewMockGatewayRepository()
	statsRepo := &MockGatewayStatsRepository{}
	svc := service.NewGatewayService(repo, statsRepo)

	// Create gateway
	gw, _ := svc.CreateGateway(context.Background(), service.CreateGatewayRequest{
		Name:        "Gateway",
		IPAddress:   "10.0.0.1",
		CarrierName: "MTN",
		GatewayType: "local",
	})

	// Disable
	err := svc.DisableGateway(context.Background(), gw.ID())
	require.NoError(t, err)

	// Verify disabled
	updated, _ := svc.GetGateway(context.Background(), gw.ID())
	assert.False(t, updated.IsActive())

	// Enable
	err = svc.EnableGateway(context.Background(), gw.ID())
	require.NoError(t, err)

	// Verify enabled
	updated, _ = svc.GetGateway(context.Background(), gw.ID())
	assert.True(t, updated.IsActive())
}

func TestGatewayServiceGetStats(t *testing.T) {
	repo := NewMockGatewayRepository()
	statsRepo := &MockGatewayStatsRepository{}
	svc := service.NewGatewayService(repo, statsRepo)

	// Create gateway
	gw, _ := svc.CreateGateway(context.Background(), service.CreateGatewayRequest{
		Name:        "Gateway",
		IPAddress:   "10.0.0.1",
		CarrierName: "MTN",
		GatewayType: "local",
	})

	// Get stats
	stats, err := svc.GetGatewayStats(context.Background(), gw.ID(), 24)
	require.NoError(t, err)
	assert.Equal(t, int64(1000), stats.TotalCalls)
	assert.Equal(t, int64(50), stats.FraudCalls)
}

func TestGatewayServiceNotFound(t *testing.T) {
	repo := NewMockGatewayRepository()
	statsRepo := &MockGatewayStatsRepository{}
	svc := service.NewGatewayService(repo, statsRepo)

	_, err := svc.GetGateway(context.Background(), "nonexistent")
	assert.Error(t, err)
	assert.Equal(t, service.ErrGatewayNotFound, err)
}
