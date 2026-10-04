import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models/user.dart';
import '../../data/repositories/friends_repository.dart';
import '../providers/app_provider.dart';
import 'friend_requests_screen.dart';
import '../../l10n/app_localizations.dart';

/// Friends list screen grouped by online status.
class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  List<User> _friends = [];
  int _incomingRequestCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(friendsRepositoryProvider);
      final friends = await repo.fetchRelationships();
      final incoming = await repo.getCachedIncomingRequests();

      if (mounted) {
        setState(() {
          _friends = friends;
          _incomingRequestCount = incoming.length;
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

  Future<void> _removeFriend(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeFriendLabel),
        content: Text('${AppLocalizations.of(context)!.removeFriendConfirm} ${user.displayNameOrUsername}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(friendsRepositoryProvider);
      await repo.removeFriend(user.id);
      setState(() => _friends.removeWhere((f) => f.id == user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.friendRemoved}: ${user.displayNameOrUsername}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.deleteFailed}: $e')),
        );
      }
    }
  }

  void _openDm(User user) {
    context.push('/user/${user.id}');
  }

  Future<void> _showAddFriendDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addFriend),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.username,
            hintText: AppLocalizations.of(context)!.username,
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.send),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result.isEmpty || !mounted) return;

    try {
      final repo = ref.read(friendsRepositoryProvider);
      await repo.sendFriendRequest(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.friendRequestSent)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.failedToSend}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineFriends = _friends.where((f) => f.online == true).toList();
    final offlineFriends = _friends.where((f) => f.online != true).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.friends),
        actions: [
          if (_incomingRequestCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
                    );
                    _loadFriends();
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      '$_incomingRequestCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
                );
                _loadFriends();
              },
            ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddFriendDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFriends,
              child: ListView(
                children: [
                  if (onlineFriends.isNotEmpty) ...[
                    _buildSectionHeader('${AppLocalizations.of(context)!.onlineCount} — ${onlineFriends.length}'),
                    ...onlineFriends.map((f) => _buildFriendTile(f)),
                  ],
                  if (offlineFriends.isNotEmpty) ...[
                    _buildSectionHeader('${AppLocalizations.of(context)!.offlineCount} — ${offlineFriends.length}'),
                    ...offlineFriends.map((f) => _buildFriendTile(f)),
                  ],
                  if (_friends.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(AppLocalizations.of(context)!.noFriends, style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildFriendTile(User user) {
    final isOnline = user.online == true;
    final presence = user.status?.presence ?? 'offline';
    final presenceColor = _presenceColor(presence);

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _getAvatarColor(user.id),
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            onBackgroundImageError: (_, __) {},
            child: Text(
              _getInitials(user),
              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: presenceColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
              ),
            ),
        ],
      ),
      title: Text(user.displayNameOrUsername),
      subtitle: Text(
        user.status?.text?.isNotEmpty == true ? user.status!.text! : _presenceLabel(context, presence),
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _openDm(user),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'remove') _removeFriend(user);
          if (value == 'profile') context.push('/user/${user.id}');
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'profile', child: Text(AppLocalizations.of(context)!.viewProfile)),
          PopupMenuItem(value: 'remove', child: Text(AppLocalizations.of(context)!.removeFriendLabel, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Color _presenceColor(String presence) {
    switch (presence) {
      case 'online': return AppTheme.successColor;
      case 'idle': return Colors.orange;
      case 'busy': return AppTheme.errorColor;
      case 'invisible': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _presenceLabel(BuildContext context, String presence) {
    final l10n = AppLocalizations.of(context)!;
    switch (presence) {
      case 'online': return l10n.online;
      case 'idle': return l10n.idle;
      case 'busy': return l10n.busy;
      case 'invisible': return l10n.invisible;
      default: return l10n.offline;
    }
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
