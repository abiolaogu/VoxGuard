// Package entity contains domain entities for the Fraud bounded context
package entity

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

// Domain errors
var (
	ErrAlertAlreadyAcknowledged = errors.New("alert is already acknowledged")
	ErrAlertAlreadyResolved     = errors.New("alert is already resolved")
	ErrAlertNotAcknowledged     = errors.New("alert must be acknowledged before resolution")
)

// AlertStatus represents the status of a fraud alert
type AlertStatus string

const (
	AlertStatusPending       AlertStatus = "pending"
	AlertStatusAcknowledged  AlertStatus = "acknowledged"
	AlertStatusInvestigating AlertStatus = "investigating"
	AlertStatusResolved      AlertStatus = "resolved"
	AlertStatusReportedNCC   AlertStatus = "reported_ncc"
)

// Severity represents alert severity level
type Severity int

const (
	SeverityLow      Severity = 1
	SeverityMedium   Severity = 2
	SeverityHigh     Severity = 3
	SeverityCritical Severity = 4
)

// ResolutionType represents how an alert was resolved
type ResolutionType string

const (
	ResolutionConfirmedFraud ResolutionType = "confirmed_fraud"
	ResolutionFalsePositive  ResolutionType = "false_positive"
	ResolutionEscalated      ResolutionType = "escalated"
	ResolutionWhitelisted    ResolutionType = "whitelisted"
)

// FraudAlert is the aggregate root for fraud detection events
type FraudAlert struct {
	id        string
	callID    string
	eventType string // e.g., "CLI_MASKING", "SIMBOX", "WANGIRI"
	severity  Severity

	// Call details
	aNumber   string
	bNumber   string
	sourceIP  string
	gatewayID string

	// Detection details
	confidence      float64
	detectionMethod string
	matchedPatterns []string

	// Workflow state
	status          AlertStatus
	acknowledgedBy  *string
	acknowledgedAt  *time.Time
	resolvedBy      *string
	resolvedAt      *time.Time
	resolution      *ResolutionType
	resolutionNotes *string

	// NCC reporting
	nccReported   bool
	nccReportID   *string
	nccReportedAt *time.Time

	// Timestamps
	detectedAt time.Time
	updatedAt  time.Time
}

// NewFraudAlert creates a new fraud alert
func NewFraudAlert(
	callID, eventType, aNumber, bNumber, sourceIP, gatewayID string,
	confidence float64,
	detectionMethod string,
	matchedPatterns []string,
) *FraudAlert {
	id := uuid.New().String()
	now := time.Now()

	// Calculate severity based on confidence
	var severity Severity
	switch {
	case confidence >= 0.9:
		severity = SeverityCritical
	case confidence >= 0.75:
		severity = SeverityHigh
	case confidence >= 0.5:
		severity = SeverityMedium
	default:
		severity = SeverityLow
	}

	return &FraudAlert{
		id:              id,
		callID:          callID,
		eventType:       eventType,
		severity:        severity,
		aNumber:         aNumber,
		bNumber:         bNumber,
		sourceIP:        sourceIP,
		gatewayID:       gatewayID,
		confidence:      confidence,
		detectionMethod: detectionMethod,
		matchedPatterns: matchedPatterns,
		status:          AlertStatusPending,
		nccReported:     false,
		detectedAt:      now,
		updatedAt:       now,
	}
}

// === Getters ===

func (a *FraudAlert) ID() string              { return a.id }
func (a *FraudAlert) CallID() string          { return a.callID }
func (a *FraudAlert) EventType() string       { return a.eventType }
func (a *FraudAlert) Severity() Severity      { return a.severity }
func (a *FraudAlert) ANumber() string         { return a.aNumber }
func (a *FraudAlert) BNumber() string         { return a.bNumber }
func (a *FraudAlert) SourceIP() string        { return a.sourceIP }
func (a *FraudAlert) GatewayID() string       { return a.gatewayID }
func (a *FraudAlert) Confidence() float64     { return a.confidence }
func (a *FraudAlert) Status() AlertStatus     { return a.status }
func (a *FraudAlert) DetectedAt() time.Time   { return a.detectedAt }
func (a *FraudAlert) AcknowledgedBy() *string { return a.acknowledgedBy }
func (a *FraudAlert) ResolvedBy() *string     { return a.resolvedBy }
func (a *FraudAlert) NCCReported() bool       { return a.nccReported }
func (a *FraudAlert) NCCReportID() *string    { return a.nccReportID }

func (a *FraudAlert) IsPending() bool {
	return a.status == AlertStatusPending
}

func (a *FraudAlert) IsResolved() bool {
	return a.status == AlertStatusResolved
}

// === Behavior ===

// Acknowledge marks the alert as acknowledged by a user
func (a *FraudAlert) Acknowledge(userID string) error {
	if a.status != AlertStatusPending {
		return ErrAlertAlreadyAcknowledged
	}

	now := time.Now()
	a.status = AlertStatusAcknowledged
	a.acknowledgedBy = &userID
	a.acknowledgedAt = &now
	a.updatedAt = now
	return nil
}

// StartInvestigation moves the alert to investigating status
func (a *FraudAlert) StartInvestigation() error {
	if a.status != AlertStatusAcknowledged {
		return ErrAlertNotAcknowledged
	}

	a.status = AlertStatusInvestigating
	a.updatedAt = time.Now()
	return nil
}

// Resolve marks the alert as resolved
func (a *FraudAlert) Resolve(userID string, resolution ResolutionType, notes string) error {
	if a.status == AlertStatusResolved {
		return ErrAlertAlreadyResolved
	}

	now := time.Now()
	a.status = AlertStatusResolved
	a.resolvedBy = &userID
	a.resolvedAt = &now
	a.resolution = &resolution
	if notes != "" {
		a.resolutionNotes = &notes
	}
	a.updatedAt = now
	return nil
}

// ReportToNCC marks the alert as reported to NCC
func (a *FraudAlert) ReportToNCC(reportID string) {
	now := time.Now()
	a.nccReported = true
	a.nccReportID = &reportID
	a.nccReportedAt = &now
	a.status = AlertStatusReportedNCC
	a.updatedAt = now
}

// ShouldAutoEscalate determines if the alert should be auto-escalated to NCC
func (a *FraudAlert) ShouldAutoEscalate() bool {
	return a.severity == SeverityCritical && a.confidence >= 0.95
}

// Blacklist represents a blacklisted entity (number or IP)
type Blacklist struct {
	ID        string
	EntryType string // "msisdn", "ip", "range"
	Value     string
	Reason    string
	Source    string // "manual", "auto", "ncc"
	AddedBy   string
	ExpiresAt *time.Time
	CreatedAt time.Time
	UpdatedAt time.Time
}

// NewBlacklistEntry creates a new blacklist entry
func NewBlacklistEntry(entryType, value, reason, source, addedBy string, expiresAt *time.Time) *Blacklist {
	now := time.Now()
	return &Blacklist{
		ID:        uuid.New().String(),
		EntryType: entryType,
		Value:     value,
		Reason:    reason,
		Source:    source,
		AddedBy:   addedBy,
		ExpiresAt: expiresAt,
		CreatedAt: now,
		UpdatedAt: now,
	}
}

// IsExpired checks if the blacklist entry has expired
func (b *Blacklist) IsExpired() bool {
	if b.ExpiresAt == nil {
		return false
	}
	return time.Now().After(*b.ExpiresAt)
}
