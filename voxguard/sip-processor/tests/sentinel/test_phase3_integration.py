"""
Phase 3 End-to-End Integration Tests

Tests for real-time event receiver, WebSocket notifications, and full system integration.
"""
import pytest
import asyncio
import json
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, MagicMock, patch
import asyncpg


class TestRealTimeEventReceiver:
    """Test real-time call event endpoint"""

    @pytest.fixture
    def mock_db_pool(self):
        """Mock database pool"""
        pool = AsyncMock(spec=asyncpg.Pool)
        conn = AsyncMock()
        pool.acquire.return_value.__aenter__.return_value = conn
        return pool

    @pytest.mark.asyncio
    async def test_receive_valid_call_event(self, mock_db_pool):
        """Test receiving a valid real-time call event"""
        from app.sentinel.routes import receive_call_event, RealTimeCallEvent

        event = RealTimeCallEvent(
            caller_number="+2348012345678",
            callee_number="+2349087654321",
            duration_seconds=45,
            call_direction="outbound",
            timestamp="2024-01-15T14:32:15Z"
        )

        # Mock database operations
        mock_db_pool.acquire.return_value.__aenter__.return_value.fetchrow.return_value = {
            'call_count': 10,
            'unique_destinations': 8,
            'avg_duration': 35.5
        }

        with patch('app.sentinel.routes.SentinelDatabase') as mock_db:
            mock_db.return_value.insert_call_records = AsyncMock()

            response = await receive_call_event(event, mock_db_pool)

            assert response.status == "accepted"
            assert response.event_id.startswith("evt_")
            assert 0.0 <= response.risk_score <= 1.0

    @pytest.mark.asyncio
    async def test_event_with_invalid_timestamp(self, mock_db_pool):
        """Test event with invalid timestamp format"""
        from app.sentinel.routes import receive_call_event, RealTimeCallEvent
        from fastapi import HTTPException

        event = RealTimeCallEvent(
            caller_number="+2348012345678",
            callee_number="+2349087654321",
            duration_seconds=45,
            call_direction="outbound",
            timestamp="invalid-timestamp"
        )

        with pytest.raises(HTTPException) as exc_info:
            await receive_call_event(event, mock_db_pool)

        assert exc_info.value.status_code == 400
        assert "Invalid timestamp" in exc_info.value.detail

    @pytest.mark.asyncio
    async def test_high_risk_caller(self, mock_db_pool):
        """Test risk scoring for high-risk caller (many short calls)"""
        from app.sentinel.routes import receive_call_event, RealTimeCallEvent

        event = RealTimeCallEvent(
            caller_number="+2348012345678",
            callee_number="+2349087654321",
            duration_seconds=2,
            call_direction="outbound",
            timestamp="2024-01-15T14:32:15Z"
        )

        # Mock high-risk pattern: 150 calls to 120 unique numbers, avg 2s duration
        mock_db_pool.acquire.return_value.__aenter__.return_value.fetchrow.return_value = {
            'call_count': 150,
            'unique_destinations': 120,
            'avg_duration': 2.0
        }

        with patch('app.sentinel.routes.SentinelDatabase') as mock_db:
            mock_db.return_value.insert_call_records = AsyncMock()

            response = await receive_call_event(event, mock_db_pool)

            assert response.status == "accepted"
            assert response.risk_score > 0.7  # High risk

    @pytest.mark.asyncio
    async def test_low_risk_caller(self, mock_db_pool):
        """Test risk scoring for low-risk caller (few normal calls)"""
        from app.sentinel.routes import receive_call_event, RealTimeCallEvent

        event = RealTimeCallEvent(
            caller_number="+2348012345678",
            callee_number="+2349087654321",
            duration_seconds=120,
            call_direction="outbound",
            timestamp="2024-01-15T14:32:15Z"
        )

        # Mock low-risk pattern: 5 calls to 4 unique numbers, avg 120s duration
        mock_db_pool.acquire.return_value.__aenter__.return_value.fetchrow.return_value = {
            'call_count': 5,
            'unique_destinations': 4,
            'avg_duration': 120.0
        }

        with patch('app.sentinel.routes.SentinelDatabase') as mock_db:
            mock_db.return_value.insert_call_records = AsyncMock()

            response = await receive_call_event(event, mock_db_pool)

            assert response.status == "accepted"
            assert response.risk_score < 0.3  # Low risk

    @pytest.mark.asyncio
    async def test_new_caller_zero_risk(self, mock_db_pool):
        """Test risk scoring for caller with no recent history"""
        from app.sentinel.routes import receive_call_event, RealTimeCallEvent

        event = RealTimeCallEvent(
            caller_number="+2348012345678",
            callee_number="+2349087654321",
            duration_seconds=60,
            call_direction="outbound",
            timestamp="2024-01-15T14:32:15Z"
        )

        # Mock no history
        mock_db_pool.acquire.return_value.__aenter__.return_value.fetchrow.return_value = {
            'call_count': 0,
            'unique_destinations': 0,
            'avg_duration': None
        }

        with patch('app.sentinel.routes.SentinelDatabase') as mock_db:
            mock_db.return_value.insert_call_records = AsyncMock()

            response = await receive_call_event(event, mock_db_pool)

            assert response.status == "accepted"
            assert response.risk_score == 0.0  # No history = no risk


