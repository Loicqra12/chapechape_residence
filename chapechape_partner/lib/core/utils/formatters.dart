import 'package:intl/intl.dart';

/// Classe utilitaire pour le formatage des prix dans différentes devises
class PriceFormatter {
  /// Formats monataires pour différentes devises
  static final Map<String, CurrencyFormat> _currencyFormats = {
    'FCFA': CurrencyFormat(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
      symbolAfter: true,
    ),
    'EUR': CurrencyFormat(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
      symbolAfter: true,
    ),
    'USD': CurrencyFormat(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
      symbolAfter: false,
    ),
    'GBP': CurrencyFormat(
      locale: 'en_GB',
      symbol: '£',
      decimalDigits: 2,
      symbolAfter: false,
    ),
  };

  /// Formate un prix selon la devise spécifiée
  /// 
  /// [amount] : Le montant à formater
  /// [withCurrency] : Indique si le symbole de la devise doit être inclus
  /// [currency] : La devise à utiliser (par défaut FCFA)
  static String formatPrice(double amount, {
    bool withCurrency = true,
    String currency = 'FCFA',
  }) {
    final format = _currencyFormats[currency] ?? _currencyFormats['FCFA']!;
    
    final formatter = NumberFormat.currency(
      locale: format.locale,
      symbol: withCurrency ? format.symbol : '',
      decimalDigits: format.decimalDigits,
    );
    
    final formattedValue = formatter.format(amount);
    
    // Gestion du symbole après le montant si nécessaire
    if (withCurrency && format.symbolAfter) {
      // Supprime le symbole au début et l'ajoute à la fin avec un espace
      return formattedValue.replaceAll(format.symbol, '').trim() + ' ' + format.symbol;
    }
    
    return formattedValue;
  }

  /// Calcule et formate le prix avec remise
  static String formatDiscountPrice(double originalPrice, double discountPercent, {
    bool withCurrency = true,
    String currency = 'FCFA',
  }) {
    final discountAmount = originalPrice * (discountPercent / 100);
    final discountedPrice = originalPrice - discountAmount;
    return formatPrice(discountedPrice, withCurrency: withCurrency, currency: currency);
  }
}

/// Classe pour la conversion de devises
class CurrencyConverter {
  /// Table de conversion des devises (valeurs approximatives)
  static final Map<String, Map<String, double>> _rates = {
    'EUR': {'FCFA': 655.957, 'USD': 1.08, 'GBP': 0.85, 'EUR': 1.0},
    'FCFA': {'EUR': 0.00152, 'USD': 0.00164, 'GBP': 0.00129, 'FCFA': 1.0},
    'USD': {'EUR': 0.93, 'FCFA': 609.86, 'GBP': 0.79, 'USD': 1.0},
    'GBP': {'EUR': 1.18, 'FCFA': 774.26, 'USD': 1.27, 'GBP': 1.0},
  };

  /// Convertit un montant d'une devise à une autre
  static double convert(double amount, String fromCurrency, String toCurrency) {
    // Si les devises sont identiques, pas besoin de conversion
    if (fromCurrency == toCurrency) {
      return amount;
    }
    
    // Vérifier si les devises sont supportées
    if (!_rates.containsKey(fromCurrency) || !_rates[fromCurrency]!.containsKey(toCurrency)) {
      throw Exception('Devise non supportée: $fromCurrency ou $toCurrency');
    }
    
    // Conversion du montant
    return amount * _rates[fromCurrency]![toCurrency]!;
  }
  
  /// Obtient la date de dernière mise à jour des taux (simulée)
  static DateTime get lastUpdated => DateTime.now();
  
  /// Obtient toutes les devises disponibles
  static List<String> get availableCurrencies => _rates.keys.toList();
}

/// Classe pour stocker le format d'une devise
class CurrencyFormat {
  final String locale;
  final String symbol;
  final int decimalDigits;
  final bool symbolAfter;
  
  CurrencyFormat({
    required this.locale,
    required this.symbol,
    required this.decimalDigits,
    required this.symbolAfter,
  });
} 