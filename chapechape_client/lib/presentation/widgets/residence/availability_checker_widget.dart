import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/services/booking_service.dart';
import 'package:chapechape_client/core/utils/booking_helpers.dart';

/// Widget pour vérifier la disponibilité d'une résidence pour les dates sélectionnées
class AvailabilityCheckerWidget extends StatefulWidget {
  final Residence residence;
  final Function(DateTime, DateTime, bool, double) onAvailabilityChecked;

  const AvailabilityCheckerWidget({
    Key? key,
    required this.residence,
    required this.onAvailabilityChecked,
  }) : super(key: key);

  @override
  State<AvailabilityCheckerWidget> createState() => _AvailabilityCheckerWidgetState();
}

class _AvailabilityCheckerWidgetState extends State<AvailabilityCheckerWidget> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  bool _isChecking = false;
  bool _isAvailable = false;
  String _errorMessage = '';
  double _totalPrice = 0.0;
  bool _hasChecked = false;
  int _numberOfGuests = 1;

  final int _maxGuests = 10;
  BookingService? _bookingService;
  
  Future<void> _initializeBookingService() async {
    if (_bookingService == null) {
      _bookingService = await BookingService.initialize();
    }
  }
  
  @override
  void initState() {
    super.initState();
    // Initialiser les dates par défaut (aujourd'hui et demain)
    final now = DateTime.now();
    _checkInDate = DateTime(now.year, now.month, now.day + 1);
    _checkOutDate = DateTime(now.year, now.month, now.day + 2);
    
    // Initialiser le service de réservation
    _initializeBookingService();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Vérifier la disponibilité',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sélection de dates
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  context: context,
                  label: 'Arrivée',
                  selectedDate: _checkInDate,
                  onTap: () => _selectDate(context, true),
                  icon: Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  context: context,
                  label: 'Départ',
                  selectedDate: _checkOutDate,
                  onTap: () => _selectDate(context, false),
                  icon: Icons.calendar_month,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Sélection du nombre d'invités
          _buildGuestSelector(theme),
          
          // Message d'erreur ou de disponibilité
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _errorMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          if (_hasChecked && _isAvailable)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Disponible pour ces dates',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // Prix total et durée du séjour (si disponible)
          if (_hasChecked && _isAvailable)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prix total',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(_totalPrice)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_checkInDate != null && _checkOutDate != null)
                    Text(
                      '${_calculateNights()} nuit${_calculateNights() > 1 ? 's' : ''} · ${_numberOfGuests} invité${_numberOfGuests > 1 ? 's' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          
          // Bouton de vérification
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: _isChecking ? null : _checkAvailability,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isChecking
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      _hasChecked ? 'Vérifier à nouveau' : 'Vérifier disponibilité',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Construire le champ de date
  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedDate == null
                      ? 'Sélectionner'
                      : DateFormat('dd MMM yyyy', 'fr_FR').format(selectedDate),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Construire le sélecteur de nombre d'invités
  Widget _buildGuestSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nombre d\'invités',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_numberOfGuests invité${_numberOfGuests > 1 ? 's' : ''}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              IconButton(
                onPressed: _numberOfGuests > 1
                    ? () => setState(() => _numberOfGuests--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: _numberOfGuests > 1
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$_numberOfGuests',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: _numberOfGuests < _maxGuests
                    ? () => setState(() => _numberOfGuests++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: _numberOfGuests < _maxGuests
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Sélection de date via le DatePicker
  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkInDate ?? DateTime.now() : _checkOutDate ?? (DateTime.now().add(const Duration(days: 1))),
      firstDate: isCheckIn ? DateTime.now() : (_checkInDate ?? DateTime.now()).add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              onPrimary: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = pickedDate;
          // Ajuster la date de check-out si nécessaire
          if (_checkOutDate == null || _checkOutDate!.isBefore(_checkInDate!.add(const Duration(days: 1)))) {
            _checkOutDate = _checkInDate!.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = pickedDate;
        }
        // Réinitialiser les résultats de vérification
        _hasChecked = false;
        _isAvailable = false;
        _errorMessage = '';
      });
    }
  }
  
  // Vérifier la disponibilité
  Future<void> _checkAvailability() async {
    // Validation des dates
    if (_checkInDate == null || _checkOutDate == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner les dates d\'arrivée et de départ';
      });
      return;
    }

    if (_checkOutDate!.difference(_checkInDate!).inDays < 1) {
      setState(() {
        _errorMessage = 'La date de départ doit être au moins un jour après l\'arrivée';
      });
      return;
    }
    
    // S'assurer que le service est initialisé
    await _initializeBookingService();
    
    // Vérification en cours
    setState(() {
      _isChecking = true;
      _errorMessage = '';
    });

    try {
      // Appel à l'API pour vérifier la disponibilité
      final isAvailable = await _bookingService!.isAvailable(
        residenceId: widget.residence.id,
        checkIn: _checkInDate!,
        checkOut: _checkOutDate!,
      );

      // Extraction du prix par nuit à partir de la chaîne de caractères (ex: "100 FCFA/nuit")
      final priceString = widget.residence.pricePerNight.replaceAll(RegExp(r'[^0-9]'), '');
      final pricePerNight = double.tryParse(priceString) ?? widget.residence.price;
      
      // Calcul du prix total estimé
      final totalPrice = BookingHelpers.calculateTotalPrice(
        null, // Pas de booking existant
        basePrice: pricePerNight,
        checkIn: _checkInDate!,
        checkOut: _checkOutDate!,
        numberOfGuests: _numberOfGuests,
        // Utiliser des valeurs par défaut ou 0 si les propriétés n'existent pas
        cleaningFee: 25.0, // Frais de ménage standard
        serviceFee: pricePerNight * 0.05, // 5% du prix par nuit
        discountPercentage: widget.residence.hasDiscount ? 10.0 : 0.0, // 10% de réduction si promotion
      );

      setState(() {
        _isChecking = false;
        _hasChecked = true;
        _isAvailable = isAvailable;
        _totalPrice = totalPrice;
        
        if (!isAvailable) {
          _errorMessage = 'Cette résidence n\'est pas disponible pour les dates sélectionnées';
        }
      });
      
      // Informer le parent du résultat
      widget.onAvailabilityChecked(
        _checkInDate!, 
        _checkOutDate!, 
        isAvailable, 
        totalPrice
      );
    } catch (e) {
      setState(() {
        _isChecking = false;
        _hasChecked = true;
        _isAvailable = false;
        _errorMessage = 'Erreur lors de la vérification: ${e.toString()}';
      });
      
      // Informer le parent de l'échec
      widget.onAvailabilityChecked(_checkInDate!, _checkOutDate!, false, 0);
    }
  }
  
  // Calculer le nombre de nuits
  int _calculateNights() {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays;
  }
}
