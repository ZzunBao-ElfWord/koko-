import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/server.dart';
import '../../data/models/channel.dart';
import '../../domain/states/app_state.dart';
import '../providers/app_provider.dart';
import '../../l10n/app_localizations.dart';
import 'server_list_screen.dart';
import 'channel_list_screen.dart';
import 'dm_list_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedServer = ref.watch(selectedServerProvider);
    final selectedChannel = ref.watch(selectedChannelProvider);

    return Scaffold(
      body: Row(
        children: [
          // Server sidebar
          const SizedBox(
            width: 72,
            child: ServerListScreen(),
          ),
          // Channel/DM sidebar
          if (selectedServer != null)
            SizedBox(
              width: 240,
              child: ChannelListScreen(server: selectedServer),
            )
          else
            const SizedBox(
              width: 240,
              child: DmListScreen(),
            ),
          // Chat area
          Expanded(
            child: selectedChannel != null
                ? ChatScreen(channel: selectedChannel)
                : _buildEmptyState(context, selectedServer != null ? AppLocalizations.of(context)!.selectChannel : AppLocalizations.of(context)!.selectConversation),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => context.push('/friends'),
        tooltip: AppLocalizations.of(context)!.friends,
        child: const Icon(Icons.people),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
