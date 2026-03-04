import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/models/reservation/reservation.dart';
import '../../../core/theme/colors.dart';

/// Widget de calendrier pour afficher les réservations
class ReservationCalendarWidget extends StatefulWidget {
  final List<Reservation> reservations;
  final Function(DateTime, List<Reservation>)? onDaySelected;
  final DateTime? selectedDay;
  final DateTime? focusedDay;

  const ReservationCalendarWidget({
    Key? key,
    required this.reservations,
    this.onDaySelected,
    this.selectedDay,
    this.focusedDay,
  }) : super(key: key);

  @override
  State<ReservationCalendarWidget> createState() => _ReservationCalendarWidgetState();
}

class _ReservationCalendarWidgetState extends State<ReservationCalendarWidget> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay ?? DateTime.now();
    _selectedDay = widget.selectedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Calendrier
        TableCalendar<Reservation>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              // Obtenir les réservations pour ce jour
              final dayReservations = _getReservationsForDay(selectedDay);
              widget.onDaySelected?.call(selectedDay, dayReservations);
            }
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: TextStyle(color: AppColors.primary),
            holidayTextStyle: TextStyle(color: AppColors.primary),
            selectedDecoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: AppColors.primary,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: AppColors.primary,
            ),
          ),
          eventLoader: _getReservationsForDay,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              
              return Positioned(
                bottom: 1,
                child: _buildEventMarker(events),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Résumé des réservations du jour sélectionné
        if (_selectedDay != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: _buildDaySummary(_selectedDay!),
          ),
        ],
      ],
    );
  }

  List<Reservation> _getReservationsForDay(DateTime day) {
    return widget.reservations.where((reservation) {
      final checkIn = reservation.checkIn;
      final checkOut = reservation.checkOut;
      
      if (checkIn == null || checkOut == null) return false;
      
      // Vérifier si le jour est entre check-in et check-out
      return day.isAfter(checkIn.subtract(const Duration(days: 1))) &&
             day.isBefore(checkOut.add(const Duration(days: 1)));
    }).toList();
  }

  Widget _buildEventMarker(List<Reservation> events) {
    if (events.isEmpty) return const SizedBox.shrink();
    
    final status = events.first.status;
    Color markerColor;
    
    switch (status) {
      case ReservationStatus.pending:
        markerColor = Colors.orange;
        break;
      case ReservationStatus.confirmed:
        markerColor = Theme.of(context).colorScheme.primary;
        break;
      case ReservationStatus.inStay:
        markerColor = Colors.green;
        break;
      case ReservationStatus.completed:
        markerColor = Colors.grey;
        break;
      case ReservationStatus.cancelled:
        markerColor = Colors.red;
        break;
      default:
        markerColor = Theme.of(context).colorScheme.primary;
    }
    
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDaySummary(DateTime day) {
    final dayReservations = _getReservationsForDay(day);
    
    if (dayReservations.isEmpty) {
      return Row(
        children: [
          Icon(Icons.event_available, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Aucune réservation pour le ${_formatDate(day)}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              '${dayReservations.length} réservation${dayReservations.length > 1 ? 's' : ''} le ${_formatDate(day)}',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...dayReservations.map((reservation) => _buildReservationItem(reservation)),
      ],
    );
  }

  Widget _buildReservationItem(Reservation reservation) {
    final statusColor = _getStatusColor(reservation.status);
    final statusIcon = _getStatusIcon(reservation.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(reservation.checkIn)} - ${_formatDate(reservation.checkOut)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reservation.status.displayName,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Theme.of(context).colorScheme.primary;
      case ReservationStatus.inStay:
        return Colors.green;
      case ReservationStatus.completed:
        return Colors.grey;
      case ReservationStatus.cancelled:
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getStatusIcon(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Icons.schedule;
      case ReservationStatus.confirmed:
        return Icons.check_circle;
      case ReservationStatus.inStay:
        return Icons.login;
      case ReservationStatus.completed:
        return Icons.logout;
      case ReservationStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.event;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
