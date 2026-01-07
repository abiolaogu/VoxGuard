"""
Test Suite for STIR/SHAKEN Attestation Verification
Anti-Call Masking Detection System

Tests cover:
- JWT parsing from Identity headers
- Attestation level verification (A, B, C)
- International origin detection with local CLI
- Manual review flagging for suspicious calls
"""

import sys
import time
from pathlib import Path

import pytest

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from verification.stir_shaken import (
    AttestationLevel,
    VerificationStatus,
    ReviewFlag,
    CallOriginInfo,
    VerificationResult,
    StirShakenVerifier,
    JWTParseError,
    parse_identity_header,
    verify_attestation,
    create_test_passport,
    create_test_identity_header,
)


class TestJWTParsing:
    """Tests for JWT parsing functionality"""

    def test_parse_valid_jwt(self):
        """Test parsing a valid STIR/SHAKEN Identity header"""
        identity_header = create_test_identity_header(
            attest="A",
            orig_tn="+12025551234",
            dest_tn="+12025559876"
        )

        claims = parse_identity_header(identity_header)

        assert claims["attest"] == "A"
        assert claims["orig"]["tn"] == "+12025551234"
        assert claims["dest"]["tn"] == ["+12025559876"]
        assert "_params" in claims

    def test_parse_empty_header_raises_error(self):
        """Test that empty headers raise an error"""
        verifier = StirShakenVerifier()

        with pytest.raises(JWTParseError, match="Empty Identity header"):
            verifier.parse_identity_header("")

    def test_parse_malformed_jwt_raises_error(self):
        """Test that malformed JWTs raise an error"""
        verifier = StirShakenVerifier()

        with pytest.raises(JWTParseError, match="Invalid JWT format"):
            verifier.parse_identity_header("not.a.valid.jwt.token")

    def test_parse_jwt_with_params(self):
        """Test parsing JWT with additional Identity header parameters"""
        identity_header = create_test_identity_header(attest="B")
        claims = parse_identity_header(identity_header)

        assert "_params" in claims
        assert "info" in claims["_params"]
        assert "alg" in claims["_params"]
        assert claims["_params"]["alg"] == "ES256"


class TestAttestationLevels:
    """Tests for attestation level verification"""

    def test_full_attestation_a(self):
        """Test Full (A) attestation verification"""
        identity_header = create_test_identity_header(attest="A")
        result = verify_attestation(identity_header)

        assert result.status == VerificationStatus.VERIFIED
        assert result.attestation == AttestationLevel.FULL
        assert result.confidence_score >= 0.9
        assert "Full (A) attestation" in result.reasons[0]

    def test_partial_attestation_b(self):
        """Test Partial (B) attestation verification"""
        identity_header = create_test_identity_header(attest="B")
        result = verify_attestation(identity_header)

        assert result.status == VerificationStatus.VERIFIED
        assert result.attestation == AttestationLevel.PARTIAL
        assert 0.5 <= result.confidence_score <= 0.8
        assert "Partial (B) attestation" in result.reasons[0]

    def test_gateway_attestation_c(self):
        """Test Gateway (C) attestation verification"""
        identity_header = create_test_identity_header(attest="C")
        result = verify_attestation(identity_header)

        assert result.status == VerificationStatus.VERIFIED
        assert result.attestation == AttestationLevel.GATEWAY
        assert result.confidence_score < 0.5
        assert "Gateway (C) attestation" in result.reasons[0]

    def test_unknown_attestation_level(self):
        """Test handling of unknown attestation level"""
        identity_header = create_test_identity_header(attest="X")
        result = verify_attestation(identity_header)

        assert result.attestation == AttestationLevel.UNKNOWN
        assert result.review_flag == ReviewFlag.HIGH_RISK
        assert result.confidence_score < 0.2


