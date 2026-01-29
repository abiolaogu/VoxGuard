import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/app_theme.dart';

/// Glassmorphism card with frosted glass effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? tintColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Border? border;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.2,
    this.tintColor,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = tintColor ?? (isDark ? Colors.white : Colors.white);

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? _buildGradientBorder(isDark),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }

  Border _buildGradientBorder(bool isDark) {
    return Border.all(
      color: (isDark ? Colors.white : Colors.white).withOpacity(0.2),
      width: 1.5,
    );
  }
}

/// Glass card with gradient border
class GlassCardGradient extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final List<Color> gradientColors;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassCardGradient({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.15,
    this.gradientColors = const [Color(0xFF1890FF), Color(0xFF722ED1)],
    this.borderWidth = 2,
    this.borderRadius = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: BorderRadius.circular(borderRadius - borderWidth),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted surface for overlays
class FrostedSurface extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color tintColor;
  final double tintOpacity;

  const FrostedSurface({
    super.key,
    required this.child,
    this.blur = 20,
    this.tintColor = Colors.white,
    this.tintOpacity = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          color: tintColor.withOpacity(tintOpacity),
          child: child,
        ),
      ),
    );
  }
}

/// Gradient header card
class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;

  const GradientCard({
    super.key,
    required this.child,
    this.gradientColors,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.borderRadius = 16,
    this.padding,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? [
      AppColors.primary,
      AppColors.primary.withBlue(200),
    ];

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: gradientBegin,
          end: gradientEnd,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? AppTheme.shadowColored(colors.first),
      ),
      child: child,
    );
  }
}

/// Neumorphic card (soft UI)
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool isPressed;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.backgroundColor,
    this.isPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.surface;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  offset: const Offset(-4, -4),
                  blurRadius: 8,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(4, 4),
                  blurRadius: 8,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Elevated card with hover effect
class HoverCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double hoverElevation;

  const HoverCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.hoverElevation = 8,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          padding: widget.padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppColors.surface,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: _isHovered
                ? AppTheme.shadowLg
                : AppTheme.shadowSm,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
