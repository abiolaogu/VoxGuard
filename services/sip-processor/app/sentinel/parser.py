"""
CDR CSV Parser

Handles parsing of Call Detail Record CSV files with validation and error handling.
"""
import csv
import io
from datetime import datetime
from typing import List, Tuple
from .models import CallRecord


class CDRParser:
    """Parser for CDR CSV files"""

    REQUIRED_FIELDS = ['call_date', 'call_time', 'caller_number', 'callee_number', 'duration_seconds']
    OPTIONAL_FIELDS = ['call_direction', 'termination_cause', 'location_code']

    def __init__(self):
        self.errors = []

    def parse_csv(self, file_content: bytes) -> Tuple[List[CallRecord], List[str]]:
        """
        Parse CDR CSV file content

        Args:
            file_content: Raw bytes of CSV file

        Returns:
            Tuple of (list of CallRecord objects, list of error messages)
        """
        self.errors = []
        records = []

        try:
            # Decode bytes to string
            content = file_content.decode('utf-8')
            csv_reader = csv.DictReader(io.StringIO(content))

            # Validate headers
            if not self._validate_headers(csv_reader.fieldnames):
                return [], self.errors

            # Parse each row
            for row_num, row in enumerate(csv_reader, start=2):  # Start at 2 (header is row 1)
                try:
                    record = self._parse_row(row)
                    if record:
                        records.append(record)
                except Exception as e:
                    self.errors.append(f"Row {row_num}: {str(e)}")

        except Exception as e:
            self.errors.append(f"Failed to parse CSV file: {str(e)}")

        return records, self.errors

    def _validate_headers(self, headers: List[str]) -> bool:
        """Validate that required headers are present"""
        if not headers:
            self.errors.append("CSV file has no headers")
            return False

        missing_fields = [field for field in self.REQUIRED_FIELDS if field not in headers]
        if missing_fields:
            self.errors.append(f"Missing required fields: {', '.join(missing_fields)}")
            return False

        return True

    def _parse_row(self, row: dict) -> CallRecord:
        """Parse a single CSV row into a CallRecord"""
        # Combine date and time
        call_date = row['call_date'].strip()
        call_time = row['call_time'].strip()

        try:
            call_timestamp = datetime.strptime(f"{call_date} {call_time}", "%Y-%m-%d %H:%M:%S")
        except ValueError:
            raise ValueError(f"Invalid date/time format: {call_date} {call_time}")

        # Parse duration
        try:
            duration_seconds = int(row['duration_seconds'])
        except ValueError:
            raise ValueError(f"Invalid duration_seconds: {row['duration_seconds']}")

        # Create CallRecord with validation
        record = CallRecord(
            call_timestamp=call_timestamp,
            caller_number=row['caller_number'].strip(),
            callee_number=row['callee_number'].strip(),
            duration_seconds=duration_seconds,
            call_direction=row.get('call_direction', '').strip() or None,
            termination_cause=row.get('termination_cause', '').strip() or None,
            location_code=row.get('location_code', '').strip() or None
        )

        return record

    def deduplicate(self, records: List[CallRecord]) -> Tuple[List[CallRecord], int]:
        """
        Remove duplicate records based on (caller, callee, timestamp)

        Args:
            records: List of CallRecord objects

        Returns:
            Tuple of (deduplicated list, number of duplicates found)
        """
        seen = set()
        unique_records = []
        duplicates = 0

        for record in records:
            key = (record.caller_number, record.callee_number, record.call_timestamp)
            if key not in seen:
                seen.add(key)
                unique_records.append(record)
            else:
                duplicates += 1

        return unique_records, duplicates
