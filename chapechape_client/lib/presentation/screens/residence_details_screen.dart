import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chapechape_maps/chapechape_maps.dart';

import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/blocs/auth/auth_state.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/booking/booking_bloc.dart';
import '../../core/models/residence_model.dart';
import '../../core/services/booking_service.dart';
import '../../core/services/residence_service.dart';
import '../screens/booking_screen.dart';
import '../widgets/skeletons/residence_details_skeleton.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kPrimary   = Color(0xFF222222);
const _kSecondary = Color(0xFF717171);
const _kDivider   = Color(0xFFDDDDDD);
const _kRed       = Color(0xFFFF385C);
const _kGreen     = Color(0xFF008A05);
const _kBg        = Colors.white;

// ── Typographie commune ───────────────────────────────────────────────────────
const _kSectionTitle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: _kPrimary,
  letterSpacing: -0.2,
);

const _kBody = TextStyle(fontSize: 14, color: _kPrimary, height: 1.55);
const _kCaption = TextStyle(fontSize: 12, color: _kSecondary);

// ─────────────────────────────────────────────────────────────────────────────
class ResidenceDetailsScreen extends StatefulWidget {
  final String residenceId;
  const ResidenceDetailsScreen({super.key, required this.residenceId});

  @override
  State<ResidenceDetailsScreen> createState() => _ResidenceDetailsScreenState();
}

class _ResidenceDetailsScreenState extends State<ResidenceDetailsScreen> {
  final _pageCtrl       = PageController();
  final _commentCtrl    = TextEditingController();

  int    _currentPhoto  = 0;
  int    _reviewKey     = 0;
  double _myRating      = 5.0;
  bool   _showAllAmenities = false;

