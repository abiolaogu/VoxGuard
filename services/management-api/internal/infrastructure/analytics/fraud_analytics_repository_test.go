package analytics

import (
	"context"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestGetDashboardSummary(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	repo := NewFraudAnalyticsRepository(db)
	ctx := context.Background()

	t.Run("successful summary retrieval", func(t *testing.T) {
		// Mock total alerts query
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(150))

		// Mock critical alerts query
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(12))

		// Mock pending alerts query
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(35))

		// Mock resolved alerts query
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(98))

		// Mock false positive rate query
		mock.ExpectQuery("SELECT(.+)FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"total", "false_pos"}).AddRow(98, 5))

		// Mock average response time query
		mock.ExpectQuery("SELECT AVG").
			WillReturnRows(sqlmock.NewRows([]string{"avg"}).AddRow(12.5))

		// Mock blacklisted count query
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM gateway_blacklist").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(24))

		// Mock NCC reports query
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(8))

		summary, err := repo.GetDashboardSummary(ctx)
		require.NoError(t, err)
		assert.NotNil(t, summary)

		assert.Equal(t, int64(150), summary.TotalAlerts24h)
		assert.Equal(t, int64(12), summary.CriticalAlerts)
		assert.Equal(t, int64(35), summary.PendingAlerts)
		assert.Equal(t, int64(98), summary.ResolvedAlerts24h)
		assert.InDelta(t, 5.10, summary.FalsePositiveRate, 0.1) // 5/98 * 100
		assert.Equal(t, 12.5, summary.AvgResponseTime)
		assert.Equal(t, int64(24), summary.TotalBlacklisted)
		assert.Equal(t, int64(8), summary.NCCReportsToday)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("handles zero false positives", func(t *testing.T) {
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(100))
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(5))
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(20))
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(50))
		mock.ExpectQuery("SELECT(.+)FROM acm_alerts").WillReturnRows(sqlmock.NewRows([]string{"total", "false_pos"}).AddRow(50, 0))
		mock.ExpectQuery("SELECT AVG").WillReturnRows(sqlmock.NewRows([]string{"avg"}).AddRow(10.0))
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM gateway_blacklist").WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(10))
		mock.ExpectQuery("SELECT COUNT\\(\\*\\) FROM acm_alerts").WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(5))

		summary, err := repo.GetDashboardSummary(ctx)
		require.NoError(t, err)
		assert.Equal(t, 0.0, summary.FalsePositiveRate)

		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestGetFraudTrends(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	repo := NewFraudAnalyticsRepository(db)
	ctx := context.Background()

	t.Run("successful trend retrieval", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{"trend_date", "alert_count", "fraud_type", "change_rate"}).
			AddRow(time.Now(), 45, "CLI_MISMATCH", 15.5).
			AddRow(time.Now().AddDate(0, 0, -1), 32, "CLI_MISMATCH", -10.2).
			AddRow(time.Now(), 28, "SIMBOX_DETECTED", 25.3)

		mock.ExpectQuery("WITH daily_stats AS").WillReturnRows(rows)

		trends, err := repo.GetFraudTrends(ctx, 7)
		require.NoError(t, err)
		assert.Len(t, trends, 3)

		assert.Equal(t, int64(45), trends[0].AlertCount)
		assert.Equal(t, "CLI_MISMATCH", trends[0].FraudType)
		assert.InDelta(t, 15.5, trends[0].ChangeRate, 0.1)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("handles empty results", func(t *testing.T) {
		mock.ExpectQuery("WITH daily_stats AS").
			WillReturnRows(sqlmock.NewRows([]string{"trend_date", "alert_count", "fraud_type", "change_rate"}))

		trends, err := repo.GetFraudTrends(ctx, 30)
		require.NoError(t, err)
		assert.Empty(t, trends)

		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestGetHotspots(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	repo := NewFraudAnalyticsRepository(db)
	ctx := context.Background()

	t.Run("successful hotspot retrieval", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{"region", "alert_count", "risk_level", "patterns"}).
			AddRow("Lagos", 125, "CRITICAL", "{CLI_MISMATCH,SIMBOX_DETECTED}").
			AddRow("Kano", 45, "HIGH", "{HIGH_VOLUME}")

		mock.ExpectQuery("WITH regional_stats AS").WillReturnRows(rows)

		hotspots, err := repo.GetHotspots(ctx, 24)
		require.NoError(t, err)
		assert.Len(t, hotspots, 2)

		assert.Equal(t, "Lagos", hotspots[0].Region)
		assert.Equal(t, int64(125), hotspots[0].AlertCount)
		assert.Equal(t, "CRITICAL", hotspots[0].RiskLevel)
		assert.Len(t, hotspots[0].TopPatterns, 2)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("handles null patterns", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{"region", "alert_count", "risk_level", "patterns"}).
			AddRow("Abuja", 30, "MEDIUM", "{}")

		mock.ExpectQuery("WITH regional_stats AS").WillReturnRows(rows)

		hotspots, err := repo.GetHotspots(ctx, 48)
		require.NoError(t, err)
		assert.Len(t, hotspots, 1)
		assert.Empty(t, hotspots[0].TopPatterns)

		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestGetPatternAnalysis(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	repo := NewFraudAnalyticsRepository(db)
	ctx := context.Background()

	t.Run("successful pattern analysis", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{"pattern_id", "pattern_name", "occurrences", "avg_confidence", "examples"}).
			AddRow("CLI_MISMATCH", "CLI_MISMATCH", 234, 0.87, "{+2348012345678,+2348087654321}").
			AddRow("SIMBOX_DETECTED", "SIMBOX_DETECTED", 156, 0.92, "{+2348012345678,+2348087654321}")

		mock.ExpectQuery("WITH pattern_stats AS").WillReturnRows(rows)

		patterns, err := repo.GetPatternAnalysis(ctx)
		require.NoError(t, err)
		assert.Len(t, patterns, 2)

		assert.Equal(t, "CLI_MISMATCH", patterns[0].PatternID)
		assert.Equal(t, int64(234), patterns[0].Occurrences)
		assert.InDelta(t, 0.87, patterns[0].Confidence, 0.01)
		assert.Len(t, patterns[0].Examples, 2)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("handles empty examples", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{"pattern_id", "pattern_name", "occurrences", "avg_confidence", "examples"}).
			AddRow("RARE_PATTERN", "RARE_PATTERN", 5, 0.65, "{}")

		mock.ExpectQuery("WITH pattern_stats AS").WillReturnRows(rows)

		patterns, err := repo.GetPatternAnalysis(ctx)
		require.NoError(t, err)
		assert.Len(t, patterns, 1)
		assert.Empty(t, patterns[0].Examples)

		assert.NoError(t, mock.ExpectationsWereMet())
	})
}
