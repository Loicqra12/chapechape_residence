import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import './carousel_widget.dart';

class PartnerLogosWidget extends StatelessWidget {
  const PartnerLogosWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logoWidgets = PartnerAssets.logos.map((logo) {
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
