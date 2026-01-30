"""
STIR/SHAKEN Attestation Verification Module
Anti-Call Masking Detection System

This module simulates STIR/SHAKEN (Secure Telephone Identity Revisited /
Signature-based Handling of Asserted information using toKENs) verification
for call authentication.

Attestation Levels:
- Full (A): The originating provider has authenticated the calling party
  and verified they are authorized to use the calling number.
- Partial (B): The originating provider has authenticated the call origin
  but cannot verify the caller's authorization to use the calling number.
- Gateway (C): The originating provider has authenticated the call
  but has no relationship with the caller and cannot verify identity.
"""

import base64
import json
import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Optional, Dict, Any, List


class AttestationLevel(Enum):
    """STIR/SHAKEN Attestation Levels"""
    FULL = "A"          # Full attestation - carrier verified caller identity
    PARTIAL = "B"       # Partial attestation - carrier authenticated origin
    GATEWAY = "C"       # Gateway attestation - no verification of caller
    UNKNOWN = "UNKNOWN" # Unable to determine attestation level


class VerificationStatus(Enum):
    """Result status of STIR/SHAKEN verification"""
    VERIFIED = "verified"           # Valid signature, attestation confirmed
    UNVERIFIED = "unverified"       # No STIR/SHAKEN information present
    FAILED = "failed"               # Signature verification failed
    EXPIRED = "expired"             # Token has expired
    INVALID = "invalid"             # Malformed token or claims


class ReviewFlag(Enum):
    """Flags for manual review"""
    NONE = "none"
    MANUAL_REVIEW = "manual_review"
    HIGH_RISK = "high_risk"
    BLOCKED = "blocked"


@dataclass
class CallOriginInfo:
    """Information about call origin for fraud analysis"""
    originating_number: str          # A-number (CLI)
    destination_number: str          # B-number
    originating_country: str         # ISO country code of actual call origin
    cli_country: str                 # Country code indicated by CLI
    originating_carrier: Optional[str] = None
    originating_ip: Optional[str] = None

    @property
    def is_cli_local(self) -> bool:
        """
        Check if CLI indicates a local/domestic number.
        Returns True if the CLI country is a recognized domestic format.
        """
        # CLI is "local" if it has a valid country code format
        return self.cli_country not in ("UNKNOWN", "", None)

    @property
    def is_origin_international(self) -> bool:
        """
        Check if the actual call origin is from a different country than CLI suggests.
        This is a key fraud indicator - when someone is calling from abroad
        but presenting a local CLI.
        """
        return self.originating_country != self.cli_country


@dataclass
class VerificationResult:
    """Result of STIR/SHAKEN verification"""
    status: VerificationStatus
    attestation: AttestationLevel
    review_flag: ReviewFlag = ReviewFlag.NONE
    confidence_score: float = 0.0
    reasons: List[str] = field(default_factory=list)
    raw_claims: Dict[str, Any] = field(default_factory=dict)
    verified_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def requires_manual_review(self) -> bool:
        """Check if this call requires manual review"""
        return self.review_flag in (ReviewFlag.MANUAL_REVIEW, ReviewFlag.HIGH_RISK)

    def to_dict(self) -> Dict[str, Any]:
        """Convert result to dictionary for serialization"""
        return {
            "status": self.status.value,
            "attestation": self.attestation.value,
            "review_flag": self.review_flag.value,
            "confidence_score": self.confidence_score,
            "reasons": self.reasons,
            "requires_manual_review": self.requires_manual_review(),
            "verified_at": self.verified_at.isoformat(),
        }


class JWTParseError(Exception):
    """Exception raised when JWT parsing fails"""
    pass


