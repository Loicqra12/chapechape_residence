import 'package:intl/intl.dart';
import '../services/exchange_rate_service.dart';

/// Classe pour gérer le formatage des prix
class PriceFormatter {
  // Devise par défaut de l'application
  static const String defaultCurrency = 'FCFA';
  
  // Map des formats pour différentes devises
  static final Map<String, NumberFormat> _currencyFormats = {
    'FCFA': NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    ),
    'EUR': NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    ),
    'USD': NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    ),
    'GBP': NumberFormat.currency(
      locale: 'en_GB',
      symbol: '£',
      decimalDigits: 2,
    ),
  };
  
  /// Formate un prix avec ou sans symbole de devise
  static String formatPrice(double price, {
    bool withCurrency = true,
    String currency = defaultCurrency,
  }) {
    // Obtenir le format pour la devise spécifiée ou utiliser le format par défaut
    final format = _currencyFormats[currency] ?? _currencyFormats[defaultCurrency]!;
    
    if (withCurrency) {
      return format.format(price);
    } else {
      // Format sans symbole de devise, juste les séparateurs numériques
      return NumberFormat('#,###', 'fr_FR').format(price);
    }
  }
  
  /// Formate un prix après une remise
  static String formatDiscount(double original, double discounted) {
    if (original <= 0 || discounted >= original) return '';
    int percentage = ((original - discounted) / original * 100).round();
    return '-$percentage%';
  }
  
  /// Formate un prix avec la devise et le symbole appropriés
  static String formatPriceWithCurrency(double price, String currency) {
    if (_currencyFormats.containsKey(currency)) {
      return _currencyFormats[currency]!.format(price);
    } else {
      // Fallback pour les devises non définies
      return '$price $currency';
    }
  }
}

/// Classe pour gérer la conversion de prix entre devises
class CurrencyConverter {
  // Service de taux de change
  static final ExchangeRateService _exchangeService = ExchangeRateService();
  
  /// Convertit un prix d'une devise à une autre
  static double convert(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) {
    // Si les devises sont identiques, pas besoin de conversion
    if (fromCurrency == toCurrency) return amount;
    
    // Utiliser le service de taux de change pour la conversion
    return _exchangeService.convert(amount, fromCurrency, toCurrency);
  }
  
  /// Récupère les taux de conversion depuis une API
  static Future<void> updateConversionRates() async {
    // Initialiser le service de taux de change s'il ne l'est pas déjà
    await _exchangeService.initialize();
    // Forcer la mise à jour des taux
    await _exchangeService.fetchLatestRates();
  }
  
  /// Récupère la date de dernière mise à jour des taux
  static DateTime? get lastUpdated => _exchangeService.lastUpdated;
  
  /// Récupère tous les taux de change disponibles
  static Map<String, double> get allRates => _exchangeService.rates;
} 