  late final LocationService _locationService;
  LatLng? _userLocation;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _fetchLocation();
    context.read<ResidenceBloc>().add(
      LoadResidenceDetails(residenceId: widget.residenceId),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      final p = await _locationService.getCurrentPosition();
      if (mounted) setState(() => _userLocation = LatLng(p.latitude, p.longitude));
    } catch (_) {}
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.read<ResidenceBloc>().add(const RefreshResidencesEvent());
        return true;
      },
      child: Scaffold(
        backgroundColor: _kBg,
        body: BlocBuilder<ResidenceBloc, ResidenceState>(
          builder: (ctx, state) {
            if (state is ResidenceLoading) return const ResidenceDetailsSkeleton();
            if (state is ResidenceDetailsLoaded) return _buildBody(state.residence);
            if (state is ResidenceError) {
              return Center(
                child: Text(state.message, style: _kBody),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildBody(Residence r) {
    return Stack(
      children: [
        // ── Contenu scrollable ──────────────────────────────────────────────
        CustomScrollView(
          slivers: [
            _buildGallerySliver(r),
            SliverToBoxAdapter(child: _buildScrollContent(r)),
          ],
        ),
        // ── Boutons overlay photo (retour + favoris + partage) ──────────────
        _buildPhotoOverlay(r),
        // ── Barre sticky bas (prix + bouton réserver) ───────────────────────
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _buildBottomBar(r),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GALERIE PHOTO
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGallerySliver(Residence r) {
    return SliverAppBar(
      expandedHeight: 310,
      pinned: false,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _buildGallery(r),
      ),
    );
  }

  Widget _buildGallery(Residence r) {
    if (r.images.isEmpty) {
      return Container(
        color: const Color(0xFFF0F0F0),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 56, color: _kSecondary),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // Photos swipeables
        PageView.builder(
          controller: _pageCtrl,
          physics: const PageScrollPhysics(),
          onPageChanged: (i) => setState(() => _currentPhoto = i),
          itemCount: r.images.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => _openGallery(context, r.images, i),
            child: CachedNetworkImage(
              imageUrl: r.images[i],
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: const Color(0xFFF0F0F0)),
              errorWidget: (_, __, ___) => Container(color: const Color(0xFFF0F0F0)),
            ),
          ),
        ),
        // Dégradé bas
        Positioned(
          left: 0, right: 0, bottom: 0, height: 70,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.38)],
              ),
            ),
          ),
        ),
        // Dots indicateur
        if (r.images.length > 1)
          Positioned(
            bottom: 14, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                r.images.length.clamp(0, 8),
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  _currentPhoto == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPhoto == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        // Compteur "2 / 7"
        Positioned(
          bottom: 14, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.48),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentPhoto + 1} / ${r.images.length}',
              style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoOverlay(Residence r) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16, right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleBtn(Icons.arrow_back, () {
            context.read<ResidenceBloc>().add(const RefreshResidencesEvent());
            Navigator.pop(context);
          }),
          Row(children: [
            _circleBtn(Icons.share_outlined, () {}),
            const SizedBox(width: 10),
            BlocBuilder<AuthBloc, dynamic>(
              builder: (_, __) => _circleBtn(
                r.isFavorite ? Icons.favorite : Icons.favorite_border,
                () {
                  if (_isAuth()) {
                    context.read<ResidenceBloc>().add(ToggleFavorite(residenceId: r.id));
                  } else {
                    _showAuthDialog();
                  }
                },
                iconColor: r.isFavorite ? _kRed : _kPrimary,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color iconColor = _kPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 8),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CONTENU PRINCIPAL
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScrollContent(Residence r) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(r),
              _sep(),
              _sectionStats(r),
              _sep(),
              _sectionBadges(r),
              _sep(),
              _sectionDescription(r),
              _sep(),
              _sectionAmenities(r),
              if (_hasRates(r)) ...[_sep(), _sectionRates(r)],
              _sep(),
              _sectionRules(r),
              if (r.paymentMethods.isNotEmpty) ...[_sep(), _sectionPayment(r)],
            ],
          ),
        ),
        // Localisation (carte pleine largeur)
        _sep(padding: const EdgeInsets.symmetric(horizontal: 24)),
        _sectionLocation(r),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sep(),
              _sectionReviews(r),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sep({EdgeInsets padding = const EdgeInsets.symmetric(vertical: 24)}) {
    return Padding(
      padding: padding,
      child: const Divider(height: 1, thickness: 1, color: _kDivider),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TITRE + TYPE + LOCALISATION + NOTE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _sectionTitle(Residence r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type · Ville
        Text(
          '${r.type.displayName} · ${_shortCity(r)}',
          style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w400,
            color: _kSecondary, letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 6),
        // Titre
        Text(r.title, style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w600,
          color: _kPrimary, height: 1.25,
        )),
        const SizedBox(height: 12),
        // Note + avis + adresse courte
        Row(
          children: [
            const Icon(Icons.star, size: 14, color: _kPrimary),
            const SizedBox(width: 4),
            Text(
              r.rating > 0 ? r.rating.toStringAsFixed(1) : 'Nouveau',
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            if (r.reviewCount > 0) ...[
              Text(
                '  ·  ${r.reviewCount} avis',
                style: const TextStyle(
                  fontSize: 13, color: _kSecondary,
                  decoration: TextDecoration.underline),
              ),
            ],
            const Spacer(),
            const Icon(Icons.location_on_outlined, size: 13, color: _kSecondary),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                _shortLocation(r),
                style: const TextStyle(
                  fontSize: 12, color: _kSecondary,
                  decoration: TextDecoration.underline),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS : chambres / sdb / m² / occupants
  // ══════════════════════════════════════════════════════════════════════════
  Widget _sectionStats(Residence r) {
    return IntrinsicHeight(
      child: Row(
        children: [
          _statItem(Icons.king_bed_outlined,
              '${r.bedrooms}',
              r.bedrooms > 1 ? 'chambres' : 'chambre'),
          _vLine(),
          _statItem(Icons.bathtub_outlined,
              '${r.bathrooms}',
              r.bathrooms > 1 ? 'salles de bain' : 'salle de bain'),
          _vLine(),
          if (r.squareMeters > 0) ...[
            _statItem(Icons.straighten, '${r.squareMeters.toInt()}', 'm²'),
            _vLine(),
          ],
          _statItem(Icons.people_outline,
              '${r.maxOccupancy}',
              r.maxOccupancy > 1 ? 'pers. max' : 'personne'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: _kPrimary),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 2),
          Text(label, style: _kCaption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _vLine() => Container(
    width: 1, margin: const EdgeInsets.symmetric(vertical: 4),
    color: _kDivider,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // BADGES : mode réservation + disponibilité
  // ══════════════════════════════════════════════════════════════════════════
  Widget _sectionBadges(Residence r) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        if (r.reservationMode == 'instant')
          _badge(Icons.flash_on_outlined, 'Réservation instantanée',
              const Color(0xFF008A05), const Color(0xFFE8F5E9))
        else
          _badge(Icons.pending_outlined, 'Sur approbation de l\'hôte',
              const Color(0xFF795548), const Color(0xFFFFF8E1)),
        if (r.isAvailable)
          _badge(Icons.check_circle_outline, 'Disponible',
              const Color(0xFF008A05), const Color(0xFFE8F5E9))
        else
          _badge(Icons.cancel_outlined, 'Non disponible',
              const Color(0xFFB71C1C), const Color(0xFFFFEBEE)),
      ],
    );
  }

  Widget _badge(IconData icon, String label, Color fgColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fgColor),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: fgColor)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DESCRIPTION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _sectionDescription(Residence r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description', style: _kSectionTitle),
        const SizedBox(height: 14),
        ExpandableText(
          r.description,
          expandText: 'Lire plus',
          collapseText: 'Réduire',
          maxLines: 4,
          linkColor: _kPrimary,
          linkStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: _kPrimary, decoration: TextDecoration.underline,
          ),
          style: _kBody,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ÉQUIPEMENTS
  // ══════════════════════════════════════════════════════════════════════════
  static const _amenityIcons = <String, IconData>{
    'wifi': Icons.wifi, 'tv': Icons.tv,
    'air_conditioning': Icons.ac_unit, 'heating': Icons.whatshot_outlined,
    'kitchen': Icons.restaurant, 'full_kitchen': Icons.restaurant,
    'kitchenette': Icons.microwave_outlined, 'pool': Icons.pool,
    'hot_tub': Icons.hot_tub, 'parking': Icons.local_parking,
    'balcony': Icons.deck, 'terrace': Icons.deck, 'garden': Icons.yard,
    'gym': Icons.fitness_center, 'security': Icons.security,
    'running_water': Icons.water_drop_outlined, 'water_tank': Icons.water_outlined,
    'hot_water': Icons.hot_tub, 'electricity': Icons.bolt,
    'generator': Icons.power, 'solar_energy': Icons.solar_power,
    'inverter': Icons.electrical_services, 'fiber_optic': Icons.wifi_tethering,
    'ethernet': Icons.lan, 'security_guard': Icons.person_outlined,
    'cctv': Icons.videocam_outlined, 'alarm_system': Icons.alarm,
    'refrigerator': Icons.kitchen, 'microwave': Icons.microwave_outlined,
    'oven': Icons.local_fire_department_outlined, 'fan': Icons.air,
    'ceiling_fan': Icons.air, 'spa': Icons.spa,
    'restaurant': Icons.restaurant, 'bar': Icons.local_bar,
    'room_service': Icons.room_service, 'laundry': Icons.local_laundry_service,
    'meeting_room': Icons.meeting_room, 'cleaning': Icons.cleaning_services,
  };

  static const _amenityLabels = <String, String>{
    'wifi': 'WiFi', 'tv': 'Télévision', 'air_conditioning': 'Climatisation',
    'heating': 'Chauffage', 'kitchen': 'Cuisine',
    'full_kitchen': 'Cuisine complète', 'kitchenette': 'Kitchenette',
    'pool': 'Piscine', 'hot_tub': 'Jacuzzi', 'parking': 'Parking',
    'balcony': 'Balcon', 'terrace': 'Terrasse', 'garden': 'Jardin',
    'gym': 'Salle de sport', 'security': 'Sécurité',
    'running_water': 'Eau courante', 'water_tank': "Réservoir d'eau",
    'hot_water': 'Eau chaude', 'electricity': 'Électricité',
    'generator': 'Générateur', 'solar_energy': 'Énergie solaire',
    'inverter': 'Onduleur', 'fiber_optic': 'Fibre optique',
    'ethernet': 'Ethernet', 'security_guard': 'Gardien 24h',
    'cctv': 'Caméras de surveillance', 'alarm_system': "Système d'alarme",
    'refrigerator': 'Réfrigérateur', 'microwave': 'Micro-ondes',
    'oven': 'Four', 'fan': 'Ventilateur',
    'ceiling_fan': 'Ventilateur de plafond', 'spa': 'Spa',
    'restaurant': 'Restaurant', 'bar': 'Bar',
    'room_service': 'Room service', 'laundry': 'Buanderie',
    'meeting_room': 'Salle de réunion', 'cleaning': 'Ménage',
  };

  Widget _sectionAmenities(Residence r) {
    if (r.amenities.isEmpty) return const SizedBox.shrink();

    final all      = r.amenities;
    final preview  = _showAllAmenities ? all : all.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ce que propose ce logement', style: _kSectionTitle),
        const SizedBox(height: 16),
        ...preview.map((a) {
          final key = a.toLowerCase();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(_amenityIcons[key] ?? Icons.check_circle_outline,
                    size: 22, color: _kPrimary),
                const SizedBox(width: 16),
                Text(_amenityLabels[key] ?? a, style: _kBody),
              ],
            ),
          );
        }),
        if (all.length > 6) ...[
          const SizedBox(height: 4),
          _outlineBtn(
            _showAllAmenities
                ? 'Réduire'
                : 'Voir les ${all.length} équipements',
            () => setState(() => _showAllAmenities = !_showAllAmenities),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TARIFS
  // ══════════════════════════════════════════════════════════════════════════
  bool _hasRates(Residence r) =>
      r.hourlyRate > 0 || r.halfDayRate > 0 || r.fullDayRate > 0;

  Widget _sectionRates(Residence r) {
    final fmt = NumberFormat.currency(
      locale: 'fr_FR', symbol: r.currency, decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tarification', style: _kSectionTitle),
        const SizedBox(height: 16),
        _rateRow('Tarif principal',
            fmt.format(r.price), _fmtPeriod(r.pricePeriod)),
        if (r.hourlyRate > 0) ...[
          const SizedBox(height: 16),
          const Text('Tarifs horaires',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: _kSecondary)),
          const SizedBox(height: 10),
          _rateRow('1 heure', fmt.format(r.hourlyRate), ''),
        ],
        if (r.halfDayRate > 0 || r.fullDayRate > 0 || r.weekendRate > 0) ...[
          const SizedBox(height: 16),
          const Text('Tarifs journaliers',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: _kSecondary)),
          const SizedBox(height: 10),
          if (r.halfDayRate > 0)
            _rateRow('Demi-journée', fmt.format(r.halfDayRate), ''),
          if (r.fullDayRate > 0)
            _rateRow('Journée complète', fmt.format(r.fullDayRate), ''),
          if (r.weekendRate > 0)
            _rateRow('Week-end', fmt.format(r.weekendRate), ''),
        ],
      ],
    );
  }

  Widget _rateRow(String label, String amount, String suffix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label, style: _kBody),
          const Spacer(),
          Text(
            suffix.isNotEmpty ? '$amount $suffix' : amount,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RÈGLES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _sectionRules(Residence r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Règles du logement', style: _kSectionTitle),
        const SizedBox(height: 16),
        _ruleRow(Icons.pets_outlined, 'Animaux de compagnie', r.allowsPets),
        _ruleRow(Icons.smoke_free, 'Fumeurs', r.allowsSmoking),
        _ruleRow(Icons.celebration_outlined, 'Fêtes et événements', r.allowsParties),
      ],
    );
  }

  Widget _ruleRow(IconData icon, String label, bool allowed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _kPrimary),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: _kBody)),
          Row(
            children: [
              Icon(
                allowed
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                size: 17,
                color: allowed ? _kGreen : _kSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                allowed ? 'Autorisé' : 'Non autorisé',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: allowed ? _kGreen : _kSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAIEMENT
  // ══════════════════════════════════════════════════════════════════════════
  static const _paymentIcons = <String, IconData>{
    'cash': Icons.payments_outlined,
    'wave': Icons.account_balance_wallet_outlined,
    'orange_money': Icons.account_balance_wallet_outlined,
    'moov_money': Icons.account_balance_wallet_outlined,
    'mtn_money': Icons.account_balance_wallet_outlined,
    'credit_card': Icons.credit_card_outlined,
    'bank_transfer': Icons.account_balance_outlined,
  };
  static const _paymentLabels = <String, String>{
    'cash': 'Espèces', 'wave': 'Wave',
    'orange_money': 'Orange Money', 'moov_money': 'Moov Money',
    'mtn_money': 'MTN Money', 'credit_card': 'Carte bancaire',
    'bank_transfer': 'Virement bancaire',
  };

  Widget _sectionPayment(Residence r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Paiement accepté', style: _kSectionTitle),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: r.paymentMethods.map((m) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kDivider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_paymentIcons[m] ?? Icons.payments_outlined,
                      size: 18, color: _kPrimary),
                  const SizedBox(width: 8),
                  Text(_paymentLabels[m] ?? m,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500,
                          color: _kPrimary)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOCALISATION + CARTE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _sectionLocation(Residence r) {
    final coords = r.coordinates;
    final hasCoords = coords.length >= 2 &&
        (coords[0] != 0.0 || coords[1] != 0.0);
    final lat = hasCoords ? coords[1] : null;
    final lng = hasCoords ? coords[0] : null;
    final addr = r.formattedAddress.isNotEmpty ? r.formattedAddress : r.address;

    String? distanceText;
    if (_userLocation != null && lat != null && lng != null) {
      try {
        final km = _locationService.calculateDistance(
          _userLocation!, LatLng(lat, lng)) / 1000;
        distanceText = km < 1
            ? '${(km * 1000).toStringAsFixed(0)} m de vous'
            : '${km.toStringAsFixed(1)} km de vous';
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: const Text('Localisation', style: _kSectionTitle),
        ),
        // Carte pleine largeur
        if (lat != null && lng != null)
          SizedBox(
            height: 220,
            child: GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: LatLng(lat, lng), zoom: 14),
              markers: {
                Marker(
                  markerId: const MarkerId('r'),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(title: r.title),
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onTap: (_) => _openFullMap(lat, lng, r),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (addr.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 18, color: _kSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(addr,
                        style: const TextStyle(
                            fontSize: 14, color: _kSecondary, height: 1.4))),
                  ],
                ),
              if (distanceText != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.near_me_outlined, size: 16, color: _kSecondary),
                    const SizedBox(width: 8),
                    Text(distanceText, style: _kCaption),
                  ],
                ),
              ],
              if (lat != null && lng != null) ...[
                const SizedBox(height: 16),
                _outlineBtn(
                  'Obtenir l\'itinéraire',
                  () => _launchMaps(lat, lng, r.title),
                  icon: Icons.directions_outlined,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AVIS + FORMULAIRE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _sectionReviews(Residence r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête note globale
        Row(
          children: [
            const Icon(Icons.star, size: 20, color: _kPrimary),
            const SizedBox(width: 6),
            Text(
              r.rating > 0 ? r.rating.toStringAsFixed(1) : 'Nouveau',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            if (r.reviewCount > 0)
              Text(
                '  ·  ${r.reviewCount} avis',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
          ],
        ),
        const SizedBox(height: 20),
        // Formulaire ou invite connexion
        if (_isAuth())
          _buildReviewForm(r)
        else
          _buildLoginPrompt(),
        const SizedBox(height: 24),
        // Liste des avis
        FutureBuilder<Map<String, dynamic>>(
          key: ValueKey(_reviewKey),
          future: _loadReviews(r.id),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kPrimary),
                ),
              );
            }
            final reviews =
                (snap.data?['data']?['reviews'] as List?) ?? [];
            if (reviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('Aucun avis pour le moment',
                      style: const TextStyle(fontSize: 14, color: _kSecondary)),
                ),
              );
            }
            return Column(
              children: [
                ...reviews
                    .take(3)
                    .map((rv) => _reviewItem(rv as Map<String, dynamic>)),
                if (reviews.length > 3) ...[
                  const SizedBox(height: 8),
                  _outlineBtn(
                    'Voir les ${reviews.length} avis',
                    () => Navigator.pushNamed(context, '/reviews/${r.id}'),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return GestureDetector(
      onTap: () => context.push('/auth/login'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: _kDivider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F0F0), shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, color: _kSecondary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Connectez-vous pour laisser un avis',
                style: TextStyle(fontSize: 14, color: _kSecondary),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm(Residence r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _kDivider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Votre note',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _myRating = i + 1.0),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  i < _myRating ? Icons.star : Icons.star_border,
                  size: 30, color: _kPrimary,
                ),
              ),
            )),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            style: _kBody,
            decoration: InputDecoration(
              hintText: 'Partagez votre expérience…',
              hintStyle: const TextStyle(fontSize: 14, color: _kSecondary),
              contentPadding: const EdgeInsets.all(14),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kDivider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kDivider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _kPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _submitReview(r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Publier',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewItem(Map<String, dynamic> review) {
    final user    = review['user']   as Map<String, dynamic>? ?? {};
    final ratingM = review['rating'] as Map<String, dynamic>? ?? {};
    final score   = (ratingM['overall'] as num?)?.toDouble() ?? 0.0;
    final comment = review['comment'] as String? ?? '';
    final name    = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final date    = _fmtDate(
      review['updatedAt'] as String? ?? review['createdAt'] as String?);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF0F0F0),
                child: Text(initial, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: _kPrimary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isNotEmpty ? name : 'Utilisateur',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: _kPrimary)),
                    Text(date, style: _kCaption),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 13, color: _kPrimary),
                  const SizedBox(width: 3),
                  Text(score.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: _kPrimary)),
                ],
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment, style: _kBody),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BARRE STICKY BAS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomBar(Residence r) {
    final fmt = NumberFormat.currency(
      locale: 'fr_FR', symbol: r.currency, decimalDigits: 0);
    final safe = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _kDivider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, -3)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 14, 24, safe + 14),
      child: Row(
        children: [
          // Prix + période + mode
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: fmt.format(r.price),
                        style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: _kPrimary),
                      ),
                      TextSpan(
                        text: ' ${_fmtPeriod(r.pricePeriod)}',
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w400,
                          color: _kSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.reservationMode == 'instant'
                      ? '⚡ Confirmation immédiate'
                      : '⏳ Sur approbation',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Bouton Réserver (rouge) ou Se connecter (or)
          GestureDetector(
            onTap: r.id.isEmpty ? null : () => _goBooking(r),
            child: _isAuth()
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF385C), Color(0xFFE31C5F)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Réserver',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Se connecter',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A))),
                  ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WIDGETS COMMUNS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _outlineBtn(String label, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: _kPrimary, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: _kPrimary),
              const SizedBox(width: 8),
            ],
            Text(label, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════
  bool _isAuth() {
    try { return context.read<AuthBloc>().state is Authenticated; }
    catch (_) { return false; }
  }

  String _shortCity(Residence r) {
    final c = r.city;
    return c.length <= 3 ? (r.address.isNotEmpty ? r.address : c) : c;
  }

  String _shortLocation(Residence r) {
    final a = r.formattedAddress;
    if (a.isNotEmpty &&
        a != 'Adresse non disponible' &&
        a != 'Adresse non spécifiée') {
      final parts = a.split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length >= 2) return '${parts[0]}, ${parts[1]}';
      if (parts.isNotEmpty) return parts[0];
    }
    return _shortCity(r);
  }

  String _fmtPeriod(String p) {
    switch (p) {
      case 'hour':  return '/heure';
      case 'day':   return '/jour';
      case 'week':  return '/semaine';
      case 'month': return '/mois';
      default:      return '';
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null) return 'Récemment';
    try {
      final d    = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inDays > 30)  return 'Il y a ${(diff.inDays / 30).floor()} mois';
      if (diff.inDays > 7)   return 'Il y a ${(diff.inDays / 7).floor()} semaines';
      if (diff.inDays > 0)   return 'Il y a ${diff.inDays} j';
      if (diff.inHours > 0)  return 'Il y a ${diff.inHours}h';
      return "À l'instant";
    } catch (_) { return 'Récemment'; }
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Connexion requise',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: const Text(
          'Connectez-vous pour réserver ou mettre cette résidence en favoris.',
          style: TextStyle(fontSize: 14, color: _kSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: _kSecondary)),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); context.go('/login'); },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Se connecter',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _goBooking(Residence r) async {
    if (!_isAuth()) { _showAuthDialog(); return; }
    final svc = await BookingService.initialize();
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => BookingBloc(bookingService: svc)),
          BlocProvider.value(value: context.read<ResidenceBloc>()),
        ],
        child: BookingScreen(residenceId: r.id),
      ),
    ));
  }

  void _openFullMap(double lat, double lng, Residence r) {
    context.push('/map-fullscreen', extra: {
      'lat': lat, 'lng': lng,
      'title': r.title, 'residenceId': r.id,
    });
  }

  Future<void> _launchMaps(double lat, double lng, String title) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _submitReview(Residence r) async {
    final comment = _commentCtrl.text.trim();
    if (comment.isEmpty) return;
    try {
      final svc = await ResidenceService.initialize();
      final ok  = await svc.submitReview(
          residenceId: r.id, rating: _myRating, comment: comment);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci pour votre avis !'),
            backgroundColor: _kGreen));
        _commentCtrl.clear();
        setState(() { _myRating = 5.0; _reviewKey++; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<Map<String, dynamic>> _loadReviews(String id) async {
    try {
      final svc = await ResidenceService.initialize();
      return await svc.getResidenceReviews(id, limit: 5);
    } catch (_) { return {}; }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// GALERIE PLEIN ÉCRAN
// ═════════════════════════════════════════════════════════════════════════════
void _openGallery(
    BuildContext context, List<String> images, int initialIndex) {
  if (images.isEmpty) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => GalleryViewerScreen(
          images: images, initialIndex: initialIndex),
    ),
  );
}

class GalleryViewerScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const GalleryViewerScreen(
      {Key? key, required this.images, required this.initialIndex})
      : super(key: key);
  @override
  State<GalleryViewerScreen> createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<GalleryViewerScreen> {
  late int _cur;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _cur  = widget.initialIndex;
    _ctrl = PageController(initialPage: _cur);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_cur + 1} / ${widget.images.length}',
            style: const TextStyle(
                fontSize: 16, color: Colors.white,
                fontWeight: FontWeight.w500)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _ctrl,
        onPageChanged: (i) => setState(() => _cur = i),
        itemCount: widget.images.length,
        itemBuilder: (_, i) => InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: widget.images[i],
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
