import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/booking/booking_event.dart';
import 'package:chapechape_client/core/blocs/booking/booking_state.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/models/modification_fees_model.dart';
import 'package:chapechape_client/presentation/widgets/date_range_picker_widget.dart';
import 'package:chapechape_client/presentation/widgets/booking_modification_dialog.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';

class BookingModifyScreen extends StatefulWidget {
  final String bookingId;

  const BookingModifyScreen({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<BookingModifyScreen> createState() => _BookingModifyScreenState();
}

class _BookingModifyScreenState extends State<BookingModifyScreen> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _numberOfGuests;
  bool _isLoading = false;
  Booking? _originalBooking;
  ModificationFees? _fees;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  void _loadBookingDetails() {
    context.read<BookingBloc>().add(
      LoadBookingDetails(bookingId: widget.bookingId),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? _validateModification() {
    final now = DateTime.now();
    
    // Vérifier si les dates sont dans le futur
    if (_checkIn.isBefore(now)) {
      return 'La date d\'arrivée doit être dans le futur';
    }

    // Vérifier l'ordre des dates
    if (_checkOut.isBefore(_checkIn) || _checkOut.isAtSameMomentAs(_checkIn)) {
      return 'La date de départ doit être après la date d\'arrivée';
    }

    // Vérifier la durée minimale (1 nuit)
    final nights = _checkOut.difference(_checkIn).inDays;
    if (nights < 1) {
      return 'La durée minimale de séjour est de 1 nuit';
    }

    // Vérifier le nombre de voyageurs
    if (_numberOfGuests < 1) {
      return 'Le nombre de voyageurs doit être d\'au moins 1';
    }

    // Vérifier si des modifications ont été apportées
    if (_checkIn == _originalBooking!.checkIn &&
        _checkOut == _originalBooking!.checkOut &&
        _numberOfGuests == _originalBooking!.numberOfGuests) {
      return 'Aucune modification n\'a été apportée';
    }

    // Vérifier si la modification est dans les limites de temps autorisées
    final hoursUntilCheckIn = _checkIn.difference(now).inHours;
    if (hoursUntilCheckIn < 48) {
      return 'Les modifications ne sont pas autorisées moins de 48 heures avant l\'arrivée';
    }

    // Vérifier si la nouvelle durée ne dépasse pas la durée maximale autorisée
    if (nights > 30) {
      return 'La durée maximale de séjour est de 30 nuits';
    }

    return null;
  }

  Future<bool> _checkAvailability() async {
    try {
      context.read<BookingBloc>().add(
        CheckResidenceAvailability(
          residenceId: _originalBooking!.residenceId,
          checkIn: _checkIn,
          checkOut: _checkOut,
        ),
      );
      return true; // Le bloc gérera la réponse
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la vérification de la disponibilité: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  void _handleSubmit() async {
    final error = _validateModification();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier la disponibilité avant de calculer les frais
    final isAvailable = await _checkAvailability();
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les dates sélectionnées ne sont pas disponibles'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _calculateFees();
  }

  void _calculateFees() {
    context.read<BookingBloc>().add(
      CalculateModificationFees(
        bookingId: widget.bookingId,
        newCheckIn: _checkIn,
        newCheckOut: _checkOut,
        newNumberOfGuests: _numberOfGuests,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la réservation'),
        elevation: 0,
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is BookingLoading;
          });

          if (state is ModificationFeesCalculated) {
            setState(() => _fees = state.fees);
            _showConfirmationDialog();
          } else if (state is BookingUpdatedWithFees) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Réservation modifiée avec succès'),
                backgroundColor: AppTheme.successColor,
              ),
            );
            context.go('/bookings');
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }

          if (state is BookingDetailsLoaded && _originalBooking == null) {
            setState(() {
              _originalBooking = state.booking;
              _checkIn = state.booking.checkIn;
              _checkOut = state.booking.checkOut;
              _numberOfGuests = state.booking.numberOfGuests;
            });
          }
        },
        builder: (context, state) {
          if (state is BookingLoading && _originalBooking == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_originalBooking == null) {
            return const Center(
              child: Text('Impossible de charger les détails de la réservation'),
            );
          }

          return SingleChildScrollView(
            padding: AppSpacing.cardPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DateRangePickerWidget(
                    initialDateRange: DateTimeRange(
                      start: _checkIn,
                      end: _checkOut,
                    ),
                    onDateRangeSelected: (dateRange) {
                      if (dateRange != null) {
                        setState(() {
                          _checkIn = dateRange.start;
                          _checkOut = dateRange.end;
                        });
                      }
                    },
                  ),
                  AppSpacing.verticalLg,
                  ListTile(
                    title: const Text('Nombre de voyageurs'),
                    trailing: DropdownButton<int>(
                      value: _numberOfGuests,
                      items: List.generate(10, (i) => i + 1)
                          .map((i) => DropdownMenuItem(
                                value: i,
                                child: Text('$i'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _numberOfGuests = value);
                        }
                      },
                    ),
                  ),
                  AppSpacing.verticalXl,
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? SizedBox(
                            height: AppSpacing.md + AppSpacing.xs,
                            width: AppSpacing.md + AppSpacing.xs,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Vérifier les frais'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showConfirmationDialog() {
    if (_fees == null) return;

    showDialog(
      context: context,
      builder: (context) => BookingModificationDialog(
        newCheckIn: _checkIn,
        newCheckOut: _checkOut,
        newNumberOfGuests: _numberOfGuests,
        fees: _fees!,
        onConfirm: () {
          Navigator.of(context).pop(); // Fermer le dialogue
          context.read<BookingBloc>().add(
                UpdateBookingWithFees(
                  bookingId: widget.bookingId,
                  checkIn: _checkIn,
                  checkOut: _checkOut,
                  numberOfGuests: _numberOfGuests,
                  modificationFee: _fees!.totalFee,
                ),
              );
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}
