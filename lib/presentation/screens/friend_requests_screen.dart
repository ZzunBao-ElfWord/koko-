import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/models/user.dart';
import '../providers/app_provider.dart';
import '../../l10n/app_localizations.dart';

/// Friend requests screen (incoming + outgoing).
class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  List<User> _incoming = [];
  List<User> _outgoing = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(friendsRepositoryProvider);
      final incoming = await repo.getCachedIncomingRequests();
      final outgoing = await repo.getCachedOutgoingRequests();

      if (mounted) {
        setState(() {
          _incoming = incoming;
          _outgoing = outgoing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.loadFailed}: $e')),
        );
      }
    }
  }

  Future<void> _accept(User user) async {
    try {
      final repo = ref.read(friendsRepositoryProvider);
      await repo.acceptFriendRequest(user.id);
      setState(() => _incoming.removeWhere((u) => u.id == user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.accept}: ${user.displayNameOrUsername}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  Future<void> _reject(User user) async {
    try {
      final repo = ref.read(friendsRepositoryProvider);
      await repo.removeFriend(user.id);
      setState(() => _incoming.removeWhere((u) => u.id == user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.rejectSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  Future<void> _cancelOutgoing(User user) async {
    try {
      final repo = ref.read(friendsRepositoryProvider);
      await repo.removeFriend(user.id);
      setState(() => _outgoing.removeWhere((u) => u.id == user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.requestCancelled)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.friendRequests),
          bottom: TabBar(
            tabs: [
              Tab(text: '${AppLocalizations.of(context)!.incoming} (${_incoming.length})'),
              Tab(text: '${AppLocalizations.of(context)!.outgoing} (${_outgoing.length})'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildIncomingList(),
                  _buildOutgoingList(),
                ],
              ),
      ),
    );
  }

  Widget _buildIncomingList() {
    if (_incoming.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.noIncomingRequests, style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _incoming.length,
      itemBuilder: (context, index) {
        final user = _incoming[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: _getAvatarColor(user.id),
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            onBackgroundImageError: (_, __) {},
            child: Text(
              _getInitials(user),
              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(user.displayNameOrUsername),
          subtitle: Text('@${user.username}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => _accept(user),
                style: TextButton.styleFrom(foregroundColor: AppTheme.successColor),
                child: Text(AppLocalizations.of(context)!.accept),
              ),
              TextButton(
                onPressed: () => _reject(user),
                style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                child: Text(AppLocalizations.of(context)!.reject),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOutgoingList() {
    if (_outgoing.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.outbox, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.noOutgoingRequests, style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _outgoing.length,
      itemBuilder: (context, index) {
        final user = _outgoing[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: _getAvatarColor(user.id),
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            onBackgroundImageError: (_, __) {},
            child: Text(
              _getInitials(user),
              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(user.displayNameOrUsername),
          subtitle: Text(AppLocalizations.of(context)!.waitingForConfirm, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          trailing: TextButton(
            onPressed: () => _cancelOutgoing(user),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text(AppLocalizations.of(context)!.cancelRequest),
          ),
        );
      },
    );
  }

  String _getInitials(User user) {
    return user.displayNameOrUsername.substring(0, 1).toUpperCase();
  }

  Color _getAvatarColor(String id) {
    final colors = [
      Colors.red, Colors.green, Colors.blue, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
    ];
    return colors[id.hashCode.abs() % colors.length];
  }
}
