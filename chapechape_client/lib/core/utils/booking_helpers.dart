import 'package:flutter/material.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/models/reservation_status.dart';

/// Classe d'utilitaires pour aider à gérer les réservations
class BookingHelpers {
  
  /// Calcule le temps restant pour l'approbation de l'hôte en secondes
  /// Retourne 0 si le délai est expiré ou si pas en mode approval_required
  static int getHostApprovalTimeRemaining(Booking booking) {
    // Vérifier si la réservation nécessite une approbation
    if (booking.reservationMode != 'approval_required' ||
        booking.status.toLowerCase() != ReservationStatusCanon.awaitingApproval) {
      return 0;
    }
    
    // Si pas de deadline définie, utiliser la durée par défaut
    DateTime deadline;
    if (booking.hostApprovalDeadline != null) {
      deadline = booking.hostApprovalDeadline!;
    } else if (booking.createdAt != null) {
      // Calculer à partir de la création + durée
      deadline = booking.createdAt!.add(Duration(minutes: booking.hostApprovalTimerDuration));
    } else {
      // Fallback avec l'heure actuelle moins la durée (déjà expiré)
      return 0;
    }
    
    final now = DateTime.now();
    final difference = deadline.difference(now);
    
    return difference.inSeconds > 0 ? difference.inSeconds : 0;
  }
  
  /// Vérifie si le timer SLA hôte est actif et en cours
  static bool isHostApprovalTimerActive(Booking booking) {
    return booking.reservationMode == 'approval_required' &&
           booking.status.toLowerCase() == ReservationStatusCanon.awaitingApproval &&
           getHostApprovalTimeRemaining(booking) > 0;
  }
  
