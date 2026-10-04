import '../../core/constants.dart';

/// Channel model matching Revolt/Stoat API
class Channel {
  final String id;
  final String channelType;
  final String? server;
  final String? name;
  final String? description;
  final String? icon;
  final List<String>? recipients;
  final String? owner;
  final String? lastMessageId;
  final int? defaultPermissions;
  final int? rolePermissions;
  final bool? nsfw;

  // For display
  int unreadCount;
  int mentionCount;

  Channel({
    required this.id,
    required this.channelType,
    this.server,
    this.name,
    this.description,
    this.icon,
    this.recipients,
    this.owner,
    this.lastMessageId,
    this.defaultPermissions,
    this.rolePermissions,
    this.nsfw,
    this.unreadCount = 0,
    this.mentionCount = 0,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['_id'] ?? json['id'] ?? '',
        channelType: json['channel_type'] ?? 'Unknown',
        server: json['server'],
        name: json['name'],
        description: json['description'],
        icon: json['icon'] is Map ? json['icon']['_id'] : json['icon'],
        recipients: (json['recipients'] as List?)?.map((e) => e.toString()).toList(),
        owner: json['owner'],
        lastMessageId: json['last_message_id'],
        defaultPermissions: json['default_permissions'],
        rolePermissions: json['role_permissions'],
        nsfw: json['nsfw'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel_type': channelType,
        'server': server,
        'name': name,
        'description': description,
        'icon': icon,
        'recipients': recipients,
        'owner': owner,
        'last_message_id': lastMessageId,
        'default_permissions': defaultPermissions,
        'role_permissions': rolePermissions,
        'nsfw': nsfw,
      };

  bool get isText => channelType == 'TextChannel';
  bool get isVoice => channelType == 'VoiceChannel';
  bool get isGroup => channelType == 'Group';
  bool get isSavedMessages => channelType == 'SavedMessages';
  bool get isDirectMessage => channelType == 'DirectMessage';

  String get displayName {
    if (name != null && name!.isNotEmpty) return name!;
    if (isSavedMessages) return 'Saved Messages';
    if (isDirectMessage && recipients != null && recipients!.isNotEmpty) {
      return recipients!.first;
    }
    return 'Unknown';
  }

  String? get iconUrl => icon != null ? '${AppConstants.autumnUrl}/icons/$icon' : null;
}
