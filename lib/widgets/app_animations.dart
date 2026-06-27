import 'package:flutter/material.dart';

/// Reusable animation widgets for ShadowCV
class AppAnimations {
  AppAnimations._();

  /// Fades in a widget with an optional slide from bottom
  static Widget fadeIn({
    required AnimationController controller,
    required Widget child,
    Offset slideBegin = Offset.zero,
  }) {
    if (slideBegin == Offset.zero) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: slideBegin,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
        child: child,
      ),
    );
  }

  /// Scales a widget in with an elastic curve
  static Widget scaleIn({
    required AnimationController controller,
    required Widget child,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  /// Staggered list item entrance animation
  static Widget staggeredItem({
    required int index,
    required AnimationController controller,
    required Widget child,
  }) {
    final delay = index * 0.1;
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(delay, delay + 0.4, curve: Curves.easeOutCubic),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Convenience extension for AnimationController quick setup
extension AnimationControllerHelper on AnimationController {
  /// Forward with a slight delay, typical for entrance animations
  Future<void> forwardWithDelay([Duration delay = const Duration(milliseconds: 100)]) async {
    await Future.delayed(delay);
    forward();
  }
}
