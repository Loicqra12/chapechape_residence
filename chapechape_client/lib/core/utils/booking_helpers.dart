import 'package:flutter/material.dart';
import 'package:chapechape_client/core/models/booking_model.dart';

/// Classe d'utilitaires pour aider à gérer les réservations
class BookingHelpers {
  /// Vérifie si une modification de réservation est permise
  /// Retourne true si la modification est autorisée, sinon false
  static bool canModifyBooking(Booking booking) {
    // Statuts qui empêchent la modification
    const List<String> nonModifiableStatuses = [
      'cancelled', 'completed', 'expired', 'pending_cancellation'
    ];
    
    // Vérifier si le statut actuel permet la modification
    if (nonModifiableStatuses.contains(booking.status.toLowerCase())) {
      return false;
    }
    
    // Vérifier si la date de début est trop proche (moins de 24h)
    final now = DateTime.now();
    final checkIn = booking.checkIn;
    final difference = checkIn.difference(now).inHours;
    
    // Empêcher les modifications moins de 24h avant le début
    if (difference < 24) {
      return false;
    }
    
    return true;
  }
  
  /// Vérifie si une annulation de réservation est permise
  /// Retourne true si l'annulation est autorisée, sinon false
  static bool canCancelBooking(Booking booking) {
    // Statuts qui empêchent l'annulation
    const List<String> nonCancellableStatuses = [
      'cancelled', 'completed', 'expired', 'pending_cancellation'
    ];
    
    // Vérifier si le statut actuel permet l'annulation
    if (nonCancellableStatuses.contains(booking.status.toLowerCase())) {
      return false;
    }
    
    // Vérifier si la date de début est déjà passée
    final now = DateTime.now();
    if (booking.checkIn.isBefore(now)) {
      return false;
    }
    
    return true;
  }
  
  /// Calcule le prix total de la réservation
  /// Si booking est null, utilise les paramètres fournis pour calculer le prix
  static double calculateTotalPrice(
    Booking? booking, {
    double? basePrice,
    DateTime? checkIn,
    DateTime? checkOut,
    int? numberOfGuests,
    double? cleaningFee = 0.0,
    double? serviceFee = 0.0,
    double? discountPercentage = 0.0,
  }) {
    // Si un objet booking est fourni, utiliser ses valeurs
    if (booking != null) {
      return booking.totalPrice;
    }
    
    // Sinon, calculer le prix à partir des paramètres fournis
    if (basePrice == null || checkIn == null || checkOut == null) {
      throw ArgumentError('basePrice, checkIn et checkOut sont requis quand booking est null');
    }
    
    // Calculer le nombre de nuits
    final nights = checkOut.difference(checkIn).inDays;
    if (nights <= 0) {
      throw ArgumentError('La date de départ doit être postérieure à la date d\'arrivée');
    }
    
    // Prix de base pour la durée du séjour
    double totalPrice = basePrice * nights;
    
    // Ajuster selon le nombre d'invités si nécessaire
    final guests = numberOfGuests ?? 1;
    if (guests > 2) {
      // Ajouter un supplément de 10% par invité supplémentaire au-delà de 2
      final extraGuestFee = basePrice * 0.1 * (guests - 2) * nights;
      totalPrice += extraGuestFee;
    }
    
    // Ajouter les frais de ménage
    if (cleaningFee != null && cleaningFee > 0) {
      totalPrice += cleaningFee;
    }
    
    // Ajouter les frais de service
    if (serviceFee != null && serviceFee > 0) {
      totalPrice += serviceFee;
    }
    
    // Appliquer la réduction si présente
    if (discountPercentage != null && discountPercentage > 0) {
      final discount = totalPrice * (discountPercentage / 100);
      totalPrice -= discount;
    }
    
    return totalPrice;
  }
  
  /// Calcule le prix par nuit
  static double calculatePricePerNight(Booking booking) {
    final nights = booking.nights;
    return nights > 0 ? booking.totalPrice / nights : booking.totalPrice;
  }
  
  /// Calcule la durée de séjour en nuits
  static int calculateStayDuration(Booking booking) {
    return booking.checkOut.difference(booking.checkIn).inDays;
  }
  
  /// Formate une date au format local préféré (jour-mois-année)
  static String formatDate(DateTime date, {Locale locale = const Locale('fr')}) {
    if (locale.languageCode == 'fr') {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } else {
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }
  
  /// Retourne un libellé de statut traduit selon la langue
  static String getStatusLabel(String status, {Locale locale = const Locale('fr')}) {
    final statusMap = {
      'fr': {
        'pending': 'En attente',
        'confirmed': 'Confirmée',
        'in_progress': 'En cours',
        'completed': 'Terminée',
        'cancelled': 'Annulée',
        'pending_cancellation': 'Annulation en cours',
        'expired': 'Expirée',
      },
      'en': {
        'pending': 'Pending',
        'confirmed': 'Confirmed',
        'in_progress': 'In progress',
        'completed': 'Completed',
        'cancelled': 'Cancelled',
        'pending_cancellation': 'Cancellation pending',
        'expired': 'Expired',
      }
    };
    
    final languageCode = locale.languageCode;
    final translations = statusMap[languageCode] ?? statusMap['en']!;
    
    return translations[status.toLowerCase()] ?? status;
  }
  
  /// Retourne la couleur associée au statut de la réservation
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.indigo;
      case 'cancelled':
        return Colors.red;
      case 'pending_cancellation':
        return Colors.deepOrange;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
  
  /// Vérifie si la réservation est active (en cours ou à venir)
  static bool isActiveBooking(Booking booking) {
    const List<String> activeStatuses = ['confirmed', 'in_progress', 'pending'];
    final now = DateTime.now();
    
    return activeStatuses.contains(booking.status.toLowerCase()) && 
           booking.checkOut.isAfter(now);
  }
}