class TestInternationalOriginLocalCLI:
    """Tests for international origin with local CLI detection"""

    def test_attestation_c_international_origin_local_cli_flags_manual_review(self):
        """
        Test case: Attestation C call with international origin but local CLI
        should be flagged for Manual Review.

        Scenario: A call originates from Nigeria (NG) but presents a US CLI,
        with Gateway (C) attestation indicating no caller verification.
        This is a high-risk fraud indicator.
        """
        # Create a Gateway attestation token with US number
        identity_header = create_test_identity_header(
            attest="C",
            orig_tn="+12025551234",  # US CLI
            dest_tn="+12025559876",
        )

        # Verify with international origin (Nigeria) but local CLI (US)
        result = verify_attestation(
            identity_header,
            originating_number="+12025551234",  # US CLI presented
            destination_number="+12025559876",
            originating_country="NG",  # Call actually originates from Nigeria
            cli_country="US",          # CLI indicates US
        )

        # Should be flagged for manual review
        assert result.attestation == AttestationLevel.GATEWAY
        assert result.review_flag == ReviewFlag.MANUAL_REVIEW
        assert result.requires_manual_review() is True
        assert result.confidence_score < 0.3

        # Check that reasons include the international origin warning
        reasons_text = " ".join(result.reasons)
        assert "International origin" in reasons_text or "international" in reasons_text.lower()
        assert "NG" in reasons_text  # Nigeria country code
        assert "US" in reasons_text  # US CLI country

    def test_attestation_c_domestic_origin_not_flagged(self):
        """
        Test case: Attestation C with domestic origin should have lower risk.

        When origin and CLI are from the same country, it's less suspicious
        even with Gateway attestation.
        """
        identity_header = create_test_identity_header(
            attest="C",
            orig_tn="+12025551234",
            dest_tn="+12025559876",
        )

        result = verify_attestation(
            identity_header,
            originating_number="+12025551234",
            destination_number="+12025559876",
            originating_country="US",  # Same country as CLI
            cli_country="US",
        )

        # Should not require manual review for matching countries
        assert result.attestation == AttestationLevel.GATEWAY
        assert result.review_flag == ReviewFlag.NONE
        assert result.requires_manual_review() is False

    def test_attestation_b_international_origin_lower_confidence(self):
        """
        Test that Partial (B) attestation with international origin
        has reduced confidence but may not require immediate review.
        """
        identity_header = create_test_identity_header(
            attest="B",
            orig_tn="+442071234567",  # UK CLI
            dest_tn="+12025559876",
        )

        result = verify_attestation(
            identity_header,
            originating_number="+442071234567",
            destination_number="+12025559876",
            originating_country="NG",  # Origin from Nigeria
            cli_country="GB",          # CLI indicates UK
        )

        assert result.attestation == AttestationLevel.PARTIAL
        assert result.confidence_score <= 0.6
        # Partial attestation with international origin - reduced confidence
        assert "international" in " ".join(result.reasons).lower()

    def test_attestation_a_international_origin_trusted(self):
        """
        Test that Full (A) attestation is trusted even for international calls.

        With Full attestation, the carrier has verified caller identity,
        so international routing is acceptable.
        """
        identity_header = create_test_identity_header(
            attest="A",
            orig_tn="+12025551234",
            dest_tn="+442071234567",
        )

        result = verify_attestation(
            identity_header,
            originating_number="+12025551234",
            destination_number="+442071234567",
            originating_country="US",
            cli_country="US",
        )

        assert result.attestation == AttestationLevel.FULL
        assert result.confidence_score >= 0.9
        assert result.review_flag == ReviewFlag.NONE


class TestCallOriginInfo:
    """Tests for CallOriginInfo class"""

    def test_is_cli_local_when_valid_country(self):
        """Test that CLI is considered local when it has a valid country code"""
        call_info = CallOriginInfo(
            originating_number="+12025551234",
            destination_number="+12025559876",
            originating_country="US",
            cli_country="US",
        )

        assert call_info.is_cli_local is True
        assert call_info.is_origin_international is False

    def test_is_origin_international_when_countries_differ(self):
        """Test detection of international origin with different CLI country"""
        call_info = CallOriginInfo(
            originating_number="+12025551234",
            destination_number="+12025559876",
            originating_country="NG",
            cli_country="US",
        )

        # CLI is "local" because it's a valid US format
        assert call_info.is_cli_local is True
        # Origin is international because NG != US
        assert call_info.is_origin_international is True

    def test_is_cli_not_local_when_unknown(self):
        """Test that CLI is not local when country is unknown"""
        call_info = CallOriginInfo(
            originating_number="123",
            destination_number="+12025559876",
            originating_country="US",
            cli_country="UNKNOWN",
        )

        assert call_info.is_cli_local is False


class TestCountryDetection:
    """Tests for automatic country detection from CLI"""

    def test_detect_us_number(self):
        """Test detection of US phone numbers"""
        verifier = StirShakenVerifier()

        assert verifier.detect_country_from_cli("+12025551234") == "US"
        assert verifier.detect_country_from_cli("12025551234") == "US"

    def test_detect_uk_number(self):
        """Test detection of UK phone numbers"""
        verifier = StirShakenVerifier()

        assert verifier.detect_country_from_cli("+442071234567") == "GB"

    def test_detect_nigeria_number(self):
        """Test detection of Nigerian phone numbers"""
        verifier = StirShakenVerifier()

        assert verifier.detect_country_from_cli("+2348012345678") == "NG"

    def test_detect_unknown_number(self):
        """Test handling of unrecognized number formats"""
        verifier = StirShakenVerifier()

        result = verifier.detect_country_from_cli("123")
        assert result == "UNKNOWN"


class TestTokenExpiration:
    """Tests for token expiration handling"""

    def test_expired_token_flagged(self):
        """Test that expired tokens are flagged"""
        # Create token with old timestamp (2 minutes ago)
        old_time = int(time.time()) - 120

        identity_header = create_test_identity_header(
            attest="A",
            orig_tn="+12025551234",
            iat=old_time,
        )

        result = verify_attestation(identity_header)

        assert result.status == VerificationStatus.EXPIRED
        assert result.review_flag == ReviewFlag.MANUAL_REVIEW
        assert "expired" in result.reasons[0].lower()

    def test_fresh_token_verified(self):
        """Test that fresh tokens are verified successfully"""
        identity_header = create_test_identity_header(
            attest="A",
            orig_tn="+12025551234",
            iat=int(time.time()),
        )

        result = verify_attestation(identity_header)

        assert result.status == VerificationStatus.VERIFIED


