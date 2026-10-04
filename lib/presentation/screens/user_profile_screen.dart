import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models/server.dart';
import '../../data/models/user.dart';
import '../../domain/states/app_state.dart';
import '../providers/app_provider.dart';
import '../../l10n/app_localizations.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  User? _user;
  List<Server> _mutualServers = [];
  bool _isLoading = false;
  bool _isCreatingDm = false;
  bool _isMutualServersLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final usersCache = ref.read(usersCacheProvider);
      if (usersCache.containsKey(widget.userId)) {
        setState(() => _user = usersCache[widget.userId]);
      }

      final api = ref.read(apiClientProvider);
      final data = await api.fetchUser(widget.userId);
      final user = User.fromJson(data);

      ref.read(usersCacheProvider.notifier).update((state) {
        return {...state, user.id: user};
      });

      if (mounted) setState(() => _user = user);

      // Load mutual servers
      _loadMutualServers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.loadFailed}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMutualServers() async {
    setState(() => _isMutualServersLoading = true);
    try {
      final repo = ref.read(friendsRepositoryProvider);
      final servers = await repo.fetchMutualServers(widget.userId);
      if (mounted) {
        setState(() => _mutualServers = servers);
      }
    } catch (_) {
      // Mutual servers optional
    } finally {
      if (mounted) setState(() => _isMutualServersLoading = false);
    }
  }

  Future<void> _openDm() async {
    setState(() => _isCreatingDm = true);
    try {
      final dmRepo = ref.read(dmRepositoryProvider);
      final channel = await dmRepo.openDm(widget.userId);

      if (mounted) {
        ref.read(selectedServerProvider.notifier).state = null;
        ref.read(selectedChannelProvider.notifier).state = channel;
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingDm = false);
    }
  }

  bool get _isSelf {
    final currentUser = ref.read(currentUserProvider);
    return currentUser?.id == widget.userId;
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final presence = user?.status?.presence ?? 'offline';
    final presenceColor = _presenceColor(presence);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile),
        actions: [
          if (_isSelf)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/edit-profile'),
              tooltip: AppLocalizations.of(context)!.editProfile,
            ),
        ],
      ),
      body: _isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? Center(child: Text(AppLocalizations.of(context)!.userNotFound))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      _buildAvatar(user),
                      const SizedBox(height: 16),
                      Text(
                        user.displayNameOrUsername,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 8),
                      // Presence badge
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: presenceColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _presenceLabel(context, presence),
                            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Status text
                      if (user.status?.text != null && user.status!.text!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.status!.text!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Action buttons
                      if (!_isSelf)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isCreatingDm ? null : _openDm,
                            icon: _isCreatingDm
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.message),
                            label: Text(_isCreatingDm ? AppLocalizations.of(context)!.opening : AppLocalizations.of(context)!.sendMessage),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Mutual servers
                      if (_mutualServers.isNotEmpty || _isMutualServersLoading) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context)!.mutualServers,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[400]),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isMutualServersLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          ..._mutualServers.map((s) => ListTile(
                            leading: const Icon(Icons.dns, size: 20),
                            title: Text(s.name),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          )),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildAvatar(User user) {
    final avatarUrl = user.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: _getAvatarColor(user.id),
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 48,
      backgroundColor: _getAvatarColor(user.id),
      child: Text(
        user.displayNameOrUsername.substring(0, 1).toUpperCase(),
        style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
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

  Color _getAvatarColor(String authorId) {
    final colors = [
      Colors.red, Colors.green, Colors.blue, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
    ];
    return colors[authorId.hashCode.abs() % colors.length];
  }
}
