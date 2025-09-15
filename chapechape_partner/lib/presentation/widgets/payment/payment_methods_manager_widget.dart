import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/models/payment/african_payment_method.dart';
import '../../../core/services/payment/african_payment_service.dart';
import '../../../core/models/phone_number.dart';
import '../common/inputs/advanced_phone_input_widget.dart';

/// Widget permettant aux partenaires de gérer les méthodes de paiement qu'ils acceptent
class PaymentMethodsManagerWidget extends StatefulWidget {
  const PaymentMethodsManagerWidget({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsManagerWidget> createState() => _PaymentMethodsManagerWidgetState();
}

class _PaymentMethodsManagerWidgetState extends State<PaymentMethodsManagerWidget> {
  bool _isLoading = true;
  List<AfricanPaymentMethod> _availableMethods = [];
  List<AfricanPaymentMethod> _selectedMethods = [];
  Map<AfricanPaymentMethod, Map<String, dynamic>> _methodDetails = {};
  Map<AfricanPaymentMethod, Map<String, dynamic>> _commissionInfo = {};
  Map<AfricanPaymentMethod, Map<String, dynamic>> _limitsInfo = {};
  
  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }
  
  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Récupérer toutes les méthodes de paiement disponibles
      final africanPaymentService = Provider.of<AfricanPaymentService>(context, listen: false);
      final availableMethods = await africanPaymentService.getAvailableAfricanPaymentMethods();
      
      // Récupérer les méthodes acceptées par le partenaire
      final acceptedMethods = await africanPaymentService.getAcceptedPaymentMethods();
      
      // Récupérer les détails des méthodes de paiement
      final methodDetails = await africanPaymentService.getAllMethodDetails();
      
      // Récupérer les informations sur les commissions et limites
      final commissionInfo = africanPaymentService.getCommissionInfo();
      final limitsInfo = africanPaymentService.getLimitsInfo();
      
      setState(() {
        _availableMethods = availableMethods;
        _selectedMethods = acceptedMethods;
        _methodDetails = methodDetails;
        _commissionInfo = commissionInfo;
        _limitsInfo = limitsInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des méthodes de paiement: $e')),
      );
    }
  }
  
  Future<void> _savePaymentMethods() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final africanPaymentService = Provider.of<AfricanPaymentService>(context, listen: false);
      
