import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/services/api/payment_service.dart';
import '../../../core/services/payment/african_payment_service.dart';
import '../../widgets/payment/payment_methods_manager_widget.dart';

/// Widget pour créer l'onglet Méthodes de paiement avec les Provider nécessaires
class PaymentMethodsTab extends StatelessWidget {
  const PaymentMethodsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtenir les services nécessaires ou les créer si nécessaire
    final dio = Dio();
    final apiService = ApiService(); // ApiService n'accepte pas de Dio en paramètre positionnel
    final paymentService = PaymentService(dio);
    final africanPaymentService = AfricanPaymentService(apiService, paymentService);
    
    return Provider<AfricanPaymentService>.value(
      value: africanPaymentService,
      child: const PaymentMethodsManagerWidget(),
    );
  }
}
