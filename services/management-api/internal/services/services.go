// Package services implements business logic for the Management API
package services

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/billyronks/acm-management-api/internal/config"
	"github.com/billyronks/acm-management-api/internal/database"
	"github.com/billyronks/acm-management-api/internal/models"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

// ================== Auth Service ==================

// AuthService handles authentication and authorization
type AuthService struct {
	jwtSecret []byte
	jwtExpiry time.Duration
}

// NewAuthService creates a new auth service
func NewAuthService(secret string, expiry time.Duration) *AuthService {
	return &AuthService{
		jwtSecret: []byte(secret),
		jwtExpiry: expiry,
	}
}

// JWTClaims represents JWT token claims
type JWTClaims struct {
	UserID   string   `json:"user_id"`
	Username string   `json:"username"`
	Email    string   `json:"email"`
	Roles    []string `json:"roles"`
	jwt.RegisteredClaims
}

// GenerateToken creates a new JWT token for a user
func (s *AuthService) GenerateToken(user *models.User) (string, error) {
	claims := JWTClaims{
		UserID:   user.ID,
		Username: user.Username,
		Email:    user.Email,
		Roles:    user.Roles,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.jwtExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "acm-management-api",
			Subject:   user.ID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}

// ValidateToken validates a JWT token and returns claims
func (s *AuthService) ValidateToken(tokenString string) (*JWTClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return s.jwtSecret, nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*JWTClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("invalid token")
}

// HashPassword hashes a password using bcrypt
func (s *AuthService) HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 12)
	return string(bytes), err
}

// CheckPassword verifies a password against its hash
func (s *AuthService) CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// ================== Gateway Service ==================

// GatewayService handles gateway management
type GatewayService struct {
	db    *database.PostgresPool
	cache *database.RedisClient
}

// NewGatewayService creates a new gateway service
func NewGatewayService(db *database.PostgresPool, cache *database.RedisClient) *GatewayService {
	return &GatewayService{db: db, cache: cache}
}

// ListGateways returns all gateways with optional filters
func (s *GatewayService) ListGateways(ctx context.Context, filter models.GatewayFilter, page database.Pagination) ([]models.Gateway, int, error) {
	query := `
		SELECT g.id, g.name, g.ip_address, g.carrier_name, g.gateway_type, 
			   g.fraud_threshold, g.cpm_limit, g.acd_threshold, g.is_active, 
			   g.is_blacklisted, g.created_at, g.updated_at,
			   COALESCE(s.calls_today, 0) as calls_today,
			   COALESCE(s.fraud_count, 0) as fraud_count
		FROM gateway_profiles g
		LEFT JOIN (
			SELECT source_ip, 
				   COUNT(*) as calls_today,
				   SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) as fraud_count
			FROM fraud_alerts 
			WHERE detected_at > NOW() - INTERVAL '24 hours'
			GROUP BY source_ip
		) s ON g.ip_address = s.source_ip
		WHERE 1=1
	`
	args := []interface{}{}
	argNum := 1

	if filter.CarrierName != "" {
		query += fmt.Sprintf(" AND g.carrier_name = $%d", argNum)
		args = append(args, filter.CarrierName)
		argNum++
	}
	if filter.GatewayType != "" {
		query += fmt.Sprintf(" AND g.gateway_type = $%d", argNum)
		args = append(args, filter.GatewayType)
		argNum++
	}
	if filter.IsActive != nil {
		query += fmt.Sprintf(" AND g.is_active = $%d", argNum)
		args = append(args, *filter.IsActive)
		argNum++
	}
	if filter.IsBlacklisted != nil {
		query += fmt.Sprintf(" AND g.is_blacklisted = $%d", argNum)
		args = append(args, *filter.IsBlacklisted)
		argNum++
	}

	// Count total
	countQuery := "SELECT COUNT(*) FROM gateway_profiles g WHERE 1=1"
	var total int
	if err := s.db.Pool().QueryRow(ctx, countQuery).Scan(&total); err != nil {
		return nil, 0, err
	}

	// Add pagination
	query += fmt.Sprintf(" ORDER BY g.created_at DESC LIMIT $%d OFFSET $%d", argNum, argNum+1)
	args = append(args, page.PageSize, page.Offset)

	rows, err := s.db.Pool().Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var gateways []models.Gateway
	for rows.Next() {
		var g models.Gateway
		if err := rows.Scan(
			&g.ID, &g.Name, &g.IPAddress, &g.CarrierName, &g.GatewayType,
			&g.FraudThreshold, &g.CPMLimit, &g.ACDThreshold, &g.IsActive,
			&g.IsBlacklisted, &g.CreatedAt, &g.UpdatedAt,
			&g.CallsToday, &g.FraudCount,
		); err != nil {
			return nil, 0, err
		}
		gateways = append(gateways, g)
	}

	return gateways, total, nil
}