      // Pour chaque méthode sélectionnée, s'assurer qu'elle est ajoutée
      for (final method in _selectedMethods) {
        final details = _methodDetails[method] ?? {};
        await africanPaymentService.addPaymentMethod(method, details);
      }
      
      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Méthodes de paiement mises à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour des méthodes de paiement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _togglePaymentMethod(AfricanPaymentMethod method, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedMethods.add(method);
      } else {
        _selectedMethods.remove(method);
      }
    });
  }
  
  void _showDetailsDialog(AfricanPaymentMethod method) {
    // Contrôleurs pour les champs de texte
    final emailController = TextEditingController();
    final accountNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final bankNameController = TextEditingController();
    
    // PhoneNumber pour le champ de téléphone
    PhoneNumber? initialPhoneNumber;
    PhoneNumber? currentPhoneNumber;
    
    // Pré-remplir avec les valeurs existantes si disponibles
    if (_methodDetails.containsKey(method)) {
      final details = _methodDetails[method]!;
      
      if (method.requiresPhoneNumber && details.containsKey('phoneNumber')) {
        final phoneText = details['phoneNumber'];
        debugPrint('🔍 [DEBUG] Phone text from details: $phoneText');
        
        // Essayer de parser le numéro E.164 d'abord
        if (phoneText.startsWith('+')) {
          initialPhoneNumber = PhoneNumber.parseE164(phoneText);
          debugPrint('🔍 [DEBUG] Parsed E164: $initialPhoneNumber');
        }
        
        // Si le parsing E.164 échoue, essayer de créer un PhoneNumber simple
        if (initialPhoneNumber == null) {
          try {
            // Nettoyer le texte (enlever espaces, tirets, etc.)
            final cleanText = phoneText.replaceAll(RegExp(r'[\s\-\(\)]'), '');
            initialPhoneNumber = PhoneNumber(
              isoCode: 'CI', // Par défaut Côte d'Ivoire
              phoneNumber: cleanText,
            );
            debugPrint('🔍 [DEBUG] Created simple PhoneNumber: $initialPhoneNumber');
          } catch (e) {
            debugPrint('🔍 [DEBUG] Error creating PhoneNumber: $e');
            // Si échec, créer un PhoneNumber vide
            initialPhoneNumber = PhoneNumber(
              isoCode: 'CI',
              phoneNumber: '',
            );
          }
        }
      }
      
      if (details.containsKey('email')) {
        emailController.text = details['email'];
      }
      
      if (method.requiresBankDetails) {
        if (details.containsKey('accountName')) {
          accountNameController.text = details['accountName'];
        }
        if (details.containsKey('accountNumber')) {
          accountNumberController.text = details['accountNumber'];
        }
        if (details.containsKey('bankName')) {
          bankNameController.text = details['bankName'];
        }
      }
    }
    
    // Initialiser currentPhoneNumber avec initialPhoneNumber si disponible
    currentPhoneNumber = initialPhoneNumber;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails pour ${method.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Afficher le champ de numéro de téléphone pour les méthodes qui en ont besoin
              if (method.requiresPhoneNumber) ...[
                AdvancedPhoneInputWidget(
                  label: 'Numéro de téléphone',
                  hint: 'Ex: +225 07 48 00 10 42',
                  initialPhoneNumber: initialPhoneNumber,
                  onPhoneChanged: (phone) {
                    currentPhoneNumber = phone;
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Champ email pour toutes les méthodes
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optionnel)',
                  hintText: 'Ex: contact@exemple.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              
              // Champs pour les détails bancaires si nécessaire
              if (method.requiresBankDetails) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la banque',
                    hintText: 'Ex: Ecobank',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: accountNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du titulaire',
                    hintText: 'Ex: Jean Dupont',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de compte',
                    hintText: 'Ex: 0123456789',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () {
              // Enregistrer les détails
              final details = <String, dynamic>{};
              
              if (method.requiresPhoneNumber) {
                debugPrint('🔍 [DEBUG] currentPhoneNumber: $currentPhoneNumber');
                debugPrint('🔍 [DEBUG] currentPhoneNumber?.isValid: ${currentPhoneNumber?.isValid}');
                debugPrint('🔍 [DEBUG] currentPhoneNumber?.completeNumber: ${currentPhoneNumber?.completeNumber}');
                
                if (currentPhoneNumber != null && currentPhoneNumber!.isValid) {
                  details['phoneNumber'] = currentPhoneNumber!.completeNumber;
                  debugPrint('🔍 [DEBUG] Numéro de téléphone sauvegardé: ${currentPhoneNumber!.completeNumber}');
                } else {
                  // Afficher une erreur si le numéro n'est pas valide
                  debugPrint('🔍 [DEBUG] Erreur: Numéro de téléphone invalide ou null');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez saisir un numéro de téléphone valide'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }
              
              if (emailController.text.isNotEmpty) {
                details['email'] = emailController.text;
              }
              
              if (method.requiresBankDetails) {
                details['bankName'] = bankNameController.text;
                details['accountName'] = accountNameController.text;
                details['accountNumber'] = accountNumberController.text;
              }
              
              setState(() {
                _methodDetails[method] = details;
              });
              
              Navigator.of(context).pop();
            },
            child: const Text('ENREGISTRER'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Méthodes de paiement acceptées',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Sélectionnez les méthodes de paiement que vous souhaitez accepter pour vos résidences.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 16),
              
              // Liste des méthodes de paiement groupées par catégorie
              _buildPaymentMethodsList(),
              
              const SizedBox(height: 24),
              
              // Bouton de sauvegarde
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: _savePaymentMethods,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Enregistrer les méthodes de paiement'),
                ),
              ),
            ],
          );
  }
  
  Widget _buildPaymentMethodsList() {
    // Grouper les méthodes par catégorie
    final mobileMethods = _availableMethods
        .where((method) => method.category == PaymentMethodCategory.mobileMoney)
        .toList();
    
    final cardMethods = _availableMethods
        .where((method) => method.category == PaymentMethodCategory.card)
        .toList();
    
    final bankMethods = _availableMethods
        .where((method) => method.category == PaymentMethodCategory.bank)
        .toList();
    
    final otherMethods = _availableMethods
        .where((method) => 
            method.category != PaymentMethodCategory.mobileMoney && 
            method.category != PaymentMethodCategory.card &&
            method.category != PaymentMethodCategory.bank)
        .toList();
    
    return Expanded(
      child: ListView(
        children: [
          // Section Mobile Money
          if (mobileMethods.isNotEmpty)
            _buildMethodsSection('Mobile Money', mobileMethods),
          
          // Section Carte bancaire
          if (cardMethods.isNotEmpty)
            _buildMethodsSection('Carte bancaire', cardMethods),
          
          // Section Virement bancaire
          if (bankMethods.isNotEmpty)
            _buildMethodsSection('Virement bancaire', bankMethods),
          
          // Section Autres méthodes
          if (otherMethods.isNotEmpty)
            _buildMethodsSection('Autres méthodes', otherMethods),
        ],
      ),
    );
  }
  
  Widget _buildMethodsSection(String title, List<AfricanPaymentMethod> methods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...methods.map((method) => _buildPaymentMethodItem(method)),
        const Divider(),
      ],
    );
  }
  
  Widget _buildPaymentMethodItem(AfricanPaymentMethod method) {
    final isSelected = _selectedMethods.contains(method);
    final hasDetails = _methodDetails.containsKey(method);
    
    // Récupérer les informations sur les commissions et limites
    final commissionData = _commissionInfo[method];
    final limitsData = _limitsInfo[method];
    
    // Formatter pour les montants
    final currencyFormatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected 
              ? method.color
              : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: method.hasLogo
            ? Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.asset(
                  method.logoAsset!,
                  fit: BoxFit.contain,
                ),
              )
            : Icon(
                method.icon,
                color: method.color,
                size: 24,
              ),
        ),
        title: Text(
          method.displayName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(method.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur de configuration
            if (isSelected && hasDetails)
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
            // Bouton de détails
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: isSelected ? () => _showDetailsDialog(method) : null,
              tooltip: 'Configurer',
            ),
            // Switch pour activer/désactiver
            Switch(
              value: isSelected,
              activeColor: method.color,
              onChanged: (value) => _togglePaymentMethod(method, value),
            ),
          ],
        ),
        children: [
          if (commissionData != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations sur les commissions
                const Text(
                  'Informations sur la commission',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.paid, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      'Commission: ${(commissionData['rate'] * 100).toStringAsFixed(1)}%'
                      '${commissionData['fixed'] > 0 ? ' + ${currencyFormatter.format(commissionData['fixed'])}' : ''}',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timelapse, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('Traitement: ${commissionData['processingTime']}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.timeline, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Min: ${currencyFormatter.format(commissionData['min'])} | '
                      'Max: ${currencyFormatter.format(commissionData['max'])}',
                    ),
                  ],
                ),
                
                // Informations sur les limites
                if (limitsData != null) ...[                
                  const SizedBox(height: 8),
                  const Text(
                    'Limites de transaction',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('Par jour: ${currencyFormatter.format(limitsData['dailyLimit'])}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.payment, size: 14, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text('Par transaction: ${currencyFormatter.format(limitsData['transactionLimit'])}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.date_range, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text('Par mois: ${currencyFormatter.format(limitsData['monthlyLimit'])}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
