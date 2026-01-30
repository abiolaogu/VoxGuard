// Package config handles application configuration loading
package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config holds all application configuration
type Config struct {
	// Server settings
	Environment    string
	Port           int
	AllowedOrigins []string

	// Database connections
	YugabyteURL   string
	ClickHouseURL string
	DragonflyURL  string

	// Authentication
	JWTSecret string
	JWTExpiry time.Duration

	// NCC Compliance
	NCCEnabled      bool
	NCCClientID     string
	NCCClientSecret string
	NCCAPIBaseURL   string
	NCCSFTPHost     string
	NCCSFTPUser     string
	NCCSFTPKeyPath  string
	ICLLicenseID    string

	// Detection Engine
	DetectionEngineURL string

	// Rate Limiting
	RateLimitRequests int
	RateLimitWindow   time.Duration
}

// Load reads configuration from environment variables
func Load() (*Config, error) {
	cfg := &Config{
		Environment:    getEnv("ENVIRONMENT", "development"),
		Port:           getEnvInt("PORT", 8081),
		AllowedOrigins: getEnvSlice("ALLOWED_ORIGINS", []string{"http://localhost:3000"}),

		YugabyteURL:   getEnv("YUGABYTE_URL", "postgres://acm_admin:secure_password@yugabyte:5433/acm_db?sslmode=prefer"),
		ClickHouseURL: getEnv("CLICKHOUSE_URL", "http://clickhouse:8123"),
		DragonflyURL:  getEnv("DRAGONFLY_URL", "redis://dragonfly:6379/0"),

		JWTSecret: getEnv("JWT_SECRET", ""),
		JWTExpiry: getEnvDuration("JWT_EXPIRY", 24*time.Hour),

		NCCEnabled:      getEnvBool("NCC_ENABLED", true),
		NCCClientID:     getEnv("NCC_CLIENT_ID", ""),
		NCCClientSecret: getEnv("NCC_CLIENT_SECRET", ""),
		NCCAPIBaseURL:   getEnv("NCC_API_BASE_URL", "https://atrs-api.ncc.gov.ng/v1"),
		NCCSFTPHost:     getEnv("NCC_SFTP_HOST", "sftp.ncc.gov.ng"),
		NCCSFTPUser:     getEnv("NCC_SFTP_USER", ""),
		NCCSFTPKeyPath:  getEnv("NCC_SFTP_KEY_PATH", "/secrets/ncc-sftp-key"),
		ICLLicenseID:    getEnv("ICL_LICENSE_ID", ""),

		DetectionEngineURL: getEnv("DETECTION_ENGINE_URL", "http://acm-engine:8080"),

		RateLimitRequests: getEnvInt("RATE_LIMIT_REQUESTS", 100),
		RateLimitWindow:   getEnvDuration("RATE_LIMIT_WINDOW", time.Minute),
	}

	// Validate required configuration
	if cfg.JWTSecret == "" {
		return nil, fmt.Errorf("JWT_SECRET is required")
	}

	if cfg.NCCEnabled {
		if cfg.NCCClientID == "" || cfg.NCCClientSecret == "" {
			return nil, fmt.Errorf("NCC_CLIENT_ID and NCC_CLIENT_SECRET are required when NCC is enabled")
		}
		if cfg.ICLLicenseID == "" {
			return nil, fmt.Errorf("ICL_LICENSE_ID is required for NCC compliance")
		}
	}

	return cfg, nil
}

// Helper functions for environment variable parsing
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if i, err := strconv.Atoi(value); err == nil {
			return i
		}
	}
	return defaultValue
}

func getEnvBool(key string, defaultValue bool) bool {
	if value := os.Getenv(key); value != "" {
		return strings.ToLower(value) == "true" || value == "1"
	}
	return defaultValue
}

func getEnvDuration(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if d, err := time.ParseDuration(value); err == nil {
			return d
		}
	}
	return defaultValue
}

func getEnvSlice(key string, defaultValue []string) []string {
	if value := os.Getenv(key); value != "" {
		return strings.Split(value, ",")
	}
	return defaultValue
}

// Nigerian MNO Configuration
type MNOConfig struct {
	Name          string
	RoutingNumber string
	Prefixes      []string
}

// GetNigerianMNOs returns the list of Nigerian MNOs with their configurations (2026)
func GetNigerianMNOs() []MNOConfig {
	return []MNOConfig{
		{
			Name:          "MTN Nigeria",
			RoutingNumber: "D013",
			Prefixes: []string{
				"234703", "234706", "234803", "234806", "234810",
				"234813", "234814", "234816", "234903", "234906",
				"234913", "234916",
			},
		},
		{
			Name:          "Airtel Nigeria",
			RoutingNumber: "D018",
			Prefixes: []string{
				"234701", "234708", "234802", "234808", "234812",
				"234901", "234902", "234904", "234907", "234912",
			},
		},
		{
			Name:          "Globacom",
			RoutingNumber: "D015",
			Prefixes: []string{
				"234705", "234805", "234807", "234811", "234815",
				"234905", "234915",
			},
		},
		{
			Name:          "9mobile",
			RoutingNumber: "D019",
			Prefixes: []string{
				"234809", "234817", "234818", "234908", "234909",
			},
		},
	}
}
