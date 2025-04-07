/// Utilitaires pour les chaînes de caractères
class StringUtils {
  /// Convertit une chaîne en format titre (première lettre de chaque mot en majuscule)
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Tronque une chaîne si elle dépasse la longueur maximale
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }

  /// Capitalise la première lettre d'une chaîne
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Formate un prix avec séparateurs de milliers
  static String formatPrice(double price, {String currency = 'FCFA'}) {
    String priceStr = price.toStringAsFixed(0);
    final pattern = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    priceStr = priceStr.replaceAllMapped(pattern, (Match m) => '${m[1]} ');
    return '$priceStr $currency';
  }

  /// Formate une surface en mètres carrés
  static String formatSurface(double surface) {
    return '${surface.toStringAsFixed(0)} m²';
  }

  /// Retire les accents d'une chaîne
  static String removeAccents(String text) {
    const withAccents = 'àáâäæãåāăąçćčđďèéêëēėęěğǵḧîïíīįìıİłḿñńǹňôöòóœøōõőṕŕřßśšşșťțûüùúūǘůűųẃẍÿýžźż';
    const withoutAccents = 'aaaaaaaaaacccddeeeeeeeegghiiiiiiiilmnnnnoooooooooprrsssssttuuuuuuuuuwxyyzzz';
    
    String result = text;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    
    return result;
  }

  /// Génère un slug à partir d'une chaîne (pour URLs)
  static String slugify(String text) {
    String result = removeAccents(text.toLowerCase());
    result = result.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    result = result.replaceAll(RegExp(r'\s+'), '-');
    result = result.replaceAll(RegExp(r'-+'), '-');
    return result.trim();
  }
} 