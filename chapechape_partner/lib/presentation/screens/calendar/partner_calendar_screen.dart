import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/blocs/calendar/partner_calendar_bloc.dart';
import '../../../core/blocs/calendar/partner_calendar_event.dart';
import '../../../core/blocs/calendar/partner_calendar_state.dart';
import '../../../core/models/calendar/partner_calendar.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/services/api/partner_calendar_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/theme/colors.dart';
import '../../widgets/calendar/occupation_actions_bar.dart';

class PartnerCalendarView extends StatelessWidget {
  final Residence residence;

  const PartnerCalendarView({super.key, required this.residence});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PartnerCalendarBloc(
        service: PartnerCalendarService(context.read<ApiService>()),
      )..add(PartnerCalendarStarted(
          residenceId: residence.id,
          month: DateTime.now().toUtc(),
        )),
      child: _PartnerCalendarBody(residence: residence),
    );
  }
}

class _PartnerCalendarBody extends StatefulWidget {
  final Residence residence;
  const _PartnerCalendarBody({required this.residence});

  @override
  State<_PartnerCalendarBody> createState() => _PartnerCalendarBodyState();
}

class _PartnerCalendarBodyState extends State<_PartnerCalendarBody> {
  Function(Map<String, dynamic>)? _prevNew;
  Function(Map<String, dynamic>)? _prevResidence;

  bool get _isHourResidence => widget.residence.pricePeriod.toLowerCase() == 'hour';

  @override
  void initState() {
    super.initState();
    final socket = SocketService();
    _prevNew = socket.onNewReservationReceived;
    _prevResidence = socket.onResidenceReservationUpdate;
    socket.onNewReservationReceived = (data) {
      _prevNew?.call(data);
      _refresh();
    };
    socket.onResidenceReservationUpdate = (data) {
      _prevResidence?.call(data);
      _refresh();
    };
    socket.joinResidence(widget.residence.id);
  }

