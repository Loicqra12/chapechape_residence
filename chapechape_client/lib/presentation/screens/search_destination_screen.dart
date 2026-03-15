import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/places_service.dart';
import '../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Données locales — communes et quartiers CI
// ---------------------------------------------------------------------------

const _localPlaces = [
  _LocalPlace('Cocody', 'Abidjan'),
  _LocalPlace('Angré', 'Cocody, Abidjan'),
  _LocalPlace('Riviera', 'Cocody, Abidjan'),
  _LocalPlace('Deux Plateaux', 'Cocody, Abidjan'),
  _LocalPlace('Angré Djibi', 'Cocody, Abidjan'),
  _LocalPlace('Angré 8ème tranche', 'Cocody, Abidjan'),
  _LocalPlace('Plateau', 'Abidjan'),
  _LocalPlace('Marcory', 'Abidjan'),
  _LocalPlace('Zone 4', 'Marcory, Abidjan'),
  _LocalPlace('Yopougon', 'Abidjan'),
  _LocalPlace('Adjamé', 'Abidjan'),
  _LocalPlace('Treichville', 'Abidjan'),
  _LocalPlace('Koumassi', 'Abidjan'),
  _LocalPlace('Port-Bouët', 'Abidjan'),
  _LocalPlace('Bingerville', 'Grand Abidjan'),
  _LocalPlace('Abobo', 'Abidjan'),
  _LocalPlace('Grand Bassam', 'Sud Comoé'),
  _LocalPlace('Assinie', 'Sud Comoé'),
  _LocalPlace('Bassam Quartier France', 'Grand Bassam'),
  _LocalPlace('Yamoussoukro', 'Capitale'),
  _LocalPlace('Bouaké', 'Gbêkê'),
  _LocalPlace('San-Pédro', 'San-Pédro'),
  _LocalPlace('Abengourou', "N'Zi Comoé"),
  _LocalPlace('Man', 'Tonkpi'),
  _LocalPlace('Daloa', 'Haut-Sassandra'),
];

class _LocalPlace {
  final String label;
  final String sub;
  const _LocalPlace(this.label, this.sub);
}

// ---------------------------------------------------------------------------
// Résultat retourné au formulaire
// ---------------------------------------------------------------------------

class DestinationResult {
  final String city;
  final String displayName;
  final String? placeId;

  const DestinationResult({
    required this.city,
    required this.displayName,
    this.placeId,
  });
}

// ---------------------------------------------------------------------------
// Écran plein-écran de recherche de destination
// ---------------------------------------------------------------------------

class SearchDestinationScreen extends StatefulWidget {
  const SearchDestinationScreen({Key? key}) : super(key: key);

  @override
  State<SearchDestinationScreen> createState() =>
      _SearchDestinationScreenState();
}

