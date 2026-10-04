import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/models/server.dart';
import '../../domain/states/app_state.dart';
import '../providers/app_provider.dart';
import '../widgets/server_icon.dart';

class ServerListScreen extends ConsumerStatefulWidget {
  const ServerListScreen({super.key});

  @override
  ConsumerState<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends ConsumerState<ServerListScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadServers();
  }

  Future<void> _loadServers() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(serverRepositoryProvider);
      final cached = await repo.getCachedServers();
      if (cached.isNotEmpty) {
        ref.read(serversProvider.notifier).state = cached;
      }
      final servers = await repo.fetchServers();
      if (mounted) {
        ref.read(serversProvider.notifier).state = servers;
      }
    } catch (e) {
      // Use cached
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectServer(Server? server) {
    ref.read(selectedServerProvider.notifier).state = server;
    if (server != null) {
      ref.read(selectedChannelProvider.notifier).state = null;
      ref.read(channelsProvider.notifier).state = [];
    }
  }

  void _selectDms() {
    ref.read(selectedServerProvider.notifier).state = null;
    ref.read(selectedChannelProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final servers = ref.watch(serversProvider);
    final selectedServer = ref.watch(selectedServerProvider);

    return Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // DM button
          _buildDmButton(selectedServer == null),
          const Divider(height: 16, indent: 16, endIndent: 16),
          // Servers list
          Expanded(
            child: _isLoading && servers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: servers.length,
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      return _buildServerItem(server, selectedServer?.id == server.id);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDmButton(bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: _selectDms,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.message,
            color: isSelected ? Colors.white : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildServerItem(Server server, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _selectServer(server),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
            borderRadius: BorderRadius.circular(16),
          ),
          child: ServerIcon(server: server, size: 48),
        ),
      ),
    );
  }
}
