import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/repositories/notification_repository.dart';
import '../../../core/models/notification/notification_model.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({Key? key}) : super(key: key);

  @override
  _NotificationListScreenState createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final repository = Provider.of<NotificationRepository>(context, listen: false);
      final paginatedResponse = await repository.getNotifications();
      final notifications = paginatedResponse.notifications;
      
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des notifications: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _markAsRead(String notificationId) async {
    try {
      final repository = Provider.of<NotificationRepository>(context, listen: false);
      final success = await repository.markAsRead(notificationId);
      
      if (success) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(isRead: true);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              side: BorderSide(color: Colors.grey.shade300),
              backgroundColor: Colors.transparent,
            ),
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications/preferences');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationTile(notification);
                    },
                  ),
                ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Pas de notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas de notifications pour le moment',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationTile(NotificationModel notification) {
    // Déterminer l'icône en fonction du type de notification
    IconData icon;
    Color iconColor;
    
    switch (notification.type) {
      case 'residence':
        icon = Icons.home;
        iconColor = Colors.blue;
        break;
      case 'booking':
        icon = Icons.calendar_today;
        iconColor = Colors.green;
        break;
      case 'message':
        icon = Icons.message;
        iconColor = Colors.purple;
        break;
      case 'review':
        icon = Icons.star;
        iconColor = Colors.amber;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }
    
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        // Supprimer la notification
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              timeago.format(notification.timestamp, locale: 'fr'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: notification.isRead
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          // Marquer comme lu
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
          
          // Si une action est définie pour cette notification, naviguer vers la destination
          if (notification.actionUrl != null) {
            // Navigation vers la destination
          }
        },
      ),
    );
  }
} 