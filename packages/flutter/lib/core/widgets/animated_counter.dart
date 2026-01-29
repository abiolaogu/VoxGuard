import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';

/// Animated counter that counts up to a target value
class AnimatedCounter extends StatefulWidget {
  final double value;
  final String? prefix;
  final String? suffix;
  final Duration duration;
  final TextStyle? style;
  final bool compact;
  final int decimals;
  final Color? color;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix,
    this.suffix,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.compact = false,
    this.decimals = 0,
    this.color,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    if (widget.compact) {
      return _formatCompact(value);
    }

    final formatter = NumberFormat.decimalPattern();
    if (widget.decimals > 0) {
      return value.toStringAsFixed(widget.decimals);
    }
    return formatter.format(value.round());
  }

  String _formatCompact(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(widget.decimals);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final formattedValue = _formatValue(_animation.value);
        final displayText = '${widget.prefix ?? ''}$formattedValue${widget.suffix ?? ''}';

        return Text(
          displayText,
          style: (widget.style ?? AppTypography.headlineLarge).copyWith(
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// Animated Naira counter
class AnimatedNairaCounter extends StatelessWidget {
  final double value;
  final Duration duration;
  final TextStyle? style;
  final bool compact;
  final int decimals;
  final Color? color;

  const AnimatedNairaCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.compact = false,
    this.decimals = 0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCounter(
      value: value,
      prefix: '₦',
      duration: duration,
      style: style,
      compact: compact,
      decimals: decimals,
      color: color ?? AppColors.nairaGreen,
    );
  }
}

/// Stat counter with label and trend indicator
class StatCounter extends StatelessWidget {
  final String label;
  final double value;
  final String? prefix;
  final String? suffix;
  final double? previousValue;
  final IconData? icon;
  final Color? iconColor;
  final bool compact;
  final CrossAxisAlignment alignment;

  const StatCounter({
    super.key,
    required this.label,
    required this.value,
    this.prefix,
    this.suffix,
    this.previousValue,
    this.icon,
    this.iconColor,
    this.compact = false,
    this.alignment = CrossAxisAlignment.start,
  });

  double? get _percentChange {
    if (previousValue == null || previousValue == 0) return null;
    return ((value - previousValue!) / previousValue!) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final trend = _percentChange;
    final isPositive = trend != null && trend > 0;
    final isNegative = trend != null && trend < 0;

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label with icon
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: iconColor ?? AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Value
        AnimatedCounter(
          value: value,
          prefix: prefix,
          suffix: suffix,
          compact: compact,
          style: AppTypography.headlineMedium,
        ),

        // Trend indicator
        if (trend != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up
                    : isNegative
                        ? Icons.trending_down
                        : Icons.trending_flat,
                size: 14,
                color: isPositive
                    ? AppColors.success
                    : isNegative
                        ? AppColors.error
                        : AppColors.textTertiary,
              ),
              const SizedBox(width: 2),
              Text(
                '${trend.abs().toStringAsFixed(1)}%',
                style: AppTypography.labelSmall.copyWith(
                  color: isPositive
                      ? AppColors.success
                      : isNegative
                          ? AppColors.error
                          : AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Percentage ring with animated fill
class PercentageRing extends StatefulWidget {
  final double percentage;
  final double size;
  final double strokeWidth;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Widget? child;
  final Duration duration;

  const PercentageRing({
    super.key,
    required this.percentage,
    this.size = 80,
    this.strokeWidth = 8,
    this.foregroundColor,
    this.backgroundColor,
    this.child,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<PercentageRing> createState() => _PercentageRingState();
}

class _PercentageRingState extends State<PercentageRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.percentage,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(PercentageRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.percentage,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  percentage: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  foregroundColor: widget.foregroundColor ?? AppColors.primary,
                  backgroundColor: widget.backgroundColor ?? AppColors.border,
                ),
              ),
              if (widget.child != null) widget.child!,
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percentage;
  final double strokeWidth;
  final Color foregroundColor;
  final Color backgroundColor;

  _RingPainter({
    required this.percentage,
    required this.strokeWidth,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground ring
    final fgPaint = Paint()
      ..color = foregroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
