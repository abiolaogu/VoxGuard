import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Transaction status page
class TransactionStatusPage extends StatelessWidget {
  final String transactionId;

  const TransactionStatusPage({
    super.key,
    required this.transactionId,
  });

  @override
  Widget build(BuildContext context) {
    // Mock transaction data
    final isComplete = true;
    final amount = 250000.0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Success/Progress icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.successBackground
                      : AppColors.primaryBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isComplete ? Icons.check_circle : Icons.schedule,
                  size: 64,
                  color: isComplete ? AppColors.success : AppColors.primary,
                ),
              )
                  .animate()
                  .scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),

              // Status text
              Text(
                isComplete ? 'Transfer Complete!' : 'Processing...',
                style: AppTypography.headlineMedium,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                isComplete
                    ? 'Your money has been sent successfully'
                    : 'Your transfer is being processed',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),

              // Amount
              Text(
                CurrencyFormatter.formatNaira(amount),
                style: AppTypography.currencyLarge.copyWith(
                  color: AppColors.success,
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
              const SizedBox(height: 8),
              Text(
                'sent to Adebayo Ogunlade',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 500.ms),

              const Spacer(),

              // Transaction details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Transaction ID', transactionId.substring(0, 8).toUpperCase()),
                    const SizedBox(height: 8),
                    _buildDetailRow('Date', 'Jan 29, 2026 04:25 AM'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Status', isComplete ? 'Completed' : 'Processing'),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Share receipt
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