  /// Format le temps SLA en format MM:SS pour la UI
  static String formatHostApprovalTimeRemaining(int seconds) {
    if (seconds <= 0) return "00:00";
    
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }
  /// Vérifie si une modification de réservation est permise
  /// Retourne true si la modification est autorisée, sinon false
  static bool canModifyBooking(Booking booking) {
    // Statuts qui empêchent la modification
    const List<String> nonModifiableStatuses = [
      ReservationStatusCanon.cancelled,
      ReservationStatusCanon.completed,
      ReservationStatusCanon.expired,
      ReservationStatusCanon.refunded,
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
      ReservationStatusCanon.cancelled,
      ReservationStatusCanon.completed,
      ReservationStatusCanon.expired,
      ReservationStatusCanon.refunded,
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
    final canonical = ReservationStatusCanon.fromApi(status);
    final statusMap = {
      'fr': {
        ReservationStatusCanon.pending: 'En attente',
        ReservationStatusCanon.confirmed: 'Confirmée',
        ReservationStatusCanon.inStay: 'Séjour en cours',
        ReservationStatusCanon.completed: 'Terminée',
        ReservationStatusCanon.cancelled: 'Annulée',
        ReservationStatusCanon.expired: 'Expirée',
        ReservationStatusCanon.awaitingApproval: 'En attente d\'approbation',
        ReservationStatusCanon.paymentPending: 'Paiement en attente',
        ReservationStatusCanon.refunded: 'Remboursée',
        ReservationStatusCanon.unknown: 'Statut inconnu',
      },
      'en': {
        ReservationStatusCanon.pending: 'Pending',
        ReservationStatusCanon.confirmed: 'Confirmed',
        ReservationStatusCanon.inStay: 'In stay',
        ReservationStatusCanon.completed: 'Completed',
        ReservationStatusCanon.cancelled: 'Cancelled',
        ReservationStatusCanon.expired: 'Expired',
        ReservationStatusCanon.awaitingApproval: 'Awaiting Approval',
        ReservationStatusCanon.paymentPending: 'Payment Pending',
        ReservationStatusCanon.refunded: 'Refunded',
        ReservationStatusCanon.unknown: 'Unknown status',
      }
    };

    final languageCode = locale.languageCode;
    final translations = statusMap[languageCode] ?? statusMap['en']!;
    return translations[canonical] ?? canonical;
  }
  
  /// Retourne la couleur associée au statut de la réservation
  static Color getStatusColor(String status) {
    switch (ReservationStatusCanon.fromApi(status)) {
      case ReservationStatusCanon.pending:
        return Colors.orange;
      case ReservationStatusCanon.confirmed:
        return Colors.green;
      case ReservationStatusCanon.inStay:
        return Colors.teal;
      case ReservationStatusCanon.completed:
        return Colors.indigo;
      case ReservationStatusCanon.cancelled:
        return Colors.red;
      case ReservationStatusCanon.expired:
        return Colors.grey;
      case ReservationStatusCanon.awaitingApproval:
        return Colors.amber;
      case ReservationStatusCanon.paymentPending:
        return Colors.orange[700]!;
      case ReservationStatusCanon.refunded:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static bool isActiveBooking(Booking booking) {
    final now = DateTime.now();
    return ReservationStatusCanon.activeUi.contains(booking.status) &&
        booking.checkOut.isAfter(now);
  }

  static bool requiresPayment(Booking booking) {
    return booking.status == ReservationStatusCanon.paymentPending ||
        booking.status == ReservationStatusCanon.awaitingApproval;
  }
  
  /// Vérifie si la réservation est en attente d'approbation partenaire
  static bool isAwaitingApproval(Booking booking) {
    return booking.status == ReservationStatusCanon.awaitingApproval;
  }
  
  /// Vérifie si le délai de paiement est expiré
  static bool isPaymentExpired(Booking booking) {
    if (booking.paymentDeadline == null) return false;
    return DateTime.now().isAfter(booking.paymentDeadline!);
  }
  
  /// Calcule le temps restant pour le paiement (en minutes)
  static int getPaymentTimeRemaining(Booking booking) {
    if (booking.paymentDeadline == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(booking.paymentDeadline!)) return 0;
    return booking.paymentDeadline!.difference(now).inMinutes;
  }
  
  /// Formate le temps restant pour affichage (ex: "15 min", "2h 30min")
  static String formatTimeRemaining(int minutes) {
    if (minutes <= 0) return "Expiré";
    if (minutes < 60) return "${minutes}min";
    
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (remainingMinutes == 0) {
      return "${hours}h";
    } else {
      return "${hours}h ${remainingMinutes}min";
    }
  }
  
  /// Vérifie si la réservation peut être modifiée (mode avancé)
  static bool canModifyAdvancedBooking(Booking booking) {
    // Statuts qui empêchent toute modification
    const List<String> nonModifiableStatuses = [
      ReservationStatusCanon.cancelled,
      ReservationStatusCanon.completed,
      ReservationStatusCanon.expired,
      ReservationStatusCanon.refunded,
    ];

    if (nonModifiableStatuses.contains(booking.status)) {
      return false;
    }

    if (booking.status == ReservationStatusCanon.paymentPending &&
        isPaymentExpired(booking)) {
      return false;
    }
    
    // Logique existante pour les délais
    return canModifyBooking(booking);
  }
  
  /// Vérifie si la réservation peut être annulée (mode avancé)
  static bool canCancelAdvancedBooking(Booking booking) {
    // Statuts qui empêchent l'annulation
    const List<String> nonCancellableStatuses = [
      ReservationStatusCanon.cancelled,
      ReservationStatusCanon.completed,
      ReservationStatusCanon.expired,
      ReservationStatusCanon.refunded,
    ];

    return !nonCancellableStatuses.contains(booking.status) &&
           canCancelBooking(booking);
  }
  
  /// Retourne le mode de réservation formaté pour affichage
  static String getReservationModeLabel(String mode, {Locale locale = const Locale('fr')}) {
    final modeMap = {
      'fr': {
        'instant': 'Réservation instantanée',
        'approval_required': 'Demande d\'approbation',
      },
      'en': {
        'instant': 'Instant Booking',
        'approval_required': 'Approval Required',
      }
    };
    
    final languageCode = locale.languageCode;
    final translations = modeMap[languageCode] ?? modeMap['en']!;
    
    return translations[mode.toLowerCase()] ?? mode;
  }
  
  /// Vérifie si la réservation utilise un timer de paiement
  static bool hasPaymentTimer(Booking booking) {
    return booking.paymentDeadline != null &&
           booking.status == ReservationStatusCanon.paymentPending;
  }
  
  /// Vérifie si des notifications ont été envoyées
  static bool hasNotificationsSent(Booking booking) {
    return booking.notificationsSent != null && 
           booking.notificationsSent!.isNotEmpty;
  }
  
  /// Compte le nombre de notifications envoyées par type
  static int getNotificationCount(Booking booking, String type) {
    if (booking.notificationsSent == null) return 0;
    return booking.notificationsSent!
        .where((notification) => notification['type'] == type)
        .length;
  }
  
  /// Vérifie si la réservation a un timer actif (SLA hôte ou paiement)
  static bool hasActiveTimer(Booking booking) {
    final now = DateTime.now();
    
    // Timer SLA hôte (awaiting_approval)
    if (booking.status == ReservationStatusCanon.awaitingApproval &&
        booking.hostApprovalDeadline != null &&
        now.isBefore(booking.hostApprovalDeadline!)) {
      return true;
    }

    if (booking.status == ReservationStatusCanon.paymentPending &&
        booking.paymentDeadline != null &&
        now.isBefore(booking.paymentDeadline!)) {
      return true;
    }
    
    return false;
  }
  
  /// Obtient le type de timer actif pour une réservation
  static String? getActiveTimerType(Booking booking) {
    final now = DateTime.now();
    
    // Priorité au timer SLA hôte
    if (booking.status == ReservationStatusCanon.awaitingApproval &&
        booking.hostApprovalDeadline != null &&
        now.isBefore(booking.hostApprovalDeadline!)) {
      return 'host_approval';
    }

    if (booking.status == ReservationStatusCanon.paymentPending &&
        booking.paymentDeadline != null &&
        now.isBefore(booking.paymentDeadline!)) {
      return 'payment';
    }
    
    return null;
  }
  
  /// Calcule le temps restant pour le timer actif
  static Duration? getRemainingTime(Booking booking) {
    final now = DateTime.now();
    
    // Timer SLA hôte
    if (booking.status == ReservationStatusCanon.awaitingApproval &&
        booking.hostApprovalDeadline != null &&
        now.isBefore(booking.hostApprovalDeadline!)) {
      return booking.hostApprovalDeadline!.difference(now);
    }

    if (booking.status == ReservationStatusCanon.paymentPending &&
        booking.paymentDeadline != null &&
        now.isBefore(booking.paymentDeadline!)) {
      return booking.paymentDeadline!.difference(now);
    }
    
    return null;
  }
}
