"""SIP header parser using scapy-compatible parsing."""
import re
import logging
from typing import Optional
from datetime import datetime

from .models import SIPHeaderInfo, SIPMethod, extract_number

logger = logging.getLogger(__name__)


def parse_sip_message(raw_sip: bytes) -> Optional[SIPHeaderInfo]:
    """Parse SIP message and extract headers.
    
    Extracts CLI and P-Asserted-Identity headers which are critical
    for detecting call masking attacks.
    
    Args:
        raw_sip: Raw SIP message bytes
        
    Returns:
        SIPHeaderInfo with extracted headers, or None if parsing fails
    """
    try:
        # Decode to string
        message = raw_sip.decode("utf-8", errors="ignore")
        lines = message.split("\r\n")
        
        if not lines:
            return None
        
        # Parse request line
        request_line = lines[0]
        method = _parse_method(request_line)
        
        # Parse headers into dict
        headers = _parse_headers(lines[1:])
        
        # Extract critical identity headers
        call_id = headers.get("call-id", headers.get("i", ""))
        from_header = headers.get("from", headers.get("f", ""))
        to_header = headers.get("to", headers.get("t", ""))
        
        # CLI from From header
        cli = extract_number_from_uri(from_header)
        
        # P-Asserted-Identity (trusted network identity)
        pai = headers.get("p-asserted-identity", "")
        p_asserted_identity = extract_number_from_uri(pai) if pai else None
        
        # Remote-Party-ID (alternative identity header)
        rpid = headers.get("remote-party-id", "")
        remote_party_id = extract_number_from_uri(rpid) if rpid else None
        
        # Contact header
        contact = headers.get("contact", headers.get("m", ""))
        
        # Via headers (can be multiple)
        via_headers = _parse_multi_header(headers, "via", "v")
        
        # CSeq
        cseq = headers.get("cseq", "")
        
        return SIPHeaderInfo(
            call_id=call_id,
            cli=cli,
            p_asserted_identity=p_asserted_identity,
            remote_party_id=remote_party_id,
            from_uri=from_header,
            to_uri=to_header,
            contact_uri=contact if contact else None,
            via=via_headers,
            cseq=cseq,
            method=method,
            timestamp=datetime.utcnow()
        )
        
    except Exception as e:
        logger.error(f"Failed to parse SIP message: {e}")
        return None


def extract_number_from_uri(uri_or_header: str) -> Optional[str]:
    """Extract phone number from SIP URI or header value.
    
    Handles various formats:
    - sip:+12025551234@example.com
    - <sip:12025551234@10.0.0.1>
    - "Display Name" <sip:+12025551234@host>;tag=xyz
    - tel:+12025551234
    
    Args:
        uri_or_header: SIP URI or full header value
        
    Returns:
        Extracted phone number or None
    """
    if not uri_or_header:
        return None
    
    # Try to extract from angle brackets first
    match = re.search(r'<([^>]+)>', uri_or_header)
    if match:
        uri = match.group(1)
    else:
        uri = uri_or_header
    
    # Use the model's extract function
    number = extract_number(uri)
    
    return number if number else None


def _parse_method(request_line: str) -> SIPMethod:
    """Parse SIP method from request line."""
    parts = request_line.split()
    if not parts:
        return SIPMethod.INVITE
    
    method_str = parts[0].upper()
    try:
        return SIPMethod(method_str)
    except ValueError:
        return SIPMethod.INVITE


def _parse_headers(lines: list[str]) -> dict[str, str]:
    """Parse SIP headers into a dictionary.
    
    Note: For headers that can appear multiple times (Via, Route, etc.),
    only the first occurrence is stored. Use _parse_multi_header for those.
    """
    headers = {}
    current_header = None
    current_value = ""
    
    for line in lines:
        if not line:  # Empty line marks end of headers
            break
            
        # Check for header continuation (line starts with whitespace)
        if line[0] in " \t":
            if current_header:
                current_value += " " + line.strip()
            continue
        
        # Save previous header
        if current_header:
            headers[current_header.lower()] = current_value
        
        # Parse new header
        if ":" in line:
            header_name, _, value = line.partition(":")
            current_header = header_name.strip()
            current_value = value.strip()
        else:
            current_header = None
            current_value = ""
    
    # Don't forget the last header
    if current_header:
        headers[current_header.lower()] = current_value
    
    return headers


def _parse_multi_header(headers: dict[str, str], name: str, short_name: str) -> list[str]:
    """Parse multi-value headers like Via."""
    values = []
    
    # Check both full and compact names
    for key in [name, short_name]:
        if key in headers:
            # Split on comma for multiple values in single header
            vals = headers[key].split(",")
            values.extend([v.strip() for v in vals])
    
    return values


def is_sip_message(data: bytes) -> bool:
    """Check if data looks like a SIP message."""
    if not data:
        return False
    
    # SIP requests start with method
    sip_methods = [b"INVITE", b"ACK", b"BYE", b"CANCEL", b"REGISTER", 
                   b"OPTIONS", b"INFO", b"UPDATE", b"PRACK", b"SUBSCRIBE", 
                   b"NOTIFY", b"REFER", b"MESSAGE"]
    
    # SIP responses start with SIP/2.0
    if data.startswith(b"SIP/2.0"):
        return True
    
    for method in sip_methods:
        if data.startswith(method):
            return True
    
    return False
