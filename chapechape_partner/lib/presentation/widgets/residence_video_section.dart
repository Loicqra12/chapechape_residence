import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:chapechape_partner/core/config/feature_flags.dart';
import 'package:chapechape_partner/core/services/api/residence_video_service.dart';

/// Section "Vidéo de présentation" dans l'onglet Médias du formulaire résidence.
///
/// Usage dans EditResidenceScreen :
///   - Créer un [ResidenceVideoService] et le passer via [videoService].
///   - Passer [residenceId] (null si création — upload désactivé).
///   - [existingVideoUrl] : URL de la vidéo actuelle si elle existe.
///   - [existingVideoId] : ID subdoc MongoDB de la vidéo existante.
///   - [onVideoUploaded] : callback quand l'upload réussit.
///   - [onVideoDeleted]  : callback quand la suppression réussit.
class ResidenceVideoSection extends StatefulWidget {
  final ResidenceVideoService videoService;
  final String? residenceId;
  final String? existingVideoUrl;
  final String? existingVideoId;
  final String? existingVideoStatus;
  final void Function(String url, String publicId)? onVideoUploaded;
  final VoidCallback? onVideoDeleted;

  const ResidenceVideoSection({
    super.key,
    required this.videoService,
    this.residenceId,
    this.existingVideoUrl,
    this.existingVideoId,
    this.existingVideoStatus,
    this.onVideoUploaded,
    this.onVideoDeleted,
  });

  @override
  State<ResidenceVideoSection> createState() => _ResidenceVideoSectionState();
}

class _ResidenceVideoSectionState extends State<ResidenceVideoSection> {
  bool _isUploading = false;
  bool _isDeleting = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  CancelToken? _cancelToken;
  VideoPlayerController? _previewController;
  bool _previewInitialized = false;

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  Future<bool> _requestVideoPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    Permission permission;
    if (Platform.isIOS) {
      permission = Permission.photos;
    } else {
      // Android 13+ : READ_MEDIA_VIDEO ; fallback READ_EXTERNAL_STORAGE
      final sdkVersion = await _getAndroidSdkVersion();
      permission = sdkVersion >= 33
          ? Permission.videos
          : Permission.storage;
    }

    final status = await permission.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permission refusée — impossible d\'accéder à la galerie vidéo'),
            action: SnackBarAction(
              label: 'Paramètres',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<int> _getAndroidSdkVersion() async {
    // Valeur conservative — la permission handler gère le fallback
    return 33;
  }

  // ---------------------------------------------------------------------------
  // Sélection + upload
  // ---------------------------------------------------------------------------

  Future<void> _pickAndUpload() async {
    if (widget.residenceId == null) {
      _showError(
        'Créez d\'abord la résidence avec le bouton Créer, '
        'puis ajoutez une vidéo ici (onglet Médias).',
      );
      return;
    }

    final hasPermission = await _requestVideoPermission();
    if (!hasPermission) return;

    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 90),
    );
    if (picked == null) return;

    final file = File(picked.path);

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
      _cancelToken = CancelToken();
    });

    try {
      final result = await widget.videoService.uploadVideo(
        residenceId: widget.residenceId!,
        videoFile: file,
        cancelToken: _cancelToken,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      widget.onVideoUploaded?.call(result.url, result.publicId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Vidéo envoyée — en attente de validation par l\'équipe ChapeChape'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _showError('Upload annulé.');
      } else {
        final code = e.response?.statusCode;
        final serverMsg = e.response?.data is Map
            ? (e.response!.data['message']?.toString())
            : null;
        _showError(
          code != null
              ? 'Erreur serveur ($code)${serverMsg != null ? ' : $serverMsg' : ''}'
              : 'Erreur réseau : ${e.message ?? e}',
        );
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _cancelUpload() {
    _cancelToken?.cancel('Annulé par l\'utilisateur');
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });
  }

  // ---------------------------------------------------------------------------
  // Suppression
  // ---------------------------------------------------------------------------

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la vidéo ?'),
        content: const Text(
          'La vidéo sera définitivement supprimée de la résidence.\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await widget.videoService.deleteVideo(
        residenceId: widget.residenceId!,
        videoId: widget.existingVideoId!,
      );
      widget.onVideoDeleted?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vidéo supprimée avec succès')),
        );
      }
    } catch (e) {
      _showError('Impossible de supprimer la vidéo : $e');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Preview
  // ---------------------------------------------------------------------------

  Future<void> _initPreview(String url) async {
    if (_previewInitialized) return;
    _previewController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _previewController!.initialize();
    if (mounted) setState(() => _previewInitialized = true);
  }

  void _togglePreview() {
    if (_previewController == null) return;
    setState(() {
      if (_previewController!.value.isPlaying) {
        _previewController!.pause();
      } else {
        _previewController!.play();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _showError(String msg) {
    if (mounted) setState(() => _errorMessage = msg);
  }

  Color _statusColor(String? status) => switch (status) {
        'approved'       => Colors.green,
        'rejected'       => Colors.red,
        'pending_review' => Colors.orange,
        _                => Colors.grey,
      };

  String _statusLabel(String? status) => switch (status) {
        'approved'       => 'Approuvée',
        'rejected'       => 'Rejetée',
        'pending_review' => 'En attente de validation',
        _                => 'Statut inconnu',
      };

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.enableResidenceVideo) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final hasVideo = widget.existingVideoUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre section
        Row(
          children: [
            const Icon(Icons.videocam_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              'Vidéo de présentation',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'MAX 90s',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ajoutez une courte vidéo (max 90 secondes) pour mettre en valeur votre résidence.\n'
          'Elle sera visible par les clients après validation par notre équipe.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        // État d'erreur
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _errorMessage = null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Barre de progression upload
        if (_isUploading) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _uploadProgress < 0.4
                        ? 'Compression en cours…'
                        : 'Upload en cours…',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '${(_uploadProgress * 100).round()}%',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _uploadProgress,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Annuler'),
                  onPressed: _cancelUpload,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Vidéo existante
        if (hasVideo && !_isUploading) ...[
          FutureBuilder(
            future: _initPreview(widget.existingVideoUrl!),
            builder: (context, snapshot) {
              return Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _previewInitialized && _previewController != null
                          ? VideoPlayer(_previewController!)
                          : Container(
                              color: Colors.black,
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                    ),
                  ),
                  // Bouton Play/Pause
                  if (_previewInitialized)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _togglePreview,
                        child: Center(
                          child: AnimatedOpacity(
                            opacity: _previewController!.value.isPlaying ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Badge statut
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(widget.existingVideoStatus),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel(widget.existingVideoStatus),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // Bouton supprimer
          OutlinedButton.icon(
            icon: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, size: 18),
            label: Text(_isDeleting ? 'Suppression…' : 'Supprimer la vidéo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: _isDeleting || widget.existingVideoId == null
                ? null
                : _confirmAndDelete,
          ),
        ],

        // Bouton ajouter (si pas de vidéo et pas en cours d'upload)
        if (!hasVideo && !_isUploading) ...[
          InkWell(
            onTap: _pickAndUpload,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajouter une vidéo',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MP4 / MOV — max 90s — depuis la galerie',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  ),
                  if (widget.residenceId == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Créez d\'abord la résidence (bouton Créer) — '
                      'la vidéo sera alors débloquée ici.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.orange),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}
