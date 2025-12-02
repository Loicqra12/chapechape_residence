import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50];
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final iconColor = const Color(0xFFD4AF37); // Gold

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.only(top: 32, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Liens en Accordéon (ExpansionTiles)
          _buildExpansionTile(
            context,
            title: 'À propos',
            children: [
              _buildFooterLink('Qui sommes-nous ?', isDarkMode: isDarkMode),
              _buildFooterLink('Notre mission', isDarkMode: isDarkMode),
              _buildFooterLink('Nos partenaires', isDarkMode: isDarkMode),
              _buildFooterLink('Blog', isDarkMode: isDarkMode),
            ],
            isDarkMode: isDarkMode,
          ),
          _buildDivider(isDarkMode),
          
          _buildExpansionTile(
            context,
            title: 'Aide',
            children: [
              _buildFooterLink('Centre d\'aide', isDarkMode: isDarkMode),
              _buildFooterLink('FAQ', isDarkMode: isDarkMode),
              _buildFooterLink('Nous contacter', isDarkMode: isDarkMode),
              _buildFooterLink('Signaler un problème', isDarkMode: isDarkMode),
            ],
            isDarkMode: isDarkMode,
          ),
          _buildDivider(isDarkMode),

          _buildExpansionTile(
            context,
            title: 'Légal',
            children: [
              _buildFooterLink('Conditions d\'utilisation', isDarkMode: isDarkMode),
              _buildFooterLink('Politique de confidentialité', isDarkMode: isDarkMode),
              _buildFooterLink('Mentions légales', isDarkMode: isDarkMode),
              _buildFooterLink('Cookies', isDarkMode: isDarkMode),
            ],
            isDarkMode: isDarkMode,
          ),
          _buildDivider(isDarkMode),

          const SizedBox(height: 32),

          // 2. Contact Compact
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Besoin d\'aide ?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompactContactButton(
                      icon: FontAwesomeIcons.whatsapp,
                      label: 'WhatsApp',
                      onTap: _launchWhatsApp,
                      color: iconColor,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(width: 24),
                    _buildCompactContactButton(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      onTap: _launchEmail,
                      color: iconColor,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(width: 24),
                    _buildCompactContactButton(
                      icon: Icons.chat_bubble_outline,
                      label: 'Chat',
                      onTap: _openChat,
                      color: iconColor,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 3. Paiements & Partenaires (Carrousel Grayscale)
          _buildSectionTitle('Nos partenaires & Paiements', textColor),
          const SizedBox(height: 16),
          _buildLogosCarousel(isDarkMode),

          const SizedBox(height: 40),

          // 4. App Download
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCompactStoreButton(
                  icon: FontAwesomeIcons.appStore,
                  onTap: () {},
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 16),
                _buildCompactStoreButton(
                  icon: FontAwesomeIcons.googlePlay,
                  onTap: () {},
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Copyright
          Center(
            child: Text(
              '© 2025 ChapeChape Résidences',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionTile(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    required bool isDarkMode,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        iconColor: const Color(0xFFD4AF37),
        collapsedIconColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        childrenPadding: const EdgeInsets.only(bottom: 16, left: 16),
        children: children.map((child) => Align(
          alignment: Alignment.centerLeft,
          child: child,
        )).toList(),
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
    );
  }

  Widget _buildFooterLink(String text, {required bool isDarkMode}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: InkWell(
        onTap: () {},
        child: Text(
          text,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color.withOpacity(0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLogosCarousel(bool isDarkMode) {
    final logos = [
      'assets/images/payment/visa.png',
      'assets/images/payment/mastercard.png',
      'assets/images/payment/orange_money.png',
      'assets/images/payment/mtn_money.png',
      'assets/images/payment/wave_money.png',
      'assets/logos/partners/partner1_logo.png',
      'assets/logos/partners/partner2_logo.png',
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: logos.length,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Opacity(
              opacity: 0.7,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]),
                child: Image.asset(
                  logos[index],
                  height: 30,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactStoreButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    const phoneNumber = '+2250000000000';
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
