import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/constants.dart';
import '../../network/api_client.dart';
import '../states/voice_state.dart';

/// Stub voice service for debug builds.
/// LiveKit voice room connections are disabled in test environment.
class VoiceService {
  final ApiClient _apiClient;

  final _participantController = StreamController<VoiceParticipant>.broadcast();
  final _disconnectController = StreamController<void>.broadcast();
  final _audioLevelController = StreamController<Map<String, double>>.broadcast();
  final _networkQualityController = StreamController<NetworkQuality>.broadcast();

  Stream<VoiceParticipant> get participantUpdates => _participantController.stream;
  Stream<void> get onDisconnected => _disconnectController.stream;
  Stream<Map<String, double>> get audioLevels => _audioLevelController.stream;
  Stream<NetworkQuality> get networkQuality => _networkQualityController.stream;

  bool get isConnected => false;

  VoiceService(this._apiClient);

  Future<void> joinVoiceChannel(
    String channelId,
    String channelName,
    VoiceRoomNotifier notifier,
  ) async {
    if (kDebugMode) {
      debugPrint('[VoiceService] Stub joinVoiceChannel called (LiveKit disabled)');
    }
    notifier.setError('语音功能在测试构建中不可用');
  }

  Future<void> leaveVoiceChannel(VoiceRoomNotifier notifier) async {
    notifier.disconnect();
  }

  Future<void> toggleMute(VoiceRoomNotifier notifier) async {
    notifier.toggleMute();
  }

  Future<void> toggleDeafen(VoiceRoomNotifier notifier) async {
    notifier.toggleDeafen();
  }

  void dispose() {
    _participantController.close();
    _disconnectController.close();
    _audioLevelController.close();
    _networkQualityController.close();
  }
}
