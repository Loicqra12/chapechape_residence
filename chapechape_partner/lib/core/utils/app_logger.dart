import 'package:flutter/foundation.dart';

/// Logs Partner — silencieux en release (store).
class AppLogger {
  AppLogger._();

  static void d(Object? message, [Object? error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    if (error != null) {
      debugPrint('$message\n$error');
      if (stackTrace != null) debugPrint('$stackTrace');
    } else {
      debugPrint('$message');
    }
  }

  static void i(Object? message) {
    if (!kDebugMode) return;
    debugPrint('INFO: $message');
  }

  static void w(Object? message, [Object? error]) {
    if (!kDebugMode) return;
    debugPrint('WARN: $message');
    if (error != null) debugPrint('$error');
  }

  static void e(Object? message, [Object? error, StackTrace? stackTrace]) {
    // Erreurs : debugPrint en debug uniquement (évite fuite en release)
    if (!kDebugMode) return;
    debugPrint('ERROR: $message');
    if (error != null) debugPrint('$error');
    if (stackTrace != null) debugPrint('$stackTrace');
  }
}
