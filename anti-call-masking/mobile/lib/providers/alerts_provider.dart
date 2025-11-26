import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/alert.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AlertsProvider extends ChangeNotifier {
  List<Alert> _alerts = [];
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  List<Alert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered alert counts
  int get totalAlerts => _alerts.length;
  int get criticalAlerts => _alerts.where((a) => a.severity == 'CRITICAL').length;
  int get highAlerts => _alerts.where((a) => a.severity == 'HIGH').length;
  int get mediumAlerts => _alerts.where((a) => a.severity == 'MEDIUM').length;
  int get lowAlerts => _alerts.where((a) => a.severity == 'LOW').length;
  int get newAlerts => _alerts.where((a) => a.status == 'NEW').length;
  int get investigatingAlerts => _alerts.where((a) => a.status == 'INVESTIGATING').length;

  // Get alerts by severity
  List<Alert> getAlertsBySeverity(String severity) {
    return _alerts.where((a) => a.severity == severity).toList();
  }

  // Get alerts by status
  List<Alert> getAlertsByStatus(String status) {
    return _alerts.where((a) => a.status == status).toList();
  }

  // Search alerts
  List<Alert> searchAlerts(String query) {
    final q = query.toLowerCase();
    return _alerts.where((a) {
      return a.bNumber.toLowerCase().contains(q) ||
          a.aNumbers.any((num) => num.toLowerCase().contains(q)) ||
          a.id.toLowerCase().contains(q);
    }).toList();
  }

  // Start auto-refresh
  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    stopAutoRefresh();
    _refreshTimer = Timer.periodic(interval, (_) => fetchAlerts());
  }

  // Stop auto-refresh
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // Fetch alerts from API
  Future<void> fetchAlerts({int minutes = 1440}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final previousAlertIds = _alerts.map((a) => a.id).toSet();
      _alerts = await ApiService.getAlerts(minutes: minutes);

      // Check for new critical alerts
      for (final alert in _alerts) {
        if (!previousAlertIds.contains(alert.id) && alert.severity == 'CRITICAL') {
          // Show notification for new critical alerts
          NotificationService.showAlertNotification(alert);
        }
      }

      // Sort by timestamp (newest first)
      _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _error = null;
    } catch (e) {
      _error = 'Failed to fetch alerts: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get single alert
  Alert? getAlert(String id) {
    try {
      return _alerts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update alert status
  Future<bool> updateAlertStatus(String id, String status, {String? notes}) async {
    try {
      final updatedAlert = await ApiService.updateAlertStatus(id, status, notes: notes);
      final index = _alerts.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alerts[index] = updatedAlert;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Failed to update alert: $e';
      notifyListeners();
      return false;
    }
  }

  // Mark alert as investigating
  Future<bool> markInvestigating(String id) async {
    return updateAlertStatus(id, 'INVESTIGATING');
  }

  // Mark alert as resolved
  Future<bool> markResolved(String id, {String? notes}) async {
    return updateAlertStatus(id, 'RESOLVED', notes: notes);
  }

  // Mark alert as false positive
  Future<bool> markFalsePositive(String id, {String? notes}) async {
    return updateAlertStatus(id, 'FALSE_POSITIVE', notes: notes);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
