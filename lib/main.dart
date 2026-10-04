import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/locale_settings.dart';
import 'domain/states/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore the user's persisted language choice; default to Chinese
  // (also when the system language is English and nothing was saved).
  final savedLocale = await LocaleSettings.load();

  runApp(
    ProviderScope(
      overrides: [
        appLocaleProvider.overrideWith((ref) => savedLocale ?? const Locale('zh')),
      ],
      child: const StoatApp(),
    ),
  );
}
