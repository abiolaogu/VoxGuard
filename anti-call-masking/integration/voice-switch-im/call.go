package model

import (
	"time"

	"github.com/google/uuid"
)

// CallEvent represents a SIP call event for fraud detection
type CallEvent struct {
	CallID      string    `json:"call_id"`
	ANumber     string    `json:"a_number"`
	BNumber     string    `json:"b_number"`
	Timestamp   time.Time `json:"timestamp"`
	Status      string    `json:"status"` // ringing, active, completed, disconnected
	CarrierID   uuid.UUID `json:"carrier_id,omitempty"`
	SwitchID    string    `json:"switch_id,omitempty"`
	Direction   string    `json:"direction,omitempty"` // inbound, outbound
	SIPMethod   string    `json:"sip_method,omitempty"`
	UserAgent   string    `json:"user_agent,omitempty"`
	SourceIP    string    `json:"source_ip,omitempty"`
	SourcePort  int       `json:"source_port,omitempty"`
}

// CallEventCreate represents the payload for reporting a new call event
type CallEventCreate struct {
	CallID    string    `json:"call_id" binding:"required"`
	ANumber   string    `json:"a_number" binding:"required"`
	BNumber   string    `json:"b_number" binding:"required"`
	Timestamp time.Time `json:"timestamp,omitempty"`
	Status    string    `json:"status" binding:"required,oneof=ringing active completed disconnected"`
	CarrierID string    `json:"carrier_id,omitempty"`
	SwitchID  string    `json:"switch_id,omitempty"`
	Direction string    `json:"direction,omitempty" binding:"omitempty,oneof=inbound outbound"`
	SIPMethod string    `json:"sip_method,omitempty"`
	SourceIP  string    `json:"source_ip,omitempty"`
}

// DisconnectRequest represents a request to disconnect a fraudulent call
type DisconnectRequest struct {
	CallIDs  []string `json:"call_ids" binding:"required,min=1"`
	AlertID  string   `json:"alert_id,omitempty"`
	Reason   string   `json:"reason,omitempty"`
}

// DisconnectResponse represents the result of a disconnect operation
type DisconnectResponse struct {
	Requested    int                 `json:"requested"`
	Disconnected int                 `json:"disconnected"`
	Failed       int                 `json:"failed"`
	Results      []DisconnectResult  `json:"results"`
}

// DisconnectResult represents the result for a single call disconnect
type DisconnectResult struct {
	CallID  string `json:"call_id"`
	Success bool   `json:"success"`
	Error   string `json:"error,omitempty"`
}

// FraudAlert represents an alert from the fraud detection system
type FraudAlert struct {
	AlertID       string     `json:"alert_id"`
	AlertType     string     `json:"alert_type"` // multicall_masking, wangiri, etc.
	BNumber       string     `json:"b_number"`
	ANumbers      []string   `json:"a_numbers"`
	CallIDs       []string   `json:"call_ids"`
	DetectedAt    time.Time  `json:"detected_at"`
	Severity      string     `json:"severity"` // low, medium, high, critical
	Action        string     `json:"action"`   // none, disconnect, block
	ActionTakenAt *time.Time `json:"action_taken_at,omitempty"`
}

// FraudAlertWebhook represents the payload sent to fraud detection webhook
type FraudAlertWebhook struct {
	EventType string      `json:"event_type"` // fraud_detected, fraud_cleared
	Alert     *FraudAlert `json:"alert"`
}

// FraudDetectionConfig represents fraud detection configuration
type FraudDetectionConfig struct {
	Enabled           bool   `json:"enabled"`
	WebhookURL        string `json:"webhook_url"`
	DetectionEndpoint string `json:"detection_endpoint"`
	WindowSeconds     int    `json:"window_seconds"`
	Threshold         int    `json:"threshold"`
	AutoDisconnect    bool   `json:"auto_disconnect"`
}

// ActiveCall represents an active call in the system
type ActiveCall struct {
	CallID     string    `json:"call_id"`
	ANumber    string    `json:"a_number"`
	BNumber    string    `json:"b_number"`
	StartedAt  time.Time `json:"started_at"`
	CarrierID  uuid.UUID `json:"carrier_id"`
	SwitchID   string    `json:"switch_id"`
	Status     string    `json:"status"`
}

// CallStats represents call statistics for monitoring
type CallStats struct {
	ActiveCalls       int     `json:"active_calls"`
	CallsLast5Min     int     `json:"calls_last_5min"`
	CallsLast1Hour    int     `json:"calls_last_1hour"`
	FraudAlertsToday  int     `json:"fraud_alerts_today"`
	DisconnectsToday  int     `json:"disconnects_today"`
	TopBNumbers       []BNumberStats `json:"top_b_numbers"`
}

// BNumberStats represents statistics for a B-number
type BNumberStats struct {
	BNumber     string  `json:"b_number"`
	CallCount   int     `json:"call_count"`
	UniqueANums int     `json:"unique_a_numbers"`
	IsFlagged   bool    `json:"is_flagged"`
}
