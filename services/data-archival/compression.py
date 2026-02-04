"""
Data Compression Service

Provides compression and decompression for archived data using GZIP or ZSTD.
"""
import gzip
import io
import logging
from typing import BinaryIO

from .config import CompressionType


logger = logging.getLogger(__name__)


# Check if zstandard is available
try:
    import zstandard as zstd
    ZSTD_AVAILABLE = True
except ImportError:
    ZSTD_AVAILABLE = False
    logger.warning("zstandard not available, falling back to GZIP")


class CompressionService:
    """Service for data compression and decompression"""

    def __init__(self, compression_type: CompressionType, compression_level: int = 3):
        """
        Initialize compression service

        Args:
            compression_type: Type of compression to use
            compression_level: Compression level (1-9 for GZIP, 1-22 for ZSTD)
        """
        self.compression_type = compression_type
        self.compression_level = compression_level

        # Validate compression type
        if compression_type == CompressionType.ZSTD and not ZSTD_AVAILABLE:
            logger.warning("ZSTD not available, falling back to GZIP")
            self.compression_type = CompressionType.GZIP

    def compress(self, data: bytes) -> bytes:
        """
        Compress data

        Args:
            data: Raw data to compress

        Returns:
            Compressed data as bytes
        """
        if self.compression_type == CompressionType.NONE:
            return data

        try:
            if self.compression_type == CompressionType.GZIP:
                return self._compress_gzip(data)
            elif self.compression_type == CompressionType.ZSTD:
                return self._compress_zstd(data)
            else:
                raise ValueError(f"Unsupported compression type: {self.compression_type}")

        except Exception as e:
            logger.error(f"Compression failed: {e}")
            raise

    def decompress(self, compressed_data: bytes) -> bytes:
        """
        Decompress data

        Args:
            compressed_data: Compressed data

        Returns:
            Original uncompressed data
        """
        if self.compression_type == CompressionType.NONE:
            return compressed_data

        try:
            if self.compression_type == CompressionType.GZIP:
                return self._decompress_gzip(compressed_data)
            elif self.compression_type == CompressionType.ZSTD:
                return self._decompress_zstd(compressed_data)
            else:
                raise ValueError(f"Unsupported compression type: {self.compression_type}")

        except Exception as e:
            logger.error(f"Decompression failed: {e}")
            raise

    def _compress_gzip(self, data: bytes) -> bytes:
        """Compress using GZIP"""
        output = io.BytesIO()
        with gzip.GzipFile(fileobj=output, mode="wb", compresslevel=self.compression_level) as gz:
            gz.write(data)
        compressed = output.getvalue()

        ratio = (1 - len(compressed) / len(data)) * 100 if len(data) > 0 else 0
        logger.debug(
            f"GZIP compressed {len(data)} bytes to {len(compressed)} bytes "
            f"({ratio:.1f}% reduction)"
        )
        return compressed

    def _decompress_gzip(self, compressed_data: bytes) -> bytes:
        """Decompress using GZIP"""
        with gzip.GzipFile(fileobj=io.BytesIO(compressed_data), mode="rb") as gz:
            decompressed = gz.read()

        logger.debug(f"GZIP decompressed {len(compressed_data)} bytes to {len(decompressed)} bytes")
        return decompressed

    def _compress_zstd(self, data: bytes) -> bytes:
        """Compress using ZSTD"""
        if not ZSTD_AVAILABLE:
            raise RuntimeError("ZSTD compression not available")

        compressor = zstd.ZstdCompressor(level=self.compression_level)
        compressed = compressor.compress(data)

        ratio = (1 - len(compressed) / len(data)) * 100 if len(data) > 0 else 0
        logger.debug(
            f"ZSTD compressed {len(data)} bytes to {len(compressed)} bytes "
            f"({ratio:.1f}% reduction)"
        )
        return compressed

    def _decompress_zstd(self, compressed_data: bytes) -> bytes:
        """Decompress using ZSTD"""
        if not ZSTD_AVAILABLE:
            raise RuntimeError("ZSTD decompression not available")

        decompressor = zstd.ZstdDecompressor()
        decompressed = decompressor.decompress(compressed_data)

        logger.debug(
            f"ZSTD decompressed {len(compressed_data)} bytes to {len(decompressed)} bytes"
        )
        return decompressed

    def get_compression_ratio(self, original_size: int, compressed_size: int) -> float:
        """
        Calculate compression ratio

        Args:
            original_size: Original data size in bytes
            compressed_size: Compressed data size in bytes

        Returns:
            Compression ratio (0.0 to 1.0, where 0.5 means 50% reduction)
        """
        if original_size == 0:
            return 0.0
        return 1.0 - (compressed_size / original_size)

    def estimate_compressed_size(self, original_size: int) -> int:
        """
        Estimate compressed size based on typical compression ratios

        Args:
            original_size: Original data size in bytes

        Returns:
            Estimated compressed size in bytes
        """
        # Typical compression ratios for database dumps
        if self.compression_type == CompressionType.GZIP:
            ratio = 0.30  # GZIP typically achieves 70% reduction
        elif self.compression_type == CompressionType.ZSTD:
            ratio = 0.25  # ZSTD typically achieves 75% reduction
        else:
            ratio = 1.0  # No compression

        return int(original_size * ratio)
