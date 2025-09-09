import 'package:flutter/material.dart';
import 'package:chapechape_client/core/models/booking_model.dart';

/// Classe d'utilitaires pour aider à gérer les réservations
class BookingHelpers {
  
  /// Calcule le temps restant pour l'approbation de l'hôte en secondes
  /// Retourne 0 si le délai est expiré ou si pas en mode approval_required
  static int getHostApprovalTimeRemaining(Booking booking) {
    // Vérifier si la réservation nécessite une approbation
    if (booking.reservationMode != 'approval_required' || 
        booking.status.toLowerCase() != 'awaiting_approval') {
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
           booking.status.toLowerCase() == 'awaiting_approval' &&
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
        // ✅ Statuts existants (conservés)
        'pending': 'En attente',
        'confirmed': 'Confirmée',
        'in_progress': 'En cours',
        'completed': 'Terminée',
        'cancelled': 'Annulée',
        'pending_cancellation': 'Annulation en cours',
        'expired': 'Expirée',
        
        // ✅ NOUVEAUX STATUTS - Système de Paiement Avancé
        'awaiting_approval': 'En attente d\'approbation',
        'payment_pending': 'Paiement en attente',
        'rejected': 'Rejetée',
        'payment_expired': 'Délai de paiement expiré',
        'payment_processing': 'Paiement en cours',
        'payment_failed': 'Paiement échoué',
        'partially_paid': 'Partiellement payée',
        'checked_in': 'Arrivée effectuée',
        'checked_out': 'Départ effectué',
      },
      'en': {
        // ✅ Statuts existants (conservés)
        'pending': 'Pending',
        'confirmed': 'Confirmed',
        'in_progress': 'In progress',
        'completed': 'Completed',
        'cancelled': 'Cancelled',
        'pending_cancellation': 'Cancellation pending',
        'expired': 'Expired',
        
        // ✅ NOUVEAUX STATUTS - Système de Paiement Avancé
        'awaiting_approval': 'Awaiting Approval',
        'payment_pending': 'Payment Pending',
        'rejected': 'Rejected',
        'payment_expired': 'Payment Deadline Expired',
        'payment_processing': 'Payment Processing',
        'payment_failed': 'Payment Failed',
        'partially_paid': 'Partially Paid',
        'checked_in': 'Checked In',
        'checked_out': 'Checked Out',
      }
    };
    
    final languageCode = locale.languageCode;
    final translations = statusMap[languageCode] ?? statusMap['en']!;
    
    return translations[status.toLowerCase()] ?? status;
  }
  
  /// Retourne la couleur associée au statut de la réservation
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      // ✅ Statuts existants (conservés)
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
        
      // ✅ NOUVEAUX STATUTS - Système de Paiement Avancé
      case 'awaiting_approval':
        return Colors.amber; // Jaune/orange pour "en attente d'approbation"
      case 'payment_pending':
        return Colors.orange[700]!; // Orange foncé pour "paiement en attente"
      case 'rejected':
        return Colors.red[800]!; // Rouge foncé pour "rejetée"
      case 'payment_expired':
        return Colors.red[600]!; // Rouge moyen pour "délai expiré"
      case 'payment_processing':
        return Colors.blue[600]!; // Bleu pour "paiement en cours"
      case 'payment_failed':
        return Colors.red; // Rouge standard pour "paiement échoué"
      case 'partially_paid':
        return Colors.yellow[700]!; // Jaune/orange pour "partiellement payé"
      case 'checked_in':
        return Colors.teal; // Bleu-vert pour "arrivée effectuée"
      case 'checked_out':
        return Colors.purple; // Violet pour "départ effectué"
        
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
  
  // ✅ NOUVELLES MÉTHODES - Système de Paiement Avancé
  
  /// Vérifie si la réservation nécessite un paiement
  static bool requiresPayment(Booking booking) {
    const List<String> paymentRequiredStatuses = [
      'payment_pending', 'payment_processing', 'awaiting_approval'
    ];
    return paymentRequiredStatuses.contains(booking.status.toLowerCase());
  }
  
  /// Vérifie si la réservation est en attente d'approbation partenaire
  static bool isAwaitingApproval(Booking booking) {
    return booking.status.toLowerCase() == 'awaiting_approval';
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
      'cancelled', 'completed', 'expired', 'payment_expired', 
      'rejected', 'checked_out', 'payment_failed'
    ];
    
    // Vérifier le statut
    if (nonModifiableStatuses.contains(booking.status.toLowerCase())) {
      return false;
    }
    
    // Si en attente de paiement et délai expiré
    if (booking.status.toLowerCase() == 'payment_pending' && 
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
      'cancelled', 'completed', 'expired', 'payment_expired', 
      'rejected', 'checked_out'
    ];
    
    return !nonCancellableStatuses.contains(booking.status.toLowerCase()) &&
           canCancelBooking(booking);
  }
  
  /// Vérifie si le QR code de check-in est disponible
  static bool hasCheckInQR(Booking booking) {
    return booking.qrCode != null && 
           booking.qrCode!.containsKey('checkInCode') &&
           booking.qrCode!['checkInCode'] != null &&
           booking.qrCode!['checkInCode'].toString().isNotEmpty;
  }
  
  /// Vérifie si le QR code de check-out est disponible
  static bool hasCheckOutQR(Booking booking) {
    return booking.qrCode != null && 
           booking.qrCode!.containsKey('checkOutCode') &&
           booking.qrCode!['checkOutCode'] != null &&
           booking.qrCode!['checkOutCode'].toString().isNotEmpty;
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
           booking.status.toLowerCase() == 'payment_pending';
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
    if (booking.status == 'awaiting_approval' && 
        booking.hostApprovalDeadline != null &&
        now.isBefore(booking.hostApprovalDeadline!)) {
      return true;
    }
    
    // Timer de paiement (pending_payment)
    if (booking.status == 'pending_payment' && 
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
    if (booking.status == 'awaiting_approval' && 
        booking.hostApprovalDeadline != null &&
        now.isBefore(booking.hostApprovalDeadline!)) {
      return 'host_approval';
    }
    
    // Timer de paiement
    if (booking.status == 'pending_payment' && 
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
    if (booking.status == 'awaiting_approval' && 
        booking.hostApprovalDeadline != null &&
        now.isBefore(booking.hostApprovalDeadline!)) {
      return booking.hostApprovalDeadline!.difference(now);
    }
    
    // Timer de paiement
    if (booking.status == 'pending_payment' && 
        booking.paymentDeadline != null &&
        now.isBefore(booking.paymentDeadline!)) {
      return booking.paymentDeadline!.difference(now);
    }
    
    return null;
  }
}
