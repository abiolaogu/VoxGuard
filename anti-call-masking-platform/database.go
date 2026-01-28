// Package database provides database connection management
package database

import (
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

// PostgresPool wraps pgxpool for YugabyteDB connections
type PostgresPool struct {
	pool *pgxpool.Pool
}

// NewPostgresPool creates a new connection pool to YugabyteDB
func NewPostgresPool(connString string) (*PostgresPool, error) {
	config, err := pgxpool.ParseConfig(connString)
	if err != nil {
		return nil, fmt.Errorf("parse connection string: %w", err)
	}

	// Connection pool settings optimized for high throughput
	config.MaxConns = 50
	config.MinConns = 10
	config.MaxConnLifetime = time.Hour
	config.MaxConnIdleTime = 30 * time.Minute
	config.HealthCheckPeriod = 30 * time.Second

	pool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		return nil, fmt.Errorf("create connection pool: %w", err)
	}

	// Verify connection
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("ping database: %w", err)
	}

	return &PostgresPool{pool: pool}, nil
}

// Close closes the connection pool
func (p *PostgresPool) Close() {
	p.pool.Close()
}

// Ping checks database connectivity
func (p *PostgresPool) Ping(ctx context.Context) error {
	return p.pool.Ping(ctx)
}

// Pool returns the underlying pgxpool for direct access
func (p *PostgresPool) Pool() *pgxpool.Pool {
	return p.pool
}

// ClickHouseClient provides HTTP-based ClickHouse access
type ClickHouseClient struct {
	baseURL    string
	httpClient *http.Client
}

// NewClickHouseClient creates a new ClickHouse HTTP client
func NewClickHouseClient(baseURL string) (*ClickHouseClient, error) {
	client := &ClickHouseClient{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
			Transport: &http.Transport{
				MaxIdleConns:        100,
				MaxIdleConnsPerHost: 100,
				IdleConnTimeout:     90 * time.Second,
			},
		},
	}

	// Verify connection
	if err := client.Ping(); err != nil {
		return nil, fmt.Errorf("ping ClickHouse: %w", err)
	}

	return client, nil
}

// Ping checks ClickHouse connectivity
func (c *ClickHouseClient) Ping() error {
	resp, err := c.httpClient.Get(c.baseURL + "/ping")
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}
	return nil
}

// Query executes a ClickHouse query and returns results
func (c *ClickHouseClient) Query(ctx context.Context, query string) (*http.Response, error) {
	req, err := http.NewRequestWithContext(ctx, "POST", c.baseURL+"/", nil)
	if err != nil {
		return nil, err
	}

	q := req.URL.Query()
	q.Add("query", query)
	req.URL.RawQuery = q.Encode()

	return c.httpClient.Do(req)
}

// Close closes the HTTP client (no-op for HTTP client)
func (c *ClickHouseClient) Close() error {
	return nil
}

// BaseURL returns the configured base URL
func (c *ClickHouseClient) BaseURL() string {
	return c.baseURL
}

// RedisClient wraps go-redis for DragonflyDB connections
type RedisClient struct {
	client *redis.Client
}

// NewRedisClient creates a new DragonflyDB/Redis client
func NewRedisClient(connString string) (*RedisClient, error) {
	opt, err := redis.ParseURL(connString)
	if err != nil {
		return nil, fmt.Errorf("parse redis URL: %w", err)
	}

	// Connection settings
	opt.PoolSize = 100
	opt.MinIdleConns = 10
	opt.MaxRetries = 3
	opt.DialTimeout = 5 * time.Second
	opt.ReadTimeout = 3 * time.Second
	opt.WriteTimeout = 3 * time.Second

	client := redis.NewClient(opt)

	// Verify connection
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("ping DragonflyDB: %w", err)
	}

	return &RedisClient{client: client}, nil
}

// Close closes the Redis client
func (r *RedisClient) Close() error {
	return r.client.Close()
}

// Client returns the underlying redis.Client
func (r *RedisClient) Client() *redis.Client {
	return r.client
}

// Common query helpers

// NullString handles nullable string columns
type NullString struct {
	sql.NullString
}

// NullInt64 handles nullable int64 columns
type NullInt64 struct {
	sql.NullInt64
}

// NullTime handles nullable time columns
type NullTime struct {
	sql.NullTime
}

// Pagination parameters
type Pagination struct {
	Page     int
	PageSize int
	Offset   int
}

// NewPagination creates pagination with defaults
func NewPagination(page, pageSize int) Pagination {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	if pageSize > 100 {
		pageSize = 100
	}
	return Pagination{
		Page:     page,
		PageSize: pageSize,
		Offset:   (page - 1) * pageSize,
	}
}

// SortOrder defines sorting direction
type SortOrder string

const (
	SortAsc  SortOrder = "ASC"
	SortDesc SortOrder = "DESC"
)

// TimeRange represents a time-based filter
type TimeRange struct {
	Start time.Time
	End   time.Time
}

// NewTimeRange creates a time range from duration
func NewTimeRange(duration time.Duration) TimeRange {
	now := time.Now().UTC()
	return TimeRange{
		Start: now.Add(-duration),
		End:   now,
	}
}

// Last24Hours returns a time range for the last 24 hours
func Last24Hours() TimeRange {
	return NewTimeRange(24 * time.Hour)
}

// Last7Days returns a time range for the last 7 days
func Last7Days() TimeRange {
	return NewTimeRange(7 * 24 * time.Hour)
}

// Last30Days returns a time range for the last 30 days
func Last30Days() TimeRange {
	return NewTimeRange(30 * 24 * time.Hour)
}
