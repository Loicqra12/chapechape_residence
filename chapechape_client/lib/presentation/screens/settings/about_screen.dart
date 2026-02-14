import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../presentation/widgets/common/watermark_widget.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const Color goldColor = Color(0xFFFFD700);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color blackColor = Color(0xFF1A1A1A);
  static const Color greyColor = Color(0xFFE0E0E0);
  
  String _appVersion = '1.0.0';
  String _deviceInfo = 'Information non disponible';
  
  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }
  
  Future<void> _loadAppInfo() async {
    try {
      // Charger les informations de l'application
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      
      String deviceData = 'Information non disponible';
      
      if (Theme.of(context).platform == TargetPlatform.android) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceData = '${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceData = '${iosInfo.model} (iOS ${iosInfo.systemVersion})';
      }
      
      setState(() {
        _appVersion = '${packageInfo.version} (Build ${packageInfo.buildNumber})';
        _deviceInfo = deviceData;
      });
    } catch (e) {
      // En cas d'erreur, garder les valeurs par défaut
      print('Erreur lors du chargement des informations: $e');
    }
  }
  
  Future<void> _showLegalDocument(BuildContext context, String title, String assetPath) async {
    try {
      final String content = await rootBundle.loadString(assetPath);
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _LegalDocumentScreen(
            title: title,
            content: content,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de charger le document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: blackColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('À propos'),
        backgroundColor: goldColor,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo de l'application
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd + AppSpacing.sm),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Image.asset(
                'assets/logos/app_icon.png',
                errorBuilder: (ctx, error, _) => Icon(
                  Icons.home_work,
                  size: 80,
                  color: goldColor,
                ),
              ),
            ),
            
            AppSpacing.verticalLg,
            
            // Nom et version de l'application
            Text(
              'ChapeChape Résidences',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Version $_appVersion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            AppSpacing.verticalXl,
            
            // Informations sur l'application
            _buildInfoSection(
              'À propos de ChapeChape Résidences',
              'ChapeChape Résidences est votre application de réservation d\'hébergement haut de gamme en Afrique de l\'Ouest. Nous proposons une sélection exclusive de résidences, villas et appartements pour vos séjours professionnels ou de loisirs.',
            ),
            
            AppSpacing.verticalLg,
            
            // Informations légales
            _buildInfoSection(
              'Informations légales',
              'ChapeChape Résidences est une marque déposée appartenant à ChapeChape Group. Tous droits réservés.',
            ),
            
            AppSpacing.verticalLg,
            
            // Informations techniques
            _buildInfoCard(
              title: 'Informations techniques',
              children: [
                _buildKeyValue('Appareil', _deviceInfo),
                _buildKeyValue('Langue', 'Français'),
                _buildKeyValue('Dernière mise à jour', '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
              ],
            ),
            
            AppSpacing.verticalLg,
            
            // Liens utiles - remplacer par des documents locaux
            _buildLinksCard(),
            
            AppSpacing.verticalXl,
            
            // Copyright
            Text(
              '© ${DateTime.now().year} ChapeChape Group. Tous droits réservés.',
              style: AppTextStyles.body.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            AppSpacing.verticalMd,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.subtitle,
        ),
        AppSpacing.verticalSm,
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: greyColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.subtitle,
            ),
            AppSpacing.verticalMd,
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildKeyValue(String key, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            '$key: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksCard() {
    return Card(
      elevation: 0,
      color: greyColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents légaux',
              style: AppTextStyles.subtitle,
            ),
            AppSpacing.verticalMd,
            _buildLegalDocumentItem(
              'Site web officiel',
              Icons.language,
              onTap: () => _launchURL('https://chapechape.com'),
            ),
            _buildLegalDocumentItem(
              'Politique de confidentialité',
              Icons.privacy_tip,
              onTap: () => _showLegalDocument(
                context, 
                'Politique de confidentialité',
                'assets/legal/privacy_policy.md',
              ),
            ),
            _buildLegalDocumentItem(
              'Conditions d\'utilisation',
              Icons.description,
              onTap: () => _showLegalDocument(
                context, 
                'Conditions d\'utilisation',
                'assets/legal/terms_of_use.md',
              ),
            ),
            _buildLegalDocumentItem(
              'Protection des données (RGPD)',
              Icons.security,
              onTap: () => _showLegalDocument(
                context, 
                'Protection des données',
                'assets/legal/data_protection.md',
              ),
            ),
            _buildLegalDocumentItem(
              'Nous contacter',
              Icons.email,
              onTap: () => _launchURL('mailto:support@chapechape.com'),
            ),
            
            // Séparateur avant le watermark
            SizedBox(height: AppSpacing.xl30), // 30px
            
            // Watermark ChapeChape
            const ChapeWatermarkWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalDocumentItem(String title, IconData icon, {required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: orangeColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
  
  Future<void> _launchURL(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir: $url')),
        );
      }
    }
  }
}

class _LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;
  
  const _LegalDocumentScreen({
    required this.title,
    required this.content,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _AboutScreenState.goldColor,
      ),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 