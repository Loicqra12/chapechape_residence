import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service de journalisation pour l'application
/// Permet de logger des messages avec différents niveaux de sévérité
class LoggerService {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  /// Enregistre un message d'information
  void info(String message) {
    _logger.i(message);
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }

  /// Enregistre un message d'erreur
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) print(error);
      if (stackTrace != null) print(stackTrace);
    }
  }

  /// Enregistre un message de débogage
  void debug(String message) {
    _logger.d(message);
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }

  /// Enregistre un message d'avertissement
  void warning(String message) {
    _logger.w(message);
    if (kDebugMode) {
      print('[WARNING] $message');
    }
  }

  /// Enregistre un message critique
  void critical(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.wtf(message, error: error, stackTrace: stackTrace);
    if (kDebugMode) {
      print('[CRITICAL] $message');
      if (error != null) print(error);
      if (stackTrace != null) print(stackTrace);
    }
  }
} 