import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Modèle de filtres
// ---------------------------------------------------------------------------

class SearchFilters {
  // Période
  final String? period; // hour | day | week | month

  // Type de résidence (catégorie)
  final String? residenceCategory; // meublee | hotel | insolite | colocation | longue_duree | economique

  // Prix
  final double minPrice;
  final double maxPrice;

  // Chambres / Salles de bain (0 = Tout)
  final int minBedrooms;
  final int minBathrooms;

  // Équipements sélectionnés
  final List<String> amenities;

  // Règles
  final bool? allowsPets;
  final bool? allowsSmoking;
  final bool? allowsParties;

  // Mode de réservation
  final bool instantOnly; // reservationMode == 'instant'

  // Note minimale
  final double minRating; // 0 = Tout

  const SearchFilters({
    this.period,
    this.residenceCategory,
    this.minPrice = 5000,
    this.maxPrice = 5000000,
    this.minBedrooms = 0,
    this.minBathrooms = 0,
    this.amenities = const [],
    this.allowsPets,
    this.allowsSmoking,
    this.allowsParties,
    this.instantOnly = false,
    this.minRating = 0,
  });

  bool get isEmpty =>
      period == null &&
      residenceCategory == null &&
      minPrice == 5000 &&
      maxPrice == 5000000 &&
      minBedrooms == 0 &&
      minBathrooms == 0 &&
      amenities.isEmpty &&
      allowsPets == null &&
      allowsSmoking == null &&
      allowsParties == null &&
      !instantOnly &&
      minRating == 0;

  int get activeCount {
    int c = 0;
    if (period != null) c++;
    if (residenceCategory != null) c++;
    if (minPrice != 5000 || maxPrice != 5000000) c++;
    if (minBedrooms > 0) c++;
    if (minBathrooms > 0) c++;
    if (amenities.isNotEmpty) c += amenities.length;
    if (allowsPets == true) c++;
    if (allowsSmoking == true) c++;
    if (allowsParties == true) c++;
    if (instantOnly) c++;
    if (minRating > 0) c++;
    return c;
  }

  /// Convertit en Map compatible avec ResidenceBloc
  Map<String, dynamic> toFilterMap() {
    return {
      if (period != null) 'period': period,
      if (residenceCategory != null) 'residenceCategory': residenceCategory,
      if (minPrice != 5000) 'minPrice': minPrice,
      if (maxPrice != 5000000) 'maxPrice': maxPrice,
      if (minBedrooms > 0) 'minBedrooms': minBedrooms,
      if (minBathrooms > 0) 'minBathrooms': minBathrooms,
      if (amenities.isNotEmpty) 'amenities': amenities,
      if (allowsPets != null) 'allowsPets': allowsPets,
      if (allowsSmoking != null) 'allowsSmoking': allowsSmoking,
      if (allowsParties != null) 'allowsParties': allowsParties,
      if (instantOnly) 'reservationMode': 'instant',
      if (minRating > 0) 'minRating': minRating,
    };
  }

  // Copie avec nouveaux champs non-nullables uniquement.
  SearchFilters copyWith({
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? minBathrooms,
    List<String>? amenities,
    bool? instantOnly,
    double? minRating,
  }) {
    return SearchFilters(
      period: period,
      residenceCategory: residenceCategory,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      minBathrooms: minBathrooms ?? this.minBathrooms,
      amenities: amenities ?? this.amenities,
      allowsPets: allowsPets,
      allowsSmoking: allowsSmoking,
      allowsParties: allowsParties,
      instantOnly: instantOnly ?? this.instantOnly,
      minRating: minRating ?? this.minRating,
    );
  }

  // Méthodes explicites pour les champs nullables (toggle on/off).
  SearchFilters withPeriod(String? v) => SearchFilters(
        period: v,
        residenceCategory: residenceCategory,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minBedrooms: minBedrooms,
        minBathrooms: minBathrooms,
        amenities: amenities,
        allowsPets: allowsPets,
        allowsSmoking: allowsSmoking,
        allowsParties: allowsParties,
        instantOnly: instantOnly,
        minRating: minRating,
      );

  SearchFilters withCategory(String? v) => SearchFilters(
        period: period,
        residenceCategory: v,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minBedrooms: minBedrooms,
        minBathrooms: minBathrooms,
        amenities: amenities,
        allowsPets: allowsPets,
        allowsSmoking: allowsSmoking,
        allowsParties: allowsParties,
        instantOnly: instantOnly,
        minRating: minRating,
      );

