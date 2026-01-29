import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import '../animations/micro_interactions.dart';

/// Beautiful call verification status widget
class VerificationStatusWidget extends StatefulWidget {
  final VerificationState status;
  final String callerNumber;
  final String calleeNumber;
  final double? confidenceScore;
  final String? detectedMNO;
  final String? gatewayName;
  final DateTime? verifiedAt;
  final VoidCallback? onExpand;
  final VoidCallback? onReport;
  final bool showDetails;

  const VerificationStatusWidget({
    super.key,
    required this.status,
    required this.callerNumber,
    required this.calleeNumber,
    this.confidenceScore,
    this.detectedMNO,
    this.gatewayName,
    this.verifiedAt,
    this.onExpand,
    this.onReport,
    this.showDetails = false,
  });

  @override
  State<VerificationStatusWidget> createState() => _VerificationStatusWidgetState();
}

class _VerificationStatusWidgetState extends State<VerificationStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.status == VerificationState.verifying) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VerificationStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == VerificationState.verifying) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.status) {
      case VerificationState.verified:
        return AppColors.success;
      case VerificationState.masked:
        return AppColors.error;
      case VerificationState.suspicious:
        return AppColors.warning;
      case VerificationState.verifying:
        return AppColors.primary;
      case VerificationState.failed:
        return AppColors.textTertiary;
    }
  }

  IconData get _statusIcon {
    switch (widget.status) {
      case VerificationState.verified:
        return Icons.verified;
      case VerificationState.masked:
        return Icons.warning;
      case VerificationState.suspicious:
        return Icons.help_outline;
      case VerificationState.verifying:
        return Icons.sync;
      case VerificationState.failed:
        return Icons.error_outline;
    }
  }

  String get _statusLabel {
    switch (widget.status) {
      case VerificationState.verified:
        return 'Verified';
      case VerificationState.masked:
        return 'Masking Detected!';
      case VerificationState.suspicious:
        return 'Suspicious';
      case VerificationState.verifying:
        return 'Verifying...';
      case VerificationState.failed:
        return 'Verification Failed';
    }
  }

  void _toggleExpand() {
    HapticFeedback.lightImpact();
    setState(() => _isExpanded = !_isExpanded);
    widget.onExpand?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Animated status indicator
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: widget.status == VerificationState.verifying
                          ? _pulseAnimation.value
                          : 1.0,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon,
                      color: _statusColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Status text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel,
                        style: AppTypography.titleMedium.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.confidenceScore != null)
                        Row(
                          children: [
                            Text(
                              'Confidence: ',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${(widget.confidenceScore! * 100).toStringAsFixed(1)}%',
                              style: AppTypography.labelMedium.copyWith(
                                color: _statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Expand button
                IconButton(
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more),
                  ),
                  onPressed: _toggleExpand,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // Expandable details
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildDetails(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),

          // Action buttons for masked calls
          if (widget.status == VerificationState.masked)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        // Block caller
                      },
                      icon: const Icon(Icons.block, size: 18),
                      label: const Text('Block'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        widget.onReport?.call();
                      },
                      icon: const Icon(Icons.report, size: 18),
                      label: const Text('Report to NCC'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 12),

          // Phone numbers
          _buildDetailRow(
            icon: Icons.call_made,
            label: 'Caller',
            value: _formatPhone(widget.callerNumber),
            badge: widget.detectedMNO,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.call_received,
            label: 'Callee',
            value: _formatPhone(widget.calleeNumber),
          ),

          if (widget.gatewayName != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.router,
              label: 'Gateway',
              value: widget.gatewayName!,
            ),
          ],

          if (widget.verifiedAt != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              icon: Icons.access_time,
              label: 'Verified',
              value: _formatTime(widget.verifiedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    String? badge,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium,
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.getMnoColor(badge).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.getMnoColor(badge),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  String _formatPhone(String phone) {
    if (phone.length == 11) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
    }
    return phone;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }
}

/// Verification state enum
enum VerificationState {
  verifying,
  verified,
  masked,
  suspicious,
  failed,
}
