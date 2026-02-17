// Package models defines data structures for the Management API
package models

import (
	"time"
)

// ================== User Models ==================

// User represents an authenticated user
type User struct {
	ID           string    `json:"id"`
	Username     string    `json:"username"`
	Email        string    `json:"email"`
	PasswordHash string    `json:"-"`
	Roles        []string  `json:"roles"`
	IsActive     bool      `json:"is_active"`
	LastLogin    time.Time `json:"last_login,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// LoginRequest represents login credentials
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// LoginResponse contains authentication tokens
type LoginResponse struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token,omitempty"`
	ExpiresAt    time.Time `json:"expires_at"`
	User         User      `json:"user"`
}

// ================== Gateway Models ==================

// Gateway represents a network gateway/carrier
type Gateway struct {
	ID             string    `json:"id"`
	Name           string    `json:"name"`
	IPAddress      string    `json:"ip_address"`
	CarrierName    string    `json:"carrier_name"`
	GatewayType    string    `json:"gateway_type"` // local, international, transit
	FraudThreshold float64   `json:"fraud_threshold"`
	CPMLimit       int       `json:"cpm_limit"`
	ACDThreshold   float64   `json:"acd_threshold"`
	IsActive       bool      `json:"is_active"`
	IsBlacklisted  bool      `json:"is_blacklisted"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`

	// Computed fields
	CallsToday int `json:"calls_today,omitempty"`
	FraudCount int `json:"fraud_count,omitempty"`
}

// GatewayFilter contains filter options for gateway queries
type GatewayFilter struct {
	CarrierName   string
	GatewayType   string
	IsActive      *bool
	IsBlacklisted *bool
}

// CreateGatewayRequest represents a new gateway request
type CreateGatewayRequest struct {
	Name           string  `json:"name" binding:"required"`
	IPAddress      string  `json:"ip_address" binding:"required,ip"`
	CarrierName    string  `json:"carrier_name" binding:"required"`
	GatewayType    string  `json:"gateway_type" binding:"required,oneof=local international transit"`
	FraudThreshold float64 `json:"fraud_threshold"`
	CPMLimit       int     `json:"cpm_limit"`
	ACDThreshold   float64 `json:"acd_threshold"`
}

// UpdateGatewayRequest represents gateway update fields
type UpdateGatewayRequest struct {
	Name           *string  `json:"name,omitempty"`
	CarrierName    *string  `json:"carrier_name,omitempty"`
	FraudThreshold *float64 `json:"fraud_threshold,omitempty"`
	CPMLimit       *int     `json:"cpm_limit,omitempty"`
	ACDThreshold   *float64 `json:"acd_threshold,omitempty"`
}

// GatewayStats contains gateway statistics
type GatewayStats struct {
	GatewayID     string    `json:"gateway_id"`
	TotalCalls    int64     `json:"total_calls"`
	FraudCalls    int64     `json:"fraud_calls"`
	FraudRate     float64   `json:"fraud_rate"`
	AvgConfidence float64   `json:"avg_confidence"`
	AvgDuration   float64   `json:"avg_duration"`
	PeakCPS       int       `json:"peak_cps"`
	Period        string    `json:"period"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// ================== Fraud Detection Models ==================

// FraudAlert represents a detected fraud event
type FraudAlert struct {
	ID             string     `json:"id"`
	CallID         string     `json:"call_id"`
	EventType      string     `json:"event_type"` // CLI_MASK, SIM_BOX, REFILING, etc.
	SourceIP       string     `json:"source_ip"`
	CallerID       string     `json:"caller_id"`
	CalledNumber   string     `json:"called_number"`
	Confidence     float64    `json:"confidence"`
	Severity       int        `json:"severity"` // 1-5
	ActionTaken    string     `json:"action_taken"`
	Description    string     `json:"description"`
	IsAcknowledged bool       `json:"is_acknowledged"`
	AcknowledgedBy *string    `json:"acknowledged_by,omitempty"`
	AcknowledgedAt *time.Time `json:"acknowledged_at,omitempty"`
	IsResolved     bool       `json:"is_resolved"`
	ResolvedBy     *string    `json:"resolved_by,omitempty"`
	ResolvedAt     *time.Time `json:"resolved_at,omitempty"`
	ResolutionNote *string    `json:"resolution_notes,omitempty"`
	NCCReported    bool       `json:"ncc_reported"`
	NCCReportID    *string    `json:"ncc_report_id,omitempty"`
	DetectedAt     time.Time  `json:"detected_at"`
}

// AlertFilter contains filter options for alert queries
type AlertFilter struct {
	EventType      string
	Severity       int
	StartTime      time.Time
	EndTime        time.Time
	SourceIP       string
	IsAcknowledged *bool
	IsResolved     *bool
}

// AlertResolution contains resolution details
type AlertResolution struct {
	Notes  string `json:"notes"`
	Action string `json:"action"` // whitelist, permanent_block, escalate
}

// SimBoxSuspect represents a potential SIM box
type SimBoxSuspect struct {
	ID                 string    `json:"id"`
	SourceIP           string    `json:"source_ip"`
	CallerIDPattern    string    `json:"caller_id_pattern"`
	CallsPerMinute     float64   `json:"calls_per_minute"`
	AvgCallDuration    float64   `json:"avg_call_duration"`
	UniqueDestinations int       `json:"unique_destinations"`
	ConcurrentCalls    int       `json:"concurrent_calls"`
	RiskScore          float64   `json:"risk_score"`
	FirstSeen          time.Time `json:"first_seen"`
	LastSeen           time.Time `json:"last_seen"`
	TotalCalls         int64     `json:"total_calls"`
	Status             string    `json:"status"` // monitoring, suspected, confirmed, cleared
}

// BlacklistEntry represents a blacklisted entity
type BlacklistEntry struct {
	ID          string    `json:"id"`
	EntryType   string    `json:"entry_type"` // ip, cli, prefix, carrier
	Value       string    `json:"value"`
	Reason      string    `json:"reason"`
	Source      string    `json:"source"` // manual, ncc, auto
	AddedBy     string    `json:"added_by"`
	ExpiresAt   time.Time `json:"expires_at,omitempty"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
	NCCSynced   bool      `json:"ncc_synced"`
	NCCSyncedAt time.Time `json:"ncc_synced_at,omitempty"`
}

