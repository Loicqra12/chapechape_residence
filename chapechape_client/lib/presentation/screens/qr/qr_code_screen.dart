import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:chapechape_client/core/cubits/stay_credential_cubit.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/models/reservation_status.dart';
import 'package:chapechape_client/core/models/stay_credential.dart';
import 'package:chapechape_client/core/services/booking_service.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/booking/booking_event.dart' as booking_events;
import 'package:chapechape_client/core/blocs/booking/booking_state.dart' as booking_states;
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/presentation/widgets/booking/reservation_status_badge.dart';
import 'dart:async';

/// Écran QR Client — credential backend CCSTAY1.* uniquement (P2-05D).
class QRCodeScreen extends StatefulWidget {
  final String bookingId;

  const QRCodeScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  Booking? _booking;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    context.read<BookingBloc>().add(
      booking_events.LoadBookingDetails(bookingId: widget.bookingId),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String? _purposeForBooking(Booking booking) {
    return ReservationStatusCanon.stayQrPurpose(booking.status);
  }

  void _issueCredential(StayCredentialCubit cubit, String purpose) {
    cubit.issue(reservationId: widget.bookingId, purpose: purpose);
  }

  void _startCountdown(StayCredential credential, StayCredentialCubit cubit) {
    _countdownTimer?.cancel();
    void tick() {
      if (!mounted) return;
      final remaining = credential.expiresAt.difference(DateTime.now());
      setState(() {
        _remaining = remaining.isNegative ? Duration.zero : remaining;
      });
      if (remaining.isNegative) {
        _countdownTimer?.cancel();
        cubit.markExpired();
      }
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  String _errorMessage(String? code) {
    switch (code) {
      case 'RESERVATION_CHECKIN_TOO_EARLY':
        return 'Check-in disponible 2 h avant votre heure d\'arrivée.';
      case 'STAY_CREDENTIAL_NOT_ELIGIBLE':
        return 'Cette réservation n\'est pas éligible au QR pour le moment.';
      case 'STAY_CREDENTIAL_REGEN_LIMITED':
        return 'Régénération temporairement limitée. Réessayez dans un instant.';
      case 'NETWORK_ERROR':
        return 'Connexion impossible. Vérifiez votre réseau.';
      default:
        return 'Impossible de générer le QR. Réessayez.';
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours}:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StayCredentialCubit(context.read<BookingService>()),
      child: Builder(
        builder: (context) {
          return BlocConsumer<BookingBloc, booking_states.BookingState>(
            listener: (context, state) {
              if (state is booking_states.BookingDetailsLoaded) {
                setState(() => _booking = state.booking);
                final purpose = _purposeForBooking(state.booking);
                if (purpose != null) {
                  final cubit = context.read<StayCredentialCubit>();
                  if (cubit.state.credential == null && !cubit.state.isIssuing) {
                    _issueCredential(cubit, purpose);
                  }
                }
              }
            },
            builder: (context, bookingState) {
              return BlocConsumer<StayCredentialCubit, StayCredentialState>(
                listener: (context, credState) {
                  if (credState.credential != null && !credState.isExpired) {
                    _startCountdown(credState.credential!, context.read<StayCredentialCubit>());
                  }
                },
                builder: (context, credState) {
                  final booking = _booking;
                  final purpose = booking != null ? _purposeForBooking(booking) : null;
                  final title = purpose == 'checkout' ? 'QR de départ' : 'QR d\'arrivée';

                  return Scaffold(
                    appBar: AppBar(
                      title: Text(title),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    body: bookingState is booking_states.BookingLoading && booking == null
                        ? const Center(child: CircularProgressIndicator())
                        : _buildBody(context, booking, purpose, credState, title),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Booking? booking,
    String? purpose,
    StayCredentialState credState,
    String title,
  ) {
    if (booking == null) {
      return const Center(child: Text('Réservation introuvable'));
    }

    if (purpose == null) {
      return Center(
        child: Padding(
          padding: AppSpacing.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2, size: 64, color: Colors.grey.shade400),
              AppSpacing.verticalMd,
              Text(
                'Aucun QR actif pour cette réservation.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              AppSpacing.verticalSm,
              ReservationStatusBadge(status: booking.status),
            ],
          ),
        ),
      );
    }

    final cubit = context.read<StayCredentialCubit>();
    final showQr = credState.credential != null &&
        !credState.isExpired &&
        !credState.isIssuing;

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Réservation #${booking.id.substring(0, 8)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  AppSpacing.verticalSm,
                  ReservationStatusBadge(status: booking.status),
                ],
              ),
            ),
          ),
          AppSpacing.verticalLg,
          if (credState.isIssuing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (credState.errorCode != null)
            _buildErrorCard(context, credState.errorCode!, cubit, purpose)
          else if (credState.isExpired)
            _buildExpiredCard(context, cubit, purpose)
          else if (showQr)
            _buildQrCard(context, credState.credential!, title)
          else
            const SizedBox.shrink(),
          AppSpacing.verticalLg,
          Text(
            'Présentez ce QR au partenaire à votre ${purpose == 'checkout' ? 'départ' : 'arrivée'}. '
            'Le partenaire confirmera l\'opération après scan.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(BuildContext context, StayCredential credential, String title) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            AppSpacing.verticalMd,
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: QrImageView(
                data: credential.credential,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
            AppSpacing.verticalMd,
            Text(
              'Expire dans ${_formatDuration(_remaining)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _remaining.inMinutes < 2
                        ? AppTheme.errorColor
                        : Theme.of(context).colorScheme.primary,
                  ),
            ),
            AppSpacing.verticalMd,
            OutlinedButton.icon(
              onPressed: context.read<StayCredentialCubit>().state.isIssuing
                  ? null
                  : () => _issueCredential(
                        context.read<StayCredentialCubit>(),
                        credential.purpose,
                      ),
              icon: const Icon(Icons.refresh),
              label: const Text('Régénérer le QR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredCard(
    BuildContext context,
    StayCredentialCubit cubit,
    String purpose,
  ) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            const Icon(Icons.timer_off, size: 48, color: Colors.orange),
            AppSpacing.verticalMd,
            Text(
              'QR expiré',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.verticalSm,
            FilledButton.icon(
              onPressed: cubit.state.isIssuing
                  ? null
                  : () => _issueCredential(cubit, purpose),
              icon: const Icon(Icons.refresh),
              label: const Text('Régénérer le QR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(
    BuildContext context,
    String code,
    StayCredentialCubit cubit,
    String purpose,
  ) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            AppSpacing.verticalMd,
            Text(
              _errorMessage(code),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (code != 'RESERVATION_CHECKIN_TOO_EARLY') ...[
              AppSpacing.verticalMd,
              FilledButton(
                onPressed: cubit.state.isIssuing
                    ? null
                    : () => _issueCredential(cubit, purpose),
                child: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
