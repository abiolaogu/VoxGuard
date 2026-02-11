// Package analytics implements predictive threat modeling
package analytics

import (
	"context"
	"database/sql"
	"fmt"
	"math"
	"time"
)

// ThreatPrediction represents a predicted threat
type ThreatPrediction struct {
	PredictedDate    time.Time
	ThreatType       string
	Probability      float64
	ExpectedCount    int64
	RiskLevel        string
	ConfidenceLevel  string
	ContributingFactors []string
}

// ThreatPredictor implements predictive threat modeling using statistical analysis
type ThreatPredictor struct {
	db *sql.DB
}

// NewThreatPredictor creates a new threat predictor
func NewThreatPredictor(db *sql.DB) *ThreatPredictor {
	return &ThreatPredictor{db: db}
}

// PredictNextWeek predicts threats for the next 7 days
func (tp *ThreatPredictor) PredictNextWeek(ctx context.Context) ([]*ThreatPrediction, error) {
	// Get historical data for the last 30 days
	historicalData, err := tp.getHistoricalTrends(ctx, 30)
	if err != nil {
		return nil, fmt.Errorf("failed to get historical data: %w", err)
	}

	// Get seasonal patterns (day of week analysis)
	seasonalPatterns, err := tp.getSeasonalPatterns(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get seasonal patterns: %w", err)
	}

	// Predict for next 7 days
	predictions := make([]*ThreatPrediction, 0, 7)
	baseDate := time.Now()

	for i := 1; i <= 7; i++ {
		predictedDate := baseDate.AddDate(0, 0, i)
		dayOfWeek := predictedDate.Weekday()

		for threatType, historical := range historicalData {
			// Simple linear regression with seasonal adjustment
			trend := tp.calculateTrend(historical)
			seasonal := seasonalPatterns[threatType][dayOfWeek]

			// Predict expected count
			expectedCount := int64(math.Max(0, trend*float64(i)+seasonal))

			// Calculate probability based on historical frequency
			probability := tp.calculateProbability(historical, expectedCount)

			// Determine risk level
			riskLevel := tp.determineRiskLevel(probability, expectedCount)

			// Get contributing factors
			factors := tp.identifyContributingFactors(ctx, threatType, historical)

			prediction := &ThreatPrediction{
				PredictedDate:       predictedDate,
				ThreatType:          threatType,
				Probability:         probability,
				ExpectedCount:       expectedCount,
				RiskLevel:           riskLevel,
				ConfidenceLevel:     tp.calculateConfidence(historical),
				ContributingFactors: factors,
			}

			predictions = append(predictions, prediction)
		}
	}

	return predictions, nil
}