class TestOriginatingNumberMismatch:
    """Tests for originating number mismatch detection"""

    def test_number_mismatch_high_risk(self):
        """Test that number mismatch is flagged as high risk"""
        # Create token claiming one number
        identity_header = create_test_identity_header(
            attest="A",
            orig_tn="+12025551234",  # Claimed number
        )

        # Verify with different actual number
        result = verify_attestation(
            identity_header,
            originating_number="+12029999999",  # Different actual number
            destination_number="+12025559876",
            originating_country="US",
            cli_country="US",
        )

        assert result.review_flag == ReviewFlag.HIGH_RISK
        assert "mismatch" in " ".join(result.reasons).lower()
        assert result.confidence_score < 0.5


class TestVerificationResult:
    """Tests for VerificationResult class"""

    def test_to_dict_serialization(self):
        """Test that VerificationResult can be serialized to dict"""
        result = VerificationResult(
            status=VerificationStatus.VERIFIED,
            attestation=AttestationLevel.FULL,
            review_flag=ReviewFlag.NONE,
            confidence_score=0.95,
            reasons=["Full (A) attestation: Caller identity verified"],
        )

        result_dict = result.to_dict()

        assert result_dict["status"] == "verified"
        assert result_dict["attestation"] == "A"
        assert result_dict["review_flag"] == "none"
        assert result_dict["confidence_score"] == 0.95
        assert result_dict["requires_manual_review"] is False

    def test_requires_manual_review_flag(self):
        """Test requires_manual_review method"""
        manual_review_result = VerificationResult(
            status=VerificationStatus.VERIFIED,
            attestation=AttestationLevel.GATEWAY,
            review_flag=ReviewFlag.MANUAL_REVIEW,
            confidence_score=0.2,
        )

        high_risk_result = VerificationResult(
            status=VerificationStatus.VERIFIED,
            attestation=AttestationLevel.UNKNOWN,
            review_flag=ReviewFlag.HIGH_RISK,
            confidence_score=0.1,
        )

        normal_result = VerificationResult(
            status=VerificationStatus.VERIFIED,
            attestation=AttestationLevel.FULL,
            review_flag=ReviewFlag.NONE,
            confidence_score=0.95,
        )

        assert manual_review_result.requires_manual_review() is True
        assert high_risk_result.requires_manual_review() is True
        assert normal_result.requires_manual_review() is False


class TestIntegrationScenarios:
    """Integration tests simulating real-world scenarios"""

    def test_spoofed_cli_attack_scenario(self):
        """
        Simulate a CLI spoofing attack:
        - Attacker in Nigeria
        - Spoofing a US number as CLI
        - Gateway (C) attestation (no verification)
        - Should be flagged for manual review
        """
        # Attack scenario: Nigeria-based attacker spoofing US number
        identity_header = create_test_identity_header(
            attest="C",
            orig_tn="+12025551234",  # Spoofed US number
            dest_tn="+12025559876",
        )

        result = verify_attestation(
            identity_header,
            originating_number="+12025551234",
            destination_number="+12025559876",
            originating_country="NG",  # Real origin: Nigeria
            cli_country="US",           # Spoofed CLI: US
        )

        # Should catch this fraud pattern
        assert result.attestation == AttestationLevel.GATEWAY
        assert result.review_flag == ReviewFlag.MANUAL_REVIEW
        assert result.confidence_score < 0.3

        # Verify the result indicates fraud risk
        result_dict = result.to_dict()
        assert result_dict["requires_manual_review"] is True

    def test_legitimate_international_call_scenario(self):
        """
        Simulate a legitimate international call:
        - US-based caller
        - Calling UK number
        - Full (A) attestation (carrier verified)
        - Should pass verification
        """
        identity_header = create_test_identity_header(
            attest="A",
            orig_tn="+12025551234",
            dest_tn="+442071234567",
        )

        result = verify_attestation(
            identity_header,
            originating_number="+12025551234",
            destination_number="+442071234567",
            originating_country="US",
            cli_country="US",
        )

        assert result.attestation == AttestationLevel.FULL
        assert result.review_flag == ReviewFlag.NONE
        assert result.confidence_score >= 0.9
        assert result.requires_manual_review() is False

    def test_voip_gateway_scenario(self):
        """
        Simulate a VoIP gateway scenario:
        - Call routed through gateway
        - Gateway (C) attestation (expected for VoIP)
        - Matching origin and CLI
        - Should pass but with lower confidence
        """
        identity_header = create_test_identity_header(
            attest="C",
            orig_tn="+12025551234",
            dest_tn="+12025559876",
        )

        result = verify_attestation(
            identity_header,
            originating_number="+12025551234",
            destination_number="+12025559876",
            originating_country="US",
            cli_country="US",
        )

        # Gateway attestation with matching countries - acceptable
        assert result.attestation == AttestationLevel.GATEWAY
        assert result.review_flag == ReviewFlag.NONE
        assert 0.3 <= result.confidence_score <= 0.5


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
