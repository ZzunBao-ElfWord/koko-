import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../domain/states/app_state.dart';
import '../../domain/services/push_notification_service.dart';
import '../providers/app_provider.dart';
import '../../l10n/app_localizations.dart';

/// Settings screen with notification preferences, language switcher and app info.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pushService = ref.read(pushNotificationServiceProvider);
    setState(() {
      _notificationsEnabled = pushService.notificationsEnabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool enabled) async {
    final pushService = ref.read(pushNotificationServiceProvider);

    if (enabled) {
      final granted = await pushService.requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.notificationDenied)),
          );
        }
        return;
      }
    }

    await pushService.setNotificationsEnabled(enabled);
    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logoutTitle),
        content: Text(AppLocalizations.of(context)!.logoutContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.logout, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Unregister push token before logout
      final pushService = ref.read(pushNotificationServiceProvider);
      await pushService.unregisterToken();

      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.clearSession();

      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _showLanguagePicker() {
    final currentLocale = ref.read(appLocaleProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context)!.languageSystem),
                trailing: currentLocale == null ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  ref.read(appLocaleProvider.notifier).state = null;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context)!.languageZh),
                trailing: currentLocale?.languageCode == 'zh' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  ref.read(appLocaleProvider.notifier).state = const Locale('zh');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context)!.languageEn),
                trailing: currentLocale?.languageCode == 'en' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  ref.read(appLocaleProvider.notifier).state = const Locale('en');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageLabel() {
    final locale = ref.watch(appLocaleProvider);
    if (locale == null) return AppLocalizations.of(context)!.languageSystem;
    if (locale.languageCode == 'zh') return AppLocalizations.of(context)!.languageZh;
    return AppLocalizations.of(context)!.languageEn;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Account section
                _buildSectionHeader(AppLocalizations.of(context)!.account),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(AppLocalizations.of(context)!.profile),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/edit-profile'),
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: Text(AppLocalizations.of(context)!.friends),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/friends'),
                ),
                const Divider(),

                // Notifications section
                _buildSectionHeader(AppLocalizations.of(context)!.notifications),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.enableNotifications),
                  subtitle: Text(AppLocalizations.of(context)!.notificationSubtitle),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  secondary: Icon(
                    _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                    color: _notificationsEnabled ? AppTheme.primaryColor : Colors.grey,
                  ),
                ),
                const Divider(),

                // Language section
                _buildSectionHeader(AppLocalizations.of(context)!.language),
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(AppLocalizations.of(context)!.language),
                  subtitle: Text(_getLanguageLabel()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showLanguagePicker,
                ),
                const Divider(),

                // Voice section
                _buildSectionHeader(AppLocalizations.of(context)!.voice),
                ListTile(
                  leading: const Icon(Icons.mic),
                  title: Text(AppLocalizations.of(context)!.microphonePermission),
                  subtitle: Text(AppLocalizations.of(context)!.microphonePermissionDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Open system app settings
                  },
                ),
                const Divider(),

                // About section
                _buildSectionHeader(AppLocalizations.of(context)!.about),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(AppLocalizations.of(context)!.version),
                  subtitle: const Text('Stoat Mobile v0.3.0 (M3)'),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(AppLocalizations.of(context)!.server),
                  subtitle: Text(AppConstants.apiBaseUrl),
                ),
                const Divider(),

                // Logout
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: Text(AppLocalizations.of(context)!.logout),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }
}
