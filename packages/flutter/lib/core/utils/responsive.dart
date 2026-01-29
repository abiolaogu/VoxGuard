import 'package:flutter/material.dart';

/// Responsive layout utilities
class Responsive {
  Responsive._();

  // Breakpoints
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;
  static const double wideBreakpoint = 1440;

  /// Check device type
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  static bool isWide(BuildContext context) {
    return MediaQuery.of(context).size.width >= wideBreakpoint;
  }

  /// Get device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < tabletBreakpoint) return DeviceType.mobile;
    if (width < desktopBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Get responsive value based on breakpoint
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  /// Get responsive padding
  static EdgeInsets padding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: value(context, mobile: 16, tablet: 24, desktop: 32),
      vertical: value(context, mobile: 16, tablet: 20, desktop: 24),
    );
  }

  /// Get content max width
  static double maxWidth(BuildContext context) {
    return value(context, mobile: double.infinity, tablet: 720, desktop: 1200);
  }

  /// Get grid column count
  static int gridColumns(BuildContext context) {
    return value(context, mobile: 2, tablet: 3, desktop: 4);
  }
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  })  : mobile = null,
        tablet = null,
        desktop = null;

  const ResponsiveBuilder.custom({
    super.key,
    required Widget this.mobile,
    this.tablet,
    this.desktop,
  }) : builder = _defaultBuilder;

  static Widget _defaultBuilder(BuildContext context, DeviceType deviceType) {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);

    if (mobile != null) {
      switch (deviceType) {
        case DeviceType.desktop:
          return desktop ?? tablet ?? mobile!;
        case DeviceType.tablet:
          return tablet ?? mobile!;
        case DeviceType.mobile:
          return mobile!;
      }
    }

    return builder(context, deviceType);
  }
}

/// Responsive layout with centered content
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool centered;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Apply max width
    final effectiveMaxWidth = maxWidth ?? Responsive.maxWidth(context);
    if (effectiveMaxWidth != double.infinity) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: content,
      );
    }

    // Center content
    if (centered) {
      content = Center(child: content);
    }

    // Apply padding
    final effectivePadding = padding ?? Responsive.padding(context);
    content = Padding(
      padding: effectivePadding,
      child: content,
    );

    return content;
  }
}

/// Responsive grid
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double? runSpacing;
  final int? columns;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing,
    this.columns,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final columnCount = columns ?? Responsive.gridColumns(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        mainAxisSpacing: runSpacing ?? spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: childAspectRatio ?? 1,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Screen size aware container
class ScreenAwareContainer extends StatelessWidget {
  final Widget child;
  final double minHeight;
  final bool fillHeight;

  const ScreenAwareContainer({
    super.key,
    required this.child,
    this.minHeight = 0,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaPadding = MediaQuery.of(context).padding;
    final availableHeight = screenHeight - safeAreaPadding.top - safeAreaPadding.bottom;

    if (fillHeight) {
      return SizedBox(
        height: availableHeight,
        child: child,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight > 0 ? minHeight : availableHeight * 0.5,
      ),
      child: child,
    );
  }
}

/// Adaptive padding that adjusts to screen size
class AdaptivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? mobilePadding;
  final EdgeInsetsGeometry? tabletPadding;
  final EdgeInsetsGeometry? desktopPadding;

  const AdaptivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.value<EdgeInsetsGeometry>(
      context,
      mobile: mobilePadding ?? const EdgeInsets.all(16),
      tablet: tabletPadding ?? const EdgeInsets.all(24),
      desktop: desktopPadding ?? const EdgeInsets.all(32),
    );

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Hide on certain breakpoints
class HideOn extends StatelessWidget {
  final Widget child;
  final bool mobile;
  final bool tablet;
  final bool desktop;
  final Widget? replacement;

  const HideOn({
    super.key,
    required this.child,
    this.mobile = false,
    this.tablet = false,
    this.desktop = false,
    this.replacement,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);

    bool shouldHide = false;
    switch (deviceType) {
      case DeviceType.mobile:
        shouldHide = mobile;
        break;
      case DeviceType.tablet:
        shouldHide = tablet;
        break;
      case DeviceType.desktop:
        shouldHide = desktop;
        break;
    }

    if (shouldHide) {
      return replacement ?? const SizedBox.shrink();
    }

    return child;
  }
}
