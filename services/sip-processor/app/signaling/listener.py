"""Real-time SIP packet capture using scapy."""
import asyncio
import logging
from typing import Callable, Optional, Awaitable
from dataclasses import dataclass
from datetime import datetime

try:
    from scapy.all import sniff, UDP, AsyncSniffer
    from scapy.layers.inet import IP
    SCAPY_AVAILABLE = True
except ImportError:
    SCAPY_AVAILABLE = False

from .parser import parse_sip_message, is_sip_message
from .models import SIPEvent, SIPHeaderInfo

logger = logging.getLogger(__name__)


@dataclass
class ListenerConfig:
    """Configuration for SIP listener."""
    interface: str = "eth0"
    port: int = 5060
    buffer_size: int = 65535
    promiscuous: bool = True


class SIPSignalingListener:
    """Real-time SIP packet capture and parsing.
    
    Uses scapy for packet capture when available, falls back to
    socket-based capture otherwise.
    """
    
    def __init__(
        self, 
        config: Optional[ListenerConfig] = None,
        on_sip_event: Optional[Callable[[SIPEvent], Awaitable[None]]] = None
    ):
        """Initialize the SIP listener.
        
        Args:
            config: Listener configuration
            on_sip_event: Async callback for processed SIP events
        """
        self.config = config or ListenerConfig()
        self.on_sip_event = on_sip_event
        self.running = False
        self._sniffer: Optional[AsyncSniffer] = None
        self._event_queue: asyncio.Queue[SIPEvent] = asyncio.Queue(maxsize=10000)
        
    def _packet_callback(self, packet) -> None:
        """Process captured packet (sync callback for scapy)."""
        try:
            if not SCAPY_AVAILABLE:
                return
                
            if UDP not in packet:
                return
                
            udp = packet[UDP]
            
            # Check if it's on SIP port
            if udp.dport != self.config.port and udp.sport != self.config.port:
                return
            
            # Extract raw SIP data
            raw_sip = bytes(udp.payload)
            
            if not raw_sip or not is_sip_message(raw_sip):
                return
            
            # Parse SIP message
            header_info = parse_sip_message(raw_sip)
            if not header_info:
                return
            
            # Create SIP event
            ip = packet[IP] if IP in packet else None
            event = SIPEvent(
                header_info=header_info,
                raw_message=raw_sip,
                source_ip=ip.src if ip else "0.0.0.0",
                source_port=udp.sport,
                dest_ip=ip.dst if ip else "0.0.0.0",
                dest_port=udp.dport,
                timestamp=datetime.utcnow()
            )
            
            # Queue for async processing
            try:
                self._event_queue.put_nowait(event)
            except asyncio.QueueFull:
                logger.warning("SIP event queue full, dropping event")
                
        except Exception as e:
            logger.error(f"Error processing packet: {e}")
    
    async def _process_events(self) -> None:
        """Process events from the queue asynchronously."""
        while self.running:
            try:
                event = await asyncio.wait_for(
                    self._event_queue.get(), 
                    timeout=1.0
                )
                
                if self.on_sip_event:
                    await self.on_sip_event(event)
                    
            except asyncio.TimeoutError:
                continue
            except Exception as e:
                logger.error(f"Error processing SIP event: {e}")
    
    async def start(self) -> None:
        """Start the SIP listener."""
        if not SCAPY_AVAILABLE:
            logger.error("scapy not available - packet capture disabled")
            return
        
        self.running = True
        logger.info(
            f"Starting SIP listener on {self.config.interface}:{self.config.port}"
        )
        
        # Start async sniffer
        bpf_filter = f"udp port {self.config.port}"
        self._sniffer = AsyncSniffer(
            iface=self.config.interface,
            filter=bpf_filter,
            prn=self._packet_callback,
            store=False
        )
        self._sniffer.start()
        
        # Start event processor
        asyncio.create_task(self._process_events())
        
        logger.info("SIP listener started")
    
    async def stop(self) -> None:
        """Stop the SIP listener."""
        self.running = False
        
        if self._sniffer:
            self._sniffer.stop()
            self._sniffer = None
        
        logger.info("SIP listener stopped")
    
    async def process_raw_message(self, raw_sip: bytes, source_ip: str = "0.0.0.0") -> Optional[SIPHeaderInfo]:
        """Process a raw SIP message directly (for HTTP API usage).
        
        Args:
            raw_sip: Raw SIP message bytes
            source_ip: Source IP address
            
        Returns:
            Parsed SIP header info
        """
        return parse_sip_message(raw_sip)
