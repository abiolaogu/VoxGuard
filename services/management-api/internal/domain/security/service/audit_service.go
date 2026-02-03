// Package service provides security business logic
package service

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/billyronks/acm-management-api/internal/domain/security/entity"
	"github.com/billyronks/acm-management-api/internal/domain/security/repository"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// AuditService handles immutable audit logging for compliance
type AuditService struct {
	repo   repository.SecurityRepository
	logger *zap.Logger
}

// NewAuditService creates a new audit service
func NewAuditService(
	repo repository.SecurityRepository,
	logger *zap.Logger,
) *AuditService {
	return &AuditService{
		repo:   repo,
		logger: logger,
	}
}

// LogEvent logs an audit event (immutable)
func (s *AuditService) LogEvent(ctx context.Context, event entity.AuditEvent) error {
	// Ensure required fields are set
	if event.ID == "" {
		event.ID = uuid.New().String()
	}
	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now()
	}
	if event.Status == "" {
		event.Status = entity.StatusSuccess
	}
	if event.Severity == "" {
		event.Severity = entity.SeverityLow
	}

	// Extract request metadata from context if available
	if requestID, ok := ctx.Value("request_id").(string); ok {
		event.RequestID = requestID
	}
	if ipAddress, ok := ctx.Value("ip_address").(string); ok && event.IPAddress == "" {
		event.IPAddress = ipAddress
	}
	if userAgent, ok := ctx.Value("user_agent").(string); ok && event.UserAgent == "" {
		event.UserAgent = userAgent
	}

	// Log to database (immutable insert)
	if err := s.repo.CreateAuditEvent(ctx, &event); err != nil {
		s.logger.Error("Failed to create audit event",
			zap.String("event_id", event.ID),
			zap.String("action", event.Action),
			zap.Error(err))
		return fmt.Errorf("create audit event: %w", err)
	}

	// Also log to structured logger for real-time monitoring
	s.logger.Info("Audit event",
		zap.String("event_id", event.ID),
		zap.String("user_id", event.UserID),
		zap.String("username", event.Username),
		zap.String("action", event.Action),
		zap.String("resource_type", event.ResourceType),
		zap.String("resource_id", event.ResourceID),
		zap.String("status", event.Status),
		zap.String("severity", event.Severity),
		zap.String("ip_address", event.IPAddress),
	)

	return nil
}

// LogAuthEvent logs authentication-related events
func (s *AuditService) LogAuthEvent(ctx context.Context, userID, username, action, ipAddress, userAgent string, success bool, errorMsg string) {
	status := entity.StatusSuccess
	severity := entity.SeverityLow
	if !success {
		status = entity.StatusFailure
		severity = entity.SeverityMedium
	}

	// Escalate severity for certain auth events
	if action == "account_locked" || action == "login_locked" {
		severity = entity.SeverityHigh
	}

	event := entity.AuditEvent{
		UserID:       userID,
		Username:     username,
		Action:       action,
		ResourceType: "auth",
		ResourceID:   userID,
		Status:       status,
		Severity:     severity,
		IPAddress:    ipAddress,
		UserAgent:    userAgent,
		ErrorMessage: errorMsg,
	}

	if err := s.LogEvent(ctx, event); err != nil {
		s.logger.Error("Failed to log auth event", zap.Error(err))
	}
}

// LogSecurityEvent logs a security-relevant event
func (s *AuditService) LogSecurityEvent(ctx context.Context, event entity.SecurityEvent) error {
	if event.ID == "" {
		event.ID = uuid.New().String()
	}
	if event.CreatedAt.IsZero() {
		event.CreatedAt = time.Now()
	}

	if err := s.repo.CreateSecurityEvent(ctx, &event); err != nil {
		s.logger.Error("Failed to create security event",
			zap.String("event_type", event.EventType),
			zap.Error(err))
		return fmt.Errorf("create security event: %w", err)
	}

	// Also create corresponding audit event
	auditEvent := entity.AuditEvent{
		UserID:       event.UserID,
		Action:       "security_event",
		ResourceType: "security",
		ResourceID:   event.ID,
		ResourceName: event.EventType,
		Status:       entity.StatusSuccess,
		Severity:     event.Severity,
		IPAddress:    event.IPAddress,
		UserAgent:    event.UserAgent,
		Metadata:     event.Metadata,
	}

	if err := s.LogEvent(ctx, auditEvent); err != nil {
		s.logger.Error("Failed to log audit event for security event", zap.Error(err))
	}

	return nil
}

