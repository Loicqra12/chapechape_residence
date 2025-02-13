import 'package:flutter/material.dart';

class ResidenceDetailsScreen extends StatelessWidget {
  final String residenceId;
  
  const ResidenceDetailsScreen({super.key, required this.residenceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Residence Details: $residenceId'),
      ),
    );
  }
}