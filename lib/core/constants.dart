import 'config/app_config.dart';

/// Core constants for the Stoat mobile app.
class AppConstants {
  AppConstants._();

  static const String appName = 'Stoat';
  static const String appVersion = '0.3.0';

  // API Configuration — sourced from compile-time --dart-define via AppConfig
  static String get apiBaseUrl => AppConfig.apiBaseUrl;
  static String get wsUrl => AppConfig.wsUrl;
  static String get autumnUrl => AppConfig.autumnUrl;
  static String get livekitUrl => AppConfig.livekitUrl;

  // Timeouts
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
  static const int wsPingIntervalSec = 30;
  static const int wsPongTimeoutSec = 10;

  // Retry
  static const int maxRetryAttempts = 10;
  static const int initialRetryDelayMs = 1000;
  static const int maxRetryDelayMs = 30000;

  // Pagination
  static const int messagesPageSize = 50;
  static const int maxMessageLength = 2000;

  // Cache
  static const int maxCacheSizeMb = 500;
  static const int messageRetentionDays = 30;
}
