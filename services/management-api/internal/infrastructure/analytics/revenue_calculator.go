// Package analytics implements revenue impact calculations
package analytics

import (
	"context"
	"database/sql"
	"fmt"
	"time"
)

// RevenueImpact represents financial impact of fraud detection
type RevenueImpact struct {
	Period            string
	StartDate         time.Time
	EndDate           time.Time

	// Fraud metrics
	TotalFraudCallsDetected    int64
	TotalFraudMinutesBlocked   float64

	// Revenue protection
	RevenueProtected           float64 // NGN
	PotentialRevenueLoss       float64 // NGN
	ActualRevenueLoss          float64 // NGN (false negatives)

	// Cost metrics
	OperationalCost            float64 // NGN
	NetBenefit                 float64 // NGN
	ROI                        float64 // Percentage

	// Performance metrics
	DetectionAccuracy          float64 // Percentage
	FalsePositiveRate          float64 // Percentage
	FalseNegativeRate          float64 // Percentage

	// Breakdown by fraud type
	RevenueByFraudType         map[string]float64
}

// RevenueCalculator calculates financial impact of fraud detection
type RevenueCalculator struct {
	db *sql.DB

	// Configurable pricing (NGN per minute)
	InterconnectRate  float64
	InternationalRate float64
	LocalRate         float64

	// Cost structure
	OperationalCostPerDay float64
}

// NewRevenueCalculator creates a new revenue calculator
func NewRevenueCalculator(db *sql.DB) *RevenueCalculator {
	return &RevenueCalculator{
		db: db,
		// Nigerian ICL typical rates (NGN per minute)
		InterconnectRate:  8.50,  // Interconnect termination rate
		InternationalRate: 45.00, // International call rate
		LocalRate:         5.50,  // Local call rate

		// Operational costs (NGN per day)
		OperationalCostPerDay: 150000, // ~$180/day for infrastructure
	}
}

// CalculateDailyImpact calculates revenue impact for a specific day
func (rc *RevenueCalculator) CalculateDailyImpact(ctx context.Context, date time.Time) (*RevenueImpact, error) {
	startOfDay := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, date.Location())
	endOfDay := startOfDay.Add(24 * time.Hour)

	return rc.calculateImpact(ctx, "Daily", startOfDay, endOfDay)
}

// CalculateWeeklyImpact calculates revenue impact for the current week
func (rc *RevenueCalculator) CalculateWeeklyImpact(ctx context.Context) (*RevenueImpact, error) {
	now := time.Now()
	startOfWeek := now.AddDate(0, 0, -int(now.Weekday()))
	startOfWeek = time.Date(startOfWeek.Year(), startOfWeek.Month(), startOfWeek.Day(), 0, 0, 0, 0, startOfWeek.Location())
	endOfWeek := startOfWeek.AddDate(0, 0, 7)

	return rc.calculateImpact(ctx, "Weekly", startOfWeek, endOfWeek)
}

// CalculateMonthlyImpact calculates revenue impact for the current month
func (rc *RevenueCalculator) CalculateMonthlyImpact(ctx context.Context) (*RevenueImpact, error) {
	now := time.Now()
	startOfMonth := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
	endOfMonth := startOfMonth.AddDate(0, 1, 0)

	return rc.calculateImpact(ctx, "Monthly", startOfMonth, endOfMonth)
}

// CalculateYearlyImpact calculates revenue impact for the current year
func (rc *RevenueCalculator) CalculateYearlyImpact(ctx context.Context) (*RevenueImpact, error) {
	now := time.Now()
	startOfYear := time.Date(now.Year(), 1, 1, 0, 0, 0, 0, now.Location())
	endOfYear := startOfYear.AddDate(1, 0, 0)

	return rc.calculateImpact(ctx, "Yearly", startOfYear, endOfYear)
}

