// Package repository defines the repository interface for Gateway persistence
package repository

import (
	"context"

	"github.com/billyronks/acm-management-api/internal/domain/gateway/entity"
)

// GatewayFilter contains filter options for gateway queries
type GatewayFilter struct {
	CarrierName   string
	GatewayType   string
	IsActive      *bool
	IsBlacklisted *bool
}

// Pagination options
type Pagination struct {
	Page     int
	PageSize int
}

// GatewayRepository defines the interface for gateway persistence
type GatewayRepository interface {
	// Save persists a gateway (insert or update)
	Save(ctx context.Context, gateway *entity.Gateway) error

	// FindByID retrieves a gateway by ID
	FindByID(ctx context.Context, id string) (*entity.Gateway, error)

	// FindByIP retrieves a gateway by IP address
	FindByIP(ctx context.Context, ip string) (*entity.Gateway, error)

	// FindAll retrieves all gateways with optional filters
	FindAll(ctx context.Context, filter GatewayFilter, page Pagination) ([]*entity.Gateway, int, error)

	// FindActive retrieves all active, non-blacklisted gateways
	FindActive(ctx context.Context) ([]*entity.Gateway, error)

	// FindBlacklisted retrieves all blacklisted gateways
	FindBlacklisted(ctx context.Context) ([]*entity.Gateway, error)

	// Delete removes a gateway
	Delete(ctx context.Context, id string) error

	// Exists checks if a gateway with the given ID exists
	Exists(ctx context.Context, id string) (bool, error)

	// IPExists checks if a gateway with the given IP exists
	IPExists(ctx context.Context, ip string) (bool, error)
}

// GatewayStatsRepository defines the interface for gateway statistics (read model)
type GatewayStatsRepository interface {
	// GetStats retrieves statistics for a gateway within a time range
	GetStats(ctx context.Context, gatewayID string, hours int) (*GatewayStats, error)

	// GetTopGateways retrieves top gateways by call volume
	GetTopGateways(ctx context.Context, limit int) ([]*GatewayStats, error)

	// GetFraudRating retrieves fraud rating for all gateways
	GetFraudRating(ctx context.Context) ([]*GatewayFraudRating, error)
}

// GatewayStats represents gateway statistics (read model)
type GatewayStats struct {
	GatewayID     string
	TotalCalls    int64
	FraudCalls    int64
	FraudRate     float64
	AvgConfidence float64
	AvgDuration   float64
	PeakCPS       int
}

// GatewayFraudRating represents fraud rating summary
type GatewayFraudRating struct {
	GatewayID   string
	GatewayName string
	FraudRate   float64
	CallCount   int64
	RiskLevel   string
}
