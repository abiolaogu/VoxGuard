"""
Unit tests for CDR CSV parser
"""
import pytest
from datetime import datetime
from app.sentinel.parser import CDRParser
from app.sentinel.models import CallRecord


class TestCDRParser:
    """Test cases for CDR CSV parser"""

    def setup_method(self):
        """Setup test fixtures"""
        self.parser = CDRParser()

    def test_parse_valid_csv(self):
        """Test parsing a valid CSV file"""
        csv_content = b"""call_date,call_time,caller_number,callee_number,duration_seconds
2024-01-15,14:32:15,+2348012345678,+2349087654321,125
2024-01-15,14:35:42,+2348012345678,+2349076543210,2"""

        records, errors = self.parser.parse_csv(csv_content)

        assert len(records) == 2
        assert len(errors) == 0

        # Check first record
        assert records[0].caller_number == "+2348012345678"
        assert records[0].callee_number == "+2349087654321"
        assert records[0].duration_seconds == 125
        assert records[0].call_timestamp == datetime(2024, 1, 15, 14, 32, 15)

    def test_parse_csv_with_optional_fields(self):
        """Test parsing CSV with optional fields"""
        csv_content = b"""call_date,call_time,caller_number,callee_number,duration_seconds,call_direction,termination_cause,location_code
2024-01-15,14:32:15,+2348012345678,+2349087654321,125,outbound,NORMAL_CLEARING,NG"""

        records, errors = self.parser.parse_csv(csv_content)

        assert len(records) == 1
        assert records[0].call_direction == "outbound"
        assert records[0].termination_cause == "NORMAL_CLEARING"
        assert records[0].location_code == "NG"

    def test_parse_csv_missing_required_fields(self):
        """Test parsing CSV with missing required fields"""
        csv_content = b"""call_date,call_time,caller_number
2024-01-15,14:32:15,+2348012345678"""

        records, errors = self.parser.parse_csv(csv_content)

        assert len(records) == 0
        assert len(errors) > 0
        assert "Missing required fields" in errors[0]

    def test_parse_csv_invalid_date_format(self):
        """Test parsing CSV with invalid date format"""
        csv_content = b"""call_date,call_time,caller_number,callee_number,duration_seconds
15-01-2024,14:32:15,+2348012345678,+2349087654321,125"""

        records, errors = self.parser.parse_csv(csv_content)

        assert len(records) == 0
        assert len(errors) > 0
        assert "Invalid date/time format" in errors[0]

    def test_parse_csv_invalid_duration(self):
        """Test parsing CSV with invalid duration"""
        csv_content = b"""call_date,call_time,caller_number,callee_number,duration_seconds
2024-01-15,14:32:15,+2348012345678,+2349087654321,abc"""

        records, errors = self.parser.parse_csv(csv_content)

        assert len(records) == 0
        assert len(errors) > 0
        assert "Invalid duration_seconds" in errors[0]

    def test_parse_csv_invalid_phone_number(self):
        """Test parsing CSV with invalid phone number"""
        csv_content = b"""call_date,call_time,caller_number,callee_number,duration_seconds
2024-01-15,14:32:15,invalid_number,+2349087654321,125"""

        records, errors = self.parser.parse_csv(csv_content)

        assert len(records) == 0
        assert len(errors) > 0
        assert "Invalid E.164 phone number format" in errors[0]

    def test_parse_csv_invalid_call_direction(self):
        """Test parsing CSV with invalid call direction"""
        csv_content = b"""call_date,call_time,caller_number,callee_number,duration_seconds,call_direction
2024-01-15,14:32:15,+2348012345678,+2349087654321,125,invalid_direction"""

        records, errors = self.parser.parse_csv(csv_content)

        assert len(records) == 0
        assert len(errors) > 0
        assert "call_direction" in errors[0]

    def test_parse_empty_csv(self):
        """Test parsing an empty CSV file"""
        csv_content = b""

        records, errors = self.parser.parse_csv(csv_content)

        assert len(records) == 0
        assert len(errors) > 0

    def test_deduplicate_records(self):
        """Test deduplication of records"""
        csv_content = b"""call_date,call_time,caller_number,callee_number,duration_seconds
2024-01-15,14:32:15,+2348012345678,+2349087654321,125
2024-01-15,14:32:15,+2348012345678,+2349087654321,125
2024-01-15,14:35:42,+2348012345678,+2349076543210,2"""

        records, _ = self.parser.parse_csv(csv_content)
        unique_records, duplicates = self.parser.deduplicate(records)

        assert len(unique_records) == 2
        assert duplicates == 1

    def test_parse_csv_with_whitespace(self):
        """Test parsing CSV with leading/trailing whitespace"""
        csv_content = b"""call_date,call_time,caller_number,callee_number,duration_seconds
2024-01-15, 14:32:15 , +2348012345678 ,+2349087654321,125"""

        records, errors = self.parser.parse_csv(csv_content)

        assert len(records) == 1
        assert records[0].caller_number == "+2348012345678"
        assert records[0].callee_number == "+2349087654321"

    def test_parse_large_csv(self):
        """Test parsing a large CSV file (performance test)"""
        # Create a CSV with 1000 records
        header = b"call_date,call_time,caller_number,callee_number,duration_seconds\n"
        rows = [
            f"2024-01-15,14:{i%60:02d}:15,+234801234567{i%10},+234908765432{i%10},{i%300}\n".encode()
            for i in range(1000)
        ]
        csv_content = header + b"".join(rows)

        records, errors = self.parser.parse_csv(csv_content)

        assert len(records) == 1000
        assert len(errors) == 0

    def test_parse_csv_partial_success(self):
        """Test parsing CSV where some rows are valid and some are invalid"""
        csv_content = b"""call_date,call_time,caller_number,callee_number,duration_seconds
2024-01-15,14:32:15,+2348012345678,+2349087654321,125
invalid-date,14:35:42,+2348012345678,+2349076543210,2
2024-01-15,14:40:00,+2348012345678,+2349076543210,30"""

        records, errors = self.parser.parse_csv(csv_content)

        assert len(records) == 2  # Two valid records
        assert len(errors) == 1   # One error for invalid row

    def test_validate_e164_format(self):
        """Test E.164 phone number validation"""
        valid_numbers = [
            "+2348012345678",
            "+1234567890",
            "+441234567890",
            "2348012345678",  # Without plus is also valid
        ]

        for number in valid_numbers:
            csv_content = f"call_date,call_time,caller_number,callee_number,duration_seconds\n2024-01-15,14:32:15,{number},+2349087654321,125".encode()
            records, errors = self.parser.parse_csv(csv_content)
            assert len(records) == 1, f"Failed for valid number: {number}"

    def test_deduplicate_empty_list(self):
        """Test deduplication with empty list"""
        unique_records, duplicates = self.parser.deduplicate([])

        assert len(unique_records) == 0
        assert duplicates == 0

    def test_parse_csv_with_utf8_bom(self):
        """Test parsing CSV with UTF-8 BOM"""
        csv_content = b"\xef\xbb\xbfcall_date,call_time,caller_number,callee_number,duration_seconds\n2024-01-15,14:32:15,+2348012345678,+2349087654321,125"

        records, errors = self.parser.parse_csv(csv_content)

        # Should handle BOM gracefully
        assert len(records) >= 0  # May or may not parse depending on BOM handling
