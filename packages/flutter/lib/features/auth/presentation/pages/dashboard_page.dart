import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Dashboard page
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ACM Platform'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryBackground,
            child: Text('AO', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning, Abiola 👋',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your account is secure',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMiniStat('Calls Verified', '1,234'),
                      const SizedBox(width: 24),
                      _buildMiniStat('Masking Blocked', '56'),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 24),

            // Quick actions
            Text('Quick Actions', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.verified_user,
                    label: 'Verify Call',
                    color: AppColors.primary,
                    onTap: () {},
                  ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.9, 0.9)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.send,
                    label: 'Send Money',
                    color: AppColors.success,
                    onTap: () {},
                  ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.store,
                    label: 'Marketplace',
                    color: AppColors.secondary,
                    onTap: () {},
                  ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent alerts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Alerts', style: AppTypography.titleMedium),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildAlertCard(
              severity: 'HIGH',
              message: 'CLI masking detected from +234 806 XXX XXXX',
              time: '2 min ago',
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
            const SizedBox(height: 8),
            _buildAlertCard(
              severity: 'MEDIUM',
              message: 'Unusual call pattern detected on Gateway A',
              time: '15 min ago',
            ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
            const SizedBox(height: 24),

            // Recent transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Transactions', style: AppTypography.titleMedium),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTransactionCard(
              name: 'Adebayo Ogunlade',
              amount: 250000,
              status: 'Completed',
              time: '1 hour ago',
            ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1),
            const SizedBox(height: 8),
            _buildTransactionCard(
              name: 'Chioma Nwosu',
              amount: 75000,
              status: 'Processing',
              time: '3 hours ago',
            ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String severity,
    required String message,
    required String time,
  }) {
    final color = severity == 'HIGH' ? AppColors.error :
                  severity == 'MEDIUM' ? AppColors.warning : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        severity,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      time,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard({
    required String name,
    required double amount,
    required String status,
    required String time,
  }) {
    final isComplete = status == 'Completed';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryBackground,
            child: Text(name[0], style: TextStyle(color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.titleSmall),
                Text(
                  time,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatNaira(amount, decimals: 0),
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.success,
                ),
              ),
              Text(
                status,
                style: AppTypography.labelSmall.copyWith(
                  color: isComplete ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
