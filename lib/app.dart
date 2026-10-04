import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'l10n/app_localizations.dart';
import 'core/theme.dart';
import 'domain/states/app_state.dart';
import 'presentation/providers/app_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/user_profile_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/edit_profile_screen.dart';
import 'presentation/screens/friends_list_screen.dart';

class StoatApp extends ConsumerStatefulWidget {
  const StoatApp({super.key});

  @override
  ConsumerState<StoatApp> createState() => _StoatAppState();
}

class _StoatAppState extends ConsumerState<StoatApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) async {
        final authRepo = ref.read(authRepositoryProvider);
        final hasToken = await authRepo.hasToken();
        final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

        if (!hasToken && !isAuthRoute) {
          return '/login';
        }
        if (hasToken && isAuthRoute) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Center(child: CircularProgressIndicator()))),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/user/:userId',
          builder: (context, state) => UserProfileScreen(userId: state.pathParameters['userId']!),
        ),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
        GoRoute(path: '/friends', builder: (_, __) => const FriendsListScreen()),
      ],
    );

    // Listen for 401 auth expiration and force redirect to login
    _listenAuthExpiration();

    // Initialize push notifications after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPushNotifications();
    });
  }

  void _listenAuthExpiration() {
    final authRepo = ref.read(authRepositoryProvider);
    authRepo.onAuthExpired.listen((_) async {
      // Unregister push token on auth expiration
      final pushService = ref.read(pushNotificationServiceProvider);
      await pushService.unregisterToken();

      await authRepo.clearSession();
      if (mounted) {
        _router.go('/login');
      }
    });
  }

  Future<void> _initPushNotifications() async {
    final pushService = ref.read(pushNotificationServiceProvider);
    await pushService.initialize();

    // Listen for notification taps to navigate
    pushService.onNotificationTap.listen((data) {
      final channelId = data['channel_id'] as String?;
      final dmUserId = data['dm_user_id'] as String?;
      if (channelId != null && mounted) {
        _router.go('/home');
        // Home screen should handle deep-linking to the specific channel
      } else if (dmUserId != null && mounted) {
        _router.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: 'Stoat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
    );
  }
}
