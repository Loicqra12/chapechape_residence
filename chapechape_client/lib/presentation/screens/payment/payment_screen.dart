import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/core/services/payment_service.dart';

import 'package:chapechape_client/config/theme.dart';

class PaymentScreen extends StatefulWidget {
  // Accepter soit reservationId (pour créer un paiement) soit paymentId (pour consulter un paiement)
  final String? reservationId;
  final String? paymentId;

  const PaymentScreen({
    Key? key,
    this.reservationId,
    this.paymentId,
  })  : assert(reservationId != null || paymentId != null,
            'Soit reservationId soit paymentId doit être fourni'),
        super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with AutomaticKeepAliveClientMixin {
  PaymentMethod _selectedMethod = PaymentMethod.mobileMoney;
  bool _isLoading = false;
  String? _phoneNumber;
  final _formKey = GlobalKey<FormState>();
  PaymentIntent? _paymentIntent;
  Payment? _payment;

  @override
  bool get wantKeepAlive => true;

  // Données pour la commission (par défaut 10%)
  double _commissionRate = 0.10;

  // Liste des méthodes de paiement acceptées
  List<PaymentMethod> _acceptedMethods = [];

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

      // Charger les méthodes de paiement acceptées
      _loadAcceptedPaymentMethods();
    }
  }

  // Nouvelle méthode pour charger les méthodes de paiement acceptées
  void _loadAcceptedPaymentMethods() async {
    final paymentService = await PaymentService.initialize();

    try {
      final methods = await paymentService.getAcceptedPaymentMethods(
        residenceId: widget.reservationId ?? '',
      );

      if (mounted) {
        setState(() {
          _acceptedMethods = methods;
          // Sélectionner par défaut la première méthode disponible
          if (_acceptedMethods.isNotEmpty) {
            _selectedMethod = _acceptedMethods.first;
          }
        });
      }
    } catch (e) {
      // En cas d'erreur, définir quelques méthodes par défaut
      setState(() {
        _acceptedMethods = [
          PaymentMethod.wave,
          PaymentMethod.orangeMoney,
          PaymentMethod.moovMoney,
          PaymentMethod.mtnMoney,
          PaymentMethod.cash,
        ];
      });
    }
  }

  void _confirmPayment() {
    // ✅ ANTI-TAP RÉPÉTÉ : Vérifier si déjà en cours de traitement
    if (_isLoading) {
      return;
    }

    if (_paymentIntent != null) {
      // Flux pour tous les paiements mobile money (incluant Wave)
      if (_selectedMethod == PaymentMethod.wave ||
          _selectedMethod == PaymentMethod.mobileMoney ||
          _selectedMethod == PaymentMethod.orangeMoney ||
          _selectedMethod == PaymentMethod.moovMoney ||
          _selectedMethod == PaymentMethod.mtnMoney) {
        // Validation renforcée du numéro de téléphone
        if (_phoneNumber != null && _phoneNumber!.trim().isNotEmpty) {
          // Formater le numéro pour le backend
          final formattedPhone = _formatPhoneNumberForBackend(_phoneNumber!.trim());
          
          // Validation supplémentaire du format du numéro formaté
          final phoneRegex = RegExp(r'^0[0-9]{8,9}$');
          if (phoneRegex.hasMatch(formattedPhone)) {
            // ✅ MARQUER COMME EN COURS
            setState(() {
              _isLoading = true;
            });
            
            context.read<PaymentBloc>().add(
              InitiateExternalPayment(
                method: _getPaymentMethodString(),
                reservationId: widget.reservationId ?? '',
                phoneNumber: formattedPhone,
                amount: _paymentIntent!.amount,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Format de numéro invalide: $formattedPhone. Utilisez le format 0XXXXXXXX'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez entrer votre numéro de téléphone'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Flux pour les cartes bancaires (ancien flux avec PaymentIntent)
        // D'abord créer l'intention de paiement avec les données complètes
        context.read<PaymentBloc>().add(
              CreatePaymentIntent(
                reservationId: widget.reservationId ?? '',
                amount: _paymentIntent!.amount,
                method: _selectedMethod,
                phoneNumber: null, // Pas de téléphone pour les cartes
              ),
            );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur: Données de paiement non disponibles')),
      );
    }
  }

  // Formater le numéro de téléphone pour le backend
  String _formatPhoneNumberForBackend(String phoneNumber) {
    // Nettoyer le numéro (supprimer espaces, tirets, parenthèses)
    String clean = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Si le numéro commence par +225, le convertir au format attendu
    if (clean.startsWith('+225')) {
      String digits = clean.substring(4); // Enlever +225
      // Si on a 10 chiffres après +225, garder seulement les 8 derniers
      if (digits.length == 10 && digits.startsWith('0')) {
        return digits.substring(1); // Enlever le 0 initial -> 8 chiffres
      } else if (digits.length == 10) {
        return '0${digits.substring(1)}'; // Ajouter 0 au début -> 0 + 9 chiffres
      } else if (digits.length == 8) {
        return '0$digits'; // Ajouter 0 au début -> 0 + 8 chiffres
      }
      return digits;
    }
    
    // Si le numéro commence par 225, le convertir
    if (clean.startsWith('225')) {
      String digits = clean.substring(3); // Enlever 225
      if (digits.length == 10 && digits.startsWith('0')) {
        return digits.substring(1); // Enlever le 0 initial
      } else if (digits.length == 10) {
        return '0${digits.substring(1)}';
      } else if (digits.length == 8) {
        return '0$digits';
      }
      return digits;
    }
    
    // Si le numéro commence déjà par 0 et fait 8-10 chiffres, le garder tel quel
    if (clean.startsWith('0') && clean.length >= 8 && clean.length <= 10) {
      return clean;
    }
    
    // Si le numéro fait 8 chiffres, ajouter 0 au début
    if (clean.length == 8) {
      return '0$clean';
    }
    
    return clean;
  }

  // Obtenir le nom du fournisseur en fonction de la méthode
  String _getProviderNameForMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.moovMoney:
        return 'Moov Money';
      case PaymentMethod.mtnMoney:
        return 'MTN Money';
      case PaymentMethod.wave:
        return 'Wave';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      default:
        return 'Mobile Money';
    }
  }

  String _getPaymentMethodString() {
    switch (_selectedMethod) {
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
      case PaymentMethod.orangeMoney:
        return 'orange_money'; // Format canonique
      case PaymentMethod.moovMoney:
        return 'moov_money'; // Format canonique
      case PaymentMethod.mtnMoney:
        return 'mtn_money';
      case PaymentMethod.wave:
        return 'wave';
      case PaymentMethod.visa:
        return 'visa';
      case PaymentMethod.mastercard:
        return 'mastercard';
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.paypal:
        return 'paypal';
      case PaymentMethod.stripe:
        return 'stripe';
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.other:
        return 'other';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Vérifier si on peut faire pop, sinon aller à l'accueil
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          // ✅ GESTION ÉTAT LOADING PLUS PRÉCISE
          if (state is PaymentLoading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is PaymentError || state is PaymentExternalLaunched || state is PaymentPending || state is PaymentPrepared) {
            setState(() {
              _isLoading = false;
            });
          }

          if (state is PaymentPrepared) {
            // Paiement préparé - attendre que l'utilisateur confirme avec son numéro
            setState(() {
              _paymentIntent = PaymentIntent(
                id: 'temp_${state.reservationId}',
                bookingId: state.reservationId,
                userId: 'current_user', // TODO: Récupérer l'ID utilisateur réel
                amount: state.amount,
                method: state.method,
                clientSecret: '',
                expiresAt: DateTime.now().add(const Duration(minutes: 30)),
                createdAt: DateTime.now(),
              );
            });
          } else if (state is PaymentStatusChecked) {
            setState(() {
              _payment = state.payment;
              // Le paymentIntent devrait venir de l'état, pas du payment
            });
          } else if (state is PaymentIntentCreated) {
            setState(() {
              _paymentIntent = state.paymentIntent;
            });

            // Pour les cartes bancaires, procéder à la confirmation automatiquement
            if (_selectedMethod == PaymentMethod.visa ||
                _selectedMethod == PaymentMethod.creditCard ||
                _selectedMethod == PaymentMethod.cash) {
              final Map<String, dynamic> paymentData = {
                'type': _getPaymentMethodString(),
                'commissionRate': _commissionRate,
              };

              context.read<PaymentBloc>().add(
                    ConfirmPayment(
                      paymentIntentId: state.paymentIntent.id,
                      paymentData: paymentData,
                    ),
                  );
            }
          } else if (state is PaymentExternalLaunched) {
            // Vérifier que nous avons un transactionId valide avant navigation
            if (state.transactionId.isNotEmpty) {
              // Nouveau flux: rediriger vers l'écran d'attente unifié
              context.go('/payment-waiting', extra: {
                'method': state.method,
                'transactionId': state.transactionId,
                'paymentUrl': state.paymentUrl,
                'expiresAt': state.expiresAt.toIso8601String(),
                'phoneNumber': state.phoneNumber,
              });
            } else {
              // Garde-fou: création de paiement échouée
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Création de paiement échouée. Veuillez réessayer.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else if (state is PaymentConfirmed) {
            // Ancien flux pour les cartes bancaires
            if (state.payment.status == PaymentStatus.processing) {
              final redirectUrl =
                  state.payment.metadata?['redirectUrl'] as String?;
              if (redirectUrl != null) {
                context.go('/payment-redirect/${state.payment.id}');
              }
            } else if (state.payment.status == PaymentStatus.succeeded) {
              context.go('/payment-success/${state.payment.id}');
            } else {
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
          // Toujours afficher le contenu pour préserver l'AppBar
          if (_isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des informations de paiement...'),
                ],
              ),
            );
          }

          return _paymentIntent != null || _payment != null
              ? _buildPaymentForm()
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement des informations de paiement...'),
                    ],
                  ),
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
          mainAxisSize: MainAxisSize.min,
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
    if (_paymentIntent == null && _payment == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Récupérer le montant du paiement ou de l'intention
    final amount = _payment?.amount ?? _paymentIntent?.amount ?? 0.0;

    // Calculer la commission (10% par défaut)
    final commissionAmount = amount * _commissionRate;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Récapitulatif du paiement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildDetailRow(
              'Montant total',
              '${amount.toStringAsFixed(0)} FCFA',
              isTotal: true,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Frais de service ChapeChape (10%)',
              '${commissionAmount.toStringAsFixed(0)} FCFA',
              isNegative: true,
            ),
            const SizedBox(height: 8),
            const Divider(
              indent: 16,
              endIndent: 16,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            // Montant partenaire masqué pour l'utilisateur final
            if (_payment?.status != null)
              Column(
                children: [
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Statut',
                    _payment!.status.displayName,
                    statusColor: _payment!.status.color,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isSubtotal = false,
    bool isNegative = false,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal || isSubtotal ? 16 : 14,
                fontWeight:
                    isTotal || isSubtotal ? FontWeight.bold : FontWeight.normal,
                color: isNegative ? Colors.red : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal || isSubtotal ? 16 : 14,
                fontWeight:
                    isTotal || isSubtotal ? FontWeight.bold : FontWeight.normal,
                color: statusColor ?? (isNegative ? Colors.red : null),
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    // Si aucune méthode n'est disponible, afficher un message
    if (_acceptedMethods.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Chargement des méthodes de paiement...',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

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
            // Options de paiement Mobile Money
            if (_acceptedMethods.contains(PaymentMethod.orangeMoney))
              _buildPaymentMethodOption(
                PaymentMethod.orangeMoney,
                'Orange Money',
                'assets/images/payment/orange_money.png',
              ),
            if (_acceptedMethods.contains(PaymentMethod.moovMoney))
              _buildPaymentMethodOption(
                PaymentMethod.moovMoney,
                'Moov Money',
                'assets/images/payment/moov_money.png',
              ),
            if (_acceptedMethods.contains(PaymentMethod.mtnMoney))
              _buildPaymentMethodOption(
                PaymentMethod.mtnMoney,
                'MTN Money',
                'assets/images/payment/mtn_money.png',
              ),
            if (_acceptedMethods.contains(PaymentMethod.wave))
              _buildPaymentMethodOption(
                PaymentMethod.wave,
                'Wave',
                'assets/images/payment/wave_money.png',
              ),

            // Options de paiement par carte
            if (_acceptedMethods.contains(PaymentMethod.visa) ||
                _acceptedMethods.contains(PaymentMethod.mastercard) ||
                _acceptedMethods.contains(PaymentMethod.creditCard))
              _buildPaymentMethodOption(
                PaymentMethod.creditCard,
                'Carte bancaire',
                'assets/images/payment/visa.png',
              ),

            // Virement bancaire
            if (_acceptedMethods.contains(PaymentMethod.bankTransfer))
              _buildPaymentMethodOption(
                PaymentMethod.bankTransfer,
                'Virement bancaire',
                'assets/images/payment/mastercard.png',
              ),

            // Espèces
            if (_acceptedMethods.contains(PaymentMethod.cash))
              _buildPaymentMethodOption(
                PaymentMethod.cash,
                'Paiement en espèces',
                'assets/images/payment/paypal.png',
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
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
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
    // Pour Wave, on demande le numéro de téléphone
    if (_selectedMethod == PaymentMethod.wave ||
        _selectedMethod == PaymentMethod.mobileMoney ||
        _selectedMethod == PaymentMethod.orangeMoney ||
        _selectedMethod == PaymentMethod.moovMoney ||
        _selectedMethod == PaymentMethod.mtnMoney) {
      final providerName = _getProviderNameForMethod(_selectedMethod);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations de paiement $providerName',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              const SizedBox(height: 16),
              TextFormField(
                key: ValueKey('phone_field_$providerName'),
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: 'Ex: +225 0101020304',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                  suffixText: providerName,
                  errorMaxLines: 2,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer votre numéro de téléphone';
                  }
                  // Validation du format du numéro de téléphone
                  final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Format de numéro invalide (8-15 chiffres)';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _phoneNumber = value.trim();
                  });
                },
                onSaved: (value) {
                  _phoneNumber = value?.trim();
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Vous recevrez une notification sur votre téléphone $providerName pour confirmer le paiement.',
                style: const TextStyle(
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations de paiement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Vous serez redirigé vers une page sécurisée pour saisir les informations de votre carte bancaire.',
                style: const TextStyle(
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
