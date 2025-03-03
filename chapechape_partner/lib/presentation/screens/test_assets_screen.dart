import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chapechape_partner/core/constants/app_icons.dart';
import 'package:chapechape_partner/core/constants/app_images.dart';

class TestAssetsScreen extends StatelessWidget {
  const TestAssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Assets'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test des logos
            const Text('Logos:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Image.asset(AppImages.logoPrimary, height: 50),
            const SizedBox(height: 16),

            // Test des icônes de navigation
            const Text('Navigation Icons:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                SvgPicture.asset(AppIcons.home, height: 24),
                SvgPicture.asset(AppIcons.profile, height: 24),
                SvgPicture.asset(AppIcons.settings, height: 24),
                SvgPicture.asset(AppIcons.messages, height: 24),
              ],
            ),
            const SizedBox(height: 16),

            // Test des icônes d'équipements
            const Text('Amenity Icons:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                SvgPicture.asset(AppIcons.wifi, height: 24),
                SvgPicture.asset(AppIcons.pool, height: 24),
                SvgPicture.asset(AppIcons.parking, height: 24),
                SvgPicture.asset(AppIcons.gym, height: 24),
              ],
            ),
            const SizedBox(height: 16),

            // Test des images d'onboarding
            const Text('Onboarding Images:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: AppImages.onboardingImages
                    .map((image) => Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Image.asset(image, height: 200),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
