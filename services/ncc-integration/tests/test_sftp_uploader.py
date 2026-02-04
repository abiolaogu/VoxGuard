"""
Unit tests for SFTP CDR Uploader.

Tests cover:
- SFTP connection management
- File upload with atomic transfers
- Batch upload functionality
- Upload verification
- Error handling
"""

import os
import pytest
from pathlib import Path
from unittest.mock import Mock, MagicMock, patch, call

from ncc_integration.sftp_uploader import SftpUploader, SftpUploadError
from ncc_integration.config import SftpConfig


@pytest.fixture
def sftp_config():
    """Create SFTP configuration for testing."""
    return SftpConfig(
        host="sftp.ncc.gov.ng",
        port=22,
        username="ncc_upload",
        private_key_path="/etc/ncc/id_rsa",
        remote_path="/uploads",
    )


@pytest.fixture
def mock_ssh_client():
    """Create a mock SSH client."""
    with patch('ncc_integration.sftp_uploader.SSHClient') as mock_client_class:
        mock_client = MagicMock()
        mock_client_class.return_value = mock_client

        # Mock SFTP channel
        mock_sftp = MagicMock()
        mock_client.open_sftp.return_value = mock_sftp

        yield mock_client, mock_sftp


@pytest.fixture
def mock_rsa_key():
    """Mock RSA key loading."""
    with patch('ncc_integration.sftp_uploader.paramiko.RSAKey.from_private_key_file') as mock_key:
        mock_key.return_value = MagicMock()
        yield mock_key


# Initialization Tests

def test_uploader_initialization(sftp_config):
    """Test uploader initializes with configuration."""
    uploader = SftpUploader(sftp_config)

    assert uploader.config == sftp_config
    assert uploader.client is None
    assert uploader.sftp is None


