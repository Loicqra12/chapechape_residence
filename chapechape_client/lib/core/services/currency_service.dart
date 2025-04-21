import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/formatters.dart';

/// Service pour gérer les devises dans l'application
class CurrencyService {
  // Singleton instance
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  // Clé pour les préférences
  static const String _prefKey = 'user_currency';

  // Devise par défaut
  static const String defaultCurrency = PriceFormatter.defaultCurrency;

  // Devises disponibles
  static const List<String> availableCurrencies = ['FCFA', 'EUR', 'USD', 'GBP'];

  // Devise actuelle de l'utilisateur
  String _currentCurrency = defaultCurrency;
  String get currentCurrency => _currentCurrency;

  // Initialiser le service
  Future<void> initialize() async {
    await loadPreferredCurrency();
    await updateExchangeRates();
  }

  // Charger la devise préférée de l'utilisateur
  Future<void> loadPreferredCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentCurrency = prefs.getString(_prefKey) ?? defaultCurrency;
    } catch (e) {
      print('Erreur lors du chargement de la devise préférée: $e');
      _currentCurrency = defaultCurrency;
    }
  }

  // Changer la devise préférée de l'utilisateur
  Future<bool> setPreferredCurrency(String currency) async {
    if (!availableCurrencies.contains(currency)) {
      return false;
    }

    try {
      _currentCurrency = currency;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, currency);
      return true;
    } catch (e) {
      print('Erreur lors de la sauvegarde de la devise préférée: $e');
      return false;
    }
  }

  // Mettre à jour les taux de change
  Future<bool> updateExchangeRates() async {
    try {
      // Ceci est un exemple, vous devriez utiliser une vraie API de taux de change
      // Comme https://exchangeratesapi.io/ ou autre
      
      // Simulation d'une mise à jour
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Appeler la méthode de mise à jour de CurrencyConverter
      await CurrencyConverter.updateConversionRates();
      
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour des taux de change: $e');
      return false;
    }
  }

  // Convertir un prix à la devise actuelle de l'utilisateur
  double convertToUserCurrency(double amount, String fromCurrency) {
    return CurrencyConverter.convert(amount, fromCurrency, _currentCurrency);
  }

  // Formater un prix dans la devise actuelle de l'utilisateur
  String formatInUserCurrency(double amount, String fromCurrency) {
    final convertedAmount = convertToUserCurrency(amount, fromCurrency);
    return PriceFormatter.formatPriceWithCurrency(convertedAmount, _currentCurrency);
  }
} 