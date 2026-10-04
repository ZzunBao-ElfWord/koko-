import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants.dart';
import '../../l10n/app_localizations.dart';

/// Full-screen video player with controls, play/pause, and dismiss gesture.
class FullscreenVideoPlayer extends StatefulWidget {
  final String attachmentId;
  final String filename;

  const FullscreenVideoPlayer({
    super.key,
    required this.attachmentId,
    required this.filename,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final videoUrl = '${AppConstants.autumnUrl}/attachments/${widget.attachmentId}';
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      _controller!.addListener(_onPlayerUpdate);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _onPlayerUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    setState(() => _showControls = true);
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity!.abs() > 300) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video
            if (_isInitialized && _controller != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else if (_hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image, color: Colors.white, size: 64),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.videoLoadFailed, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Controls overlay
            if (_showControls)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: Column(
                  children: [
                    // Top bar
                    SafeArea(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              widget.filename,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Play/pause button
                    if (_isInitialized)
                      IconButton(
                        iconSize: 64,
                        icon: Icon(
                          _controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    const Spacer(),
                    // Bottom progress bar
                    if (_isInitialized && _controller != null)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VideoProgressIndicator(
                                _controller!,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: Colors.white,
                                  bufferedColor: Colors.grey,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_controller!.value.position),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  Text(
                                    _formatDuration(_controller!.value.duration),
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    super.dispose();
  }
}
