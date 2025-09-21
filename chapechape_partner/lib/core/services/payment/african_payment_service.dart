import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import './payment_preferences_service.dart';
import '../../models/payment/african_payment_method.dart';
import '../../models/payment/payment_model.dart';
import '../api/api_service.dart';
import '../api/payment_service.dart';

/// Service pour gérer les paiements africains
class AfricanPaymentService {
  final ApiService _apiService;
  final PaymentService _paymentService;
  final PaymentPreferencesService _preferencesService = PaymentPreferencesService();
  
  AfricanPaymentService(this._apiService, this._paymentService);
  
  /// Récupère toutes les méthodes de paiement africaines disponibles
  Future<List<AfricanPaymentMethod>> getAvailableAfricanPaymentMethods({
    String? residenceId,
    String? partnerId,
  }) async {
    try {
      // Simulation - dans une version réelle, cela serait remplacé par un appel API
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Retourne toutes les méthodes disponibles pour le test
      return AfricanPaymentMethod.values;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des méthodes de paiement: $e');
      // En cas d'erreur, retourner les méthodes les plus courantes
      return [
        AfricanPaymentMethod.wave,
        AfricanPaymentMethod.orangeMoney,
        AfricanPaymentMethod.cash,
      ];
    }
  }
  
  /// Récupère les méthodes de paiement acceptées par le partenaire
  Future<List<AfricanPaymentMethod>> getAcceptedPaymentMethods({String? residenceId}) async {
    try {
      // ✅ UTILISER L'API EXISTANTE: GET /api/residences/:id pour récupérer les méthodes de paiement
      if (residenceId != null) {
        try {
          final response = await _apiService.get('/residences/$residenceId');
          if (response.statusCode == 200) {
            final List<dynamic> paymentMethods = response.data['paymentMethods'] ?? [];
            return paymentMethods.map((method) => _parsePaymentMethod(method)).toList();
          }
        } catch (apiError) {
          debugPrint('API non disponible, utilisation du stockage local: $apiError');
        }
      }
      
      // Fallback vers le stockage local si l'API n'est pas disponible
      final localMethods = await _preferencesService.getAcceptedMethods();
      
      if (localMethods.isNotEmpty) {
        return localMethods;
      }
      
      // En dernier recours, utiliser des méthodes par défaut
      return [
        AfricanPaymentMethod.wave,
        AfricanPaymentMethod.orangeMoney,
        AfricanPaymentMethod.mtnMoney,
        AfricanPaymentMethod.moovMoney,
        AfricanPaymentMethod.cash,
      ];
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des méthodes de paiement: $e');
      // En cas d'erreur, on simule des méthodes par défaut pour le développement
      return [
        AfricanPaymentMethod.wave,
        AfricanPaymentMethod.orangeMoney,
        AfricanPaymentMethod.cash,
      ];
    }
  }
  
