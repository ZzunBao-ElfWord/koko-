import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants.dart';
import '../../network/api_client.dart';
import '../states/voice_state.dart';

/// Service for managing LiveKit voice room connections.
/// Handles connect, disconnect, mute/unmute, deafen/undeafen,
/// participant state tracking, audio levels, and network quality.
class VoiceService {
  final ApiClient _apiClient;
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  Timer? _audioLevelTimer;
  Timer? _networkQualityTimer;

  final _participantController = StreamController<VoiceParticipant>.broadcast();
  final _disconnectController = StreamController<void>.broadcast();
  final _audioLevelController = StreamController<Map<String, double>>.broadcast();
  final _networkQualityController = StreamController<NetworkQuality>.broadcast();

  Stream<VoiceParticipant> get participantUpdates => _participantController.stream;
  Stream<void> get onDisconnected => _disconnectController.stream;
  Stream<Map<String, double>> get audioLevels => _audioLevelController.stream;
  Stream<NetworkQuality> get networkQuality => _networkQualityController.stream;

  bool get isConnected => _room != null && _room!.state == RoomState.connected;

  VoiceService(this._apiClient);

  /// Request microphone permission and join a voice channel.
  Future<void> joinVoiceChannel(
    String channelId,
    String channelName,
    VoiceRoomNotifier notifier,
  ) async {
    if (isConnected) {
      await leaveVoiceChannel(notifier);
    }

    // Request microphone permission
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      notifier.setError('麦克风权限被拒绝，请在设置中开启');
      return;
    }

    notifier.setConnecting(channelId, channelName);

    try {
      // Fetch LiveKit token from backend
      final tokenData = await _apiClient.fetchLiveKitToken(channelId);
      final token = tokenData['token'] as String?;
      final url = tokenData['url'] as String? ?? AppConstants.livekitUrl;

      if (token == null || token.isEmpty) {
        notifier.setError('无法获取语音房间令牌，请确认后端 LiveKit 已配置');
        return;
      }

      // Create and connect to LiveKit room
      final roomOptions = RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      );

      _room = Room(roomOptions: roomOptions);
      _listener = _room!.createListener();
      _setupRoomListeners(notifier);
      _startAudioLevelMonitoring(notifier);
      _startNetworkQualityMonitoring(notifier);

      await _room!.connect(
        url,
        token,
        roomOptions: roomOptions,
      );

      // Publish local audio (microphone)
      await _room!.localParticipant!.setMicrophoneEnabled(true);

      notifier.setConnected(channelId, channelName);

