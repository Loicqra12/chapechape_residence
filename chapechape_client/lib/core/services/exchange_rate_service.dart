import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service qui gère la récupération des taux de change depuis une API externe
class ExchangeRateService {
  // Singleton
  static final ExchangeRateService _instance = ExchangeRateService._internal();
  factory ExchangeRateService() => _instance;
  ExchangeRateService._internal();

  // API endpoints - vous devrez vous inscrire pour obtenir une clé API
  // Exemples d'APIs:
  // - https://exchangeratesapi.io/
  // - https://openexchangerates.org/
  // - https://fixer.io/
  static const String _apiUrl = 'https://api.exchangerate.host/latest';
  
  // Clé pour le cache
  static const String _cacheKey = 'exchange_rates_cache';
  static const Duration _cacheDuration = Duration(hours: 12);
  
  // Devise de base (celle utilisée par l'API)
  static const String _baseCurrency = 'EUR';
  
  // Devises suivies
  static const List<String> _trackedCurrencies = ['EUR', 'USD', 'GBP', 'XOF']; // XOF = FCFA

  // Taux de change
  Map<String, double> _rates = {};
  Map<String, double> get rates => _rates;
  
  // Date de dernière mise à jour
  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;
  
  // Initialisation du service
  Future<void> initialize() async {
    await _loadCachedRates();
    // Si le cache est vide ou trop ancien, rafraîchir les taux
    if (_rates.isEmpty || _shouldRefreshRates()) {
      await fetchLatestRates();
    }
  }
  
  // Vérifier si les taux doivent être rafraîchis
  bool _shouldRefreshRates() {
    if (_lastUpdated == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(_lastUpdated!);
    return difference > _cacheDuration;
  }
  
  // Charger les taux depuis le cache
  Future<void> _loadCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      
      if (cachedData != null && cachedData.isNotEmpty) {
        final data = jsonDecode(cachedData);
        
        _lastUpdated = DateTime.parse(data['timestamp']);
        
        final ratesData = data['rates'] as Map<String, dynamic>;
        _rates = ratesData.map((key, value) => 
          MapEntry(key, (value is num) ? value.toDouble() : 0.0));
      }
    } catch (e) {
      print('Erreur lors du chargement des taux de change depuis le cache: $e');
      _rates = {};
      _lastUpdated = null;
    }
  }
  
  // Enregistrer les taux dans le cache
  Future<void> _saveRatesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'timestamp': _lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'rates': _rates,
      };
      
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (e) {
      print('Erreur lors de la sauvegarde des taux de change dans le cache: $e');
    }
  }
  
  // Récupérer les derniers taux depuis l'API
  Future<bool> fetchLatestRates() async {
    try {
      // Note: Dans la version réelle, il faut ajouter votre clé API
      // Pour cet exemple, on utilise une API gratuite sans clé
      final response = await http.get(Uri.parse('$_apiUrl?base=$_baseCurrency&symbols=${_trackedCurrencies.join(',')}'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Mettre à jour les taux
        final ratesData = data['rates'] as Map<String, dynamic>;
        _rates = {};
        
        // Ajouter la devise de base (taux = 1)
        _rates[_baseCurrency] = 1.0;
        
        // Ajouter les autres devises
        for (final currency in _trackedCurrencies) {
          if (currency != _baseCurrency && ratesData.containsKey(currency)) {
            if (ratesData[currency] is num) {
              _rates[currency] = (ratesData[currency] as num).toDouble();
            }
          }
        }
        
        // Ajouter le taux pour FCFA (qui est fixe par rapport à l'EUR)
        // 1 EUR = 655.957 FCFA (taux fixe)
        _rates['FCFA'] = 655.957;
        
        // Mettre à jour la date
        _lastUpdated = DateTime.now();
        
        // Sauvegarder dans le cache
        await _saveRatesToCache();
        
        return true;
      } else {
        print('Erreur lors de la récupération des taux de change: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Exception lors de la récupération des taux de change: $e');
      return false;
    }
  }
  
  // Convertir un montant d'une devise à une autre
  double convert(double amount, String fromCurrency, String toCurrency) {
    // Si les devises sont identiques, pas de conversion nécessaire
    if (fromCurrency == toCurrency) return amount;
    
    // Si les taux ne sont pas disponibles, retourner le montant original
    if (_rates.isEmpty || !_rates.containsKey(fromCurrency) || !_rates.containsKey(toCurrency)) {
      return amount;
    }
    
    // Convertir via la devise de base (EUR)
    // 1. Convertir le montant dans la devise de base
    final amountInBaseCurrency = (fromCurrency == _baseCurrency) 
        ? amount 
        : amount / _rates[fromCurrency]!;
        
    // 2. Convertir de la devise de base à la devise cible
    return (toCurrency == _baseCurrency) 
        ? amountInBaseCurrency 
        : amountInBaseCurrency * _rates[toCurrency]!;
  }
} 