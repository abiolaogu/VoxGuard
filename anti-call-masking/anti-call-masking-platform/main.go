// ACM Management API - Administrative dashboard backend
// Provides CRUD operations for gateway management, fraud analysis, and NCC compliance
package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/billyronks/acm-management-api/internal/config"
	"github.com/billyronks/acm-management-api/internal/database"
	"github.com/billyronks/acm-management-api/internal/handlers"
	"github.com/billyronks/acm-management-api/internal/middleware"
	"github.com/billyronks/acm-management-api/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.uber.org/zap"
)

// @title ACM Management API
// @version 2.0
// @description Administrative API for Nigerian Anti-Call Masking Platform
// @host localhost:8081
// @BasePath /api/v1
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
func main() {
	// Initialize logger
	logger, _ := zap.NewProduction()
	defer logger.Sync()
	sugar := logger.Sugar()

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		sugar.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize database connections
	db, err := database.NewPostgresPool(cfg.YugabyteURL)
	if err != nil {
		sugar.Fatalf("Failed to connect to YugabyteDB: %v", err)
	}
	defer db.Close()

	clickhouse, err := database.NewClickHouseClient(cfg.ClickHouseURL)
	if err != nil {
		sugar.Fatalf("Failed to connect to ClickHouse: %v", err)
	}
	defer clickhouse.Close()

	redis, err := database.NewRedisClient(cfg.DragonflyURL)
	if err != nil {
		sugar.Fatalf("Failed to connect to DragonflyDB: %v", err)
	}
	defer redis.Close()

	// Initialize services
	authService := services.NewAuthService(cfg.JWTSecret, cfg.JWTExpiry)
	gatewayService := services.NewGatewayService(db, redis)
	fraudService := services.NewFraudService(db, clickhouse, redis)
	mnpService := services.NewMNPService(db, redis)
	complianceService := services.NewComplianceService(db, clickhouse, cfg)
	analyticsService := services.NewAnalyticsService(clickhouse, redis)
	auditService := services.NewAuditService(db)

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(authService, auditService)
	gatewayHandler := handlers.NewGatewayHandler(gatewayService, auditService)
	fraudHandler := handlers.NewFraudHandler(fraudService)
	mnpHandler := handlers.NewMNPHandler(mnpService, auditService)
	complianceHandler := handlers.NewComplianceHandler(complianceService)
	analyticsHandler := handlers.NewAnalyticsHandler(analyticsService)
	dashboardHandler := handlers.NewDashboardHandler(fraudService, gatewayService, analyticsService)

	// Configure Gin
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(middleware.Logger(logger))
	router.Use(middleware.CORS(cfg.AllowedOrigins))
	router.Use(middleware.RateLimiter(redis, 100, time.Minute))

	// Health endpoints
	router.GET("/health", handlers.HealthCheck)
	router.GET("/ready", func(c *gin.Context) {
		if err := db.Ping(c.Request.Context()); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"status": "unhealthy", "error": "database"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "healthy"})
	})

	// Metrics endpoint
	router.GET("/metrics", gin.WrapH(promhttp.Handler()))

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// Authentication (public)
		auth := v1.Group("/auth")
		{
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh", authHandler.RefreshToken)
			auth.POST("/logout", authHandler.Logout)
		}

		// Protected routes
		protected := v1.Group("")
		protected.Use(middleware.JWTAuth(authService))
		{
			// Dashboard
			dashboard := protected.Group("/dashboard")
			{
				dashboard.GET("/summary", dashboardHandler.GetSummary)
				dashboard.GET("/realtime", dashboardHandler.GetRealtimeStats)
				dashboard.GET("/trends", dashboardHandler.GetTrends)
			}

			// Gateway Management
			gateways := protected.Group("/gateways")
			{
				gateways.GET("", gatewayHandler.List)
				gateways.POST("", middleware.RequireRole("admin"), gatewayHandler.Create)
				gateways.GET("/:id", gatewayHandler.Get)
				gateways.PUT("/:id", middleware.RequireRole("admin"), gatewayHandler.Update)
				gateways.DELETE("/:id", middleware.RequireRole("admin"), gatewayHandler.Delete)
				gateways.GET("/:id/stats", gatewayHandler.GetStats)
				gateways.POST("/:id/enable", middleware.RequireRole("admin"), gatewayHandler.Enable)
				gateways.POST("/:id/disable", middleware.RequireRole("admin"), gatewayHandler.Disable)
			}

			// Fraud Detection
			fraud := protected.Group("/fraud")
			{
				fraud.GET("/alerts", fraudHandler.ListAlerts)
				fraud.GET("/alerts/:id", fraudHandler.GetAlert)
				fraud.POST("/alerts/:id/acknowledge", fraudHandler.AcknowledgeAlert)
				fraud.POST("/alerts/:id/resolve", fraudHandler.ResolveAlert)
				fraud.GET("/simbox-suspects", fraudHandler.ListSimBoxSuspects)
				fraud.GET("/patterns", fraudHandler.GetPatterns)
				fraud.GET("/heatmap", fraudHandler.GetHeatmap)
			}

			// MNP Management
			mnp := protected.Group("/mnp")
			{
				mnp.GET("/lookup/:msisdn", mnpHandler.Lookup)
				mnp.POST("/bulk-lookup", mnpHandler.BulkLookup)
				mnp.GET("/stats", mnpHandler.GetStats)
				mnp.POST("/import", middleware.RequireRole("admin"), mnpHandler.ImportMNPData)
			}

			// Blacklist Management
			blacklist := protected.Group("/blacklist")
			{
				blacklist.GET("", fraudHandler.ListBlacklist)
				blacklist.POST("", middleware.RequireRole("admin"), fraudHandler.AddToBlacklist)
				blacklist.DELETE("/:id", middleware.RequireRole("admin"), fraudHandler.RemoveFromBlacklist)
				blacklist.POST("/sync-ncc", middleware.RequireRole("admin"), fraudHandler.SyncNCCBlacklist)
			}

			// NCC Compliance
			compliance := protected.Group("/compliance")
			{
				compliance.GET("/reports", complianceHandler.ListReports)
				compliance.GET("/reports/:id", complianceHandler.GetReport)
				compliance.POST("/reports/generate", middleware.RequireRole("admin"), complianceHandler.GenerateReport)
				compliance.GET("/audit-trail", complianceHandler.GetAuditTrail)
				compliance.GET("/settlement-disputes", complianceHandler.ListDisputes)
				compliance.POST("/settlement-disputes", complianceHandler.CreateDispute)
			}

			// Analytics
			analytics := protected.Group("/analytics")
			{
				analytics.GET("/cdr-summary", analyticsHandler.GetCDRSummary)
				analytics.GET("/traffic-analysis", analyticsHandler.GetTrafficAnalysis)
				analytics.GET("/fraud-trends", analyticsHandler.GetFraudTrends)
				analytics.GET("/gateway-performance", analyticsHandler.GetGatewayPerformance)
				analytics.POST("/export", analyticsHandler.ExportData)
			}

			// User Management (admin only)
			users := protected.Group("/users")
			users.Use(middleware.RequireRole("admin"))
			{
				users.GET("", authHandler.ListUsers)
				users.POST("", authHandler.CreateUser)
				users.PUT("/:id", authHandler.UpdateUser)
				users.DELETE("/:id", authHandler.DeleteUser)
			}
		}
	}

	// Create HTTP server
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.Port),
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown
	go func() {
		sugar.Infof("Management API starting on port %d", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			sugar.Fatalf("Server error: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	sugar.Info("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		sugar.Fatalf("Server forced to shutdown: %v", err)
	}

	sugar.Info("Server exited")
}
