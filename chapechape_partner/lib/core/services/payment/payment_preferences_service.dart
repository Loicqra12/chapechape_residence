import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/payment/african_payment_method.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

/// Service pour gérer le stockage local des préférences de paiement
class PaymentPreferencesService {
  // Clés de stockage
  static const String _acceptedMethodsKey = 'accepted_payment_methods';
  static const String _methodDetailsPrefix = 'payment_method_details_';
  
  /// Sauvegarde les méthodes de paiement acceptées
  Future<bool> saveAcceptedMethods(List<AfricanPaymentMethod> methods) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final methodsAsStrings = methods.map((m) => m.toString().split('.').last).toList();
      
      return await prefs.setStringList(_acceptedMethodsKey, methodsAsStrings);
    } catch (e) {
      AppLogger.d('❌ Erreur lors de la sauvegarde des méthodes de paiement: $e');
      return false;
    }
  }
  
  /// Récupère les méthodes de paiement acceptées
  Future<List<AfricanPaymentMethod>> getAcceptedMethods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final methodsAsStrings = prefs.getStringList(_acceptedMethodsKey) ?? [];
      
      return methodsAsStrings.map(_parsePaymentMethod).toList();
    } catch (e) {
      AppLogger.d('❌ Erreur lors de la récupération des méthodes de paiement: $e');
      return [];
    }
  }
  
  /// Sauvegarde les détails d'une méthode de paiement
  Future<bool> saveMethodDetails(AfricanPaymentMethod method, Map<String, dynamic> details) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getMethodDetailsKey(method);
      final detailsJson = jsonEncode(details);
      
      return await prefs.setString(key, detailsJson);
    } catch (e) {
      AppLogger.d('❌ Erreur lors de la sauvegarde des détails de la méthode de paiement: $e');
      return false;
    }
  }
  
  /// Récupère les détails d'une méthode de paiement
  Future<Map<String, dynamic>?> getMethodDetails(AfricanPaymentMethod method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getMethodDetailsKey(method);
      final detailsJson = prefs.getString(key);
      
      if (detailsJson == null) {
        return null;
      }
      
      return jsonDecode(detailsJson) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.d('❌ Erreur lors de la récupération des détails de la méthode de paiement: $e');
      return null;
    }
  }
  
  /// Récupère les détails de toutes les méthodes de paiement
  Future<Map<AfricanPaymentMethod, Map<String, dynamic>>> getAllMethodDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final acceptedMethods = await getAcceptedMethods();
      final result = <AfricanPaymentMethod, Map<String, dynamic>>{};
      
      for (final method in acceptedMethods) {
        final key = _getMethodDetailsKey(method);
        final detailsJson = prefs.getString(key);
        
        if (detailsJson != null) {
          result[method] = jsonDecode(detailsJson) as Map<String, dynamic>;
        }
      }
      
      return result;
    } catch (e) {
      AppLogger.d('❌ Erreur lors de la récupération des détails des méthodes de paiement: $e');
      return {};
    }
  }
  
  /// Supprime une méthode de paiement et ses détails
  Future<bool> removeMethod(AfricanPaymentMethod method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final acceptedMethods = await getAcceptedMethods();
      
      // Supprimer la méthode de la liste des méthodes acceptées
      acceptedMethods.remove(method);
      
      // Sauvegarder la nouvelle liste
      final methodsAsStrings = acceptedMethods.map((m) => m.toString().split('.').last).toList();
      await prefs.setStringList(_acceptedMethodsKey, methodsAsStrings);
      
      // Supprimer les détails de la méthode
      final key = _getMethodDetailsKey(method);
      await prefs.remove(key);
      
      return true;
    } catch (e) {
      AppLogger.d('❌ Erreur lors de la suppression de la méthode de paiement: $e');
      return false;
    }
  }
  
  // Génère la clé pour les détails d'une méthode de paiement
  String _getMethodDetailsKey(AfricanPaymentMethod method) {
    return _methodDetailsPrefix + method.toString().split('.').last;
  }
  
  // Parse une chaîne en méthode de paiement
  AfricanPaymentMethod _parsePaymentMethod(String methodString) {
    switch (methodString.toLowerCase()) {
      case 'wave':
        return AfricanPaymentMethod.wave;
      case 'orangemoney':
        return AfricanPaymentMethod.orangeMoney;
      case 'mtnmoney':
        return AfricanPaymentMethod.mtnMoney;
      case 'moovmoney':
        return AfricanPaymentMethod.moovMoney;
      case 'cash':
        return AfricanPaymentMethod.cash;
      case 'bankcard':
        return AfricanPaymentMethod.bankCard;
      case 'banktransfer':
        return AfricanPaymentMethod.bankTransfer;
      case 'visa':
        return AfricanPaymentMethod.visa;
      case 'mastercard':
        return AfricanPaymentMethod.mastercard;
      case 'paypal':
        return AfricanPaymentMethod.paypal;
      case 'stripe':
        return AfricanPaymentMethod.stripe;
      default:
        throw Exception('Méthode de paiement non reconnue: $methodString');
    }
  }
}
