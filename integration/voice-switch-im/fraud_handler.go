package api

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"github.com/example/voice-switch-im/backend/internal/model"
)

// FraudDetectionService handles call events and fraud detection integration
// Uses LumaDB as the unified database (replaces kdb+, Kafka, Redis, PostgreSQL)
type FraudDetectionService struct {
	logger           *zap.Logger
	lumadbEndpoint   string  // LumaDB ACM Detection Service endpoint
	webhookSecret    string
	activeCalls      map[string]*model.ActiveCall
	mu               sync.RWMutex
	httpClient       *http.Client
	metricsEnabled   bool
	callEventsBuffer []model.CallEvent
	bufferMu         sync.Mutex
	flushInterval    time.Duration
}

// NewFraudDetectionService creates a new fraud detection service
// Connects to the LumaDB-powered ACM Detection Service
func NewFraudDetectionService(logger *zap.Logger) *FraudDetectionService {
	// LumaDB ACM Detection Service endpoint (Python FastAPI on port 5001)
	lumadbEndpoint := os.Getenv("FRAUD_DETECTION_URL")
	if lumadbEndpoint == "" {
		lumadbEndpoint = "http://acm-detection:5001"
	}

	svc := &FraudDetectionService{
		logger:         logger,
		lumadbEndpoint: lumadbEndpoint,
		webhookSecret:  os.Getenv("FRAUD_WEBHOOK_SECRET"),
		activeCalls:    make(map[string]*model.ActiveCall),
		httpClient: &http.Client{
			Timeout: 5 * time.Second,
		},
		metricsEnabled:   true,
		callEventsBuffer: make([]model.CallEvent, 0, 100),
		flushInterval:    100 * time.Millisecond,
	}

	// Start background buffer flusher
	go svc.startBufferFlusher()

	return svc
}

// startBufferFlusher periodically flushes buffered events to LumaDB
func (s *FraudDetectionService) startBufferFlusher() {
	ticker := time.NewTicker(s.flushInterval)
	defer ticker.Stop()

	for range ticker.C {
		s.flushBuffer()
	}
}

