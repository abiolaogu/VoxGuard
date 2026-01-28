"""
Unit Tests for Domain Entities

Tests entity behavior, state transitions, and invariants.
"""

import pytest
from datetime import datetime, timedelta
from app.domain.entities import (
    Call,
    CallStatus,
    FraudAlert,
    AlertStatus,
    ResolutionType,
    Blacklist,
)
from app.domain.value_objects import (
    MSISDN,
    IPAddress,
    FraudScore,
    CallId,
    FraudType,
    Severity,
)


class TestCall:
    """Tests for Call entity"""
    
    def test_create_call(self):
        """Should create a call with valid data"""
        call = Call.create(
            a_number="+2348012345678",
            b_number="+2348098765432",
            source_ip="192.168.1.1",
        )
        
        assert call.a_number == MSISDN("+2348012345678")
        assert call.b_number == MSISDN("+2348098765432")
        assert call.status == CallStatus.RINGING
        assert not call.is_flagged
    
    def test_flag_as_fraud(self):
        """Should flag call as fraud"""
        call = Call.create(
            a_number="+2348012345678",
            b_number="+2348098765432",
            source_ip="192.168.1.1",
        )
        
        call.flag_as_fraud("alert-123", FraudScore(0.9))
        
        assert call.is_flagged
        assert call.alert_id == "alert-123"
        assert call.fraud_score.value == 0.9
    
    def test_cannot_flag_twice(self):
        """Should not allow flagging twice"""
        call = Call.create(
            a_number="+2348012345678",
            b_number="+2348098765432",
            source_ip="192.168.1.1",
        )
        
        call.flag_as_fraud("alert-123", FraudScore(0.9))
        
        with pytest.raises(ValueError):
            call.flag_as_fraud("alert-456", FraudScore(0.8))
    
    def test_update_status(self):
        """Should update status correctly"""
        call = Call.create(
            a_number="+2348012345678",
            b_number="+2348098765432",
            source_ip="192.168.1.1",
        )
        
        call.update_status(CallStatus.ACTIVE)
        assert call.status == CallStatus.ACTIVE
        
        call.update_status(CallStatus.COMPLETED)
        assert call.status == CallStatus.COMPLETED
    
    def test_cannot_update_after_terminal(self):
        """Should not allow status update after terminal state"""
        call = Call.create(
            a_number="+2348012345678",
            b_number="+2348098765432",
            source_ip="192.168.1.1",
        )
        
        call.update_status(CallStatus.COMPLETED)
        
        with pytest.raises(ValueError):
            call.update_status(CallStatus.ACTIVE)
    
    def test_cli_masking_detection(self):
        """Should detect potential CLI masking"""
        # Nigerian number but foreign IP
        call = Call.create(
            a_number="+2348012345678",
            b_number="+2348098765432",
            source_ip="8.8.8.8",  # Public IP (likely international)
        )
        
        assert call.is_potential_cli_masking


