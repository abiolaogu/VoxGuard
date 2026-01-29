import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for screen readers and A11y compliance
class A11y {
  A11y._();

  /// Make a widget accessible with label and hint
  static Widget semantic({
    required Widget child,
    required String label,
    String? hint,
    bool? button,
    bool? header,
    bool? link,
    bool? selected,
    bool? enabled,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      header: header,
      link: link,
      selected: selected,
      enabled: enabled ?? true,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }

  /// Exclude from semantics (for decorative elements)
  static Widget excludeSemantics({required Widget child}) {
    return ExcludeSemantics(child: child);
  }

  /// Merge child semantics into single node
  static Widget mergeSemantics({
    required Widget child,
    String? label,
  }) {
    return MergeSemantics(
      child: label != null
          ? Semantics(label: label, child: child)
          : child,
    );
  }

  /// Announce message to screen reader
  static void announce(String message, {TextDirection? textDirection}) {
    SemanticsService.announce(message, textDirection ?? TextDirection.ltr);
  }

  /// Ensure minimum touch target size (48x48 for accessibility)
  static Widget ensureTouchTarget({
    required Widget child,
    double minSize = 48,
  }) {
    return SizedBox(
      width: minSize,
      height: minSize,
      child: Center(child: child),
    );
  }
}

/// Large text scaling support
class LargeTextScaler extends StatelessWidget {
  final Widget child;
  final double maxScale;

  const LargeTextScaler({
    super.key,
    required this.child,
    this.maxScale = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final scale = mediaQuery.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: maxScale,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: scale),
      child: child,
    );
  }
}

/// Focus traversal utilities
class FocusHelper {
  FocusHelper._();

  /// Create a focus traversal group
  static Widget group({
    required Widget child,
    FocusTraversalPolicy? policy,
  }) {
    return FocusTraversalGroup(
      policy: policy ?? ReadingOrderTraversalPolicy(),
      child: child,
    );
  }

  /// Skip focus for decorative widgets
  static Widget skipFocus({required Widget child}) {
    return ExcludeFocus(child: child);
  }

  /// Request focus programmatically
  static void requestFocus(FocusNode node) {
    node.requestFocus();
  }

  /// Unfocus current element
  static void unfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

/// Color contrast checker
class ContrastChecker {
  ContrastChecker._();

  /// Check if contrast ratio meets WCAG requirements
  static bool meetsWCAG(Color foreground, Color background, {bool largeText = false}) {
    final ratio = _getContrastRatio(foreground, background);
    final threshold = largeText ? 3.0 : 4.5;
    return ratio >= threshold;
  }

  /// Check if contrast ratio meets WCAG AAA
  static bool meetsWCAGAAA(Color foreground, Color background, {bool largeText = false}) {
    final ratio = _getContrastRatio(foreground, background);
    final threshold = largeText ? 4.5 : 7.0;
    return ratio >= threshold;
  }

  static double _getContrastRatio(Color foreground, Color background) {
    final l1 = foreground.computeLuminance();
    final l2 = background.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }
}

/// Reduce motion preference support
class ReducedMotion {
  ReducedMotion._();

  /// Check if reduced motion is preferred
  static bool isEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get appropriate duration based on motion preference
  static Duration getDuration(
    BuildContext context, {
    Duration normal = const Duration(milliseconds: 300),
    Duration reduced = Duration.zero,
  }) {
    return isEnabled(context) ? reduced : normal;
  }

  /// Build widget conditionally based on motion preference
  static Widget builder(
    BuildContext context, {
    required Widget Function(bool reduced) builder,
  }) {
    return builder(isEnabled(context));
  }
}

/// Accessible button with all required properties
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final String? hint;
  final VoidCallback? onPressed;
  final bool enabled;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.hint,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: hint,
      button: true,
      enabled: enabled,
      child: A11y.ensureTouchTarget(
        child: GestureDetector(
          onTap: enabled ? onPressed : null,
          child: child,
        ),
      ),
    );
  }
}

/// Accessible icon with label
class AccessibleIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? size;
  final Color? color;

  const AccessibleIcon({
    super.key,
    required this.icon,
    required this.label,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Icon(
        icon,
        size: size,
        color: color,
        semanticLabel: label,
      ),
    );
  }
}