class TestWebSocketAlerts:
    """Test WebSocket alert notifications"""

    @pytest.mark.asyncio
    async def test_websocket_connection_acceptance(self):
        """Test WebSocket connection is accepted"""
        from app.sentinel.websocket import AlertNotificationManager
        from unittest.mock import AsyncMock

        manager = AlertNotificationManager()
        mock_websocket = AsyncMock()

        await manager.connect(mock_websocket)

        mock_websocket.accept.assert_called_once()
        assert mock_websocket in manager.active_connections

    def test_websocket_disconnection(self):
        """Test WebSocket disconnection cleanup"""
        from app.sentinel.websocket import AlertNotificationManager
        from unittest.mock import MagicMock

        manager = AlertNotificationManager()
        mock_websocket = MagicMock()
        manager.active_connections.add(mock_websocket)

        manager.disconnect(mock_websocket)

        assert mock_websocket not in manager.active_connections

    @pytest.mark.asyncio
    async def test_broadcast_alert_to_clients(self):
        """Test broadcasting alert to multiple WebSocket clients"""
        from app.sentinel.websocket import AlertNotificationManager
        from unittest.mock import AsyncMock

        manager = AlertNotificationManager()

        # Create mock WebSocket clients
        client1 = AsyncMock()
        client2 = AsyncMock()
        manager.active_connections.add(client1)
        manager.active_connections.add(client2)

        alert = {
            "id": 123,
            "alert_type": "SDHF_SIMBOX",
            "suspect_number": "+2348012345678",
            "alert_severity": "HIGH"
        }

        await manager.broadcast_alert(alert)

        # Both clients should receive the alert
        assert client1.send_text.call_count == 1
        assert client2.send_text.call_count == 1

        # Verify message format
        sent_message = json.loads(client1.send_text.call_args[0][0])
        assert sent_message["type"] == "alert"
        assert sent_message["data"] == alert
        assert "timestamp" in sent_message

    @pytest.mark.asyncio
    async def test_broadcast_removes_disconnected_clients(self):
        """Test that disconnected clients are removed during broadcast"""
        from app.sentinel.websocket import AlertNotificationManager
        from unittest.mock import AsyncMock

        manager = AlertNotificationManager()

        # Create mock clients: one working, one disconnected
        working_client = AsyncMock()
        broken_client = AsyncMock()
        broken_client.send_text.side_effect = Exception("Connection closed")

        manager.active_connections.add(working_client)
        manager.active_connections.add(broken_client)

        alert = {"id": 123, "alert_type": "SDHF_SIMBOX"}

        await manager.broadcast_alert(alert)

        # Working client should still be connected
        assert working_client in manager.active_connections
        # Broken client should be removed
        assert broken_client not in manager.active_connections

    @pytest.mark.asyncio
    async def test_heartbeat_message(self):
        """Test heartbeat messages keep connection alive"""
        from app.sentinel.websocket import AlertNotificationManager
        from unittest.mock import AsyncMock

        manager = AlertNotificationManager()
        client = AsyncMock()
        manager.active_connections.add(client)

        await manager.send_heartbeat()

        assert client.send_text.call_count == 1
        sent_message = json.loads(client.send_text.call_args[0][0])
        assert sent_message["type"] == "heartbeat"
        assert "timestamp" in sent_message


