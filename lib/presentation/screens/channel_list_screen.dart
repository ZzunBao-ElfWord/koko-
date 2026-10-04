import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/models/server.dart';
import '../../data/models/channel.dart';
import '../../domain/states/app_state.dart';
import '../../domain/states/voice_state.dart';
import '../providers/app_provider.dart';
import 'voice_room_screen.dart';

class ChannelListScreen extends ConsumerStatefulWidget {
  final Server server;

  const ChannelListScreen({super.key, required this.server});

  @override
  ConsumerState<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends ConsumerState<ChannelListScreen> {
  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    try {
      final repo = ref.read(serverRepositoryProvider);
      final cached = await repo.getCachedChannels(widget.server.id);
      if (cached.isNotEmpty) {
        ref.read(channelsProvider.notifier).state = cached;
      }
      final channels = await repo.fetchChannels(widget.server.id);
      if (mounted) {
        ref.read(channelsProvider.notifier).state = channels;
      }
    } catch (e) {
      // Use cached
    }
  }

  void _onChannelTap(Channel channel) {
    if (channel.isVoice) {
      // Navigate to voice room
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VoiceRoomScreen(channel: channel),
        ),
      );
    } else {
      // Select text channel
      ref.read(selectedChannelProvider.notifier).state = channel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(channelsProvider);
    final selectedChannel = ref.watch(selectedChannelProvider);
    final voiceState = ref.watch(voiceRoomProvider);

    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      child: Column(
        children: [
          // Server header
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.server.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          // Channels list
          Expanded(
            child: ListView.builder(
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                return _buildChannelTile(
                  channel,
                  selectedChannel?.id == channel.id,
                  voiceState,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTile(Channel channel, bool isSelected, VoiceRoomState voiceState) {
    IconData icon;
    if (channel.isText) {
      icon = Icons.tag;
    } else if (channel.isVoice) {
      icon = Icons.mic;
    } else {
      icon = Icons.chat_bubble_outline;
    }

    // For voice channels, show participant count if connected to this channel
    final isInVoiceRoom = voiceState.isConnected && voiceState.roomId == channel.id;
    final voiceCount = isInVoiceRoom ? voiceState.participantCount : null;

    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: isSelected && channel.isText ? AppTheme.primaryColor : Colors.grey,
      ),
      title: Text(
        channel.displayName,
        style: TextStyle(
          color: isSelected && channel.isText ? AppTheme.primaryColor : null,
          fontWeight: isSelected && channel.isText ? FontWeight.bold : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      selected: isSelected && channel.isText,
      dense: true,
      onTap: () => _onChannelTap(channel),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (channel.isVoice && voiceCount != null && voiceCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person, size: 10, color: Colors.green),
                  const SizedBox(width: 2),
                  Text(
                    '$voiceCount',
                    style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          if (channel.isVoice && isInVoiceRoom)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.circle, size: 8, color: Colors.green),
            ),
          if (channel.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: channel.mentionCount > 0 ? AppTheme.errorColor : AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${channel.unreadCount > 99 ? '99+' : channel.unreadCount}',
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
