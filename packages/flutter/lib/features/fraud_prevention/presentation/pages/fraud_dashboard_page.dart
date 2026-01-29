// Fraud Prevention Dashboard Page
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fraud_prevention_provider.dart';
import '../widgets/fraud_summary_card.dart';
import '../widgets/risk_score_indicator.dart';

class FraudDashboardPage extends ConsumerWidget {
  const FraudDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(fraudSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fraud Prevention'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(fraudSummaryProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(fraudSummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Section
              Text(
                'Fraud Summary',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              summaryAsync.when(
                data: (summary) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FraudSummaryCard(
                            title: 'CLI Spoofing',
                            count: summary.cliSpoofingCount,
                            icon: Icons.security,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FraudSummaryCard(
                            title: 'IRSF',
                            count: summary.irsfCount,
                            icon: Icons.language,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FraudSummaryCard(
                            title: 'Wangiri',
                            count: summary.wangiriCount,
                            icon: Icons.phone_missed,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FraudSummaryCard(
                            title: 'Callback',
                            count: summary.callbackFraudCount,
                            icon: Icons.phone_callback,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Revenue Protected
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 40,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Revenue Protected',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    '₦${summary.totalRevenueProtected.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              _buildActionTile(
                context,
                icon: Icons.security,
                title: 'CLI Verifications',
                subtitle: 'View spoofing detections',
                onTap: () => Navigator.pushNamed(context, '/fraud/cli'),
              ),
              _buildActionTile(
                context,
                icon: Icons.language,
                title: 'IRSF Incidents',
                subtitle: 'International revenue share fraud',
                onTap: () => Navigator.pushNamed(context, '/fraud/irsf'),
              ),
              _buildActionTile(
                context,
                icon: Icons.phone_missed,
                title: 'Wangiri Detection',
                subtitle: 'One-ring fraud tracking',
                onTap: () => Navigator.pushNamed(context, '/fraud/wangiri'),
              ),
              _buildActionTile(
                context,
                icon: Icons.block,
                title: 'Blocked Numbers',
                subtitle: 'Manage blacklist',
                onTap: () => Navigator.pushNamed(context, '/fraud/blacklist'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
