import 'package:flutter/material.dart';
import '../../../core/models/calendar/partner_calendar.dart';
import '../../../core/theme/colors.dart';

class OccupationActionsBar extends StatelessWidget {
  final PartnerOccupation? occupation;
  final bool hasRange;
  final VoidCallback? onCreateBlock;
  final VoidCallback? onCreateExternal;
  final VoidCallback? onViewReservation;
  final VoidCallback? onUnblock;
  final VoidCallback? onViewBlock;
  final VoidCallback? onViewExternal;
  final VoidCallback? onEditExternal;
  final VoidCallback? onCancelExternal;
  final VoidCallback? onCompleteExternal;

  const OccupationActionsBar({
    super.key,
    required this.occupation,
    required this.hasRange,
    this.onCreateBlock,
    this.onCreateExternal,
    this.onViewReservation,
    this.onUnblock,
    this.onViewBlock,
    this.onViewExternal,
    this.onEditExternal,
    this.onCancelExternal,
    this.onCompleteExternal,
  });

  @override
  Widget build(BuildContext context) {
    final actions = occupation == null
        ? (hasRange ? PartnerCalendarActionPolicy.forEmptySelection() : const <PartnerCalendarAction>[])
        : PartnerCalendarActionPolicy.forOccupation(occupation!);

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) => _chip(context, action)).toList(),
    );
  }

  Widget _chip(BuildContext context, PartnerCalendarAction action) {
    switch (action) {
      case PartnerCalendarAction.createBlock:
        return ActionChip(
          avatar: const Icon(Icons.block, size: 18),
          label: const Text('Bloquer cette période'),
          onPressed: onCreateBlock,
        );
      case PartnerCalendarAction.createExternal:
        return ActionChip(
          avatar: const Icon(Icons.person_add_alt, size: 18),
          label: const Text('Réservation externe'),
          onPressed: onCreateExternal,
        );
      case PartnerCalendarAction.viewReservation:
        return ActionChip(
          avatar: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Voir la réservation'),
          onPressed: onViewReservation,
        );
      case PartnerCalendarAction.unblock:
        return ActionChip(
          avatar: const Icon(Icons.lock_open, size: 18),
          label: const Text('Débloquer'),
          onPressed: onUnblock,
        );
      case PartnerCalendarAction.viewBlock:
        return ActionChip(
          avatar: const Icon(Icons.info_outline, size: 18),
          label: const Text('Voir le blocage'),
          onPressed: onViewBlock,
        );
      case PartnerCalendarAction.viewExternal:
        return ActionChip(
          avatar: const Icon(Icons.info_outline, size: 18),
          label: const Text('Voir'),
          onPressed: onViewExternal,
        );
      case PartnerCalendarAction.editExternal:
        return ActionChip(
          avatar: const Icon(Icons.edit, size: 18),
          label: const Text('Modifier'),
          onPressed: onEditExternal,
        );
      case PartnerCalendarAction.cancelExternal:
        return ActionChip(
          avatar: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('Annuler'),
          onPressed: onCancelExternal,
        );
      case PartnerCalendarAction.completeExternal:
        return ActionChip(
          avatar: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Marquer terminée'),
          onPressed: onCompleteExternal,
        );
    }
  }
}

class CalendarSourceLegend extends StatelessWidget {
  const CalendarSourceLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendDot(color: AppColors.success, label: 'Disponible'),
        _LegendDot(color: Color(0xFF1565C0), label: 'ChapeChape'),
        _LegendDot(color: Color(0xFF6A1B9A), label: 'Externe'),
        _LegendDot(color: Color(0xFFEF6C00), label: 'Bloc Partner'),
        _LegendDot(color: Color(0xFFFFA000), label: 'En attente'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

Color colorForOccupation(PartnerOccupation occupation) {
  if (occupation.sourceType == CalendarSourceType.reservation) {
    if (occupation.isAwaitingApproval) return const Color(0xFFFFA000);
    if (occupation.reservationStatus == 'payment_pending') {
      return const Color(0xFF42A5F5);
    }
    if (occupation.reservationStatus == 'in_stay') return AppColors.success;
    return const Color(0xFF1565C0);
  }
  if (occupation.sourceType == CalendarSourceType.externalReservation) {
    return const Color(0xFF6A1B9A);
  }
  switch (occupation.blockType) {
    case 'maintenance':
      return const Color(0xFFEF6C00);
    case 'cleaning':
      return const Color(0xFF00897B);
    case 'personal_use':
      return const Color(0xFF8D6E63);
    case 'renovation':
      return const Color(0xFF5D4037);
    default:
      return const Color(0xFFEF6C00);
  }
}

String labelForOccupation(PartnerOccupation occupation) {
  if (occupation.sourceType == CalendarSourceType.reservation) {
    switch (occupation.reservationStatus) {
      case 'awaiting_approval':
        return 'ChapeChape — en attente de votre réponse';
      case 'payment_pending':
        return 'ChapeChape — paiement en attente';
      case 'confirmed':
        return 'Réservation ChapeChape';
      case 'in_stay':
        return 'ChapeChape — séjour en cours';
      default:
        return 'Réservation ChapeChape';
    }
  }
  if (occupation.sourceType == CalendarSourceType.externalReservation) {
    return 'Réservation externe${occupation.channel != null && occupation.channel!.isNotEmpty ? ' (${occupation.channel})' : ''}';
  }
  switch (occupation.blockType) {
    case 'maintenance':
      return 'Maintenance';
    case 'cleaning':
      return 'Nettoyage';
    case 'personal_use':
      return 'Usage personnel';
    case 'renovation':
      return 'Rénovation';
    case 'administrative':
      return 'Bloc administratif';
    default:
      return 'Période bloquée';
  }
}
