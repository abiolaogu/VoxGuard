"""
Unit tests for compression service
"""
import pytest
from ..compression import CompressionService, CompressionType


class TestCompressionService:
    """Test suite for CompressionService"""

    def test_gzip_compression_and_decompression(self):
        """Test GZIP compression and decompression"""
        service = CompressionService(CompressionType.GZIP, compression_level=6)
        original_data = b"Hello, World! " * 100

        # Compress
        compressed = service.compress(original_data)
        assert len(compressed) < len(original_data)
        assert compressed != original_data

        # Decompress
        decompressed = service.decompress(compressed)
        assert decompressed == original_data

    def test_zstd_compression_and_decompression(self):
        """Test ZSTD compression and decompression"""
        service = CompressionService(CompressionType.ZSTD, compression_level=3)
        original_data = b"Hello, World! " * 100

        try:
            # Compress
            compressed = service.compress(original_data)
            assert len(compressed) < len(original_data)
            assert compressed != original_data

            # Decompress
            decompressed = service.decompress(compressed)
            assert decompressed == original_data
        except RuntimeError:
            # ZSTD may not be available in test environment
            pytest.skip("ZSTD not available")

    def test_no_compression(self):
        """Test that NONE compression type returns data unchanged"""
        service = CompressionService(CompressionType.NONE)
        original_data = b"Hello, World!"

        compressed = service.compress(original_data)
        assert compressed == original_data

        decompressed = service.decompress(compressed)
        assert decompressed == original_data

    def test_compression_ratio_calculation(self):
        """Test compression ratio calculation"""
        service = CompressionService(CompressionType.GZIP)

        ratio = service.get_compression_ratio(1000, 300)
        assert ratio == 0.7  # 70% reduction

        ratio = service.get_compression_ratio(1000, 1000)
        assert ratio == 0.0  # No reduction

        ratio = service.get_compression_ratio(0, 0)
        assert ratio == 0.0  # Edge case

    def test_estimate_compressed_size(self):
        """Test compressed size estimation"""
        service_gzip = CompressionService(CompressionType.GZIP)
        service_zstd = CompressionService(CompressionType.ZSTD)
        service_none = CompressionService(CompressionType.NONE)

        original_size = 1000

        # GZIP should estimate ~30% of original (70% reduction)
        estimated_gzip = service_gzip.estimate_compressed_size(original_size)
        assert estimated_gzip == 300

        # ZSTD should estimate ~25% of original (75% reduction)
        estimated_zstd = service_zstd.estimate_compressed_size(original_size)
        assert estimated_zstd == 250

        # No compression should estimate 100% of original
        estimated_none = service_none.estimate_compressed_size(original_size)
        assert estimated_none == 1000

    def test_compression_reduces_size_with_repetitive_data(self):
        """Test that compression significantly reduces size with repetitive data"""
        service = CompressionService(CompressionType.GZIP, compression_level=9)

        # Highly repetitive data
        original_data = b"A" * 10000
        compressed = service.compress(original_data)

        # Should achieve >90% compression with repetitive data
        ratio = service.get_compression_ratio(len(original_data), len(compressed))
        assert ratio > 0.90

    def test_compression_with_random_data(self):
        """Test compression with random (incompressible) data"""
        import os

        service = CompressionService(CompressionType.GZIP)

        # Random data (hard to compress)
        original_data = os.urandom(1000)
        compressed = service.compress(original_data)

        # Compression may not reduce size much for random data
        # but should still decompress correctly
        decompressed = service.decompress(compressed)
        assert decompressed == original_data

    def test_empty_data_compression(self):
        """Test compression of empty data"""
        service = CompressionService(CompressionType.GZIP)

        original_data = b""
        compressed = service.compress(original_data)
        decompressed = service.decompress(compressed)

        assert decompressed == original_data

    def test_large_data_compression(self):
        """Test compression of large data"""
        service = CompressionService(CompressionType.GZIP)

        # 1 MB of data
        original_data = b"Hello, World! " * 100000
        compressed = service.compress(original_data)
        decompressed = service.decompress(compressed)

        assert decompressed == original_data
        assert len(compressed) < len(original_data)

    def test_compression_level_affects_ratio(self):
        """Test that compression level affects compression ratio"""
        data = b"Hello, World! " * 1000

        service_low = CompressionService(CompressionType.GZIP, compression_level=1)
        service_high = CompressionService(CompressionType.GZIP, compression_level=9)

        compressed_low = service_low.compress(data)
        compressed_high = service_high.compress(data)

        # Higher compression level should produce smaller output
        assert len(compressed_high) <= len(compressed_low)

        # Both should decompress correctly
        assert service_low.decompress(compressed_low) == data
        assert service_high.decompress(compressed_high) == data