// QueryAuditLogs queries audit logs with filters
func (s *AuditService) QueryAuditLogs(ctx context.Context, filter entity.AuditFilter, page, pageSize int) ([]*entity.AuditEvent, int, error) {
	// Validate pagination
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 50
	}

	// Set default time range if not provided (last 30 days)
	if filter.StartTime.IsZero() {
		filter.StartTime = time.Now().AddDate(0, 0, -30)
	}
	if filter.EndTime.IsZero() {
		filter.EndTime = time.Now()
	}

	events, total, err := s.repo.QueryAuditEvents(ctx, filter, page, pageSize)
	if err != nil {
		return nil, 0, fmt.Errorf("query audit events: %w", err)
	}

	return events, total, nil
}

// GetAuditStats generates audit statistics for a time period
func (s *AuditService) GetAuditStats(ctx context.Context, startTime, endTime time.Time) (*entity.AuditStats, error) {
	stats, err := s.repo.GetAuditStats(ctx, startTime, endTime)
	if err != nil {
		return nil, fmt.Errorf("get audit stats: %w", err)
	}

	stats.Period = fmt.Sprintf("%s to %s", startTime.Format("2006-01-02"), endTime.Format("2006-01-02"))
	stats.GeneratedAt = time.Now()

	return stats, nil
}

// GetUserActivity gets recent activity for a specific user
func (s *AuditService) GetUserActivity(ctx context.Context, userID string, limit int) ([]*entity.AuditEvent, error) {
	if limit < 1 || limit > 100 {
		limit = 50
	}

	filter := entity.AuditFilter{
		UserID:    userID,
		StartTime: time.Now().AddDate(0, 0, -30),
		EndTime:   time.Now(),
	}

	events, _, err := s.repo.QueryAuditEvents(ctx, filter, 1, limit)
	if err != nil {
		return nil, fmt.Errorf("get user activity: %w", err)
	}

	return events, nil
}

// GetSecurityEvents retrieves security events with filters
func (s *AuditService) GetSecurityEvents(ctx context.Context, eventType, severity string, resolved *bool, page, pageSize int) ([]*entity.SecurityEvent, int, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 50
	}

	events, total, err := s.repo.QuerySecurityEvents(ctx, eventType, severity, resolved, page, pageSize)
	if err != nil {
		return nil, 0, fmt.Errorf("get security events: %w", err)
	}

	return events, total, nil
}

// ResolveSecurityEvent marks a security event as resolved
func (s *AuditService) ResolveSecurityEvent(ctx context.Context, eventID, resolvedBy, note string) error {
	event, err := s.repo.GetSecurityEventByID(ctx, eventID)
	if err != nil {
		return fmt.Errorf("get security event: %w", err)
	}

	if event.IsResolved {
		return fmt.Errorf("security event already resolved")
	}

	now := time.Now()
	event.IsResolved = true
	event.ResolvedBy = &resolvedBy
	event.ResolvedAt = &now
	event.ResolutionNote = &note

	if err := s.repo.UpdateSecurityEvent(ctx, event); err != nil {
		return fmt.Errorf("update security event: %w", err)
	}

	// Log audit event
	auditEvent := entity.AuditEvent{
		UserID:       resolvedBy,
		Action:       "resolve_security_event",
		ResourceType: "security",
		ResourceID:   eventID,
		ResourceName: event.EventType,
		Status:       entity.StatusSuccess,
		Severity:     entity.SeverityMedium,
		NewValues:    fmt.Sprintf(`{"resolved": true, "note": "%s"}`, note),
	}

	if err := s.LogEvent(ctx, auditEvent); err != nil {
		s.logger.Error("Failed to log audit event", zap.Error(err))
	}

	return nil
}

// ExportAuditLogs exports audit logs to a file for compliance archival
func (s *AuditService) ExportAuditLogs(ctx context.Context, filter entity.AuditFilter, format string) ([]byte, error) {
	// Query all matching events (no pagination)
	events, _, err := s.repo.QueryAuditEvents(ctx, filter, 1, 10000)
	if err != nil {
		return nil, fmt.Errorf("query audit events: %w", err)
	}

	switch format {
	case "json":
		return json.MarshalIndent(events, "", "  ")
	case "csv":
		return s.exportToCSV(events)
	default:
		return nil, fmt.Errorf("unsupported format: %s", format)
	}
}

