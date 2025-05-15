import 'package:flutter/material.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/utils/booking_helpers.dart';
import 'package:intl/intl.dart';

/// Widget réutilisable pour afficher un résumé de réservation
class BookingSummaryCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onTap;
  final bool showActions;
  final bool compact;

  const BookingSummaryCard({
    Key? key,
    required this.booking,
    this.onTap,
    this.showActions = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final statusColor = BookingHelpers.getStatusColor(booking.status);
    final statusLabel = BookingHelpers.getStatusLabel(booking.status, locale: locale);
    final isActive = BookingHelpers.isActiveBooking(booking);
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: compact ? 0 : 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Container(
              color: statusColor.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.residenceName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Chip(
                    label: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: statusColor.withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            
            // Détails de la réservation
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dates
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${BookingHelpers.formatDate(booking.checkIn, locale: locale)} - ${BookingHelpers.formatDate(booking.checkOut, locale: locale)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${booking.nights} ${booking.nights > 1 ? 'nuits' : 'nuit'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Nombre d'invités
                  Row(
                    children: [
                      const Icon(Icons.people, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${booking.numberOfGuests} ${booking.numberOfGuests > 1 ? 'personnes' : 'personne'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  
                  if (!compact) ...[
                    const SizedBox(height: 8),
                    
                    // Prix
                    Row(
                      children: [
                        const Icon(Icons.payments_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(booking.totalPrice)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    if (booking.paymentStatus != null) ...[
                      const SizedBox(height: 8),
                      
                      // Statut de paiement
                      Row(
                        children: [
                          Icon(
                            booking.isPaid ? Icons.check_circle : Icons.pending_outlined,
                            size: 18,
                            color: booking.isPaid ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            booking.isPaid ? 'Payé' : 'Paiement en attente',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: booking.isPaid ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            
            // Actions (si actives)
            if (showActions && isActive && !compact)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (BookingHelpers.canModifyBooking(booking))
                      OutlinedButton.icon(
                        onPressed: () {
                          // Navigation vers la modification
                          Navigator.of(context).pushNamed(
                            '/bookings/edit',
                            arguments: booking,
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Modifier'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (BookingHelpers.canCancelBooking(booking))
                      OutlinedButton.icon(
                        onPressed: () {
                          // Dialogue de confirmation d'annulation
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Annuler la réservation ?'),
                              content: const Text(
                                'Êtes-vous sûr de vouloir annuler cette réservation ? '
                                'Cette action pourrait entraîner des frais selon notre politique d\'annulation.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('ANNULER'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    // Navigation vers la page d'annulation
                                    Navigator.of(context).pushNamed(
                                      '/bookings/cancel',
                                      arguments: booking,
                                    );
                                  },
                                  child: const Text('CONFIRMER'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text('Annuler', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
