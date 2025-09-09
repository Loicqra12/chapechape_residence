import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/booking/booking_event.dart' as booking_events;
import 'package:chapechape_client/core/blocs/booking/booking_state.dart' as booking_states;
import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:chapechape_client/core/blocs/user/user_bloc.dart';
import 'package:chapechape_client/core/blocs/user/user_state.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/core/models/user_model.dart';
import 'package:chapechape_client/core/services/notification_service.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';
import 'package:chapechape_client/presentation/widgets/phone_verification_widget.dart';
import 'package:chapechape_client/presentation/widgets/payment_method_selector.dart';
import 'package:chapechape_client/config/theme.dart';
import 'package:provider/provider.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String bookingId;

  const BookingConfirmationScreen({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  Booking? _booking;
  bool _isLoading = false;
  bool _isSendingSms = false;
  bool _showPhoneVerification = false;
  bool _smsSuccess = false;
  bool _smsError = false;
  String? _smsErrorMessage;
  String? _selectedPaymentMethod;
  bool _sendingPaymentInstructions = false;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  void _loadBookingDetails() {
    context.read<BookingBloc>().add(
      booking_events.LoadBookingDetails(bookingId: widget.bookingId),
    );
  }

  void _initiatePayment() {
    if (_booking != null) {
      context.read<PaymentBloc>().add(
        PreparePayment(
          reservationId: _booking!.id,
          method: PaymentMethod.mobileMoney,
        ),
      );
    }
  }
  
  Future<void> _sendBookingDetailsBySms() async {
    // Vérifier si l'utilisateur a un numéro de téléphone vérifié
    final userState = context.read<UserBloc>().state;
    User? currentUser;
    bool isPhoneVerified = false;
    
    if (userState is UserProfileLoaded) {
      currentUser = userState.user;
      isPhoneVerified = currentUser.isPhoneVerified ?? false;
    }
    
    // Si le numéro n'est pas vérifié, montrer le widget de vérification
    if (!isPhoneVerified) {
      setState(() {
        _showPhoneVerification = true;
      });
      return;
    }
    
    // Sinon, envoyer le SMS directement
    _sendSmsDirectly();
  }
  
  Future<void> _sendSmsDirectly() async {
    if (_booking == null) return;
    
    setState(() {
      _isSendingSms = true;
      _smsSuccess = false;
      _smsError = false;
      _smsErrorMessage = null;
    });
    
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      // Créer le contenu du SMS
      final dateFormat = DateFormat('dd/MM/yyyy');
      final message = "Confirmation de réservation: ${_booking!.residenceName}\n" +
          "Du ${dateFormat.format(_booking!.checkIn)} au ${dateFormat.format(_booking!.checkOut)}\n" +
          "${_booking!.nights} nuits, ${_booking!.numberOfGuests} personnes\n" +
          "Total: ${_booking!.totalPrice.toStringAsFixed(0)} FCFA\n" +
          "Statut: ${_getStatusText(_booking!.status)}\n" +
          "Référence: ${_booking!.id}";
      
      // Obtenir le numéro de téléphone de l'utilisateur
      final userState = context.read<UserBloc>().state;
      String phoneNumber = '';
      
      if (userState is UserProfileLoaded) {
        phoneNumber = userState.user.phoneNumber;
      }
      
      if (phoneNumber.isEmpty) {
        throw Exception('Numéro de téléphone non disponible');
      }
      
      // Envoyer le SMS
      await notificationService.sendCustomSms(
        phoneNumber: phoneNumber,
        message: message,
      );
      
      setState(() {
        _isSendingSms = false;
        _smsSuccess = true;
      });
      
      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Détails de réservation envoyés par SMS')),
      );
    } catch (e) {
      setState(() {
        _isSendingSms = false;
        _smsError = true;
        _smsErrorMessage = e.toString();
      });
      
      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi du SMS: ${e.toString()}')),
      );
    }
  }
  
  void _onPhoneVerified(String phoneNumber) {
    setState(() {
      _showPhoneVerification = false;
    });
    
    // Envoyer directement le SMS maintenant que le téléphone est vérifié
    _sendSmsDirectly();
  }
  
  // Méthode appelée lorsque l'utilisateur annule la vérification de téléphone
  void _cancelPhoneVerification() {
    setState(() {
      _showPhoneVerification = false;
    });
  }
  
  Future<void> _sendPaymentInstructions() async {
    if (_booking == null) return;
    
    // Vérifier si l'utilisateur a un numéro de téléphone vérifié
    final userState = context.read<UserBloc>().state;
    User? currentUser;
    bool isPhoneVerified = false;
    
    if (userState is UserProfileLoaded) {
      currentUser = userState.user;
      isPhoneVerified = currentUser.isPhoneVerified ?? false;
    }
    
    // Si le numéro n'est pas vérifié, montrer le widget de vérification
    if (!isPhoneVerified) {
      setState(() {
        _showPhoneVerification = true;
      });
      return;
    }
    
    // Afficher le sélecteur de méthode de paiement
    _showPaymentMethodModal();
  }
  
  void _showPaymentMethodModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Instructions de paiement',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PaymentMethodSelector(
              selectedMethod: _selectedPaymentMethod,
              onMethodSelected: (method) {
                setState(() {
                  _selectedPaymentMethod = method;
                });
              },
              showTitle: false,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedPaymentMethod == null || _sendingPaymentInstructions
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _sendPaymentInstructionsSms(_selectedPaymentMethod!);
                      },
                icon: _sendingPaymentInstructions
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_sendingPaymentInstructions
                    ? 'Envoi...'
                    : 'Envoyer les instructions'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  
  Future<void> _sendPaymentInstructionsSms(String paymentMethod) async {
    if (_booking == null) return;
    
    setState(() {
      _sendingPaymentInstructions = true;
      _smsSuccess = false;
      _smsError = false;
      _smsErrorMessage = null;
    });
    
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      // Essayer d'envoyer via l'API backend
      bool success = await notificationService.sendPaymentInstructionsSms(
        bookingId: _booking!.id,
        paymentMethod: paymentMethod,
      );
      
      if (success) {
        setState(() {
          _smsSuccess = true;
          _selectedPaymentMethod = paymentMethod;
        });
        
        // Afficher confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Instructions de paiement ${_getPaymentMethodName(paymentMethod)} envoyées par SMS',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Fallback : générer le message localement et l'envoyer
        final message = notificationService.generatePaymentInstructionsMessage(
          paymentMethod: paymentMethod,
          amount: _booking!.totalPrice,
          reference: 'CHAPE${_booking!.id.substring(0, 6)}',
          residenceName: _booking!.residenceName,
        );
        
        // Obtenir le numéro de téléphone de l'utilisateur
        final userState = context.read<UserBloc>().state;
        String phoneNumber = '';
        
        if (userState is UserProfileLoaded) {
          phoneNumber = userState.user.phoneNumber;
        }
        
        if (phoneNumber.isNotEmpty) {
          success = await notificationService.sendCustomSms(
            phoneNumber: phoneNumber,
            message: message,
          );
          
          if (success) {
            setState(() {
              _smsSuccess = true;
              _selectedPaymentMethod = paymentMethod;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Instructions de paiement envoyées par SMS'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            throw Exception('Impossible d\'envoyer le SMS');
          }
        } else {
          throw Exception('Numéro de téléphone manquant');
        }
      }
    } catch (e) {
      setState(() {
        _smsError = true;
        _smsErrorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Erreur: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sendingPaymentInstructions = false;
        });
      }
    }
  }
  
  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'wave': return 'Wave';
      case 'orange_money': return 'Orange Money';
      case 'mtn_money': return 'MTN Money';
      case 'moov_money': return 'Moov Money';
      case 'credit_card': return 'Carte bancaire';
      case 'cash': return 'Espèces';
      default: return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Comportement normal de retour - permet de revenir à l'écran précédent
        return true; // Permettre le comportement par défaut (pop normal)
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Confirmation de réservation'),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigation normale au lieu de forcer l'accueil
              Navigator.of(context).pop();
            },
          ),
        ),
        body: LoadingOverlay(
        isLoading: _isLoading || _isSendingSms,
        child: MultiBlocListener(
          listeners: [
            BlocListener<BookingBloc, booking_states.BookingState>(
              listener: (context, state) {
                setState(() {
                  _isLoading = state is booking_states.BookingLoading;
                });

                if (state is booking_states.BookingDetailsLoaded) {
                  setState(() {
                    _booking = state.booking;
                  });
                } else if (state is booking_states.BookingError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                } else if (state is booking_states.BookingApproved) {
                  // Navigation automatique vers l'écran d'approbation
                  context.go('/booking-approved/${state.bookingId}');
                } else if (state is booking_states.BookingRejected) {
                  // Navigation automatique vers l'écran de rejet
                  context.go('/booking-rejected/${state.bookingId}');
                } else if (state is booking_states.BookingExpired) {
                  // Navigation automatique vers l'écran d'expiration
                  context.go('/booking-expired/${state.bookingId}');
                }
              },
            ),
            BlocListener<PaymentBloc, PaymentState>(
              listener: (context, state) {
                setState(() {
                  _isLoading = state is PaymentLoading;
                });

                if (state is PaymentPrepared) {
                  // Navigation vers l'écran de paiement avec l'ID de réservation
                  context.go('/payment/${state.reservationId}');
                } else if (state is PaymentIntentCreated) {
                  // Rediriger vers l'écran de paiement avec l'ID de réservation
                  context.go('/payment/${state.paymentIntent.reservationId}');
                } else if (state is PaymentError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
          ],
          child: _booking == null
              ? const Center(child: Text('Chargement des détails...'))
              : _buildBookingConfirmation(),
        ),
      ),
    ));
  }

  Widget _buildBookingConfirmation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _showPhoneVerification
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Vérification du numéro de téléphone',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pour recevoir les détails de votre réservation par SMS, veuillez vérifier votre numéro de téléphone.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                PhoneVerificationWidget(
                  initialPhoneNumber: '',
                  onVerificationSuccess: _onPhoneVerified,
                  onCancel: _cancelPhoneVerification,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSuccessHeader(),
                const SizedBox(height: 24),
                _buildBookingDetails(),
                const SizedBox(height: 24),
                _buildSmsSection(),
                const SizedBox(height: 24),
                _buildPaymentSection(),
              ],
            ),
    );
  }

  Widget _buildSuccessHeader() {
    if (_booking == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Chargement des informations...')),
        ),
      );
    }
    
    return Card(
      color: AppTheme.successColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.successColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Réservation créée avec succès !',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Référence: ${_booking!.id}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetails() {
    if (_booking == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Chargement des détails...')),
        ),
      );
    }
    
    // Utiliser une variable locale pour éviter les accès répétés avec non-null assertion
    final booking = _booking!;
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Détails de la réservation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_smsSuccess)
                  const Icon(
                    Icons.message,
                    color: Colors.green,
                    size: 24,
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow('Résidence', booking.residenceName),
            _buildDetailRow('Date d\'arrivée', dateFormat.format(booking.checkIn)),
            _buildDetailRow('Date de départ', dateFormat.format(booking.checkOut)),
            _buildDetailRow('Nombre de nuits', '${booking.nights}'),
            _buildDetailRow('Nombre de personnes', '${booking.numberOfGuests}'),
            _buildDetailRow('Statut', _getStatusText(booking.status)),
            _buildDetailRow('Prix total', '${booking.totalPrice.toStringAsFixed(0)} FCFA'),
            const SizedBox(height: 8),
            Text(
              'Détails de paiement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            _buildDetailRow('Statut du paiement', _getPaymentStatusText(booking.isPaid)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    if (_booking == null) {
      return const SizedBox.shrink();
    }
    
    if (_booking!.isPaid) {
      return Card(
        color: AppTheme.successColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(
                Icons.payment,
                color: AppTheme.successColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Réservation déjà payée',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Procéder au paiement',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Votre réservation est confirmée, mais elle ne sera garantie qu\'après le paiement. Veuillez procéder au paiement maintenant.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initiatePayment,
              icon: const Icon(Icons.payment),
              label: const Text('Payer maintenant'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                context.go('/bookings');
              },
              child: const Text('Payer plus tard'),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'cancelled':
        return 'Annulée';
      case 'completed':
        return 'Terminée';
      default:
        return 'Inconnu';
    }
  }

  String _getPaymentStatusText(bool isPaid) {
    return isPaid ? 'Payé' : 'Non payé';
  }
  
  Widget _buildSmsSection() {
    if (_booking == null) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.message, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Recevoir par SMS',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Recevez les détails de votre réservation par SMS pour y accéder facilement, même sans connexion internet.',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.phone_android),
                    label: const Text('Détails de réservation'),
                    onPressed: _isSendingSms ? null : _sendBookingDetailsBySms,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_booking!.isPaid)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: _sendingPaymentInstructions 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payment),
                      label: Text(_sendingPaymentInstructions 
                        ? 'Envoi...' 
                        : 'Instructions de paiement'),
                      onPressed: _isSendingSms || _sendingPaymentInstructions 
                        ? null 
                        : _sendPaymentInstructions,
                    ),
                  ),
              ],
            ),
            if (_smsError && _smsErrorMessage != null) ...[  
              const SizedBox(height: 12),
              Text(
                'Erreur: $_smsErrorMessage',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 