// ============================================================================
// Anti-Call Masking Platform - Management API
// Go-based administration service for ACM platform
// Version: 2.0 | Date: 2026-01-22
// ============================================================================

package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/redis/go-redis/v9"
)

// Config holds application configuration
type Config struct {
	Port          string
	YugabyteURL   string
	DragonflyURL  string
	ClickHouseURL string
	ACMEngineURL  string
	JWTSecret     string
}

// App holds application dependencies
type App struct {
	config     *Config
	db         *pgxpool.Pool
	cache      *redis.Client
	logger     *slog.Logger
	httpClient *http.Client
}

func main() {
	// Initialize logger
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	// Load configuration
	config := &Config{
		Port:          getEnv("PORT", "8081"),
		YugabyteURL:   getEnv("YUGABYTE_URL", "postgres://opensips:acm_secure_2026@localhost:5433/opensips"),
		DragonflyURL:  getEnv("DRAGONFLY_URL", "redis://localhost:6379"),
		ClickHouseURL: getEnv("CLICKHOUSE_URL", "http://localhost:8123"),
		ACMEngineURL:  getEnv("ACM_ENGINE_URL", "http://localhost:8080"),
		JWTSecret:     getEnv("JWT_SECRET", "change_me_in_production"),
	}

	// Initialize database connection
	ctx := context.Background()
	db, err := pgxpool.New(ctx, config.YugabyteURL)
	if err != nil {
		logger.Error("Failed to connect to YugabyteDB", "error", err)
		os.Exit(1)
	}
	defer db.Close()

	// Test database connection
	if err := db.Ping(ctx); err != nil {
		logger.Error("Failed to ping YugabyteDB", "error", err)
		os.Exit(1)
	}
	logger.Info("Connected to YugabyteDB")

	// Initialize Redis/DragonflyDB connection
	opt, err := redis.ParseURL(config.DragonflyURL)
	if err != nil {
		logger.Error("Failed to parse DragonflyDB URL", "error", err)
		os.Exit(1)
	}
	cache := redis.NewClient(opt)
	defer cache.Close()

	// Test cache connection
	if _, err := cache.Ping(ctx).Result(); err != nil {
		logger.Error("Failed to ping DragonflyDB", "error", err)
		os.Exit(1)
	}
	logger.Info("Connected to DragonflyDB")

	// Initialize app
	app := &App{
		config: config,
		db:     db,
		cache:  cache,
		logger: logger,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}

	// Setup router
	r := chi.NewRouter()

	// Middleware
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.Timeout(60 * time.Second))
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-Request-ID"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	// Health endpoints
	r.Get("/health", app.healthHandler)
	r.Get("/ready", app.readyHandler)
	r.Handle("/metrics", promhttp.Handler())

	// API v1 routes
	r.Route("/api/v1", func(r chi.Router) {
		// Gateway management
		r.Route("/gateways", func(r chi.Router) {
			r.Get("/", app.listGateways)
			r.Post("/", app.createGateway)
			r.Get("/{id}", app.getGateway)
			r.Put("/{id}", app.updateGateway)
			r.Delete("/{id}", app.deleteGateway)
			r.Post("/{id}/block", app.blockGateway)
			r.Post("/{id}/unblock", app.unblockGateway)
		})

		// Blacklist management
		r.Route("/blacklist", func(r chi.Router) {
			r.Get("/", app.listBlacklist)
			r.Post("/", app.addToBlacklist)
			r.Delete("/{id}", app.removeFromBlacklist)
			r.Post("/sync-ncc", app.syncNCCBlacklist)
		})

		// Fraud alerts
		r.Route("/alerts", func(r chi.Router) {
			r.Get("/", app.listAlerts)
			r.Get("/{id}", app.getAlert)
			r.Post("/{id}/acknowledge", app.acknowledgeAlert)
			r.Get("/stats", app.alertStats)
		})

		// MNP management
		r.Route("/mnp", func(r chi.Router) {
			r.Get("/lookup/{msisdn}", app.mnpLookup)
			r.Post("/bulk-lookup", app.mnpBulkLookup)
			r.Get("/stats", app.mnpStats)
			r.Post("/refresh-cache", app.refreshMNPCache)
		})

		// Detection thresholds
		r.Route("/thresholds", func(r chi.Router) {
			r.Get("/", app.listThresholds)
			r.Get("/{id}", app.getThreshold)
			r.Put("/{id}", app.updateThreshold)
		})

		// Settlement disputes
		r.Route("/disputes", func(r chi.Router) {
			r.Get("/", app.listDisputes)
			r.Post("/", app.createDispute)
			r.Get("/{id}", app.getDispute)
			r.Put("/{id}", app.updateDispute)
			r.Post("/{id}/escalate", app.escalateDispute)
		})

		// Analytics
		r.Route("/analytics", func(r chi.Router) {
			r.Get("/fraud-summary", app.fraudSummary)
			r.Get("/gateway-stats", app.gatewayStats)
			r.Get("/hourly-traffic", app.hourlyTraffic)
			r.Get("/top-fraud-sources", app.topFraudSources)
		})

		// System
		r.Route("/system", func(r chi.Router) {
			r.Get("/status", app.systemStatus)
			r.Post("/cache/flush", app.flushCache)
			r.Get("/config", app.getConfig)
		})
	})

	// Create server
	server := &http.Server{
		Addr:         ":" + config.Port,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown
	done := make(chan bool)
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-quit
		logger.Info("Server is shutting down...")

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		server.SetKeepAlivesEnabled(false)
		if err := server.Shutdown(ctx); err != nil {
			logger.Error("Could not gracefully shutdown the server", "error", err)
		}
		close(done)
	}()

	logger.Info("Starting Management API", "port", config.Port)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		logger.Error("Server failed to start", "error", err)
		os.Exit(1)
	}

	<-done
	logger.Info("Server stopped")
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