  SearchFilters withAllowsPets(bool? v) => SearchFilters(
        period: period,
        residenceCategory: residenceCategory,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minBedrooms: minBedrooms,
        minBathrooms: minBathrooms,
        amenities: amenities,
        allowsPets: v,
        allowsSmoking: allowsSmoking,
        allowsParties: allowsParties,
        instantOnly: instantOnly,
        minRating: minRating,
      );

  SearchFilters withAllowsSmoking(bool? v) => SearchFilters(
        period: period,
        residenceCategory: residenceCategory,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minBedrooms: minBedrooms,
        minBathrooms: minBathrooms,
        amenities: amenities,
        allowsPets: allowsPets,
        allowsSmoking: v,
        allowsParties: allowsParties,
        instantOnly: instantOnly,
        minRating: minRating,
      );

  SearchFilters withAllowsParties(bool? v) => SearchFilters(
        period: period,
        residenceCategory: residenceCategory,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minBedrooms: minBedrooms,
        minBathrooms: minBathrooms,
        amenities: amenities,
        allowsPets: allowsPets,
        allowsSmoking: allowsSmoking,
        allowsParties: v,
        instantOnly: instantOnly,
        minRating: minRating,
      );
}

// ---------------------------------------------------------------------------
// Données statiques des filtres
// ---------------------------------------------------------------------------

const _periods = [
  _PeriodOption('hour', 'À l\'heure', Icons.access_time),
  _PeriodOption('day', 'À la journée', Icons.wb_sunny_outlined),
  _PeriodOption('week', 'À la semaine', Icons.date_range_outlined),
  _PeriodOption('month', 'Au mois', Icons.calendar_month_outlined),
];

const _categories = [
  _CategoryOption('meublee', 'Meublées', Icons.chair_outlined),
  _CategoryOption('hotel', 'Hôtels', Icons.hotel_outlined),
  _CategoryOption('insolite', 'Insolites', Icons.cabin_outlined),
  _CategoryOption('colocation', 'Colocation', Icons.people_outline),
  _CategoryOption('longue_duree', 'Longue durée', Icons.home_work_outlined),
  _CategoryOption('economique', 'Économiques', Icons.savings_outlined),
];

const _amenityOptions = [
  _AmenityOption('wifi', 'WiFi', Icons.wifi),
  _AmenityOption('pool', 'Piscine', Icons.pool),
  _AmenityOption('air_conditioning', 'Climatisation', Icons.ac_unit),
  _AmenityOption('parking', 'Parking', Icons.local_parking),
  _AmenityOption('kitchen', 'Cuisine', Icons.kitchen_outlined),
  _AmenityOption('gym', 'Salle de sport', Icons.fitness_center),
  _AmenityOption('security', 'Sécurité 24/7', Icons.security),
  _AmenityOption('tv', 'Télévision', Icons.tv),
  _AmenityOption('spa', 'Spa', Icons.spa_outlined),
  _AmenityOption('balcony', 'Balcon', Icons.balcony_outlined),
  _AmenityOption('terrace', 'Terrasse', Icons.deck_outlined),
  _AmenityOption('generator', 'Générateur', Icons.power),
  _AmenityOption('washing_machine', 'Lave-linge', Icons.local_laundry_service),
  _AmenityOption('restaurant', 'Restaurant', Icons.restaurant),
  _AmenityOption('room_service', 'Service en chambre', Icons.room_service),
];

class _PeriodOption {
  final String value;
  final String label;
  final IconData icon;
  const _PeriodOption(this.value, this.label, this.icon);
}

class _CategoryOption {
  final String value;
  final String label;
  final IconData icon;
  const _CategoryOption(this.value, this.label, this.icon);
}

class _AmenityOption {
  final String value;
  final String label;
  final IconData icon;
  const _AmenityOption(this.value, this.label, this.icon);
}

// ---------------------------------------------------------------------------
// Sheet de filtres
// ---------------------------------------------------------------------------

