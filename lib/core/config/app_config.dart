/// Compile-time app configuration via --dart-define.
///
/// Default domain: openelfai.cn (production backend)
/// To switch to kokokongkong.com, build with:
///   --dart-define=API_BASE_URL=https://kokokongkong.com
///
/// Example build commands:
///   # Production domain (default, no extra flags needed)
///   flutter build apk --release
///
///   # Alternate domain (transition / fallback)
///   flutter build apk --release --dart-define=API_BASE_URL=https://kokokongkong.com
class AppConfig {
  AppConfig._();

  /// Base domain for all API services.
  /// Override with --dart-define=API_BASE_URL=<url>
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://openelfai.cn',
  );

  /// WebSocket endpoint derived from base URL.
  /// Converts https:// → wss:// and http:// → ws://
  static String get wsUrl {
    final base = apiBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$base/ws';
  }

  /// Autumn file service endpoint derived from base URL.
  static String get autumnUrl => '$apiBaseUrl/autumn';

  /// LiveKit SFU endpoint derived from base URL.
  /// Converts https:// → wss:// and http:// → ws://
  static String get livekitUrl {
    final base = apiBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    return '$base/livekit';
  }
}