class StirShakenVerifier:
    """
    STIR/SHAKEN JWT Verifier

    Parses and verifies Identity headers containing STIR/SHAKEN PASSporT tokens.
    In a production environment, this would verify cryptographic signatures
    against trusted certificate authorities.
    """

    # Country code patterns for CLI analysis
    COUNTRY_CODE_PATTERNS = {
        # North America Numbering Plan
        "US": r"^\+?1[2-9]\d{9}$",
        "CA": r"^\+?1[2-9]\d{9}$",
        # UK
        "GB": r"^\+?44\d{10}$",
        # Nigeria
        "NG": r"^\+?234\d{10}$",
        # Germany
        "DE": r"^\+?49\d{10,11}$",
        # International format
        "INTL": r"^\+\d{10,15}$",
    }

    # Trusted attestation issuers (in production, these would be verified)
    TRUSTED_ISSUERS = {
        "SHAKEN",
        "stir.example.com",
        "verification.carrier.com",
    }

    def __init__(self, strict_mode: bool = False):
        """
        Initialize the verifier.

        Args:
            strict_mode: If True, reject tokens with any issues.
                        If False, attempt to process with warnings.
        """
        self.strict_mode = strict_mode

    def parse_identity_header(self, identity_header: str) -> Dict[str, Any]:
        """
        Parse the Identity header containing a STIR/SHAKEN PASSporT.

        The Identity header format is:
        Identity: <JWT>;info=<certificate-url>;alg=<algorithm>;ppt=shaken

        Args:
            identity_header: The full Identity header value

        Returns:
            Dictionary containing parsed JWT claims

        Raises:
            JWTParseError: If the header cannot be parsed
        """
        if not identity_header:
            raise JWTParseError("Empty Identity header")

        # Extract the JWT portion (before the first semicolon)
        parts = identity_header.split(";")
        jwt_token = parts[0].strip()

        # Parse additional parameters
        params = {}
        for part in parts[1:]:
            if "=" in part:
                key, value = part.split("=", 1)
                params[key.strip()] = value.strip()

        # Decode the JWT
        claims = self._decode_jwt(jwt_token)
        claims["_params"] = params

        return claims

    def _decode_jwt(self, token: str) -> Dict[str, Any]:
        """
        Decode a JWT token (without signature verification for simulation).

        In production, this would verify the signature using the certificate
        from the info parameter.

        Args:
            token: The JWT string

        Returns:
            Dictionary of JWT claims

        Raises:
            JWTParseError: If the token is malformed
        """
        parts = token.split(".")

        if len(parts) != 3:
            raise JWTParseError(f"Invalid JWT format: expected 3 parts, got {len(parts)}")

        try:
            # Decode header
            header_json = self._base64url_decode(parts[0])
            header = json.loads(header_json)

            # Decode payload
            payload_json = self._base64url_decode(parts[1])
            payload = json.loads(payload_json)

            # In production, we would verify signature using parts[2]
            # For simulation, we just note the signature exists
            payload["_header"] = header
            payload["_has_signature"] = len(parts[2]) > 0

            return payload

        except (ValueError, json.JSONDecodeError) as e:
            raise JWTParseError(f"Failed to decode JWT: {e}")

    def _base64url_decode(self, data: str) -> str:
        """Decode base64url-encoded data"""
        # Add padding if needed
        padding = 4 - len(data) % 4
        if padding != 4:
            data += "=" * padding

        # Convert base64url to standard base64
        data = data.replace("-", "+").replace("_", "/")

        return base64.b64decode(data).decode("utf-8")

    def verify_attestation(
        self,
        identity_header: str,
        call_info: Optional[CallOriginInfo] = None
    ) -> VerificationResult:
        """
        Verify STIR/SHAKEN attestation and analyze for fraud indicators.

        Args:
            identity_header: The Identity header containing the PASSporT
            call_info: Optional call origin information for fraud analysis

        Returns:
            VerificationResult with attestation level and any flags
        """
        reasons = []
        review_flag = ReviewFlag.NONE
        confidence_score = 1.0

        # Parse the JWT
        try:
            claims = self.parse_identity_header(identity_header)
        except JWTParseError as e:
            return VerificationResult(
                status=VerificationStatus.INVALID,
                attestation=AttestationLevel.UNKNOWN,
                review_flag=ReviewFlag.HIGH_RISK,
                confidence_score=0.0,
                reasons=[f"Failed to parse Identity header: {e}"],
            )

        # Check for required claims
        if "attest" not in claims:
            return VerificationResult(
                status=VerificationStatus.INVALID,
                attestation=AttestationLevel.UNKNOWN,
                review_flag=ReviewFlag.MANUAL_REVIEW,
                confidence_score=0.2,
                reasons=["Missing 'attest' claim in PASSporT"],
                raw_claims=claims,
            )

        # Parse attestation level
        attest_value = claims.get("attest", "").upper()
        attestation = self._parse_attestation_level(attest_value)

        # Check expiration (iat claim)
        if "iat" in claims:
            issued_at = datetime.fromtimestamp(claims["iat"], tz=timezone.utc)
            now = datetime.now(timezone.utc)
            age_seconds = (now - issued_at).total_seconds()

            # PASSporT tokens are typically valid for 60 seconds
            if age_seconds > 60:
                return VerificationResult(
                    status=VerificationStatus.EXPIRED,
                    attestation=attestation,
                    review_flag=ReviewFlag.MANUAL_REVIEW,
                    confidence_score=0.3,
                    reasons=[f"Token expired: issued {age_seconds:.0f} seconds ago"],
                    raw_claims=claims,
                )

        # Analyze based on attestation level
        if attestation == AttestationLevel.GATEWAY:
            confidence_score = 0.4
            reasons.append("Gateway (C) attestation: No caller verification performed")

            # Check for international origin with local CLI
            if call_info and call_info.is_origin_international and call_info.is_cli_local:
                review_flag = ReviewFlag.MANUAL_REVIEW
                confidence_score = 0.2
                reasons.append(
                    f"International origin ({call_info.originating_country}) "
                    f"with local CLI ({call_info.cli_country})"
                )

        elif attestation == AttestationLevel.PARTIAL:
            confidence_score = 0.7
            reasons.append("Partial (B) attestation: Origin authenticated, caller not verified")

            if call_info and call_info.is_origin_international:
                confidence_score = 0.5
                reasons.append("International call with partial attestation")

        elif attestation == AttestationLevel.FULL:
            confidence_score = 0.95
            reasons.append("Full (A) attestation: Caller identity verified")

        else:
            confidence_score = 0.1
            review_flag = ReviewFlag.HIGH_RISK
            reasons.append(f"Unknown attestation level: {attest_value}")

        # Verify originating number matches (if available)
        if call_info and "orig" in claims:
            orig_claim = claims["orig"]
            if isinstance(orig_claim, dict) and "tn" in orig_claim:
                claimed_number = self._normalize_number(orig_claim["tn"])
                actual_number = self._normalize_number(call_info.originating_number)

                if claimed_number != actual_number:
                    review_flag = ReviewFlag.HIGH_RISK
                    confidence_score *= 0.3
                    reasons.append(
                        f"Originating number mismatch: "
                        f"claimed {claimed_number}, actual {actual_number}"
                    )

        return VerificationResult(
            status=VerificationStatus.VERIFIED,
            attestation=attestation,
            review_flag=review_flag,
            confidence_score=confidence_score,
            reasons=reasons,
            raw_claims=claims,
        )

    def _parse_attestation_level(self, attest_value: str) -> AttestationLevel:
        """Parse attestation level from claim value"""
        attest_map = {
            "A": AttestationLevel.FULL,
            "FULL": AttestationLevel.FULL,
            "B": AttestationLevel.PARTIAL,
            "PARTIAL": AttestationLevel.PARTIAL,
            "C": AttestationLevel.GATEWAY,
            "GATEWAY": AttestationLevel.GATEWAY,
        }
        return attest_map.get(attest_value.upper(), AttestationLevel.UNKNOWN)

    def _normalize_number(self, number: str) -> str:
        """Normalize phone number for comparison"""
        # Remove all non-digit characters except leading +
        if number.startswith("+"):
            return "+" + re.sub(r"\D", "", number[1:])
        return re.sub(r"\D", "", number)

    def detect_country_from_cli(self, cli: str) -> str:
        """
        Detect country code from CLI (Calling Line Identification).

        Args:
            cli: The calling number

        Returns:
            ISO country code or "UNKNOWN"
        """
        normalized = self._normalize_number(cli)

        # Check for E.164 format with country code
        if normalized.startswith("+"):
            # Extract country code
            if normalized.startswith("+1"):
                return "US"  # NANP (could be US/CA)
            elif normalized.startswith("+44"):
                return "GB"
            elif normalized.startswith("+234"):
                return "NG"
            elif normalized.startswith("+49"):
                return "DE"
            elif normalized.startswith("+"):
                return "INTL"

        # Default patterns for local numbers
        for country, pattern in self.COUNTRY_CODE_PATTERNS.items():
            if re.match(pattern, normalized):
                return country

        return "UNKNOWN"


