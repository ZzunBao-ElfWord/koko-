import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../data/models/channel.dart';
import '../../data/models/message.dart';
import '../../data/models/attachment.dart';
import '../../domain/states/app_state.dart';
import '../../domain/services/websocket_service.dart';
import '../providers/app_provider.dart';
import '../widgets/message_bubble.dart';
import 'search_screen.dart';
import '../../l10n/app_localizations.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Channel channel;

  const ChatScreen({super.key, required this.channel});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _oldestMessageId;
  bool _isOffline = false;

  // Reply state
  String? _replyingToId;
  Message? _replyingToMessage;

  // Edit state
  String? _editingMessageId;
  String? _editingOriginalContent;

  // Upload state
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Pending file for combined text + file send
  String? _pendingFileName;
  Uint8List? _pendingFileBytes;
  String? _pendingFileMimeType;

  // WebSocket stream subscriptions (must be cancelled on dispose)
  StreamSubscription? _newMessageSub;
  StreamSubscription? _reactionSub;
  StreamSubscription? _userSub;
  StreamSubscription? _messageUpdateSub;
  StreamSubscription? _messageDeleteSub;
  StreamSubscription? _connectionSub;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupWebSocketListener();
    _setupNetworkListener();
  }

  void _setupNetworkListener() {
    final ws = ref.read(webSocketServiceProvider);
    _connectionSub?.cancel();
    _connectionSub = ws.connectionChanges.listen((isConnected) {
      if (!mounted) return;
      final wasOffline = _isOffline;
      setState(() => _isOffline = !isConnected);

      // Show snackbar when coming back online
      if (wasOffline && isConnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.backOnline),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    });
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channel.id != widget.channel.id) {
      _replyingToId = null;
      _replyingToMessage = null;
      _cancelEdit();
      _loadMessages();
    }
  }

  void _setupWebSocketListener() {
    final ws = ref.read(webSocketServiceProvider);
    _newMessageSub?.cancel();
    _newMessageSub = ws.newMessages.listen((message) {
      if (message.channel == widget.channel.id && mounted) {
        setState(() {});
        _scrollToBottom();
      }
    });
    _reactionSub?.cancel();
    _reactionSub = ws.reactionUpdates.listen((event) {
      if (event.channelId == widget.channel.id && mounted) {
        setState(() {});
      }
    });
    _userSub?.cancel();
    _userSub = ws.userUpdates.listen((user) {
      ref.read(usersCacheProvider.notifier).update((state) {
        return {...state, user.id: user};
      });
    });
    _messageUpdateSub?.cancel();
    _messageUpdateSub = ws.messageUpdates.listen((event) {
      if (!mounted) return;
      final updatedId = event['id'] as String?;
      final newContent = event['content'] as String?;
      final editedTime = event['edited'] as String?;
      if (updatedId == null) return;
      final current = ref.read(channelMessagesProvider);
      final idx = current.indexWhere((m) => m.id == updatedId);
      if (idx >= 0) {
        final updated = current[idx].copyWith(
          content: newContent ?? current[idx].content,
          edited: editedTime,
        );
        final newList = List<Message>.from(current);
        newList[idx] = updated;
        ref.read(channelMessagesProvider.notifier).state = newList;
      }
    });
    _messageDeleteSub?.cancel();
    _messageDeleteSub = ws.messageDeletes.listen((deletedId) {
      if (!mounted) return;
      final current = ref.read(channelMessagesProvider);
      ref.read(channelMessagesProvider.notifier).state =
          current.where((m) => m.id != deletedId).toList();
    });
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(messageRepositoryProvider);
      final cached = await repo.getCachedMessages(widget.channel.id);
      if (cached.isNotEmpty) {
        ref.read(channelMessagesProvider.notifier).state = cached;
      }
      final messages = await repo.fetchMessages(widget.channel.id);
      if (mounted) {
        ref.read(channelMessagesProvider.notifier).state = messages;
        if (messages.isNotEmpty) {
          _oldestMessageId = messages.first.id;
        }
      }
    } catch (e) {
      // Error handled
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || _oldestMessageId == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final repo = ref.read(messageRepositoryProvider);
      final more = await repo.fetchMessages(widget.channel.id, before: _oldestMessageId);
      if (mounted && more.isNotEmpty) {
        final current = ref.read(channelMessagesProvider);
        ref.read(channelMessagesProvider.notifier).state = [...more, ...current];
        _oldestMessageId = more.first.id;
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    final hasContent = content.isNotEmpty;
    final hasPendingFile = _pendingFileBytes != null;

    // If editing, handle edit instead of send
    if (_editingMessageId != null) {
      await _submitEdit(content);
      return;
    }

    // Nothing to send
    if (!hasContent && !hasPendingFile && _replyingToId == null) return;

    final replyIds = _replyingToId != null ? [_replyingToId!] : null;
    _messageController.clear();
    _clearReply();

    List<Attachment>? attachments;

    // If there's a pending file, upload it first
    if (hasPendingFile) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      try {
        final bytes = _pendingFileBytes!;
        final filename = _pendingFileName!;
        final repo = ref.read(messageRepositoryProvider);
        final attachment = await repo.uploadAttachment(
          filename,
          bytes,
          contentType: _pendingFileMimeType,
          onSendProgress: (sent, total) {
            if (mounted && total > 0) {
              setState(() => _uploadProgress = sent / total);
            }
          },
        );
        attachments = [attachment];
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.uploadFailed}: $e')),
          );
        }
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
        return;
      } finally {
        if (mounted) {
          setState(() {
            _pendingFileName = null;
            _pendingFileBytes = null;
            _pendingFileMimeType = null;
          });
        }
      }
    }

    // Send message with content and/or attachments
    try {
      ref.read(isSendingProvider.notifier).state = true;
      final repo = ref.read(messageRepositoryProvider);
      await repo.sendMessage(
        widget.channel.id,
        content,
        replies: replyIds,
        attachments: attachments,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.failedToSend}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
        ref.read(isSendingProvider.notifier).state = false;
      }
    }
  }

  // ========== EDIT ==========

  void _startEdit(Message message) {
    setState(() {
      _editingMessageId = message.id;
      _editingOriginalContent = message.content ?? '';
      _messageController.text = message.content ?? '';
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
      _editingOriginalContent = null;
      _messageController.clear();
    });
  }

  Future<void> _submitEdit(String content) async {
    if (_editingMessageId == null) return;
    final messageId = _editingMessageId!;

    try {
      final repo = ref.read(messageRepositoryProvider);
      await repo.editMessage(widget.channel.id, messageId, content);
      _cancelEdit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.editFailed}: $e')),
        );
      }
    }
  }

  // ========== DELETE ==========

  Future<void> _deleteMessage(Message message) async {
    try {
      final repo = ref.read(messageRepositoryProvider);
      await repo.deleteMessage(widget.channel.id, message.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.deleteFailed}: $e')),
        );
      }
    }
  }

  // ========== REPLY ==========

  void _clearReply() {
    setState(() {
      _replyingToId = null;
      _replyingToMessage = null;
    });
  }

  void _setReplyTarget(Message message) {
    setState(() {
      _replyingToId = message.id;
      _replyingToMessage = message;
    });
  }

  // ========== FILE PICKER ==========

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();
      if (mounted) {
        setState(() {
          _pendingFileName = picked.name;
          _pendingFileBytes = bytes;
          _pendingFileMimeType = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.readImageFailed}: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cannotReadFile)),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _pendingFileName = file.name;
        _pendingFileBytes = file.bytes;
        _pendingFileMimeType = file.extension != null ? _mimeFromExtension(file.extension!) : null;
      });
    }
  }

  String? _mimeFromExtension(String ext) {
    final map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'webm': 'video/webm',
      'pdf': 'application/pdf',
      'txt': 'text/plain',
      'zip': 'application/zip',
    };
    return map[ext.toLowerCase()];
  }

  void _showAttachmentPicker() {
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
                leading: const Icon(Icons.image),
                title: Text(AppLocalizations.of(context)!.image),
                subtitle: Text(AppLocalizations.of(context)!.imagePickerSubtitle),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(AppLocalizations.of(context)!.file),
                subtitle: Text(AppLocalizations.of(context)!.filePickerSubtitle),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearPendingFile() {
    setState(() {
      _pendingFileName = null;
      _pendingFileBytes = null;
      _pendingFileMimeType = null;
    });
  }

  // ========== REACTIONS ==========

  Future<void> _addReaction(String messageId, String emoji) async {
    try {
      final repo = ref.read(messageRepositoryProvider);
      await repo.addReaction(widget.channel.id, messageId, emoji);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.addReactionFailed}: $e')),
        );
      }
    }
  }

  Future<void> _removeReaction(String messageId, String emoji) async {
    try {
      final repo = ref.read(messageRepositoryProvider);
      await repo.removeReaction(widget.channel.id, messageId, emoji);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.removeReactionFailed}: $e')),
        );
      }
    }
  }

  // ========== SEARCH ==========

  Future<void> _openSearch() async {
    final targetMessageId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SearchScreen(channel: widget.channel),
      ),
    );

    if (targetMessageId != null && mounted) {
      _jumpToMessage(targetMessageId);
    }
  }

  // ========== SCROLL ==========

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _jumpToMessage(String messageId) {
    final key = _messageKeys[messageId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        alignment: 0.3,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(channelMessagesProvider);
    final isSending = ref.watch(isSendingProvider);
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.id;

    // Build message lookup map for reply targets
    final messageMap = {for (final m in messages) m.id: m};

    return Column(
      children: [
        // Offline banner
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppTheme.errorColor.withOpacity(0.9),
            child: Row(
              children: [
                const Icon(Icons.cloud_off, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.offlineBanner,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        // Channel header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 0.5)),
          ),
          child: Row(
            children: [
              Icon(
                widget.channel.isDirectMessage ? Icons.person : Icons.tag,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.channel.displayName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Search button
              IconButton(
                icon: const Icon(Icons.search, size: 20),
                onPressed: _openSearch,
                tooltip: AppLocalizations.of(context)!.searchTooltip,
              ),
              _buildConnectionIndicator(),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.settings, size: 20),
                onPressed: () => context.push('/settings'),
                tooltip: AppLocalizations.of(context)!.settingsTooltip,
              ),
            ],
          ),
        ),
        // Messages list
        Expanded(
          child: _isLoading && messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification &&
                        notification.metrics.pixels <= notification.metrics.minScrollExtent + 50) {
                      _loadMoreMessages();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && _isLoadingMore) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final msgIndex = _isLoadingMore ? index - 1 : index;
                      final message = messages[msgIndex];
                      final replyTarget = message.hasReplies && message.replies!.isNotEmpty
                          ? messageMap[message.replies!.first]
                          : null;

                      final key = _messageKeys.putIfAbsent(message.id, () => GlobalKey());
                      return MessageBubble(
                        key: key,
                        message: message,
                        replyTarget: replyTarget,
                        currentUserId: currentUserId,
                        onDelete: () => _deleteMessage(message),
                        onEdit: (id) => _startEdit(message),
                        onReply: _setReplyTarget,
                        onAddReaction: _addReaction,
                        onRemoveReaction: _removeReaction,
                        onJumpToReply: _jumpToMessage,
                      );
                    },
                  ),
                ),
        ),
        // Edit preview
        if (_editingMessageId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.editing}: ${_editingOriginalContent != null && _editingOriginalContent!.length > 40 ? '${_editingOriginalContent!.substring(0, 40)}...' : _editingOriginalContent ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: _cancelEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        // Reply preview
        if (_replyingToMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.reply, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.replyingTo}: ${_replyingToMessage!.content != null && _replyingToMessage!.content!.isNotEmpty ? _replyingToMessage!.content!.length > 40 ? '${_replyingToMessage!.content!.substring(0, 40)}...' : _replyingToMessage!.content! : AppLocalizations.of(context)!.attachmentPlaceholder}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: _clearReply,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        // Pending file preview
        if (_pendingFileName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _pendingFileName!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: _clearPendingFile,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        // Upload progress
        if (_isUploading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: LinearProgressIndicator(value: _uploadProgress > 0 ? _uploadProgress : null),
          ),
        // Message input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: _isUploading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_circle_outline),
                  onPressed: _isUploading ? null : _showAttachmentPicker,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _editingMessageId != null
                          ? AppLocalizations.of(context)!.editMessageHint
                          : '${AppLocalizations.of(context)!.messageHintWithChannel}${widget.channel.displayName}',
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _isUploading ? null : _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: isSending || _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_editingMessageId != null ? Icons.check : Icons.send),
                  onPressed: (isSending || _isUploading) ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionIndicator() {
    final ws = ref.watch(webSocketServiceProvider);
    final isConnected = ws.isConnected;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isConnected ? AppTheme.successColor : AppTheme.errorColor,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  void dispose() {
    _newMessageSub?.cancel();
    _reactionSub?.cancel();
    _userSub?.cancel();
    _messageUpdateSub?.cancel();
    _messageDeleteSub?.cancel();
    _connectionSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