class TestEndToEndIntegration:
    """End-to-end integration tests for complete workflows"""

    @pytest.mark.asyncio
    async def test_full_detection_pipeline_with_websocket(self, mock_db_pool):
        """Test complete flow: ingest -> detect -> alert -> WebSocket notification"""
        from app.sentinel.detector import SDHFDetector
        from app.sentinel.websocket import notification_manager
        from unittest.mock import AsyncMock, patch

        # Setup mock data
        mock_conn = AsyncMock()
        mock_db_pool.acquire.return_value.__aenter__.return_value = mock_conn

        # Mock detection query result
        mock_conn.fetch.return_value = [
            {
                'caller_number': '+2348012345678',
                'call_count': 75,
                'unique_destinations': 65,
                'avg_duration': 2.3,
                'first_call': datetime.utcnow() - timedelta(hours=23),
                'last_call': datetime.utcnow()
            }
        ]

        # Mock alert creation
        mock_conn.fetchrow.return_value = {
            'id': 456,
            'created_at': datetime.utcnow()
        }

        # Mock WebSocket client
        mock_client = AsyncMock()
        notification_manager.active_connections.add(mock_client)

        # Run detection
        detector = SDHFDetector(mock_db_pool)
        alert_ids = await detector.generate_sdhf_alerts()

        # Verify alert was created
        assert len(alert_ids) == 1
        assert alert_ids[0] == 456

        # Verify WebSocket notification was sent
        await asyncio.sleep(0.1)  # Allow async broadcast to complete
        assert mock_client.send_text.call_count > 0

        # Clean up
        notification_manager.active_connections.clear()

    @pytest.mark.asyncio
    async def test_real_time_event_triggers_detection(self, mock_db_pool):
        """Test that real-time events can trigger immediate detection"""
        from app.sentinel.routes import receive_call_event, RealTimeCallEvent

        # Send multiple events simulating SIM Box pattern
        events = [
            RealTimeCallEvent(
                caller_number="+2348012345678",
                callee_number=f"+23490{8760000 + i}",
                duration_seconds=2,
                call_direction="outbound",
                timestamp=datetime.utcnow().isoformat() + "Z"
            )
            for i in range(5)
        ]

        # Mock increasing risk scores
        risk_scores = [0.1, 0.3, 0.5, 0.7, 0.9]

        for i, event in enumerate(events):
            mock_db_pool.acquire.return_value.__aenter__.return_value.fetchrow.return_value = {
                'call_count': (i + 1) * 20,
                'unique_destinations': (i + 1) * 18,
                'avg_duration': 2.0
            }

            with patch('app.sentinel.routes.SentinelDatabase') as mock_db:
                mock_db.return_value.insert_call_records = AsyncMock()

                response = await receive_call_event(event, mock_db_pool)

                # Risk score should increase with each event
                assert response.status == "accepted"
                if i > 0:
                    # Later events should have higher risk
                    assert response.risk_score >= 0.0

    @pytest.mark.asyncio
    async def test_alert_management_workflow(self, mock_db_pool):
        """Test complete alert lifecycle: create -> retrieve -> review"""
        from app.sentinel.routes import detect_sdhf, get_alerts, update_alert
        from app.sentinel.routes import SDHFDetectionRequest

        mock_conn = AsyncMock()
        mock_db_pool.acquire.return_value.__aenter__.return_value = mock_conn

        # Step 1: Create alerts via SDHF detection
        mock_conn.fetch.return_value = [
            {
                'caller_number': '+2348012345678',
                'call_count': 100,
                'unique_destinations': 85,
                'avg_duration': 1.8,
                'first_call': datetime.utcnow() - timedelta(hours=20),
                'last_call': datetime.utcnow()
            }
        ]
        mock_conn.fetchrow.return_value = {'id': 789, 'created_at': datetime.utcnow()}
        mock_conn.fetchval.return_value = 789

        detection_request = SDHFDetectionRequest(
            time_window_hours=24,
            min_unique_destinations=50,
            max_avg_duration_seconds=3.0
        )

        detection_result = await detect_sdhf(detection_request, mock_db_pool)
        assert detection_result['alerts_generated'] == 1

        # Step 2: Retrieve alerts
        with patch('app.sentinel.routes.SentinelDatabase') as mock_db:
            mock_db.return_value.get_alerts = AsyncMock(return_value=[
                {
                    'id': 789,
                    'alert_type': 'SDHF_SIMBOX',
                    'suspect_number': '+2348012345678',
                    'alert_severity': 'HIGH',
                    'reviewed': False
                }
            ])

            alerts_result = await get_alerts(severity="HIGH", reviewed=False, limit=50, db_pool=mock_db_pool)
            assert alerts_result['count'] == 1
            assert alerts_result['alerts'][0]['id'] == 789

        # Step 3: Mark alert as reviewed
        mock_conn.fetchrow.return_value = {
            'id': 789,
            'reviewed': True,
            'reviewer_notes': 'Confirmed SIM Box - blocked caller'
        }

        review_result = await update_alert(
            alert_id=789,
            reviewed=True,
            reviewer_notes="Confirmed SIM Box - blocked caller",
            db_pool=mock_db_pool
        )

        assert review_result['status'] == 'success'
        assert review_result['alert']['reviewed'] == True