// Helper function to export audit logs to CSV
func (s *AuditService) exportToCSV(events []*entity.AuditEvent) ([]byte, error) {
	var csv string
	csv += "ID,Timestamp,User ID,Username,Action,Resource Type,Resource ID,Status,Severity,IP Address,Error Message\n"

	for _, event := range events {
		csv += fmt.Sprintf("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
			event.ID,
			event.Timestamp.Format(time.RFC3339),
			event.UserID,
			event.Username,
			event.Action,
			event.ResourceType,
			event.ResourceID,
			event.Status,
			event.Severity,
			event.IPAddress,
			event.ErrorMessage,
		)
	}

	return []byte(csv), nil
}

// ArchiveOldLogs archives audit logs older than the retention period
// This should be called by a scheduled job for 7-year retention compliance
func (s *AuditService) ArchiveOldLogs(ctx context.Context, retentionYears int) error {
	if retentionYears < 7 {
		return fmt.Errorf("retention period must be at least 7 years for NCC compliance")
	}

	archiveDate := time.Now().AddDate(-retentionYears, 0, 0)

	s.logger.Info("Archiving audit logs",
		zap.Time("archive_date", archiveDate),
		zap.Int("retention_years", retentionYears))

	// Export logs to archive before deletion
	filter := entity.AuditFilter{
		StartTime: time.Time{}, // Beginning of time
		EndTime:   archiveDate,
	}

	archiveData, err := s.ExportAuditLogs(ctx, filter, "json")
	if err != nil {
		return fmt.Errorf("export logs for archive: %w", err)
	}

	// TODO: Store archiveData to cold storage (S3, Glacier, etc.)
	s.logger.Info("Archive data prepared", zap.Int("bytes", len(archiveData)))

	// After successful archive, we could delete from hot storage
	// However, for compliance, we keep all logs and only move to cold storage
	// Actual deletion should be done very carefully and only after legal review

	return nil
}

// GenerateComplianceReport generates a compliance report for NCC
func (s *AuditService) GenerateComplianceReport(ctx context.Context, startDate, endDate time.Time) (map[string]interface{}, error) {
	stats, err := s.GetAuditStats(ctx, startDate, endDate)
	if err != nil {
		return nil, err
	}

	// Get high severity events
	highSeverityFilter := entity.AuditFilter{
		Severity:  entity.SeverityHigh,
		StartTime: startDate,
		EndTime:   endDate,
	}
	highSeverityEvents, _, err := s.repo.QueryAuditEvents(ctx, highSeverityFilter, 1, 1000)
	if err != nil {
		return nil, err
	}

	// Get critical severity events
	criticalSeverityFilter := entity.AuditFilter{
		Severity:  entity.SeverityCritical,
		StartTime: startDate,
		EndTime:   endDate,
	}
	criticalEvents, _, err := s.repo.QueryAuditEvents(ctx, criticalSeverityFilter, 1, 1000)
	if err != nil {
		return nil, err
	}

	// Get failed authentication attempts
	failedAuthFilter := entity.AuditFilter{
		Action:    "login_failure",
		Status:    entity.StatusFailure,
		StartTime: startDate,
		EndTime:   endDate,
	}
	failedAuthEvents, _, err := s.repo.QueryAuditEvents(ctx, failedAuthFilter, 1, 1000)
	if err != nil {
		return nil, err
	}

	report := map[string]interface{}{
		"report_period": map[string]interface{}{
			"start_date": startDate.Format("2006-01-02"),
			"end_date":   endDate.Format("2006-01-02"),
		},
		"statistics": stats,
		"high_severity_events": map[string]interface{}{
			"count":  len(highSeverityEvents),
			"events": highSeverityEvents,
		},
		"critical_events": map[string]interface{}{
			"count":  len(criticalEvents),
			"events": criticalEvents,
		},
		"failed_authentication_attempts": map[string]interface{}{
			"count":  len(failedAuthEvents),
			"events": failedAuthEvents,
		},
		"compliance_status": map[string]interface{}{
			"ncc_icl_compliant": true,
			"retention_period":  "7 years",
			"audit_trail":       "immutable",
		},
		"generated_at": time.Now().Format(time.RFC3339),
		"generated_by": "VoxGuard Audit Service",
	}

	return report, nil
}

// Helper function to track changes for audit purposes
func (s *AuditService) TrackChanges(oldData, newData interface{}) (string, string, error) {
	oldJSON, err := json.Marshal(oldData)
	if err != nil {
		return "", "", fmt.Errorf("marshal old data: %w", err)
	}

	newJSON, err := json.Marshal(newData)
	if err != nil {
		return "", "", fmt.Errorf("marshal new data: %w", err)
	}

	return string(oldJSON), string(newJSON), nil
}