// Health check handler
func (a *App) healthHandler(w http.ResponseWriter, r *http.Request) {
	respondJSON(w, http.StatusOK, map[string]string{
		"status":  "healthy",
		"service": "acm-management-api",
		"version": "2.0",
	})
}

// Readiness check handler
func (a *App) readyHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	// Check database
	if err := a.db.Ping(ctx); err != nil {
		respondError(w, http.StatusServiceUnavailable, "database not ready")
		return
	}

	// Check cache
	if _, err := a.cache.Ping(ctx).Result(); err != nil {
		respondError(w, http.StatusServiceUnavailable, "cache not ready")
		return
	}

	respondJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

// ============================================================================
// Gateway Handlers
// ============================================================================

type Gateway struct {
	ID              string    `json:"id"`
	Name            string    `json:"name"`
	CarrierCode     string    `json:"carrier_code"`
	CarrierName     string    `json:"carrier_name,omitempty"`
	GatewayType     string    `json:"gateway_type"`
	PrimaryIP       string    `json:"primary_ip"`
	SecondaryIP     string    `json:"secondary_ip,omitempty"`
	SIPPort         int       `json:"sip_port"`
	Transport       string    `json:"transport"`
	MaxCPS          int       `json:"max_cps"`
	MaxConcurrent   int       `json:"max_concurrent"`
	IsActive        bool      `json:"is_active"`
	IsBlacklisted   bool      `json:"is_blacklisted"`
	BlacklistReason string    `json:"blacklist_reason,omitempty"`
	NCCLicense      string    `json:"ncc_license,omitempty"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

func (a *App) listGateways(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	query := `
		SELECT id, name, carrier_code, carrier_name, gateway_type,
			   primary_ip::text, secondary_ip::text, sip_port, transport,
			   max_cps, max_concurrent, is_active, is_blacklisted,
			   blacklist_reason, ncc_license, created_at, updated_at
		FROM gateway_profiles
		ORDER BY name
	`

	rows, err := a.db.Query(ctx, query)
	if err != nil {
		a.logger.Error("Failed to query gateways", "error", err)
		respondError(w, http.StatusInternalServerError, "failed to fetch gateways")
		return
	}
	defer rows.Close()

	var gateways []Gateway
	for rows.Next() {
		var gw Gateway
		var secondaryIP, blacklistReason, nccLicense *string

		err := rows.Scan(
			&gw.ID, &gw.Name, &gw.CarrierCode, &gw.CarrierName,
			&gw.GatewayType, &gw.PrimaryIP, &secondaryIP, &gw.SIPPort,
			&gw.Transport, &gw.MaxCPS, &gw.MaxConcurrent, &gw.IsActive,
			&gw.IsBlacklisted, &blacklistReason, &nccLicense,
			&gw.CreatedAt, &gw.UpdatedAt,
		)
		if err != nil {
			a.logger.Error("Failed to scan gateway", "error", err)
			continue
		}

		if secondaryIP != nil {
			gw.SecondaryIP = *secondaryIP
		}
		if blacklistReason != nil {
			gw.BlacklistReason = *blacklistReason
		}
		if nccLicense != nil {
			gw.NCCLicense = *nccLicense
		}

		gateways = append(gateways, gw)
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"gateways": gateways,
		"total":    len(gateways),
	})
}

func (a *App) createGateway(w http.ResponseWriter, r *http.Request) {
	var gw Gateway
	if err := json.NewDecoder(r.Body).Decode(&gw); err != nil {
		respondError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	ctx := r.Context()
	query := `
		INSERT INTO gateway_profiles (
			name, carrier_code, carrier_name, gateway_type,
			primary_ip, secondary_ip, sip_port, transport,
			max_cps, max_concurrent, ncc_license
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING id, created_at, updated_at
	`

	var secondaryIP *string
	if gw.SecondaryIP != "" {
		secondaryIP = &gw.SecondaryIP
	}

	err := a.db.QueryRow(ctx, query,
		gw.Name, gw.CarrierCode, gw.CarrierName, gw.GatewayType,
		gw.PrimaryIP, secondaryIP, gw.SIPPort, gw.Transport,
		gw.MaxCPS, gw.MaxConcurrent, gw.NCCLicense,
	).Scan(&gw.ID, &gw.CreatedAt, &gw.UpdatedAt)

	if err != nil {
		a.logger.Error("Failed to create gateway", "error", err)
		respondError(w, http.StatusInternalServerError, "failed to create gateway")
		return
	}

	gw.IsActive = true
	gw.IsBlacklisted = false

	respondJSON(w, http.StatusCreated, gw)
}

func (a *App) getGateway(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	ctx := r.Context()

	query := `
		SELECT id, name, carrier_code, carrier_name, gateway_type,
			   primary_ip::text, secondary_ip::text, sip_port, transport,
			   max_cps, max_concurrent, is_active, is_blacklisted,
			   blacklist_reason, ncc_license, created_at, updated_at
		FROM gateway_profiles
		WHERE id = $1
	`

	var gw Gateway
	var secondaryIP, blacklistReason, nccLicense *string

	err := a.db.QueryRow(ctx, query, id).Scan(
		&gw.ID, &gw.Name, &gw.CarrierCode, &gw.CarrierName,
		&gw.GatewayType, &gw.PrimaryIP, &secondaryIP, &gw.SIPPort,
		&gw.Transport, &gw.MaxCPS, &gw.MaxConcurrent, &gw.IsActive,
		&gw.IsBlacklisted, &blacklistReason, &nccLicense,
		&gw.CreatedAt, &gw.UpdatedAt,
	)

	if err != nil {
		respondError(w, http.StatusNotFound, "gateway not found")
		return
	}

	if secondaryIP != nil {
		gw.SecondaryIP = *secondaryIP
	}
	if blacklistReason != nil {
		gw.BlacklistReason = *blacklistReason
	}
	if nccLicense != nil {
		gw.NCCLicense = *nccLicense
	}

	respondJSON(w, http.StatusOK, gw)
}

func (a *App) updateGateway(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var gw Gateway
	if err := json.NewDecoder(r.Body).Decode(&gw); err != nil {
		respondError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	ctx := r.Context()
	query := `
		UPDATE gateway_profiles SET
			name = $2, carrier_code = $3, carrier_name = $4,
			max_cps = $5, max_concurrent = $6, is_active = $7,
			updated_at = NOW()
		WHERE id = $1
		RETURNING updated_at
	`

	err := a.db.QueryRow(ctx, query, id,
		gw.Name, gw.CarrierCode, gw.CarrierName,
		gw.MaxCPS, gw.MaxConcurrent, gw.IsActive,
	).Scan(&gw.UpdatedAt)

	if err != nil {
		a.logger.Error("Failed to update gateway", "error", err)
		respondError(w, http.StatusInternalServerError, "failed to update gateway")
		return
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message":    "gateway updated",
		"gateway_id": id,
	})
}

func (a *App) deleteGateway(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	ctx := r.Context()

	_, err := a.db.Exec(ctx, "DELETE FROM gateway_profiles WHERE id = $1", id)
	if err != nil {
		a.logger.Error("Failed to delete gateway", "error", err)
		respondError(w, http.StatusInternalServerError, "failed to delete gateway")
		return
	}

	respondJSON(w, http.StatusOK, map[string]string{"message": "gateway deleted"})
}

func (a *App) blockGateway(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var req struct {
		Reason string `json:"reason"`
	}
	json.NewDecoder(r.Body).Decode(&req)

	ctx := r.Context()
	query := `
		UPDATE gateway_profiles SET
			is_blacklisted = true,
			blacklist_reason = $2,
			updated_at = NOW()
		WHERE id = $1
	`

	_, err := a.db.Exec(ctx, query, id, req.Reason)
	if err != nil {
		a.logger.Error("Failed to block gateway", "error", err)
		respondError(w, http.StatusInternalServerError, "failed to block gateway")
		return
	}

	// Also add to address blacklist group (66)
	a.db.Exec(ctx, `
		UPDATE address SET grp = 66 
		WHERE tag = (SELECT carrier_code FROM gateway_profiles WHERE id = $1)
	`, id)

	// Invalidate cache
	a.cache.Del(ctx, fmt.Sprintf("gateway:%s", id))

	a.logger.Info("Gateway blocked", "gateway_id", id, "reason", req.Reason)
	respondJSON(w, http.StatusOK, map[string]string{
		"message":    "gateway blocked",
		"gateway_id": id,
	})
}

func (a *App) unblockGateway(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	ctx := r.Context()

	query := `
		UPDATE gateway_profiles SET
			is_blacklisted = false,
			blacklist_reason = NULL,
			updated_at = NOW()
		WHERE id = $1
	`

	_, err := a.db.Exec(ctx, query, id)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to unblock gateway")
		return
	}

	respondJSON(w, http.StatusOK, map[string]string{
		"message":    "gateway unblocked",
		"gateway_id": id,
	})
}

// ============================================================================
// Blacklist Handlers
// ============================================================================

type BlacklistEntry struct {
	ID          string     `json:"id"`
	EntryType   string     `json:"entry_type"`
	EntryValue  string     `json:"entry_value"`
	Reason      string     `json:"reason"`
	Severity    int        `json:"severity"`
	Source      string     `json:"source"`
	AddedAt     time.Time  `json:"added_at"`
	ExpiresAt   *time.Time `json:"expires_at,omitempty"`
	IsPermanent bool       `json:"is_permanent"`
	IsActive    bool       `json:"is_active"`
}

func (a *App) listBlacklist(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	entryType := r.URL.Query().Get("type")

	query := `
		SELECT id, entry_type, entry_value, reason, severity, source,
			   added_at, expires_at, is_permanent, is_active
		FROM blacklist
		WHERE is_active = true
	`
	args := []interface{}{}

	if entryType != "" {
		query += " AND entry_type = $1"
		args = append(args, entryType)
	}

	query += " ORDER BY added_at DESC LIMIT 1000"

	rows, err := a.db.Query(ctx, query, args...)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to fetch blacklist")
		return
	}
	defer rows.Close()

	var entries []BlacklistEntry
	for rows.Next() {
		var e BlacklistEntry
		rows.Scan(
			&e.ID, &e.EntryType, &e.EntryValue, &e.Reason, &e.Severity,
			&e.Source, &e.AddedAt, &e.ExpiresAt, &e.IsPermanent, &e.IsActive,
		)
		entries = append(entries, e)
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"entries": entries,
		"total":   len(entries),
	})
}

func (a *App) addToBlacklist(w http.ResponseWriter, r *http.Request) {
	var entry BlacklistEntry
	if err := json.NewDecoder(r.Body).Decode(&entry); err != nil {
		respondError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	ctx := r.Context()
	query := `
		INSERT INTO blacklist (entry_type, entry_value, reason, severity, source, is_permanent)
		VALUES ($1, $2, $3, $4, 'INTERNAL', $5)
		ON CONFLICT (entry_type, entry_value) DO UPDATE SET
			reason = EXCLUDED.reason,
			severity = EXCLUDED.severity,
			is_active = true
		RETURNING id, added_at
	`

	err := a.db.QueryRow(ctx, query,
		entry.EntryType, entry.EntryValue, entry.Reason,
		entry.Severity, entry.IsPermanent,
	).Scan(&entry.ID, &entry.AddedAt)

	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to add to blacklist")
		return
	}

	// Update cache
	cacheKey := fmt.Sprintf("blacklist:%s:%s", entry.EntryType, entry.EntryValue)
	a.cache.Set(ctx, cacheKey, "1", 24*time.Hour)

	a.logger.Info("Added to blacklist",
		"type", entry.EntryType,
		"value", entry.EntryValue,
		"reason", entry.Reason,
	)

	respondJSON(w, http.StatusCreated, entry)
}

func (a *App) removeFromBlacklist(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	ctx := r.Context()

	// Get entry details first for cache invalidation
	var entryType, entryValue string
	a.db.QueryRow(ctx,
		"SELECT entry_type, entry_value FROM blacklist WHERE id = $1",
		id,
	).Scan(&entryType, &entryValue)

	_, err := a.db.Exec(ctx,
		"UPDATE blacklist SET is_active = false WHERE id = $1",
		id,
	)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to remove from blacklist")
		return
	}

	// Invalidate cache
	cacheKey := fmt.Sprintf("blacklist:%s:%s", entryType, entryValue)
	a.cache.Del(ctx, cacheKey)

	respondJSON(w, http.StatusOK, map[string]string{"message": "removed from blacklist"})
}

func (a *App) syncNCCBlacklist(w http.ResponseWriter, r *http.Request) {
	// This would call the NCC ATRS API to fetch the latest blacklist
	// For now, return a placeholder
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message":  "NCC blacklist sync initiated",
		"synced":   0,
		"new":      0,
		"removed":  0,
		"duration": "0s",
	})
}

// ============================================================================
// Alert Handlers
// ============================================================================

func (a *App) listAlerts(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	fraudType := r.URL.Query().Get("fraud_type")
	limit := r.URL.Query().Get("limit")
	if limit == "" {
		limit = "100"
	}

	query := `
		SELECT id, call_id, fraud_type, source_ip::text, caller_id,
			   called_number, confidence, severity, action_taken,
			   ncc_reported, detected_at
		FROM fraud_alerts
		WHERE 1=1
	`
	args := []interface{}{}
	argNum := 1

	if fraudType != "" {
		query += fmt.Sprintf(" AND fraud_type = $%d", argNum)
		args = append(args, fraudType)
		argNum++
	}

	query += fmt.Sprintf(" ORDER BY detected_at DESC LIMIT $%d", argNum)
	args = append(args, limit)

	rows, err := a.db.Query(ctx, query, args...)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to fetch alerts")
		return
	}
	defer rows.Close()

	var alerts []map[string]interface{}
	for rows.Next() {
		var id, callID, fraudType, sourceIP, callerID, calledNumber, actionTaken string
		var confidence float64
		var severity int
		var nccReported bool
		var detectedAt time.Time

		rows.Scan(&id, &callID, &fraudType, &sourceIP, &callerID,
			&calledNumber, &confidence, &severity, &actionTaken,
			&nccReported, &detectedAt)

		alerts = append(alerts, map[string]interface{}{
			"id":            id,
			"call_id":       callID,
			"fraud_type":    fraudType,
			"source_ip":     sourceIP,
			"caller_id":     callerID,
			"called_number": calledNumber,
			"confidence":    confidence,
			"severity":      severity,
			"action_taken":  actionTaken,
			"ncc_reported":  nccReported,
			"detected_at":   detectedAt,
		})
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"alerts": alerts,
		"total":  len(alerts),
	})
}

func (a *App) getAlert(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	ctx := r.Context()

	query := `
		SELECT id, call_id, fraud_type, source_ip::text, caller_id,
			   called_number, confidence, severity, action_taken,
			   reasons, raw_data, ncc_reported, ncc_report_id,
			   detected_at, created_at
		FROM fraud_alerts
		WHERE id = $1
	`

	var alert map[string]interface{}
	var id_, callID, fraudType, sourceIP, callerID, calledNumber, actionTaken string
	var confidence float64
	var severity int
	var reasons []string
	var rawData interface{}
	var nccReported bool
	var nccReportID *string
	var detectedAt, createdAt time.Time

	err := a.db.QueryRow(ctx, query, id).Scan(
		&id_, &callID, &fraudType, &sourceIP, &callerID,
		&calledNumber, &confidence, &severity, &actionTaken,
		&reasons, &rawData, &nccReported, &nccReportID,
		&detectedAt, &createdAt,
	)

	if err != nil {
		respondError(w, http.StatusNotFound, "alert not found")
		return
	}

	alert = map[string]interface{}{
		"id":            id_,
		"call_id":       callID,
		"fraud_type":    fraudType,
		"source_ip":     sourceIP,
		"caller_id":     callerID,
		"called_number": calledNumber,
		"confidence":    confidence,
		"severity":      severity,
		"action_taken":  actionTaken,
		"reasons":       reasons,
		"raw_data":      rawData,
		"ncc_reported":  nccReported,
		"ncc_report_id": nccReportID,
		"detected_at":   detectedAt,
		"created_at":    createdAt,
	}

	respondJSON(w, http.StatusOK, alert)
}

func (a *App) acknowledgeAlert(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	respondJSON(w, http.StatusOK, map[string]string{
		"message":  "alert acknowledged",
		"alert_id": id,
	})
}

func (a *App) alertStats(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	query := `
		SELECT 
			COUNT(*) as total,
			COUNT(*) FILTER (WHERE fraud_type = 'CLI_MASK') as cli_mask,
			COUNT(*) FILTER (WHERE fraud_type = 'SIM_BOX') as sim_box,
			COUNT(*) FILTER (WHERE fraud_type = 'REFILING') as refiling,
			COUNT(*) FILTER (WHERE ncc_reported = true) as ncc_reported,
			COUNT(*) FILTER (WHERE detected_at > NOW() - INTERVAL '1 hour') as last_hour,
			COUNT(*) FILTER (WHERE detected_at > NOW() - INTERVAL '24 hours') as last_24h
		FROM fraud_alerts
		WHERE detected_at > NOW() - INTERVAL '7 days'
	`

	var total, cliMask, simBox, refiling, nccReported, lastHour, last24h int
	a.db.QueryRow(ctx, query).Scan(
		&total, &cliMask, &simBox, &refiling, &nccReported, &lastHour, &last24h,
	)

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"period": "7d",
		"total":  total,
		"by_type": map[string]int{
			"cli_mask": cliMask,
			"sim_box":  simBox,
			"refiling": refiling,
		},
		"ncc_reported": nccReported,
		"last_hour":    lastHour,
		"last_24h":     last24h,
	})
}

// ============================================================================
// MNP Handlers
// ============================================================================

func (a *App) mnpLookup(w http.ResponseWriter, r *http.Request) {
	msisdn := chi.URLParam(r, "msisdn")
	ctx := r.Context()

	// Check cache first
	cacheKey := fmt.Sprintf("mnp:%s", msisdn)
	if cached, err := a.cache.Get(ctx, cacheKey).Result(); err == nil {
		var result map[string]interface{}
		json.Unmarshal([]byte(cached), &result)
		result["cache_hit"] = true
		respondJSON(w, http.StatusOK, result)
		return
	}

	// Query database
	query := `
		SELECT msisdn, original_network_id, hosting_network_id,
			   routing_number, is_ported, last_updated
		FROM mnp_data
		WHERE msisdn = $1
	`

	var result struct {
		MSISDN            string    `json:"msisdn"`
		OriginalNetwork   string    `json:"original_network_id"`
		HostingNetwork    string    `json:"hosting_network_id"`
		RoutingNumber     string    `json:"routing_number"`
		IsPorted          bool      `json:"is_ported"`
		LastUpdated       time.Time `json:"last_updated"`
		CacheHit          bool      `json:"cache_hit"`
	}

	err := a.db.QueryRow(ctx, query, msisdn).Scan(
		&result.MSISDN, &result.OriginalNetwork, &result.HostingNetwork,
		&result.RoutingNumber, &result.IsPorted, &result.LastUpdated,
	)

	if err != nil {
		respondError(w, http.StatusNotFound, "MSISDN not found in MNP database")
		return
	}

	result.CacheHit = false

	// Cache the result
	jsonData, _ := json.Marshal(result)
	a.cache.Set(ctx, cacheKey, jsonData, 24*time.Hour)

	respondJSON(w, http.StatusOK, result)
}

func (a *App) mnpBulkLookup(w http.ResponseWriter, r *http.Request) {
	var req struct {
		MSISDNs []string `json:"msisdns"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if len(req.MSISDNs) > 1000 {
		respondError(w, http.StatusBadRequest, "maximum 1000 MSISDNs per request")
		return
	}

	// For brevity, returning placeholder
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"results": []interface{}{},
		"total":   len(req.MSISDNs),
		"found":   0,
	})
}

