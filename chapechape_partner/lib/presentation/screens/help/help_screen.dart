import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section FAQ
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: ExpansionTile(
              title: const Text('Questions fréquentes'),
              children: [
                _FAQItem(
                  question: 'Comment ajouter une nouvelle résidence ?',
                  answer: 'Pour ajouter une nouvelle résidence, accédez à l\'onglet "Résidences" et appuyez sur le bouton "+". Remplissez ensuite les informations requises et téléchargez des photos de qualité.',
                ),
                _FAQItem(
                  question: 'Comment gérer mes disponibilités ?',
                  answer: 'Vous pouvez gérer vos disponibilités dans le calendrier de chaque résidence. Bloquez les dates non disponibles et définissez vos tarifs saisonniers.',
                ),
                _FAQItem(
                  question: 'Comment sont gérés les paiements ?',
                  answer: 'Les paiements sont automatiquement traités par notre système. Vous recevrez vos paiements directement sur votre compte bancaire une fois la réservation terminée.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Section Contact
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contacter le support',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _ContactOption(
                    icon: Icons.chat_outlined,
                    title: 'Chat en direct',
                    subtitle: 'Discutez avec notre équipe',
                    onTap: () {
                      // TODO: Ouvrir le chat
                    },
                  ),
                  const SizedBox(height: 12),
                  _ContactOption(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: 'support@chapechape.com',
                    onTap: () {
                      // TODO: Ouvrir l'email
                    },
                  ),
                  const SizedBox(height: 12),
                  _ContactOption(
                    icon: Icons.phone_outlined,
                    title: 'Téléphone',
                    subtitle: '+33 1 23 45 67 89',
                    onTap: () {
                      // TODO: Appeler le support
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}
