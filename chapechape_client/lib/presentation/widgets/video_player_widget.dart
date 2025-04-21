import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    required this.title,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    // Vérifier si l'URL est une URL YouTube ou une URL de fichier
    if (widget.videoUrl.contains('youtu.be') || widget.videoUrl.contains('youtube.com')) {
      // Pour les vidéos YouTube, nous aurons besoin d'un package supplémentaire
      // comme youtube_player_flutter, mais pour l'instant, affichons un message
      _showYoutubeNotSupportedMessage();
    } else {
      // Utiliser HttpHeaders pour optimiser les performances de chargement vidéo
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: const {'Accept-Encoding': 'gzip'},
      )..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
          }
        }).catchError((error) {
          debugPrint('Erreur lors de l\'initialisation du lecteur vidéo: $error');
          if (mounted) {
            setState(() {
              _isInitialized = false;
            });
          }
        });
    }
  }

  void _showYoutubeNotSupportedMessage() {
    // Cette méthode sera utilisée pour afficher un message indiquant que
    // les vidéos YouTube ne sont pas directement supportées
    setState(() {
      _isInitialized = false;
    });
  }

  @override
  void dispose() {
    // Vérifier si le contrôleur existe et est initialisé avant de le libérer
    if (this._isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (widget.videoUrl.contains('youtu.be') || widget.videoUrl.contains('youtube.com')) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Vidéo YouTube',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'URL: ${widget.videoUrl}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Ici, on pourrait ouvrir l'URL dans un navigateur externe
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Ouvrir dans le navigateur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFFD700),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        if (!_isPlaying)
          IconButton(
            onPressed: () {
              setState(() {
                _controller.play();
                _isPlaying = true;
              });
            },
            icon: const Icon(
              Icons.play_circle_fill,
              size: 80,
              color: Color(0xFFFFD700),
            ),
          ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Color(0xFFFFD700),
              bufferedColor: Colors.white24,
              backgroundColor: Colors.grey,
            ),
            padding: const EdgeInsets.all(16),
          ),
        ),
        Positioned(
          bottom: 50,
          right: 16,
          child: IconButton(
            onPressed: () {
              setState(() {
                if (_isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
                _isPlaying = !_isPlaying;
              });
            },
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}
