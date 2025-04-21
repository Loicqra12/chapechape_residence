import 'package:shared_preferences/shared_preferences.dart';
import '../utils/formatters.dart';

/// Service pour gérer les devises dans l'application
class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  
  factory CurrencyService() => _instance;
  
  CurrencyService._internal();
  
  /// Clé pour stocker la devise préférée dans les préférences
  static const String _prefsKey = 'preferred_currency';
  
  /// Devise par défaut
  static const String _defaultCurrency = 'FCFA';
  
  /// Devise actuellement sélectionnée
  String _currentCurrency = _defaultCurrency;
  
  /// Liste des devises disponibles
  final List<String> availableCurrencies = ['FCFA', 'EUR', 'USD', 'GBP'];
  
  /// Getter pour obtenir la devise actuelle
  String get currentCurrency => _currentCurrency;
  
  /// Initialise le service
  Future<void> initialize() async {
    await loadPreferredCurrency();
  }
  
  /// Charge la devise préférée depuis les préférences
  Future<void> loadPreferredCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentCurrency = prefs.getString(_prefsKey) ?? _defaultCurrency;
    } catch (e) {
      print('Erreur lors du chargement de la devise préférée: $e');
      _currentCurrency = _defaultCurrency;
    }
  }
  
  /// Définit la devise préférée
  Future<void> setPreferredCurrency(String currency) async {
    if (!availableCurrencies.contains(currency)) {
      throw Exception('Devise non supportée: $currency');
    }
    
    _currentCurrency = currency;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, currency);
    } catch (e) {
      print('Erreur lors de la sauvegarde de la devise préférée: $e');
    }
  }
  
  /// Convertit un montant vers la devise préférée de l'utilisateur
  double convertToUserCurrency(double amount, String fromCurrency) {
    return CurrencyConverter.convert(amount, fromCurrency, _currentCurrency);
  }
  
  /// Formate un prix dans la devise préférée de l'utilisateur
  String formatInUserCurrency(double amount, {bool withCurrency = true}) {
    return PriceFormatter.formatPrice(
      amount, 
      withCurrency: withCurrency, 
      currency: _currentCurrency,
    );
  }
  
  /// Convertit et formate un montant dans la devise de l'utilisateur
  String convertAndFormat(double amount, String fromCurrency, {bool withCurrency = true}) {
    final convertedAmount = convertToUserCurrency(amount, fromCurrency);
    return formatInUserCurrency(convertedAmount, withCurrency: withCurrency);
  }
} 