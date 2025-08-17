// FILE: lib/utils/safe_navigation_helper.dart
// Helper class to handle safe navigation operations

import 'package:flutter/material.dart';

class SafeNavigationHelper {
  /// Safely pop the navigator if it can pop
  static bool safePop(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return true;
    }
    return false;
  }

  /// Safely push a route
  static Future<T?> safePush<T extends Object?>(
    BuildContext context,
    Route<T> route,
  ) async {
    try {
      return await Navigator.push(context, route);
    } catch (e) {
      debugPrint('Navigation push failed: $e');
      return null;
    }
  }

  /// Safely push named route
  static Future<T?> safePushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    try {
      return await Navigator.pushNamed(
        context,
        routeName,
        arguments: arguments,
      );
    } catch (e) {
      debugPrint('Named navigation failed: $e');
      return null;
    }
  }

  /// Safely replace current route
  static Future<T?> safePushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Route<T> newRoute, {
    TO? result,
  }) async {
    try {
      return await Navigator.pushReplacement(
        context,
        newRoute,
        result: result,
      );
    } catch (e) {
      debugPrint('Navigation replacement failed: $e');
      return null;
    }
  }

  /// Safely pop until a specific route
  static void safePopUntil(
    BuildContext context,
    RoutePredicate predicate,
  ) {
    try {
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, predicate);
      }
    } catch (e) {
      debugPrint('PopUntil failed: $e');
    }
  }

  /// Check if navigator can perform operations
  static bool canNavigate(BuildContext context) {
    try {
      final navigator = Navigator.maybeOf(context);
      return navigator != null;
    } catch (e) {
      debugPrint('Navigator check failed: $e');
      return false;
    }
  }

  /// Safe navigation with GlobalKey
  static bool safeNavigateWithKey<T extends Object?>(
    GlobalKey<NavigatorState> navigatorKey,
    String routeName, {
    Object? arguments,
  }) {
    try {
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamed(routeName, arguments: arguments);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Key navigation failed: $e');
      return false;
    }
  }

  /// Safe pop with GlobalKey
  static bool safePopWithKey(GlobalKey<NavigatorState> navigatorKey) {
    try {
      final navigator = navigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Key pop failed: $e');
      return false;
    }
  }
}

/// Extension on BuildContext for easier navigation
extension SafeNavigationExtension on BuildContext {
  /// Safely navigate to a route
  Future<T?> safePushRoute<T extends Object?>(Route<T> route) {
    return SafeNavigationHelper.safePush(this, route);
  }

  /// Safely navigate to named route
  Future<T?> safePushNamedRoute<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return SafeNavigationHelper.safePushNamed(
      this,
      routeName,
      arguments: arguments,
    );
  }

  /// Safely pop current route
  bool safePopRoute() {
    return SafeNavigationHelper.safePop(this);
  }

  /// Check if navigation is possible
  bool get canNavigate => SafeNavigationHelper.canNavigate(this);
}
