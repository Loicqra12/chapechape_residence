import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Lecteur vidéo résidence : play/pause, seek, mute, plein écran.
class ResidenceVideoPlayer extends StatefulWidget {
  final String url;
  final String? thumbnail;
  final TextStyle? sectionTitleStyle;

  const ResidenceVideoPlayer({
    super.key,
    required this.url,
    this.thumbnail,
    this.sectionTitleStyle,
  });

  @override
  State<ResidenceVideoPlayer> createState() => _ResidenceVideoPlayerState();
}

class _ResidenceVideoPlayerState extends State<ResidenceVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _loading = false;
  bool _showControls = true;
  bool _muted = false;
  Timer? _hideTimer;

  Future<void> _initAndPlay() async {
    if (_initialized || _loading) return;
    setState(() => _loading = true);
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      controller.addListener(_onTick);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initialized = true;
        _loading = false;
        _showControls = true;
      });
      _scheduleHideControls();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    if (_controller?.value.isPlaying != true) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller?.value.isPlaying == true) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  Future<void> _togglePlay() async {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
      setState(() => _showControls = true);
      _hideTimer?.cancel();
    } else {
      await c.play();
      _scheduleHideControls();
    }
    setState(() {});
  }

  Future<void> _toggleMute() async {
    final c = _controller;
    if (c == null) return;
    final next = !_muted;
    await c.setVolume(next ? 0 : 1);
    setState(() => _muted = next);
    _scheduleHideControls();
  }

  Future<void> _seekRelative(Duration delta) async {
    final c = _controller;
    if (c == null) return;
    final target = c.value.position + delta;
    final max = c.value.duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > max ? max : target);
    await c.seekTo(clamped);
    _scheduleHideControls();
  }

  Future<void> _openFullscreen() async {
    final c = _controller;
    if (c == null || !_initialized) return;
    _hideTimer?.cancel();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _VideoFullscreenPage(
          controller: c,
          muted: _muted,
          onMutedChanged: (m) {
            if (mounted) setState(() => _muted = m);
          },
        ),
      ),
    );
    if (mounted) {
      setState(() => _showControls = true);
      _scheduleHideControls();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Visite vidéo', style: widget.sectionTitleStyle),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _initialized && _controller != null
                ? _controller!.value.aspectRatio.clamp(0.5, 2.5)
                : 16 / 9,
            child: ColoredBox(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (!_initialized && widget.thumbnail != null)
                    Image.network(widget.thumbnail!, fit: BoxFit.cover),
                  if (_initialized && _controller != null)
                    FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  if (_loading)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  if (!_initialized && !_loading)
                    Center(
                      child: _RoundControl(
                        icon: Icons.play_arrow_rounded,
                        size: 64,
                        iconSize: 40,
                        onTap: _initAndPlay,
                      ),
                    ),
                  if (_initialized && _controller != null)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleControls,
                        child: AnimatedOpacity(
                          opacity: _showControls ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            ignoring: !_showControls,
                            child: _VideoControlsOverlay(
                              controller: _controller!,
                              muted: _muted,
                              onPlayPause: _togglePlay,
                              onMute: _toggleMute,
                              onFullscreen: _openFullscreen,
                              onSeekBack: () =>
                                  _seekRelative(const Duration(seconds: -10)),
                              onSeekForward: () =>
                                  _seekRelative(const Duration(seconds: 10)),
                              onInteraction: _scheduleHideControls,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;
  final bool muted;
  final bool isFullscreen;
  final VoidCallback onPlayPause;
  final VoidCallback onMute;
  final VoidCallback onFullscreen;
  final VoidCallback onSeekBack;
  final VoidCallback onSeekForward;
  final VoidCallback onInteraction;

  const _VideoControlsOverlay({
    required this.controller,
    required this.muted,
    this.isFullscreen = false,
    required this.onPlayPause,
    required this.onMute,
    required this.onFullscreen,
    required this.onSeekBack,
    required this.onSeekForward,
    required this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final position = value.position;
    final duration = value.duration;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x66000000),
            Colors.transparent,
            Color(0x99000000),
          ],
          stops: [0, 0.45, 1],
        ),
      ),
      child: Column(
        children: [
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundControl(
                icon: Icons.replay_10_rounded,
                size: 44,
                iconSize: 26,
                onTap: onSeekBack,
              ),
              _RoundControl(
                icon: value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 64,
                iconSize: 40,
                onTap: onPlayPause,
              ),
              _RoundControl(
                icon: Icons.forward_10_rounded,
                size: 44,
                iconSize: 26,
                onTap: onSeekForward,
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white38,
                    thumbColor: Colors.white,
                    overlayColor: Colors.white24,
                  ),
                  child: Slider(
                    value: progress,
                    onChanged: (v) {
                      onInteraction();
                      final ms = (duration.inMilliseconds * v).round();
                      controller.seekTo(Duration(milliseconds: ms));
                    },
                    onChangeEnd: (_) => onInteraction(),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${_fmt(position)} / ${_fmt(duration)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onMute,
                      icon: Icon(
                        muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onFullscreen,
                      icon: Icon(
                        isFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoFullscreenPage extends StatefulWidget {
  final VideoPlayerController controller;
  final bool muted;
  final ValueChanged<bool> onMutedChanged;

  const _VideoFullscreenPage({
    required this.controller,
    required this.muted,
    required this.onMutedChanged,
  });

  @override
  State<_VideoFullscreenPage> createState() => _VideoFullscreenPageState();
}

class _VideoFullscreenPageState extends State<_VideoFullscreenPage> {
  bool _showControls = true;
  late bool _muted;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _muted = widget.muted;
    widget.controller.addListener(_onTick);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _scheduleHide();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!widget.controller.value.isPlaying) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  Future<void> _togglePlay() async {
    final c = widget.controller;
    if (c.value.isPlaying) {
      await c.pause();
      setState(() => _showControls = true);
      _hideTimer?.cancel();
    } else {
      await c.play();
      _scheduleHide();
    }
    setState(() {});
  }

  Future<void> _toggleMute() async {
    final next = !_muted;
    await widget.controller.setVolume(next ? 0 : 1);
    setState(() => _muted = next);
    widget.onMutedChanged(next);
    _scheduleHide();
  }

  Future<void> _seekRelative(Duration delta) async {
    final c = widget.controller;
    final target = c.value.position + delta;
    final max = c.value.duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > max ? max : target);
    await c.seekTo(clamped);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onTick);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
                child: VideoPlayer(c),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => _showControls = !_showControls);
                  if (_showControls) _scheduleHide();
                },
                child: AnimatedOpacity(
                  opacity: _showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 8,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        _VideoControlsOverlay(
                          controller: c,
                          muted: _muted,
                          isFullscreen: true,
                          onPlayPause: _togglePlay,
                          onMute: _toggleMute,
                          onFullscreen: () => Navigator.of(context).pop(),
                          onSeekBack: () =>
                              _seekRelative(const Duration(seconds: -10)),
                          onSeekForward: () =>
                              _seekRelative(const Duration(seconds: 10)),
                          onInteraction: _scheduleHide,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  const _RoundControl({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

String _fmt(Duration d) {
  final total = d.inSeconds;
  final m = (total ~/ 60).toString().padLeft(2, '0');
  final s = (total % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
