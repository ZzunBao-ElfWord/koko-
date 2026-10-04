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
    final channels = (serverData['channels'] as List? ?? [])
        .map((c) => Channel.fromJson(c as Map<String, dynamic>))
        .toList();
    await LocalDatabase.insertChannels(channels);
    return channels;
  }

  Future<List<Channel>> getCachedChannels(String serverId) async {
    return LocalDatabase.getChannels(serverId: serverId);
  }

  Future<Map<String, dynamic>> joinServer(String inviteCode) async {
    return _api.joinServer(inviteCode);
  }
}