// calculateImpact calculates revenue impact for a given period
func (rc *RevenueCalculator) calculateImpact(ctx context.Context, period string, startDate, endDate time.Time) (*RevenueImpact, error) {
	impact := &RevenueImpact{
		Period:             period,
		StartDate:          startDate,
		EndDate:            endDate,
		RevenueByFraudType: make(map[string]float64),
	}

	// Query fraud calls detected and blocked
	err := rc.db.QueryRowContext(ctx, `
		SELECT
			COUNT(*) as fraud_calls,
			COALESCE(SUM(
				CASE
					WHEN acr.duration_seconds IS NOT NULL
					THEN acr.duration_seconds / 60.0
					ELSE 0
				END
			), 0) as total_minutes
		FROM acm_alerts aa
		LEFT JOIN acm_call_records acr ON aa.id = acr.alert_id
		WHERE aa.created_at >= $1 AND aa.created_at < $2
		AND aa.status != 'FALSE_POSITIVE'
	`, startDate, endDate).Scan(&impact.TotalFraudCallsDetected, &impact.TotalFraudMinutesBlocked)
	if err != nil {
		return nil, fmt.Errorf("failed to query fraud metrics: %w", err)
	}

	// Calculate revenue protected by fraud type
	rows, err := rc.db.QueryContext(ctx, `
		SELECT
			aa.event_type,
			COUNT(*) as call_count,
			COALESCE(SUM(acr.duration_seconds / 60.0), 0) as total_minutes,
			aa.source_country
		FROM acm_alerts aa
		LEFT JOIN acm_call_records acr ON aa.id = acr.alert_id
		WHERE aa.created_at >= $1 AND aa.created_at < $2
		AND aa.status != 'FALSE_POSITIVE'
		GROUP BY aa.event_type, aa.source_country
	`, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to query fraud breakdown: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var eventType string
		var callCount int64
		var minutes float64
		var country sql.NullString

		if err := rows.Scan(&eventType, &callCount, &minutes, &country); err != nil {
			return nil, fmt.Errorf("failed to scan fraud breakdown: %w", err)
		}

		// Determine rate based on call type
		rate := rc.determineRate(country)
		revenue := minutes * rate

		impact.RevenueByFraudType[eventType] = revenue
		impact.RevenueProtected += revenue
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating fraud breakdown: %w", err)
	}

	// Calculate false positive impact (legitimate calls blocked)
	var falsePositiveCalls int64
	var falsePositiveMinutes float64
	err = rc.db.QueryRowContext(ctx, `
		SELECT
			COUNT(*) as fp_calls,
			COALESCE(SUM(acr.duration_seconds / 60.0), 0) as fp_minutes
		FROM acm_alerts aa
		LEFT JOIN acm_call_records acr ON aa.id = acr.alert_id
		WHERE aa.created_at >= $1 AND aa.created_at < $2
		AND aa.resolution_type = 'FALSE_POSITIVE'
	`, startDate, endDate).Scan(&falsePositiveCalls, &falsePositiveMinutes)
	if err != nil {
		return nil, fmt.Errorf("failed to query false positives: %w", err)
	}

	// Revenue lost due to false positives (legitimate revenue blocked)
	impact.ActualRevenueLoss = falsePositiveMinutes * rc.InterconnectRate

	// Estimate potential revenue loss (if fraud wasn't detected)
	// This would be the full interconnect charges that fraudsters would have bypassed
	impact.PotentialRevenueLoss = impact.TotalFraudMinutesBlocked * rc.InterconnectRate

	// Calculate operational cost
	days := endDate.Sub(startDate).Hours() / 24
	impact.OperationalCost = rc.OperationalCostPerDay * days

	// Calculate net benefit
	impact.NetBenefit = impact.RevenueProtected - impact.ActualRevenueLoss - impact.OperationalCost

	// Calculate ROI
	if impact.OperationalCost > 0 {
		impact.ROI = (impact.NetBenefit / impact.OperationalCost) * 100
	}

	// Calculate performance metrics
	totalAlerts, err := rc.getTotalAlerts(ctx, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to get total alerts: %w", err)
	}

	if totalAlerts > 0 {
		impact.DetectionAccuracy = float64(impact.TotalFraudCallsDetected) / float64(totalAlerts) * 100
		impact.FalsePositiveRate = float64(falsePositiveCalls) / float64(totalAlerts) * 100
	}

	// Estimate false negative rate (missed fraud)
	// This is harder to calculate precisely, but we can estimate based on
	// the ratio of detected fraud to total suspicious patterns
	suspiciousPatterns, err := rc.getSuspiciousCallCount(ctx, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to get suspicious patterns: %w", err)
	}

	if suspiciousPatterns > 0 {
		impact.FalseNegativeRate = float64(suspiciousPatterns-impact.TotalFraudCallsDetected) / float64(suspiciousPatterns) * 100
		impact.FalseNegativeRate = max(0, impact.FalseNegativeRate) // Ensure non-negative
	}

	return impact, nil
}

// GetRevenueProjection projects revenue protection for next period
func (rc *RevenueCalculator) GetRevenueProjection(ctx context.Context, days int) (float64, error) {
	// Get average daily revenue protection for last 30 days
	endDate := time.Now()
	startDate := endDate.AddDate(0, 0, -30)

	var avgDailyRevenue float64
	err := rc.db.QueryRowContext(ctx, `
		SELECT
			COALESCE(SUM(acr.duration_seconds / 60.0), 0) / 30.0 as avg_daily_minutes
		FROM acm_alerts aa
		LEFT JOIN acm_call_records acr ON aa.id = acr.alert_id
		WHERE aa.created_at >= $1 AND aa.created_at < $2
		AND aa.status != 'FALSE_POSITIVE'
	`, startDate, endDate).Scan(&avgDailyRevenue)
	if err != nil {
		return 0, fmt.Errorf("failed to calculate projection: %w", err)
	}

	// Project for the specified number of days
	return avgDailyRevenue * rc.InterconnectRate * float64(days), nil
}

// determineRate determines the rate based on call destination
func (rc *RevenueCalculator) determineRate(country sql.NullString) float64 {
	if !country.Valid {
		return rc.InterconnectRate
	}

	// Nigerian country codes
	if country.String == "NGA" || country.String == "234" {
		return rc.LocalRate
	}

	// International calls
	return rc.InternationalRate
}

// getTotalAlerts gets total alerts for a period
func (rc *RevenueCalculator) getTotalAlerts(ctx context.Context, startDate, endDate time.Time) (int64, error) {
	var count int64
	err := rc.db.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM acm_alerts
		WHERE created_at >= $1 AND created_at < $2
	`, startDate, endDate).Scan(&count)
	return count, err
}

// getSuspiciousCallCount gets count of suspicious calls (potential fraud)
func (rc *RevenueCalculator) getSuspiciousCallCount(ctx context.Context, startDate, endDate time.Time) (int64, error) {
	var count int64
	err := rc.db.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM acm_call_records
		WHERE setup_time >= $1 AND setup_time < $2
		AND (risk_score >= 0.3 OR is_flagged = true)
	`, startDate, endDate).Scan(&count)
	return count, err
}

// max returns the maximum of two float64 values
func max(a, b float64) float64 {
	if a > b {
		return a
	}
	return b
}
