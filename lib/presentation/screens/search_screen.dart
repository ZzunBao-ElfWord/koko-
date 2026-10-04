import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models/channel.dart';
import '../../data/models/message.dart';
import '../../domain/states/app_state.dart';
import '../providers/app_provider.dart';
import '../widgets/message_bubble.dart';
import '../../l10n/app_localizations.dart';

/// Channel message search screen.
/// Searches via server-side API and shows results with tap-to-jump.
class SearchScreen extends ConsumerStatefulWidget {
  final Channel channel;

  const SearchScreen({super.key, required this.channel});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearching = false;
  List<Message> _results = [];
  String? _error;

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _results = [];
    });

    try {
      final repo = ref.read(messageRepositoryProvider);
      final results = await repo.searchMessages(widget.channel.id, query: query);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${AppLocalizations.of(context)!.loadFailed}: $e';
          _isSearching = false;
        });
      }
    }
  }

  void _jumpToMessage(Message message) {
    // Return to chat screen with the target message ID
    context.pop(message.id);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.id;
    final usersCache = ref.watch(usersCacheProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${AppLocalizations.of(context)!.searchChannel}${widget.channel.displayName}'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchMessages,
                      filled: true,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _results = []);
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isSearching ? null : _performSearch,
                  child: _isSearching
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.search),
                ),
              ],
            ),
          ),
          // Error banner
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppTheme.errorColor.withOpacity(0.2),
              child: Text(
                _error!,
                style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          // Results
          Expanded(
            child: _results.isEmpty && !_isSearching
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? AppLocalizations.of(context)!.startSearch
                          : AppLocalizations.of(context)!.noMatchingMessages,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final message = _results[index];
                      final replyTarget = message.hasReplies && message.replies!.isNotEmpty
                          ? _results.firstWhere(
                              (m) => m.id == message.replies!.first,
                              orElse: () => message,
                            )
                          : null;
                      final cachedUser = usersCache[message.author];

                      return InkWell(
                        onTap: () => _jumpToMessage(message),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[800]?.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[800]!, width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    cachedUser?.displayNameOrUsername ?? message.author.substring(0, message.author.length > 6 ? 6 : message.author.length),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    message.createdAt != null
                                        ? '${message.createdAt!.month}/${message.createdAt!.day} ${message.createdAt!.hour.toString().padLeft(2, '0')}:${message.createdAt!.minute.toString().padLeft(2, '0')}'
                                        : '',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (message.hasContent)
                                Text(
                                  message.content!,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (message.hasAttachments)
                                Text(
                                  '[${message.attachments!.length} ${AppLocalizations.of(context)!.attachmentCount}]',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.tapToJump,
                                style: TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
