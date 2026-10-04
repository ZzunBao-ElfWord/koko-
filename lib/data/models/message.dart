import 'attachment.dart';
import 'reaction.dart';

/// Message model matching Revolt/Stoat API
class Message {
  final String id;
  final String channel;
  final String author;
  final String? content;
  final List<Attachment>? attachments;
  final List<dynamic>? embeds;
  final List<String>? mentions;
  final List<String>? replies;
  final Map<String, Reaction>? reactions;
  final String? edited;
  final String? masquerade;
  final int? flags;

  // Local state
  bool isPending;
  bool isFailed;

  Message({
    required this.id,
    required this.channel,
    required this.author,
    this.content,
    this.attachments,
    this.embeds,
    this.mentions,
    this.replies,
    this.reactions,
    this.edited,
    this.masquerade,
    this.flags,
    this.isPending = false,
    this.isFailed = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final attachmentsRaw = json['attachments'] as List?;
    final reactionsRaw = json['reactions'] as Map<String, dynamic>?;

    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      channel: json['channel'] ?? '',
      author: json['author'] ?? '',
      content: json['content'],
      attachments: attachmentsRaw?.map((a) => Attachment.fromJson(a as Map<String, dynamic>)).toList(),
      embeds: json['embeds'] as List?,
      mentions: (json['mentions'] as List?)?.map((e) => e.toString()).toList(),
      replies: (json['replies'] as List?)?.map((e) {
        if (e is Map) return e['_id']?.toString() ?? e['id']?.toString() ?? '';
        return e.toString();
      }).where((s) => s.isNotEmpty).toList(),
      reactions: reactionsRaw?.map((emoji, users) => MapEntry(emoji, Reaction.fromEntry(emoji, users as List))),
      edited: json['edited'],
      masquerade: json['masquerade']?.toString(),
      flags: json['flags'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel': channel,
        'author': author,
        'content': content,
        'attachments': attachments?.map((a) => a.toJson()).toList(),
        'embeds': embeds,
        'mentions': mentions,
        'replies': replies,
        'reactions': reactions?.map((emoji, reaction) => MapEntry(emoji, reaction.userIds)),
        'edited': edited,
        'masquerade': masquerade,
        'flags': flags,
      };

  bool get hasContent => content != null && content!.isNotEmpty;
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;
  bool get isEdited => edited != null;
  bool get isSystem => flags != null && flags! & 1 != 0;
  bool get hasReactions => reactions != null && reactions!.isNotEmpty;
  bool get hasReplies => replies != null && replies!.isNotEmpty;

  DateTime? get createdAt {
    try {
      // ULID-based timestamp extraction (first 10 chars = timestamp)
      if (id.length >= 10) {
        final timestamp = int.parse(id.substring(0, 10), radix: 32);
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (_) {}
    return null;
  }

  Message copyWith({
    String? id,
    String? channel,
    String? author,
    String? content,
    List<Attachment>? attachments,
    List<dynamic>? embeds,
    List<String>? mentions,
    List<String>? replies,
    Map<String, Reaction>? reactions,
    String? edited,
    String? masquerade,
    int? flags,
    bool? isPending,
    bool? isFailed,
  }) =>
      Message(
        id: id ?? this.id,
        channel: channel ?? this.channel,
        author: author ?? this.author,
        content: content ?? this.content,
        attachments: attachments ?? this.attachments,
        embeds: embeds ?? this.embeds,
        mentions: mentions ?? this.mentions,
        replies: replies ?? this.replies,
        reactions: reactions ?? this.reactions,
        edited: edited ?? this.edited,
        masquerade: masquerade ?? this.masquerade,
        flags: flags ?? this.flags,
        isPending: isPending ?? this.isPending,
        isFailed: isFailed ?? this.isFailed,
      );
}
