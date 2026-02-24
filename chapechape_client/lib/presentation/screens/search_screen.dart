import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/models/residence_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/custom_marker_generator.dart';
import '../widgets/skeletons/search_result_skeleton.dart';
import '../widgets/search_filters_sheet.dart';
import 'package:chapechape_client/presentation/widgets/common/empty_state_widget.dart';

// Abidjan par défaut
const _defaultCenter = LatLng(5.3599517, -4.0082563);

// ---------------------------------------------------------------------------
// Bouton favori avec animation — style Airbnb
// ---------------------------------------------------------------------------
class _FavoriteIcon extends StatefulWidget {
  const _FavoriteIcon();

  @override
  State<_FavoriteIcon> createState() => _FavoriteIconState();
}

class _FavoriteIconState extends State<_FavoriteIcon>
    with SingleTickerProviderStateMixin {
  bool _isFaved = false;
  late final AnimationController _anim;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1, end: 1.3)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _isFaved = !_isFaved);
    _anim.forward().then((_) => _anim.reverse());
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Icon(
              _isFaved ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: _isFaved ? const Color(0xFFFF385C) : const Color(0xFF222222),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Carousel de photos sur la carte — style Airbnb
// ---------------------------------------------------------------------------
class _PhotoCarousel extends StatefulWidget {
  final List<String> images;
  final double height;

  const _PhotoCarousel({required this.images, this.height = 220});

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            // ── PageView des photos ─────────────────────────────────────
            PageView.builder(
              controller: _controller,
              physics: const PageScrollPhysics(),
              itemCount: images.isEmpty ? 1 : images.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, i) {
                final url = images.isEmpty ? null : images[i];
                return url != null && url.startsWith('http')
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: widget.height,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder();
              },
            ),

            // ── Points indicateurs ──────────────────────────────────────
            if (images.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length > 10 ? 10 : images.length,
                    (i) {
                      final active = i == _currentIndex ||
                          (i == 9 && _currentIndex >= 9);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: active ? 7 : 5,
                        height: active ? 7 : 5,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.55),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_outlined, size: 40, color: Colors.grey),
        ),
      );
}

class SearchScreen extends StatefulWidget {
  final String? category;
  final String? types;
  final Map<String, dynamic>? initialSearchParams;

