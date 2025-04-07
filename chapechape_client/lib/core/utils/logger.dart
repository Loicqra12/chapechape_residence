import 'package:logging/logging.dart' as logging;

class AppLogger {
  final logging.Logger _logger;

  AppLogger(String name) : _logger = logging.Logger(name) {
    _initializeLogging();
  }

  static void _initializeLogging() {
    logging.hierarchicalLoggingEnabled = true;
    logging.Logger.root.level = logging.Level.ALL;
    logging.Logger.root.onRecord.listen((record) {
      // En mode debug, on affiche les logs dans la console
      print('${record.time}: ${record.level.name}: ${record.loggerName}: ${record.message}');
      if (record.error != null) {
        print('Error: ${record.error}');
        if (record.stackTrace != null) {
          print('Stack trace:\n${record.stackTrace}');
        }
      }
    });
  }

  void info(String message) {
    _logger.info(message);
  }

  void warning(String message) {
    _logger.warning(message);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }

  void debug(String message) {
    _logger.fine(message);
  }
} 