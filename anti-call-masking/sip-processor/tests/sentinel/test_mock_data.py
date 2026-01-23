"""
Unit tests for mock CDR data generator
"""
import pytest
import csv
import io
from datetime import datetime
from app.sentinel.mock_data import MockCDRGenerator


@pytest.fixture
def generator():
    """Create MockCDRGenerator instance"""
    return MockCDRGenerator(seed=42)


class TestMockCDRGenerator:
    """Test cases for mock data generation"""

    def test_generate_phone_number_format(self, generator):
        """Test phone number generation format"""
        phone = generator.generate_phone_number()

        # Should be E.164 format with Nigerian prefix
        assert phone.startswith('+234')
        assert len(phone) == 14  # +234 (4) + 10 digits

    def test_generate_phone_number_with_prefix(self, generator):
        """Test phone number generation with specific prefix"""
        prefix = '+234801'
        phone = generator.generate_phone_number(prefix)

        assert phone.startswith(prefix)
        assert len(phone) == 14

    def test_generate_phone_number_uniqueness(self, generator):
        """Test that generated numbers are reasonably unique"""
        numbers = [generator.generate_phone_number() for _ in range(100)]
        unique_numbers = set(numbers)

        # Should have high uniqueness (allow for some collisions)
        assert len(unique_numbers) > 90

    def test_generate_normal_call_structure(self, generator):
        """Test normal call record structure"""
        base_time = datetime.utcnow()
        call = generator.generate_normal_call(base_time)

        # Verify all required fields present
        assert 'call_date' in call
        assert 'call_time' in call
        assert 'caller_number' in call
        assert 'callee_number' in call
        assert 'duration_seconds' in call
        assert 'call_direction' in call
        assert 'termination_cause' in call

    def test_generate_normal_call_duration(self, generator):
        """Test normal call has realistic duration"""
        base_time = datetime.utcnow()
        call = generator.generate_normal_call(base_time)

        # Normal calls should be 30 seconds to 30 minutes
        assert 30 <= call['duration_seconds'] <= 1800

    def test_generate_normal_call_phone_format(self, generator):
        """Test normal call has valid phone numbers"""
        base_time = datetime.utcnow()
        call = generator.generate_normal_call(base_time)

        assert call['caller_number'].startswith('+234')
        assert call['callee_number'].startswith('+234')
        assert len(call['caller_number']) == 14
        assert len(call['callee_number']) == 14

    def test_generate_simbox_call_structure(self, generator):
        """Test SIM Box call record structure"""
        caller = '+2348012345678'
        base_time = datetime.utcnow()
        call = generator.generate_simbox_call(caller, base_time)

        # Verify structure
        assert call['caller_number'] == caller
        assert call['call_direction'] == 'outbound'
        assert call['termination_cause'] == 'NORMAL_CLEARING'

    def test_generate_simbox_call_short_duration(self, generator):
        """Test SIM Box call has short duration"""
        caller = '+2348012345678'
        base_time = datetime.utcnow()
        call = generator.generate_simbox_call(caller, base_time)

        # SIM Box calls should be very short (1-5 seconds)
        assert 1 <= call['duration_seconds'] <= 5

    def test_generate_dataset_size(self, generator):
        """Test dataset generation produces correct number of records"""
        records, simbox_numbers = generator.generate_dataset(
            total_records=1000,
            simbox_callers=2,
            simbox_calls_per_caller=50
        )

        assert len(records) == 1000
        assert len(simbox_numbers) == 2

    def test_generate_dataset_simbox_calls(self, generator):
        """Test dataset includes correct number of SIM Box calls"""
        simbox_callers = 3
        simbox_calls_per_caller = 75

        records, simbox_numbers = generator.generate_dataset(
            total_records=5000,
            simbox_callers=simbox_callers,
            simbox_calls_per_caller=simbox_calls_per_caller
        )

        # Count SIM Box calls
        simbox_call_count = sum(
            1 for r in records if r['caller_number'] in simbox_numbers
        )

        expected_simbox_calls = simbox_callers * simbox_calls_per_caller
        assert simbox_call_count == expected_simbox_calls

    def test_generate_dataset_normal_calls(self, generator):
        """Test dataset includes normal calls"""
        total_records = 1000
        simbox_callers = 2
        simbox_calls_per_caller = 50

        records, simbox_numbers = generator.generate_dataset(
            total_records=total_records,
            simbox_callers=simbox_callers,
            simbox_calls_per_caller=simbox_calls_per_caller
        )

        # Count normal calls
        normal_call_count = sum(
            1 for r in records if r['caller_number'] not in simbox_numbers
        )

        expected_normal_calls = total_records - (simbox_callers * simbox_calls_per_caller)
        assert normal_call_count == expected_normal_calls

    def test_generate_dataset_mixed_durations(self, generator):
        """Test dataset has both short and normal duration calls"""
        records, simbox_numbers = generator.generate_dataset(
            total_records=500,
            simbox_callers=1,
            simbox_calls_per_caller=50
        )

        # Check for short duration calls (SIM Box)
        short_calls = [r for r in records if r['duration_seconds'] <= 5]
        assert len(short_calls) >= 50

        # Check for normal duration calls
        normal_calls = [r for r in records if r['duration_seconds'] > 30]
        assert len(normal_calls) > 0

    def test_generate_csv_format(self, generator):
        """Test CSV generation produces valid CSV"""
        csv_content, simbox_numbers = generator.generate_csv(
            total_records=100,
            simbox_callers=1,
            simbox_calls_per_caller=10
        )

        # Parse CSV
        csv_reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(csv_reader)

        # Verify CSV structure
        assert len(rows) == 100

        # Verify headers
        expected_headers = [
            'call_date', 'call_time', 'caller_number', 'callee_number',
            'duration_seconds', 'call_direction', 'termination_cause'
        ]
        assert csv_reader.fieldnames == expected_headers

    def test_generate_csv_valid_records(self, generator):
        """Test CSV contains valid record data"""
        csv_content, simbox_numbers = generator.generate_csv(
            total_records=50,
            simbox_callers=1,
            simbox_calls_per_caller=10
        )

        # Parse CSV
        csv_reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(csv_reader)

        # Verify first record
        first_row = rows[0]
        assert len(first_row['call_date']) == 10  # YYYY-MM-DD
        assert len(first_row['call_time']) == 8   # HH:MM:SS
        assert first_row['caller_number'].startswith('+234')
        assert first_row['callee_number'].startswith('+234')
        assert int(first_row['duration_seconds']) > 0

    def test_generate_csv_reproducibility(self):
        """Test that same seed produces same data"""
        gen1 = MockCDRGenerator(seed=123)
        gen2 = MockCDRGenerator(seed=123)

        csv1, simbox1 = gen1.generate_csv(total_records=100)
        csv2, simbox2 = gen2.generate_csv(total_records=100)

        assert csv1 == csv2
        assert simbox1 == simbox2

    def test_generate_dataset_time_distribution(self, generator):
        """Test that calls are distributed across time window"""
        records, _ = generator.generate_dataset(
            total_records=100,
            simbox_callers=1,
            simbox_calls_per_caller=20
        )

        # Parse timestamps
        timestamps = []
        for record in records:
            dt_str = f"{record['call_date']} {record['call_time']}"
            dt = datetime.strptime(dt_str, '%Y-%m-%d %H:%M:%S')
            timestamps.append(dt)

        # Check time span
        min_time = min(timestamps)
        max_time = max(timestamps)
        time_span_hours = (max_time - min_time).total_seconds() / 3600

        # Should span most of the 23-hour window
        assert time_span_hours > 20

    def test_generate_csv_simbox_detection_feasibility(self, generator):
        """Test that generated SIM Box patterns are detectable"""
        csv_content, simbox_numbers = generator.generate_csv(
            total_records=1000,
            simbox_callers=2,
            simbox_calls_per_caller=75
        )

        # Parse CSV and analyze SIM Box callers
        csv_reader = csv.DictReader(io.StringIO(csv_content))
        rows = list(csv_reader)

        for simbox_number in simbox_numbers:
            # Get calls from this SIM Box
            simbox_calls = [r for r in rows if r['caller_number'] == simbox_number]

            # Count unique destinations
            unique_destinations = len(set(r['callee_number'] for r in simbox_calls))

            # Calculate average duration
            durations = [int(r['duration_seconds']) for r in simbox_calls]
            avg_duration = sum(durations) / len(durations)

            # Should meet SDHF detection criteria
            assert unique_destinations >= 50, f"Expected >=50 destinations, got {unique_destinations}"
            assert avg_duration <= 5, f"Expected avg duration <=5s, got {avg_duration}s"

    def test_generate_dataset_edge_cases(self, generator):
        """Test dataset generation with edge case parameters"""
        # Minimum dataset
        records, simbox = generator.generate_dataset(
            total_records=10,
            simbox_callers=1,
            simbox_calls_per_caller=5
        )
        assert len(records) == 10

        # No SIM Box callers
        records, simbox = generator.generate_dataset(
            total_records=100,
            simbox_callers=0,
            simbox_calls_per_caller=0
        )
        assert len(records) == 100
        assert len(simbox) == 0

    def test_generate_dataset_all_simbox(self, generator):
        """Test dataset with only SIM Box calls"""
        total = 200
        records, simbox = generator.generate_dataset(
            total_records=total,
            simbox_callers=2,
            simbox_calls_per_caller=100
        )

        assert len(records) == total

        # All calls should be from SIM Box
        simbox_calls = sum(1 for r in records if r['caller_number'] in simbox)
        assert simbox_calls == total
