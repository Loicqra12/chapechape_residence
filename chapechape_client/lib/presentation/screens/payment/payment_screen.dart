import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';
import 'package:chapechape_client/config/theme.dart';

class PaymentScreen extends StatefulWidget {
  // Accepter soit reservationId (pour créer un paiement) soit paymentId (pour consulter un paiement)
  final String? reservationId;
  final String? paymentId;

  const PaymentScreen({
    Key? key,
    this.reservationId,
    this.paymentId,
  }) : assert(reservationId != null || paymentId != null, 'Soit reservationId soit paymentId doit être fourni'),
       super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.mobileMoney;
  bool _isLoading = false;
  String? _phoneNumber;
  final _formKey = GlobalKey<FormState>();
  PaymentIntent? _paymentIntent;
  Payment? _payment;

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  void _loadPaymentData() {
    if (widget.paymentId != null) {
      // Charger un paiement existant
      context.read<PaymentBloc>().add(
        CheckPaymentStatus(paymentId: widget.paymentId!),
      );
    } else if (widget.reservationId != null) {
      // Préparer un nouveau paiement pour une réservation
      context.read<PaymentBloc>().add(
        PreparePayment(
          reservationId: widget.reservationId!,
          method: _selectedMethod,
        ),
      );
    }
  }

  void _confirmPayment() {
    if (_formKey.currentState!.validate() && _paymentIntent != null) {
      final Map<String, dynamic> paymentData = {
        'type': _getPaymentMethodString(),
      };

      if (_selectedMethod == PaymentMethod.mobileMoney) {
        // Ajouter les informations spécifiques au mobile money
        if (_phoneNumber != null) {
          paymentData['phoneNumber'] = _phoneNumber;
          paymentData['provider'] = 'Orange Money'; // Ou autre opérateur selon le choix
        }
      }

      context.read<PaymentBloc>().add(
        ConfirmPayment(
          paymentIntentId: _paymentIntent!.id,
          paymentData: paymentData,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez compléter correctement le formulaire')),
      );
    }
  }

  String _getPaymentMethodString() {
    switch (_selectedMethod) {
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
      case PaymentMethod.visa:
        return 'card';
      case PaymentMethod.mastercard:
        return 'card';
      case PaymentMethod.wave:
        return 'wave';
      case PaymentMethod.paypal:
        return 'paypal';
      case PaymentMethod.stripe:
        return 'stripe';
      case PaymentMethod.cash:
        return 'cash';
      default:
        return 'mobile_money';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        elevation: 0,
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is PaymentLoading;
          });

          if (state is PaymentStatusChecked) {
            setState(() {
              _payment = state.payment;
              // Le paymentIntent devrait venir de l'état, pas du payment
            });
          } else if (state is PaymentIntentCreated) {
            setState(() {
              _paymentIntent = state.paymentIntent;
            });
          } else if (state is PaymentConfirmed) {
            // Redirection en fonction du résultat
            if (state.payment.status == PaymentStatus.processing) {
              // Si une action supplémentaire est requise (comme redirection vers un site tiers)
              final redirectUrl = state.payment.metadata?['redirectUrl'] as String?;
              if (redirectUrl != null) {
                // Rediriger vers une page web externe ou un composant WebView
                context.go('/payment-redirect/${state.payment.id}');
              }
            } else if (state.payment.status == PaymentStatus.succeeded) {
              // Paiement réussi, rediriger vers la page de succès
              context.go('/payment-success/${state.payment.id}');
            } else {
              // Paiement en attente ou autre statut
              context.go('/payment-pending/${state.payment.id}');
            }
          } else if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: _isLoading,
            child: _paymentIntent != null || _payment != null
                ? _buildPaymentForm()
                : const Center(child: Text('Chargement des informations de paiement...')),
          );
        },
      ),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPaymentSummary(),
            const SizedBox(height: 24),
            _buildPaymentMethodSelector(),
            const SizedBox(height: 24),
            _buildPaymentDetailsForm(),
            const SizedBox(height: 24),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    // Adapter l'affichage selon que nous ayons un paymentIntent ou un payment
    double amount = 0;
    String? reservationId;
    String description = "Paiement";
    
    if (_paymentIntent != null) {
      amount = _paymentIntent!.amount;
      reservationId = _paymentIntent!.reservationId;
      // Description à construire, car paymentIntent n'a pas de propriété description
      description = 'Paiement pour la réservation';
    } else if (_payment != null) {
      amount = _payment!.amount;
      reservationId = _payment!.reservationId;
      description = 'Paiement pour la réservation';
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé du paiement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow('Montant', '$amount FCFA'),
            _buildDetailRow('Description', description),
            if (reservationId != null)
              _buildDetailRow('Réservation', 'Réf: $reservationId'),
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
            width: 110,
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

  Widget _buildPaymentMethodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Méthode de paiement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            // Orange Money
            _buildPaymentMethodOption(
              PaymentMethod.mobileMoney,
              'Orange Money',
              'assets/images/orange_money.png',
            ),
            
            // MTN Mobile Money
            _buildPaymentMethodOption(
              PaymentMethod.mobileMoney,
              'MTN Mobile Money',
              'assets/images/mtn_momo.png',
            ),
            
            // Moov Money
            _buildPaymentMethodOption(
              PaymentMethod.mobileMoney,
              'Moov Money',
              'assets/images/moov_money.png',
            ),
            
            // CinetPay
            _buildPaymentMethodOption(
              PaymentMethod.mobileMoney,
              'Autres opérateurs',
              'assets/images/cinetpay.png',
            ),
            
            // Carte bancaire
            _buildPaymentMethodOption(
              PaymentMethod.visa,
              'Carte bancaire',
              'assets/images/credit_card.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    PaymentMethod method,
    String title,
    String iconPath,
  ) {
    return RadioListTile<PaymentMethod>(
      title: Row(
        children: [
          Text(title),
          const Spacer(),
          Image.asset(
            iconPath,
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.payment, size: 40);
            },
          ),
        ],
      ),
      value: method,
      groupValue: _selectedMethod,
      onChanged: (PaymentMethod? value) {
        if (value != null) {
          setState(() {
            _selectedMethod = value;
          });
        }
      },
    );
  }

  Widget _buildPaymentDetailsForm() {
    // Pour les méthodes Mobile Money, on demande le numéro de téléphone
    if (_selectedMethod == PaymentMethod.mobileMoney) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations de paiement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: 'Ex: +225 0101020304',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro de téléphone';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _phoneNumber = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Vous recevrez une notification sur votre téléphone pour confirmer le paiement.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_selectedMethod == PaymentMethod.visa) {
      // Pour les cartes bancaires, on utiliserait idéalement un widget spécifique pour saisir les informations de carte
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations de paiement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Vous serez redirigé vers une page sécurisée pour saisir les informations de votre carte bancaire.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _confirmPayment,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppTheme.primaryColor,
      ),
      child: const Text(
        'Confirmer le paiement',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 