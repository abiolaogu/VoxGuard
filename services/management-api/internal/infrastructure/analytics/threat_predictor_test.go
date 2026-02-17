package analytics

import (
	"context"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestPredictNextWeek(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	predictor := NewThreatPredictor(db)
	ctx := context.Background()

	t.Run("successful prediction", func(t *testing.T) {
		// Mock historical trends query
		historicalRows := sqlmock.NewRows([]string{"alert_date", "event_type", "count"}).
			AddRow(time.Now().AddDate(0, 0, -1), "CLI_MISMATCH", 45).
			AddRow(time.Now().AddDate(0, 0, -2), "CLI_MISMATCH", 42).
			AddRow(time.Now().AddDate(0, 0, -3), "CLI_MISMATCH", 38).
			AddRow(time.Now().AddDate(0, 0, -1), "SIMBOX_DETECTED", 28).
			AddRow(time.Now().AddDate(0, 0, -2), "SIMBOX_DETECTED", 30)

		mock.ExpectQuery("SELECT(.+)FROM acm_alerts(.+)GROUP BY DATE").
			WillReturnRows(historicalRows)

		// Mock seasonal patterns query
		seasonalRows := sqlmock.NewRows([]string{"event_type", "day_of_week", "avg_count"}).
			AddRow("CLI_MISMATCH", 1, 42.5). // Monday
			AddRow("CLI_MISMATCH", 2, 45.0). // Tuesday
			AddRow("SIMBOX_DETECTED", 1, 28.0)

		mock.ExpectQuery("SELECT(.+)FROM(.+)daily_stats(.+)GROUP BY event_type").
			WillReturnRows(seasonalRows)

		predictions, err := predictor.PredictNextWeek(ctx)
		require.NoError(t, err)
		assert.NotEmpty(t, predictions)

		// Verify predictions contain expected threat types
		foundCLI := false
		foundSimbox := false
		for _, pred := range predictions {
			if pred.ThreatType == "CLI_MISMATCH" {
				foundCLI = true
				assert.True(t, pred.Probability >= 0 && pred.Probability <= 1)
				assert.NotEmpty(t, pred.RiskLevel)
			}
			if pred.ThreatType == "SIMBOX_DETECTED" {
				foundSimbox = true
			}
		}
		assert.True(t, foundCLI)
		assert.True(t, foundSimbox)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("handles no historical data", func(t *testing.T) {
		mock.ExpectQuery("SELECT(.+)FROM acm_alerts(.+)GROUP BY DATE").
			WillReturnRows(sqlmock.NewRows([]string{"alert_date", "event_type", "count"}))

		mock.ExpectQuery("SELECT(.+)FROM(.+)daily_stats(.+)GROUP BY event_type").
			WillReturnRows(sqlmock.NewRows([]string{"event_type", "day_of_week", "avg_count"}))

		predictions, err := predictor.PredictNextWeek(ctx)
		require.NoError(t, err)
		assert.Empty(t, predictions)

		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestPredictEmergingThreats(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	predictor := NewThreatPredictor(db)
	ctx := context.Background()

	t.Run("identifies emerging threats", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{"event_type", "current_count", "growth_rate"}).
			AddRow("NEW_THREAT_PATTERN", 65, 85.5). // High growth
			AddRow("CLI_MISMATCH", 120, 15.2).      // Moderate growth
			AddRow("SIMBOX_DETECTED", 55, 35.8)     // Above 30% threshold

		mock.ExpectQuery("WITH weekly_counts AS").WillReturnRows(rows)

		predictions, err := predictor.PredictEmergingThreats(ctx)
		require.NoError(t, err)
		assert.Len(t, predictions, 3)

		// First prediction should be the highest growth threat
		assert.Equal(t, "NEW_THREAT_PATTERN", predictions[0].ThreatType)
		assert.Equal(t, int64(120), predictions[0].ExpectedCount) // Projected next-week count
		assert.Contains(t, predictions[0].ContributingFactors[0], "85.5%")
		assert.Equal(t, "HIGH", predictions[0].ConfidenceLevel)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("handles no emerging threats", func(t *testing.T) {
		mock.ExpectQuery("WITH weekly_counts AS").
			WillReturnRows(sqlmock.NewRows([]string{"event_type", "current_count", "growth_rate"}))

		predictions, err := predictor.PredictEmergingThreats(ctx)
		require.NoError(t, err)
		assert.Empty(t, predictions)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("calculates correct risk levels", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{"event_type", "current_count", "growth_rate"}).
			AddRow("CRITICAL_THREAT", 200, 150.0). // Should be CRITICAL
			AddRow("HIGH_THREAT", 80, 60.0).       // Should be HIGH
			AddRow("MEDIUM_THREAT", 40, 35.0)      // Should be MEDIUM or HIGH

		mock.ExpectQuery("WITH weekly_counts AS").WillReturnRows(rows)

		predictions, err := predictor.PredictEmergingThreats(ctx)
		require.NoError(t, err)
		assert.Len(t, predictions, 3)

		// Verify risk level assignment
		assert.Contains(t, []string{"CRITICAL", "HIGH"}, predictions[0].RiskLevel)

		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestCalculateTrend(t *testing.T) {
	predictor := &ThreatPredictor{}

	t.Run("calculates positive trend", func(t *testing.T) {
		data := []int64{10, 12, 15, 18, 22, 25}
		trend := predictor.calculateTrend(data)
		assert.True(t, trend > 0, "Expected positive trend")
	})

	t.Run("calculates negative trend", func(t *testing.T) {
		data := []int64{50, 45, 40, 35, 30}
		trend := predictor.calculateTrend(data)
		assert.True(t, trend < 0, "Expected negative trend")
	})

	t.Run("handles flat trend", func(t *testing.T) {
		data := []int64{20, 20, 20, 20}
		trend := predictor.calculateTrend(data)
		assert.InDelta(t, 0.0, trend, 0.1)
	})

	t.Run("handles insufficient data", func(t *testing.T) {
		data := []int64{10}
		trend := predictor.calculateTrend(data)
		assert.Equal(t, 0.0, trend)
	})
}

func TestCalculateProbability(t *testing.T) {
	predictor := &ThreatPredictor{}

	t.Run("calculates high probability", func(t *testing.T) {
		historical := []int64{10, 15, 12, 18, 20, 14, 16} // All non-zero
		prob := predictor.calculateProbability(historical, 15)
		assert.InDelta(t, 1.0, prob, 0.1) // Should be close to 100%
	})

	t.Run("calculates medium probability", func(t *testing.T) {
		historical := []int64{10, 0, 12, 0, 20, 0, 16} // 50% non-zero
		prob := predictor.calculateProbability(historical, 8)
		assert.InDelta(t, 0.57, prob, 0.1)
	})

	t.Run("handles no historical data", func(t *testing.T) {
		historical := []int64{}
		prob := predictor.calculateProbability(historical, 10)
		assert.Equal(t, 0.5, prob) // Default to 50%
	})

	t.Run("adjusts for high expected count", func(t *testing.T) {
		historical := []int64{10, 12, 8, 15}
		probLow := predictor.calculateProbability(historical, 5)
		probHigh := predictor.calculateProbability(historical, 50)
		assert.True(t, probHigh >= probLow, "Higher count should have higher or equal probability")
	})
}

func TestDetermineRiskLevel(t *testing.T) {
	predictor := &ThreatPredictor{}

	tests := []struct {
		name        string
		probability float64
		count       int64
		expected    string
	}{
		{"critical high prob", 0.85, 100, "CRITICAL"},
		{"critical high score", 0.6, 100, "CRITICAL"},
		{"high level", 0.65, 40, "HIGH"},
		{"medium level", 0.45, 30, "MEDIUM"},
		{"low level", 0.3, 10, "LOW"},
		{"low with small count", 0.2, 5, "LOW"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := predictor.determineRiskLevel(tt.probability, tt.count)
			assert.Equal(t, tt.expected, result)
		})
	}
}

func TestCalculateConfidence(t *testing.T) {
	predictor := &ThreatPredictor{}

	t.Run("high confidence with enough data", func(t *testing.T) {
		data := make([]int64, 35)
		conf := predictor.calculateConfidence(data)
		assert.Equal(t, "HIGH", conf)
	})

	t.Run("medium confidence", func(t *testing.T) {
		data := make([]int64, 20)
		conf := predictor.calculateConfidence(data)
		assert.Equal(t, "MEDIUM", conf)
	})

	t.Run("low confidence with little data", func(t *testing.T) {
		data := make([]int64, 5)
		conf := predictor.calculateConfidence(data)
		assert.Equal(t, "LOW", conf)
	})
}

func TestIdentifyContributingFactors(t *testing.T) {
	predictor := &ThreatPredictor{}
	ctx := context.Background()

	t.Run("identifies increasing trend", func(t *testing.T) {
		historical := []int64{10, 12, 15, 18, 20, 25, 30, 35}
		factors := predictor.identifyContributingFactors(ctx, "CLI_MISMATCH", historical)
		assert.NotEmpty(t, factors)
		assert.Contains(t, factors[0], "Increasing trend")
	})

	t.Run("identifies decreasing trend", func(t *testing.T) {
		historical := []int64{50, 45, 40, 35, 30, 25, 20, 15}
		factors := predictor.identifyContributingFactors(ctx, "SIMBOX_DETECTED", historical)
		assert.NotEmpty(t, factors)
		assert.Contains(t, factors[0], "Decreasing trend")
	})

	t.Run("identifies high frequency pattern", func(t *testing.T) {
		historical := []int64{10, 12, 15, 18, 20, 14, 16, 19, 21, 17}
		factors := predictor.identifyContributingFactors(ctx, "HIGH_VOLUME", historical)
		assert.NotEmpty(t, factors)

		hasFrequency := false
		for _, factor := range factors {
			if contains(factor, "frequency") {
				hasFrequency = true
				break
			}
		}
		assert.True(t, hasFrequency)
	})

	t.Run("identifies recent spike", func(t *testing.T) {
		historical := []int64{10, 12, 10, 11, 50} // Spike at end
		factors := predictor.identifyContributingFactors(ctx, "ANOMALY", historical)
		assert.NotEmpty(t, factors)

		hasSpike := false
		for _, factor := range factors {
			if contains(factor, "spike") {
				hasSpike = true
				break
			}
		}
		assert.True(t, hasSpike)
	})
}

func TestAverage(t *testing.T) {
	predictor := &ThreatPredictor{}

	t.Run("calculates average correctly", func(t *testing.T) {
		data := []int64{10, 20, 30, 40}
		avg := predictor.average(data)
		assert.Equal(t, 25.0, avg)
	})

	t.Run("handles empty slice", func(t *testing.T) {
		data := []int64{}
		avg := predictor.average(data)
		assert.Equal(t, 0.0, avg)
	})

	t.Run("handles single value", func(t *testing.T) {
		data := []int64{42}
		avg := predictor.average(data)
		assert.Equal(t, 42.0, avg)
	})
}

// Helper function
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > len(substr) &&
		(s[:len(substr)] == substr || s[len(s)-len(substr):] == substr ||
			findSubstring(s, substr)))
}

func findSubstring(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
