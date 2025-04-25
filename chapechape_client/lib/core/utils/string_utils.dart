class StringUtils {
  // Transforme une chaîne en titre (capitalise chaque mot)
  static String toTitleCase(String text) {
    if (text.isEmpty) return '';
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  // Ajoute des espaces entre les mots en camelCase
  static String camelCaseToSentence(String text) {
    if (text.isEmpty) return '';
    
    return text.replaceAllMapped(
      RegExp(r'(?<=[a-z])[A-Z]'),
      (match) => ' ${match.group(0)}'
    ).capitalizeFirst;
  }
  
  // Formate un prix en chaîne de caractères
  static String formatPrice(dynamic price, {String currencySymbol = 'FCFA', bool showDecimal = false}) {
    if (price == null) return 'Prix non disponible';
    
    double numericPrice;
    try {
      numericPrice = double.parse(price.toString());
    } catch (_) {
      return 'Prix invalide';
    }
    
    final formatter = showDecimal
        ? numericPrice.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match.group(1)} '
          )
        : numericPrice.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
            (match) => '${match.group(1)} '
          );
    
    return '$formatter $currencySymbol';
  }
  
  // Tronque une chaîne à la longueur maximale
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
  
  // Formate un nombre entier (1000 -> 1k, 1000000 -> 1M)
  static String formatNumber(int number) {
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(1)}k';
    return '${(number / 1000000).toStringAsFixed(1)}M';
  }
  
  // Vérifie si une chaîne est vide ou null
  static bool isNullOrEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }
  
  // Extrait le nom de domaine d'une URL
  static String getDomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }
  
  // Formate un numéro de téléphone
  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length != 10) return phoneNumber;
    
    return '${phoneNumber.substring(0, 2)} ${phoneNumber.substring(2, 4)} ${phoneNumber.substring(4, 6)} ${phoneNumber.substring(6, 8)} ${phoneNumber.substring(8)}';
  }
}

// Extensions sur String
extension StringExtension on String {
  String get capitalizeFirst {
    if (isEmpty) return '';
    return this[0].toUpperCase() + substring(1);
  }
  
  String get capitalizEach {
    if (isEmpty) return '';
    return split(' ').map((word) => word.capitalizeFirst).join(' ');
  }
} 