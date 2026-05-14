import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_assets.dart';
import '../../core/utils/partner_store_launch.dart';

/// Plein écran type « interstitiel » après tap sur la bannière partenaire (accueil).
class PartnerPromoFullScreen extends StatelessWidget {
  const PartnerPromoFullScreen({super.key});

  static const Color _ctaPurple = Color(0xFF6D28D9); // violet lisible sur fond clair
  static const Color _ctaPurplePressed = Color(0xFF5B21B6);

  Future<void> _onDownload(BuildContext context) async {
    final ok = await PartnerStoreLaunch.openPlayStoreListing();
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d\'ouvrir le Play Store pour le moment. Réessayez plus tard.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.partnerPromoFullscreen,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade900,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 48),
              ),
            ),
          ),
          // Lisibilité en haut (bouton fermer)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          // Dégradé bas pour texte + CTA
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 48, 20, 20 + bottom),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0),
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.88),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Vous avez une résidence, un appartement ou une maison d\'hôtes ?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 1)),
                          ],
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Publiez vos annonces, gérez vos disponibilités et recevez des réservations avec l\'application Partenaire ChapeChape.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.92),
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _onDownload(context);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) {
                          return _ctaPurplePressed;
                        }
                        return _ctaPurple;
                      }),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 16),
                      ),
                      shape: WidgetStateProperty.all(const StadiumBorder()),
                      elevation: WidgetStateProperty.all(0),
                    ),
                    child: const Text(
                      'Télécharger l\'app Partenaire',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.35),
                ),
                tooltip: 'Fermer',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
