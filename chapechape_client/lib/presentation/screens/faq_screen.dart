import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';

/// Écran FAQ complet avec catégories et questions/réponses
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<Map<String, dynamic>> _faqCategories = [
    {
      'title': 'Réservations',
      'icon': Icons.calendar_today,
      'questions': [
        {
          'question': 'Comment réserver une résidence ?',
          'answer': 'Pour réserver une résidence, parcourez notre catalogue, sélectionnez la résidence qui vous intéresse, choisissez vos dates et cliquez sur "Réserver". Suivez ensuite les étapes de paiement pour confirmer votre réservation.'
        },
        {
          'question': 'Comment modifier ma réservation ?',
          'answer': 'Rendez-vous dans "Mes réservations" depuis votre profil. Sélectionnez la réservation concernée et cliquez sur "Modifier". Les modifications sont soumises aux conditions de la politique d\'annulation de la résidence.'
        },
        {
          'question': 'Quels sont les délais d\'annulation ?',
          'answer': 'Les délais d\'annulation varient selon la résidence. Généralement, vous pouvez annuler gratuitement jusqu\'à 48h avant l\'arrivée. Consultez les conditions spécifiques sur la page de la résidence avant de réserver.'
        },
        {
          'question': 'Comment utiliser mon QR code de check-in ?',
          'answer': 'Le QR code est disponible dans les détails de votre réservation. Présentez-le au partenaire à votre arrivée pour valider votre check-in. Un second QR code est disponible pour le check-out.'
        },
      ]
    },
    {
      'title': 'Paiements',
      'icon': Icons.payment,
      'questions': [
        {
          'question': 'Quels moyens de paiement acceptez-vous ?',
          'answer': 'Nous acceptons les cartes Visa et Mastercard, ainsi que les paiements par Mobile Money : Orange Money, MTN Mobile Money, Moov Money et Wave. La fonctionnalité PayPal sera bientôt disponible.'
        },
        {
          'question': 'Mon paiement est-il sécurisé ?',
          'answer': 'Oui, tous les paiements sont sécurisés par cryptage SSL. Nous ne stockons jamais vos informations de carte bancaire. Les transactions Mobile Money sont effectuées via les canaux officiels des opérateurs.'
        },
        {
          'question': 'Comment demander un remboursement ?',
          'answer': 'Pour demander un remboursement, contactez notre service client via l\'écran "Aide et Support" ou par email à support@chapechape.com. Précisez le numéro de réservation et la raison de votre demande.'
        },
        {
          'question': 'Quand serai-je débité ?',
          'answer': 'Le débit est effectué immédiatement lors de la confirmation de réservation. Pour certaines résidences, un acompte peut être demandé avec le solde à payer sur place.'
        },
      ]
    },
    {
      'title': 'Compte et Profil',
      'icon': Icons.person,
      'questions': [
        {
          'question': 'Comment créer un compte ?',
          'answer': 'Cliquez sur "S\'inscrire" depuis l\'écran de connexion. Renseignez vos informations (email, téléphone, mot de passe) et validez. Vous pouvez aussi vous connecter via Google ou Facebook.'
        },
        {
          'question': 'Comment réinitialiser mon mot de passe ?',
          'answer': 'Sur l\'écran de connexion, cliquez sur "Mot de passe oublié" et saisissez votre email. Un lien de réinitialisation vous sera envoyé dans les minutes qui suivent.'
        },
        {
          'question': 'Comment modifier mes informations personnelles ?',
          'answer': 'Allez dans votre Profil, puis "Paramètres". Vous pouvez y modifier votre nom, email, numéro de téléphone et photo de profil.'
        },
        {
          'question': 'Comment supprimer mon compte ?',
          'answer': 'Contactez notre service client pour demander la suppression de votre compte. Cette action est irréversible et entraînera la perte de toutes vos données, favoris et historique.'
        },
      ]
    },
    {
      'title': 'Résidences',
      'icon': Icons.home,
      'questions': [
        {
          'question': 'Comment trouver une résidence près de moi ?',
          'answer': 'Utilisez la fonctionnalité "Autour de moi" sur l\'écran d\'accueil ou activez la géolocalisation dans la recherche pour voir les résidences à proximité de votre position.'
        },
        {
          'question': 'Comment contacter un partenaire ?',
          'answer': 'Une fois votre réservation confirmée, vous pouvez envoyer un message au partenaire via la messagerie intégrée accessible depuis les détails de votre réservation.'
        },
        {
          'question': 'Comment laisser un avis ?',
          'answer': 'Après votre séjour, vous recevrez une notification vous invitant à évaluer la résidence. Vous pouvez aussi laisser un avis depuis l\'historique de vos réservations.'
        },
        {
          'question': 'Que faire si la résidence ne correspond pas aux photos ?',
          'answer': 'Contactez immédiatement notre service client via le chat ou par téléphone. Nous traiterons votre réclamation en priorité et vous proposerons une solution adaptée.'
        },
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent),
            onPressed: () => context.push('/support'),
            tooltip: 'Contacter le support',
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppSpacing.md + AppSpacing.xs),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Column(
              children: [
                const Icon(Icons.help_outline, size: 48, color: Colors.white),
                AppSpacing.verticalSmd,
                Text(
                  'Comment pouvons-nous vous aider ?',
                  style: AppTextStyles.title.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.verticalSm,
                Text(
                  'Trouvez rapidement des réponses à vos questions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          AppSpacing.verticalLg,
          
          // FAQ Categories
          ..._faqCategories.map((category) => _buildFaqCategory(category)),
          
          AppSpacing.verticalLg,
          
          // Contact Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 32, color: Colors.grey),
                  AppSpacing.verticalSmd,
                  Text(
                    'Vous n\'avez pas trouvé votre réponse ?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.verticalSm,
                  Text(
                    'Notre équipe est disponible pour vous aider',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.verticalMd,
                  ElevatedButton.icon(
                    onPressed: () => context.push('/support'),
                    icon: const Icon(Icons.headset_mic),
                    label: const Text('Contacter le support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: AppSpacing.buttonPadding,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          AppSpacing.verticalMd,
        ],
      ),
    );
  }

  Widget _buildFaqCategory(Map<String, dynamic> category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.smd),
          child: Row(
            children: [
              Icon(category['icon'], color: AppTheme.primaryColor),
              SizedBox(width: AppSpacing.sm),
              Text(
                category['title'],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...List.generate(
          (category['questions'] as List).length,
          (index) => _buildFaqItem(category['questions'][index]),
        ),
        AppSpacing.verticalSm,
      ],
    );
  }

  Widget _buildFaqItem(Map<String, dynamic> faq) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          title: Text(
            faq['question'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Text(
                faq['answer'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
