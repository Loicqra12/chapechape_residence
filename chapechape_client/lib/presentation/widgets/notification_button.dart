import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/notification/notification_bloc.dart';
import '../../core/blocs/notification/notification_state.dart';
import '../../core/blocs/notification/notification_event.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;

    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;

        if (state is NotificationLoaded) {
          unreadCount = state.notifications.where((n) => !n.isRead).length;
        }

        final button = IconButton(
          icon: Stack(
            children: [
              Icon(Icons.notifications, color: iconColor),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            context.pushNamed('notifications');
            context.read<NotificationBloc>().add(const MarkAllNotificationsAsRead());
          },
          tooltip: 'Notifications',
        );

        if (isDark) {
          return Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: button,
          );
        }
        return button;
      },
    );
  }
}
