import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/booking/booking_event.dart' as booking_events;
import 'package:chapechape_client/core/blocs/booking/booking_state.dart' as booking_states;
import 'package:chapechape_client/core/blocs/residence/residence_bloc.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/extensions/model_extensions.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/presentation/widgets/booking/flexible_date_selector.dart';
import 'package:chapechape_client/presentation/widgets/booking/reservation_mode_banner.dart';

class BookingScreen extends StatefulWidget {
  final String residenceId;
  
  const BookingScreen({super.key, required this.residenceId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs du formulaire
  final _guestsController = TextEditingController(text: '1');
  
  // Dates de réservation
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  
  // Prix estimé
  double _estimatedPrice = 0;
  
  // Résidence à réserver
  Residence? _residence;
  
  // Disponibilité vérifiée
  bool _isAvailabilityChecked = false;
  bool _isAvailable = false;
  
  // Type de réservation (hourly, daily, weekly, monthly) - utilisé par FlexibleBookingDateSelector
  String _selectedBookingType = 'day';
  Map<String, dynamic> _pricingDetails = {};
  
  @override
  void initState() {
    super.initState();
    
    // Charger les détails de la résidence
    context.read<ResidenceBloc>().add(
      LoadResidenceDetails(residenceId: widget.residenceId)
    );
    
    // Initialiser les dates par défaut
    _checkInDate = DateTime.now().add(const Duration(days: 1));
    _checkOutDate = DateTime.now().add(const Duration(days: 3));
  }
  
  // Vérifier la disponibilité
  void _checkAvailability() {
    if (_checkInDate != null && _checkOutDate != null) {
      // Déboguer le residenceId
      debugPrint('Vérification de disponibilité pour residenceId: ${widget.residenceId}');
      
      // Vérifier si le residenceId est valide
      if (widget.residenceId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur: ID de résidence manquant')),
        );
        return;
      }
      
      context.read<BookingBloc>().add(
        booking_events.CheckResidenceAvailability(
          residenceId: widget.residenceId,
          checkIn: _checkInDate!,
          checkOut: _checkOutDate!,
        )
      );
    }
  }
  
  // Créer une réservation
  void _handleSubmit() {
    context.read<BookingBloc>().add(
      booking_events.CreateBooking(
        bookingData: {
          'residence': widget.residenceId,
          'checkIn': _checkInDate,
          'checkOut': _checkOutDate,
          'numberOfGuests': int.parse(_guestsController.text),
          'specialRequests': '',
          // ✅ Utiliser les nouvelles données de réservation flexible
          'bookingType': _selectedBookingType,
          'pricingDetails': _pricingDetails,
          'estimatedPrice': _estimatedPrice,
        },
      ),
    );
  }

  void _onBookingBlocListen(BuildContext context, booking_states.BookingState state) {
    if (state is booking_states.BookingCreated) {
      context.go('/booking-confirmation/${state.booking.id}');
    } else if (state is booking_states.BookingError) {
      String errorMessage = state.message;
      if (errorMessage.contains('n\'est pas disponible pour ces dates')) {
        errorMessage =
            'Cette résidence n\'est plus disponible pour les dates sélectionnées. Veuillez essayer d\'autres dates.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      if (errorMessage.contains('disponible')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isAvailabilityChecked = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSticky = _residence != null;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    // Espace pour la barre (~56px bouton + paddings 14*2) + safe area
    const stickyBarContentHeight = 72.0;
    final scrollBottomPad = AppSpacing.pagePadding.bottom +
        AppSpacing.lg +
        (showSticky ? stickyBarContentHeight + 28 + safeBottom : 0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        title: Text(
          'Réserver',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ),
      body: BlocListener<BookingBloc, booking_states.BookingState>(
        listenWhen: (prev, next) =>
            next is booking_states.BookingCreated || next is booking_states.BookingError,
        listener: _onBookingBlocListen,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SafeArea(
              bottom: !showSticky,
              child: LoadingOverlay(
                isLoading: _isLoadingState(context),
                child: SingleChildScrollView(
                  padding: AppSpacing.pagePadding.copyWith(
                    bottom: scrollBottomPad,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildResidenceInfo(),
                      AppSpacing.verticalLg,
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDateSelectionSection(),
                            AppSpacing.verticalLg,
                            _buildReservationModeSection(),
                            AppSpacing.verticalMd,
                            _buildGuestsField(),
                            AppSpacing.verticalLg,
                            _buildPriceSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (showSticky)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildStickyBookingBar(context),
              ),
          ],
        ),
      ),
    );
  }
  
  // Vérifier si un état de chargement est actif
  bool _isLoadingState(BuildContext context) {
    final bookingState = context.watch<BookingBloc>().state;
    final residenceState = context.watch<ResidenceBloc>().state;
    
    return bookingState is booking_states.BookingLoading || 
           residenceState is ResidenceLoading;
  }
  
  // Construire les informations sur la résidence
  Widget _buildResidenceInfo() {
    return BlocBuilder<ResidenceBloc, ResidenceState>(
      builder: (context, state) {
        if (state is ResidenceDetailsLoaded) {
          _residence = state.residence;
          
          // Mettre à jour le prix estimé
          // Calculer le prix par défaut SEULEMENT si aucun pricing flexible n'est déjà défini
          // (évite d'écraser le prix horaire/hebdo sélectionné par FlexibleBookingDateSelector)
          if (_residence != null && _checkInDate != null && _checkOutDate != null &&
              !_isAvailabilityChecked && _pricingDetails.isEmpty) {
            _estimatedPrice = _residence!.estimateTotalPrice(_checkInDate!, _checkOutDate!);
            _checkAvailability();
          }
          
          final theme = Theme.of(context);
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.10)),
            ),
            child: Padding(
              padding: AppSpacing.pagePadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ResidenceThumb(imageUrl: _residence!.imageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _residence!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Réserver',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.verticalSm,
                        Text(
                          _residence!.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                        AppSpacing.verticalSm,
                        Text(
                          _residence!.shortDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                            color: theme.colorScheme.onSurface.withOpacity(0.85),
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
        
        // État de chargement ou d'erreur
        return const Card(
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Center(
              child: Text('Chargement des informations...'),
            ),
          ),
        );
      },
    );
  }
  
  // Construire la section de sélection des dates
  Widget _buildDateSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dates de séjour',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        AppSpacing.verticalSm,
        
        // Utiliser FlexibleBookingDateSelector si la résidence est chargée
        if (_residence != null) ...[
          FlexibleBookingDateSelector(
            residence: _residence!,
            initialCheckIn: _checkInDate,
            initialCheckOut: _checkOutDate,
            onDatesSelected: (checkIn, checkOut, bookingType, pricing) {
              setState(() {
                _checkInDate = checkIn;
                _checkOutDate = checkOut;
                _selectedBookingType = bookingType;
                _pricingDetails = pricing;
                _estimatedPrice = pricing['price']?.toDouble() ?? 0;
                _isAvailabilityChecked = false;
              });
            },
          ),
        ] else ...[
          // Fallback vers l'ancien système si résidence pas encore chargée
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Arrivée',
                  date: _checkInDate,
                  onSelect: (date) {
                    setState(() {
                      _checkInDate = date;
                      _isAvailabilityChecked = false;
                      if (_checkOutDate != null && _checkOutDate!.isBefore(_checkInDate!)) {
                        _checkOutDate = _checkInDate!.add(const Duration(days: 1));
                      }
                    });
                  },
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDateField(
                  label: 'Départ',
                  date: _checkOutDate,
                  onSelect: (date) {
                    setState(() {
                      _checkOutDate = date;
                      _isAvailabilityChecked = false;
                    });
                  },
                  minDate: _checkInDate?.add(const Duration(days: 1)),
                ),
              ),
            ],
          ),
        ],
        
        // Bouton de vérification de disponibilité
        if (_checkInDate != null && _checkOutDate != null) ...[
          AppSpacing.verticalMd,
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _checkAvailability();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: const Text(
              'Vérifier la disponibilité',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        // Afficher le résultat de la vérification de disponibilité
        BlocListener<BookingBloc, booking_states.BookingState>(
          listener: (context, state) {
            if (state is booking_states.ResidenceAvailabilityChecked) {
              setState(() {
                _isAvailabilityChecked = true;
                _isAvailable = state.isAvailable;
                // ✅ CORRECTION : Ne pas écraser le prix flexible calculé par FlexibleBookingDateSelector
                // Seulement utiliser le prix backend si aucun pricing flexible n'est défini
                if (state.price != null && _pricingDetails.isEmpty) {
                  _estimatedPrice = state.price!;
                }
              });
            }
          },
          child: _isAvailabilityChecked
              ? Padding(
                  padding: EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.smd),
                        decoration: BoxDecoration(
                          color: _isAvailable 
                              ? AppTheme.successColor.withOpacity(0.1) 
                              : AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: _isAvailable ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isAvailable ? Icons.check_circle : Icons.error,
                                  color: _isAvailable ? AppTheme.successColor : AppTheme.errorColor,
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _isAvailable
                                        ? 'Résidence disponible pour les dates sélectionnées!'
                                        : 'Cette résidence n\'est pas disponible pour ces dates',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _isAvailable ? AppTheme.successColor : AppTheme.errorColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!_isAvailable) ...[  
                              AppSpacing.verticalSm,
                              Text(
                                'Essayez de sélectionner d\'autres dates ou une autre résidence.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              SizedBox(height: AppSpacing.smd),
                              OutlinedButton(
                                onPressed: () async {
                                  // Proposer de nouvelles dates (date d'aujourd'hui + 7 jours)
                                  final newStartDate = DateTime.now().add(const Duration(days: 7));
                                  final newEndDate = newStartDate.add(const Duration(days: 3));
                                  
                                  setState(() {
                                    _checkInDate = newStartDate;
                                    _checkOutDate = newEndDate;
                                    _isAvailabilityChecked = false;
                                  });
                                  
                                  // Vérifier automatiquement la disponibilité pour ces nouvelles dates
                                  _checkAvailability();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).primaryColor,
                                ),
                                child: const Text('Essayer des dates dans 1 semaine'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
  
  // Construire un champ de sélection de date
  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required Function(DateTime) onSelect,
    DateTime? minDate,
  }) {
    return InkWell(
      onTap: () async {
        HapticFeedback.selectionClick();
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: minDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        
        if (selectedDate != null) {
          onSelect(selectedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
        ),
        child: Text(
          date != null
              ? DateFormat('dd/MM/yyyy').format(date)
              : 'Sélectionner une date',
        ),
      ),
    );
  }
  
  // Construire la section de sélection du mode de réservation
  Widget _buildReservationModeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode de Réservation',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.verticalSm,
        Text(
          'Mode de réservation défini par le partenaire',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        AppSpacing.verticalMd,
        // ✅ CORRECTION CRITIQUE : Bannière informative au lieu du sélecteur
        if (_residence != null)
          ReservationModeBanner(
            reservationMode: _residence!.reservationMode,
            onInfoTap: () {
              showDialog(
                context: context,
                builder: (_) => const ReservationModeInfoDialog(),
              );
            },
          ),
        
        // L'information du mode est déjà affichée dans ReservationModeBanner
      ],
    );
  }

  
  // Construire le champ pour le nombre d'invités
  Widget _buildGuestsField() {
    return TextFormField(
      controller: _guestsController,
      decoration: InputDecoration(
        labelText: 'Nombre de personnes',
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
        prefixIcon: Icon(Icons.people_outline, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer le nombre de personnes';
        }
        final guests = int.tryParse(value);
        if (guests == null || guests < 1) {
          return 'Le nombre de personnes doit être au moins 1';
        }
        final maxGuests = _residence?.maxOccupancy;
        if (maxGuests != null && guests > maxGuests) {
          return 'Capacité maximale: $maxGuests personnes';
        }
        return null;
      },
    );
  }
  
  // Construire la section du prix
  Widget _buildPriceSection() {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails du prix',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            AppSpacing.verticalMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Prix total', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '${_estimatedPrice.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_checkInDate != null && _checkOutDate != null)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  _buildDurationLabel(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// Barre bas fixe (comme la fiche résidence) : prix seul + CTA or/noir.
  Widget _buildStickyBookingBar(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final safe = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: onSurface.withOpacity(0.12), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(24, 14, 24, safe + 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${_estimatedPrice.toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isAvailable
                  ? () {
                      HapticFeedback.heavyImpact();
                      _handleSubmit();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.4),
                disabledForegroundColor: Colors.black.withOpacity(0.6),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                minimumSize: const Size(0, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: const Text(
                'Réserver maintenant',
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, height: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Libellé durée aligné sur `bookingType` + `details` du sélecteur flexible.
  String _buildDurationLabel() {
    Map<String, dynamic>? details;
    var bookingType = _selectedBookingType;

    if (_pricingDetails.isNotEmpty) {
      final bt = _pricingDetails['bookingType'];
      if (bt is String && bt.isNotEmpty) {
        bookingType = bt;
      }
      final raw = _pricingDetails['details'];
      if (raw is Map<String, dynamic>) {
        details = raw;
      }

      switch (bookingType) {
        case 'hour':
          final h = details?['hours'] as int?;
          if (h != null && h > 0) {
            return 'Pour $h heure${h > 1 ? 's' : ''}';
          }
          break;
        case 'day':
          final dayType = details?['dayType'] as String?;
          if (dayType == 'half') return 'Pour une demi-journée';
          if (dayType == 'weekend') return 'Pour le weekend';
          if (dayType == 'full') return 'Pour une journée complète';
          return 'Pour une journée complète';
        case 'week':
          return 'Pour 1 semaine';
        case 'month':
          return 'Pour 1 mois';
        default:
          break;
      }
    }

    if (_checkInDate != null && _checkOutDate != null) {
      if (bookingType == 'hour') {
        final hours = _checkOutDate!.difference(_checkInDate!).inHours;
        if (hours > 0) {
          return 'Pour $hours heure${hours > 1 ? 's' : ''}';
        }
      }
      if (bookingType == 'day') {
        return 'Pour une journée complète';
      }
      final nights = _checkOutDate!.difference(_checkInDate!).inDays;
      if (nights > 0) {
        return 'Pour $nights nuit${nights > 1 ? 's' : ''}';
      }
    }
    return '';
  }

  @override
  void dispose() {
    _guestsController.dispose();
    super.dispose();
  }
}

class _ResidenceThumb extends StatelessWidget {
  final String imageUrl;

  const _ResidenceThumb({required this.imageUrl});

  bool get _isNetwork =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    final radius = BorderRadius.circular(12);
    if (_isNetwork) {
      return ClipRRect(
        borderRadius: radius,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: size,
            height: size,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => _fallback(context, size, radius),
        ),
      );
    }
    return _fallback(context, size, radius);
  }

  Widget _fallback(BuildContext context, double size, BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: imageUrl.startsWith('assets/')
            ? Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.home_work_outlined),
              )
            : const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}