/// Reaction model for message emoji reactions
class Reaction {
  final String emoji;
  final List<String> userIds;

  Reaction({required this.emoji, required this.userIds});

  factory Reaction.fromEntry(String emoji, List<dynamic> users) => Reaction(
        emoji: emoji,
        userIds: users.map((e) => e.toString()).toList(),
      );

  int get count => userIds.length;

  bool hasUser(String userId) => userIds.contains(userId);
}
