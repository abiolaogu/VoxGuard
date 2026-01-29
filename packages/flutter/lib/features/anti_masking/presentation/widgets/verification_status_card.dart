import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../domain/entities/call_verification.dart';

/// Verification status card widget
class VerificationStatusCard extends StatelessWidget {
  final CallVerification verification;
  final VoidCallback? onDismiss;
  final VoidCallback? onDetails;

  const VerificationStatusCard({
    super.key,
    required this.verification,
    this.onDismiss,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isSafe = verification.isSafe;
    final statusColor = isSafe ? AppColors.success : AppColors.error;
    final backgroundColor = isSafe ? AppColors.successBackground : AppColors.errorBackground;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSafe ? Icons.verified : Icons.warning,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSafe ? 'Call Verified' : 'Masking Detected!',
                        style: AppTypography.titleMedium.copyWith(
                          color: statusColor,
                        ),
                      ),
                      Text(
                        'Confidence: ${(verification.confidenceScore * 100).toStringAsFixed(1)}%',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.call_made,
                  label: 'Caller',
                  value: PhoneFormatter.format(verification.callerNumber),
                  mno: verification.mno,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.call_received,
                  label: 'Callee',
                  value: PhoneFormatter.format(verification.calleeNumber),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.fingerprint,
                  label: 'Original CLI',
                  value: verification.originalCli,
                ),
                if (verification.detectedCli != null &&
                    verification.detectedCli != verification.originalCli) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.warning_amber,
                    label: 'Detected CLI',
                    value: verification.detectedCli!,
                    isWarning: true,
                  ),
                ],
                if (verification.gatewayName != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: Icons.router,
                    label: 'Gateway',
                    value: verification.gatewayName!,
                  ),
                ],
              ],
            ),
          ),

          // Risk level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Risk Level: ',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(int.parse('0xFF${verification.riskLevel.color}')),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        verification.riskLevel.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (onDetails != null)
                  TextButton(
                    onPressed: onDetails,
                    child: const Text('View Details'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? mno,
    bool isWarning = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isWarning ? AppColors.error : AppColors.textTertiary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isWarning ? AppColors.error : AppColors.textPrimary,
                      fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (mno != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.getMnoColor(mno).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        mno,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.getMnoColor(mno),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
