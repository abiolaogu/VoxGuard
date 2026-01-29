import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/animations/micro_interactions.dart';

/// In-app notification overlay
class InAppNotification extends StatefulWidget {
  final String title;
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool showIcon;

  const InAppNotification({
    super.key,
    required this.title,
    required this.message,
    this.type = NotificationType.info,
    this.duration = const Duration(seconds: 4),
    this.onTap,
    this.onDismiss,
    this.showIcon = true,
  });

  @override
  State<InAppNotification> createState() => _InAppNotificationState();
}

class _InAppNotificationState extends State<InAppNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Haptic feedback for alerts
    if (widget.type == NotificationType.alert ||
        widget.type == NotificationType.masking) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  Color get _backgroundColor {
    switch (widget.type) {
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.alert:
        return AppColors.error;
      case NotificationType.masking:
        return AppColors.maskingAlert;
      case NotificationType.info:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.alert:
        return Icons.error;
      case NotificationType.masking:
        return Icons.security;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity!.abs() > 200) {
              _dismiss();
            }
          },
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _backgroundColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.showIcon) ...[
                  _buildIcon(),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.message,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: _dismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (widget.type == NotificationType.masking) {
      return PulseAnimation(
        duration: const Duration(milliseconds: 800),
        minScale: 0.9,
        maxScale: 1.1,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon, color: Colors.white, size: 24),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(_icon, color: Colors.white, size: 24),
    );
  }
}

enum NotificationType {
  success,
  warning,
  alert,
  masking, // Special type for call masking alerts
  info,
}

/// Notification overlay manager
class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({
    super.key,
    required this.child,
  });

  static NotificationOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<NotificationOverlayState>();
  }

  @override
  State<NotificationOverlay> createState() => NotificationOverlayState();
}

class NotificationOverlayState extends State<NotificationOverlay> {
  final List<_NotificationEntry> _notifications = [];

  void showNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    setState(() {
      _notifications.add(_NotificationEntry(
        id: id,
        title: title,
        message: message,
        type: type,
        duration: duration,
        onTap: onTap,
      ));
    });
  }

  void showMaskingAlert({
    required String callerNumber,
    String? detectedCli,
    VoidCallback? onTap,
  }) {
    showNotification(
      title: '⚠️ Call Masking Detected!',
      message: 'Suspicious activity from $callerNumber',
      type: NotificationType.masking,
      duration: const Duration(seconds: 8),
      onTap: onTap,
    );
  }

  void _removeNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: Column(
            children: _notifications.map((entry) {
              return InAppNotification(
                key: ValueKey(entry.id),
                title: entry.title,
                message: entry.message,
                type: entry.type,
                duration: entry.duration,
                onTap: entry.onTap,
                onDismiss: () => _removeNotification(entry.id),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _NotificationEntry {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final Duration duration;
  final VoidCallback? onTap;

  _NotificationEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.duration,
    this.onTap,
  });
}

/// Masking alert banner (for persistent display)
class MaskingAlertBanner extends StatefulWidget {
  final String callerNumber;
  final String? originalCli;
  final String? detectedCli;
  final double? confidenceScore;
  final VoidCallback? onReport;
  final VoidCallback? onDismiss;

  const MaskingAlertBanner({
    super.key,
    required this.callerNumber,
    this.originalCli,
    this.detectedCli,
    this.confidenceScore,
    this.onReport,
    this.onDismiss,
  });

  @override
  State<MaskingAlertBanner> createState() => _MaskingAlertBannerState();
}

class _MaskingAlertBannerState extends State<MaskingAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Heavy haptic for masking alert
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error,
            AppColors.error.withRed(200),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with pulsing icon
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLI MASKING DETECTED',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'This call shows signs of fraud',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onDismiss,
                  ),
              ],
            ),
          ),

          // Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                _buildDetailRow('Caller', widget.callerNumber),
                if (widget.originalCli != null)
                  _buildDetailRow('Original CLI', widget.originalCli!),
                if (widget.detectedCli != null)
                  _buildDetailRow('Detected CLI', widget.detectedCli!),
                if (widget.confidenceScore != null)
                  _buildDetailRow(
                    'Confidence',
                    '${(widget.confidenceScore! * 100).toStringAsFixed(1)}%',
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('Block'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onReport,
                        icon: const Icon(Icons.report, size: 18),
                        label: const Text('Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