// PredictEmergingThreats identifies emerging threat patterns
func (tp *ThreatPredictor) PredictEmergingThreats(ctx context.Context) ([]*ThreatPrediction, error) {
	// Look for threat types with accelerating growth
	rows, err := tp.db.QueryContext(ctx, `
		WITH weekly_counts AS (
			SELECT
				event_type,
				DATE_TRUNC('week', created_at) as week,
				COUNT(*) as count
			FROM acm_alerts
			WHERE created_at >= NOW() - INTERVAL '12 weeks'
			GROUP BY event_type, DATE_TRUNC('week', created_at)
		),
		growth_rates AS (
			SELECT
				w1.event_type,
				w1.week as current_week,
				w1.count as current_count,
				w2.count as previous_count,
				CASE
					WHEN w2.count = 0 OR w2.count IS NULL THEN 100
					ELSE ((w1.count::float - w2.count::float) / w2.count::float * 100)
				END as growth_rate
			FROM weekly_counts w1
			LEFT JOIN weekly_counts w2
				ON w1.event_type = w2.event_type
				AND w2.week = w1.week - INTERVAL '1 week'
			WHERE w1.week = DATE_TRUNC('week', NOW())
		)
		SELECT
			event_type,
			current_count,
			growth_rate
		FROM growth_rates
		WHERE growth_rate > 30 OR current_count > 50
		ORDER BY growth_rate DESC, current_count DESC
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to query emerging threats: %w", err)
	}
	defer rows.Close()

	var predictions []*ThreatPrediction
	for rows.Next() {
		var threatType string
		var currentCount int64
		var growthRate float64

		err := rows.Scan(&threatType, &currentCount, &growthRate)
		if err != nil {
			return nil, fmt.Errorf("failed to scan emerging threat: %w", err)
		}

		// Project next week's count based on growth rate
		nextWeekCount := int64(float64(currentCount) * (1 + growthRate/100))

		prediction := &ThreatPrediction{
			PredictedDate:   time.Now().AddDate(0, 0, 7),
			ThreatType:      threatType,
			Probability:     math.Min(0.95, 0.5+growthRate/200), // Cap at 95%
			ExpectedCount:   nextWeekCount,
			RiskLevel:       tp.determineRiskLevel(growthRate/100, nextWeekCount),
			ConfidenceLevel: "HIGH",
			ContributingFactors: []string{
				fmt.Sprintf("%.1f%% week-over-week growth", growthRate),
				fmt.Sprintf("%d incidents in current week", currentCount),
			},
		}

		predictions = append(predictions, prediction)
	}

	return predictions, nil
}

// getHistoricalTrends retrieves historical alert trends by threat type
func (tp *ThreatPredictor) getHistoricalTrends(ctx context.Context, days int) (map[string][]int64, error) {
	cutoff := time.Now().AddDate(0, 0, -days)

	rows, err := tp.db.QueryContext(ctx, `
		SELECT
			DATE(created_at) as alert_date,
			event_type,
			COUNT(*) as count
		FROM acm_alerts
		WHERE created_at >= $1
		GROUP BY DATE(created_at), event_type
		ORDER BY alert_date ASC
	`, cutoff)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	trends := make(map[string][]int64)
	for rows.Next() {
		var date time.Time
		var eventType string
		var count int64

		if err := rows.Scan(&date, &eventType, &count); err != nil {
			return nil, err
		}

		trends[eventType] = append(trends[eventType], count)
	}

	return trends, rows.Err()
}

// getSeasonalPatterns retrieves day-of-week patterns for each threat type
func (tp *ThreatPredictor) getSeasonalPatterns(ctx context.Context) (map[string]map[time.Weekday]float64, error) {
	rows, err := tp.db.QueryContext(ctx, `
		SELECT
			event_type,
			EXTRACT(DOW FROM created_at)::int as day_of_week,
			AVG(daily_count) as avg_count
		FROM (
			SELECT
				event_type,
				DATE(created_at) as alert_date,
				created_at,
				COUNT(*) OVER (PARTITION BY event_type, DATE(created_at)) as daily_count
			FROM acm_alerts
			WHERE created_at >= NOW() - INTERVAL '90 days'
		) daily_stats
		GROUP BY event_type, EXTRACT(DOW FROM created_at)
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	patterns := make(map[string]map[time.Weekday]float64)
	for rows.Next() {
		var eventType string
		var dayOfWeek int
		var avgCount float64

		if err := rows.Scan(&eventType, &dayOfWeek, &avgCount); err != nil {
			return nil, err
		}

		if patterns[eventType] == nil {
			patterns[eventType] = make(map[time.Weekday]float64)
		}
		patterns[eventType][time.Weekday(dayOfWeek)] = avgCount
	}

	return patterns, rows.Err()
}

// calculateTrend calculates linear trend from historical data
func (tp *ThreatPredictor) calculateTrend(data []int64) float64 {
	if len(data) < 2 {
		return 0
	}

	// Simple linear regression: y = mx + b
	n := float64(len(data))
	var sumX, sumY, sumXY, sumX2 float64

	for i, y := range data {
		x := float64(i + 1)
		sumX += x
		sumY += float64(y)
		sumXY += x * float64(y)
		sumX2 += x * x
	}

	// Calculate slope (m)
	slope := (n*sumXY - sumX*sumY) / (n*sumX2 - sumX*sumX)
	return slope
}

// calculateProbability calculates probability of threat occurrence
func (tp *ThreatPredictor) calculateProbability(historical []int64, expectedCount int64) float64 {
	if len(historical) == 0 {
		return 0.5 // Default to 50% if no historical data
	}

	// Calculate frequency of non-zero days
	nonZeroDays := 0
	for _, count := range historical {
		if count > 0 {
			nonZeroDays++
		}
	}

	baseProbability := float64(nonZeroDays) / float64(len(historical))

	// Adjust based on expected count
	if expectedCount > 10 {
		baseProbability = math.Min(0.95, baseProbability*1.2)
	}

	return baseProbability
}

// determineRiskLevel determines risk level based on probability and count
func (tp *ThreatPredictor) determineRiskLevel(probability float64, count int64) string {
	score := probability * float64(count)

	switch {
	case score >= 50 || probability >= 0.8:
		return "CRITICAL"
	case score >= 20 || probability >= 0.6:
		return "HIGH"
	case score >= 10 || probability >= 0.4:
		return "MEDIUM"
	default:
		return "LOW"
	}
}

// calculateConfidence calculates confidence level based on data quality
func (tp *ThreatPredictor) calculateConfidence(historical []int64) string {
	dataPoints := len(historical)

	switch {
	case dataPoints >= 30:
		return "HIGH"
	case dataPoints >= 14:
		return "MEDIUM"
	default:
		return "LOW"
	}
}

// identifyContributingFactors identifies factors contributing to threat prediction
func (tp *ThreatPredictor) identifyContributingFactors(ctx context.Context, threatType string, historical []int64) []string {
	factors := []string{}

	// Calculate trend direction
	if len(historical) >= 7 {
		recentAvg := tp.average(historical[len(historical)-7:])
		olderAvg := tp.average(historical[:len(historical)-7])

		if recentAvg > olderAvg*1.2 {
			factors = append(factors, "Increasing trend detected")
		} else if recentAvg < olderAvg*0.8 {
			factors = append(factors, "Decreasing trend detected")
		}
	}

	// Check for consistent occurrence
	nonZeroDays := 0
	for _, count := range historical {
		if count > 0 {
			nonZeroDays++
		}
	}
	if float64(nonZeroDays)/float64(len(historical)) > 0.7 {
		factors = append(factors, "High frequency pattern")
	}

	// Check for recent spike
	if len(historical) > 0 && historical[len(historical)-1] > int64(tp.average(historical)*1.5) {
		factors = append(factors, "Recent spike detected")
	}

	return factors
}

// average calculates the average of a slice of int64
func (tp *ThreatPredictor) average(data []int64) float64 {
	if len(data) == 0 {
		return 0
	}
	var sum int64
	for _, v := range data {
		sum += v
	}
	return float64(sum) / float64(len(data))
}
