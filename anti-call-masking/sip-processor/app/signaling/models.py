"""SIP data models."""
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Optional


class SIPMethod(str, Enum):
    """SIP request methods."""
    INVITE = "INVITE"
    ACK = "ACK"
    BYE = "BYE"
    CANCEL = "CANCEL"
    REGISTER = "REGISTER"
    OPTIONS = "OPTIONS"
    INFO = "INFO"
    UPDATE = "UPDATE"
    PRACK = "PRACK"
    SUBSCRIBE = "SUBSCRIBE"
    NOTIFY = "NOTIFY"
    REFER = "REFER"
    MESSAGE = "MESSAGE"


@dataclass
class SIPHeaderInfo:
    """Parsed SIP header information."""
    
    # Core identifiers
    call_id: str
    
    # Caller identity (critical for masking detection)
    cli: Optional[str] = None                    # Calling Line Identity (From header)
    p_asserted_identity: Optional[str] = None    # P-Asserted-Identity (trusted network ID)
    remote_party_id: Optional[str] = None        # Remote-Party-ID header
    
    # URIs
    from_uri: str = ""
    to_uri: str = ""
    contact_uri: Optional[str] = None
    
    # Call routing
    via: list[str] = field(default_factory=list)
    route: list[str] = field(default_factory=list)
    record_route: list[str] = field(default_factory=list)
    
    # Transaction
    cseq: str = ""
    method: SIPMethod = SIPMethod.INVITE
    
    # Timestamp
    timestamp: datetime = field(default_factory=datetime.utcnow)
    
    @property
    def has_cli_mismatch(self) -> bool:
        """Check if CLI differs from P-Asserted-Identity (potential spoofing)."""
        if not self.cli or not self.p_asserted_identity:
            return False
        return self.cli != self.p_asserted_identity
    
    @property
    def a_number(self) -> str:
        """Get the A-number (caller) - prefer P-Asserted-Identity if available."""
        return self.p_asserted_identity or self.cli or ""
    
    @property
    def b_number(self) -> str:
        """Get the B-number (called party) from To URI."""
        return extract_number(self.to_uri)


@dataclass
class SIPEvent:
    """SIP event for processing."""
    
    header_info: SIPHeaderInfo
    raw_message: bytes
    source_ip: str
    source_port: int
    dest_ip: str
    dest_port: int
    timestamp: datetime = field(default_factory=datetime.utcnow)
    
    @property 
    def is_invite(self) -> bool:
        """Check if this is an INVITE request."""
        return self.header_info.method == SIPMethod.INVITE


def extract_number(uri: str) -> str:
    """Extract phone number from SIP URI.
    
    Examples:
        sip:+12025551234@example.com -> +12025551234
        sip:12025551234@10.0.0.1:5060 -> 12025551234
        tel:+12025551234 -> +12025551234
    """
    if not uri:
        return ""
    
    # Remove sip: or tel: prefix
    if uri.startswith("sip:"):
        uri = uri[4:]
    elif uri.startswith("tel:"):
        uri = uri[4:]
    elif uri.startswith("<sip:"):
        uri = uri[5:]
    
    # Remove display name if present (e.g., "John Doe" <sip:...)
    if ">" in uri:
        uri = uri.split(">")[0]
    
    # Extract user part (before @)
    if "@" in uri:
        uri = uri.split("@")[0]
    
    # Remove any parameters (;param=value)
    if ";" in uri:
        uri = uri.split(";")[0]
    
    return uri.strip()
