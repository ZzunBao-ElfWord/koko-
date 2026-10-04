import '../../core/constants.dart';

/// Server model matching Revolt/Stoat API
class Server {
  final String id;
  final String owner;
  final String name;
  final String? description;
  final String? icon;
  final String? banner;
  final List<String>? channels;
  final List<Category>? categories;
  final List<String>? roles;
  final bool? nsfw;
  final int? flags;

  const Server({
    required this.id,
    required this.owner,
    required this.name,
    this.description,
    this.icon,
    this.banner,
    this.channels,
    this.categories,
    this.roles,
    this.nsfw,
    this.flags,
  });

  factory Server.fromJson(Map<String, dynamic> json) => Server(
        id: json['_id'] ?? json['id'] ?? '',
        owner: json['owner'] ?? '',
        name: json['name'] ?? '',
        description: json['description'],
        icon: json['icon'] is Map ? json['icon']['_id'] : json['icon'],
        banner: json['banner'] is Map ? json['banner']['_id'] : json['banner'],
        channels: (json['channels'] as List?)?.map((e) => e.toString()).toList(),
        categories: (json['categories'] as List?)?.map((e) => Category.fromJson(e)).toList(),
        roles: (json['roles'] as List?)?.map((e) => e.toString()).toList(),
        nsfw: json['nsfw'],
        flags: json['flags'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner': owner,
        'name': name,
        'description': description,
        'icon': icon,
        'banner': banner,
        'channels': channels,
        'categories': categories?.map((e) => e.toJson()).toList(),
        'roles': roles,
        'nsfw': nsfw,
        'flags': flags,
      };

  String? get iconUrl => icon != null ? '${AppConstants.autumnUrl}/icons/$icon' : null;
}

class Category {
  final String id;
  final String title;
  final List<String> channels;

  const Category({required this.id, required this.title, required this.channels});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        channels: (json['channels'] as List?)?.map((e) => e.toString()).toList() ?? [],
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'channels': channels};
}