      // Populate initial participants
      _syncParticipants(notifier);
    } catch (e) {
      debugPrint('LiveKit connection error: $e');
      notifier.setError('语音连接失败: $e');
      await _cleanup();
    }
  }

  /// Leave the current voice channel and release resources.
  Future<void> leaveVoiceChannel(VoiceRoomNotifier notifier) async {
    await _cleanup();
    notifier.setDisconnected();
  }

  /// Toggle local microphone mute state.
  Future<void> toggleMute(VoiceRoomNotifier notifier) async {
    if (_room == null || _room!.localParticipant == null) return;

    final current = _room!.localParticipant!.isMuted;
    await _room!.localParticipant!.setMicrophoneEnabled(current);
    notifier.setLocalMuted(!current);
  }

  /// Toggle deafen state (mute all remote audio + local mic).
  Future<void> toggleDeafen(VoiceRoomNotifier notifier) async {
    if (_room == null) return;

    final newDeafen = !notifier.state.isLocalDeafened;

    // Mute/unmute local mic
    await _room!.localParticipant?.setMicrophoneEnabled(!newDeafen);

    // Mute/unmute all remote audio tracks
    for (final participant in _room!.remoteParticipants.values) {
      for (final track in participant.audioTrackPublications) {
        await track.setMuted(newDeafen);
      }
    }

    notifier.setLocalDeafened(newDeafen);
    notifier.setLocalMuted(newDeafen);
  }

  void _setupRoomListeners(VoiceRoomNotifier notifier) {
    if (_listener == null) return;

    _listener!.on<RoomConnectedEvent>((_) {
      notifier.setConnected(
        notifier.state.roomId ?? '',
        notifier.state.channelName ?? '',
      );
    });

    _listener!.on<RoomDisconnectedEvent>((event) {
      debugPrint('Room disconnected: ${event.reason}');
      _disconnectController.add(null);
      notifier.setDisconnected();
    });

    _listener!.on<ParticipantConnectedEvent>((event) {
      _syncParticipants(notifier);
    });

    _listener!.on<ParticipantDisconnectedEvent>((event) {
      notifier.removeParticipant(event.participant.identity);
    });

    _listener!.on<TrackSubscribedEvent>((event) {
      _syncParticipants(notifier);
    });

    _listener!.on<TrackUnsubscribedEvent>((event) {
      _syncParticipants(notifier);
    });

    _listener!.on<LocalTrackPublishedEvent>((_) {
      _syncParticipants(notifier);
    });

    _listener!.on<LocalTrackUnpublishedEvent>((_) {
      _syncParticipants(notifier);
    });

    _listener!.on<ActiveSpeakersChangedEvent>((event) {
      for (final speaker in event.speakers) {
        final updated = VoiceParticipant(
          identity: speaker.identity,
          name: speaker.name,
          isSpeaking: true,
        );
        notifier.updateParticipant(updated);
        _participantController.add(updated);
      }
      _syncParticipants(notifier);
    });

    _listener!.on<TrackMutedEvent>((event) {
      _syncParticipants(notifier);
    });

    _listener!.on<TrackUnmutedEvent>((event) {
      _syncParticipants(notifier);
    });

    _listener!.on<ConnectionQualityChangedEvent>((event) {
      _updateNetworkQuality(notifier);
    });
  }

  void _syncParticipants(VoiceRoomNotifier notifier) {
    if (_room == null) return;

    final participants = <VoiceParticipant>[];

    for (final rp in _room!.remoteParticipants.values) {
      final audioPub = rp.audioTrackPublications.firstOrNull;
      participants.add(VoiceParticipant(
        identity: rp.identity,
        name: rp.name,
        isSpeaking: rp.isSpeaking,
        isMuted: audioPub?.muted ?? true,
      ));
    }

    notifier.updateParticipants(participants);
  }

  // ========== AUDIO LEVEL MONITORING ==========

  void _startAudioLevelMonitoring(VoiceRoomNotifier notifier) {
    _audioLevelTimer?.cancel();
    _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_room == null) return;

      final levels = <String, double>{};

      // Local participant audio level
      final localParticipant = _room!.localParticipant;
      if (localParticipant != null && !localParticipant.isMuted) {
        // Simulate audio level based on speaking state (LiveKit Flutter SDK
        // does not expose direct audio level; we use isSpeaking as proxy)
        final level = localParticipant.isSpeaking ? 0.5 + Random().nextDouble() * 0.5 : 0.0;
        levels['local'] = level.clamp(0.0, 1.0);
      }

      // Remote participants audio levels
      for (final rp in _room!.remoteParticipants.values) {
        final level = rp.isSpeaking ? 0.3 + Random().nextDouble() * 0.7 : 0.0;
        levels[rp.identity] = level.clamp(0.0, 1.0);
      }

      _audioLevelController.add(levels);
      notifier.updateAudioLevels(levels);
    });
  }

  // ========== NETWORK QUALITY MONITORING ==========

  void _startNetworkQualityMonitoring(VoiceRoomNotifier notifier) {
    _networkQualityTimer?.cancel();
    _networkQualityTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _updateNetworkQuality(notifier);
    });
  }

  void _updateNetworkQuality(VoiceRoomNotifier notifier) {
    if (_room == null) return;

    // Gather connection quality from all participants
    int poorCount = 0;
    int totalCount = 0;

    for (final rp in _room!.remoteParticipants.values) {
      totalCount++;
      if (rp.connectionQuality == ConnectionQuality.poor) {
        poorCount++;
      }
    }

    // Check local connection quality
    final localParticipant = _room!.localParticipant;
    if (localParticipant != null) {
      totalCount++;
      if (localParticipant.connectionQuality == ConnectionQuality.poor) {
        poorCount++;
      }
    }

    // Determine overall quality
    NetworkQuality quality;
    if (totalCount == 0) {
      quality = NetworkQuality.unknown;
    } else if (poorCount > 0) {
      quality = NetworkQuality.poor;
    } else {
      quality = NetworkQuality.good;
    }

    _networkQualityController.add(quality);
    notifier.updateNetworkQuality(quality);
  }

  Future<void> _cleanup() async {
    _audioLevelTimer?.cancel();
    _audioLevelTimer = null;
    _networkQualityTimer?.cancel();
    _networkQualityTimer = null;
    _listener?.dispose();
    _listener = null;
    await _room?.dispose();
    _room = null;
  }

  void dispose() {
    _cleanup();
    _participantController.close();
    _disconnectController.close();
    _audioLevelController.close();
    _networkQualityController.close();
  }
}

/// Network quality enum for voice call
enum NetworkQuality {
  unknown,
  good,
  poor,
}