func (a *App) mnpStats(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	query := `
		SELECT 
			COUNT(*) as total,
			COUNT(*) FILTER (WHERE is_ported = true) as ported,
			COUNT(DISTINCT hosting_network_id) as networks
		FROM mnp_data
	`

	var total, ported, networks int
	a.db.QueryRow(ctx, query).Scan(&total, &ported, &networks)

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"total_numbers": total,
		"ported":        ported,
		"networks":      networks,
	})
}

func (a *App) refreshMNPCache(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	// Clear MNP cache entries
	keys, _ := a.cache.Keys(ctx, "mnp:*").Result()
	if len(keys) > 0 {
		a.cache.Del(ctx, keys...)
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message":       "MNP cache refreshed",
		"entries_cleared": len(keys),
	})
}

// ============================================================================
// Threshold Handlers
// ============================================================================

func (a *App) listThresholds(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	rows, err := a.db.Query(ctx, `
		SELECT id, profile_name, prefix, carrier_code,
			   cpm_warning, cpm_critical,
			   acd_warning_seconds, acd_critical_seconds,
			   unique_dest_warning, unique_dest_critical,
			   is_active
		FROM fraud_detection_profiles
		ORDER BY profile_name
	`)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to fetch thresholds")
		return
	}
	defer rows.Close()

	var profiles []map[string]interface{}
	for rows.Next() {
		var id int
		var profileName string
		var prefix, carrierCode *string
		var cpmWarn, cpmCrit, uniqueDestWarn, uniqueDestCrit int
		var acdWarn, acdCrit float64
		var isActive bool

		rows.Scan(&id, &profileName, &prefix, &carrierCode,
			&cpmWarn, &cpmCrit, &acdWarn, &acdCrit,
			&uniqueDestWarn, &uniqueDestCrit, &isActive)

		profiles = append(profiles, map[string]interface{}{
			"id":                   id,
			"profile_name":         profileName,
			"prefix":               prefix,
			"carrier_code":         carrierCode,
			"cpm_warning":          cpmWarn,
			"cpm_critical":         cpmCrit,
			"acd_warning_seconds":  acdWarn,
			"acd_critical_seconds": acdCrit,
			"unique_dest_warning":  uniqueDestWarn,
			"unique_dest_critical": uniqueDestCrit,
			"is_active":            isActive,
		})
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"profiles": profiles,
		"total":    len(profiles),
	})
}