  const SearchScreen({
    super.key,
    this.category,
    this.types,
    this.initialSearchParams,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Map<String, dynamic> _filters = {};
  SearchFilters _activeFilters = const SearchFilters();
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _isSheetExpanded = false;
  Residence? _selectedMarkerResidence;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());

    _sheetController.addListener(() {
      final expanded = _sheetController.size > 0.75;
      if (expanded != _isSheetExpanded) {
        setState(() => _isSheetExpanded = expanded);
      }
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _init() {
    if (widget.initialSearchParams != null &&
        widget.initialSearchParams!.isNotEmpty) {
      setState(() => _filters = widget.initialSearchParams!);
      context.read<ResidenceBloc>().add(
            SearchResidencesEvent(filters: widget.initialSearchParams!),
          );
    } else if (widget.types != null && widget.types!.isNotEmpty) {
      final typesList = widget.types!.split(',');
      setState(() {
        _filters = {
          'typesList': typesList,
          'category': widget.category ?? 'Résultats',
        };
      });
      context
          .read<ResidenceBloc>()
          .add(SearchResidencesEvent(filters: _filters));
    } else {
      // Charger TOUTES les résidences par défaut
      context
          .read<ResidenceBloc>()
          .add(const SearchResidencesEvent(filters: {}));
    }
  }

  Future<void> _buildMarkers(List<Residence> residences) async {
    final newMarkers = <Marker>{};
    for (final r in residences) {
      final lat = r.latitude;
      final lng = r.longitude;
      if (lat == null || lng == null) continue;
      try {
        final icon = await CustomMarkerGenerator.createPriceMarker(
          price: r.price,
        );
        newMarkers.add(Marker(
          markerId: MarkerId(r.id),
          position: LatLng(lat, lng),
          icon: icon,
          consumeTapEvents: true,
          onTap: () => _onMarkerTapped(r),
        ));
      } catch (_) {
        newMarkers.add(Marker(
          markerId: MarkerId(r.id),
          position: LatLng(lat, lng),
          consumeTapEvents: true,
          onTap: () => _onMarkerTapped(r),
        ));
      }
    }
    if (mounted) setState(() => _markers = newMarkers);
  }

  void _onMarkerTapped(Residence r) {
    setState(() => _selectedMarkerResidence = r);
    // Réduire le sheet pour que la carte soit visible
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.10,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  /// Carte flottante affichée au-dessus du sheet quand un marqueur est tapé
  Widget _buildMarkerCard(Residence r) {
    return GestureDetector(
      onTap: () => context.push('/residence/${r.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 110,
                height: 90,
                child: r.images.isNotEmpty
                    ? Image.network(r.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey[200], child: const Icon(Icons.home)))
                    : Container(color: Colors.grey[200], child: const Icon(Icons.home)),
              ),
            ),
            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Type + Ville
                    Text(
                      '${r.type.displayName} · ${_shortLocation(r)}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF555555)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Titre
                    Text(
                      r.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Note
                    if (r.rating > 0)
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 13, color: Color(0xFF1A1A1A)),
                          const SizedBox(width: 3),
                          Text(
                            r.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    // Prix
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Color(0xFF1A1A1A)),
                        children: [
                          TextSpan(
                            text: _formatPrice(r.price),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline),
                          ),
                          TextSpan(
                            text: ' ${_formatPeriod(r.pricePeriod)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bouton fermer
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedMarkerResidence = null),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: Colors.grey[100], shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 14, color: Color(0xFF555555)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilters(int totalResults) async {
    final result = await showSearchFiltersSheet(
      context,
      currentFilters: _activeFilters,
      totalResults: totalResults,
    );
    if (result == null || !mounted) return;

    setState(() => _activeFilters = result);

    // Fusionner les filtres de base (ville, etc.) avec les nouveaux filtres
    final merged = <String, dynamic>{
      ..._filters,
      ...result.toFilterMap(),
    };
    context
        .read<ResidenceBloc>()
        .add(SearchResidencesEvent(filters: merged));
  }

  String _buildFilterSummary() {
    final parts = <String>[];
    if (_filters['city'] != null) parts.add(_filters['city'] as String);

    final periodMap = {
      'hour': 'À l\'heure',
      'day': 'À la journée',
      'week': 'À la semaine',
      'month': 'Au mois',
    };
    final period = _activeFilters.period ?? _filters['period'] as String?;
    if (period != null) parts.add(periodMap[period] ?? period);

    if (_activeFilters.residenceCategory != null) {
      const catMap = {
        'meublee': 'Meublées',
        'hotel': 'Hôtels',
        'insolite': 'Insolites',
        'colocation': 'Colocation',
        'longue_duree': 'Longue durée',
        'economique': 'Économiques',
      };
      parts.add(catMap[_activeFilters.residenceCategory] ??
          _activeFilters.residenceCategory!);
    }

    if (parts.isEmpty) return 'Toutes les résidences';
    return parts.join(' · ');
  }

  String _formatPrice(double price) {
    return NumberFormat.compact(locale: 'fr_FR').format(price) + ' FCFA';
  }

  String _formatPeriod(String? period) {
    switch (period) {
      case 'hour': return '/h';
      case 'day': return '/jour';
      case 'week': return '/sem';
      case 'month': return '/mois';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<ResidenceBloc, ResidenceState>(
        listener: (context, state) {
          if (state is ResidencesLoaded) {
            _buildMarkers(state.residences);
          }
        },
        builder: (context, state) {
          final residences =
              state is ResidencesLoaded ? state.residences : <Residence>[];
          final isLoading = state is ResidenceLoading;

          return Stack(
            children: [
              // ── Carte plein écran en fond ──────────────────────────────
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _defaultCenter,
                    zoom: 12,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (ctrl) => _mapController = ctrl,
                  onTap: (_) => setState(() => _selectedMarkerResidence = null),
                ),
              ),

              // ── AppBar flottant ────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            // Retour
                            IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Color(0xFF1A1A1A), size: 22),
                              onPressed: () => context.go('/home'),
                            ),
                            // Résumé des filtres
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _buildFilterSummary(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (residences.isNotEmpty)
                                    Text(
                                      '${residences.length} résidence${residences.length > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Bouton filtres
                            GestureDetector(
                              onTap: () => _openFilters(residences.length),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _activeFilters.isEmpty
                                        ? Colors.grey[300]!
                                        : const Color(0xFF1A1A1A),
                                    width: _activeFilters.isEmpty ? 1 : 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: _activeFilters.isEmpty
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.tune,
                                        color: _activeFilters.isEmpty
                                            ? const Color(0xFF1A1A1A)
                                            : Colors.white,
                                        size: 18),
                                    if (!_activeFilters.isEmpty) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${_activeFilters.activeCount}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Carte flottante marqueur sélectionné ─────────────────
              if (_selectedMarkerResidence != null)
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.12 + 8,
                  left: 0,
                  right: 0,
                  child: _buildMarkerCard(_selectedMarkerResidence!),
                ),

              // ── DraggableScrollableSheet ───────────────────────────────
              DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: 0.45,
                minChildSize: 0.10,
                maxChildSize: 1.0,
                snap: true,
                snapSizes: const [0.10, 0.45, 1.0],
                builder: (context, scrollController) {
                  return DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    // CustomScrollView avec le même controller pour tout
                    // (handle + header + liste) → le glissement vers le bas
                    // fonctionne depuis n'importe quelle zone du panel
                    child: CustomScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        // ── Handle + compteur ──────────────────────────
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              // Drag handle
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              // Compteur
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 12),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          residences.isEmpty
                                              ? 'Aucune résidence trouvée'
                                              : 'Plus de ${residences.length} résidence${residences.length > 1 ? 's' : ''}',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        // ── Contenu ────────────────────────────────────
                        if (isLoading && residences.isEmpty)
                          const SliverFillRemaining(
                            child: SearchResultSkeleton(itemCount: 3),
                          )
                        else if (residences.isEmpty)
                          SliverFillRemaining(child: _buildEmpty())
                        else
                          SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _buildCard(residences[i]),
                                childCount: residences.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Carte résidence ──────────────────────────────────────────────────

  Widget _buildCard(Residence residence) {
    final imageUrl = residence.imageUrl;
    final hasValidImage = imageUrl != null && imageUrl.startsWith('http');
    final photos = residence.images.isNotEmpty
        ? residence.images
        : (hasValidImage ? [imageUrl!] : <String>[]);

    void navigate() {
      HapticFeedback.selectionClick();
      context.push('/residence/${residence.id}');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Carousel + bouton cœur ─────────────────────────────────────
          // GestureDetector ici gère uniquement les TAPS (pas les drags).
          // Le PageView interne reçoit les drags horizontaux sans conflit.
          GestureDetector(
            onTap: navigate,
            child: Stack(
              children: [
                _PhotoCarousel(images: photos),
                const Positioned(
                  top: 12,
                  right: 12,
                  child: _FavoriteIcon(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Informations (zone tappable séparée) ──────────────────────
          GestureDetector(
            onTap: navigate,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ligne 1 : Type · Ville  |  ★ note (avis)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${residence.type.displayName} · ${_shortLocation(residence)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (residence.rating > 0) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFF222222)),
                      const SizedBox(width: 2),
                      Text(
                        '${residence.rating.toStringAsFixed(1)}'
                        '${residence.reviewCount > 0 ? ' (${residence.reviewCount})' : ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 3),

                // Ligne 2 : Titre de la résidence
                Text(
                  residence.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF555555),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 3),

                // Ligne 3 : Surface m² · Chambres · Salles de bain
                Text(
                  _buildPropertyInfo(residence),
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),

                const SizedBox(height: 7),

                // Ligne 4 : Prix + badge mode de réservation
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF222222)),
                          children: [
                            TextSpan(
                              text: _formatPrice(residence.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(
                              text: ' ${_formatPeriod(residence.pricePeriod)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (residence.reservationMode == 'instant')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.bolt,
                              size: 13, color: Color(0xFF2196F3)),
                          SizedBox(width: 2),
                          Text(
                            'Instantané',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  /// Retourne une localisation courte lisible depuis formattedAddress
  /// Ex: "Riviera 3, Cocody, Abidjan, CI" → "Riviera 3, Cocody"
  String _shortLocation(Residence r) {
    final formatted = r.formattedAddress;
    if (formatted.isNotEmpty &&
        formatted != 'Adresse non disponible' &&
        formatted != 'Adresse non spécifiée') {
      final parts = formatted
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length >= 2) return '${parts[0]}, ${parts[1]}';
      if (parts.isNotEmpty) return parts[0];
    }
    // Fallback : si city est un code court (≤3 car), on retourne juste address
    final city = r.city;
    if (city.length <= 3) {
      final addr = r.address;
      return addr.isNotEmpty ? addr : city;
    }
    return city;
  }

  /// Ligne "Xm² · X ch · X sdb" — caractéristiques immobilières
  String _buildPropertyInfo(Residence r) {
    final parts = <String>[];
    if (r.squareMeters > 0) {
      parts.add('${r.squareMeters.toStringAsFixed(0)} m²');
    }
    if (r.bedrooms > 0) {
      parts.add('${r.bedrooms} ch');
    }
    if (r.bathrooms > 0) {
      parts.add('${r.bathrooms} sdb');
    }
    return parts.join(' · ');
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.apartment, size: 48, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildEmpty() {
    return EmptyStateWidget(
      imagePath:
          'assets/images/empty_states/empty_search_illustration.png',
      title: 'Aucune résidence trouvée',
      subtitle: 'Essayez avec d\'autres critères',
      fallbackIcon: Icons.search_off,
      action: ElevatedButton.icon(
        onPressed: () => context.go('/home'),
        icon: const Icon(Icons.home),
        label: const Text('Retour à l\'accueil'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
