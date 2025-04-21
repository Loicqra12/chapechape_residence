import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/utils/responsive_utils.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'dart:math' as math;

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // Liste factice des méthodes de paiement enregistrées
  final List<Map<String, dynamic>> _savedMethods = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Moyens de paiement'),
        backgroundColor: const Color(0xFFFFD700),
      ),
      body: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec description
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                'Gérez vos moyens de paiement pour faciliter vos réservations',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(16),
                  color: Colors.grey[600],
                ),
              ),
            ),

            // Méthodes de paiement enregistrées
            Text(
              'Méthodes enregistrées',
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Afficher les méthodes ou un message si aucune
            _savedMethods.isEmpty
                ? _buildEmptyMethodsMessage()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _savedMethods.length,
                    itemBuilder: (context, index) {
                      return _buildPaymentMethodCard(_savedMethods[index]);
                    },
                  ),

            const SizedBox(height: 24),

            // Ajouter une nouvelle méthode
            Text(
              'Ajouter un moyen de paiement',
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Types de paiement supportés
            _buildPaymentTypeCard(
              icon: Icons.phone_android,
              title: 'Mobile Money',
              subtitle: 'Orange Money, MTN Mobile Money, Moov Money, Wave',
              onTap: () => _showAddMobileMoneyDialog(),
              color: Colors.orange[100]!,
              iconColor: Colors.deepOrange,
            ),
            
            _buildPaymentTypeCard(
              icon: Icons.credit_card,
              title: 'Carte bancaire',
              subtitle: 'Visa, Mastercard',
              onTap: () => _showAddCardDialog(),
              color: Colors.blue[100]!,
              iconColor: Colors.blue,
            ),
            
            _buildPaymentTypeCard(
              icon: Icons.account_balance_wallet,
              title: 'PayPal',
              subtitle: 'Payer avec votre compte PayPal',
              onTap: () => _showPaypalDialog(),
              color: Colors.indigo[100]!,
              iconColor: Colors.indigo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMethodsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.credit_card_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun moyen de paiement',
              style: TextStyle(
                fontSize: context.responsiveFontSize(16),
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez une carte ou un compte mobile money pour faciliter vos paiements',
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final bool isCard = method['type'] == 'card';
    final bool isMobileMoney = method['type'] == 'mobileMoney';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          isCard
              ? Icons.credit_card
              : isMobileMoney
                  ? Icons.phone_android
                  : Icons.account_balance_wallet,
          color: isCard
              ? Colors.blue
              : isMobileMoney
                  ? Colors.orange
                  : Colors.indigo,
        ),
        title: Text(method['title']),
        subtitle: Text(method['details']),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            setState(() {
              _savedMethods.remove(method);
            });
          },
        ),
      ),
    );
  }

  Widget _buildPaymentTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 24,
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMobileMoneyDialog() {
    String selectedProvider = 'Orange Money';
    String phoneNumber = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter Mobile Money'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sélection du fournisseur
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Fournisseur',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedProvider,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      selectedProvider = newValue;
                    }
                  },
                  items: [
                    'Orange Money',
                    'MTN Mobile Money',
                    'Moov Money',
                    'Wave'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Champ pour le numéro de téléphone
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: 07XXXXXXXX',
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    phoneNumber = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (phoneNumber.isNotEmpty) {
                  setState(() {
                    _savedMethods.add({
                      'type': 'mobileMoney',
                      'title': selectedProvider,
                      'details': 'Numéro: $phoneNumber',
                    });
                  });
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCardDialog() {
    String cardNumber = '';
    String cardHolder = '';
    String expiryDate = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter une carte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Numéro de carte
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Numéro de carte',
                    border: OutlineInputBorder(),
                    hintText: 'XXXX XXXX XXXX XXXX',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    cardNumber = value;
                  },
                ),
                const SizedBox(height: 16),
                // Titulaire de la carte
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Titulaire de la carte',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    cardHolder = value;
                  },
                ),
                const SizedBox(height: 16),
                // Date d'expiration
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date d\'expiration (MM/AA)',
                    border: OutlineInputBorder(),
                    hintText: 'MM/AA',
                  ),
                  keyboardType: TextInputType.datetime,
                  onChanged: (value) {
                    expiryDate = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (cardNumber.isNotEmpty && cardHolder.isNotEmpty && expiryDate.isNotEmpty) {
                  setState(() {
                    _savedMethods.add({
                      'type': 'card',
                      'title': 'Carte bancaire',
                      'details': 'XXXX XXXX XXXX ${cardNumber.substring(math.min(cardNumber.length, 12))} - Exp: $expiryDate',
                    });
                  });
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _showPaypalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter PayPal'),
          content: const Text('Cette fonctionnalité sera disponible prochainement.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
} 