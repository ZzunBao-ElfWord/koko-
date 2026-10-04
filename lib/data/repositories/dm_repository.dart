import '../../network/api_client.dart';
import '../local/database.dart';
import '../models/channel.dart';

class DmRepository {
  final ApiClient _api;

  DmRepository(this._api);

  Future<Channel> openDm(String targetUserId) async {
    final data = await _api.openDm(targetUserId);
    final channel = Channel.fromJson(data);
    await LocalDatabase.insertChannel(channel);
    return channel;
  }

  Future<List<Channel>> fetchUserDms() async {
    final raw = await _api.fetchUserDms();
    final channels = raw.map((c) => Channel.fromJson(c as Map<String, dynamic>)).toList();
    await LocalDatabase.insertChannels(channels);
    return channels;
  }

  Future<List<Channel>> getCachedDms() async {
    final all = await LocalDatabase.getChannels();
    return all.where((c) => c.isDirectMessage || c.isGroup || c.isSavedMessages).toList();
  }
}
