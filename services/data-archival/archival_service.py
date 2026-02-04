"""
Archival Service

Core service for archiving old data to cold storage with compression.
Implements retention policies and supports restoration.
"""
import io
import json
import logging
import hashlib
from datetime import datetime, timedelta
from typing import Optional, List, Dict
from uuid import uuid4

import psycopg2
from psycopg2.extras import RealDictCursor

from .config import Config, ArchivalConfig
from .storage_client import StorageClient, ArchiveMetadata
from .compression import CompressionService


logger = logging.getLogger(__name__)


class ArchivalService:
    """Service for archiving data to cold storage"""

    def __init__(self, config: Config):
        self.config = config
        self.storage = StorageClient(config.s3)
        self.compression = CompressionService(
            config.archival.compression,
            config.archival.compression_level,
        )
        self.db_conn = self._create_db_connection()

    def _create_db_connection(self):
        """Create PostgreSQL database connection"""
        return psycopg2.connect(
            host=self.config.db.host,
            port=self.config.db.port,
            database=self.config.db.database,
            user=self.config.db.user,
            password=self.config.db.password,
            cursor_factory=RealDictCursor,
        )

    def archive_table(
        self,
        table_name: str,
        partition_key: str,
        cutoff_date: datetime,
    ) -> Optional[ArchiveMetadata]:
        """
        Archive data from a table older than cutoff date

        Args:
            table_name: Name of the table to archive
            partition_key: Partition identifier (e.g., "2024-01")
            cutoff_date: Archive data older than this date

        Returns:
            ArchiveMetadata if successful, None otherwise
        """
        try:
            # Query data to archive
            records = self._query_records_to_archive(table_name, cutoff_date)
            if not records:
                logger.info(f"No records to archive for {table_name} before {cutoff_date}")
                return None

            # Convert to JSON
            records_json = json.dumps(records, default=str, indent=2)
            original_size = len(records_json.encode("utf-8"))

            # Compress data
            compressed_data = self.compression.compress(records_json.encode("utf-8"))
            compressed_size = len(compressed_data)

            # Calculate checksum
            checksum = hashlib.sha256(compressed_data).hexdigest()

            # Create metadata
            archive_id = str(uuid4())
            now = datetime.utcnow()
            retention_until = now + timedelta(days=self.config.archival.cold_retention_years * 365)

            s3_key = f"{self.config.archival.archive_prefix}/{table_name}/{partition_key}/{archive_id}.{self.config.archival.compression.value}"

            metadata = ArchiveMetadata(
                archive_id=archive_id,
                table_name=table_name,
                partition_key=partition_key,
                record_count=len(records),
                original_size_bytes=original_size,
                compressed_size_bytes=compressed_size,
                compression_type=self.config.archival.compression.value,
                created_at=now.isoformat(),
                checksum_sha256=checksum,
                s3_key=s3_key,
                retention_until=retention_until.isoformat(),
            )

            # Upload to S3
            data_stream = io.BytesIO(compressed_data)
            success = self.storage.upload_archive(data_stream, metadata)

            if not success:
                logger.error(f"Failed to upload archive for {table_name}")
                return None

            # Delete archived records from hot storage
            deleted_count = self._delete_archived_records(table_name, cutoff_date)
            logger.info(
                f"Archived and deleted {deleted_count} records from {table_name} "
                f"(compression ratio: {self.compression.get_compression_ratio(original_size, compressed_size):.2%})"
            )

            return metadata

        except Exception as e:
            logger.error(f"Failed to archive {table_name}: {e}")
            return None

    def _query_records_to_archive(
        self,
        table_name: str,
        cutoff_date: datetime,
    ) -> List[Dict]:
        """Query records older than cutoff date"""
        # Determine date column based on table
        date_column = self._get_date_column(table_name)

        query = f"""
        SELECT *
        FROM {table_name}
        WHERE {date_column} < %s
        ORDER BY {date_column}
        LIMIT %s
        """

        with self.db_conn.cursor() as cursor:
            cursor.execute(query, (cutoff_date, self.config.archival.chunk_size))
            records = cursor.fetchall()
            return [dict(record) for record in records]

    def _delete_archived_records(
        self,
        table_name: str,
        cutoff_date: datetime,
    ) -> int:
        """Delete records that have been archived"""
        date_column = self._get_date_column(table_name)

        query = f"""
        DELETE FROM {table_name}
        WHERE {date_column} < %s
        """

        with self.db_conn.cursor() as cursor:
            cursor.execute(query, (cutoff_date,))
            deleted_count = cursor.rowcount
            self.db_conn.commit()
            return deleted_count

    def _get_date_column(self, table_name: str) -> str:
        """Get the date column name for a table"""
        # Common date columns by table
        date_columns = {
            "acm_alerts": "detected_at",
            "audit_events": "created_at",
            "call_detail_records": "call_start_time",
            "gateway_blacklist_history": "created_at",
            "fraud_investigations": "created_at",
        }
        return date_columns.get(table_name, "created_at")

    def restore_archive(self, archive_id: str) -> Optional[List[Dict]]:
        """
        Restore archived data back to hot storage

        Args:
            archive_id: Unique archive identifier

        Returns:
            List of restored records, or None if restoration fails
        """
        try:
            # Get metadata
            metadata = self.storage.get_metadata(archive_id)
            if metadata is None:
                logger.error(f"Metadata not found for archive {archive_id}")
                return None

            # Download archive
            compressed_data = self.storage.download_archive(metadata.s3_key)
            if compressed_data is None:
                logger.error(f"Failed to download archive {archive_id}")
                return None

            # Verify integrity
            actual_checksum = hashlib.sha256(compressed_data).hexdigest()
            if actual_checksum != metadata.checksum_sha256:
                logger.error(
                    f"Checksum mismatch for archive {archive_id}: "
                    f"expected {metadata.checksum_sha256}, got {actual_checksum}"
                )
                return None

            # Decompress
            decompressed_data = self.compression.decompress(compressed_data)
            records_json = decompressed_data.decode("utf-8")
            records = json.loads(records_json)

            # Insert records back into table
            restored_count = self._insert_restored_records(metadata.table_name, records)
            logger.info(f"Restored {restored_count} records from archive {archive_id}")

            return records

        except Exception as e:
            logger.error(f"Failed to restore archive {archive_id}: {e}")
            return None

    def _insert_restored_records(self, table_name: str, records: List[Dict]) -> int:
        """Insert restored records back into the database"""
        if not records:
            return 0

        # Generate INSERT statement dynamically
        columns = list(records[0].keys())
        placeholders = ", ".join(["%s"] * len(columns))
        column_names = ", ".join(columns)

        query = f"""
        INSERT INTO {table_name} ({column_names})
        VALUES ({placeholders})
        ON CONFLICT DO NOTHING
        """

        inserted_count = 0
        with self.db_conn.cursor() as cursor:
            for record in records:
                values = [record[col] for col in columns]
                try:
                    cursor.execute(query, values)
                    inserted_count += cursor.rowcount
                except Exception as e:
                    logger.warning(f"Failed to insert record: {e}")
                    continue

            self.db_conn.commit()

        return inserted_count

    def list_archives_for_table(self, table_name: str) -> List[ArchiveMetadata]:
        """
        List all archives for a specific table

        Args:
            table_name: Name of the table

        Returns:
            List of ArchiveMetadata objects
        """
        prefix = f"{self.config.archival.archive_prefix}/{table_name}/"
        s3_keys = self.storage.list_archives(prefix)

        archives = []
        for s3_key in s3_keys:
            # Extract archive ID from key
            # Format: archives/{table}/{partition}/{archive_id}.{ext}
            parts = s3_key.split("/")
            if len(parts) >= 4:
                filename = parts[-1]
                archive_id = filename.split(".")[0]

                metadata = self.storage.get_metadata(archive_id)
                if metadata:
                    archives.append(metadata)

        return archives

    def get_retention_statistics(self) -> Dict[str, any]:
        """
        Get statistics about data retention and archival

        Returns:
            Dictionary with retention statistics
        """
        stats = {
            "total_archives": 0,
            "total_archived_records": 0,
            "total_compressed_size_mb": 0.0,
            "total_original_size_mb": 0.0,
            "compression_ratio": 0.0,
            "by_table": {},
        }

        for table_name in self.config.archival.tables_to_archive:
            archives = self.list_archives_for_table(table_name)
            if not archives:
                continue

            table_stats = {
                "archive_count": len(archives),
                "record_count": sum(a.record_count for a in archives),
                "compressed_size_mb": sum(a.compressed_size_bytes for a in archives) / (1024 * 1024),
                "original_size_mb": sum(a.original_size_bytes for a in archives) / (1024 * 1024),
            }

            stats["by_table"][table_name] = table_stats
            stats["total_archives"] += table_stats["archive_count"]
            stats["total_archived_records"] += table_stats["record_count"]
            stats["total_compressed_size_mb"] += table_stats["compressed_size_mb"]
            stats["total_original_size_mb"] += table_stats["original_size_mb"]

        if stats["total_original_size_mb"] > 0:
            stats["compression_ratio"] = 1.0 - (
                stats["total_compressed_size_mb"] / stats["total_original_size_mb"]
            )

        return stats

    def delete_expired_archives(self) -> int:
        """
        Delete archives that have exceeded retention period (GDPR compliance)

        Returns:
            Number of archives deleted
        """
        now = datetime.utcnow()
        deleted_count = 0

        for table_name in self.config.archival.tables_to_archive:
            archives = self.list_archives_for_table(table_name)
            for metadata in archives:
                retention_until = datetime.fromisoformat(metadata.retention_until)
                if now > retention_until:
                    logger.info(f"Deleting expired archive {metadata.archive_id}")
                    success = self.storage.delete_archive(metadata.s3_key, metadata.archive_id)
                    if success:
                        deleted_count += 1

        logger.info(f"Deleted {deleted_count} expired archives")
        return deleted_count

    def close(self):
        """Close database connection"""
        if self.db_conn:
            self.db_conn.close()
