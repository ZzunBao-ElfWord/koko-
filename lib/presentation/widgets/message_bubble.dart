import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';
import '../../data/models/attachment.dart';
import '../../domain/states/app_state.dart';
import 'emoji_picker.dart';
import 'fullscreen_image_viewer.dart';
import 'fullscreen_video_player.dart';
import '../../l10n/app_localizations.dart';

class MessageBubble extends ConsumerStatefulWidget {
  final Message message;
  final VoidCallback? onDelete;
  final Function(String)? onEdit;
  final Function(String)? onReply;
  final Function(String, String)? onAddReaction;
  final Function(String, String)? onRemoveReaction;
  final String? currentUserId;
  final Message? replyTarget;
  final Function(String)? onJumpToReply;

  const MessageBubble({
    super.key,
    required this.message,
    this.onDelete,
    this.onEdit,
    this.onReply,
    this.onAddReaction,
    this.onRemoveReaction,
    this.currentUserId,
    this.replyTarget,
    this.onJumpToReply,
  });

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  bool _showActions = false;
  bool _isDownloading = false;

  void _showRetryOptions() {
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
                leading: const Icon(Icons.refresh, color: AppTheme.primaryColor),
                title: Text(AppLocalizations.of(context)!.retrySend),
                onTap: () {
                  Navigator.pop(context);
                  // Retry logic: re-send the message content
                  widget.onEdit?.call(widget.message.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                title: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EmojiPicker(
        onEmojiSelected: (emoji) {
          widget.onAddReaction?.call(widget.message.id, emoji);
        },
      ),
    );
  }

  void _showMessageMenu() {
    final isOwnMessage = widget.message.author == widget.currentUserId;

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
                leading: const Icon(Icons.reply),
                title: Text(AppLocalizations.of(context)!.messageMenuReply),
                onTap: () {
                  Navigator.pop(context);
                  widget.onReply?.call(widget.message.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_reaction),
                title: Text(AppLocalizations.of(context)!.messageMenuAddReaction),
                onTap: () {
                  Navigator.pop(context);
                  _showEmojiPicker();
                },
              ),
              if (isOwnMessage)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: Text(AppLocalizations.of(context)!.messageMenuEdit),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onEdit?.call(widget.message.id);
                  },
                ),
              if (isOwnMessage)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                  title: Text(AppLocalizations.of(context)!.messageMenuDelete, style: const TextStyle(color: AppTheme.errorColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMessageTitle),
        content: Text(AppLocalizations.of(context)!.deleteMessageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.message.isPending;
    final isFailed = widget.message.isFailed;
    final createdAt = widget.message.createdAt;

    final usersCache = ref.watch(usersCacheProvider);
    final cachedUser = usersCache[widget.message.author];

    return GestureDetector(
      onLongPress: _showMessageMenu,
      onTap: () => setState(() => _showActions = !_showActions),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(cachedUser, widget.message.author),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author and timestamp
                  Row(
                    children: [
                      Text(
                        _getAuthorName(cachedUser, widget.message.author),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        createdAt != null ? _formatTime(createdAt) : '',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      if (widget.message.isEdited)
                        Text(
                          ' (${AppLocalizations.of(context)!.edited})',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Reply reference
                  if (widget.replyTarget != null)
                    _buildReplyReference(widget.replyTarget!),
                  // Message content
                  if (widget.message.hasContent)
                    Opacity(
                      opacity: isPending ? 0.6 : 1.0,
                      child: MarkdownBody(
                        data: widget.message.content!,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 14),
                          code: TextStyle(
                            backgroundColor: Colors.grey[800],
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            // Handle link tap
                          }
                        },
                      ),
                    ),
                  if (isPending)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.sending,
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  if (isFailed)
                    GestureDetector(
                      onTap: _showRetryOptions,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 12, color: AppTheme.errorColor),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.sendFailedRetry,
                              style: TextStyle(fontSize: 11, color: AppTheme.errorColor, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Attachments
                  if (widget.message.hasAttachments)
                    _buildAttachments(widget.message.attachments!),
                  // Reactions
                  if (widget.message.hasReactions)
                    _buildReactions(widget.message.reactions!),
                  // Quick action bar
                  if (_showActions)
                    _buildQuickActions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyReference(Message target) {
    final usersCache = ref.watch(usersCacheProvider);
    final targetUser = usersCache[target.author];
    final authorName = targetUser?.displayNameOrUsername ?? target.author.substring(0, target.author.length > 6 ? 6 : target.author.length);
    final preview = target.content != null && target.content!.isNotEmpty
        ? target.content!.length > 50 ? '${target.content!.substring(0, 50)}...' : target.content!
        : target.hasAttachments ? AppLocalizations.of(context)!.attachmentPlaceholder : AppLocalizations.of(context)!.noContent;

    final child = Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: const Border(
          left: BorderSide(color: Colors.grey, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            authorName,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Text(
            preview,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (widget.onJumpToReply != null) {
      return GestureDetector(
        onTap: () => widget.onJumpToReply!(target.id),
        child: child,
      );
    }
    return child;
  }

  Widget _buildQuickActions() {
    final isOwnMessage = widget.message.author == widget.currentUserId;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: [
          _ActionChip(
            icon: Icons.reply,
            label: AppLocalizations.of(context)!.messageMenuReply,
            onTap: () => widget.onReply?.call(widget.message.id),
          ),
          _ActionChip(
            icon: Icons.add_reaction,
            label: AppLocalizations.of(context)!.addReaction,
            onTap: _showEmojiPicker,
          ),
          if (isOwnMessage)
            _ActionChip(
              icon: Icons.edit,
              label: AppLocalizations.of(context)!.messageMenuEdit,
              onTap: () => widget.onEdit?.call(widget.message.id),
            ),
          if (isOwnMessage)
            _ActionChip(
              icon: Icons.delete,
              label: AppLocalizations.of(context)!.messageMenuDelete,
              onTap: _confirmDelete,
              color: AppTheme.errorColor,
            ),
        ],
      ),
    );
  }

  Widget _buildReactions(Map<String, Reaction> reactions) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactions.entries.map((entry) {
          final emoji = entry.key;
          final reaction = entry.value;
          final count = reaction.count;
          final hasReacted = widget.currentUserId != null && reaction.hasUser(widget.currentUserId!);

          return InkWell(
            onTap: () {
              if (hasReacted) {
                widget.onRemoveReaction?.call(widget.message.id, emoji);
              } else {
                widget.onAddReaction?.call(widget.message.id, emoji);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasReacted ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                border: hasReacted ? Border.all(color: AppTheme.primaryColor, width: 1) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasReacted ? AppTheme.primaryColor : Colors.grey[400],
                      fontWeight: hasReacted ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvatar(User? user, String authorId) {
    final avatarUrl = user?.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: _getAvatarColor(authorId),
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
        child: Text(
          _getInitials(user, authorId),
          style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: _getAvatarColor(authorId),
      child: Text(
        _getInitials(user, authorId),
        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAttachments(List<Attachment> attachments) {
    // Separate images, videos, and documents
    final images = attachments.where((a) => a.isImage).toList();
    final videos = attachments.where((a) => a.isVideo).toList();
    final documents = attachments.where((a) => !a.isImage && !a.isVideo).toList();

    final imageUrls = images.map((a) => '${AppConstants.autumnUrl}/attachments/${a.id}').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images grid
        if (images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: images.asMap().entries.map((entry) {
              final index = entry.key;
              final a = entry.value;
              final imageUrl = '${AppConstants.autumnUrl}/attachments/${a.id}';
              return _buildImageAttachment(a, imageUrl, imageUrls, index);
            }).toList(),
          ),
        // Videos
        if (videos.isNotEmpty)
          ...videos.map((a) => _buildVideoAttachment(a)),
        // Documents
        if (documents.isNotEmpty)
          ...documents.map((a) => _buildFileAttachment(a)),
      ],
    );
  }

  Widget _buildImageAttachment(Attachment a, String imageUrl, List<String> allUrls, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FullscreenImageViewer(
                imageUrls: allUrls,
                initialIndex: index,
              ),
            ),
          );
        },
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          height: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 200,
            width: 200,
            color: Colors.grey[800],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => _buildFileAttachment(a),
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(Attachment a) {
    final thumbnailUrl = '${AppConstants.autumnUrl}/attachments/${a.id}';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FullscreenVideoPlayer(
                attachmentId: a.id,
                filename: a.filename,
              ),
            ),
          );
        },
        child: Container(
          height: 200,
          width: double.infinity,
          color: Colors.grey[800],
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Thumbnail attempt
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.videocam, size: 48, color: Colors.grey),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(Icons.videocam, size: 48, color: Colors.grey),
                  ),
                ),
              ),
              // Play button overlay
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.play_arrow, size: 32, color: Colors.white),
                ),
              ),
              // Duration / filename overlay at bottom
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    a.filename,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileAttachment(Attachment a) {
    return InkWell(
      onTap: () => _downloadOrOpenFile(a),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(a.filename, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                  if (a.displaySize.isNotEmpty)
                    Text(a.displaySize, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_isDownloading)
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.download, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadOrOpenFile(Attachment a) async {
    final fileUrl = '${AppConstants.autumnUrl}/attachments/${a.id}';
    final uri = Uri.parse(fileUrl);

    // Try to download to local storage first
    try {
      setState(() => _isDownloading = true);

      final dir = await getApplicationDocumentsDirectory();
      // Sanitize filename to prevent path traversal
      var safeFilename = p.basename(a.filename);
      if (safeFilename.isEmpty || safeFilename == '.' || safeFilename == '..') {
        safeFilename = 'attachment_${a.id}';
      }
      final savePath = '${dir.path}/downloads/${a.id}_$safeFilename';
      await Directory('${dir.path}/downloads').create(recursive: true);

      final file = File(savePath);
      if (await file.exists()) {
        // Already downloaded, open it
        setState(() => _isDownloading = false);
        if (await canLaunchUrl(Uri.file(savePath))) {
          await launchUrl(Uri.file(savePath));
        }
        return;
      }

      final dio = Dio();
      await dio.download(fileUrl, savePath);

      setState(() => _isDownloading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.downloaded}: ${a.filename}')),
        );
      }

      // Try to open the downloaded file
      if (await canLaunchUrl(Uri.file(savePath))) {
        await launchUrl(Uri.file(savePath));
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      // Fallback to external browser
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  String _getAuthorName(User? user, String authorId) {
    if (user != null) {
      return user.displayNameOrUsername;
    }
    return authorId.substring(0, authorId.length > 6 ? 6 : authorId.length);
  }

  String _getInitials(User? user, String authorId) {
    final name = user?.displayNameOrUsername ?? authorId;
    return name.substring(0, 1).toUpperCase();
  }

  Color _getAvatarColor(String authorId) {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[authorId.hashCode.abs() % colors.length];
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    if (now.difference(dateTime).inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _ActionChip({required this.icon, required this.label, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}
