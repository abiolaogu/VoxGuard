"""
Mock CDR Data Generator

Generates realistic Call Detail Record (CDR) data for testing Sentinel detection engine.
"""
import random
import csv
import io
from datetime import datetime, timedelta
from typing import List, Tuple


class MockCDRGenerator:
    """Generate mock CDR data for testing"""

    # Nigerian phone number prefixes
    NIGERIAN_PREFIXES = [
        '+234701', '+234702', '+234703', '+234704', '+234705',
        '+234706', '+234707', '+234708', '+234709', '+234801',
        '+234802', '+234803', '+234804', '+234805', '+234806',
        '+234807', '+234808', '+234809', '+234810', '+234811',
        '+234812', '+234813', '+234814', '+234815', '+234816',
        '+234817', '+234818', '+234901', '+234902', '+234903',
        '+234904', '+234905', '+234906', '+234907', '+234908',
        '+234909', '+234910', '+234911', '+234912', '+234913',
        '+234914', '+234915', '+234916', '+234917', '+234918'
    ]

    TERMINATION_CAUSES = [
        'NORMAL_CLEARING',
        'USER_BUSY',
        'NO_ANSWER',
        'CALL_REJECTED',
        'NETWORK_ERROR'
    ]

    CALL_DIRECTIONS = ['inbound', 'outbound']

    def __init__(self, seed: int = 42):
        """
        Initialize generator with optional seed for reproducibility

        Args:
            seed: Random seed for reproducible data generation
        """
        self._rng = random.Random(seed)
        # Fixed anchor time keeps generated datasets reproducible across runs.
        self._base_time = datetime(2026, 1, 1, 0, 0, 0)

    def generate_phone_number(self, prefix: str = None) -> str:
        """
        Generate a random Nigerian phone number

        Args:
            prefix: Optional prefix to use, otherwise random

        Returns:
            Phone number in E.164 format
        """
        if prefix is None:
            prefix = self._rng.choice(self.NIGERIAN_PREFIXES)

        # Generate 7 remaining digits
        suffix = ''.join([str(self._rng.randint(0, 9)) for _ in range(7)])
        return f"{prefix}{suffix}"

    def generate_normal_call(self, base_time: datetime) -> dict:
        """
        Generate a normal call record

        Args:
            base_time: Base timestamp for the call

        Returns:
            Dictionary with call record fields
        """
        # Normal calls: 30 seconds to 30 minutes duration
        duration = self._rng.randint(30, 1800)

        return {
            'call_date': base_time.strftime('%Y-%m-%d'),
            'call_time': base_time.strftime('%H:%M:%S'),
            'caller_number': self.generate_phone_number(),
            'callee_number': self.generate_phone_number(),
            'duration_seconds': duration,
            'call_direction': self._rng.choice(self.CALL_DIRECTIONS),
            'termination_cause': self._rng.choice(self.TERMINATION_CAUSES)
        }

    def generate_simbox_call(self, caller: str, base_time: datetime) -> dict:
        """
        Generate a SIM Box fraud call (short duration, high frequency)

        Args:
            caller: The caller number (SIM Box)
            base_time: Base timestamp for the call

        Returns:
            Dictionary with call record fields
        """
        # SIM Box calls: Very short duration (1-5 seconds)
        duration = self._rng.randint(1, 5)

        return {
            'call_date': base_time.strftime('%Y-%m-%d'),
            'call_time': base_time.strftime('%H:%M:%S'),
            'caller_number': caller,
            'callee_number': self.generate_phone_number(),
            'duration_seconds': duration,
            'call_direction': 'outbound',
            'termination_cause': 'NORMAL_CLEARING'
        }

    def generate_dataset(
        self,
        total_records: int = 5000,
        simbox_callers: int = 3,
        simbox_calls_per_caller: int = 75
    ) -> Tuple[List[dict], List[str]]:
        """
        Generate a complete CDR dataset with normal and fraudulent calls

        Args:
            total_records: Total number of records to generate
            simbox_callers: Number of SIM Box fraudsters to include
            simbox_calls_per_caller: Number of calls per SIM Box caller

        Returns:
            Tuple of (list of call records, list of SIM Box caller numbers)
        """
        records = []
        base_time = self._base_time

        # Generate SIM Box fraudulent calls
        simbox_numbers = [self.generate_phone_number() for _ in range(simbox_callers)]

        for simbox_number in simbox_numbers:
            for i in range(simbox_calls_per_caller):
                # Spread calls across the time window
                call_time = base_time + timedelta(
                    minutes=self._rng.randint(0, 23 * 60)
                )
                record = self.generate_simbox_call(simbox_number, call_time)
                records.append(record)

        # Generate normal calls to fill the dataset
        normal_calls_needed = total_records - len(records)

        for i in range(normal_calls_needed):
            # Random time within the window
            call_time = base_time + timedelta(
                    minutes=self._rng.randint(0, 23 * 60)
            )
            record = self.generate_normal_call(call_time)
            records.append(record)

        # Shuffle records to mix normal and fraudulent calls
        self._rng.shuffle(records)

        return records, simbox_numbers

    def generate_csv(
        self,
        total_records: int = 5000,
        simbox_callers: int = 3,
        simbox_calls_per_caller: int = 75
    ) -> Tuple[str, List[str]]:
        """
        Generate CDR dataset as CSV string

        Args:
            total_records: Total number of records to generate
            simbox_callers: Number of SIM Box fraudsters to include
            simbox_calls_per_caller: Number of calls per SIM Box caller

        Returns:
            Tuple of (CSV string, list of SIM Box caller numbers)
        """
        records, simbox_numbers = self.generate_dataset(
            total_records,
            simbox_callers,
            simbox_calls_per_caller
        )

        # Generate CSV
        output = io.StringIO()
        fieldnames = [
            'call_date', 'call_time', 'caller_number', 'callee_number',
            'duration_seconds', 'call_direction', 'termination_cause'
        ]

        writer = csv.DictWriter(output, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(records)

        csv_content = output.getvalue()
        output.close()

        return csv_content, simbox_numbers

    def save_to_file(
        self,
        filename: str,
        total_records: int = 5000,
        simbox_callers: int = 3,
        simbox_calls_per_caller: int = 75
    ) -> List[str]:
        """
        Generate and save CDR dataset to CSV file

        Args:
            filename: Output filename
            total_records: Total number of records to generate
            simbox_callers: Number of SIM Box fraudsters to include
            simbox_calls_per_caller: Number of calls per SIM Box caller

        Returns:
            List of SIM Box caller numbers (for verification)
        """
        csv_content, simbox_numbers = self.generate_csv(
            total_records,
            simbox_callers,
            simbox_calls_per_caller
        )

        with open(filename, 'w') as f:
            f.write(csv_content)

        print(f"Generated {total_records} CDR records to {filename}")
        print(f"SIM Box callers (for testing): {simbox_numbers}")

        return simbox_numbers


# CLI interface for standalone usage
if __name__ == "__main__":
    import sys

    generator = MockCDRGenerator()

    # Default parameters
    output_file = "mock_cdr_data.csv"
    total_records = 5000
    simbox_callers = 3
    simbox_calls_per_caller = 75

    # Parse command line arguments
    if len(sys.argv) > 1:
        output_file = sys.argv[1]
    if len(sys.argv) > 2:
        total_records = int(sys.argv[2])
    if len(sys.argv) > 3:
        simbox_callers = int(sys.argv[3])
    if len(sys.argv) > 4:
        simbox_calls_per_caller = int(sys.argv[4])

    # Generate dataset
    simbox_numbers = generator.save_to_file(
        output_file,
        total_records,
        simbox_callers,
        simbox_calls_per_caller
    )

    print("\nDataset generation complete!")
    print(f"Total records: {total_records}")
    print(f"SIM Box callers: {simbox_callers}")
    print(f"Calls per SIM Box: {simbox_calls_per_caller}")
    print(f"\nExpected detections: {simbox_numbers}")
