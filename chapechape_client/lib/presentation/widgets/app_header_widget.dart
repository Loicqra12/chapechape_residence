import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_button_widget.dart';

class AppHeaderWidget extends StatelessWidget {
  const AppHeaderWidget({Key? key}) : super(key: key);

  /// Lance WhatsApp avec le numéro de support
  Future<void> _launchWhatsApp(BuildContext context) async {
    const phoneNumber = '+2250000000000'; // Numéro support ChapeChape
    final url = Uri.parse('https://wa.me/$phoneNumber?text=Bonjour, j\'ai besoin d\'aide avec l\'application ChapeChape.');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ouverture de WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Image.asset(
              'assets/logos/app_logo.png',
              height: 40,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => context.push('/search'),
                tooltip: 'Rechercher',
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
                tooltip: 'Notifications',
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
                onPressed: () => _launchWhatsApp(context),
                tooltip: 'Contacter via WhatsApp',
              ),
              const SizedBox(width: 8),
              // Ajout du widget de boutons d'authentification
              const AuthButtonWidget(),
            ],
          ),
        ],
      ),
    );
  }
}