# Module-level convenience functions

def parse_identity_header(identity_header: str) -> Dict[str, Any]:
    """
    Parse a STIR/SHAKEN Identity header.

    Args:
        identity_header: The Identity header value

    Returns:
        Dictionary of parsed JWT claims
    """
    verifier = StirShakenVerifier()
    return verifier.parse_identity_header(identity_header)


def verify_attestation(
    identity_header: str,
    originating_number: Optional[str] = None,
    destination_number: Optional[str] = None,
    originating_country: Optional[str] = None,
    cli_country: Optional[str] = None,
) -> VerificationResult:
    """
    Verify STIR/SHAKEN attestation from an Identity header.

    Args:
        identity_header: The Identity header value
        originating_number: The A-number (CLI)
        destination_number: The B-number
        originating_country: Country code of call origin
        cli_country: Country code indicated by CLI

    Returns:
        VerificationResult with attestation level and flags
    """
    verifier = StirShakenVerifier()

    call_info = None
    if originating_number:
        # Auto-detect CLI country if not provided
        if not cli_country:
            cli_country = verifier.detect_country_from_cli(originating_number)

        call_info = CallOriginInfo(
            originating_number=originating_number,
            destination_number=destination_number or "",
            originating_country=originating_country or cli_country,
            cli_country=cli_country,
        )

    return verifier.verify_attestation(identity_header, call_info)


