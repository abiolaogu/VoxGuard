import 'package:flutter/material.dart';

/// Page transition animations
class PageTransitions {
  PageTransitions._();

  /// Fade transition
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: child,
    );
  }

  /// Slide from right transition
  static Widget slideRightTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }

  /// Slide from bottom transition
  static Widget slideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: child,
    );
  }

  /// Scale transition with fade
  static Widget scaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.9,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// Shared axis horizontal transition
  static Widget sharedAxisHorizontal(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.7),
        ),
        child: child,
      ),
    );
  }
}

/// Custom page route with configurable transition
class CustomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final PageTransitionType transitionType;

  CustomPageRoute({
    required this.page,
    this.transitionType = PageTransitionType.fade,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (transitionType) {
              case PageTransitionType.fade:
                return PageTransitions.fadeTransition(
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                );
              case PageTransitionType.slideRight:
                return PageTransitions.slideRightTransition(
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                );
              case PageTransitionType.slideUp:
                return PageTransitions.slideUpTransition(
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                );
              case PageTransitionType.scale:
                return PageTransitions.scaleTransition(
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                );
            }
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}

enum PageTransitionType {
  fade,
  slideRight,
  slideUp,
  scale,
}

/// Hero animation with custom flight shuttle builder
class HeroAnimation {
  HeroAnimation._();

  /// Custom flight shuttle for smooth hero transitions
  static Widget flightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final hero = flightDirection == HeroFlightDirection.push
        ? toHeroContext.widget as Hero
        : fromHeroContext.widget as Hero;

    return Material(
      type: MaterialType.transparency,
      child: hero.child,
    );
  }

  /// Hero with default configuration
  static Widget hero({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: flightShuttleBuilder,
      transitionOnUserGestures: true,
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

/// Staggered animation helper
class StaggeredAnimation {
  final int index;
  final int totalItems;
  final Duration baseDuration;
  final Duration staggerDelay;

  StaggeredAnimation({
    required this.index,
    required this.totalItems,
    this.baseDuration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 50),
  });

  Duration get delay => staggerDelay * index;
  Duration get duration => baseDuration;

  /// Get interval for Tween animation
  Interval get interval {
    final start = index / (totalItems + 2);
    final end = (index + 2) / (totalItems + 2);
    return Interval(start.clamp(0, 1), end.clamp(0, 1), curve: Curves.easeOutCubic);
  }
}