/// Ouvrir le panneau de filtres.
/// Utilise PageRouteBuilder(opaque: false) pour éviter le bug Flutter
/// '_RenderBottomSheetLayoutWithSizeListener' / '!_debugDoingThisLayout'
/// qui survient avec showModalBottomSheet dans un contexte go_router/ShellRoute.
Future<SearchFilters?> showSearchFiltersSheet(
  BuildContext context, {
  required SearchFilters currentFilters,
  int totalResults = 0,
}) {
  return Navigator.of(context, rootNavigator: true).push<SearchFilters>(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => _SearchFiltersPage(
        initialFilters: currentFilters,
        totalResults: totalResults,
      ),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ),
  );
}

/// Page transparente avec panneau de filtres animé depuis le bas.
/// N'utilise PAS showModalBottomSheet pour éviter le bug Flutter
/// _RenderBottomSheetLayoutWithSizeListener dans les contextes go_router.
class _SearchFiltersPage extends StatefulWidget {
  final SearchFilters initialFilters;
  final int totalResults;

  const _SearchFiltersPage({
    required this.initialFilters,
    required this.totalResults,
  });

  @override
  State<_SearchFiltersPage> createState() => _SearchFiltersPageState();
}

class _SearchFiltersPageState extends State<_SearchFiltersPage> {
  late SearchFilters _filters;
  bool _showAllAmenities = false;

