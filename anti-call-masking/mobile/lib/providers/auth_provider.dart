import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Demo users for all roles
  final Map<String, User> _demoUsers = {
    'admin@acm.com': User(
      id: '1',
      name: 'System Admin',
      email: 'admin@acm.com',
      role: UserRole.admin,
      permissions: ['all'],
    ),
    'analyst@acm.com': User(
      id: '2',
      name: 'SOC Analyst',
      email: 'analyst@acm.com',
      role: UserRole.analyst,
      permissions: [
        'view_alerts',
        'manage_alerts',
        'view_analytics',
        'generate_reports'
      ],
    ),
    'developer@acm.com': User(
      id: '3',
      name: 'API Developer',
      email: 'developer@acm.com',
      role: UserRole.developer,
      permissions: ['view_api_docs', 'manage_api_keys', 'view_analytics'],
    ),
    'viewer@acm.com': User(
      id: '4',
      name: 'Executive Viewer',
      email: 'viewer@acm.com',
      role: UserRole.viewer,
      permissions: ['view_dashboard', 'view_analytics'],
    ),
  };

  AuthProvider() {
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    const storage = FlutterSecureStorage();
    final email = await storage.read(key: 'user_email');
    if (email != null && _demoUsers.containsKey(email)) {
      _user = _demoUsers[email];
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Demo authentication
      await Future.delayed(const Duration(milliseconds: 500));

      final normalizedEmail = email.toLowerCase();
      if (_demoUsers.containsKey(normalizedEmail) && password == 'demo123') {
        _user = _demoUsers[normalizedEmail];

        // Save to secure storage
        const storage = FlutterSecureStorage();
        await storage.write(key: 'user_email', value: normalizedEmail);

        // Generate demo token
        final token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
        await ApiService.setToken(token);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An error occurred. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _error = null;

    const storage = FlutterSecureStorage();
    await storage.delete(key: 'user_email');
    await ApiService.clearToken();

    notifyListeners();
  }

  bool hasPermission(String permission) {
    return _user?.hasPermission(permission) ?? false;
  }

  bool hasRole(List<UserRole> roles) {
    return _user?.hasRole(roles) ?? false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