  @override
  void dispose() {
    final socket = SocketService();
    socket.onNewReservationReceived = _prevNew;
    socket.onResidenceReservationUpdate = _prevResidence;
    socket.leaveResidence(widget.residence.id);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    context.read<PartnerCalendarBloc>().add(const PartnerCalendarSocketPinged());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PartnerCalendarBloc, PartnerCalendarState>(
      listenWhen: (previous, current) =>
          current is PartnerCalendarLoaded &&
          current.bannerMessage != null &&
          (previous is! PartnerCalendarLoaded ||
              previous.bannerMessage != current.bannerMessage),
      listener: (context, state) {
        if (state is PartnerCalendarLoaded && state.bannerMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.bannerMessage!),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PartnerCalendarLoading || state is PartnerCalendarInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PartnerCalendarError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.read<PartnerCalendarBloc>().add(
                        PartnerCalendarStarted(
                          residenceId: widget.residence.id,
                          month: DateTime.now().toUtc(),
                        ),
                      ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        final loaded = state as PartnerCalendarLoaded;
        return RefreshIndicator(
          onRefresh: () async {
            context.read<PartnerCalendarBloc>().add(const PartnerCalendarRefreshed());
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Calendrier Partner',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'days.available = journée entière louable, pas « aucune minute occupée ». '
                'Les plages horaires se lisent dans le détail du jour.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 12),
              const CalendarSourceLegend(),
              const SizedBox(height: 12),
              TableCalendar<PartnerOccupation>(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2032, 12, 31),
                focusedDay: loaded.focusedMonth,
                rangeSelectionMode: RangeSelectionMode.enforced,
                rangeStartDay: loaded.rangeStart,
                rangeEndDay: _inclusiveRangeEnd(loaded.rangeEnd),
                startingDayOfWeek: StartingDayOfWeek.monday,
                locale: 'fr_FR',
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
                eventLoader: (day) => loaded.calendar.occupationsOn(day),
                onPageChanged: (focused) {
                  context.read<PartnerCalendarBloc>().add(PartnerCalendarMonthChanged(focused));
                },
                onRangeSelected: (start, end, focused) {
                  if (start == null) return;
                  if (end == null) {
                    context.read<PartnerCalendarBloc>().add(PartnerCalendarDaySelected(start));
                    return;
                  }
                  context.read<PartnerCalendarBloc>().add(PartnerCalendarRangeSelected(
                        start: DateTime.utc(start.year, start.month, start.day),
                        end: DateTime.utc(end.year, end.month, end.day)
                            .add(const Duration(days: 1)),
                      ));
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    return Positioned(
                      bottom: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: events.take(3).map((occ) {
                          return Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: colorForOccupation(occ),
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              if (loaded.mutating) const LinearProgressIndicator(),
              const SizedBox(height: 16),
              if (loaded.selectedDay != null) _buildDayPanel(context, loaded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayPanel(BuildContext context, PartnerCalendarLoaded loaded) {
    final day = loaded.selectedDay!;
    final occupations = loaded.calendar.occupationsOn(day);
    final dayInfo = loaded.calendar.dayFor(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat.yMMMMEEEEd('fr_FR').format(day),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          dayInfo?.available == true
              ? 'Journée entière disponible'
              : 'Journée non louable en entier (slot(s) occupé(s))',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (_isHourResidence) _HourTimeline(occupations: occupations, day: day),
        ...occupations.map((occ) => _OccupationTile(
              occupation: occ,
              selected: loaded.selectedOccupation?.id == occ.id,
              onTap: () => context.read<PartnerCalendarBloc>().add(
                    PartnerCalendarOccupationSelected(occ.id),
                  ),
            )),
        const SizedBox(height: 12),
        OccupationActionsBar(
          occupation: loaded.selectedOccupation,
          hasRange: loaded.rangeStart != null && loaded.rangeEnd != null,
          onCreateBlock: () => _openBlockForm(context, loaded),
          onCreateExternal: () => _openExternalForm(context, loaded),
          onViewReservation: loaded.selectedOccupation?.sourceType == CalendarSourceType.reservation
              ? () => context.push('/reservations/${loaded.selectedOccupation!.id}')
              : null,
          onUnblock: loaded.selectedOccupation != null &&
                  PartnerCalendarActionPolicy.canUnblock(loaded.selectedOccupation!)
              ? () => context.read<PartnerCalendarBloc>().add(
                    PartnerCalendarUnblockRequested(loaded.selectedOccupation!.id),
                  )
              : null,
          onViewBlock: () => _showOccupationDetails(context, loaded.selectedOccupation),
          onViewExternal: () => _showOccupationDetails(context, loaded.selectedOccupation),
          onEditExternal: () => _openExternalForm(context, loaded, existing: loaded.selectedOccupation),
          onCancelExternal: () => context.read<PartnerCalendarBloc>().add(
                PartnerCalendarExternalCancelled(loaded.selectedOccupation!.id),
              ),
          onCompleteExternal: () => context.read<PartnerCalendarBloc>().add(
                PartnerCalendarExternalCompleted(loaded.selectedOccupation!.id),
              ),
        ),
      ],
    );
  }

  DateTime? _inclusiveRangeEnd(DateTime? exclusiveEnd) {
    if (exclusiveEnd == null) return null;
    return exclusiveEnd.subtract(const Duration(days: 1));
  }

  Future<void> _openBlockForm(BuildContext context, PartnerCalendarLoaded loaded) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PeriodFormSheet(
        title: 'Bloquer une période',
        isHour: _isHourResidence,
        initialStart: loaded.rangeStart ?? loaded.selectedDay,
        initialEnd: loaded.rangeEnd,
        showType: true,
      ),
    );
    if (result == null || !context.mounted) return;
    context.read<PartnerCalendarBloc>().add(PartnerCalendarBlockRequested(
          start: result['start'] as DateTime,
          end: result['end'] as DateTime,
          bookingType: _isHourResidence ? 'hour' : 'day',
          type: result['type'] as String? ?? 'other',
          reason: result['reason'] as String? ?? '',
        ));
  }

  Future<void> _openExternalForm(
    BuildContext context,
    PartnerCalendarLoaded loaded, {
    PartnerOccupation? existing,
  }) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PeriodFormSheet(
        title: existing == null ? 'Réservation externe' : 'Modifier la réservation externe',
        isHour: _isHourResidence,
        initialStart: existing?.start ?? loaded.rangeStart ?? loaded.selectedDay,
        initialEnd: existing?.end ?? loaded.rangeEnd,
        guestName: existing?.guestName,
        channel: existing?.channel,
      ),
    );
    if (result == null || !context.mounted) return;
    if (existing != null) {
      context.read<PartnerCalendarBloc>().add(
            PartnerCalendarExternalUpdated(
              id: existing.id,
              checkIn: result['start'] as DateTime,
              checkOut: result['end'] as DateTime,
              channel: result['channel'] as String? ?? 'other',
              guestName: result['guestName'] as String? ?? '',
              guestPhone: result['guestPhone'] as String? ?? '',
              notes: result['notes'] as String? ?? '',
            ),
          );
      return;
    }
    context.read<PartnerCalendarBloc>().add(PartnerCalendarExternalRequested(
          checkIn: result['start'] as DateTime,
          checkOut: result['end'] as DateTime,
          bookingType: _isHourResidence ? 'hour' : 'day',
          channel: result['channel'] as String? ?? 'other',
          guestName: result['guestName'] as String? ?? '',
          guestPhone: result['guestPhone'] as String? ?? '',
          notes: result['notes'] as String? ?? '',
        ));
  }

  void _showOccupationDetails(BuildContext context, PartnerOccupation? occ) {
    if (occ == null) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(labelForOccupation(occ), style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('${_fmt(occ.start)} → ${_fmt(occ.end)}'),
            if (occ.guestName != null && occ.guestName!.isNotEmpty) Text('Client : ${occ.guestName}'),
            if (occ.guestPhone != null && occ.guestPhone!.isNotEmpty) Text('Tél. : ${occ.guestPhone}'),
            if (occ.notes != null && occ.notes!.isNotEmpty) Text(occ.notes!),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) => DateFormat('dd/MM HH:mm').format(dt.toLocal());
}

class _OccupationTile extends StatelessWidget {
  final PartnerOccupation occupation;
  final bool selected;
  final VoidCallback onTap;

  const _OccupationTile({
    required this.occupation,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorForOccupation(occupation);
    return Card(
      color: selected ? color.withValues(alpha: 0.12) : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: color, radius: 8),
        title: Text(labelForOccupation(occupation)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('HH:mm').format(occupation.start.toLocal())} → ${DateFormat('HH:mm').format(occupation.end.toLocal())}',
            ),
            if (occupation.isAwaitingApproval)
              _ApprovalCountdown(deadline: occupation.hostApprovalDeadline),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCountdown extends StatefulWidget {
  final DateTime? deadline;
  const _ApprovalCountdown({this.deadline});

  @override
  State<_ApprovalCountdown> createState() => _ApprovalCountdownState();
}

class _ApprovalCountdownState extends State<_ApprovalCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.deadline;
    if (deadline == null) {
      return const Text('En attente de votre réponse');
    }
    final remaining = deadline.difference(DateTime.now().toUtc());
    if (remaining.isNegative) {
      return const Text('Délai d\'approbation expiré');
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return Text(
      'En attente de votre réponse — expire dans ${hours}h ${minutes}m',
      style: const TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.w600),
    );
  }
}

class _HourTimeline extends StatelessWidget {
  final List<PartnerOccupation> occupations;
  final DateTime day;
  const _HourTimeline({required this.occupations, required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: 15,
        itemBuilder: (context, index) {
          final hour = 8 + index;
          final slotStart = DateTime.utc(day.year, day.month, day.day, hour);
          final slotEnd = slotStart.add(const Duration(hours: 1));
          final hits = occupations.where((occ) => occ.start.isBefore(slotEnd) && occ.end.isAfter(slotStart)).toList();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 48, child: Text('${hour.toString().padLeft(2, '0')}:00', style: const TextStyle(fontSize: 12))),
                Expanded(
                  child: hits.isEmpty
                      ? Container(height: 16, color: AppColors.success.withValues(alpha: 0.15))
                      : Row(
                          children: hits.map((occ) {
                            return Expanded(
                              child: Container(
                                height: 16,
                                color: colorForOccupation(occ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodFormSheet extends StatefulWidget {
  final String title;
  final bool isHour;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final bool showType;
  final String? guestName;
  final String? channel;

  const _PeriodFormSheet({
    required this.title,
    required this.isHour,
    this.initialStart,
    this.initialEnd,
    this.showType = false,
    this.guestName,
    this.channel,
  });

  @override
  State<_PeriodFormSheet> createState() => _PeriodFormSheetState();
}

class _PeriodFormSheetState extends State<_PeriodFormSheet> {
  late DateTime _start;
  late DateTime _end;
  String _type = 'other';
  String _channel = 'other';
  final _reason = TextEditingController();
  final _guestName = TextEditingController();
  final _guestPhone = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart ?? DateTime.now().toUtc();
    _end = widget.initialEnd ?? _start.add(widget.isHour ? const Duration(hours: 2) : const Duration(days: 1));
    _guestName.text = widget.guestName ?? '';
    _channel = widget.channel ?? 'other';
  }

  @override
  void dispose() {
    _reason.dispose();
    _guestName.dispose();
    _guestPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isStart) async {
    final initial = isStart ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.toLocal(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!mounted) return;
    var combined = DateTime.utc(date.year, date.month, date.day, initial.hour, initial.minute);
    if (widget.isHour) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial.toLocal()),
      );
      if (time == null || !mounted) return;
      combined = DateTime.utc(date.year, date.month, date.day, time.hour, time.minute);
    }
    setState(() {
      if (isStart) {
        _start = combined;
        if (!_end.isAfter(_start)) {
          _end = _start.add(widget.isHour ? const Duration(hours: 1) : const Duration(days: 1));
        }
      } else {
        _end = combined;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            ListTile(
              title: const Text('Début'),
              subtitle: Text(_start.toIso8601String()),
              onTap: () => _pick(true),
            ),
            ListTile(
              title: const Text('Fin'),
              subtitle: Text(_end.toIso8601String()),
              onTap: () => _pick(false),
            ),
            if (widget.showType)
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Motif'),
                items: const [
                  DropdownMenuItem(value: 'personal_use', child: Text('Usage personnel')),
                  DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                  DropdownMenuItem(value: 'cleaning', child: Text('Nettoyage')),
                  DropdownMenuItem(value: 'renovation', child: Text('Rénovation')),
                  DropdownMenuItem(value: 'administrative', child: Text('Administratif')),
                  DropdownMenuItem(value: 'other', child: Text('Autre')),
                ],
                onChanged: (value) => setState(() => _type = value ?? 'other'),
              ),
            if (!widget.showType) ...[
              DropdownButtonFormField<String>(
                value: _channel,
                decoration: const InputDecoration(labelText: 'Canal'),
                items: const [
                  DropdownMenuItem(value: 'phone', child: Text('Téléphone')),
                  DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                  DropdownMenuItem(value: 'walk_in', child: Text('Sur place')),
                  DropdownMenuItem(value: 'airbnb', child: Text('Airbnb')),
                  DropdownMenuItem(value: 'booking_com', child: Text('Booking.com')),
                  DropdownMenuItem(value: 'other_platform', child: Text('Autre plateforme')),
                  DropdownMenuItem(value: 'other', child: Text('Autre')),
                ],
                onChanged: (value) => setState(() => _channel = value ?? 'other'),
              ),
              TextField(controller: _guestName, decoration: const InputDecoration(labelText: 'Nom (optionnel)')),
              TextField(controller: _guestPhone, decoration: const InputDecoration(labelText: 'Téléphone (optionnel)')),
              TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes')),
            ] else
              TextField(controller: _reason, decoration: const InputDecoration(labelText: 'Raison')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'start': _start,
                'end': _end,
                'type': _type,
                'reason': _reason.text,
                'channel': _channel,
                'guestName': _guestName.text,
                'guestPhone': _guestPhone.text,
                'notes': _notes.text,
              }),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