// AddBlacklistRequest represents a new blacklist entry
type AddBlacklistRequest struct {
	EntryType string    `json:"entry_type" binding:"required,oneof=ip cli prefix carrier"`
	Value     string    `json:"value" binding:"required"`
	Reason    string    `json:"reason" binding:"required"`
	ExpiresAt time.Time `json:"expires_at,omitempty"`
}

// ================== MNP Models ==================

// MNPResult represents an MNP lookup result
type MNPResult struct {
	MSISDN        string `json:"msisdn"`
	RoutingNumber string `json:"routing_number"`
	OperatorName  string `json:"operator_name"`
	IsPorted      bool   `json:"is_ported"`
	Source        string `json:"source"` // cache, database, prefix
	Error         string `json:"error,omitempty"`
}

// MNPStats contains MNP statistics
type MNPStats struct {
	TotalPorted   int            `json:"total_ported"`
	ByOperator    map[string]int `json:"by_operator"`
	LastUpdated   time.Time      `json:"last_updated"`
	CacheHitRate  float64        `json:"cache_hit_rate"`
	AvgLookupTime float64        `json:"avg_lookup_time_ms"`
}

// BulkMNPRequest represents a bulk lookup request
type BulkMNPRequest struct {
	MSISDNs []string `json:"msisdns" binding:"required,max=1000"`
}

// ================== Compliance Models ==================

// ComplianceReport represents an NCC compliance report
type ComplianceReport struct {
	ID          string    `json:"id"`
	ReportType  string    `json:"report_type"` // daily, weekly, monthly
	ReportDate  time.Time `json:"report_date"`
	TotalCalls  int64     `json:"total_calls"`
	FraudCalls  int64     `json:"fraud_calls"`
	FilePath    string    `json:"file_path"`
	SubmittedAt time.Time `json:"submitted_at,omitempty"`
	NCKAckID    *string   `json:"ncc_ack_id,omitempty"`
	Status      string    `json:"status"` // pending, submitted, acknowledged, failed
}

