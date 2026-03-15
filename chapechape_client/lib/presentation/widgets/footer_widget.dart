import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/text_styles.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = scheme.surface;
    final textColor = scheme.onSurface;
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
              _buildFooterLink(context, 'Qui sommes-nous ?', isDarkMode: isDarkMode),
              _buildFooterLink(context, 'Notre mission', isDarkMode: isDarkMode),
              _buildFooterLink(context, 'Nos partenaires', isDarkMode: isDarkMode),
              _buildFooterLink(context, 'Blog', isDarkMode: isDarkMode),
            ],
            isDarkMode: isDarkMode,
          ),
          _buildDivider(context),
          
          _buildExpansionTile(
            context,
            title: 'Aide',
            children: [
              _buildFooterLink(context, 'Centre d\'aide', isDarkMode: isDarkMode),
              _buildFooterLink(context, 'FAQ', isDarkMode: isDarkMode),
              _buildFooterLink(context, 'Nous contacter', isDarkMode: isDarkMode),
              _buildFooterLink(context, 'Signaler un problème', isDarkMode: isDarkMode),
            ],
            isDarkMode: isDarkMode,
          ),
          _buildDivider(context),

          _buildExpansionTile(
            context,
            title: 'Légal',
            children: [
              _buildFooterLink(context, 'Conditions d\'utilisation', isDarkMode: isDarkMode),
              _buildFooterLink(context, 'Politique de confidentialité', isDarkMode: isDarkMode),
              _buildFooterLink(context, 'Mentions légales', isDarkMode: isDarkMode),
              _buildFooterLink(context, 'Cookies', isDarkMode: isDarkMode),
            ],
            isDarkMode: isDarkMode,
          ),
          _buildDivider(context),

          const SizedBox(height: 32),

          // 2. Contact Compact
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Besoin d\'aide ?',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompactContactButton(
                      context,
                      icon: FontAwesomeIcons.whatsapp,
                      label: 'WhatsApp',
                      onTap: _launchWhatsApp,
                      color: iconColor,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(width: 24),
                    _buildCompactContactButton(
                      context,
                      icon: Icons.email_outlined,
                      label: 'Email',
                      onTap: _launchEmail,
                      color: iconColor,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(width: 24),
                    _buildCompactContactButton(
                      context,
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
                  context,
                  icon: FontAwesomeIcons.appStore,
                  onTap: () {},
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 16),
                _buildCompactStoreButton(
                  context,
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
                color: scheme.onSurface.withOpacity(0.7),
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
          style: AppTextStyles.title.copyWith(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        iconColor: const Color(0xFFD4AF37),
        collapsedIconColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        childrenPadding: const EdgeInsets.only(bottom: 16, left: 16),
        children: children.map((child) => Align(
          alignment: Alignment.centerLeft,
          child: child,
        )).toList(),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
    );
  }

  Widget _buildFooterLink(BuildContext context, String text, {required bool isDarkMode}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: InkWell(
        onTap: () {},
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactContactButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isDarkMode,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outline.withOpacity(0.3),
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

  Widget _buildCompactStoreButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(icon, color: scheme.onInverseSurface, size: 18),
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