  /// Ajoute une méthode de paiement pour le partenaire
  Future<bool> addPaymentMethod(AfricanPaymentMethod method, Map<String, dynamic> details, {String? residenceId}) async {
    try {
      // Valider les détails de la méthode de paiement
      final validationError = validatePaymentMethodDetails(method, details);
      if (validationError != null) {
        throw Exception(validationError);
      }
      
      // ✅ UTILISER L'API EXISTANTE: PUT /api/residences/:id/payment-methods
      if (residenceId != null) {
        try {
          // Récupérer les méthodes actuelles
          final currentMethods = await getAcceptedPaymentMethods(residenceId: residenceId);
          
          // Ajouter la nouvelle méthode si elle n'existe pas déjà
          if (!currentMethods.contains(method)) {
            currentMethods.add(method);
            
            // Convertir en format API
            final paymentMethodsList = currentMethods.map((m) => m.toString().split('.').last).toList();
            
            // Mettre à jour via l'API
            final response = await _apiService.put('/residences/$residenceId/payment-methods', data: {
              'paymentMethods': paymentMethodsList,
            });
            
            if (response.statusCode == 200) {
              debugPrint('✅ Méthode de paiement ajoutée via API: ${method.displayName}');
              return true;
            }
          } else {
            debugPrint('ℹ️ Méthode de paiement déjà présente: ${method.displayName}');
            return true;
          }
        } catch (apiError) {
          debugPrint('API non disponible, utilisation du stockage local: $apiError');
        }
      }
      
      // Fallback vers le stockage local si l'API n'est pas disponible
      debugPrint('ℹ️ Sauvegarde locale (fallback)');
      await _preferencesService.saveMethodDetails(method, details);
      
      // Récupérer les méthodes acceptées et ajouter la nouvelle si elle n'existe pas déjà
      final acceptedMethods = await _preferencesService.getAcceptedMethods();
      if (!acceptedMethods.contains(method)) {
        acceptedMethods.add(method);
        await _preferencesService.saveAcceptedMethods(acceptedMethods);
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ajout de la méthode de paiement: $e');
      return false;
    }
  }
  
  /// Supprime une méthode de paiement pour le partenaire
  Future<bool> removePaymentMethod(AfricanPaymentMethod method, {String? residenceId}) async {
    try {
      // ✅ UTILISER L'API EXISTANTE: PUT /api/residences/:id/payment-methods
      if (residenceId != null) {
        try {
          // Récupérer les méthodes actuelles
          final currentMethods = await getAcceptedPaymentMethods(residenceId: residenceId);
          
          // Supprimer la méthode
          currentMethods.remove(method);
          
          // Convertir en format API
          final paymentMethodsList = currentMethods.map((m) => m.toString().split('.').last).toList();
          
          // Mettre à jour via l'API
          final response = await _apiService.put('/residences/$residenceId/payment-methods', data: {
            'paymentMethods': paymentMethodsList,
          });
          
          if (response.statusCode == 200) {
            debugPrint('✅ Méthode de paiement supprimée via API: ${method.displayName}');
            return true;
          }
        } catch (apiError) {
          debugPrint('API non disponible, utilisation du stockage local: $apiError');
        }
      }
      
      // Fallback vers le stockage local si l'API n'est pas disponible
      debugPrint('ℹ️ Suppression locale (fallback)');
      return await _preferencesService.removeMethod(method);
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la méthode de paiement: $e');
      return false;
    }
  }
  
  /// Traite un paiement mobile money
  Future<PaymentTransactionResult> processMobileMoneyPayment({
    required String bookingId,
    required double amount,
    required AfricanPaymentMethod method,
    required String phoneNumber,
    String? email,
    PaymentResultCallback? callback,
  }) async {
    try {
      // Vérifier que la méthode est bien du mobile money
      if (method.category != PaymentMethodCategory.mobileMoney) {
        throw Exception('La méthode de paiement n\'est pas du mobile money');
      }
      
      // Préparer les détails du paiement
      final details = MobileMoneyDetails(
        phoneNumber: phoneNumber,
        email: email,
        provider: method.toString().split('.').last,
      );
      
      // Simuler un appel API pour le traitement du paiement
      await Future.delayed(const Duration(seconds: 2));
      
      // Créer un résultat de transaction simulé
      final result = PaymentTransactionResult(
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        method: method,
        status: 'completed',
        timestamp: DateTime.now(),
        additionalData: {
          'phoneNumber': phoneNumber,
          if (email != null) 'email': email,
          'provider': method.displayName,
        },
      );
      
      // Appeler le callback de succès si fourni
      callback?.onPaymentSuccess(result);
      
      return result;
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement du paiement mobile money: $e');
      
      // Appeler le callback d'erreur si fourni
      callback?.onPaymentError(e.toString(), null);
      
      // Renvoyer une exception pour la gestion d'erreur en amont
      rethrow;
    }
  }
  
  /// Traite un paiement par carte bancaire
  Future<PaymentTransactionResult> processCardPayment({
    required String bookingId,
    required double amount,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolderName,
    PaymentResultCallback? callback,
  }) async {
    try {
      // Simuler un appel API pour le traitement du paiement
      await Future.delayed(const Duration(seconds: 2));
      
      // Masquer le numéro de carte pour la sécurité
      final lastFourDigits = cardNumber.substring(cardNumber.length - 4);
      
      // Créer un résultat de transaction simulé
      final result = PaymentTransactionResult(
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        method: AfricanPaymentMethod.bankCard,
        status: 'completed',
        timestamp: DateTime.now(),
        additionalData: {
          'cardLastFour': lastFourDigits,
          'cardHolderName': cardHolderName,
        },
      );
      
      // Appeler le callback de succès si fourni
      callback?.onPaymentSuccess(result);
      
      return result;
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement du paiement par carte: $e');
      
      // Appeler le callback d'erreur si fourni
      callback?.onPaymentError(e.toString(), null);
      
      // Renvoyer une exception pour la gestion d'erreur en amont
      rethrow;
    }
  }
  
  /// Traite un paiement en espèces
  Future<PaymentTransactionResult> processCashPayment({
    required String bookingId,
    required double amount,
    PaymentResultCallback? callback,
  }) async {
    try {
      // Simuler un appel API pour le traitement du paiement
      await Future.delayed(const Duration(seconds: 1));
      
      // Créer un résultat de transaction simulé
      final result = PaymentTransactionResult(
        transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        method: AfricanPaymentMethod.cash,
        status: 'pending', // Les paiements en espèces sont d'abord en attente
        timestamp: DateTime.now(),
      );
      
      // Appeler le callback de succès si fourni
      callback?.onPaymentSuccess(result);
      
      return result;
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement du paiement en espèces: $e');
      
      // Appeler le callback d'erreur si fourni
      callback?.onPaymentError(e.toString(), null);
      
      // Renvoyer une exception pour la gestion d'erreur en amont
      rethrow;
    }
  }
  
  /// Confirme un paiement en espèces (après réception de l'argent)
  Future<bool> confirmCashPayment(String transactionId) async {
    try {
      // Simuler un appel API pour la confirmation du paiement
      await Future.delayed(const Duration(seconds: 1));
      
      // Dans une vraie implémentation, on appellerait l'API pour mettre à jour le statut
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la confirmation du paiement en espèces: $e');
      return false;
    }
  }
  
  /// Vérifie le statut d'un paiement
  Future<String> checkPaymentStatus(String transactionId) async {
    try {
      final response = await _apiService.get('/payments/$transactionId/status');
      
      if (response.statusCode == 200) {
        return response.data['status'];
      } else {
        throw Exception('Erreur lors de la vérification du statut du paiement');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du statut du paiement: $e');
      // Pour le développement, on simule un statut aléatoire
      return 'completed';
    }
  }
  
  /// Méthode utilitaire pour parser une chaîne en méthode de paiement
  /// Récupère les détails de toutes les méthodes de paiement
  Future<Map<AfricanPaymentMethod, Map<String, dynamic>>> getAllMethodDetails() async {
    try {
      // Essayer d'abord de récupérer depuis l'API
      try {
        final response = await _apiService.get('/partners/payment-methods/details');
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> methodsMap = response.data;
          final result = <AfricanPaymentMethod, Map<String, dynamic>>{};
          
          methodsMap.forEach((key, value) {
            try {
              final method = _parsePaymentMethod(key);
              result[method] = Map<String, dynamic>.from(value as Map);
            } catch (e) {
              debugPrint('Erreur lors du parsing de la méthode $key: $e');
            }
          });
          
          // Mettre à jour le stockage local
          for (final entry in result.entries) {
            await _preferencesService.saveMethodDetails(entry.key, entry.value);
          }
          
          return result;
        }
      } catch (apiError) {
        debugPrint('API non disponible, utilisation du stockage local: $apiError');
      }
      
      // Si l'API n'est pas disponible, utiliser le stockage local
      return await _preferencesService.getAllMethodDetails();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des détails des méthodes de paiement: $e');
      return {};
    }
  }
  
  /// Valide les détails d'une méthode de paiement
  String? validatePaymentMethodDetails(AfricanPaymentMethod method, Map<String, dynamic> details) {
    switch (method) {
      case AfricanPaymentMethod.wave:
      case AfricanPaymentMethod.orangeMoney:
      case AfricanPaymentMethod.mtnMoney:
      case AfricanPaymentMethod.moovMoney:
        return _validateMobileMoneyDetails(method, details);
      case AfricanPaymentMethod.bankTransfer:
        return _validateBankTransferDetails(details);
      case AfricanPaymentMethod.visa:
      case AfricanPaymentMethod.mastercard:
      case AfricanPaymentMethod.bankCard:
        return _validateCardDetails(details);
      case AfricanPaymentMethod.paypal:
        return _validatePaypalDetails(details);
      case AfricanPaymentMethod.stripe:
        return _validateStripeDetails(details);
      case AfricanPaymentMethod.cash:
        // Pas de validation spécifique pour le cash
        return null;
    }
  }
  
  /// Valide les détails d'un paiement Mobile Money
  String? _validateMobileMoneyDetails(AfricanPaymentMethod method, Map<String, dynamic> details) {
    debugPrint('🔍 [DEBUG] _validateMobileMoneyDetails - method: $method');
    debugPrint('🔍 [DEBUG] _validateMobileMoneyDetails - details: $details');
    debugPrint('🔍 [DEBUG] _validateMobileMoneyDetails - containsKey phoneNumber: ${details.containsKey('phoneNumber')}');
    debugPrint('🔍 [DEBUG] _validateMobileMoneyDetails - phoneNumber value: ${details['phoneNumber']}');
    
    if (!details.containsKey('phoneNumber') || details['phoneNumber'].toString().isEmpty) {
      debugPrint('🔍 [DEBUG] _validateMobileMoneyDetails - ERREUR: Numéro de téléphone manquant ou vide');
      return 'Le numéro de téléphone est requis';
    }
    
    final phoneNumber = details['phoneNumber'].toString();
    
    // Validation du format du numéro de téléphone selon l'opérateur (alignée avec le backend)
    switch (method) {
      case AfricanPaymentMethod.wave:
        // Format Wave: Côte d'Ivoire - Orange Money (07, 47, 67) - 8 à 10 chiffres
        if (!RegExp(r'^(\+225)?(07|47|67)\d{6,8}$').hasMatch(phoneNumber.replaceAll(' ', ''))) {
          return 'Format de numéro Wave invalide (Orange Money CI: 07, 47, 67)';
        }
        break;
      case AfricanPaymentMethod.orangeMoney:
        // Format Orange Money: Côte d'Ivoire (07, 47, 67) - 8 à 10 chiffres
        if (!RegExp(r'^(\+225)?(07|47|67)\d{6,8}$').hasMatch(phoneNumber.replaceAll(' ', ''))) {
          return 'Format de numéro Orange Money invalide (07, 47, 67)';
        }
        break;
      case AfricanPaymentMethod.mtnMoney:
        // Format MTN Money: Côte d'Ivoire (05, 45, 65) - 8 à 10 chiffres
        if (!RegExp(r'^(\+225)?(05|45|65)\d{6,8}$').hasMatch(phoneNumber.replaceAll(' ', ''))) {
          return 'Format de numéro MTN Money invalide (05, 45, 65)';
        }
        break;
      case AfricanPaymentMethod.moovMoney:
        // Format Moov Money: Côte d'Ivoire (01, 41, 61) - 8 à 10 chiffres
        if (!RegExp(r'^(\+225)?(01|41|61)\d{6,8}$').hasMatch(phoneNumber.replaceAll(' ', ''))) {
          return 'Format de numéro Moov Money invalide (01, 41, 61)';
        }
        break;
      default:
        break;
    }
    
    return null;
  }
  
  /// Valide les détails d'un virement bancaire
  String? _validateBankTransferDetails(Map<String, dynamic> details) {
    if (!details.containsKey('bankName') || details['bankName'].toString().isEmpty) {
      return 'Le nom de la banque est requis';
    }
    
    if (!details.containsKey('accountNumber') || details['accountNumber'].toString().isEmpty) {
      return 'Le numéro de compte est requis';
    }
    
    if (!details.containsKey('accountName') || details['accountName'].toString().isEmpty) {
      return 'Le nom du titulaire du compte est requis';
    }
    
    // Validation du format IBAN si présent
    if (details.containsKey('iban') && details['iban'].toString().isNotEmpty) {
      final iban = details['iban'].toString().toUpperCase().replaceAll(' ', '');
      
      // Validation de base d'un IBAN (format simplifié)
      if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{4,}$').hasMatch(iban)) {
        return 'Format IBAN invalide';
      }
    }
    
    return null;
  }
  
