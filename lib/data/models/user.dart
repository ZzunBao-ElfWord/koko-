import '../../core/constants.dart';

/// User model matching Revolt/Stoat API
class User {
  final String id;
  final String username;
  final String? displayName;
  final String? avatar;
  final String? banner;
  final UserStatus? status;
  final String? relationship;
  final bool? online;
  final int? flags;

  const User({
    required this.id,
    required this.username,
    this.displayName,
    this.avatar,
    this.banner,
    this.status,
    this.relationship,
    this.online,
    this.flags,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      username: json['username'] ?? '',
      displayName: json['display_name'],
      avatar: json['avatar'] is Map ? json['avatar']['_id'] : json['avatar'],
      banner: json['banner'] is Map ? json['banner']['_id'] : json['banner'],
      status: json['status'] != null ? UserStatus.fromJson(json['status']) : null,
      relationship: json['relationship'],
      online: json['online'],
      flags: json['flags'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar': avatar,
        'banner': banner,
        'status': status?.toJson(),
        'relationship': relationship,
        'online': online,
        'flags': flags,
      };

  String get displayNameOrUsername => displayName?.isNotEmpty == true ? displayName! : username;

  String? get avatarUrl => avatar != null ? '${AppConstants.autumnUrl}/avatars/$avatar' : null;

  User copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatar,
    String? banner,
    UserStatus? status,
    String? relationship,
    bool? online,
    int? flags,
  }) =>
      User(
        id: id ?? this.id,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        avatar: avatar ?? this.avatar,
        banner: banner ?? this.banner,
        status: status ?? this.status,
        relationship: relationship ?? this.relationship,
        online: online ?? this.online,
        flags: flags ?? this.flags,
      );
}

class UserStatus {
  final String? text;
  final String presence;

  const UserStatus({this.text, required this.presence});

  factory UserStatus.fromJson(Map<String, dynamic> json) => UserStatus(
        text: json['text'],
        presence: json['presence'] ?? 'unknown',
      );

  Map<String, dynamic> toJson() => {'text': text, 'presence': presence};

  bool get isOnline => presence == 'online';
  bool get isIdle => presence == 'idle';
  bool get isBusy => presence == 'busy';
  bool get isInvisible => presence == 'invisible';
}
