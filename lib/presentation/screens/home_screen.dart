import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/channel.dart';
import '../../data/models/server.dart';
import '../../domain/states/app_state.dart';
import '../providers/app_provider.dart';
import '../../l10n/app_localizations.dart';
import 'server_list_screen.dart';
import 'channel_list_screen.dart';
import 'dm_list_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  StreamSubscription? _serverSub;
  StreamSubscription? _channelSub;
  StreamSubscription? _userSub;
  bool _realtimeBootstrapped = false;

  @override
  void initState() {
    super.initState();
    _bootstrapRealtime();
  }

  /// Connect the WebSocket after login and wire its event streams into the
  /// app-level providers. The backend (Revolt 0.15.5) has no REST endpoint to
  /// list a user's servers, so the server list / channel list primarily come
  /// from the WebSocket `Ready` payload (cached via LocalDatabase and emitted
  /// through WebSocketService streams).
  Future<void> _bootstrapRealtime() async {
    if (_realtimeBootstrapped) return;
    _realtimeBootstrapped = true;

    final authRepo = ref.read(authRepositoryProvider);
    final token = await authRepo.getToken();
    if (token == null || token.isEmpty) return;

    final ws = ref.read(webSocketServiceProvider);
    if (!ws.isConnected) {
      try {
        await ws.connect(token);
      } catch (_) {
        // WS will retry internally; REST cached data still renders.
      }
    }

    _serverSub = ws.serverUpdates.listen((server) {
      final current = List<Server>.from(ref.read(serversProvider));
      final idx = current.indexWhere((s) => s.id == server.id);
      if (idx >= 0) {
        current[idx] = server;
      } else {
        current.add(server);
      }
      ref.read(serversProvider.notifier).state = current;
    });

    _channelSub = ws.channelUpdates.listen((channel) {
      final current = List<Channel>.from(ref.read(channelsProvider));
      final idx = current.indexWhere((c) => c.id == channel.id);
      if (idx >= 0) {
        current[idx] = channel;
      } else {
        current.add(channel);
      }
      ref.read(channelsProvider.notifier).state = current;
    });

    _userSub = ws.userUpdates.listen((user) {
      ref.read(usersCacheProvider.notifier).update((state) {
        return {...state, user.id: user};
      });
    });
  }

  @override
  void dispose() {
    _serverSub?.cancel();
    _channelSub?.cancel();
    _userSub?.cancel();
    ref.read(webSocketServiceProvider).disconnect();
    super.dispose();
  }

  void _closeChat() {
    ref.read(selectedChannelProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final selectedServer = ref.watch(selectedServerProvider);
    final selectedChannel = ref.watch(selectedChannelProvider);
    final isWide = MediaQuery.of(context).size.width >= 840;

    final serverRail = const SizedBox(width: 72, child: ServerListScreen());
    final listPane = selectedServer != null
        ? ChannelListScreen(
            key: ValueKey('channels-${selectedServer.id}'),
            server: selectedServer,
          )
        : const DmListScreen();

    Widget body;
    if (isWide) {
      // Desktop / tablet: three-pane layout.
      body = Row(
        children: [
          serverRail,
          SizedBox(width: 240, child: listPane),
          Expanded(
            child: selectedChannel != null
                ? ChatScreen(channel: selectedChannel)
                : _buildEmptyState(
                    context,
                    selectedServer != null
                        ? AppLocalizations.of(context)!.selectChannel
                        : AppLocalizations.of(context)!.selectConversation,
                  ),
          ),
        ],
      );
    } else if (selectedChannel != null) {
      // Phone: chat fills the screen, with a back button to return to lists.
      body = ChatScreen(channel: selectedChannel);
    } else {
      // Phone: server rail + channel/DM list.
      body = Row(
        children: [
          serverRail,
          Expanded(child: listPane),
        ],
      );
    }

    return Scaffold(
      appBar: !isWide && selectedChannel != null
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _closeChat,
              ),
              title: Text(
                selectedChannel.displayName,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
      body: body,
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
