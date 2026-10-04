import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../services/voice_service.dart';

/// State for a single voice participant
class VoiceParticipant {
  final String identity;
  final String? name;
  final String? avatarUrl;
  final bool isSpeaking;
  final bool isMuted;
  final bool isDeafened;
  final bool isCameraEnabled;
  final bool isScreenShareEnabled;
  final double audioLevel; // 0.0 - 1.0

  VoiceParticipant({
    required this.identity,
    this.name,
    this.avatarUrl,
    this.isSpeaking = false,
    this.isMuted = false,
    this.isDeafened = false,
    this.isCameraEnabled = false,
    this.isScreenShareEnabled = false,
    this.audioLevel = 0.0,
  });

  VoiceParticipant copyWith({
    String? identity,
    String? name,
    String? avatarUrl,
    bool? isSpeaking,
    bool? isMuted,
    bool? isDeafened,
    bool? isCameraEnabled,
    bool? isScreenShareEnabled,
    double? audioLevel,
  }) {
    return VoiceParticipant(
      identity: identity ?? this.identity,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isMuted: isMuted ?? this.isMuted,
      isDeafened: isDeafened ?? this.isDeafened,
      isCameraEnabled: isCameraEnabled ?? this.isCameraEnabled,
      isScreenShareEnabled: isScreenShareEnabled ?? this.isScreenShareEnabled,
      audioLevel: audioLevel ?? this.audioLevel,
    );
  }
}

/// Global voice room state
class VoiceRoomState {
  final bool isConnected;
  final bool isConnecting;
  final String? roomId;
  final String? channelName;
  final String? error;
  final bool isLocalMuted;
  final bool isLocalDeafened;
  final List<VoiceParticipant> participants;
  final Map<String, double> audioLevels;
  final NetworkQuality networkQuality;

  VoiceRoomState({
    this.isConnected = false,
    this.isConnecting = false,
    this.roomId,
    this.channelName,
    this.error,
    this.isLocalMuted = false,
    this.isLocalDeafened = false,
    this.participants = const [],
    this.audioLevels = const {},
    this.networkQuality = NetworkQuality.unknown,
  });

  VoiceRoomState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? roomId,
    String? channelName,
    String? error,
    bool? isLocalMuted,
    bool? isLocalDeafened,
    List<VoiceParticipant>? participants,
    Map<String, double>? audioLevels,
    NetworkQuality? networkQuality,
  }) {
    return VoiceRoomState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      roomId: roomId ?? this.roomId,
      channelName: channelName ?? this.channelName,
      error: error,
      isLocalMuted: isLocalMuted ?? this.isLocalMuted,
      isLocalDeafened: isLocalDeafened ?? this.isLocalDeafened,
      participants: participants ?? this.participants,
      audioLevels: audioLevels ?? this.audioLevels,
      networkQuality: networkQuality ?? this.networkQuality,
    );
  }

  int get participantCount => participants.length + (isConnected ? 1 : 0);
}

class VoiceRoomNotifier extends StateNotifier<VoiceRoomState> {
  VoiceRoomNotifier() : super(VoiceRoomState());

  void setConnecting(String roomId, String channelName) {
    state = VoiceRoomState(
      isConnecting: true,
      roomId: roomId,
      channelName: channelName,
    );
  }

  void setConnected(String roomId, String channelName) {
    state = VoiceRoomState(
      isConnected: true,
      roomId: roomId,
      channelName: channelName,
    );
  }

  void setError(String error) {
    state = VoiceRoomState(error: error);
  }

  void setDisconnected() {
    state = VoiceRoomState();
  }

  void setLocalMuted(bool muted) {
    state = state.copyWith(isLocalMuted: muted);
  }

  void setLocalDeafened(bool deafened) {
    state = state.copyWith(isLocalDeafened: deafened);
  }

  void updateParticipants(List<VoiceParticipant> participants) {
    state = state.copyWith(participants: participants);
  }

  void updateParticipant(VoiceParticipant participant) {
    final list = [...state.participants];
    final idx = list.indexWhere((p) => p.identity == participant.identity);
    if (idx >= 0) {
      list[idx] = participant;
    } else {
      list.add(participant);
    }
    state = state.copyWith(participants: list);
  }

  void removeParticipant(String identity) {
    final list = state.participants.where((p) => p.identity != identity).toList();
    state = state.copyWith(participants: list);
  }

  void updateAudioLevels(Map<String, double> levels) {
    state = state.copyWith(audioLevels: levels);

    // Also update participant audioLevel fields
    final updatedParticipants = state.participants.map((p) {
      final level = levels[p.identity] ?? 0.0;
      return p.copyWith(audioLevel: level, isSpeaking: level > 0.1);
    }).toList();
    state = state.copyWith(participants: updatedParticipants);
  }

  void updateNetworkQuality(NetworkQuality quality) {
    state = state.copyWith(networkQuality: quality);
  }
}

final voiceRoomProvider = StateNotifierProvider<VoiceRoomNotifier, VoiceRoomState>((ref) {
  return VoiceRoomNotifier();
});
