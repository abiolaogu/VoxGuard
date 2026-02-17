// Package analytics implements the fraud analytics repository
package analytics

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/billyronks/acm-management-api/internal/domain/fraud/repository"
)

// FraudAnalyticsRepository implements fraud analytics using PostgreSQL
type FraudAnalyticsRepository struct {
	db *sql.DB
}

// NewFraudAnalyticsRepository creates a new fraud analytics repository
func NewFraudAnalyticsRepository(db *sql.DB) *FraudAnalyticsRepository {
	return &FraudAnalyticsRepository{db: db}
}

// GetDashboardSummary returns summary statistics for the dashboard
func (r *FraudAnalyticsRepository) GetDashboardSummary(ctx context.Context) (*repository.DashboardSummary, error) {
	summary := &repository.DashboardSummary{}

	// Calculate time boundaries
	now := time.Now()
	last24h := now.Add(-24 * time.Hour)

	// Query: Total alerts in last 24h
	err := r.db.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM acm_alerts
		WHERE created_at >= $1
	`, last24h).Scan(&summary.TotalAlerts24h)
	if err != nil {
		return nil, fmt.Errorf("failed to count total alerts: %w", err)
	}

	// Query: Critical alerts
	err = r.db.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM acm_alerts
		WHERE severity = 'CRITICAL' AND status != 'RESOLVED'
	`).Scan(&summary.CriticalAlerts)
	if err != nil {
		return nil, fmt.Errorf("failed to count critical alerts: %w", err)
	}

	// Query: Pending alerts
	err = r.db.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM acm_alerts
		WHERE status IN ('NEW', 'ACKNOWLEDGED')
	`).Scan(&summary.PendingAlerts)
	if err != nil {
		return nil, fmt.Errorf("failed to count pending alerts: %w", err)
	}

	// Query: Resolved alerts in last 24h
	err = r.db.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM acm_alerts
		WHERE status = 'RESOLVED' AND updated_at >= $1
	`, last24h).Scan(&summary.ResolvedAlerts24h)
	if err != nil {
		return nil, fmt.Errorf("failed to count resolved alerts: %w", err)
	}

	// Query: False positive rate
	var totalResolved, falsePositives int64
	err = r.db.QueryRowContext(ctx, `
		SELECT
			COUNT(*) FILTER (WHERE resolution_type IS NOT NULL) as total,
			COUNT(*) FILTER (WHERE resolution_type = 'FALSE_POSITIVE') as false_pos
		FROM acm_alerts
		WHERE status = 'RESOLVED' AND updated_at >= $1
	`, last24h).Scan(&totalResolved, &falsePositives)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate false positive rate: %w", err)
	}
	if totalResolved > 0 {
		summary.FalsePositiveRate = float64(falsePositives) / float64(totalResolved) * 100
	}

	// Query: Average response time (time to acknowledgement)
	var avgMinutes sql.NullFloat64
	err = r.db.QueryRowContext(ctx, `
		SELECT AVG(EXTRACT(EPOCH FROM (acknowledged_at - created_at)) / 60.0)
		FROM acm_alerts
		WHERE acknowledged_at IS NOT NULL AND created_at >= $1
	`, last24h).Scan(&avgMinutes)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate avg response time: %w", err)
	}
	if avgMinutes.Valid {
		summary.AvgResponseTime = avgMinutes.Float64
	}

	// Query: Total blacklisted entries
	err = r.db.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM gateway_blacklist
		WHERE is_active = true
	`).Scan(&summary.TotalBlacklisted)
	if err != nil {
		return nil, fmt.Errorf("failed to count blacklisted entries: %w", err)
	}

	// Query: NCC reports today
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	err = r.db.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM acm_alerts
		WHERE ncc_report_id IS NOT NULL AND ncc_reported_at >= $1
	`, today).Scan(&summary.NCCReportsToday)
	if err != nil {
		return nil, fmt.Errorf("failed to count NCC reports: %w", err)
	}

	return summary, nil
}

// GetFraudTrends returns fraud trends over the specified number of days
func (r *FraudAnalyticsRepository) GetFraudTrends(ctx context.Context, days int) ([]*repository.FraudTrend, error) {
	startDate := time.Now().AddDate(0, 0, -days)

	rows, err := r.db.QueryContext(ctx, `
		WITH daily_stats AS (
			SELECT
				DATE(created_at) as trend_date,
				event_type as fraud_type,
				COUNT(*) as alert_count
			FROM acm_alerts
			WHERE created_at >= $1
			GROUP BY DATE(created_at), event_type
		),
		previous_stats AS (
			SELECT
				DATE(created_at) as trend_date,
				event_type as fraud_type,
				COUNT(*) as prev_count
			FROM acm_alerts
			WHERE created_at >= $2 AND created_at < $1
			GROUP BY DATE(created_at), event_type
		)
		SELECT
			ds.trend_date,
			ds.alert_count,
			ds.fraud_type,
			CASE
				WHEN ps.prev_count IS NULL OR ps.prev_count = 0 THEN 0
				ELSE ((ds.alert_count::float - ps.prev_count::float) / ps.prev_count::float * 100)
			END as change_rate
		FROM daily_stats ds
		LEFT JOIN previous_stats ps ON ds.fraud_type = ps.fraud_type
		ORDER BY ds.trend_date DESC, ds.fraud_type
	`, startDate, startDate.AddDate(0, 0, -days))
	if err != nil {
		return nil, fmt.Errorf("failed to query fraud trends: %w", err)
	}
	defer rows.Close()

	var trends []*repository.FraudTrend
	for rows.Next() {
		var trend repository.FraudTrend
		err := rows.Scan(&trend.Date, &trend.AlertCount, &trend.FraudType, &trend.ChangeRate)
		if err != nil {
			return nil, fmt.Errorf("failed to scan fraud trend: %w", err)
		}
		trends = append(trends, &trend)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating fraud trends: %w", err)
	}

	return trends, nil
}

