// Package service implements application services for the Gateway bounded context
package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/billyronks/acm-management-api/internal/domain/gateway/entity"
	"github.com/billyronks/acm-management-api/internal/domain/gateway/repository"
	"github.com/google/uuid"
)

// Common errors
var (
	ErrGatewayNotFound         = errors.New("gateway not found")
	ErrGatewayAlreadyExists    = errors.New("gateway with this IP already exists")
	ErrCannotDeleteBlacklisted = errors.New("cannot delete blacklisted gateway")
)

// CreateGatewayRequest contains data for creating a new gateway
type CreateGatewayRequest struct {
	Name           string
	IPAddress      string
	CarrierName    string
	GatewayType    string
	FraudThreshold float64
	CPMLimit       int
	ACDThreshold   float64
}

// UpdateGatewayRequest contains data for updating a gateway
type UpdateGatewayRequest struct {
	Name           *string
	CarrierName    *string
	FraudThreshold *float64
	CPMLimit       *int
	ACDThreshold   *float64
}

// GatewayService handles gateway management use cases
type GatewayService struct {
	repo      repository.GatewayRepository
	statsRepo repository.GatewayStatsRepository
}

// NewGatewayService creates a new gateway service
func NewGatewayService(repo repository.GatewayRepository, statsRepo repository.GatewayStatsRepository) *GatewayService {
	return &GatewayService{
		repo:      repo,
		statsRepo: statsRepo,
	}
}

// CreateGateway creates a new gateway
func (s *GatewayService) CreateGateway(ctx context.Context, req CreateGatewayRequest) (*entity.Gateway, error) {
	// Check if IP already exists
	exists, err := s.repo.IPExists(ctx, req.IPAddress)
	if err != nil {
		return nil, fmt.Errorf("failed to check IP existence: %w", err)
	}
	if exists {
		return nil, ErrGatewayAlreadyExists
	}

	// Create gateway entity
	id := uuid.New().String()
	gateway, err := entity.NewGateway(
		id,
		req.Name,
		req.IPAddress,
		req.CarrierName,
		entity.GatewayType(req.GatewayType),
	)
	if err != nil {
		return nil, err
	}

	// Set thresholds if provided
	if req.FraudThreshold > 0 || req.CPMLimit > 0 || req.ACDThreshold > 0 {
		var ft *float64
		var cpm *int
		var acd *float64
		if req.FraudThreshold > 0 {
			ft = &req.FraudThreshold
		}
		if req.CPMLimit > 0 {
			cpm = &req.CPMLimit
		}
		if req.ACDThreshold > 0 {
			acd = &req.ACDThreshold
		}
		gateway.UpdateThresholds(ft, cpm, acd)
	}

	// Persist
	if err := s.repo.Save(ctx, gateway); err != nil {
		return nil, fmt.Errorf("failed to save gateway: %w", err)
	}

	return gateway, nil
}

// GetGateway retrieves a gateway by ID
func (s *GatewayService) GetGateway(ctx context.Context, id string) (*entity.Gateway, error) {
	gateway, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to find gateway: %w", err)
	}
	if gateway == nil {
		return nil, ErrGatewayNotFound
	}
	return gateway, nil
}

// UpdateGateway updates an existing gateway
func (s *GatewayService) UpdateGateway(ctx context.Context, id string, req UpdateGatewayRequest) (*entity.Gateway, error) {
	gateway, err := s.GetGateway(ctx, id)
	if err != nil {
		return nil, err
	}

	// Apply updates using domain methods
	if req.Name != nil {
		gateway.UpdateName(*req.Name)
	}
	if req.CarrierName != nil {
		gateway.UpdateCarrier(*req.CarrierName)
	}
	gateway.UpdateThresholds(req.FraudThreshold, req.CPMLimit, req.ACDThreshold)

	// Persist
	if err := s.repo.Save(ctx, gateway); err != nil {
		return nil, fmt.Errorf("failed to save gateway: %w", err)
	}

	return gateway, nil
}

// DeleteGateway removes a gateway
func (s *GatewayService) DeleteGateway(ctx context.Context, id string) error {
	gateway, err := s.GetGateway(ctx, id)
	if err != nil {
		return err
	}

	if gateway.IsBlacklisted() {
		return ErrCannotDeleteBlacklisted
	}

	return s.repo.Delete(ctx, id)
}

// EnableGateway activates a gateway
func (s *GatewayService) EnableGateway(ctx context.Context, id string) error {
	gateway, err := s.GetGateway(ctx, id)
	if err != nil {
		return err
	}

	if err := gateway.Activate(); err != nil {
		return err
	}

	return s.repo.Save(ctx, gateway)
}

// DisableGateway deactivates a gateway
func (s *GatewayService) DisableGateway(ctx context.Context, id string) error {
	gateway, err := s.GetGateway(ctx, id)
	if err != nil {
		return err
	}

	if err := gateway.Deactivate(); err != nil {
		return err
	}

	return s.repo.Save(ctx, gateway)
}

// BlacklistGateway adds a gateway to the blacklist
func (s *GatewayService) BlacklistGateway(ctx context.Context, id, reason string, expiresAt *time.Time) error {
	gateway, err := s.GetGateway(ctx, id)
	if err != nil {
		return err
	}

	gateway.Blacklist(reason, expiresAt)
	return s.repo.Save(ctx, gateway)
}

// UnblacklistGateway removes a gateway from the blacklist
func (s *GatewayService) UnblacklistGateway(ctx context.Context, id string) error {
	gateway, err := s.GetGateway(ctx, id)
	if err != nil {
		return err
	}

	gateway.Unblacklist()
	return s.repo.Save(ctx, gateway)
}

// ListGateways retrieves gateways with filters
func (s *GatewayService) ListGateways(ctx context.Context, filter repository.GatewayFilter, page repository.Pagination) ([]*entity.Gateway, int, error) {
	return s.repo.FindAll(ctx, filter, page)
}

// GetGatewayStats retrieves statistics for a gateway
func (s *GatewayService) GetGatewayStats(ctx context.Context, id string, hours int) (*repository.GatewayStats, error) {
	// Verify gateway exists
	if _, err := s.GetGateway(ctx, id); err != nil {
		return nil, err
	}

	return s.statsRepo.GetStats(ctx, id, hours)
}