// flushBuffer sends buffered events to LumaDB via the ACM Detection Service
func (s *FraudDetectionService) flushBuffer() {
	s.bufferMu.Lock()
	if len(s.callEventsBuffer) == 0 {
		s.bufferMu.Unlock()
		return
	}

	events := s.callEventsBuffer
	s.callEventsBuffer = make([]model.CallEvent, 0, 100)
	s.bufferMu.Unlock()

	// Send batch to LumaDB ACM Detection Service
	payload, err := json.Marshal(map[string]interface{}{
		"events": events,
	})
	if err != nil {
		s.logger.Error("failed to marshal events batch", zap.Error(err))
		return
	}

	resp, err := s.httpClient.Post(
		s.lumadbEndpoint+"/acm/calls/batch",
		"application/json",
		bytes.NewBuffer(payload),
	)
	if err != nil {
		s.logger.Warn("failed to send events to LumaDB fraud detection",
			zap.Error(err),
			zap.Int("event_count", len(events)),
		)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusAccepted {
		s.logger.Warn("LumaDB fraud detection returned non-OK status",
			zap.Int("status", resp.StatusCode),
		)
	}
}

// RegisterFraudRoutes registers fraud detection API routes
func RegisterFraudRoutes(rg *gin.RouterGroup, logger *zap.Logger) *FraudDetectionService {
	svc := NewFraudDetectionService(logger)

	fraud := rg.Group("/fraud")
	{
		// Call event endpoints
		fraud.POST("/events", svc.handleCallEvent())
		fraud.POST("/events/batch", svc.handleCallEventBatch())

		// Disconnect endpoint for LumaDB ACM to call
		fraud.POST("/disconnect", svc.handleDisconnect())

		// Active calls management
		fraud.GET("/calls/active", svc.getActiveCalls())
		fraud.GET("/calls/stats", svc.getCallStats())

		// Alert management (proxied from LumaDB)
		fraud.GET("/alerts", svc.getAlerts())
		fraud.POST("/alerts/webhook", svc.handleAlertWebhook())

		// Configuration
		fraud.GET("/config", svc.getConfig())
		fraud.PUT("/config", svc.updateConfig())

		// Health check for fraud detection subsystem
		fraud.GET("/health", svc.healthCheck())
	}

	return svc
}

// handleCallEvent processes a single call event
func (s *FraudDetectionService) handleCallEvent() gin.HandlerFunc {
	return func(c *gin.Context) {
		var req model.CallEventCreate
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Set timestamp if not provided
		if req.Timestamp.IsZero() {
			req.Timestamp = time.Now().UTC()
		}

		// Create call event
		event := model.CallEvent{
			CallID:    req.CallID,
			ANumber:   req.ANumber,
			BNumber:   req.BNumber,
			Timestamp: req.Timestamp,
			Status:    req.Status,
			SwitchID:  req.SwitchID,
			Direction: req.Direction,
			SIPMethod: req.SIPMethod,
			SourceIP:  req.SourceIP,
		}

		// Track active calls
		s.trackCall(&event)

		// Buffer event for batch sending to LumaDB
		s.bufferMu.Lock()
		s.callEventsBuffer = append(s.callEventsBuffer, event)
		shouldFlush := len(s.callEventsBuffer) >= 50
		s.bufferMu.Unlock()

		// Flush immediately if buffer is large
		if shouldFlush {
			go s.flushBuffer()
		}

		// For active calls, also send immediately for real-time detection
		if event.Status == "active" || event.Status == "ringing" {
			go s.sendToLumaDB(&event)
		}

		c.JSON(http.StatusAccepted, gin.H{
			"status":  "accepted",
			"call_id": event.CallID,
		})
	}
}

// handleCallEventBatch processes multiple call events
func (s *FraudDetectionService) handleCallEventBatch() gin.HandlerFunc {
	return func(c *gin.Context) {
		var events []model.CallEventCreate
		if err := c.ShouldBindJSON(&events); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		now := time.Now().UTC()
		processed := 0

		for _, req := range events {
			if req.Timestamp.IsZero() {
				req.Timestamp = now
			}

			event := model.CallEvent{
				CallID:    req.CallID,
				ANumber:   req.ANumber,
				BNumber:   req.BNumber,
				Timestamp: req.Timestamp,
				Status:    req.Status,
				SwitchID:  req.SwitchID,
				Direction: req.Direction,
				SIPMethod: req.SIPMethod,
				SourceIP:  req.SourceIP,
			}

			s.trackCall(&event)

			s.bufferMu.Lock()
			s.callEventsBuffer = append(s.callEventsBuffer, event)
			s.bufferMu.Unlock()

			processed++
		}

		// Flush the buffer
		go s.flushBuffer()

		c.JSON(http.StatusAccepted, gin.H{
			"status":    "accepted",
			"processed": processed,
		})
	}
}

// trackCall updates the active calls tracking
func (s *FraudDetectionService) trackCall(event *model.CallEvent) {
	s.mu.Lock()
	defer s.mu.Unlock()

	switch event.Status {
	case "ringing", "active":
		s.activeCalls[event.CallID] = &model.ActiveCall{
			CallID:    event.CallID,
			ANumber:   event.ANumber,
			BNumber:   event.BNumber,
			StartedAt: event.Timestamp,
			SwitchID:  event.SwitchID,
			Status:    event.Status,
		}
	case "completed", "disconnected":
		delete(s.activeCalls, event.CallID)
	}
}

// sendToLumaDB sends a call event to the LumaDB-powered fraud detection system
func (s *FraudDetectionService) sendToLumaDB(event *model.CallEvent) {
	payload, err := json.Marshal(map[string]interface{}{
		"a_number":    event.ANumber,
		"b_number":    event.BNumber,
		"call_id":     event.CallID,
		"source_ip":   event.SourceIP,
		"switch_id":   event.SwitchID,
		"raw_call_id": event.CallID,
	})
	if err != nil {
		s.logger.Error("failed to marshal call event", zap.Error(err))
		return
	}

	resp, err := s.httpClient.Post(
		s.lumadbEndpoint+"/acm/call",
		"application/json",
		bytes.NewBuffer(payload),
	)
	if err != nil {
		s.logger.Warn("failed to send event to LumaDB fraud detection",
			zap.Error(err),
			zap.String("call_id", event.CallID),
		)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		// Check for fraud detection result
		var result map[string]interface{}
		if err := json.NewDecoder(resp.Body).Decode(&result); err == nil {
			if detected, ok := result["detected"].(bool); ok && detected {
				s.logger.Warn("fraud detected by LumaDB",
					zap.String("call_id", event.CallID),
					zap.String("b_number", event.BNumber),
					zap.Any("result", result),
				)
			}
		}
	}
}

// handleDisconnect handles disconnect requests from the LumaDB fraud detection system
func (s *FraudDetectionService) handleDisconnect() gin.HandlerFunc {
	return func(c *gin.Context) {
		var req model.DisconnectRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		s.logger.Info("disconnect request received from LumaDB ACM",
			zap.Strings("call_ids", req.CallIDs),
			zap.String("alert_id", req.AlertID),
			zap.String("reason", req.Reason),
		)

		response := model.DisconnectResponse{
			Requested: len(req.CallIDs),
			Results:   make([]model.DisconnectResult, 0, len(req.CallIDs)),
		}

		for _, callID := range req.CallIDs {
			result := s.disconnectCall(callID, req.Reason)
			response.Results = append(response.Results, result)
			if result.Success {
				response.Disconnected++
			} else {
				response.Failed++
			}
		}

		c.JSON(http.StatusOK, response)
	}
}

// disconnectCall sends a disconnect command to the SIP switch
func (s *FraudDetectionService) disconnectCall(callID string, reason string) model.DisconnectResult {
	result := model.DisconnectResult{
		CallID: callID,
	}

	// Check if call is active
	s.mu.RLock()
	call, exists := s.activeCalls[callID]
	s.mu.RUnlock()

	if !exists {
		result.Success = false
		result.Error = "call not found or already ended"
		return result
	}

	// Send BYE to Kamailio SBC via JSON-RPC
	kamailioEndpoint := os.Getenv("KAMAILIO_MI_URL")
	if kamailioEndpoint == "" {
		kamailioEndpoint = "http://kamailio-sbc:5060"
	}

	// Construct JSON-RPC request for dialog termination
	rpcRequest := map[string]interface{}{
		"jsonrpc": "2.0",
		"method":  "dlg.end_dlg",
		"params": map[string]string{
			"callid": callID,
		},
		"id": 1,
	}

	payload, _ := json.Marshal(rpcRequest)
	resp, err := s.httpClient.Post(
		kamailioEndpoint+"/RPC",
		"application/json",
		bytes.NewBuffer(payload),
	)

	if err != nil {
		s.logger.Error("failed to send disconnect to Kamailio",
			zap.Error(err),
			zap.String("call_id", callID),
		)
		result.Success = false
		result.Error = fmt.Sprintf("switch communication error: %v", err)
		return result
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		result.Success = true
		// Remove from active calls
		s.mu.Lock()
		delete(s.activeCalls, callID)
		s.mu.Unlock()

		s.logger.Info("call disconnected successfully",
			zap.String("call_id", callID),
			zap.String("a_number", call.ANumber),
			zap.String("b_number", call.BNumber),
			zap.String("reason", reason),
		)
	} else {
		result.Success = false
		result.Error = fmt.Sprintf("switch returned status %d", resp.StatusCode)
	}

	return result
}

// getActiveCalls returns the list of active calls
func (s *FraudDetectionService) getActiveCalls() gin.HandlerFunc {
	return func(c *gin.Context) {
		s.mu.RLock()
		calls := make([]*model.ActiveCall, 0, len(s.activeCalls))
		for _, call := range s.activeCalls {
			calls = append(calls, call)
		}
		s.mu.RUnlock()

		c.JSON(http.StatusOK, gin.H{
			"active_calls": calls,
			"count":        len(calls),
		})
	}
}

// getCallStats returns call statistics
func (s *FraudDetectionService) getCallStats() gin.HandlerFunc {
	return func(c *gin.Context) {
		s.mu.RLock()
		activeCount := len(s.activeCalls)

		// Calculate B-number stats
		bNumberCounts := make(map[string]map[string]bool)
		for _, call := range s.activeCalls {
			if _, exists := bNumberCounts[call.BNumber]; !exists {
				bNumberCounts[call.BNumber] = make(map[string]bool)
			}
			bNumberCounts[call.BNumber][call.ANumber] = true
		}
		s.mu.RUnlock()

		topBNumbers := make([]model.BNumberStats, 0)
		for bNum, aNumbers := range bNumberCounts {
			topBNumbers = append(topBNumbers, model.BNumberStats{
				BNumber:     bNum,
				CallCount:   len(aNumbers),
				UniqueANums: len(aNumbers),
				IsFlagged:   len(aNumbers) >= 5, // Matches detection threshold
			})
		}

		c.JSON(http.StatusOK, model.CallStats{
			ActiveCalls: activeCount,
			TopBNumbers: topBNumbers,
		})
	}
}

// getAlerts fetches alerts from the LumaDB ACM Detection system
func (s *FraudDetectionService) getAlerts() gin.HandlerFunc {
	return func(c *gin.Context) {
		resp, err := s.httpClient.Get(s.lumadbEndpoint + "/acm/alerts")
		if err != nil {
			s.logger.Error("failed to fetch alerts from LumaDB", zap.Error(err))
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "LumaDB fraud detection service unavailable"})
			return
		}
		defer resp.Body.Close()

		var alertsResponse map[string]interface{}
		if err := json.NewDecoder(resp.Body).Decode(&alertsResponse); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to parse alerts"})
			return
		}

		c.JSON(http.StatusOK, alertsResponse)
	}
}

