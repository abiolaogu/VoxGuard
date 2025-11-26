import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/alerts_provider.dart';
import '../models/alert.dart';
import '../theme/app_theme.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _selectedSeverity = 'ALL';
  String _selectedStatus = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AlertsProvider>().fetchAlerts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by B-number, A-number, or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Severity filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedSeverity == 'ALL',
                  onTap: () => setState(() => _selectedSeverity = 'ALL'),
                ),
                _FilterChip(
                  label: 'Critical',
                  isSelected: _selectedSeverity == 'CRITICAL',
                  color: const Color(0xFFEF4444),
                  onTap: () => setState(() => _selectedSeverity = 'CRITICAL'),
                ),
                _FilterChip(
                  label: 'High',
                  isSelected: _selectedSeverity == 'HIGH',
                  color: const Color(0xFFF97316),
                  onTap: () => setState(() => _selectedSeverity = 'HIGH'),
                ),
                _FilterChip(
                  label: 'Medium',
                  isSelected: _selectedSeverity == 'MEDIUM',
                  color: const Color(0xFFEAB308),
                  onTap: () => setState(() => _selectedSeverity = 'MEDIUM'),
                ),
                _FilterChip(
                  label: 'Low',
                  isSelected: _selectedSeverity == 'LOW',
                  color: const Color(0xFF22C55E),
                  onTap: () => setState(() => _selectedSeverity = 'LOW'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Alerts list
          Expanded(
            child: Consumer<AlertsProvider>(
              builder: (context, alerts, _) {
                if (alerts.isLoading && alerts.alerts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredAlerts = _filterAlerts(alerts.alerts);

                if (filteredAlerts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No alerts found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => alerts.fetchAlerts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = filteredAlerts[index];
                      return _AlertListItem(
                        alert: alert,
                        onTap: () => context.go('/alerts/${alert.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Alert> _filterAlerts(List<Alert> alerts) {
    return alerts.where((alert) {
      // Severity filter
      if (_selectedSeverity != 'ALL' && alert.severity != _selectedSeverity) {
        return false;
      }

      // Status filter
      if (_selectedStatus != 'ALL' && alert.status != _selectedStatus) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return alert.bNumber.toLowerCase().contains(query) ||
            alert.aNumbers.any((a) => a.toLowerCase().contains(query)) ||
            alert.id.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Alerts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['ALL', 'NEW', 'INVESTIGATING', 'RESOLVED', 'FALSE_POSITIVE']
                  .map((status) => ChoiceChip(
                        label: Text(status),
                        selected: _selectedStatus == status,
                        onSelected: (selected) {
                          setState(() => _selectedStatus = status);
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedSeverity = 'ALL';
                    _selectedStatus = 'ALL';
                    _searchQuery = '';
                  });
                  Navigator.pop(context);
                },
                child: const Text('Reset Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: chipColor.withOpacity(0.2),
        checkmarkColor: chipColor,
        labelStyle: TextStyle(
          color: isSelected ? chipColor : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _AlertListItem extends StatelessWidget {
  final Alert alert;
  final VoidCallback onTap;

  const _AlertListItem({
    required this.alert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.getSeverityColor(alert.severity);
    final statusColor = AppTheme.getStatusColor(alert.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: severityColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      alert.severity,
                      style: TextStyle(
                        color: severityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      alert.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeago.format(alert.timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'B-Number: ${alert.bNumber}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${alert.callCount} calls from ${alert.aNumbers.length} A-numbers',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
