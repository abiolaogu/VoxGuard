// Package entity contains domain entities for the Compliance bounded context
package entity

import (
	"errors"
	"time"

	"github.com/google/uuid"
)

// Compliance domain errors
var (
	ErrReportNotFound    = errors.New("compliance report not found")
	ErrDisputeNotFound   = errors.New("dispute not found")
	ErrInvalidReportType = errors.New("invalid report type")
)

// ReportType represents the type of NCC compliance report
type ReportType string

const (
	ReportTypeDaily    ReportType = "daily"
	ReportTypeWeekly   ReportType = "weekly"
	ReportTypeMonthly  ReportType = "monthly"
	ReportTypeIncident ReportType = "incident"
	ReportTypeAudit    ReportType = "audit"
)

// ReportStatus represents the status of a report
type ReportStatus string

const (
	ReportStatusDraft     ReportStatus = "draft"
	ReportStatusPending   ReportStatus = "pending"
	ReportStatusSubmitted ReportStatus = "submitted"
	ReportStatusAccepted  ReportStatus = "accepted"
	ReportStatusRejected  ReportStatus = "rejected"
)

// NCCReport represents a compliance report for NCC
type NCCReport struct {
	id          string
	reportType  ReportType
	periodStart time.Time
	periodEnd   time.Time
	title       string
	summary     string

	// Statistics
	totalCalls      int64
	fraudCalls      int64
	blockedCalls    int64
	alertsGenerated int64
	alertsResolved  int64

	// Status
	status       ReportStatus
	submittedAt  *time.Time
	submittedBy  *string
	nccReference *string

	// Audit
	generatedBy string
	approvedBy  *string
	approvedAt  *time.Time
	createdAt   time.Time
	updatedAt   time.Time
}

// NewNCCReport creates a new NCC compliance report
func NewNCCReport(reportType ReportType, periodStart, periodEnd time.Time, generatedBy string) *NCCReport {
	now := time.Now()
	return &NCCReport{
		id:          uuid.New().String(),
		reportType:  reportType,
		periodStart: periodStart,
		periodEnd:   periodEnd,
		status:      ReportStatusDraft,
		generatedBy: generatedBy,
		createdAt:   now,
		updatedAt:   now,
	}
}

// === Getters ===

func (r *NCCReport) ID() string             { return r.id }
func (r *NCCReport) ReportType() ReportType { return r.reportType }
func (r *NCCReport) Status() ReportStatus   { return r.status }
func (r *NCCReport) PeriodStart() time.Time { return r.periodStart }
func (r *NCCReport) PeriodEnd() time.Time   { return r.periodEnd }
func (r *NCCReport) TotalCalls() int64      { return r.totalCalls }
func (r *NCCReport) FraudCalls() int64      { return r.fraudCalls }
func (r *NCCReport) BlockedCalls() int64    { return r.blockedCalls }

// FraudRate calculates the fraud rate
func (r *NCCReport) FraudRate() float64 {
	if r.totalCalls == 0 {
		return 0
	}
	return float64(r.fraudCalls) / float64(r.totalCalls) * 100
}

// === Behavior ===

// SetStatistics populates report statistics
func (r *NCCReport) SetStatistics(totalCalls, fraudCalls, blockedCalls, alertsGenerated, alertsResolved int64) {
	r.totalCalls = totalCalls
	r.fraudCalls = fraudCalls
	r.blockedCalls = blockedCalls
	r.alertsGenerated = alertsGenerated
	r.alertsResolved = alertsResolved
	r.updatedAt = time.Now()
}

// SetContent sets report title and summary
func (r *NCCReport) SetContent(title, summary string) {
	r.title = title
	r.summary = summary
	r.updatedAt = time.Now()
}

// Approve approves the report for submission
func (r *NCCReport) Approve(approverID string) error {
	if r.status != ReportStatusDraft {
		return errors.New("only draft reports can be approved")
	}
	now := time.Now()
	r.status = ReportStatusPending
	r.approvedBy = &approverID
	r.approvedAt = &now
	r.updatedAt = now
	return nil
}

// Submit marks the report as submitted to NCC
func (r *NCCReport) Submit(submitterID, nccReference string) error {
	if r.status != ReportStatusPending {
		return errors.New("only pending reports can be submitted")
	}
	now := time.Now()
	r.status = ReportStatusSubmitted
	r.submittedBy = &submitterID
	r.submittedAt = &now
	r.nccReference = &nccReference
	r.updatedAt = now
	return nil
}

// MarkAccepted marks the report as accepted by NCC
func (r *NCCReport) MarkAccepted() {
	r.status = ReportStatusAccepted
	r.updatedAt = time.Now()
}

// MarkRejected marks the report as rejected by NCC
func (r *NCCReport) MarkRejected() {
	r.status = ReportStatusRejected
	r.updatedAt = time.Now()
}

// SettlementDispute represents a billing dispute based on fraud claims
type SettlementDispute struct {
	id          string
	operatorA   string // Disputing party
	operatorB   string // Other party
	disputeType string // "fraud_charge", "incorrect_routing", "missing_cdr"
	amount      float64
	currency    string
	description string
	status      string // "open", "investigating", "resolved", "escalated"
	evidence    []string
	resolution  *string
	resolvedAt  *time.Time
	createdAt   time.Time
	updatedAt   time.Time
}

// NewSettlementDispute creates a new settlement dispute
func NewSettlementDispute(operatorA, operatorB, disputeType string, amount float64, description string) *SettlementDispute {
	now := time.Now()
	return &SettlementDispute{
		id:          uuid.New().String(),
		operatorA:   operatorA,
		operatorB:   operatorB,
		disputeType: disputeType,
		amount:      amount,
		currency:    "NGN",
		description: description,
		status:      "open",
		evidence:    []string{},
		createdAt:   now,
		updatedAt:   now,
	}
}

func (d *SettlementDispute) ID() string      { return d.id }
func (d *SettlementDispute) Status() string  { return d.status }
func (d *SettlementDispute) Amount() float64 { return d.amount }

// AddEvidence adds evidence to the dispute
func (d *SettlementDispute) AddEvidence(evidenceID string) {
	d.evidence = append(d.evidence, evidenceID)
	d.updatedAt = time.Now()
}

// Resolve resolves the dispute
func (d *SettlementDispute) Resolve(resolution string) {
	now := time.Now()
	d.status = "resolved"
	d.resolution = &resolution
	d.resolvedAt = &now
	d.updatedAt = now
}

// Escalate escalates the dispute
func (d *SettlementDispute) Escalate() {
	d.status = "escalated"
	d.updatedAt = time.Now()
}
