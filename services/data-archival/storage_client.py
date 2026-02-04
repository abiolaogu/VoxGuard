"""
S3-Compatible Storage Client for Data Archival

Provides abstraction over S3-compatible storage (AWS S3, MinIO, etc.)
for archival data storage with compression and metadata tracking.
"""
import io
import json
import logging
from datetime import datetime
from typing import Optional, BinaryIO
from dataclasses import dataclass, asdict

import boto3
from botocore.exceptions import ClientError
from botocore.config import Config as BotoConfig

from .config import S3Config, CompressionType


logger = logging.getLogger(__name__)


@dataclass
class ArchiveMetadata:
    """Metadata for archived data"""
    archive_id: str
    table_name: str
    partition_key: str  # e.g., "2024-01" for monthly partition
    record_count: int
    original_size_bytes: int
    compressed_size_bytes: int
    compression_type: str
    created_at: str  # ISO 8601 timestamp
    checksum_sha256: str
    s3_key: str
    retention_until: str  # ISO 8601 timestamp (7 years from creation)


class StorageClient:
    """S3-compatible storage client for data archival"""

    def __init__(self, config: S3Config):
        self.config = config
        self.s3_client = self._create_s3_client()
        self._ensure_bucket_exists()

    def _create_s3_client(self):
        """Create boto3 S3 client with retry configuration"""
        boto_config = BotoConfig(
            region_name=self.config.region,
            retries={
                "max_attempts": 3,
                "mode": "adaptive",
            },
            connect_timeout=10,
            read_timeout=60,
        )

        return boto3.client(
            "s3",
            endpoint_url=self.config.endpoint_url,
            aws_access_key_id=self.config.access_key,
            aws_secret_access_key=self.config.secret_key,
            use_ssl=self.config.use_ssl,
            config=boto_config,
        )

    def _ensure_bucket_exists(self):
        """Create bucket if it doesn't exist"""
        try:
            self.s3_client.head_bucket(Bucket=self.config.bucket_name)
            logger.info(f"Bucket {self.config.bucket_name} exists")
        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "")
            if error_code == "404":
                logger.info(f"Creating bucket {self.config.bucket_name}")
                try:
                    if self.config.region == "us-east-1":
                        self.s3_client.create_bucket(Bucket=self.config.bucket_name)
                    else:
                        self.s3_client.create_bucket(
                            Bucket=self.config.bucket_name,
                            CreateBucketConfiguration={"LocationConstraint": self.config.region},
                        )
                    logger.info(f"Bucket {self.config.bucket_name} created successfully")
                except ClientError as create_error:
                    logger.error(f"Failed to create bucket: {create_error}")
                    raise
            else:
                logger.error(f"Error checking bucket: {e}")
                raise

    def upload_archive(
        self,
        data: BinaryIO,
        metadata: ArchiveMetadata,
        content_type: str = "application/octet-stream",
    ) -> bool:
        """
        Upload archived data to S3 with metadata

        Args:
            data: Binary data stream to upload
            metadata: Archive metadata
            content_type: MIME type of the data

        Returns:
            True if upload successful, False otherwise
        """
        try:
            # Upload data
            self.s3_client.upload_fileobj(
                data,
                self.config.bucket_name,
                metadata.s3_key,
                ExtraArgs={
                    "ContentType": content_type,
                    "Metadata": {
                        "archive-id": metadata.archive_id,
                        "table-name": metadata.table_name,
                        "partition-key": metadata.partition_key,
                        "record-count": str(metadata.record_count),
                        "compression": metadata.compression_type,
                        "checksum-sha256": metadata.checksum_sha256,
                        "created-at": metadata.created_at,
                        "retention-until": metadata.retention_until,
                    },
                    "ServerSideEncryption": "AES256",  # Enable encryption at rest
                },
            )

            # Upload metadata as separate JSON file
            metadata_key = f"metadata/{metadata.archive_id}.json"
            metadata_json = json.dumps(asdict(metadata), indent=2)
            self.s3_client.put_object(
                Bucket=self.config.bucket_name,
                Key=metadata_key,
                Body=metadata_json.encode("utf-8"),
                ContentType="application/json",
                ServerSideEncryption="AES256",
            )

            logger.info(
                f"Uploaded archive {metadata.archive_id} ({metadata.compressed_size_bytes} bytes) "
                f"to {metadata.s3_key}"
            )
            return True

        except ClientError as e:
            logger.error(f"Failed to upload archive {metadata.archive_id}: {e}")
            return False

    def download_archive(self, s3_key: str) -> Optional[bytes]:
        """
        Download archived data from S3

        Args:
            s3_key: S3 object key

        Returns:
            Archive data as bytes, or None if download fails
        """
        try:
            response = self.s3_client.get_object(
                Bucket=self.config.bucket_name,
                Key=s3_key,
            )
            data = response["Body"].read()
            logger.info(f"Downloaded archive from {s3_key} ({len(data)} bytes)")
            return data

        except ClientError as e:
            logger.error(f"Failed to download archive {s3_key}: {e}")
            return None

    def get_metadata(self, archive_id: str) -> Optional[ArchiveMetadata]:
        """
        Retrieve metadata for an archive

        Args:
            archive_id: Unique archive identifier

        Returns:
            ArchiveMetadata object, or None if not found
        """
        metadata_key = f"metadata/{archive_id}.json"
        try:
            response = self.s3_client.get_object(
                Bucket=self.config.bucket_name,
                Key=metadata_key,
            )
            metadata_json = response["Body"].read().decode("utf-8")
            metadata_dict = json.loads(metadata_json)
            return ArchiveMetadata(**metadata_dict)

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "")
            if error_code == "NoSuchKey":
                logger.warning(f"Metadata not found for archive {archive_id}")
            else:
                logger.error(f"Failed to retrieve metadata for {archive_id}: {e}")
            return None

    def list_archives(
        self,
        prefix: str = "archives/",
        max_keys: int = 1000,
    ) -> list[str]:
        """
        List all archives with given prefix

        Args:
            prefix: S3 key prefix to filter archives
            max_keys: Maximum number of keys to return

        Returns:
            List of S3 keys
        """
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=self.config.bucket_name,
                Prefix=prefix,
                MaxKeys=max_keys,
            )

            if "Contents" not in response:
                return []

            return [obj["Key"] for obj in response["Contents"]]

        except ClientError as e:
            logger.error(f"Failed to list archives with prefix {prefix}: {e}")
            return []

    def delete_archive(self, s3_key: str, archive_id: str) -> bool:
        """
        Delete an archive and its metadata (GDPR compliance)

        Args:
            s3_key: S3 object key for archive data
            archive_id: Archive identifier for metadata

        Returns:
            True if deletion successful, False otherwise
        """
        try:
            # Delete archive data
            self.s3_client.delete_object(
                Bucket=self.config.bucket_name,
                Key=s3_key,
            )

            # Delete metadata
            metadata_key = f"metadata/{archive_id}.json"
            self.s3_client.delete_object(
                Bucket=self.config.bucket_name,
                Key=metadata_key,
            )

            logger.info(f"Deleted archive {archive_id} and metadata")
            return True

        except ClientError as e:
            logger.error(f"Failed to delete archive {archive_id}: {e}")
            return False

    def get_archive_size(self, s3_key: str) -> Optional[int]:
        """
        Get size of an archive without downloading

        Args:
            s3_key: S3 object key

        Returns:
            Size in bytes, or None if not found
        """
        try:
            response = self.s3_client.head_object(
                Bucket=self.config.bucket_name,
                Key=s3_key,
            )
            return response["ContentLength"]

        except ClientError as e:
            logger.error(f"Failed to get size of {s3_key}: {e}")
            return None

    def verify_integrity(self, s3_key: str, expected_checksum: str) -> bool:
        """
        Verify archive integrity using SHA-256 checksum

        Args:
            s3_key: S3 object key
            expected_checksum: Expected SHA-256 checksum (hex string)

        Returns:
            True if checksums match, False otherwise
        """
        import hashlib

        try:
            # Download and compute checksum
            data = self.download_archive(s3_key)
            if data is None:
                return False

            actual_checksum = hashlib.sha256(data).hexdigest()
            matches = actual_checksum == expected_checksum

            if not matches:
                logger.error(
                    f"Checksum mismatch for {s3_key}: "
                    f"expected {expected_checksum}, got {actual_checksum}"
                )
            else:
                logger.info(f"Checksum verified for {s3_key}")

            return matches

        except Exception as e:
            logger.error(f"Failed to verify integrity of {s3_key}: {e}")
            return False