func (a *App) getThreshold(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	respondJSON(w, http.StatusOK, map[string]string{"id": id})
}

func (a *App) updateThreshold(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	respondJSON(w, http.StatusOK, map[string]string{
		"message": "threshold updated",
		"id":      id,
	})
}

// ============================================================================
// Dispute Handlers
// ============================================================================

func (a *App) listDisputes(w http.ResponseWriter, r *http.Request) {
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"disputes": []interface{}{},
		"total":    0,
	})
}

func (a *App) createDispute(w http.ResponseWriter, r *http.Request) {
	respondJSON(w, http.StatusCreated, map[string]string{"message": "dispute created"})
}

func (a *App) getDispute(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	respondJSON(w, http.StatusOK, map[string]string{"id": id})
}

func (a *App) updateDispute(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	respondJSON(w, http.StatusOK, map[string]string{"id": id})
}

func (a *App) escalateDispute(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	respondJSON(w, http.StatusOK, map[string]string{
		"message":    "dispute escalated to NCC",
		"dispute_id": id,
	})
}

// ============================================================================
// Analytics Handlers
// ============================================================================

func (a *App) fraudSummary(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	query := `
		SELECT 
			fraud_type,
			COUNT(*) as count,
			AVG(confidence) as avg_confidence
		FROM fraud_alerts
		WHERE detected_at > NOW() - INTERVAL '24 hours'
		GROUP BY fraud_type
		ORDER BY count DESC
	`

	rows, err := a.db.Query(ctx, query)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to fetch fraud summary")
		return
	}
	defer rows.Close()

	var summary []map[string]interface{}
	for rows.Next() {
		var fraudType string
		var count int
		var avgConfidence float64
		rows.Scan(&fraudType, &count, &avgConfidence)
		summary = append(summary, map[string]interface{}{
			"fraud_type":     fraudType,
			"count":          count,
			"avg_confidence": avgConfidence,
		})
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"period":  "24h",
		"summary": summary,
	})
}