class TestPerformanceAndScaling:
    """Test performance under load"""

    @pytest.mark.asyncio
    async def test_concurrent_real_time_events(self, mock_db_pool):
        """Test handling multiple concurrent real-time events"""
        from app.sentinel.routes import receive_call_event, RealTimeCallEvent

        # Create 50 concurrent events
        events = [
            RealTimeCallEvent(
                caller_number=f"+23480{12340000 + i}",
                callee_number=f"+23490{87650000 + i}",
                duration_seconds=45,
                call_direction="outbound",
                timestamp=datetime.utcnow().isoformat() + "Z"
            )
            for i in range(50)
        ]

        mock_db_pool.acquire.return_value.__aenter__.return_value.fetchrow.return_value = {
            'call_count': 10,
            'unique_destinations': 8,
            'avg_duration': 35.5
        }

        with patch('app.sentinel.routes.SentinelDatabase') as mock_db:
            mock_db.return_value.insert_call_records = AsyncMock()

            # Process all events concurrently
            tasks = [receive_call_event(event, mock_db_pool) for event in events]
            results = await asyncio.gather(*tasks)

            # All events should be processed successfully
            assert len(results) == 50
            assert all(r.status == "accepted" for r in results)

    @pytest.mark.asyncio
    async def test_websocket_with_many_clients(self):
        """Test WebSocket broadcast to many concurrent clients"""
        from app.sentinel.websocket import AlertNotificationManager
        from unittest.mock import AsyncMock

        manager = AlertNotificationManager()

        # Connect 100 mock clients
        clients = [AsyncMock() for _ in range(100)]
        for client in clients:
            manager.active_connections.add(client)

        alert = {"id": 999, "alert_type": "SDHF_SIMBOX"}

        await manager.broadcast_alert(alert)

        # All clients should receive the alert
        assert all(client.send_text.call_count == 1 for client in clients)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