// GetGateway retrieves a single gateway by ID
func (s *GatewayService) GetGateway(ctx context.Context, id string) (*models.Gateway, error) {
	query := `
		SELECT id, name, ip_address, carrier_name, gateway_type, 
			   fraud_threshold, cpm_limit, acd_threshold, is_active, 
			   is_blacklisted, created_at, updated_at
		FROM gateway_profiles WHERE id = $1
	`
	var g models.Gateway
	err := s.db.Pool().QueryRow(ctx, query, id).Scan(
		&g.ID, &g.Name, &g.IPAddress, &g.CarrierName, &g.GatewayType,
		&g.FraudThreshold, &g.CPMLimit, &g.ACDThreshold, &g.IsActive,
		&g.IsBlacklisted, &g.CreatedAt, &g.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return &g, nil
}

// CreateGateway creates a new gateway profile
func (s *GatewayService) CreateGateway(ctx context.Context, req models.CreateGatewayRequest) (*models.Gateway, error) {
	query := `
		INSERT INTO gateway_profiles (name, ip_address, carrier_name, gateway_type,
			fraud_threshold, cpm_limit, acd_threshold, is_active)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id, created_at, updated_at
	`
	var g models.Gateway
	err := s.db.Pool().QueryRow(ctx, query,
		req.Name, req.IPAddress, req.CarrierName, req.GatewayType,
		req.FraudThreshold, req.CPMLimit, req.ACDThreshold, true,
	).Scan(&g.ID, &g.CreatedAt, &g.UpdatedAt)
	if err != nil {
		return nil, err
	}

	g.Name = req.Name
	g.IPAddress = req.IPAddress
	g.CarrierName = req.CarrierName
	g.GatewayType = req.GatewayType
	g.FraudThreshold = req.FraudThreshold
	g.CPMLimit = req.CPMLimit
	g.ACDThreshold = req.ACDThreshold
	g.IsActive = true

	// Invalidate cache
	s.cache.Client().Del(ctx, "gateway:"+req.IPAddress)

	return &g, nil
}

// UpdateGateway updates an existing gateway
func (s *GatewayService) UpdateGateway(ctx context.Context, id string, req models.UpdateGatewayRequest) (*models.Gateway, error) {
	query := `
		UPDATE gateway_profiles 
		SET name = COALESCE($2, name),
			carrier_name = COALESCE($3, carrier_name),
			fraud_threshold = COALESCE($4, fraud_threshold),
			cpm_limit = COALESCE($5, cpm_limit),
			acd_threshold = COALESCE($6, acd_threshold),
			updated_at = NOW()
		WHERE id = $1
		RETURNING id, name, ip_address, carrier_name, gateway_type, 
			fraud_threshold, cpm_limit, acd_threshold, is_active, 
			is_blacklisted, created_at, updated_at
	`
	var g models.Gateway
	err := s.db.Pool().QueryRow(ctx, query, id,
		req.Name, req.CarrierName, req.FraudThreshold, req.CPMLimit, req.ACDThreshold,
	).Scan(
		&g.ID, &g.Name, &g.IPAddress, &g.CarrierName, &g.GatewayType,
		&g.FraudThreshold, &g.CPMLimit, &g.ACDThreshold, &g.IsActive,
		&g.IsBlacklisted, &g.CreatedAt, &g.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	// Invalidate cache
	s.cache.Client().Del(ctx, "gateway:"+g.IPAddress)

	return &g, nil
}

// DeleteGateway removes a gateway
func (s *GatewayService) DeleteGateway(ctx context.Context, id string) error {
	// Get IP first for cache invalidation
	var ip string
	if err := s.db.Pool().QueryRow(ctx, "SELECT ip_address FROM gateway_profiles WHERE id = $1", id).Scan(&ip); err != nil {
		return err
	}

	_, err := s.db.Pool().Exec(ctx, "DELETE FROM gateway_profiles WHERE id = $1", id)
	if err != nil {
		return err
	}

	s.cache.Client().Del(ctx, "gateway:"+ip)
	return nil
}

// EnableGateway enables a gateway
func (s *GatewayService) EnableGateway(ctx context.Context, id string) error {
	_, err := s.db.Pool().Exec(ctx, "UPDATE gateway_profiles SET is_active = true, updated_at = NOW() WHERE id = $1", id)
	return err
}

// DisableGateway disables a gateway
func (s *GatewayService) DisableGateway(ctx context.Context, id string) error {
	_, err := s.db.Pool().Exec(ctx, "UPDATE gateway_profiles SET is_active = false, updated_at = NOW() WHERE id = $1", id)
	return err
}

// GetGatewayStats retrieves statistics for a gateway
func (s *GatewayService) GetGatewayStats(ctx context.Context, id string, timeRange database.TimeRange) (*models.GatewayStats, error) {
	// Get gateway IP
	var ip string
	if err := s.db.Pool().QueryRow(ctx, "SELECT ip_address FROM gateway_profiles WHERE id = $1", id).Scan(&ip); err != nil {
		return nil, err
	}

	stats := &models.GatewayStats{GatewayID: id}

	// This would query ClickHouse for detailed stats
	// For now, basic query from fraud_alerts
	query := `
		SELECT COUNT(*), 
			   SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END),
			   AVG(confidence)
		FROM fraud_alerts 
		WHERE source_ip = $1 AND detected_at BETWEEN $2 AND $3
	`
	err := s.db.Pool().QueryRow(ctx, query, ip, timeRange.Start, timeRange.End).Scan(
		&stats.TotalCalls, &stats.FraudCalls, &stats.AvgConfidence,
	)
	if err != nil {
		return nil, err
	}

	if stats.TotalCalls > 0 {
		stats.FraudRate = float64(stats.FraudCalls) / float64(stats.TotalCalls) * 100
	}

	return stats, nil
}

// ================== Fraud Service ==================

// FraudService handles fraud detection queries
type FraudService struct {
	db         *database.PostgresPool
	clickhouse *database.ClickHouseClient
	cache      *database.RedisClient
}

// NewFraudService creates a new fraud service
func NewFraudService(db *database.PostgresPool, ch *database.ClickHouseClient, cache *database.RedisClient) *FraudService {
	return &FraudService{db: db, clickhouse: ch, cache: cache}
}

// ListAlerts returns fraud alerts with optional filters
func (s *FraudService) ListAlerts(ctx context.Context, filter models.AlertFilter, page database.Pagination) ([]models.FraudAlert, int, error) {
	query := `
		SELECT id, call_id, event_type, source_ip, caller_id, called_number,
			   confidence, severity, action_taken, description, is_acknowledged,
			   acknowledged_by, acknowledged_at, is_resolved, resolved_by, resolved_at,
			   ncc_reported, ncc_report_id, detected_at
		FROM fraud_alerts WHERE 1=1
	`
	args := []interface{}{}
	argNum := 1

	if filter.EventType != "" {
		query += fmt.Sprintf(" AND event_type = $%d", argNum)
		args = append(args, filter.EventType)
		argNum++
	}
	if filter.Severity > 0 {
		query += fmt.Sprintf(" AND severity >= $%d", argNum)
		args = append(args, filter.Severity)
		argNum++
	}
	if !filter.StartTime.IsZero() {
		query += fmt.Sprintf(" AND detected_at >= $%d", argNum)
		args = append(args, filter.StartTime)
		argNum++
	}
	if !filter.EndTime.IsZero() {
		query += fmt.Sprintf(" AND detected_at <= $%d", argNum)
		args = append(args, filter.EndTime)
		argNum++
	}
	if filter.SourceIP != "" {
		query += fmt.Sprintf(" AND source_ip = $%d", argNum)
		args = append(args, filter.SourceIP)
		argNum++
	}
	if filter.IsAcknowledged != nil {
		query += fmt.Sprintf(" AND is_acknowledged = $%d", argNum)
		args = append(args, *filter.IsAcknowledged)
		argNum++
	}

	// Count total
	var total int
	// Would need to rebuild WHERE clause for count - simplified here
	if err := s.db.Pool().QueryRow(ctx, "SELECT COUNT(*) FROM fraud_alerts").Scan(&total); err != nil {
		return nil, 0, err
	}

	query += fmt.Sprintf(" ORDER BY detected_at DESC LIMIT $%d OFFSET $%d", argNum, argNum+1)
	args = append(args, page.PageSize, page.Offset)

	rows, err := s.db.Pool().Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var alerts []models.FraudAlert
	for rows.Next() {
		var a models.FraudAlert
		if err := rows.Scan(
			&a.ID, &a.CallID, &a.EventType, &a.SourceIP, &a.CallerID, &a.CalledNumber,
			&a.Confidence, &a.Severity, &a.ActionTaken, &a.Description, &a.IsAcknowledged,
			&a.AcknowledgedBy, &a.AcknowledgedAt, &a.IsResolved, &a.ResolvedBy, &a.ResolvedAt,
			&a.NCCReported, &a.NCCReportID, &a.DetectedAt,
		); err != nil {
			return nil, 0, err
		}
		alerts = append(alerts, a)
	}

	return alerts, total, nil
}

// GetAlert retrieves a single alert
func (s *FraudService) GetAlert(ctx context.Context, id string) (*models.FraudAlert, error) {
	query := `
		SELECT id, call_id, event_type, source_ip, caller_id, called_number,
			   confidence, severity, action_taken, description, is_acknowledged,
			   acknowledged_by, acknowledged_at, is_resolved, resolved_by, resolved_at,
			   ncc_reported, ncc_report_id, detected_at
		FROM fraud_alerts WHERE id = $1
	`
	var a models.FraudAlert
	err := s.db.Pool().QueryRow(ctx, query, id).Scan(
		&a.ID, &a.CallID, &a.EventType, &a.SourceIP, &a.CallerID, &a.CalledNumber,
		&a.Confidence, &a.Severity, &a.ActionTaken, &a.Description, &a.IsAcknowledged,
		&a.AcknowledgedBy, &a.AcknowledgedAt, &a.IsResolved, &a.ResolvedBy, &a.ResolvedAt,
		&a.NCCReported, &a.NCCReportID, &a.DetectedAt,
	)
	if err != nil {
		return nil, err
	}
	return &a, nil
}

// AcknowledgeAlert marks an alert as acknowledged
func (s *FraudService) AcknowledgeAlert(ctx context.Context, id, userID string) error {
	_, err := s.db.Pool().Exec(ctx,
		`UPDATE fraud_alerts SET is_acknowledged = true, acknowledged_by = $2, acknowledged_at = NOW() WHERE id = $1`,
		id, userID,
	)
	return err
}

// ResolveAlert marks an alert as resolved
func (s *FraudService) ResolveAlert(ctx context.Context, id, userID string, resolution models.AlertResolution) error {
	_, err := s.db.Pool().Exec(ctx,
		`UPDATE fraud_alerts SET is_resolved = true, resolved_by = $2, resolved_at = NOW(), 
		 resolution_notes = $3 WHERE id = $1`,
		id, userID, resolution.Notes,
	)
	return err
}

// GetDashboardSummary returns summary statistics for the dashboard
func (s *FraudService) GetDashboardSummary(ctx context.Context) (*models.DashboardSummary, error) {
	summary := &models.DashboardSummary{}

	// Get 24h stats
	query := `
		SELECT 
			COUNT(*) as total_calls,
			SUM(CASE WHEN is_fraud THEN 1 ELSE 0 END) as fraud_calls,
			COUNT(DISTINCT source_ip) as active_gateways,
			AVG(confidence) as avg_confidence
		FROM fraud_alerts 
		WHERE detected_at > NOW() - INTERVAL '24 hours'
	`
	// This is simplified - would need proper CDR table
	s.db.Pool().QueryRow(ctx, query).Scan(
		&summary.TotalCalls24h,
		&summary.FraudCalls24h,
		&summary.ActiveGateways,
		&summary.AvgConfidence,
	)

	// Get unacknowledged alerts
	s.db.Pool().QueryRow(ctx,
		"SELECT COUNT(*) FROM fraud_alerts WHERE is_acknowledged = false AND detected_at > NOW() - INTERVAL '24 hours'",
	).Scan(&summary.PendingAlerts)

	// Get by event type
	rows, err := s.db.Pool().Query(ctx,
		`SELECT event_type, COUNT(*) FROM fraud_alerts 
		 WHERE detected_at > NOW() - INTERVAL '24 hours' 
		 GROUP BY event_type`,
	)
	if err == nil {
		defer rows.Close()
		summary.FraudByType = make(map[string]int)
		for rows.Next() {
			var eventType string
			var count int
			rows.Scan(&eventType, &count)
			summary.FraudByType[eventType] = count
		}
	}

	return summary, nil
}

// ================== MNP Service ==================

// MNPService handles Mobile Number Portability lookups
type MNPService struct {
	db    *database.PostgresPool
	cache *database.RedisClient
}

// NewMNPService creates a new MNP service
func NewMNPService(db *database.PostgresPool, cache *database.RedisClient) *MNPService {
	return &MNPService{db: db, cache: cache}
}

// Lookup performs an MNP lookup for a single MSISDN
func (s *MNPService) Lookup(ctx context.Context, msisdn string) (*models.MNPResult, error) {
	// Try cache first
	cacheKey := "mnp:" + msisdn
	cached, err := s.cache.Client().Get(ctx, cacheKey).Result()
	if err == nil {
		// Parse cached result
		return &models.MNPResult{
			MSISDN:        msisdn,
			RoutingNumber: cached,
			Source:        "cache",
		}, nil
	}

	// Query database
	var routingNumber string
	var operatorName string
	err = s.db.Pool().QueryRow(ctx,
		`SELECT routing_number, operator_name FROM mnp_data WHERE msisdn = $1`,
		msisdn,
	).Scan(&routingNumber, &operatorName)

	if err != nil {
		// Not ported - determine from prefix
		result := s.determineFromPrefix(msisdn)
		return result, nil
	}

	result := &models.MNPResult{
		MSISDN:        msisdn,
		RoutingNumber: routingNumber,
		OperatorName:  operatorName,
		IsPorted:      true,
		Source:        "database",
	}

	// Cache the result (24h TTL)
	s.cache.Client().Set(ctx, cacheKey, routingNumber, 24*time.Hour)

	return result, nil
}

// determineFromPrefix returns the MNO based on the number prefix
func (s *MNPService) determineFromPrefix(msisdn string) *models.MNPResult {
	// Normalize - remove +234 or 234 prefix
	normalized := msisdn
	if len(normalized) > 10 {
		if normalized[0:4] == "+234" {
			normalized = "234" + normalized[4:]
		}
	}

	mnos := config.GetNigerianMNOs()
	for _, mno := range mnos {
		for _, prefix := range mno.Prefixes {
			if len(normalized) >= len(prefix) && normalized[:len(prefix)] == prefix {
				return &models.MNPResult{
					MSISDN:        msisdn,
					RoutingNumber: mno.RoutingNumber,
					OperatorName:  mno.Name,
					IsPorted:      false,
					Source:        "prefix",
				}
			}
		}
	}

	return &models.MNPResult{
		MSISDN: msisdn,
		Source: "unknown",
	}
}

// BulkLookup performs MNP lookups for multiple MSISDNs
func (s *MNPService) BulkLookup(ctx context.Context, msisdns []string) ([]models.MNPResult, error) {
	results := make([]models.MNPResult, 0, len(msisdns))
	for _, msisdn := range msisdns {
		result, err := s.Lookup(ctx, msisdn)
		if err != nil {
			results = append(results, models.MNPResult{
				MSISDN: msisdn,
				Error:  err.Error(),
			})
			continue
		}
		results = append(results, *result)
	}
	return results, nil
}

// GetStats returns MNP lookup statistics
func (s *MNPService) GetStats(ctx context.Context) (*models.MNPStats, error) {
	stats := &models.MNPStats{}

	// Count total ported numbers
	s.db.Pool().QueryRow(ctx, "SELECT COUNT(*) FROM mnp_data").Scan(&stats.TotalPorted)

	// Count by operator
	rows, err := s.db.Pool().Query(ctx,
		"SELECT operator_name, COUNT(*) FROM mnp_data GROUP BY operator_name",
	)
	if err == nil {
		defer rows.Close()
		stats.ByOperator = make(map[string]int)
		for rows.Next() {
			var op string
			var count int
			rows.Scan(&op, &count)
			stats.ByOperator[op] = count
		}
	}

	return stats, nil
}

// ================== Compliance Service ==================

// ComplianceService handles NCC compliance reporting
type ComplianceService struct {
	db         *database.PostgresPool
	clickhouse *database.ClickHouseClient
	config     *config.Config
}

// NewComplianceService creates a new compliance service
func NewComplianceService(db *database.PostgresPool, ch *database.ClickHouseClient, cfg *config.Config) *ComplianceService {
	return &ComplianceService{db: db, clickhouse: ch, config: cfg}
}

// ListReports returns NCC compliance reports
func (s *ComplianceService) ListReports(ctx context.Context, page database.Pagination) ([]models.ComplianceReport, int, error) {
	// Query from audit log or dedicated reports table
	query := `
		SELECT id, report_type, report_date, total_calls, fraud_calls, 
			   file_path, submitted_at, ncc_ack_id, status
		FROM ncc_reports
		ORDER BY report_date DESC
		LIMIT $1 OFFSET $2
	`
	rows, err := s.db.Pool().Query(ctx, query, page.PageSize, page.Offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var reports []models.ComplianceReport
	for rows.Next() {
		var r models.ComplianceReport
		if err := rows.Scan(
			&r.ID, &r.ReportType, &r.ReportDate, &r.TotalCalls, &r.FraudCalls,
			&r.FilePath, &r.SubmittedAt, &r.NCKAckID, &r.Status,
		); err != nil {
			return nil, 0, err
		}
		reports = append(reports, r)
	}

	var total int
	s.db.Pool().QueryRow(ctx, "SELECT COUNT(*) FROM ncc_reports").Scan(&total)

	return reports, total, nil
}

// ================== Analytics Service ==================

// AnalyticsService handles analytics queries
type AnalyticsService struct {
	clickhouse *database.ClickHouseClient
	cache      *database.RedisClient
}

// NewAnalyticsService creates a new analytics service
func NewAnalyticsService(ch *database.ClickHouseClient, cache *database.RedisClient) *AnalyticsService {
	return &AnalyticsService{clickhouse: ch, cache: cache}
}

// GetTrafficAnalysis returns traffic analysis for a time period
func (s *AnalyticsService) GetTrafficAnalysis(ctx context.Context, timeRange database.TimeRange) (*models.TrafficAnalysis, error) {
	// Query ClickHouse for traffic data
	// This is a placeholder - would use actual ClickHouse queries
	return &models.TrafficAnalysis{
		Period:     fmt.Sprintf("%s to %s", timeRange.Start.Format(time.RFC3339), timeRange.End.Format(time.RFC3339)),
		TotalCalls: 0,
	}, nil
}

// ================== Audit Service ==================

// AuditService handles audit logging
type AuditService struct {
	db *database.PostgresPool
}

// NewAuditService creates a new audit service
func NewAuditService(db *database.PostgresPool) *AuditService {
	return &AuditService{db: db}
}

// Log records an audit event
func (s *AuditService) Log(ctx context.Context, event models.AuditEvent) error {
	_, err := s.db.Pool().Exec(ctx,
		`INSERT INTO audit_log (user_id, action, resource_type, resource_id, details, ip_address)
		 VALUES ($1, $2, $3, $4, $5, $6)`,
		event.UserID, event.Action, event.ResourceType, event.ResourceID, event.Details, event.IPAddress,
	)
	return err
}

// generateID creates a random ID
func generateID() string {
	bytes := make([]byte, 16)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}
