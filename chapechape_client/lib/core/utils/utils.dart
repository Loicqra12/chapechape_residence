import 'package:intl/intl.dart';

/// Formate un montant en monnaie avec le symbole FCFA
String formatCurrency(dynamic amount, {bool showSymbol = true}) {
  if (amount == null) return '0 FCFA';
  
  final formatter = NumberFormat.currency(
    locale: 'fr_CI',
    symbol: showSymbol ? 'FCFA' : '',
    decimalDigits: 0,
  );
  
  try {
    final value = amount is String ? double.tryParse(amount) ?? 0 : (amount as num).toDouble();
    return formatter.format(value);
  } catch (e) {
    return '0 FCFA';
  }
}

/// Formate une date au format jour/mois/année
String formatDate(DateTime? date) {
  if (date == null) return '';
  
  final formatter = DateFormat('dd/MM/yyyy');
  return formatter.format(date);
}

/// Convertit une chaîne en DateTime
DateTime? parseDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return null;
  
  try {
    return DateFormat('yyyy-MM-dd').parse(dateStr);
  } catch (e) {
    return null;
  }
}

/// Tronque un texte à la longueur spécifiée
String truncateText(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

/// Récupère l'extension d'un fichier à partir de son chemin
String getFileExtension(String path) {
  return path.split('.').last.toLowerCase();
}

/// Vérifie si un fichier est une image basé sur son extension
bool isImageFile(String path) {
  final extension = getFileExtension(path);
  return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
}

/// Vérifie si un fichier est une vidéo basé sur son extension
bool isVideoFile(String path) {
  final extension = getFileExtension(path);
  return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
} 