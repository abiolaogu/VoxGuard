import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../models/user.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final isAdmin = auth.user?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Notifications Section
          _SectionHeader(title: 'Notifications'),
          Card(
            child: Column(
              children: [
                _SettingSwitch(
                  title: 'Push Notifications',
                  subtitle: 'Receive alert notifications',
                  value: settings.notificationsEnabled,
                  onChanged: settings.setNotificationsEnabled,
                ),
                const Divider(height: 1),
                _SettingSwitch(
                  title: 'Critical Alerts Only',
                  subtitle: 'Only notify for critical severity',
                  value: settings.criticalAlertsOnly,
                  onChanged: settings.setCriticalAlertsOnly,
                ),
                const Divider(height: 1),
                _SettingSwitch(
                  title: 'Sound',
                  subtitle: 'Play sound for notifications',
                  value: settings.soundEnabled,
                  onChanged: settings.setSoundEnabled,
                ),
                const Divider(height: 1),
                _SettingSwitch(
                  title: 'Vibration',
                  subtitle: 'Vibrate for notifications',
                  value: settings.vibrationEnabled,
                  onChanged: settings.setVibrationEnabled,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App Settings Section
          _SectionHeader(title: 'App Settings'),
          Card(
            child: Column(
              children: [
                _SettingTile(
                  title: 'Refresh Interval',
                  subtitle: 'Every ${settings.refreshInterval} seconds',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRefreshIntervalPicker(context, settings),
                ),
                if (isAdmin) ...[
                  const Divider(height: 1),
                  _SettingTile(
                    title: 'API URL',
                    subtitle: settings.apiUrl,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showApiUrlDialog(context, settings),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account Section
          _SectionHeader(title: 'Account'),
          Card(
            child: Column(
              children: [
                _SettingTile(
                  title: 'Profile',
                  subtitle: auth.user?.email ?? '',
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      auth.user?.initials ?? 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/profile'),
                ),
                const Divider(height: 1),
                _SettingTile(
                  title: 'Role',
                  subtitle: auth.user?.role.name.toUpperCase() ?? 'Unknown',
                  leading: const Icon(Icons.badge, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          _SectionHeader(title: 'About'),
          Card(
            child: Column(
              children: [
                _SettingTile(
                  title: 'Version',
                  subtitle: '1.0.0',
                  leading: const Icon(Icons.info_outline, color: Color(0xFF64748B)),
                ),
                const Divider(height: 1),
                _SettingTile(
                  title: 'Privacy Policy',
                  leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF64748B)),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () {
                    // Open privacy policy
                  },
                ),
                const Divider(height: 1),
                _SettingTile(
                  title: 'Terms of Service',
                  leading: const Icon(Icons.description_outlined, color: Color(0xFF64748B)),
                  trailing: const Icon(Icons.open_in_new, size: 20),
                  onTap: () {
                    // Open terms
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout
          Card(
            child: _SettingTile(
              title: 'Sign Out',
              leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              titleColor: const Color(0xFFEF4444),
              onTap: () => _showLogoutDialog(context, auth),
            ),
          ),

          const SizedBox(height: 32),

          // Reset Settings
          Center(
            child: TextButton(
              onPressed: () => _showResetDialog(context, settings),
              child: Text(
                'Reset to Default Settings',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRefreshIntervalPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Refresh Interval',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...[15, 30, 60, 120, 300].map((seconds) => ListTile(
                  title: Text('$seconds seconds'),
                  trailing: settings.refreshInterval == seconds
                      ? const Icon(Icons.check, color: Color(0xFF2563EB))
                      : null,
                  onTap: () {
                    settings.setRefreshInterval(seconds);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showApiUrlDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.apiUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://localhost:5001',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setApiUrl(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              auth.logout();
              Navigator.pop(context);
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF2563EB),
    );
  }
}