  static const double _minPrice = 5000;
  static const double _maxPrice = 5000000;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  String _formatPrice(double v) =>
      NumberFormat.compact(locale: 'fr_FR').format(v) + ' FCFA';

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // SizedBox.expand() force le Stack à occuper tout l'écran,
    // ce qui garantit des contraintes bornées pour Positioned(left:0,right:0).
    // Sans ça, PageRouteBuilder(opaque:false) peut passer des contraintes
    // non-bornées → Column/Row sans largeur → RenderBox not laid out.
    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Zone de dismiss en appuyant à l'extérieur
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),

            // Panneau de filtres ancré en bas
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: mq.size.height * 0.92,
              child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // ── Handle ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 2),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // ── Header ──────────────────────────────────────
                  _buildHeader(),

                  // ── Contenu scrollable ───────────────────────────
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      children: [
                        _section('Période de location', _buildPeriods()),
                        _divider(),
                        _section('Type de résidence', _buildCategories()),
                        _divider(),
                        _section('Fourchette de prix', _buildPriceSlider()),
                        _divider(),
                        _section('Chambres & Salles de bain', _buildCounters()),
                        _divider(),
                        _section('Équipements', _buildAmenities()),
                        _divider(),
                        _section('Règles', _buildRules()),
                        _divider(),
                        _section('Mode de réservation', _buildReservationMode()),
                        _divider(),
                        _section('Note minimale', _buildRating()),
                      ],
                    ),
                  ),

                  // ── Footer fixe ──────────────────────────────────
                  _buildFooter(mq.padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
      ),  // SizedBox.expand
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      child: Row(
        children: [
          const Text('Filtres',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A))),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ── Période ───────────────────────────────────────────────────────────────

  Widget _buildPeriods() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _periods.map((p) {
        final selected = _filters.period == p.value;
        return _PillChip(
          label: p.label,
          icon: p.icon,
          selected: selected,
          onTap: () => setState(() {
            _filters = _filters.withPeriod(selected ? null : p.value);
          }),
        );
      }).toList(),
    );
  }

  // ── Catégories ────────────────────────────────────────────────────────────

  Widget _buildCategories() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((c) {
        final selected = _filters.residenceCategory == c.value;
        return _PillChip(
          label: c.label,
          icon: c.icon,
          selected: selected,
          onTap: () => setState(() {
            _filters = _filters.withCategory(selected ? null : c.value);
          }),
        );
      }).toList(),
    );
  }

  // ── Prix ──────────────────────────────────────────────────────────────────

  Widget _buildPriceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PriceBox('Min', _formatPrice(_filters.minPrice)),
            _PriceBox('Max', _formatPrice(_filters.maxPrice)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: Colors.grey[200],
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.15),
            trackHeight: 3,
          ),
          child: RangeSlider(
            min: _minPrice,
            max: _maxPrice,
            divisions: 200,
            values: RangeValues(_filters.minPrice, _filters.maxPrice),
            onChanged: (v) => setState(() {
              _filters =
                  _filters.copyWith(minPrice: v.start, maxPrice: v.end);
            }),
          ),
        ),
      ],
    );
  }

  // ── Compteurs chambres / SdB ──────────────────────────────────────────────

  Widget _buildCounters() {
    return Column(
      children: [
        _CounterRow(
          label: 'Chambres',
          value: _filters.minBedrooms,
          onChanged: (v) =>
              setState(() => _filters = _filters.copyWith(minBedrooms: v)),
        ),
        const SizedBox(height: 14),
        _CounterRow(
          label: 'Salles de bain',
          value: _filters.minBathrooms,
          onChanged: (v) =>
              setState(() => _filters = _filters.copyWith(minBathrooms: v)),
        ),
      ],
    );
  }

  // ── Équipements ───────────────────────────────────────────────────────────

  Widget _buildAmenities() {
    final visible =
        _showAllAmenities ? _amenityOptions : _amenityOptions.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: visible.map((a) {
            final selected = _filters.amenities.contains(a.value);
            return _PillChip(
              label: a.label,
              icon: a.icon,
              selected: selected,
              onTap: () {
                final list = List<String>.from(_filters.amenities);
                selected ? list.remove(a.value) : list.add(a.value);
                setState(() =>
                    _filters = _filters.copyWith(amenities: list));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () =>
              setState(() => _showAllAmenities = !_showAllAmenities),
          child: Row(
            children: [
              Text(
                _showAllAmenities
                    ? 'Afficher moins'
                    : 'Afficher plus (${_amenityOptions.length - 6})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showAllAmenities
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Règles ────────────────────────────────────────────────────────────────

  Widget _buildRules() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _PillChip(
          label: 'Animaux acceptés',
          icon: Icons.pets,
          selected: _filters.allowsPets == true,
          onTap: () => setState(() => _filters =
              _filters.withAllowsPets(_filters.allowsPets == true ? null : true)),
        ),
        _PillChip(
          label: 'Tabac autorisé',
          icon: Icons.smoking_rooms,
          selected: _filters.allowsSmoking == true,
          onTap: () => setState(() => _filters =
              _filters.withAllowsSmoking(_filters.allowsSmoking == true ? null : true)),
        ),
        _PillChip(
          label: 'Fêtes autorisées',
          icon: Icons.celebration_outlined,
          selected: _filters.allowsParties == true,
          onTap: () => setState(() => _filters =
              _filters.withAllowsParties(_filters.allowsParties == true ? null : true)),
        ),
      ],
    );
  }

  // ── Mode de réservation ───────────────────────────────────────────────────

  Widget _buildReservationMode() {
    return _PillChip(
      label: 'Réservation instantanée',
      icon: Icons.flash_on,
      selected: _filters.instantOnly,
      onTap: () => setState(() => _filters =
          _filters.copyWith(instantOnly: !_filters.instantOnly)),
    );
  }

  // ── Note minimale ─────────────────────────────────────────────────────────

  Widget _buildRating() {
    return Row(
      children: [0.0, 3.0, 3.5, 4.0, 4.5].map((r) {
        final selected = _filters.minRating == r;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() =>
                _filters = _filters.copyWith(minRating: r)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF1A1A1A)
                      : Colors.grey[300]!,
                ),
              ),
              child: Text(
                r == 0 ? 'Tout' : '${r.toString()} ★',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Tout effacer
          TextButton(
            onPressed: () => setState(() =>
                _filters = const SearchFilters()),
            child: const Text(
              'Tout effacer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Spacer(),
          // Appliquer
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_filters),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                widget.totalResults > 0
                    ? 'Afficher ${widget.totalResults} résidence${widget.totalResults > 1 ? 's' : ''}'
                    : 'Appliquer les filtres',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _section(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: Colors.grey[200]);
}

// ---------------------------------------------------------------------------
// Widgets réutilisables
// ---------------------------------------------------------------------------

class _PillChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color:
                selected ? const Color(0xFF1A1A1A) : Colors.grey[300]!,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _CounterRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF1A1A1A))),
        ),
        _CountBtn(
          icon: Icons.remove,
          enabled: value > 0,
          onTap: () => onChanged(value - 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            value == 0 ? 'Tout' : '$value+',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A)),
          ),
        ),
        _CountBtn(
          icon: Icons.add,
          enabled: value < 10,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CountBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: enabled ? Colors.grey[400]! : Colors.grey[200]!),
        ),
        child: Icon(icon,
            size: 18,
            color: enabled ? const Color(0xFF1A1A1A) : Colors.grey[300]),
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final String value;

  const _PriceBox(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}