// handleAlertWebhook receives alert webhooks from LumaDB ACM
func (s *FraudDetectionService) handleAlertWebhook() gin.HandlerFunc {
	return func(c *gin.Context) {
		var webhook model.FraudAlertWebhook
		if err := c.ShouldBindJSON(&webhook); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		s.logger.Info("received fraud alert webhook from LumaDB",
			zap.String("event_type", webhook.EventType),
			zap.String("alert_id", webhook.Alert.AlertID),
			zap.String("alert_type", webhook.Alert.AlertType),
			zap.String("b_number", webhook.Alert.BNumber),
			zap.Strings("a_numbers", webhook.Alert.ANumbers),
		)

		// Handle the alert based on type
		switch webhook.EventType {
		case "fraud_detected":
			// Could trigger additional actions here (e.g., notify operators)
		case "fraud_cleared":
			// Could update monitoring dashboards
		}

		c.JSON(http.StatusOK, gin.H{"status": "received"})
	}
}

// getConfig returns the current fraud detection configuration
func (s *FraudDetectionService) getConfig() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Fetch config from LumaDB ACM Detection Service
		resp, err := s.httpClient.Get(s.lumadbEndpoint + "/acm/config")
		if err != nil {
			c.JSON(http.StatusOK, model.FraudDetectionConfig{
				Enabled:           true,
				WebhookURL:        s.lumadbEndpoint + "/acm/call",
				DetectionEndpoint: s.lumadbEndpoint,
				WindowSeconds:     5,
				Threshold:         5,
				AutoDisconnect:    false,
			})
			return
		}
		defer resp.Body.Close()

		var config map[string]interface{}
		json.NewDecoder(resp.Body).Decode(&config)
		c.JSON(http.StatusOK, config)
	}
}

