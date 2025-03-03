import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_assets.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          // Liens rapides
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'À propos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink('Qui sommes-nous ?'),
                    _buildFooterLink('Notre mission'),
                    _buildFooterLink('Nos partenaires'),
                    _buildFooterLink('Blog'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aide',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink('Centre d\'aide'),
                    _buildFooterLink('FAQ'),
                    _buildFooterLink('Nous contacter'),
                    _buildFooterLink('Signaler un problème'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Légal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink('Conditions d\'utilisation'),
                    _buildFooterLink('Politique de confidentialité'),
                    _buildFooterLink('Mentions légales'),
                    _buildFooterLink('Cookies'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Contactez-nous
          Column(
            children: [
              const Text(
                'Contactez-nous',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildContactButton(
                    icon: FontAwesomeIcons.whatsapp,
                    text: 'WhatsApp',
                    onTap: _launchWhatsApp,
                  ),
                  const SizedBox(width: 16),
                  _buildContactButton(
                    icon: Icons.email,
                    text: 'Email',
                    onTap: _launchEmail,
                  ),
                  const SizedBox(width: 16),
                  _buildContactButton(
                    icon: Icons.chat_bubble_outline,
                    text: 'Chat',
                    onTap: _openChat,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Méthodes de paiement
          Column(
            children: [
              const Text(
                'Méthodes de paiement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPaymentMethodLogo('assets/images/payment/visa.png'),
                  _buildPaymentMethodLogo('assets/images/payment/mastercard.png'),
                  _buildPaymentMethodLogo('assets/images/payment/paypal.png'),
                  _buildPaymentMethodLogo('assets/images/payment/orange_money.png'),
                  _buildPaymentMethodLogo('assets/images/payment/mtn_money.png'),
                  _buildPaymentMethodLogo('assets/images/payment/moov_money.png'),
                  _buildPaymentMethodLogo('assets/images/payment/wave_money.png'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Nos partenaires
          Column(
            children: [
              const Text(
                'Nos partenaires',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPartnerLogo('assets/logos/partners/partner1_logo.png'),
                  _buildPartnerLogo('assets/logos/partners/partner2_logo.png'),
                  _buildPartnerLogo('assets/logos/partners/partner3_logo.png'),
                  _buildPartnerLogo('assets/logos/partners/partner4_logo.png'),
                  _buildPartnerLogo('assets/logos/partners/partner5_logo.png'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Téléchargez notre application
          Column(
            children: [
              const Text(
                'Téléchargez notre application',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStoreButton(
                    'App Store',
                    FontAwesomeIcons.appStoreIos,
                    () {},
                  ),
                  const SizedBox(width: 16),
                  _buildStoreButton(
                    'Google Play',
                    FontAwesomeIcons.googlePlay,
                    () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Copyright
          const Text(
            ' 2025 ChapeChape Résidences. Tous droits réservés.',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {},
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 30, color: const Color(0xFFFFD700)),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodLogo(String assetPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Image.asset(
        assetPath,
        height: 30,
        width: 50,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildPartnerLogo(String assetPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Image.asset(
        assetPath,
        height: 40,
        width: 80,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildStoreButton(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    const phoneNumber = '+2250000000000'; // Remplacer par le vrai numéro
    final url = 'https://wa.me/$phoneNumber';
    await _launchURL(url);
  }

  Future<void> _launchEmail() async {
    const email = 'contact@chapechape.com';
    final url = 'mailto:$email';
    await _launchURL(url);
  }

  void _openChat() {
    // Implémenter l'ouverture du chat
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
