import 'package:flutter/material.dart';

class BookingScreen extends StatelessWidget {
  final String residenceId;
  
  const BookingScreen({super.key, required this.residenceId});

  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFCCAC00);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color blackColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservation'),
        backgroundColor: goldColor,
      ),
      body: Center(
        child: Text('Booking Screen: $residenceId'),
      ),
    );
  }
}