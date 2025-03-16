import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';
import 'package:chapechape_client/config/theme.dart';

class PaymentScreen extends StatefulWidget {
  final String reservationId;
  
  const PaymentScreen({super.key, required this.reservationId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.mobileMoney;
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  String _selectedProvider = 'Orange Money';
  bool _isLoading = false;
  double _amount = 0;

  final List<String> _providers = [
    'Orange Money',
    'MTN Mobile Money',
    'Moov Money',
    'Wave',
  ];

  @override
  void initState() {
    super.initState();
    // Charger le montant depuis la réservation
    _fetchReservationDetails();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  void _fetchReservationDetails() {
    setState(() {
      _isLoading = true;
    });
    
    // Simuler le chargement des détails de la réservation
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _amount = 35000; // Montant fictif pour la démonstration
        _isLoading = false;
      });
    });
  }

  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Préparer les données de paiement
      context.read<PaymentBloc>().add(
        PreparePayment(
          reservationId: widget.reservationId,
          method: _selectedMethod,
        ),
      );
    }
  }

  Map<String, dynamic> _preparePaymentData() {
    if (_selectedMethod == PaymentMethod.mobileMoney) {
      return {
        'phoneNumber': _phoneController.text,
        'provider': _selectedProvider,
      };
    } else if (_selectedMethod == PaymentMethod.visa || 
               _selectedMethod == PaymentMethod.mastercard) {
      return {
        'cardDetails': {
          'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
          'expiryMonth': _expiryController.text.split('/')[0],
          'expiryYear': '20${_expiryController.text.split('/')[1]}',
          'cvc': _cvcController.text,
          'name': _nameController.text,
        }
      };
    }
    return {};
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    if (value.length < 10) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer le numéro de carte';
    }
    if (value.replaceAll(' ', '').length != 16) {
      return 'Numéro de carte invalide';
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer la date d\'expiration';
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Format invalide (MM/AA)';
    }
    return null;
  }

  String? _validateCVC(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer le code CVC';
    }
    if (value.length < 3 || value.length > 4) {
      return 'Code CVC invalide';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer le nom du titulaire';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentLoading) {
          setState(() => _isLoading = true);
        } else {
          setState(() => _isLoading = false);
        }

        if (state is PaymentIntentCreated) {
          // Confirmer le paiement
          context.read<PaymentBloc>().add(ConfirmPayment(
            paymentIntentId: state.paymentIntent.clientSecret,
            paymentData: _preparePaymentData(),
          ));
        } else if (state is PaymentConfirmed) {
          // Paiement réussi
          _showSuccessDialog(state.payment);
        } else if (state is PaymentPending) {
          // Afficher un message de paiement en attente
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.orange,
            ),
          );
          
          // Rediriger vers l'URL si nécessaire
          if (state.redirectUrl != null) {
            // Ici, nous utiliserions une méthode pour ouvrir une WebView ou un navigateur externe
            debugPrint('Redirection vers: ${state.redirectUrl}');
          }
        } else if (state is PaymentError) {
          // Afficher l'erreur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: LoadingOverlay(
        isLoading: _isLoading,
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
            backgroundColor: AppTheme.primaryColor,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Récapitulatif du paiement
                  _buildPaymentSummary(),
                  
                  const SizedBox(height: 20),
                  
                  // Sélection de la méthode de paiement
                  _buildPaymentMethodSelection(),
                  
                  const SizedBox(height: 20),
                  
                  // Formulaire de paiement
                  _buildPaymentForm(),
                  
                  const SizedBox(height: 30),
                  
                  // Bouton de paiement
                  ElevatedButton(
                    onPressed: _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Payer ${NumberFormat.currency(
                        symbol: 'FCFA ',
                        decimalDigits: 0,
                        locale: 'fr_FR',
                      ).format(_amount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Note sur la sécurité
                  const Center(
                    child: Text(
                      'Toutes les transactions sont sécurisées et chiffrées',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Récapitulatif',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Réservation'),
                Text('Réf: ${widget.reservationId.substring(0, 8)}'),
              ],
            ),
            const SizedBox(height: 5),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Service'),
                Text('Réservation de résidence'),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Montant total',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    symbol: 'FCFA ',
                    decimalDigits: 0,
                    locale: 'fr_FR',
                  ).format(_amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Méthode de paiement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPaymentMethodOption(
                method: PaymentMethod.mobileMoney,
                title: 'Mobile Money',
                icon: Icons.phone_android,
              ),
              _buildPaymentMethodOption(
                method: PaymentMethod.visa,
                title: 'Visa',
                icon: Icons.credit_card,
              ),
              _buildPaymentMethodOption(
                method: PaymentMethod.mastercard,
                title: 'Mastercard',
                icon: Icons.credit_card,
              ),
              _buildPaymentMethodOption(
                method: PaymentMethod.wave,
                title: 'Wave',
                icon: Icons.waves,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption({
    required PaymentMethod method,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    if (_selectedMethod == PaymentMethod.mobileMoney) {
      return _buildMobileMoneyForm();
    } else if (_selectedMethod == PaymentMethod.visa || 
               _selectedMethod == PaymentMethod.mastercard) {
      return _buildCardPaymentForm();
    } else if (_selectedMethod == PaymentMethod.wave) {
      return _buildWavePaymentForm();
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildMobileMoneyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paiement par Mobile Money',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        
        // Sélection du fournisseur
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Fournisseur',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: const Icon(Icons.business),
          ),
          value: _selectedProvider,
          items: _providers.map((provider) {
            return DropdownMenuItem<String>(
              value: provider,
              child: Text(provider),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedProvider = value;
              });
            }
          },
        ),
        
        const SizedBox(height: 15),
        
        // Numéro de téléphone
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Numéro de téléphone',
            hintText: 'Ex: 0701234567',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: const Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: _validatePhone,
        ),
        
        const SizedBox(height: 15),
        
        // Instructions
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  '1. Entrez votre numéro $_selectedProvider',
                  style: const TextStyle(fontSize: 12),
                ),
                const Text(
                  '2. Vous recevrez une notification sur votre téléphone',
                  style: TextStyle(fontSize: 12),
                ),
                const Text(
                  '3. Confirmez le paiement en saisissant votre code PIN',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paiement par ${_selectedMethod == PaymentMethod.visa ? 'Visa' : 'Mastercard'}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        
        // Nom du titulaire
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nom du titulaire',
            hintText: 'Ex: JOHN DOE',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: const Icon(Icons.person),
          ),
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.characters,
          validator: _validateName,
        ),
        
        const SizedBox(height: 15),
        
        // Numéro de carte
        TextFormField(
          controller: _cardNumberController,
          decoration: InputDecoration(
            labelText: 'Numéro de carte',
            hintText: 'XXXX XXXX XXXX XXXX',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: Icon(
              _selectedMethod == PaymentMethod.visa ? Icons.credit_card : Icons.credit_card,
              color: _selectedMethod == PaymentMethod.visa ? Colors.blue : Colors.orange,
            ),
          ),
          keyboardType: TextInputType.number,
          validator: _validateCardNumber,
        ),
        
        const SizedBox(height: 15),
        
        // Date d'expiration et CVC
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _expiryController,
                decoration: InputDecoration(
                  labelText: 'Date d\'expiration',
                  hintText: 'MM/AA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                validator: _validateExpiry,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextFormField(
                controller: _cvcController,
                decoration: InputDecoration(
                  labelText: 'CVC',
                  hintText: '123',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.security),
                ),
                keyboardType: TextInputType.number,
                validator: _validateCVC,
                obscureText: true,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 15),
        
        // Instructions
        Card(
          color: Colors.blue[50],
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sécurité:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  'Vos informations de carte sont sécurisées et ne sont jamais stockées sur nos serveurs.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWavePaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paiement par Wave',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        
        // Numéro de téléphone Wave
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Numéro Wave',
            hintText: 'Ex: 0701234567',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            prefixIcon: const Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: _validatePhone,
        ),
        
        const SizedBox(height: 15),
        
        // Instructions
        Card(
          color: Colors.blue[50],
          child: const Padding(
            padding: EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  '1. Entrez votre numéro Wave',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '2. Vous recevrez un lien dans l\'application Wave',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '3. Ouvrez l\'application Wave et confirmez le paiement',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog(Payment payment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 30),
            const SizedBox(width: 10),
            const Text('Paiement réussi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Votre paiement de ${NumberFormat.currency(
              symbol: 'FCFA ',
              decimalDigits: 0,
              locale: 'fr_FR',
            ).format(payment.amount)} a été effectué avec succès.'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Référence:'),
                Text(payment.id.substring(0, 8)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Date:'),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.go('/bookings');
            },
            child: const Text('Voir mes réservations'),
          ),
          ElevatedButton(
            onPressed: () {
              context.go('/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    );
  }
}