/// LONE LINK — Structured Logger
///
/// Application-wide logging with levels, categories, and privacy controls.
/// Wraps the `logger` package with domain-specific conventions.
///
/// SECURITY: Never log private keys, plaintext message content,
/// or sensitive user data at any log level.
library;

import 'package:logger/logger.dart' as pkg;

/// Log categories for filtering.
enum LogCategory {
  ble,
  internet,
  routing,
  security,
  storage,
  sync,
  protocol,
  bridge,
  message,
  ui,
  lifecycle,
  general,
}

/// A single log entry stored for the diagnostics screen.
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final LogCategory category;
  final String message;
  final String? detail;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.detail,
  });
}

/// Log levels matching the spec requirements.
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Application logger that stores recent entries for diagnostics viewing.
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;

  AppLogger._internal();

  final pkg.Logger _logger = pkg.Logger(
    printer: pkg.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: pkg.DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: pkg.Level.debug,
  );

  /// In-memory log buffer for diagnostics screen.
  /// Capped at [_maxEntries] to prevent memory growth.
  final List<LogEntry> _entries = [];
  static const int _maxEntries = 1000;

  /// Get all log entries (for diagnostics screen).
  List<LogEntry> get entries => List.unmodifiable(_entries);

  /// Get entries filtered by category.
  List<LogEntry> entriesByCategory(LogCategory category) =>
      _entries.where((e) => e.category == category).toList();

  /// Get entries filtered by level (and above).
  List<LogEntry> entriesByLevel(LogLevel minLevel) =>
      _entries.where((e) => e.level.index >= minLevel.index).toList();

  /// Clear all stored log entries.
  void clear() => _entries.clear();

  void _addEntry(LogLevel level, LogCategory category, String message, [String? detail]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      detail: detail,
    );
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
  }

  // ─── Public Logging Methods ───

  void debug(LogCategory category, String message, [String? detail]) {
    _addEntry(LogLevel.debug, category, message, detail);
    _logger.d('[$category] $message${detail != null ? '\n$detail' : ''}');
  }

  void info(LogCategory category, String message, [String? detail]) {
    _addEntry(LogLevel.info, category, message, detail);
    _logger.i('[$category] $message${detail != null ? '\n$detail' : ''}');
  }

  void warning(LogCategory category, String message, [String? detail]) {
    _addEntry(LogLevel.warning, category, message, detail);
    _logger.w('[$category] $message${detail != null ? '\n$detail' : ''}');
  }

  void error(LogCategory category, String message, [Object? error, StackTrace? stackTrace]) {
    _addEntry(LogLevel.error, category, message, error?.toString());
    _logger.e('[$category] $message', error: error, stackTrace: stackTrace);
  }
}

/// Global logger instance.
final log = AppLogger();