def test_uploader_context_manager(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test uploader works as context manager."""
    mock_client, mock_sftp = mock_ssh_client

    with patch('os.path.exists', return_value=True):
        with SftpUploader(sftp_config) as uploader:
            # Should be connected
            assert uploader.client is not None
            assert uploader.sftp is not None

        # Should be disconnected after exiting context
        mock_sftp.close.assert_called_once()
        mock_client.close.assert_called_once()


# Connection Management Tests

def test_connect_success(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test successful SFTP connection."""
    mock_client, mock_sftp = mock_ssh_client

    with patch('os.path.exists', return_value=True):
        uploader = SftpUploader(sftp_config)
        uploader.connect()

        # Verify key was loaded
        mock_rsa_key.assert_called_once_with("/etc/ncc/id_rsa")

        # Verify connection was established
        mock_client.connect.assert_called_once()
        assert mock_client.connect.call_args[1]['hostname'] == "sftp.ncc.gov.ng"
        assert mock_client.connect.call_args[1]['port'] == 22
        assert mock_client.connect.call_args[1]['username'] == "ncc_upload"

        # Verify SFTP channel was opened
        mock_client.open_sftp.assert_called_once()
        assert uploader.sftp == mock_sftp


def test_connect_missing_private_key(sftp_config, mock_ssh_client):
    """Test connection fails when private key is missing."""
    with patch('os.path.exists', return_value=False):
        uploader = SftpUploader(sftp_config)

        with pytest.raises(SftpUploadError) as exc_info:
            uploader.connect()

        assert "Private key not found" in str(exc_info.value)


def test_connect_authentication_failure(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test connection fails on authentication error."""
    mock_client, _ = mock_ssh_client
    mock_client.connect.side_effect = Exception("Authentication failed")

    with patch('os.path.exists', return_value=True):
        uploader = SftpUploader(sftp_config)

        with pytest.raises(SftpUploadError) as exc_info:
            uploader.connect()

        assert "Failed to connect to SFTP server" in str(exc_info.value)


def test_disconnect(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test SFTP disconnection."""
    mock_client, mock_sftp = mock_ssh_client

    with patch('os.path.exists', return_value=True):
        uploader = SftpUploader(sftp_config)
        uploader.connect()
        uploader.disconnect()

        # Verify channels were closed
        mock_sftp.close.assert_called_once()
        mock_client.close.assert_called_once()

        # Verify client references are cleared
        assert uploader.sftp is None
        assert uploader.client is None


def test_disconnect_graceful_none(sftp_config):
    """Test disconnect handles None connections gracefully."""
    uploader = SftpUploader(sftp_config)
    uploader.disconnect()  # Should not raise error


# File Upload Tests

def test_upload_file_success(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test successful file upload with atomic transfer."""
    mock_client, mock_sftp = mock_ssh_client

    # Mock file stats
    mock_stat = MagicMock()
    mock_stat.st_size = 1024
    mock_sftp.stat.return_value = mock_stat

    with patch('os.path.exists', return_value=True), \
         patch('os.path.getsize', return_value=1024):

        uploader = SftpUploader(sftp_config)
        uploader.connect()
        uploader.upload_file("/local/report.csv", "report.csv")

        # Verify upload to temp file
        mock_sftp.put.assert_called_once_with(
            "/local/report.csv",
            "/uploads/report.csv.tmp"
        )

        # Verify size verification
        mock_sftp.stat.assert_called_once_with("/uploads/report.csv.tmp")

        # Verify atomic rename
        mock_sftp.rename.assert_called_once_with(
            "/uploads/report.csv.tmp",
            "/uploads/report.csv"
        )


def test_upload_file_without_connection(sftp_config):
    """Test upload fails when not connected."""
    uploader = SftpUploader(sftp_config)

    with pytest.raises(SftpUploadError) as exc_info:
        uploader.upload_file("/local/report.csv", "report.csv")

    assert "Not connected to SFTP server" in str(exc_info.value)


def test_upload_file_missing_local_file(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test upload fails when local file doesn't exist."""
    with patch('os.path.exists', side_effect=[True, False]):  # Key exists, file doesn't
        uploader = SftpUploader(sftp_config)
        uploader.connect()

        with pytest.raises(SftpUploadError) as exc_info:
            uploader.upload_file("/local/missing.csv", "missing.csv")

        assert "Local file not found" in str(exc_info.value)


def test_upload_file_size_mismatch(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test upload detects size mismatch."""
    mock_client, mock_sftp = mock_ssh_client

    # Mock different sizes for local and remote
    mock_stat = MagicMock()
    mock_stat.st_size = 512  # Remote size different
    mock_sftp.stat.return_value = mock_stat

    with patch('os.path.exists', return_value=True), \
         patch('os.path.getsize', return_value=1024):  # Local size

        uploader = SftpUploader(sftp_config)
        uploader.connect()

        with pytest.raises(SftpUploadError) as exc_info:
            uploader.upload_file("/local/report.csv", "report.csv")

        assert "Size mismatch" in str(exc_info.value)
        assert "local=1024" in str(exc_info.value)
        assert "remote=512" in str(exc_info.value)


def test_upload_file_without_verification(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test upload without size verification."""
    mock_client, mock_sftp = mock_ssh_client

    with patch('os.path.exists', return_value=True), \
         patch('os.path.getsize', return_value=1024):

        uploader = SftpUploader(sftp_config)
        uploader.connect()
        uploader.upload_file("/local/report.csv", "report.csv", verify=False)

        # Verify upload happened
        mock_sftp.put.assert_called_once()

        # Verify NO size verification
        mock_sftp.stat.assert_not_called()

        # Verify atomic rename still happened
        mock_sftp.rename.assert_called_once()


def test_upload_file_cleanup_on_error(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test temp file cleanup on upload error."""
    mock_client, mock_sftp = mock_ssh_client
    mock_sftp.put.side_effect = Exception("Network error")

    with patch('os.path.exists', return_value=True), \
         patch('os.path.getsize', return_value=1024):

        uploader = SftpUploader(sftp_config)
        uploader.connect()

        with pytest.raises(SftpUploadError) as exc_info:
            uploader.upload_file("/local/report.csv", "report.csv", verify=False)

        # Verify temp file removal was attempted
        mock_sftp.remove.assert_called_once_with("/uploads/report.csv.tmp")


# Batch Upload Tests

def test_upload_batch_success(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test successful batch upload."""
    mock_client, mock_sftp = mock_ssh_client

    # Mock file stats
    mock_stat = MagicMock()
    mock_stat.st_size = 1024
    mock_sftp.stat.return_value = mock_stat

    files = [
        ("/local/stats.csv", "stats.csv"),
        ("/local/alerts.csv", "alerts.csv"),
        ("/local/summary.json", "summary.json"),
    ]

    with patch('os.path.exists', return_value=True), \
         patch('os.path.getsize', return_value=1024):

        uploader = SftpUploader(sftp_config)
        uploader.connect()
        uploader.upload_batch(files)

        # Verify all files were uploaded
        assert mock_sftp.put.call_count == 3
        assert mock_sftp.rename.call_count == 3


def test_upload_batch_without_connection(sftp_config):
    """Test batch upload fails when not connected."""
    uploader = SftpUploader(sftp_config)

    with pytest.raises(SftpUploadError) as exc_info:
        uploader.upload_batch([("/local/file.csv", "file.csv")])

    assert "Not connected to SFTP server" in str(exc_info.value)


def test_upload_batch_partial_failure(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test batch upload handles partial failures."""
    mock_client, mock_sftp = mock_ssh_client

    # Make second file upload fail
    def put_side_effect(local, remote):
        if "alerts" in local:
            raise Exception("Network error")

    mock_sftp.put.side_effect = put_side_effect

    files = [
        ("/local/stats.csv", "stats.csv"),
        ("/local/alerts.csv", "alerts.csv"),  # This will fail
        ("/local/summary.json", "summary.json"),
    ]

    with patch('os.path.exists', return_value=True), \
         patch('os.path.getsize', return_value=1024):

        uploader = SftpUploader(sftp_config)
        uploader.connect()

        with pytest.raises(SftpUploadError) as exc_info:
            uploader.upload_batch(files)

        assert "Failed to upload" in str(exc_info.value)
        assert "alerts.csv" in str(exc_info.value)


# Remote Operations Tests

def test_list_remote_files(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test listing remote files."""
    mock_client, mock_sftp = mock_ssh_client
    mock_sftp.listdir.return_value = [
        "ACM_DAILY_001_20260128.csv",
        "ACM_DAILY_001_20260129.csv",
        "ACM_ALERTS_001_20260128.csv",
        "other_file.txt",
    ]

    with patch('os.path.exists', return_value=True):
        uploader = SftpUploader(sftp_config)
        uploader.connect()
        files = uploader.list_remote_files()

        # Verify all files returned
        assert len(files) == 4
        assert "ACM_DAILY_001_20260128.csv" in files


def test_list_remote_files_with_pattern(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test listing remote files with pattern filter."""
    mock_client, mock_sftp = mock_ssh_client
    mock_sftp.listdir.return_value = [
        "ACM_DAILY_001_20260128.csv",
        "ACM_DAILY_001_20260129.csv",
        "ACM_ALERTS_001_20260128.csv",
        "other_file.txt",
    ]

    with patch('os.path.exists', return_value=True):
        uploader = SftpUploader(sftp_config)
        uploader.connect()
        files = uploader.list_remote_files(pattern="ACM_DAILY_*.csv")

        # Verify only matching files returned
        assert len(files) == 2
        assert "ACM_DAILY_001_20260128.csv" in files
        assert "ACM_DAILY_001_20260129.csv" in files
        assert "ACM_ALERTS_001_20260128.csv" not in files


def test_list_remote_files_without_connection(sftp_config):
    """Test list fails when not connected."""
    uploader = SftpUploader(sftp_config)

    with pytest.raises(SftpUploadError) as exc_info:
        uploader.list_remote_files()

    assert "Not connected to SFTP server" in str(exc_info.value)


def test_list_remote_files_directory_error(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test list handles directory access errors."""
    mock_client, mock_sftp = mock_ssh_client
    mock_sftp.listdir.side_effect = Exception("Permission denied")

    with patch('os.path.exists', return_value=True):
        uploader = SftpUploader(sftp_config)
        uploader.connect()

        with pytest.raises(SftpUploadError) as exc_info:
            uploader.list_remote_files()

        assert "Failed to list remote files" in str(exc_info.value)


# Connectivity Tests

def test_verify_connectivity_success(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test successful connectivity verification."""
    mock_client, mock_sftp = mock_ssh_client
    mock_sftp.listdir.return_value = []

    with patch('os.path.exists', return_value=True):
        uploader = SftpUploader(sftp_config)
        uploader.connect()

        assert uploader.verify_connectivity() is True
        mock_sftp.listdir.assert_called_with("/uploads")


def test_verify_connectivity_failure(sftp_config, mock_ssh_client, mock_rsa_key):
    """Test connectivity verification failure."""
    mock_client, mock_sftp = mock_ssh_client
    mock_sftp.listdir.side_effect = Exception("Connection refused")

    with patch('os.path.exists', return_value=True):
        uploader = SftpUploader(sftp_config)
        uploader.connect()

        assert uploader.verify_connectivity() is False