class TestFraudAlert:
    """Tests for FraudAlert entity"""
    
    def create_test_alert(self) -> FraudAlert:
        """Helper to create test alert"""
        return FraudAlert.create(
            b_number="+2348098765432",
            fraud_type=FraudType.CLI_MASKING,
            score=0.85,
            a_numbers=["+2348011111111", "+2348022222222"],
            call_ids=["call-1", "call-2"],
            source_ips=["192.168.1.1"],
        )
    
    def test_create_alert(self):
        """Should create alert with correct data"""
        alert = self.create_test_alert()
        
        assert alert.fraud_type == FraudType.CLI_MASKING
        assert alert.severity == Severity.HIGH
        assert alert.status == AlertStatus.PENDING
        assert alert.distinct_callers == 2
    
    def test_acknowledge_alert(self):
        """Should acknowledge alert"""
        alert = self.create_test_alert()
        
        alert.acknowledge("analyst-1")
        
        assert alert.status == AlertStatus.ACKNOWLEDGED
        assert alert.acknowledged_by == "analyst-1"
        assert alert.acknowledged_at is not None
    
    def test_cannot_acknowledge_twice(self):
        """Should not allow acknowledging twice"""
        alert = self.create_test_alert()
        alert.acknowledge("analyst-1")
        
        with pytest.raises(ValueError):
            alert.acknowledge("analyst-2")
    
    def test_start_investigation(self):
        """Should start investigation after acknowledgment"""
        alert = self.create_test_alert()
        alert.acknowledge("analyst-1")
        
        alert.start_investigation()
        
        assert alert.status == AlertStatus.INVESTIGATING
    
    def test_cannot_investigate_without_acknowledgment(self):
        """Should not allow investigation without acknowledgment"""
        alert = self.create_test_alert()
        
        with pytest.raises(ValueError):
            alert.start_investigation()
    
    def test_resolve_alert(self):
        """Should resolve alert"""
        alert = self.create_test_alert()
        alert.acknowledge("analyst-1")
        
        alert.resolve("analyst-1", ResolutionType.CONFIRMED_FRAUD, "Verified attack")
        
        assert alert.status == AlertStatus.RESOLVED
        assert alert.resolved_by == "analyst-1"
        assert alert.resolution == ResolutionType.CONFIRMED_FRAUD
        assert alert.resolution_notes == "Verified attack"
    
    def test_cannot_resolve_twice(self):
        """Should not allow resolving twice"""
        alert = self.create_test_alert()
        alert.acknowledge("analyst-1")
        alert.resolve("analyst-1", ResolutionType.CONFIRMED_FRAUD)
        
        with pytest.raises(ValueError):
            alert.resolve("analyst-2", ResolutionType.FALSE_POSITIVE)
    
    def test_report_to_ncc(self):
        """Should report to NCC"""
        alert = self.create_test_alert()
        
        alert.report_to_ncc("NCC-2024-001")
        
        assert alert.ncc_reported
        assert alert.ncc_report_id == "NCC-2024-001"
        assert alert.status == AlertStatus.REPORTED_NCC
    
    def test_auto_escalate_critical(self):
        """Critical alerts with high confidence should auto-escalate"""
        alert = FraudAlert.create(
            b_number="+2348098765432",
            fraud_type=FraudType.CLI_MASKING,
            score=0.95,  # High enough for auto-escalate
            a_numbers=["+2348011111111"],
            call_ids=["call-1"],
            source_ips=["192.168.1.1"],
        )
        
        assert alert.should_auto_escalate


class TestBlacklist:
    """Tests for Blacklist entity"""
    
    def test_create_msisdn_entry(self):
        """Should create MSISDN blacklist entry"""
        entry = Blacklist.create_msisdn_entry(
            msisdn="+2348012345678",
            reason="Fraud detected",
            added_by="admin",
        )
        
        assert entry.entry_type == "msisdn"
        assert entry.value == "+2348012345678"
        assert entry.source == "manual"
    
    def test_create_ip_entry(self):
        """Should create IP blacklist entry"""
        entry = Blacklist.create_ip_entry(
            ip="192.168.1.1",
            reason="SIM-box gateway",
            added_by="admin",
        )
        
        assert entry.entry_type == "ip"
        assert entry.value == "192.168.1.1"
    
    def test_not_expired_without_expiry(self):
        """Entry without expiry should not expire"""
        entry = Blacklist.create_msisdn_entry(
            msisdn="+2348012345678",
            reason="Fraud",
            added_by="admin",
        )
        
        assert not entry.is_expired
    
    def test_expired_entry(self):
        """Entry past expiry should be expired"""
        entry = Blacklist.create_msisdn_entry(
            msisdn="+2348012345678",
            reason="Fraud",
            added_by="admin",
        )
        entry.expires_at = datetime.utcnow() - timedelta(hours=1)
        
        assert entry.is_expired
