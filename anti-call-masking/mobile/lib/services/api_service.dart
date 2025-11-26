import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/alert.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:5001';
  static const _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Health check
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get alerts
  static Future<List<Alert>> getAlerts({int minutes = 60}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/acm/alerts?minutes=$minutes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Alert.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch alerts: ${response.statusCode}');
    } catch (e) {
      // Return demo data for development
      return _getDemoAlerts();
    }
  }

  // Get single alert
  static Future<Alert> getAlert(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/acm/alerts/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Alert.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to fetch alert: ${response.statusCode}');
    } catch (e) {
      // Return demo alert for development
      return _getDemoAlerts().first;
    }
  }

  // Update alert status
  static Future<Alert> updateAlertStatus(String id, String status, {String? notes}) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/acm/alerts/$id'),
      headers: headers,
      body: json.encode({
        'status': status,
        if (notes != null) 'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      return Alert.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update alert: ${response.statusCode}');
  }

  // Get system stats
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/acm/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to fetch stats: ${response.statusCode}');
    } catch (e) {
      // Return demo stats for development
      return _getDemoStats();
    }
  }

  // Get elevated threats
  static Future<List<Map<String, dynamic>>> getElevatedThreats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/acm/threats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      }
      throw Exception('Failed to fetch threats: ${response.statusCode}');
    } catch (e) {
      return [];
    }
  }

  // Demo data for development
  static List<Alert> _getDemoAlerts() {
    return [
      Alert(
        id: 'alert-001',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        bNumber: '+2348012345678',
        aNumbers: [
          '+2347011111111',
          '+2347022222222',
          '+2347033333333',
          '+2347044444444',
          '+2347055555555',
        ],
        sourceIps: ['192.168.1.100', '192.168.1.101'],
        callCount: 5,
        windowSeconds: 5,
        severity: 'CRITICAL',
        status: 'NEW',
      ),
      Alert(
        id: 'alert-002',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        bNumber: '+2348098765432',
        aNumbers: [
          '+2347066666666',
          '+2347077777777',
          '+2347088888888',
          '+2347099999999',
          '+2347000000000',
          '+2347011112222',
        ],
        sourceIps: ['10.0.0.50'],
        callCount: 6,
        windowSeconds: 5,
        severity: 'HIGH',
        status: 'INVESTIGATING',
        assignedTo: 'John Analyst',
      ),
      Alert(
        id: 'alert-003',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        bNumber: '+2348055667788',
        aNumbers: [
          '+2347033334444',
          '+2347055556666',
          '+2347077778888',
          '+2347099990000',
          '+2347011112233',
        ],
        sourceIps: ['172.16.0.10', '172.16.0.11', '172.16.0.12'],
        callCount: 5,
        windowSeconds: 5,
        severity: 'MEDIUM',
        status: 'RESOLVED',
        notes: 'Verified as coordinated marketing campaign. Whitelisted.',
      ),
    ];
  }

  static Map<String, dynamic> _getDemoStats() {
    return {
      'totalAlerts': 127,
      'criticalAlerts': 12,
      'highAlerts': 28,
      'mediumAlerts': 54,
      'lowAlerts': 33,
      'resolvedToday': 45,
      'avgResponseTime': 2.3,
      'callsProcessed': 1247893,
      'fraudPrevented': 4521,
      'systemUptime': 99.97,
    };
  }
}
