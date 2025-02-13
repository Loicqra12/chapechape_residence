import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

          // Modes de paiement
          Column(
            children: [
              const Text(
                'Modes de paiement acceptés',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPaymentLogo('assets/images/payment/orange_money.png'),
                  _buildPaymentLogo('assets/images/payment/mtn_money.png'),
                  _buildPaymentLogo('assets/images/payment/moov_money.png'),
                  _buildPaymentLogo('assets/images/payment/wave_money.png'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Service client
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Service Client 24/7',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildContactButton(
                      icon: FontAwesomeIcons.whatsapp,
                      text: 'WhatsApp',
                      onTap: () => _launchWhatsApp(),
                    ),
                    const SizedBox(width: 20),
                    _buildContactButton(
                      icon: Icons.email,
                      text: 'Email',
                      onTap: () => _launchEmail(),
                    ),
                    const SizedBox(width: 20),
                    _buildContactButton(
                      icon: Icons.chat_bubble,
                      text: 'Chat',
                      onTap: () => _openChat(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Télécharger l'application
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
                    'Google Play',
                    Icons.android,
                    () => _launchURL('https://play.google.com/store/apps/details?id=com.chapechape.residences'),
                  ),
                  const SizedBox(width: 20),
                  _buildStoreButton(
                    'App Store',
                    Icons.apple,
                    () => _launchURL('https://apps.apple.com/app/chapechape-residences/id123456789'),
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

  Widget _buildPaymentLogo(String assetPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Image.asset(
        assetPath,
        height: 40,
        fit: BoxFit.contain,
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
