// Package repository defines repository interfaces for the Fraud bounded context
package repository

import (
	"context"
	"time"

	"github.com/billyronks/acm-management-api/internal/domain/fraud/entity"
)

// AlertFilter contains filter options for alert queries
type AlertFilter struct {
	EventType      string
	Severity       *entity.Severity
	Status         *entity.AlertStatus
	GatewayID      string
	SourceIP       string
	StartTime      *time.Time
	EndTime        *time.Time
	IsAcknowledged *bool
	IsResolved     *bool
}

// AlertRepository defines the interface for fraud alert persistence
type AlertRepository interface {
	// Save persists an alert (insert or update)
	Save(ctx context.Context, alert *entity.FraudAlert) error

	// FindByID retrieves an alert by ID
	FindByID(ctx context.Context, id string) (*entity.FraudAlert, error)

	// FindAll retrieves alerts with filters
	FindAll(ctx context.Context, filter AlertFilter, page, pageSize int) ([]*entity.FraudAlert, int, error)

	// FindPending retrieves all pending alerts
	FindPending(ctx context.Context) ([]*entity.FraudAlert, error)

	// FindBySeverity retrieves alerts by severity
	FindBySeverity(ctx context.Context, severity entity.Severity) ([]*entity.FraudAlert, error)

	// CountPending returns the count of pending alerts
	CountPending(ctx context.Context) (int64, error)

	// CountBySeverity returns counts grouped by severity
	CountBySeverity(ctx context.Context) (map[entity.Severity]int64, error)
}

// BlacklistRepository defines the interface for blacklist persistence
type BlacklistRepository interface {
	// Save persists a blacklist entry
	Save(ctx context.Context, entry *entity.Blacklist) error

	// FindByValue retrieves a blacklist entry by value
	FindByValue(ctx context.Context, value string) (*entity.Blacklist, error)

	// FindAll retrieves all blacklist entries
	FindAll(ctx context.Context, entryType string, page, pageSize int) ([]*entity.Blacklist, int, error)

	// Delete removes a blacklist entry
	Delete(ctx context.Context, id string) error

	// IsBlacklisted checks if a value is blacklisted
	IsBlacklisted(ctx context.Context, value string) (bool, error)

	// CleanupExpired removes expired entries
	CleanupExpired(ctx context.Context) (int, error)
}

// FraudAnalyticsRepository defines the interface for fraud analytics (read model)
type FraudAnalyticsRepository interface {
	// GetDashboardSummary returns summary stats for dashboard
	GetDashboardSummary(ctx context.Context) (*DashboardSummary, error)

	// GetFraudTrends returns fraud trends over time
	GetFraudTrends(ctx context.Context, days int) ([]*FraudTrend, error)

	// GetHotspots returns geographic fraud hotspots
	GetHotspots(ctx context.Context, hours int) ([]*FraudHotspot, error)

	// GetPatternAnalysis returns detected patterns
	GetPatternAnalysis(ctx context.Context) ([]*PatternSummary, error)
}

// DashboardSummary represents dashboard statistics
type DashboardSummary struct {
	TotalAlerts24h    int64
	CriticalAlerts    int64
	PendingAlerts     int64
	ResolvedAlerts24h int64
	FalsePositiveRate float64
	AvgResponseTime   float64 // minutes
	TotalBlacklisted  int64
	NCCReportsToday   int64
}

// FraudTrend represents fraud trend data point
type FraudTrend struct {
	Date       time.Time
	AlertCount int64
	FraudType  string
	ChangeRate float64
}

// FraudHotspot represents a geographic fraud hotspot
type FraudHotspot struct {
	Region      string
	AlertCount  int64
	RiskLevel   string
	TopPatterns []string
}

// PatternSummary represents a detected fraud pattern
type PatternSummary struct {
	PatternID   string
	Name        string
	Occurrences int64
	Confidence  float64
	Examples    []string
}