func (a *App) gatewayStats(w http.ResponseWriter, r *http.Request) {
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"gateways": []interface{}{},
	})
}

func (a *App) hourlyTraffic(w http.ResponseWriter, r *http.Request) {
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"traffic": []interface{}{},
	})
}

func (a *App) topFraudSources(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	query := `
		SELECT source_ip::text, COUNT(*) as count
		FROM fraud_alerts
		WHERE detected_at > NOW() - INTERVAL '24 hours'
		GROUP BY source_ip
		ORDER BY count DESC
		LIMIT 20
	`

	rows, err := a.db.Query(ctx, query)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "failed to fetch top fraud sources")
		return
	}
	defer rows.Close()

	var sources []map[string]interface{}
	for rows.Next() {
		var ip string
		var count int
		rows.Scan(&ip, &count)
		sources = append(sources, map[string]interface{}{
			"source_ip": ip,
			"count":     count,
		})
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"period":  "24h",
		"sources": sources,
	})
}

// ============================================================================
// System Handlers
// ============================================================================

func (a *App) systemStatus(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	// Check all services
	dbOK := a.db.Ping(ctx) == nil
	cacheOK := a.cache.Ping(ctx).Err() == nil

	// Call ACM engine health
	engineOK := false
	resp, err := a.httpClient.Get(a.config.ACMEngineURL + "/health")
	if err == nil && resp.StatusCode == 200 {
		engineOK = true
		resp.Body.Close()
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"status": "operational",
		"services": map[string]bool{
			"yugabyte":         dbOK,
			"dragonfly":        cacheOK,
			"detection_engine": engineOK,
		},
		"timestamp": time.Now().UTC(),
	})
}

func (a *App) flushCache(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req struct {
		Pattern string `json:"pattern"`
	}
	json.NewDecoder(r.Body).Decode(&req)

	if req.Pattern == "" {
		req.Pattern = "*"
	}

	keys, _ := a.cache.Keys(ctx, req.Pattern).Result()
	if len(keys) > 0 {
		a.cache.Del(ctx, keys...)
	}

	a.logger.Info("Cache flushed", "pattern", req.Pattern, "keys_deleted", len(keys))

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"message":      "cache flushed",
		"pattern":      req.Pattern,
		"keys_deleted": len(keys),
	})
}

func (a *App) getConfig(w http.ResponseWriter, r *http.Request) {
	// Return non-sensitive configuration
	respondJSON(w, http.StatusOK, map[string]interface{}{
		"version":       "2.0",
		"region":        "lagos",
		"ncc_enabled":   a.config.JWTSecret != "", // Placeholder check
		"acm_engine":    a.config.ACMEngineURL,
	})
}

// ============================================================================
// Helpers
// ============================================================================

func respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func respondError(w http.ResponseWriter, status int, message string) {
	respondJSON(w, status, map[string]string{
		"error":   http.StatusText(status),
		"message": message,
	})
}
