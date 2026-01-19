import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/booking/booking_event.dart' as booking_events;
import 'package:chapechape_client/core/blocs/booking/booking_state.dart' as booking_states;
import 'package:chapechape_client/core/blocs/residence/residence_bloc.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/extensions/model_extensions.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réserver'),
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoadingState(context),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Informations sur la résidence
              _buildResidenceInfo(),
              
              const SizedBox(height: 24),
              
              // Formulaire de réservation
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDateSelectionSection(),
                    const SizedBox(height: 24),
                    _buildReservationModeSection(),
                    const SizedBox(height: 16),
                    _buildGuestsField(),
                    const SizedBox(height: 24),
                    _buildPriceSection(),
                    const SizedBox(height: 24),
                    _buildBookingButton(),
                  ],
                ),
              ),
            ],
          ),
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
          if (_residence != null && _checkInDate != null && _checkOutDate != null && !_isAvailabilityChecked) {
            _estimatedPrice = _residence!.estimateTotalPrice(_checkInDate!, _checkOutDate!);
            _checkAvailability();
          }
          
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _residence!.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _residence!.address,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _residence!.shortDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }
        
        // État de chargement ou d'erreur
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
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
        const SizedBox(height: 8),
        
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
              const SizedBox(width: 16),
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              _checkAvailability();
            },
            child: const Text('Vérifier la disponibilité'),
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
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: _isAvailable 
                              ? AppTheme.successColor.withOpacity(0.1) 
                              : AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.0),
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
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isAvailable
                                        ? 'Résidence disponible pour les dates sélectionnées!'
                                        : 'Cette résidence n\'est pas disponible pour ces dates',
                                    style: TextStyle(
                                      color: _isAvailable ? AppTheme.successColor : AppTheme.errorColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!_isAvailable) ...[  
                              const SizedBox(height: 8),
                              const Text(
                                'Essayez de sélectionner d\'autres dates ou une autre résidence.',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 12),
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
          border: const OutlineInputBorder(),
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
        const SizedBox(height: 8),
        Text(
          'Mode de réservation défini par le partenaire',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
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
      decoration: const InputDecoration(
        labelText: 'Nombre de personnes',
        border: OutlineInputBorder(),
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
        return null;
      },
    );
  }
  
  // Construire la section du prix
  Widget _buildPriceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails du prix',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Prix total'),
                Text(
                  '${_estimatedPrice.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_checkInDate != null && _checkOutDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Pour ${_checkOutDate!.difference(_checkInDate!).inDays} nuits',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Construire le bouton de réservation
  Widget _buildBookingButton() {
    return BlocListener<BookingBloc, booking_states.BookingState>(
      listener: (context, state) {
        if (state is booking_states.BookingCreated) {
          // Rediriger vers l'écran de paiement ou de confirmation
          context.go('/booking-confirmation/${state.booking.id}');
        } else if (state is booking_states.BookingError) {
          // Afficher une erreur plus détaillée
          String errorMessage = state.message;
          
          // Traiter les messages d'erreur spécifiques
          if (errorMessage.contains('n\'est pas disponible pour ces dates')) {
            errorMessage = 'Cette résidence n\'est plus disponible pour les dates sélectionnées. Veuillez essayer d\'autres dates.';
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
          
          // Si l'erreur concerne la disponibilité, on réinitialise le check
          if (errorMessage.contains('disponible')) {
            setState(() {
              _isAvailabilityChecked = false;
            });
          }
        }
      },
      child: ElevatedButton(
        onPressed: _isAvailable ? () {
          HapticFeedback.heavyImpact();
          _handleSubmit();
        } : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Réserver maintenant'),
      ),
    );
  }
  
  @override
  void dispose() {
    _guestsController.dispose();
    super.dispose();
  }
}