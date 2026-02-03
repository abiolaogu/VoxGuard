"""
SFTP CDR Uploader

Handles secure SFTP uploads of daily CDR reports to NCC servers.
"""

import logging
import os
from pathlib import Path
from typing import List, Optional

import paramiko
from paramiko import SSHClient, AutoAddPolicy

from .config import SftpConfig

logger = logging.getLogger(__name__)


class SftpUploadError(Exception):
    """SFTP upload error."""
    pass


class SftpUploader:
    """
    Secure SFTP uploader for NCC CDR reports.

    Handles:
    - SSH key authentication
    - Atomic file transfers (temp → final)
    - Upload verification
    - Connection management
    """

    def __init__(self, config: SftpConfig):
        """
        Initialize SFTP uploader.

        Args:
            config: SFTP configuration
        """
        self.config = config
        self.client: Optional[SSHClient] = None
        self.sftp: Optional[paramiko.SFTPClient] = None

    def __enter__(self):
        """Context manager entry."""
        self.connect()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.disconnect()

    def connect(self) -> None:
        """
        Establish SFTP connection.

        Raises:
            SftpUploadError: If connection fails
        """
        try:
            # Create SSH client
            self.client = SSHClient()
            self.client.set_missing_host_key_policy(AutoAddPolicy())

            # Load private key
            if not os.path.exists(self.config.private_key_path):
                raise SftpUploadError(
                    f"Private key not found: {self.config.private_key_path}"
                )

            private_key = paramiko.RSAKey.from_private_key_file(
                self.config.private_key_path
            )

            # Connect
            logger.info(f"Connecting to SFTP server: {self.config.host}:{self.config.port}")
            self.client.connect(
                hostname=self.config.host,
                port=self.config.port,
                username=self.config.username,
                pkey=private_key,
                timeout=30,
            )

            # Open SFTP channel
            self.sftp = self.client.open_sftp()
            logger.info("SFTP connection established")

        except Exception as e:
            raise SftpUploadError(f"Failed to connect to SFTP server: {e}")

    def disconnect(self) -> None:
        """Close SFTP connection."""
        if self.sftp:
            self.sftp.close()
            self.sftp = None

        if self.client:
            self.client.close()
            self.client = None

        logger.info("SFTP connection closed")

    def upload_file(
        self,
        local_path: str,
        remote_filename: str,
        verify: bool = True
    ) -> None:
        """
        Upload a file to NCC SFTP server with atomic transfer.

        Args:
            local_path: Path to local file
            remote_filename: Remote filename (without path)
            verify: Verify upload by checking file size

        Raises:
            SftpUploadError: If upload fails
        """
        if not self.sftp:
            raise SftpUploadError("Not connected to SFTP server")

        if not os.path.exists(local_path):
            raise SftpUploadError(f"Local file not found: {local_path}")

        local_size = os.path.getsize(local_path)

        # Use atomic transfer: upload to temp file, then rename
        remote_path = os.path.join(self.config.remote_path, remote_filename)
        remote_temp_path = remote_path + ".tmp"

        try:
            logger.info(f"Uploading {local_path} → {remote_path} ({local_size} bytes)")

            # Upload to temp file
            self.sftp.put(local_path, remote_temp_path)

            # Verify size if requested
            if verify:
                remote_stat = self.sftp.stat(remote_temp_path)
                if remote_stat.st_size != local_size:
                    raise SftpUploadError(
                        f"Size mismatch: local={local_size}, remote={remote_stat.st_size}"
                    )

            # Atomic rename
            self.sftp.rename(remote_temp_path, remote_path)

            logger.info(f"Successfully uploaded: {remote_filename}")

        except Exception as e:
            # Clean up temp file on error
            try:
                self.sftp.remove(remote_temp_path)
            except:
                pass

            raise SftpUploadError(f"Failed to upload {remote_filename}: {e}")

    def upload_batch(
        self,
        files: List[tuple[str, str]]
    ) -> None:
        """
        Upload multiple files in a batch.

        Args:
            files: List of (local_path, remote_filename) tuples

        Raises:
            SftpUploadError: If any upload fails
        """
        if not self.sftp:
            raise SftpUploadError("Not connected to SFTP server")

        logger.info(f"Uploading batch of {len(files)} files")

        failed = []
        for local_path, remote_filename in files:
            try:
                self.upload_file(local_path, remote_filename)
            except SftpUploadError as e:
                logger.error(f"Failed to upload {remote_filename}: {e}")
                failed.append((remote_filename, str(e)))

        if failed:
            failures = ", ".join(f[0] for f in failed)
            raise SftpUploadError(f"Failed to upload {len(failed)} files: {failures}")

        logger.info(f"Successfully uploaded all {len(files)} files")

    def list_remote_files(self, pattern: Optional[str] = None) -> List[str]:
        """
        List files in remote directory.

        Args:
            pattern: Optional filename pattern to filter

        Returns:
            List of filenames
        """
        if not self.sftp:
            raise SftpUploadError("Not connected to SFTP server")

        try:
            files = self.sftp.listdir(self.config.remote_path)

            if pattern:
                import fnmatch
                files = [f for f in files if fnmatch.fnmatch(f, pattern)]

            return files

        except Exception as e:
            raise SftpUploadError(f"Failed to list remote files: {e}")

    def verify_connectivity(self) -> bool:
        """
        Test SFTP connectivity.

        Returns:
            True if connected and can access remote directory
        """
        try:
            if not self.sftp:
                self.connect()

            # Try to list remote directory
            self.sftp.listdir(self.config.remote_path)
            return True

        except Exception as e:
            logger.error(f"SFTP connectivity test failed: {e}")
            return False