// SettlementDispute represents a billing dispute
type SettlementDispute struct {
	ID                 string    `json:"id"`
	DisputeType        string    `json:"dispute_type"` // fraud_billing, interconnect, regulatory
	CounterpartyCarier string    `json:"counterparty_carrier"`
	DisputedAmount     float64   `json:"disputed_amount"`
	Currency           string    `json:"currency"`
	CallCount          int       `json:"call_count"`
	StartDate          time.Time `json:"start_date"`
	EndDate            time.Time `json:"end_date"`
	Description        string    `json:"description"`
	Status             string    `json:"status"` // open, under_review, resolved, escalated
	Resolution         *string   `json:"resolution,omitempty"`
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`
}

// CreateDisputeRequest represents a new dispute
type CreateDisputeRequest struct {
	DisputeType        string    `json:"dispute_type" binding:"required"`
	CounterpartyCarier string    `json:"counterparty_carrier" binding:"required"`
	DisputedAmount     float64   `json:"disputed_amount" binding:"required,gt=0"`
	Currency           string    `json:"currency" binding:"required"`
	CallCount          int       `json:"call_count"`
	StartDate          time.Time `json:"start_date" binding:"required"`
	EndDate            time.Time `json:"end_date" binding:"required"`
	Description        string    `json:"description" binding:"required"`
}

// ================== Analytics Models ==================

// DashboardSummary contains summary statistics for the dashboard
type DashboardSummary struct {
	TotalCalls24h   int64          `json:"total_calls_24h"`
	FraudCalls24h   int64          `json:"fraud_calls_24h"`
	FraudRate24h    float64        `json:"fraud_rate_24h"`
	ActiveGateways  int            `json:"active_gateways"`
	PendingAlerts   int            `json:"pending_alerts"`
	AvgConfidence   float64        `json:"avg_confidence"`
	FraudByType     map[string]int `json:"fraud_by_type"`
	TopOffenders    []Gateway      `json:"top_offenders"`
	NCCReportStatus string         `json:"ncc_report_status"`
}

// RealtimeStats contains real-time statistics
type RealtimeStats struct {
	CurrentCPS      int       `json:"current_cps"`
	FraudRateLive   float64   `json:"fraud_rate_live"`
	DetectionLatP50 float64   `json:"detection_lat_p50_us"`
	DetectionLatP99 float64   `json:"detection_lat_p99_us"`
	CacheHitRate    float64   `json:"cache_hit_rate"`
	ActiveCalls     int       `json:"active_calls"`
	UpdatedAt       time.Time `json:"updated_at"`
}

// TrafficAnalysis contains traffic analysis data
type TrafficAnalysis struct {
	Period               string           `json:"period"`
	TotalCalls           int64            `json:"total_calls"`
	TotalMinutes         float64          `json:"total_minutes"`
	AvgCallDuration      float64          `json:"avg_call_duration"`
	PeakHour             string           `json:"peak_hour"`
	PeakCPS              int              `json:"peak_cps"`
	ByGateway            []GatewayTraffic `json:"by_gateway"`
	ByDestination        []DestTraffic    `json:"by_destination"`
	HourlyDistribution   []HourlyData     `json:"hourly_distribution"`
	InternationalMinutes float64          `json:"international_minutes"`
	LocalMinutes         float64          `json:"local_minutes"`
}

// GatewayTraffic contains traffic data for a gateway
type GatewayTraffic struct {
	GatewayID   string  `json:"gateway_id"`
	GatewayName string  `json:"gateway_name"`
	Calls       int64   `json:"calls"`
	Minutes     float64 `json:"minutes"`
	FraudRate   float64 `json:"fraud_rate"`
}

// DestTraffic contains traffic data for a destination
type DestTraffic struct {
	Prefix   string  `json:"prefix"`
	Country  string  `json:"country"`
	Operator string  `json:"operator"`
	Calls    int64   `json:"calls"`
	Minutes  float64 `json:"minutes"`
}

// HourlyData contains hourly traffic data
type HourlyData struct {
	Hour       int     `json:"hour"`
	Calls      int64   `json:"calls"`
	FraudCalls int64   `json:"fraud_calls"`
	FraudRate  float64 `json:"fraud_rate"`
}

// FraudTrend contains fraud trend data
type FraudTrend struct {
	Date            time.Time `json:"date"`
	TotalCalls      int64     `json:"total_calls"`
	FraudCalls      int64     `json:"fraud_calls"`
	FraudRate       float64   `json:"fraud_rate"`
	CLIMaskingCalls int64     `json:"cli_masking_calls"`
	SimBoxCalls     int64     `json:"simbox_calls"`
	RefilingCalls   int64     `json:"refiling_calls"`
	OtherFraud      int64     `json:"other_fraud"`
}

// ExportRequest represents a data export request
type ExportRequest struct {
	ReportType string            `json:"report_type" binding:"required,oneof=cdr fraud alerts settlement"`
	StartDate  time.Time         `json:"start_date" binding:"required"`
	EndDate    time.Time         `json:"end_date" binding:"required"`
	Format     string            `json:"format" binding:"required,oneof=csv xlsx pdf"`
	Filters    map[string]string `json:"filters,omitempty"`
}

// ExportResponse contains export result
type ExportResponse struct {
	JobID       string `json:"job_id"`
	Status      string `json:"status"`
	DownloadURL string `json:"download_url,omitempty"`
}

// ================== Audit Models ==================

// AuditEvent represents an audit log entry
type AuditEvent struct {
	ID           string    `json:"id"`
	UserID       string    `json:"user_id"`
	Username     string    `json:"username"`
	Action       string    `json:"action"` // create, update, delete, login, export
	ResourceType string    `json:"resource_type"`
	ResourceID   string    `json:"resource_id"`
	Details      string    `json:"details"`
	IPAddress    string    `json:"ip_address"`
	CreatedAt    time.Time `json:"created_at"`
}

// ================== Common Response Models ==================

// PaginatedResponse wraps paginated results
type PaginatedResponse struct {
	Data       interface{} `json:"data"`
	Total      int         `json:"total"`
	Page       int         `json:"page"`
	PageSize   int         `json:"page_size"`
	TotalPages int         `json:"total_pages"`
}

// ErrorResponse represents an API error
type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    int    `json:"code,omitempty"`
}

// SuccessResponse represents a successful operation
type SuccessResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
}
