/// Reply intent model for message replies
class ReplyIntent {
  final String id;
  final bool mention;

  ReplyIntent({required this.id, this.mention = false});

  factory ReplyIntent.fromJson(Map<String, dynamic> json) => ReplyIntent(
        id: json['id'] ?? json['_id'] ?? '',
        mention: json['mention'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mention': mention,
      };
}
