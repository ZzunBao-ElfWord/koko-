import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models/channel.dart';
import '../../data/models/user.dart';
import '../../domain/states/app_state.dart';
import '../providers/app_provider.dart';
import 'chat_screen.dart';
import '../../l10n/app_localizations.dart';

class DmListScreen extends ConsumerStatefulWidget {
  const DmListScreen({super.key});

  @override
  ConsumerState<DmListScreen> createState() => _DmListScreenState();
}

class _DmListScreenState extends ConsumerState<DmListScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDms();
  }

  Future<void> _loadDms() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(dmRepositoryProvider);
      final cached = await repo.getCachedDms();
      if (cached.isNotEmpty) {
        ref.read(dmChannelsProvider.notifier).state = cached;
      }
      final dms = await repo.fetchUserDms();
      if (mounted) {
        ref.read(dmChannelsProvider.notifier).state = dms;
      }
    } catch (e) {
      // Use cached
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dmChannels = ref.watch(dmChannelsProvider);
    final usersCache = ref.watch(usersCacheProvider);

    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)!.directMessagesTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading && dmChannels.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : dmChannels.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.message_outlined, size: 48, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(AppLocalizations.of(context)!.noDirectMessages, style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: dmChannels.length,
                        itemBuilder: (context, index) {
                          final channel = dmChannels[index];
                          return _buildDmTile(channel, usersCache);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDmTile(Channel channel, Map<String, User> usersCache) {
    IconData icon;
    if (channel.isSavedMessages) {
      icon = Icons.bookmark;
    } else if (channel.isGroup) {
      icon = Icons.group;
    } else {
      icon = Icons.person;
    }

    // For DM channels, try to find recipient user info
    String displayTitle = channel.displayName;
    String? avatarUrl;
    if (channel.isDirectMessage && channel.recipients != null && channel.recipients!.isNotEmpty) {
      final recipientId = channel.recipients!.first;
      final user = usersCache[recipientId];
      if (user != null) {
        displayTitle = user.displayNameOrUsername;
        avatarUrl = user.avatarUrl;
      }
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: avatarUrl != null ? Colors.transparent : Colors.grey[700],
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null ? Icon(icon, size: 16) : null,
      ),
      title: Text(
        displayTitle,
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
      onTap: () {
        ref.read(selectedChannelProvider.notifier).state = channel;
        ref.read(selectedServerProvider.notifier).state = null;
      },
      trailing: channel.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: channel.mentionCount > 0 ? AppTheme.errorColor : AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${channel.unreadCount > 99 ? '99+' : channel.unreadCount}',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
