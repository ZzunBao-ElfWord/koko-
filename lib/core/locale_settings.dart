import 'dart:ui';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the user's language selection across app restarts.
///
/// Stored via [FlutterSecureStorage] (same mechanism as the auth session),
/// key `app_locale` with value `zh` or `en`. Absence of a stored value means
/// the user never chose a language and the app falls back to Chinese.
class LocaleSettings {
  static const String _key = 'app_locale';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Returns the saved locale, or `null` when nothing valid is stored.
  static Future<Locale?> load() async {
    try {
      final value = await _storage.read(key: _key);
      if (value == 'zh') return const Locale('zh');
      if (value == 'en') return const Locale('en');
    } catch (_) {
      // Storage unavailable: fall back to the default locale.
    }
    return null;
  }

  /// Persists [locale] as the user's language choice.
  static Future<void> save(Locale locale) async {
    try {
      await _storage.write(key: _key, value: locale.languageCode);
    } catch (_) {
      // Best-effort persistence; ignore storage failures.
    }
  }
}