  /// Valide les détails d'une carte bancaire
  String? _validateCardDetails(Map<String, dynamic> details) {
    // Pour des raisons de sécurité, nous ne stockons généralement pas les détails complets de la carte
    // Mais nous pouvons valider certaines informations comme le nom du titulaire
    if (details.containsKey('holderName') && details['holderName'].toString().isEmpty) {
      return 'Le nom du titulaire de la carte est requis';
    }
    
    return null;
  }
  
  /// Valide les détails PayPal
  String? _validatePaypalDetails(Map<String, dynamic> details) {
    if (!details.containsKey('email') || details['email'].toString().isEmpty) {
      return 'L\'email PayPal est requis';
    }
    
    final email = details['email'].toString();
    
    // Validation basique d'email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Format d\'email PayPal invalide';
    }
    
    return null;
  }
  
  /// Valide les détails Stripe
  String? _validateStripeDetails(Map<String, dynamic> details) {
    if (!details.containsKey('email') || details['email'].toString().isEmpty) {
      return 'L\'email Stripe est requis';
    }
    
    final email = details['email'].toString();
    
    // Validation basique d'email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Format d\'email Stripe invalide';
    }
    
    return null;
  }
  
  /// Retourne les informations sur les commissions par méthode de paiement
  Map<AfricanPaymentMethod, Map<String, dynamic>> getCommissionInfo() {
    return {
      AfricanPaymentMethod.wave: {
        'rate': 0.01, // 1%
        'fixed': 0, // Pas de frais fixe
        'min': 100, // Montant minimum
        'max': 1000000, // Montant maximum
        'processingTime': 'Instantané'
      },
      AfricanPaymentMethod.orangeMoney: {
        'rate': 0.015, // 1.5%
        'fixed': 100, // Frais fixe
        'min': 100,
        'max': 1000000,
        'processingTime': 'Instantané'
      },
      AfricanPaymentMethod.mtnMoney: {
        'rate': 0.015, // 1.5%
        'fixed': 50, // Frais fixe
        'min': 100,
        'max': 500000,
        'processingTime': 'Instantané'
      },
      AfricanPaymentMethod.moovMoney: {
        'rate': 0.015, // 1.5%
        'fixed': 50, // Frais fixe
        'min': 100,
        'max': 500000,
        'processingTime': 'Instantané'
      },
      AfricanPaymentMethod.visa: {
        'rate': 0.03, // 3%
        'fixed': 0, // Pas de frais fixe
        'min': 1000,
        'max': 5000000,
        'processingTime': 'Instantané'
      },
      AfricanPaymentMethod.mastercard: {
        'rate': 0.03, // 3%
        'fixed': 0, // Pas de frais fixe
        'min': 1000,
        'max': 5000000,
        'processingTime': 'Instantané'
      },
      AfricanPaymentMethod.paypal: {
        'rate': 0.039, // 3.9%
        'fixed': 500, // Frais fixe
        'min': 1000,
        'max': 10000000,
        'processingTime': '2-3 jours'
      },
      AfricanPaymentMethod.stripe: {
        'rate': 0.029, // 2.9%
        'fixed': 300, // Frais fixe
        'min': 1000,
        'max': 50000000,
        'processingTime': '2-7 jours'
      },
      AfricanPaymentMethod.bankTransfer: {
        'rate': 0.01, // 1%
        'fixed': 1000, // Frais fixe
        'min': 10000,
        'max': 100000000,
        'processingTime': '1-3 jours ouvrés'
      },
      AfricanPaymentMethod.cash: {
        'rate': 0, // Pas de commission
        'fixed': 0, // Pas de frais fixe
        'min': 0,
        'max': 1000000,
        'processingTime': 'Instantané'
      },
      AfricanPaymentMethod.bankCard: {
        'rate': 0.025, // 2.5%
        'fixed': 200, // Frais fixe
        'min': 1000,
        'max': 5000000,
        'processingTime': 'Instantané'
      },
    };
  }
  
  /// Retourne les informations de limite par jour et par transaction pour chaque méthode
  Map<AfricanPaymentMethod, Map<String, dynamic>> getLimitsInfo() {
    return {
      AfricanPaymentMethod.wave: {
        'dailyLimit': 2000000, // Limite quotidienne
        'transactionLimit': 1000000, // Limite par transaction
        'monthlyLimit': 10000000, // Limite mensuelle
      },
      AfricanPaymentMethod.orangeMoney: {
        'dailyLimit': 1500000,
        'transactionLimit': 1000000,
        'monthlyLimit': 5000000,
      },
      AfricanPaymentMethod.mtnMoney: {
        'dailyLimit': 1000000,
        'transactionLimit': 500000,
        'monthlyLimit': 3000000,
      },
      AfricanPaymentMethod.moovMoney: {
        'dailyLimit': 1000000,
        'transactionLimit': 500000,
        'monthlyLimit': 3000000,
      },
      AfricanPaymentMethod.visa: {
        'dailyLimit': 5000000,
        'transactionLimit': 5000000,
        'monthlyLimit': 20000000,
      },
      AfricanPaymentMethod.mastercard: {
        'dailyLimit': 5000000,
        'transactionLimit': 5000000,
        'monthlyLimit': 20000000,
      },
      AfricanPaymentMethod.paypal: {
        'dailyLimit': 10000000,
        'transactionLimit': 10000000,
        'monthlyLimit': 50000000,
      },
      AfricanPaymentMethod.stripe: {
        'dailyLimit': 50000000,
        'transactionLimit': 50000000,
        'monthlyLimit': 100000000,
      },
      AfricanPaymentMethod.bankTransfer: {
        'dailyLimit': 100000000,
        'transactionLimit': 100000000,
        'monthlyLimit': 500000000,
      },
      AfricanPaymentMethod.cash: {
        'dailyLimit': 1000000,
        'transactionLimit': 1000000,
        'monthlyLimit': 5000000,
      },
      AfricanPaymentMethod.bankCard: {
        'dailyLimit': 5000000,
        'transactionLimit': 5000000,
        'monthlyLimit': 20000000,
      },
    };
  }
  
  AfricanPaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'wave':
        return AfricanPaymentMethod.wave;
      case 'orangemoney':
      case 'orange_money':
      case 'orange':
        return AfricanPaymentMethod.orangeMoney;
      case 'mtnmoney':
      case 'mtn_money':
      case 'mtn':
        return AfricanPaymentMethod.mtnMoney;
      case 'moovmoney':
      case 'moov_money':
      case 'moov':
        return AfricanPaymentMethod.moovMoney;
      case 'cash':
      case 'especes':
      case 'espèces':
        return AfricanPaymentMethod.cash;
      case 'bankcard':
      case 'bank_card':
      case 'card':
      case 'carte':
        return AfricanPaymentMethod.bankCard;
      case 'banktransfer':
      case 'bank_transfer':
      case 'transfer':
      case 'virement':
        return AfricanPaymentMethod.bankTransfer;
      default:
        throw Exception('Méthode de paiement non reconnue: $method');
    }
  }
}
