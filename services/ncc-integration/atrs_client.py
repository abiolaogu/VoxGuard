"""
ATRS API Client

Client for the NCC's Automated Trouble Reporting System (ATRS).
Handles OAuth 2.0 authentication, incident reporting, and compliance submissions.
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from enum import Enum

import aiohttp
from aiohttp import ClientSession, ClientTimeout

from .config import AtrsConfig

logger = logging.getLogger(__name__)


class IncidentType(str, Enum):
    """NCC incident types."""
    CLI_SPOOFING = "CLI_SPOOFING"
    WANGIRI = "WANGIRI"
    IRSF = "IRSF"
    REVENUE_FRAUD = "REVENUE_FRAUD"
    SIM_BOX = "SIM_BOX"
    OTHER = "OTHER"


class Severity(str, Enum):
    """Incident severity levels."""
    CRITICAL = "CRITICAL"  # 1 hour response
    HIGH = "HIGH"          # 4 hours response
    MEDIUM = "MEDIUM"      # 24 hours response
    LOW = "LOW"            # Weekly summary


class IncidentStatus(str, Enum):
    """Incident status."""
    RECEIVED = "RECEIVED"
    ACKNOWLEDGED = "ACKNOWLEDGED"
    INVESTIGATING = "INVESTIGATING"
    CROSS_OPERATOR = "CROSS_OPERATOR"
    RESOLVED = "RESOLVED"
    CLOSED = "CLOSED"


class AtrsClientError(Exception):
    """Base exception for ATRS client errors."""
    pass


class AtrsAuthenticationError(AtrsClientError):
    """Authentication failure."""
    pass


class AtrsRateLimitError(AtrsClientError):
    """Rate limit exceeded."""
    def __init__(self, reset_time: int):
        self.reset_time = reset_time
        super().__init__(f"Rate limited. Resets at {reset_time}")


class AtrsClient:
    """
    Client for NCC ATRS API.

    Handles:
    - OAuth 2.0 token management with auto-refresh
    - Fraud incident reporting
    - Compliance report submission
    - Exponential backoff retry logic
    - Rate limit handling
    """

    def __init__(self, config: AtrsConfig):
        """
        Initialize ATRS client.

        Args:
            config: ATRS configuration
        """
        self.config = config
        self.token: Optional[str] = None
        self.token_expiry: Optional[datetime] = None
        self._session: Optional[ClientSession] = None

    async def __aenter__(self):
        """Async context manager entry."""
        await self._ensure_session()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        await self.close()

    async def _ensure_session(self):
        """Ensure aiohttp session exists."""
        if self._session is None or self._session.closed:
            timeout = ClientTimeout(total=self.config.timeout_seconds)
            self._session = ClientSession(timeout=timeout)

    async def close(self):
        """Close the client session."""
        if self._session and not self._session.closed:
            await self._session.close()

    def _is_token_expired(self) -> bool:
        """Check if OAuth token is expired or about to expire."""
        if self.token is None or self.token_expiry is None:
            return True

        # Refresh 60 seconds before expiry
        return datetime.utcnow() >= self.token_expiry - timedelta(seconds=60)

    async def _refresh_token(self) -> None:
        """
        Refresh OAuth 2.0 access token using client credentials flow.

        Raises:
            AtrsAuthenticationError: If authentication fails
        """
        await self._ensure_session()

        data = {
            "grant_type": "client_credentials",
            "client_id": self.config.client_id,
            "client_secret": self.config.client_secret,
            "scope": "fraud:write fraud:read compliance:write compliance:read",
        }

        try:
            async with self._session.post(
                f"{self.config.base_url.replace('/v2', '')}/oauth/token",
                data=data,
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            ) as response:
                if response.status == 401:
                    raise AtrsAuthenticationError("Invalid client credentials")

                response.raise_for_status()
                result = await response.json()

                self.token = result["access_token"]
                expires_in = result.get("expires_in", 3600)
                self.token_expiry = datetime.utcnow() + timedelta(seconds=expires_in)

                logger.info(f"OAuth token refreshed, expires in {expires_in}s")

        except aiohttp.ClientError as e:
            raise AtrsAuthenticationError(f"Token refresh failed: {e}")

    async def _ensure_token(self) -> str:
        """Ensure we have a valid OAuth token."""
        if self._is_token_expired():
            await self._refresh_token()
        return self.token

    async def _request(
        self,
        method: str,
        endpoint: str,
        json: Optional[Dict] = None,
        params: Optional[Dict] = None,
        retry_count: int = 0,
    ) -> Dict[str, Any]:
        """
        Make an authenticated request to ATRS API with retry logic.

        Args:
            method: HTTP method
            endpoint: API endpoint (without base URL)
            json: JSON body
            params: Query parameters
            retry_count: Current retry attempt

        Returns:
            Response JSON

        Raises:
            AtrsRateLimitError: If rate limited
            AtrsClientError: For other errors
        """
        await self._ensure_session()
        token = await self._ensure_token()

        url = f"{self.config.base_url}{endpoint}"
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "X-ICL-License": self.config.icl_license,
            "X-Request-ID": f"voxguard-{datetime.utcnow().timestamp()}",
        }

        try:
            async with self._session.request(
                method,
                url,
                json=json,
                params=params,
                headers=headers,
            ) as response:
                # Handle rate limiting
                if response.status == 429:
                    reset_time = int(response.headers.get("X-RateLimit-Reset", 0))
                    raise AtrsRateLimitError(reset_time)

                # Handle authentication errors
                if response.status == 401:
                    # Token might be expired, try refreshing once
                    if retry_count == 0:
                        self.token = None
                        return await self._request(method, endpoint, json, params, retry_count + 1)
                    raise AtrsAuthenticationError("Authentication failed")

                response.raise_for_status()
                return await response.json()

        except AtrsRateLimitError:
            raise
        except aiohttp.ClientError as e:
            # Exponential backoff for retryable errors
            if retry_count < self.config.max_retries:
                delay = 2 ** retry_count
                logger.warning(f"Request failed, retrying in {delay}s: {e}")
                await asyncio.sleep(delay)
                return await self._request(method, endpoint, json, params, retry_count + 1)

            raise AtrsClientError(f"Request failed after {retry_count} retries: {e}")

    async def submit_incident(
        self,
        incident_type: IncidentType,
        severity: Severity,
        detected_at: datetime,
        b_number: str,
        a_numbers: List[str],
        detection_window_ms: int,
        source_ips: Optional[List[str]] = None,
        actions_taken: Optional[List[str]] = None,
        metadata: Optional[Dict] = None,
    ) -> Dict[str, Any]:
        """
        Submit a fraud incident to ATRS.

        Args:
            incident_type: Type of fraud detected
            severity: Incident severity
            detected_at: Detection timestamp
            b_number: Target phone number
            a_numbers: List of spoofed A-numbers
            detection_window_ms: Detection window in milliseconds
            source_ips: Source IP addresses
            actions_taken: Actions taken (ALERT_GENERATED, CALLS_DISCONNECTED, etc.)
            metadata: Additional metadata

        Returns:
            ATRS incident response with incident_id

        Raises:
            AtrsClientError: If submission fails
        """
        payload = {
            "incident_type": incident_type.value,
            "severity": severity.value,
            "detected_at": detected_at.isoformat() + "Z",
            "b_number": b_number,
            "a_numbers": a_numbers[:100],  # Max 100 per API spec
            "detection_window_ms": detection_window_ms,
        }

        if source_ips:
            payload["source_ips"] = source_ips

        if actions_taken:
            payload["actions_taken"] = actions_taken
        else:
            payload["actions_taken"] = ["ALERT_GENERATED"]

        if metadata:
            payload["metadata"] = metadata

        logger.info(
            f"Submitting {severity.value} incident: {len(a_numbers)} A-numbers "
            f"targeting {b_number}"
        )

        response = await self._request("POST", "/fraud/incidents", json=payload)

        logger.info(f"Incident submitted: {response.get('incident_id')}")
        return response

    async def get_incident(self, incident_id: str) -> Dict[str, Any]:
        """
        Query incident status.

        Args:
            incident_id: NCC incident ID

        Returns:
            Incident details
        """
        return await self._request("GET", f"/fraud/incidents/{incident_id}")

    async def submit_daily_report(
        self,
        report_date: str,
        statistics: Dict[str, Any],
        top_targeted_numbers: List[Dict[str, Any]],
        checksum: str,
    ) -> Dict[str, Any]:
        """
        Submit daily compliance report.

        Args:
            report_date: Report date (YYYY-MM-DD)
            statistics: Daily statistics
            top_targeted_numbers: Top targeted B-numbers
            checksum: SHA-256 checksum of report data

        Returns:
            Report submission response with report_id
        """
        payload = {
            "report_date": report_date,
            "icl_license": self.config.icl_license,
            "statistics": statistics,
            "top_targeted_numbers": top_targeted_numbers,
            "checksum": checksum,
        }

        logger.info(f"Submitting daily report for {report_date}")
        response = await self._request("POST", "/compliance/reports/daily", json=payload)
        logger.info(f"Daily report submitted: {response.get('report_id')}")
        return response

    async def submit_monthly_report(
        self,
        report_month: str,
        executive_summary: str,
        statistics: Dict[str, Any],
        trend_analysis: Dict[str, Any],
        attachments: Optional[List[Dict]] = None,
    ) -> Dict[str, Any]:
        """
        Submit monthly compliance report.

        Args:
            report_month: Report month (YYYY-MM)
            executive_summary: Executive summary text
            statistics: Monthly statistics
            trend_analysis: Trend analysis data
            attachments: Optional attachments (CSV, PDF)

        Returns:
            Report submission response
        """
        payload = {
            "report_month": report_month,
            "icl_license": self.config.icl_license,
            "executive_summary": executive_summary,
            "statistics": statistics,
            "trend_analysis": trend_analysis,
        }

        if attachments:
            payload["attachments"] = attachments

        logger.info(f"Submitting monthly report for {report_month}")
        response = await self._request("POST", "/compliance/reports/monthly", json=payload)
        logger.info(f"Monthly report submitted: {response.get('report_id')}")
        return response

    async def health_check(self) -> bool:
        """
        Check ATRS API health.

        Returns:
            True if healthy, False otherwise
        """
        try:
            await self._request("GET", "/health")
            return True
        except Exception as e:
            logger.error(f"ATRS health check failed: {e}")
            return False
