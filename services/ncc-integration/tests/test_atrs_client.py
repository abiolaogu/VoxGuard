"""Tests for ATRS API client."""

import pytest
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

from ncc_integration.atrs_client import (
    AtrsClient,
    AtrsConfig,
    AtrsAuthenticationError,
    AtrsRateLimitError,
    IncidentType,
    Severity,
)


@pytest.fixture
def atrs_config():
    """Create test ATRS configuration."""
    return AtrsConfig(
        base_url="https://atrs-sandbox.ncc.gov.ng/v2",
        client_id="test_client_id",
        client_secret="test_client_secret",
        icl_license="ICL-NG-2025-001234",
        timeout_seconds=10,
        max_retries=2,
    )


@pytest.fixture
def mock_session():
    """Create mock aiohttp session."""
    session = AsyncMock()
    return session


class TestAtrsClient:
    """Test suite for ATRS API client."""

    @pytest.mark.asyncio
    async def test_token_refresh_success(self, atrs_config, mock_session):
        """Test successful OAuth token refresh."""
        client = AtrsClient(atrs_config)
        client._session = mock_session

        # Mock token response
        mock_response = AsyncMock()
        mock_response.status = 200
        mock_response.json = AsyncMock(return_value={
            "access_token": "test_token_123",
            "token_type": "Bearer",
            "expires_in": 3600,
        })
        mock_session.post.return_value.__aenter__.return_value = mock_response

        await client._refresh_token()

        assert client.token == "test_token_123"
        assert client.token_expiry is not None
        mock_session.post.assert_called_once()

    @pytest.mark.asyncio
    async def test_token_refresh_authentication_error(self, atrs_config, mock_session):
        """Test token refresh with invalid credentials."""
        client = AtrsClient(atrs_config)
        client._session = mock_session

        # Mock 401 response
        mock_response = AsyncMock()
        mock_response.status = 401
        mock_session.post.return_value.__aenter__.return_value = mock_response

        with pytest.raises(AtrsAuthenticationError):
            await client._refresh_token()

    @pytest.mark.asyncio
    async def test_token_auto_refresh(self, atrs_config, mock_session):
        """Test automatic token refresh before expiry."""
        client = AtrsClient(atrs_config)
        client._session = mock_session

        # First call - no token
        assert client._is_token_expired() is True

        # Mock token response
        mock_response = AsyncMock()
        mock_response.status = 200
        mock_response.json = AsyncMock(return_value={
            "access_token": "test_token",
            "expires_in": 3600,
        })
        mock_session.post.return_value.__aenter__.return_value = mock_response

        token = await client._ensure_token()

        assert token == "test_token"
        assert client._is_token_expired() is False

    @pytest.mark.asyncio
    async def test_submit_incident_success(self, atrs_config, mock_session):
        """Test successful incident submission."""
        client = AtrsClient(atrs_config)
        client._session = mock_session
        client.token = "valid_token"
        client.token_expiry = datetime.utcnow()

        # Mock incident response
        mock_response = AsyncMock()
        mock_response.status = 201
        mock_response.json = AsyncMock(return_value={
            "incident_id": "NCC-2026-01-0001234",
            "status": "RECEIVED",
        })
        mock_session.request.return_value.__aenter__.return_value = mock_response

        response = await client.submit_incident(
            incident_type=IncidentType.CLI_SPOOFING,
            severity=Severity.CRITICAL,
            detected_at=datetime(2026, 1, 29, 10, 30, 0),
            b_number="+2348012345678",
            a_numbers=["+2347011111111", "+2347022222222"],
            detection_window_ms=4200,
        )

        assert response["incident_id"] == "NCC-2026-01-0001234"
        assert response["status"] == "RECEIVED"

    @pytest.mark.asyncio
    async def test_rate_limit_handling(self, atrs_config, mock_session):
        """Test rate limit error handling."""
        client = AtrsClient(atrs_config)
        client._session = mock_session
        client.token = "valid_token"
        client.token_expiry = datetime.utcnow()

        # Mock 429 response
        mock_response = AsyncMock()
        mock_response.status = 429
        mock_response.headers = {"X-RateLimit-Reset": "1706526600"}
        mock_session.request.return_value.__aenter__.return_value = mock_response

        with pytest.raises(AtrsRateLimitError) as exc_info:
            await client._request("POST", "/fraud/incidents", json={})

        assert exc_info.value.reset_time == 1706526600

    @pytest.mark.asyncio
    async def test_retry_on_transient_error(self, atrs_config, mock_session):
        """Test exponential backoff retry on transient errors."""
        client = AtrsClient(atrs_config)
        client._session = mock_session
        client.token = "valid_token"
        client.token_expiry = datetime.utcnow()

        # First call fails, second succeeds
        mock_error_response = AsyncMock()
        mock_error_response.status = 500
        mock_error_response.raise_for_status.side_effect = Exception("Server error")

        mock_success_response = AsyncMock()
        mock_success_response.status = 200
        mock_success_response.json = AsyncMock(return_value={"success": True})

        mock_session.request.return_value.__aenter__.side_effect = [
            mock_error_response,
            mock_success_response,
        ]

        with patch("asyncio.sleep", new_callable=AsyncMock):
            response = await client._request("POST", "/test", json={})

        assert response == {"success": True}

    @pytest.mark.asyncio
    async def test_get_incident(self, atrs_config, mock_session):
        """Test incident status query."""
        client = AtrsClient(atrs_config)
        client._session = mock_session
        client.token = "valid_token"
        client.token_expiry = datetime.utcnow()

        # Mock incident response
        mock_response = AsyncMock()
        mock_response.status = 200
        mock_response.json = AsyncMock(return_value={
            "incident_id": "NCC-2026-01-0001234",
            "status": "INVESTIGATING",
        })
        mock_session.request.return_value.__aenter__.return_value = mock_response

        incident = await client.get_incident("NCC-2026-01-0001234")

        assert incident["incident_id"] == "NCC-2026-01-0001234"
        assert incident["status"] == "INVESTIGATING"

    @pytest.mark.asyncio
    async def test_submit_daily_report(self, atrs_config, mock_session):
        """Test daily report submission."""
        client = AtrsClient(atrs_config)
        client._session = mock_session
        client.token = "valid_token"
        client.token_expiry = datetime.utcnow()

        # Mock report response
        mock_response = AsyncMock()
        mock_response.status = 202
        mock_response.json = AsyncMock(return_value={
            "report_id": "RPT-2026-01-28-001234",
            "status": "PROCESSING",
        })
        mock_session.request.return_value.__aenter__.return_value = mock_response

        response = await client.submit_daily_report(
            report_date="2026-01-28",
            statistics={"total_calls_processed": 12500000},
            top_targeted_numbers=[],
            checksum="abc123",
        )

        assert response["report_id"] == "RPT-2026-01-28-001234"
        assert response["status"] == "PROCESSING"

    @pytest.mark.asyncio
    async def test_health_check_success(self, atrs_config, mock_session):
        """Test successful health check."""
        client = AtrsClient(atrs_config)
        client._session = mock_session
        client.token = "valid_token"
        client.token_expiry = datetime.utcnow()

        mock_response = AsyncMock()
        mock_response.status = 200
        mock_response.json = AsyncMock(return_value={"status": "healthy"})
        mock_session.request.return_value.__aenter__.return_value = mock_response

        healthy = await client.health_check()

        assert healthy is True

    @pytest.mark.asyncio
    async def test_health_check_failure(self, atrs_config, mock_session):
        """Test health check failure."""
        client = AtrsClient(atrs_config)
        client._session = mock_session
        client.token = "valid_token"
        client.token_expiry = datetime.utcnow()

        mock_response = AsyncMock()
        mock_response.status = 500
        mock_response.raise_for_status.side_effect = Exception("Server error")
        mock_session.request.return_value.__aenter__.return_value = mock_response

        healthy = await client.health_check()

        assert healthy is False

    @pytest.mark.asyncio
    async def test_context_manager(self, atrs_config):
        """Test async context manager usage."""
        async with AtrsClient(atrs_config) as client:
            assert client._session is not None

        # Session should be closed after context exit
        assert client._session is None or client._session.closed
