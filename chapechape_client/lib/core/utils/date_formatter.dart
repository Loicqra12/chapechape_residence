import 'package:intl/intl.dart';

class DateFormatter {
  static String formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Aujourd'hui, afficher l'heure
      return DateFormat.Hm().format(dateTime);
    } else if (messageDate == yesterday) {
      // Hier
      return 'Hier';
    } else if (now.difference(dateTime).inDays < 7) {
      // Cette semaine, afficher le jour
      return DateFormat.E().format(dateTime);
    } else {
      // Plus ancien, afficher la date
      return DateFormat.yMd().format(dateTime);
    }
  }

  static String formatLastMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} j';
    } else {
      return DateFormat.MMMd().format(dateTime);
    }
  }
  
  static String formatReviewDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
  
  static String formatBookingDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
  
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours heure${hours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days jour${days > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks semaine${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months mois ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years an${years > 1 ? 's' : ''} ago';
    }
  }
  
  static String formatMessageTime(DateTime dateTime) {
    return DateFormat.Hm().format(dateTime);
  }
  
  static String formatTime(DateTime dateTime) {
    return DateFormat.Hm().format(dateTime);
  }
}
