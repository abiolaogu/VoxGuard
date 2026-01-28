// Package service implements application services for the Fraud bounded context
package service

import (
	"context"
	"errors"
	"fmt"

	"github.com/billyronks/acm-management-api/internal/domain/fraud/entity"
	"github.com/billyronks/acm-management-api/internal/domain/fraud/repository"
)

// Common errors
var (
	ErrAlertNotFound     = errors.New("alert not found")
	ErrBlacklistNotFound = errors.New("blacklist entry not found")
)

// FraudService handles fraud detection use cases
type FraudService struct {
	alertRepo     repository.AlertRepository
	blacklistRepo repository.BlacklistRepository
	analyticsRepo repository.FraudAnalyticsRepository
}

// NewFraudService creates a new fraud service
func NewFraudService(
	alertRepo repository.AlertRepository,
	blacklistRepo repository.BlacklistRepository,
	analyticsRepo repository.FraudAnalyticsRepository,
) *FraudService {
	return &FraudService{
		alertRepo:     alertRepo,
		blacklistRepo: blacklistRepo,
		analyticsRepo: analyticsRepo,
	}
}

// GetAlert retrieves a fraud alert by ID
func (s *FraudService) GetAlert(ctx context.Context, id string) (*entity.FraudAlert, error) {
	alert, err := s.alertRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to find alert: %w", err)
	}
	if alert == nil {
		return nil, ErrAlertNotFound
	}
	return alert, nil
}

// ListAlerts retrieves alerts with filters
func (s *FraudService) ListAlerts(ctx context.Context, filter repository.AlertFilter, page, pageSize int) ([]*entity.FraudAlert, int, error) {
	return s.alertRepo.FindAll(ctx, filter, page, pageSize)
}

// AcknowledgeAlert acknowledges an alert
func (s *FraudService) AcknowledgeAlert(ctx context.Context, alertID, userID string) error {
	alert, err := s.GetAlert(ctx, alertID)
	if err != nil {
		return err
	}

	if err := alert.Acknowledge(userID); err != nil {
		return err
	}

	return s.alertRepo.Save(ctx, alert)
}

// ResolveAlert resolves an alert
func (s *FraudService) ResolveAlert(ctx context.Context, alertID, userID string, resolution entity.ResolutionType, notes string) error {
	alert, err := s.GetAlert(ctx, alertID)
	if err != nil {
		return err
	}

	if err := alert.Resolve(userID, resolution, notes); err != nil {
		return err
	}

	return s.alertRepo.Save(ctx, alert)
}

// ReportToNCC reports an alert to NCC
func (s *FraudService) ReportToNCC(ctx context.Context, alertID, reportID string) error {
	alert, err := s.GetAlert(ctx, alertID)
	if err != nil {
		return err
	}

	alert.ReportToNCC(reportID)
	return s.alertRepo.Save(ctx, alert)
}

// GetDashboardSummary retrieves dashboard statistics
func (s *FraudService) GetDashboardSummary(ctx context.Context) (*repository.DashboardSummary, error) {
	return s.analyticsRepo.GetDashboardSummary(ctx)
}

// AddToBlacklist adds an entry to the blacklist
func (s *FraudService) AddToBlacklist(ctx context.Context, entryType, value, reason, addedBy string) error {
	// Check if already blacklisted
	exists, err := s.blacklistRepo.IsBlacklisted(ctx, value)
	if err != nil {
		return fmt.Errorf("failed to check blacklist: %w", err)
	}
	if exists {
		return errors.New("entry already blacklisted")
	}

	entry := entity.NewBlacklistEntry(entryType, value, reason, "manual", addedBy, nil)
	return s.blacklistRepo.Save(ctx, entry)
}

// RemoveFromBlacklist removes an entry from the blacklist
func (s *FraudService) RemoveFromBlacklist(ctx context.Context, id string) error {
	return s.blacklistRepo.Delete(ctx, id)
}

// ListBlacklist retrieves blacklist entries
func (s *FraudService) ListBlacklist(ctx context.Context, entryType string, page, pageSize int) ([]*entity.Blacklist, int, error) {
	return s.blacklistRepo.FindAll(ctx, entryType, page, pageSize)
}

// IsBlacklisted checks if a value is blacklisted
func (s *FraudService) IsBlacklisted(ctx context.Context, value string) (bool, error) {
	return s.blacklistRepo.IsBlacklisted(ctx, value)
}

// GetPendingAlertCount returns the count of pending alerts
func (s *FraudService) GetPendingAlertCount(ctx context.Context) (int64, error) {
	return s.alertRepo.CountPending(ctx)
}
