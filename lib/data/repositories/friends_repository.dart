import '../../network/api_client.dart';
import '../local/database.dart';
import '../models/user.dart';
import '../models/server.dart';

/// Repository for managing friend relationships.
class FriendsRepository {
  final ApiClient _api;

  FriendsRepository(this._api);

  /// Fetch all relationships (friends, incoming requests, outgoing requests, blocked).
  Future<List<User>> fetchRelationships() async {
    final raw = await _api.fetchRelationships();
    final users = raw.map((u) => User.fromJson(u as Map<String, dynamic>)).toList();
    await LocalDatabase.insertUsers(users);
    return users;
  }

  /// Get cached friends (relationship == 'Friend').
  Future<List<User>> getCachedFriends() async {
    return LocalDatabase.getUsersByRelationship('Friend');
  }

  /// Get cached incoming friend requests.
  Future<List<User>> getCachedIncomingRequests() async {
    return LocalDatabase.getUsersByRelationship('Incoming');
  }

  /// Get cached outgoing friend requests.
  Future<List<User>> getCachedOutgoingRequests() async {
    return LocalDatabase.getUsersByRelationship('Outgoing');
  }

  /// Send a friend request by username.
  Future<void> sendFriendRequest(String username) async {
    await _api.addFriend(username);
  }

  /// Accept a friend request.
  Future<void> acceptFriendRequest(String userId) async {
    await _api.acceptFriend(userId);
    await LocalDatabase.updateUserRelationship(userId, 'Friend');
  }

  /// Reject or remove a friend.
  Future<void> removeFriend(String userId) async {
    await _api.removeFriend(userId);
    await LocalDatabase.updateUserRelationship(userId, 'None');
  }

  /// Fetch mutual servers with a user.
  Future<List<Server>> fetchMutualServers(String userId) async {
    final raw = await _api.fetchMutualServers(userId);
    return raw.map((s) => Server.fromJson(s as Map<String, dynamic>)).toList();
  }
}