// GetHotspots returns geographic fraud hotspots for the last N hours
func (r *FraudAnalyticsRepository) GetHotspots(ctx context.Context, hours int) ([]*repository.FraudHotspot, error) {
	cutoffTime := time.Now().Add(-time.Duration(hours) * time.Hour)

	rows, err := r.db.QueryContext(ctx, `
		WITH regional_stats AS (
			SELECT
				a.source_region as region,
				COUNT(*) as alert_count,
				AVG(a.threat_score) as avg_threat_score,
				array_agg(DISTINCT a.event_type) FILTER (WHERE a.event_type IS NOT NULL) as patterns
			FROM acm_alerts a
			WHERE a.created_at >= $1 AND a.source_region IS NOT NULL
			GROUP BY a.source_region
			HAVING COUNT(*) >= 5
		)
		SELECT
			region,
			alert_count,
			CASE
				WHEN avg_threat_score >= 0.8 THEN 'CRITICAL'
				WHEN avg_threat_score >= 0.6 THEN 'HIGH'
				WHEN avg_threat_score >= 0.4 THEN 'MEDIUM'
				ELSE 'LOW'
			END as risk_level,
			patterns
		FROM regional_stats
		ORDER BY alert_count DESC, avg_threat_score DESC
		LIMIT 20
	`, cutoffTime)
	if err != nil {
		return nil, fmt.Errorf("failed to query hotspots: %w", err)
	}
	defer rows.Close()

	var hotspots []*repository.FraudHotspot
	for rows.Next() {
		var hotspot repository.FraudHotspot
		var patternsRaw string
		err := rows.Scan(&hotspot.Region, &hotspot.AlertCount, &hotspot.RiskLevel, &patternsRaw)
		if err != nil {
			return nil, fmt.Errorf("failed to scan hotspot: %w", err)
		}

		hotspot.TopPatterns = parsePGTextArray(patternsRaw)

		hotspots = append(hotspots, &hotspot)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating hotspots: %w", err)
	}

	return hotspots, nil
}

// GetPatternAnalysis returns detected fraud patterns
func (r *FraudAnalyticsRepository) GetPatternAnalysis(ctx context.Context) ([]*repository.PatternSummary, error) {
	rows, err := r.db.QueryContext(ctx, `
		WITH pattern_stats AS (
			SELECT
				event_type,
				COUNT(*) as occurrences,
				AVG(threat_score) as avg_confidence,
				array_agg(DISTINCT a_number) FILTER (WHERE a_number IS NOT NULL) as example_numbers
			FROM acm_alerts
			WHERE created_at >= NOW() - INTERVAL '7 days'
			GROUP BY event_type
		)
		SELECT
			event_type as pattern_id,
			event_type as pattern_name,
			occurrences,
			avg_confidence,
			example_numbers[1:3] as examples
		FROM pattern_stats
		WHERE occurrences >= 3
		ORDER BY occurrences DESC, avg_confidence DESC
		LIMIT 15
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to query pattern analysis: %w", err)
	}
	defer rows.Close()

	var patterns []*repository.PatternSummary
	for rows.Next() {
		var pattern repository.PatternSummary
		var examplesRaw string
		err := rows.Scan(
			&pattern.PatternID,
			&pattern.Name,
			&pattern.Occurrences,
			&pattern.Confidence,
			&examplesRaw,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan pattern: %w", err)
		}

		pattern.Examples = parsePGTextArray(examplesRaw)

		patterns = append(patterns, &pattern)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating patterns: %w", err)
	}

	return patterns, nil
}

func parsePGTextArray(raw string) []string {
	cleaned := strings.TrimSpace(raw)
	if cleaned == "" || cleaned == "{}" {
		return []string{}
	}

	cleaned = strings.TrimPrefix(cleaned, "{")
	cleaned = strings.TrimSuffix(cleaned, "}")
	if cleaned == "" {
		return []string{}
	}

	parts := strings.Split(cleaned, ",")
	values := make([]string, 0, len(parts))
	for _, part := range parts {
		item := strings.Trim(strings.TrimSpace(part), `"`)
		if item != "" {
			values = append(values, item)
		}
	}

	return values
}
