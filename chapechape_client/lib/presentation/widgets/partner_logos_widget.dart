import 'package:flutter/material.dart';
import './carousel_widget.dart';

class PartnerLogosWidget extends StatelessWidget {
  const PartnerLogosWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Utiliser une liste locale de logos partenaires en attendant la définition de PartnerAssets
    final partnerLogos = [
      'assets/images/partners/partner1.png',
      'assets/images/partners/partner2.png',
      'assets/images/partners/partner3.png',
      'assets/images/partners/partner4.png',
      'assets/images/partners/partner5.png',
    ];
    
    final logoWidgets = partnerLogos.map((logo) {
      return Container(
        width: 120,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          logo,
          fit: BoxFit.contain,
        ),
      );
    }).toList();

    return CarouselWidget(
      height: 100,
      items: logoWidgets,
      autoPlayInterval: const Duration(seconds: 2),
    );
  }
}
