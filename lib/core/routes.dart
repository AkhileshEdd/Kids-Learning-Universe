import 'package:flutter/material.dart';

/// Bouncy zoom + fade transition used between screens.
class ZoomRoute<T> extends PageRouteBuilder<T> {
  ZoomRoute(Widget page)
      : super(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.6)),
              child: ScaleTransition(scale: Tween(begin: 0.86, end: 1.0).animate(curved), child: child),
            );
          },
        );
}

Future<T?> pushScreen<T>(BuildContext context, Widget page) => Navigator.of(context).push<T>(ZoomRoute<T>(page));

Future<T?> replaceScreen<T>(BuildContext context, Widget page) =>
    Navigator.of(context).pushReplacement<T, void>(ZoomRoute<T>(page));

/// Clears the stack and shows [page].
void resetTo(BuildContext context, Widget page) =>
    Navigator.of(context).pushAndRemoveUntil(ZoomRoute<void>(page), (_) => false);