def create_test_passport(
    attest: str = "A",
    orig_tn: str = "+12025551234",
    dest_tn: str = "+12025559876",
    iat: Optional[int] = None,
) -> str:
    """
    Create a test PASSporT JWT for testing purposes.

    Args:
        attest: Attestation level (A, B, or C)
        orig_tn: Originating telephone number
        dest_tn: Destination telephone number
        iat: Issued-at timestamp (defaults to current time)

    Returns:
        A JWT string (with dummy signature)
    """
    import time

    header = {
        "alg": "ES256",
        "ppt": "shaken",
        "typ": "passport",
        "x5u": "https://cert.example.com/cert.pem",
    }

    payload = {
        "attest": attest,
        "dest": {"tn": [dest_tn]},
        "iat": iat or int(time.time()),
        "orig": {"tn": orig_tn},
        "origid": "abc123-def456-ghi789",
    }

    def base64url_encode(data: bytes) -> str:
        return base64.urlsafe_b64encode(data).rstrip(b"=").decode("utf-8")

    header_b64 = base64url_encode(json.dumps(header).encode())
    payload_b64 = base64url_encode(json.dumps(payload).encode())
    signature_b64 = base64url_encode(b"dummy_signature_for_testing")

    return f"{header_b64}.{payload_b64}.{signature_b64}"


def create_test_identity_header(
    attest: str = "A",
    orig_tn: str = "+12025551234",
    dest_tn: str = "+12025559876",
    iat: Optional[int] = None,
) -> str:
    """
    Create a complete test Identity header.

    Args:
        attest: Attestation level (A, B, or C)
        orig_tn: Originating telephone number
        dest_tn: Destination telephone number
        iat: Issued-at timestamp

    Returns:
        A complete Identity header string
    """
    jwt = create_test_passport(attest, orig_tn, dest_tn, iat)
    return f"{jwt};info=<https://cert.example.com/cert.pem>;alg=ES256;ppt=shaken"
