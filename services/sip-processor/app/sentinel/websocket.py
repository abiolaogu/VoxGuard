"""
Sentinel WebSocket handlers for real-time alert notifications

Provides WebSocket endpoints for streaming fraud alerts to frontend clients.
"""
import asyncio
import json
from typing import Set
from fastapi import WebSocket, WebSocketDisconnect, APIRouter, Depends
from datetime import datetime
import asyncpg

router = APIRouter(prefix="/api/v1/sentinel", tags=["sentinel-websocket"])


class AlertNotificationManager:
    """
    Manages WebSocket connections for real-time alert notifications

    Allows multiple clients to subscribe to fraud alert updates.
    Broadcasts new alerts to all connected clients.
    """

    def __init__(self):
        self.active_connections: Set[WebSocket] = set()

    async def connect(self, websocket: WebSocket):
        """Accept new WebSocket connection"""
        await websocket.accept()
        self.active_connections.add(websocket)

    def disconnect(self, websocket: WebSocket):
        """Remove WebSocket connection"""
        self.active_connections.discard(websocket)

    async def broadcast_alert(self, alert: dict):
        """
        Broadcast alert to all connected clients

        Args:
            alert: Alert dictionary with fraud detection details
        """
        message = json.dumps({
            "type": "alert",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "data": alert
        })

        # Remove disconnected clients
        disconnected = set()

        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception:
                disconnected.add(connection)

        # Clean up disconnected clients
        self.active_connections -= disconnected

    async def send_heartbeat(self):
        """Send periodic heartbeat to keep connections alive"""
        message = json.dumps({
            "type": "heartbeat",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })

        disconnected = set()

        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception:
                disconnected.add(connection)

        self.active_connections -= disconnected


# Global notification manager instance
notification_manager = AlertNotificationManager()


async def get_db_pool():
    """Placeholder for database pool dependency"""
    from fastapi import HTTPException
    raise HTTPException(status_code=500, detail="Database pool not configured")


@router.websocket("/ws/alerts")
async def websocket_alerts_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time fraud alert notifications

    **Usage:**
    ```javascript
    const ws = new WebSocket('ws://localhost:8000/api/v1/sentinel/ws/alerts');

    ws.onmessage = (event) => {
        const message = JSON.parse(event.data);

        if (message.type === 'alert') {
            console.log('New fraud alert:', message.data);
            // Update UI with alert details
        } else if (message.type === 'heartbeat') {
            console.log('Connection alive:', message.timestamp);
        }
    };

    ws.onerror = (error) => {
        console.error('WebSocket error:', error);
    };

    ws.onclose = () => {
        console.log('WebSocket connection closed');
    };
    ```

    **Message Types:**

    1. Alert Message:
    ```json
    {
        "type": "alert",
        "timestamp": "2024-01-15T14:32:15Z",
        "data": {
            "id": 123,
            "alert_type": "SDHF_SIMBOX",
            "suspect_number": "+2348012345678",
            "alert_severity": "HIGH",
            "evidence_summary": "75 unique destinations, avg 2.1s duration",
            "call_count": 75,
            "unique_destinations": 75,
            "avg_duration_seconds": 2.1,
            "created_at": "2024-01-15T14:32:15Z"
        }
    }
    ```

    2. Heartbeat Message:
    ```json
    {
        "type": "heartbeat",
        "timestamp": "2024-01-15T14:32:30Z"
    }
    ```
    """
    await notification_manager.connect(websocket)

    try:
        # Send welcome message
        await websocket.send_text(json.dumps({
            "type": "connected",
            "message": "Connected to Sentinel alert stream",
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }))

        # Keep connection alive and listen for client messages
        while True:
            # Wait for client messages (optional - can be used for client filters)
            try:
                data = await asyncio.wait_for(websocket.receive_text(), timeout=30.0)
                # Echo back client messages (can be extended for filtering)
                await websocket.send_text(json.dumps({
                    "type": "ack",
                    "message": "Message received",
                    "data": data
                }))
            except asyncio.TimeoutError:
                # Send heartbeat every 30 seconds if no activity
                await websocket.send_text(json.dumps({
                    "type": "heartbeat",
                    "timestamp": datetime.utcnow().isoformat() + "Z"
                }))

    except WebSocketDisconnect:
        notification_manager.disconnect(websocket)
    except Exception as e:
        notification_manager.disconnect(websocket)
        print(f"WebSocket error: {e}")


async def notify_new_alert(alert: dict):
    """
    Helper function to broadcast new alerts to all WebSocket clients

    Call this function whenever a new alert is generated:

    ```python
    from app.sentinel.websocket import notify_new_alert

    # After creating alert in database
    await notify_new_alert({
        "id": alert_id,
        "alert_type": "SDHF_SIMBOX",
        "suspect_number": "+2348012345678",
        "alert_severity": "HIGH",
        ...
    })
    ```

    Args:
        alert: Alert dictionary with fraud detection details
    """
    await notification_manager.broadcast_alert(alert)


async def start_heartbeat_task():
    """
    Background task to send periodic heartbeats

    Should be started when the application starts:

    ```python
    @app.on_event("startup")
    async def startup():
        asyncio.create_task(start_heartbeat_task())
    ```
    """
    while True:
        await asyncio.sleep(30)  # Send heartbeat every 30 seconds
        await notification_manager.send_heartbeat()
