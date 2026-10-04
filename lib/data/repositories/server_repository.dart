import '../../network/api_client.dart';
import '../local/database.dart';
import '../models/server.dart';
import '../models/channel.dart';

class ServerRepository {
  final ApiClient _api;

  ServerRepository(this._api);

  Future<List<Server>> fetchServers() async {
    final raw = await _api.fetchServers();
    final servers = raw.map((s) => Server.fromJson(s as Map<String, dynamic>)).toList();
    await LocalDatabase.insertServers(servers);
    return servers;
  }

  Future<List<Server>> getCachedServers() async {
    return LocalDatabase.getServers();
  }

  Future<List<Channel>> fetchChannels(String serverId) async {
    final serverData = await _api.fetchServer(serverId);
    final raw = serverData['channels'];
    // Revolt 0.15.x returns channel IDs (strings) here, not full objects;
    // full channel objects arrive via the WebSocket Ready payload and are
    // cached in LocalDatabase, so fall back to the cache in that case.
    if (raw is List && raw.isNotEmpty && raw.first is Map<String, dynamic>) {
      final channels = raw
          .map((c) => Channel.fromJson(c as Map<String, dynamic>))
          .toList();
      await LocalDatabase.insertChannels(channels);
      return channels;
    }
    return LocalDatabase.getChannels(serverId: serverId);
  }

  Future<List<Channel>> getCachedChannels(String serverId) async {
    return LocalDatabase.getChannels(serverId: serverId);
  }

  Future<Map<String, dynamic>> joinServer(String inviteCode) async {
    return _api.joinServer(inviteCode);
  }
}