// updateConfig updates the fraud detection configuration
func (s *FraudDetectionService) updateConfig() gin.HandlerFunc {
	return func(c *gin.Context) {
		var config model.FraudDetectionConfig
		if err := c.ShouldBindJSON(&config); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// Forward config update to LumaDB ACM Detection Service
		payload, _ := json.Marshal(config)
		resp, err := s.httpClient.Post(
			s.lumadbEndpoint+"/acm/config",
			"application/json",
			bytes.NewBuffer(payload),
		)
		if err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"error": "failed to update config in LumaDB"})
			return
		}
		defer resp.Body.Close()

		c.JSON(http.StatusOK, gin.H{"status": "updated"})
	}
}

// healthCheck returns the health status of the fraud detection subsystem
func (s *FraudDetectionService) healthCheck() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Check LumaDB ACM Detection Service connectivity
		lumadbHealthy := false
		resp, err := s.httpClient.Get(s.lumadbEndpoint + "/health")
		if err == nil {
			lumadbHealthy = resp.StatusCode == http.StatusOK
			resp.Body.Close()
		}

		s.mu.RLock()
		activeCallCount := len(s.activeCalls)
		s.mu.RUnlock()

		status := "healthy"
		if !lumadbHealthy {
			status = "degraded"
		}

		c.JSON(http.StatusOK, gin.H{
			"status":            status,
			"lumadb_connected":  lumadbHealthy,
			"database":          "LumaDB",
			"active_call_count": activeCallCount,
			"timestamp":         time.Now().UTC().Format(time.RFC3339),
		})
	}
}
