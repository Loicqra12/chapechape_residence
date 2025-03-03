import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/constants/app_images.dart';

class SplashAnimation extends StatelessWidget {
  const SplashAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo animation
          SizedBox(
            width: 200,
            height: 200,
            child: Image.asset(
              AppImages.logoPrimary,
              height: 80,
            ),
          ),
          const SizedBox(height: 20),
          // Loading animation
          SizedBox(
            width: 100,
            height: 100,
            child: Lottie.asset(
              'assets/animations/loading.json',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