class _SearchDestinationScreenState extends State<SearchDestinationScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final PlacesService _service = PlacesService();

  List<PlacePrediction> _apiResults = [];
  List<_LocalPlace> _localResults = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  bool _apiWorking = true; // devient false si l'API échoue
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecent();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final list = await _service.getRecentSearches();
    if (mounted) setState(() => _recentSearches = list);
  }

  // Recherche locale dans _localPlaces
  List<_LocalPlace> _searchLocal(String q) {
    final query = q.toLowerCase().trim();
    if (query.isEmpty) return [];
    return _localPlaces.where((p) {
      return p.label.toLowerCase().contains(query) ||
          p.sub.toLowerCase().contains(query);
    }).toList();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final q = _controller.text.trim();

    if (q.isEmpty) {
      setState(() {
        _apiResults = [];
        _localResults = [];
        _isLoading = false;
      });
      return;
    }

    // Recherche locale immédiate
    setState(() {
      _localResults = _searchLocal(q);
      _isLoading = q.length >= 2;
    });

    if (q.length < 2) return;

    // Appel API avec debounce
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final results = await _service.autocomplete(q);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (results.isNotEmpty) {
          _apiResults = results;
          _apiWorking = true;
        } else {
          // API ne répond pas → on reste sur les résultats locaux
          _apiResults = [];
          _apiWorking = false;
        }
      });
    });
  }

  // --- Sélection ---

  Future<void> _selectApi(PlacePrediction p) async {
    await _service.addRecentSearch(p.description);
    if (!mounted) return;
    Navigator.of(context).pop(DestinationResult(
      city: p.mainText,
      displayName: p.description,
      placeId: p.placeId,
    ));
  }

  Future<void> _selectLocal(_LocalPlace p) async {
    final display = '${p.label}, ${p.sub}';
    await _service.addRecentSearch(display);
    if (!mounted) return;
    Navigator.of(context).pop(DestinationResult(
      city: p.label,
      displayName: display,
    ));
  }

  void _selectRecent(String recent) {
    Navigator.of(context).pop(DestinationResult(
      city: recent.split(',').first.trim(),
      displayName: recent,
    ));
  }

  Future<void> _useCurrentLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (!mounted) return;
      Navigator.of(context).pop(const DestinationResult(
        city: 'Ma position',
        displayName: 'À proximité',
      ));
    } catch (_) {}
  }

  Future<void> _clearRecent() async {
    await _service.clearRecentSearches();
    if (mounted) setState(() => _recentSearches = []);
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.5), width: 1.5),
          ),
          child: Row(
            children: [
              // Flèche retour à l'intérieur du champ
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_back,
                      size: 20, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              // Séparateur vertical
              Container(width: 1, height: 22, color: AppTheme.dividerColor),
              // Champ de texte
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une résidence...',
                    hintStyle:
                        TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontSize: 15),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                ),
              ),
              // Bouton effacer
              if (_controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() {
                      _apiResults = [];
                      _localResults = [];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 14, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ),
              if (_controller.text.isEmpty) const SizedBox(width: 12),
            ],
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.dividerColor),
      ),
    );
  }

  Widget _buildBody() {
    final query = _controller.text.trim();

    if (query.isEmpty) return _buildDefaultContent();

    // Pendant le chargement API → afficher d'abord les résultats locaux
    final showLocal = _localResults.isNotEmpty;
    final showApi = _apiResults.isNotEmpty;

    if (!showLocal && !showApi && !_isLoading) {
      return _buildEmpty(query);
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),

        // Résultats API Google Places
        if (showApi) ...[
          ..._apiResults.map((p) => _buildApiTile(p, query)),
        ]
        // Fallback résultats locaux
        else if (showLocal) ...[
          ..._localResults.map((p) => _buildLocalTile(p, query)),
        ],
      ],
    );
  }

  // --- Vue par défaut (aucune saisie) ---

  Widget _buildDefaultContent() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildTile(
          icon: Icons.near_me_outlined,
          iconBg: AppTheme.primaryColor.withOpacity(0.1),
          iconColor: AppTheme.primaryColor,
          title: 'À proximité',
          subtitle: 'Utiliser ma position actuelle',
          onTap: _useCurrentLocation,
        ),

        const Divider(height: 1, indent: 16),

        if (_recentSearches.isNotEmpty) ...[
          _sectionHeader(
            'Recherches récentes',
            action: GestureDetector(
              onTap: _clearRecent,
              child: Text(
                'Effacer',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            ),
          ),
          ..._recentSearches.map((r) => _buildTile(
                icon: Icons.history,
                iconBg: AppTheme.dividerColor,
                iconColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                title: r.split(',').first.trim(),
                subtitle: r,
                onTap: () => _selectRecent(r),
              )),
          const Divider(height: 1, indent: 16),
        ],

        _sectionHeader('Communes populaires'),
        ..._localPlaces.take(10).map((p) => _buildTile(
              icon: Icons.location_city_outlined,
              iconBg: AppTheme.dividerColor,
              iconColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              title: p.label,
              subtitle: p.sub,
              onTap: () => _selectLocal(p),
            )),
      ],
    );
  }

  Widget _buildEmpty(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          'Aucun résultat pour "$query"',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontSize: 15),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // --- Tuile résultat Google Places (avec texte en gras sur la partie matchée) ---

  Widget _buildApiTile(PlacePrediction p, String query) {
    return InkWell(
      onTap: () => _selectApi(p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _iconBox(
              Icons.location_on_outlined,
              Theme.of(context).colorScheme.surfaceContainerLow,
              AppTheme.primaryColor,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _highlightText(p.mainText, query,
                      baseStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  if (p.secondaryText.isNotEmpty)
                    Text(
                      p.secondaryText,
                      style:
                          TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tuile résultat local ---

  Widget _buildLocalTile(_LocalPlace p, String query) {
    return InkWell(
      onTap: () => _selectLocal(p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _iconBox(
              Icons.location_on_outlined,
              Theme.of(context).colorScheme.surfaceContainerLow,
              Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _highlightText(p.label, query,
                      baseStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  Text(
                    p.sub,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tuile générique ---

  Widget _buildTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _iconBox(icon, iconBg, iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- En-tête de section ---

  Widget _sectionHeader(String title, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              )),
          if (action != null) action,
        ],
      ),
    );
  }

  // --- Icône dans un carré arrondi ---

  Widget _iconBox(IconData icon, Color bg, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  // --- Texte avec la partie matchée en gras (style Airbnb) ---

  Widget _highlightText(String text, String query,
      {required TextStyle baseStyle}) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx < 0) return Text(text, style: baseStyle);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + q.length),
            style: baseStyle.copyWith(fontWeight: FontWeight.w800),
          ),
          if (idx + q.length < text.length)
            TextSpan(text: text.substring(idx + q.length)),
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
