import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.secondaryColor,
      ),
      body: const Center(
        child: Text('Notification Screen'),
      ),
    );
  }
}