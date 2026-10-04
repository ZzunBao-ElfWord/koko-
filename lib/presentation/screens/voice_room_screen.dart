import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../data/models/channel.dart';
import '../../domain/states/voice_state.dart';
import '../../domain/services/voice_service.dart';
import '../providers/app_provider.dart';
import '../../l10n/app_localizations.dart';

/// Voice room screen showing participants and call controls.
/// Includes speaking volume waves, network quality banner, and call controls.
class VoiceRoomScreen extends ConsumerStatefulWidget {
  final Channel channel;

  const VoiceRoomScreen({super.key, required this.channel});

  @override
  ConsumerState<VoiceRoomScreen> createState() => _VoiceRoomScreenState();
}

class _VoiceRoomScreenState extends ConsumerState<VoiceRoomScreen> {
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _joinRoom();
  }

  Future<void> _joinRoom() async {
    setState(() => _isJoining = true);
    final voiceService = ref.read(voiceServiceProvider);
    final notifier = ref.read(voiceRoomProvider.notifier);
    await voiceService.joinVoiceChannel(
      widget.channel.id,
      widget.channel.displayName,
      notifier,
    );
    if (mounted) setState(() => _isJoining = false);
  }

  Future<void> _leaveRoom() async {
    final voiceService = ref.read(voiceServiceProvider);
    final notifier = ref.read(voiceRoomProvider.notifier);
    await voiceService.leaveVoiceChannel(notifier);
    if (mounted) context.pop();
  }

  Future<void> _toggleMute() async {
    final voiceService = ref.read(voiceServiceProvider);
    final notifier = ref.read(voiceRoomProvider.notifier);
    await voiceService.toggleMute(notifier);
  }

  Future<void> _toggleDeafen() async {
    final voiceService = ref.read(voiceServiceProvider);
    final notifier = ref.read(voiceRoomProvider.notifier);
    await voiceService.toggleDeafen(notifier);
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceRoomProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leaveRoom,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.channel.displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              voiceState.isConnected
                  ? '${voiceState.participantCount} ${AppLocalizations.of(context)!.onlineCountPeople}'
                  : voiceState.isConnecting
                      ? AppLocalizations.of(context)!.connecting
                      : voiceState.error ?? AppLocalizations.of(context)!.notConnected,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Network quality banner
          if (voiceState.networkQuality == NetworkQuality.poor)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange.withOpacity(0.2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.signal_cellular_connected_no_internet_4_bar, size: 16, color: Colors.orange[300]),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.networkQualityPoor,
                    style: TextStyle(color: Colors.orange[300], fontSize: 13),
                  ),
                ],
              ),
            ),

          // Error banner
          if (voiceState.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: AppTheme.errorColor.withOpacity(0.2),
              child: Text(
                voiceState.error!,
                style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

          // Loading indicator
          if (_isJoining || voiceState.isConnecting)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.joiningVoice),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: _buildParticipantsGrid(voiceState),
            ),

          // Bottom controls
          _buildControls(voiceState),
        ],
      ),
    );
  }

  Widget _buildParticipantsGrid(VoiceRoomState voiceState) {
    final allParticipants = <VoiceParticipant>[];

    // Add local user
    if (voiceState.isConnected) {
      final localLevel = voiceState.audioLevels['local'] ?? 0.0;
      allParticipants.add(VoiceParticipant(
        identity: 'local',
        name: AppLocalizations.of(context)!.me,
        isMuted: voiceState.isLocalMuted,
        isDeafened: voiceState.isLocalDeafened,
        audioLevel: localLevel,
      ));
    }

    // Add remote participants
    allParticipants.addAll(voiceState.participants);

    if (allParticipants.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noOtherParticipants),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: allParticipants.length,
      itemBuilder: (context, index) {
        final participant = allParticipants[index];
        return _buildParticipantCard(participant);
      },
    );
  }

  Widget _buildParticipantCard(VoiceParticipant participant) {
    final isLocal = participant.identity == 'local';
    final isSpeaking = participant.isSpeaking && !participant.isMuted && !participant.isDeafened;
    final audioLevel = participant.audioLevel;

    return Column(
      children: [
        // Avatar with speaking indicator and volume waves
        Stack(
          alignment: Alignment.center,
          children: [
            // Volume wave rings when speaking
            if (isSpeaking)
              _VolumeWaveIndicator(audioLevel: audioLevel),
            // Avatar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isSpeaking
                    ? [
                        BoxShadow(
                          color: AppTheme.successColor.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: isSpeaking ? AppTheme.successColor.withOpacity(0.3) : Colors.grey[800],
                child: participant.avatarUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: participant.avatarUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => _buildDefaultAvatar(participant, isLocal),
                        ),
                      )
                    : _buildDefaultAvatar(participant, isLocal),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Name
        Text(
          participant.name ?? participant.identity,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        // Status icons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (participant.isMuted)
              const Icon(Icons.mic_off, size: 14, color: Colors.red),
            if (participant.isDeafened)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.headset_off, size: 14, color: Colors.red),
              ),
            if (isSpeaking)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.volume_up, size: 14, color: Colors.green),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(VoiceParticipant participant, bool isLocal) {
    return Icon(
      isLocal ? Icons.person : Icons.person_outline,
      size: 36,
      color: Colors.grey[400],
    );
  }

  Widget _buildControls(VoiceRoomState voiceState) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            _buildControlButton(
              icon: voiceState.isLocalMuted ? Icons.mic_off : Icons.mic,
              label: voiceState.isLocalMuted ? AppLocalizations.of(context)!.unmute : AppLocalizations.of(context)!.mute,
              color: voiceState.isLocalMuted ? Colors.red : AppTheme.primaryColor,
              onPressed: _toggleMute,
            ),
            // Deafen button
            _buildControlButton(
              icon: voiceState.isLocalDeafened ? Icons.headset_off : Icons.headset,
              label: voiceState.isLocalDeafened ? AppLocalizations.of(context)!.undeafen : AppLocalizations.of(context)!.deafen,
              color: voiceState.isLocalDeafened ? Colors.red : AppTheme.primaryColor,
              onPressed: _toggleDeafen,
            ),
            // Leave button
            _buildControlButton(
              icon: Icons.call_end,
              label: AppLocalizations.of(context)!.leave,
              color: Colors.red,
              onPressed: _leaveRoom,
              isLeave: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLeave = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    // Ensure we leave the room when the screen is disposed
    final voiceService = ref.read(voiceServiceProvider);
    final notifier = ref.read(voiceRoomProvider.notifier);
    voiceService.leaveVoiceChannel(notifier);
    super.dispose();
  }
}

/// Animated volume wave indicator that pulses around the avatar when speaking.
class _VolumeWaveIndicator extends StatefulWidget {
  final double audioLevel;

  const _VolumeWaveIndicator({required this.audioLevel});

  @override
  State<_VolumeWaveIndicator> createState() => _VolumeWaveIndicatorState();
}

class _VolumeWaveIndicatorState extends State<_VolumeWaveIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final waveCount = 3;
        final waveOpacity = (1.0 - progress) * 0.4 * widget.audioLevel;
        final waveScale = 1.0 + progress * 0.3 * widget.audioLevel;

        return Stack(
          alignment: Alignment.center,
          children: List.generate(waveCount, (index) {
            final delay = index / waveCount;
            final adjustedProgress = ((progress + delay) % 1.0);
            final opacity = (1.0 - adjustedProgress) * 0.3 * widget.audioLevel;
            final scale = 1.0 + adjustedProgress * 0.4;

            return Transform.scale(
              scale: scale,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(opacity.clamp(0.0, 0.4)),
                    width: 2,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
