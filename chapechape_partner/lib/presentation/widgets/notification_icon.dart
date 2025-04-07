import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/repositories/notification_repository.dart';
import '../screens/notifications/notification_settings_screen.dart';

class NotificationIcon extends StatefulWidget {
  const NotificationIcon({Key? key}) : super(key: key);

  @override
  _NotificationIconState createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  int _unreadCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    try {
      final repository = Provider.of<NotificationRepository>(context, listen: false);
      final notifications = await repository.getNotifications();
      setState(() {
        _unreadCount = notifications.where((n) => !n.isRead).length;
      });
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des notifications: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => _showNotificationMenu(context),
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
  
  void _showNotificationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Préférences de notification'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notifications/preferences');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.mark_email_read),
            title: const Text('Marquer tout comme lu'),
            onTap: () async {
              Navigator.pop(context);
              // Implémenter la logique pour marquer tout comme lu
              setState(() {
                _unreadCount = 0;
              });
            },
          ),
        ],
      ),
    );
  }
} 