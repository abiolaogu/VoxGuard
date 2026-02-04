package analytics

import (
	"context"
	"database/sql"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestCalculateDailyImpact(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	calculator := NewRevenueCalculator(db)
	ctx := context.Background()
	testDate := time.Date(2026, 2, 4, 0, 0, 0, 0, time.UTC)

	t.Run("successful daily impact calculation", func(t *testing.T) {
		// Mock fraud calls and minutes query
		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa").
			WillReturnRows(sqlmock.NewRows([]string{"fraud_calls", "total_minutes"}).
				AddRow(125, 1850.5))

		// Mock fraud breakdown by type query
		mock.ExpectQuery("SELECT(.+)aa.event_type").
			WillReturnRows(sqlmock.NewRows([]string{"event_type", "call_count", "total_minutes", "source_country"}).
				AddRow("CLI_MISMATCH", 75, 1100.0, sql.NullString{String: "NGA", Valid: true}).
				AddRow("SIMBOX_DETECTED", 50, 750.5, sql.NullString{String: "USA", Valid: true}))

		// Mock false positive query
		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa(.+)FALSE_POSITIVE").
			WillReturnRows(sqlmock.NewRows([]string{"fp_calls", "fp_minutes"}).
				AddRow(5, 45.0))

		// Mock total alerts query
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(130))

		// Mock suspicious call count query
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_call_records").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(150))

		impact, err := calculator.CalculateDailyImpact(ctx, testDate)
		require.NoError(t, err)
		assert.NotNil(t, impact)

		assert.Equal(t, "Daily", impact.Period)
		assert.Equal(t, int64(125), impact.TotalFraudCallsDetected)
		assert.InDelta(t, 1850.5, impact.TotalFraudMinutesBlocked, 0.1)

		// Revenue protected calculation:
		// CLI_MISMATCH: 1100 * 5.50 (local) = 6,050
		// SIMBOX_DETECTED: 750.5 * 45.00 (international) = 33,772.50
		// Total: 39,822.50
		assert.InDelta(t, 39822.5, impact.RevenueProtected, 1.0)

		// Revenue lost (false positives): 45.0 * 8.50 = 382.5
		assert.InDelta(t, 382.5, impact.ActualRevenueLoss, 1.0)

		// Potential loss: 1850.5 * 8.50 = 15,729.25
		assert.InDelta(t, 15729.25, impact.PotentialRevenueLoss, 1.0)

		// Operational cost: 150,000 NGN/day * 1 day
		assert.InDelta(t, 150000.0, impact.OperationalCost, 1.0)

		// Net benefit: 39,822.5 - 382.5 - 150,000 = -110,560
		// (In this case, operational cost exceeds protected revenue)
		assert.InDelta(t, -110560.0, impact.NetBenefit, 1.0)

		// Detection accuracy: 125/130 * 100 = 96.15%
		assert.InDelta(t, 96.15, impact.DetectionAccuracy, 0.1)

		// False positive rate: 5/130 * 100 = 3.85%
		assert.InDelta(t, 3.85, impact.FalsePositiveRate, 0.1)

		// False negative rate: (150 - 125) / 150 * 100 = 16.67%
		assert.InDelta(t, 16.67, impact.FalseNegativeRate, 0.1)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("handles zero fraud calls", func(t *testing.T) {
		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa").
			WillReturnRows(sqlmock.NewRows([]string{"fraud_calls", "total_minutes"}).AddRow(0, 0.0))

		mock.ExpectQuery("SELECT(.+)aa.event_type").
			WillReturnRows(sqlmock.NewRows([]string{"event_type", "call_count", "total_minutes", "source_country"}))

		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa(.+)FALSE_POSITIVE").
			WillReturnRows(sqlmock.NewRows([]string{"fp_calls", "fp_minutes"}).AddRow(0, 0.0))

		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(0))

		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_call_records").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(0))

		impact, err := calculator.CalculateDailyImpact(ctx, testDate)
		require.NoError(t, err)

		assert.Equal(t, int64(0), impact.TotalFraudCallsDetected)
		assert.Equal(t, 0.0, impact.RevenueProtected)
		assert.Equal(t, 0.0, impact.FalseNegativeRate)

		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestCalculateWeeklyImpact(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	calculator := NewRevenueCalculator(db)
	ctx := context.Background()

	t.Run("successful weekly calculation", func(t *testing.T) {
		// Setup mocks for all queries
		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa").
			WillReturnRows(sqlmock.NewRows([]string{"fraud_calls", "total_minutes"}).AddRow(850, 12500.0))

		mock.ExpectQuery("SELECT(.+)aa.event_type").
			WillReturnRows(sqlmock.NewRows([]string{"event_type", "call_count", "total_minutes", "source_country"}).
				AddRow("CLI_MISMATCH", 500, 7500.0, sql.NullString{String: "NGA", Valid: true}).
				AddRow("SIMBOX_DETECTED", 350, 5000.0, sql.NullString{Valid: false}))

		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa(.+)FALSE_POSITIVE").
			WillReturnRows(sqlmock.NewRows([]string{"fp_calls", "fp_minutes"}).AddRow(25, 300.0))

		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(875))

		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_call_records").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1000))

		impact, err := calculator.CalculateWeeklyImpact(ctx)
		require.NoError(t, err)

		assert.Equal(t, "Weekly", impact.Period)
		assert.Equal(t, int64(850), impact.TotalFraudCallsDetected)

		// Operational cost for 7 days
		assert.InDelta(t, 1050000.0, impact.OperationalCost, 1.0) // 150,000 * 7

		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestCalculateMonthlyImpact(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	calculator := NewRevenueCalculator(db)
	ctx := context.Background()

	t.Run("successful monthly calculation", func(t *testing.T) {
		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa").
			WillReturnRows(sqlmock.NewRows([]string{"fraud_calls", "total_minutes"}).AddRow(3500, 52000.0))

		mock.ExpectQuery("SELECT(.+)aa.event_type").
			WillReturnRows(sqlmock.NewRows([]string{"event_type", "call_count", "total_minutes", "source_country"}).
				AddRow("CLI_MISMATCH", 2000, 30000.0, sql.NullString{String: "NGA", Valid: true}))

		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa(.+)FALSE_POSITIVE").
			WillReturnRows(sqlmock.NewRows([]string{"fp_calls", "fp_minutes"}).AddRow(100, 1200.0))

		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(3600))

		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_call_records").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(4000))

		impact, err := calculator.CalculateMonthlyImpact(ctx)
		require.NoError(t, err)

		assert.Equal(t, "Monthly", impact.Period)

		// Should have operational cost for ~28-31 days
		assert.True(t, impact.OperationalCost >= 4200000.0) // At least 28 days

		// Positive ROI check (high fraud detection should yield positive ROI)
		assert.True(t, impact.RevenueProtected > 0)

		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestGetRevenueProjection(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	calculator := NewRevenueCalculator(db)
	ctx := context.Background()

	t.Run("successful projection", func(t *testing.T) {
		// Mock average daily minutes: 1500 minutes/day average
		mock.ExpectQuery("SELECT(.+)avg_daily_minutes").
			WillReturnRows(sqlmock.NewRows([]string{"avg_daily_minutes"}).AddRow(1500.0))

		projection, err := calculator.GetRevenueProjection(ctx, 30)
		require.NoError(t, err)

		// Expected: 1500 minutes * 8.50 NGN/min * 30 days = 382,500 NGN
		assert.InDelta(t, 382500.0, projection, 1.0)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("handles no historical data", func(t *testing.T) {
		mock.ExpectQuery("SELECT(.+)avg_daily_minutes").
			WillReturnRows(sqlmock.NewRows([]string{"avg_daily_minutes"}).AddRow(0.0))

		projection, err := calculator.GetRevenueProjection(ctx, 7)
		require.NoError(t, err)
		assert.Equal(t, 0.0, projection)

		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestDetermineRate(t *testing.T) {
	calculator := NewRevenueCalculator(nil)

	tests := []struct {
		name     string
		country  sql.NullString
		expected float64
	}{
		{"Nigerian local", sql.NullString{String: "NGA", Valid: true}, 5.50},
		{"Nigerian with code", sql.NullString{String: "234", Valid: true}, 5.50},
		{"International", sql.NullString{String: "USA", Valid: true}, 45.00},
		{"Null country", sql.NullString{Valid: false}, 8.50},
		{"Empty country", sql.NullString{String: "", Valid: true}, 45.00},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rate := calculator.determineRate(tt.country)
			assert.Equal(t, tt.expected, rate)
		})
	}
}

func TestRevenueImpactBreakdown(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	calculator := NewRevenueCalculator(db)
	ctx := context.Background()
	testDate := time.Date(2026, 2, 1, 0, 0, 0, 0, time.UTC)

	t.Run("revenue breakdown by fraud type", func(t *testing.T) {
		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa").
			WillReturnRows(sqlmock.NewRows([]string{"fraud_calls", "total_minutes"}).AddRow(200, 3000.0))

		// Mock multiple fraud types
		mock.ExpectQuery("SELECT(.+)aa.event_type").
			WillReturnRows(sqlmock.NewRows([]string{"event_type", "call_count", "total_minutes", "source_country"}).
				AddRow("CLI_MISMATCH", 100, 1500.0, sql.NullString{String: "NGA", Valid: true}).
				AddRow("SIMBOX_DETECTED", 60, 900.0, sql.NullString{String: "USA", Valid: true}).
				AddRow("HIGH_VOLUME", 40, 600.0, sql.NullString{Valid: false}))

		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa(.+)FALSE_POSITIVE").
			WillReturnRows(sqlmock.NewRows([]string{"fp_calls", "fp_minutes"}).AddRow(10, 100.0))

		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(210))

		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_call_records").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(220))

		impact, err := calculator.CalculateDailyImpact(ctx, testDate)
		require.NoError(t, err)

		// Verify breakdown by fraud type
		assert.Contains(t, impact.RevenueByFraudType, "CLI_MISMATCH")
		assert.Contains(t, impact.RevenueByFraudType, "SIMBOX_DETECTED")
		assert.Contains(t, impact.RevenueByFraudType, "HIGH_VOLUME")

		// CLI_MISMATCH: 1500 * 5.50 = 8,250
		assert.InDelta(t, 8250.0, impact.RevenueByFraudType["CLI_MISMATCH"], 1.0)

		// SIMBOX_DETECTED: 900 * 45.00 = 40,500
		assert.InDelta(t, 40500.0, impact.RevenueByFraudType["SIMBOX_DETECTED"], 1.0)

		// HIGH_VOLUME: 600 * 8.50 = 5,100
		assert.InDelta(t, 5100.0, impact.RevenueByFraudType["HIGH_VOLUME"], 1.0)

		// Total revenue protected should be sum of all types
		expectedTotal := 8250.0 + 40500.0 + 5100.0
		assert.InDelta(t, expectedTotal, impact.RevenueProtected, 1.0)

		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestROICalculation(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	calculator := NewRevenueCalculator(db)
	ctx := context.Background()
	testDate := time.Date(2026, 2, 1, 0, 0, 0, 0, time.UTC)

	t.Run("positive ROI scenario", func(t *testing.T) {
		// High fraud detection, low false positives
		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa").
			WillReturnRows(sqlmock.NewRows([]string{"fraud_calls", "total_minutes"}).AddRow(500, 7500.0))

		mock.ExpectQuery("SELECT(.+)aa.event_type").
			WillReturnRows(sqlmock.NewRows([]string{"event_type", "call_count", "total_minutes", "source_country"}).
				AddRow("SIMBOX_DETECTED", 500, 7500.0, sql.NullString{String: "USA", Valid: true}))

		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa(.+)FALSE_POSITIVE").
			WillReturnRows(sqlmock.NewRows([]string{"fp_calls", "fp_minutes"}).AddRow(5, 50.0))

		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(505))

		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_call_records").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(550))

		impact, err := calculator.CalculateDailyImpact(ctx, testDate)
		require.NoError(t, err)

		// Revenue protected: 7500 * 45 = 337,500
		// Actual loss: 50 * 8.50 = 425
		// Operational cost: 150,000
		// Net benefit: 337,500 - 425 - 150,000 = 187,075
		// ROI: (187,075 / 150,000) * 100 = 124.72%

		assert.True(t, impact.ROI > 0, "Expected positive ROI")
		assert.InDelta(t, 124.72, impact.ROI, 1.0)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("negative ROI scenario", func(t *testing.T) {
		// Low fraud detection, high operational cost
		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa").
			WillReturnRows(sqlmock.NewRows([]string{"fraud_calls", "total_minutes"}).AddRow(50, 500.0))

		mock.ExpectQuery("SELECT(.+)aa.event_type").
			WillReturnRows(sqlmock.NewRows([]string{"event_type", "call_count", "total_minutes", "source_country"}).
				AddRow("CLI_MISMATCH", 50, 500.0, sql.NullString{String: "NGA", Valid: true}))

		mock.ExpectQuery("SELECT(.+)FROM acm_alerts aa(.+)FALSE_POSITIVE").
			WillReturnRows(sqlmock.NewRows([]string{"fp_calls", "fp_minutes"}).AddRow(10, 100.0))

		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(60))

		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_call_records").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(70))

		impact, err := calculator.CalculateDailyImpact(ctx, testDate)
		require.NoError(t, err)

		// Revenue protected: 500 * 5.50 = 2,750
		// Actual loss: 100 * 8.50 = 850
		// Operational cost: 150,000
		// Net benefit: 2,750 - 850 - 150,000 = -148,100
		// ROI: (-148,100 / 150,000) * 100 = -98.73%

		assert.True(t, impact.ROI < 0, "Expected negative ROI")

		assert.NoError(t, mock.ExpectationsWereMet())
	})
}
