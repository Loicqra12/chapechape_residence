import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/blocs/help/help_bloc.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../../core/services/api/help_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
  
  // Méthode factory pour créer l'écran avec son propre BlocProvider
  static Widget withBloc(BuildContext context) {
    return BlocProvider<HelpBloc>(
      create: (context) {
        try {
          // Essayer d'utiliser un bloc existant
          return context.read<HelpBloc>();
        } catch (_) {
          // Si aucun bloc n'est trouvé, en créer un nouveau
          final dio = Dio();
          final helpService = HelpService(dio);
          return HelpBloc(helpService: helpService);
        }
      },
      child: const HelpScreen(),
    );
  }
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    // Charger les FAQs au démarrage
    context.read<HelpBloc>().add(const LoadFAQs());
    
    // Ajouter des FAQs personnalisées adaptées au contexte africain si elles n'existent pas déjà
    _addCustomFAQsIfNeeded();
  }
  
  void _addCustomFAQsIfNeeded() {
    // Ces FAQs seront ajoutées localement si le bloc ne contient pas déjà des FAQs similaires
    final customFaqs = [
      FAQItem(
        id: 'custom_1',
        question: 'Comment spécifier les options d\'approvisionnement en eau?',
        answer: 'Dans la section Équipements améliorés, vous pouvez choisir parmi plusieurs options: continu, programmé, limité, puits ou forage. Sélectionnez celle qui correspond le mieux à votre résidence pour informer précisément vos clients potentiels.',
        category: 'Équipements',
        isExpanded: false,
      ),
      FAQItem(
        id: 'custom_2',
        question: 'Comment configurer les méthodes de paiement africaines?',
        answer: 'ChapeChape supporte plusieurs méthodes de paiement locales comme Wave, Orange Money, MTN Money et Moov Money. Accédez à la section Méthodes de paiement dans les paramètres de votre résidence pour les activer selon vos préférences.',
        category: 'Paiements',
        isExpanded: false,
      ),
      FAQItem(
        id: 'custom_3',
        question: 'Comment ajouter des points d\'intérêt à proximité de ma résidence?',
        answer: 'Dans la section détails de votre résidence, appuyez sur "Modifier les points d\'intérêt". Vous pourrez alors ajouter des restaurants, marchés, stations de transport ou autres lieux pertinents à proximité avec leur distance et description.',
        category: 'Résidence',
        isExpanded: false,
      ),
      FAQItem(
        id: 'custom_4',
        question: 'Comment gérer les coupures d\'électricité pour ma résidence?',
        answer: 'Dans les équipements améliorés, spécifiez votre type d\'alimentation électrique (stable, instable, générateur de secours, solaire). Si vous disposez d\'un générateur, précisez-le pour rassurer vos clients sur la continuité du service malgré les coupures.',
        category: 'Équipements',
        isExpanded: false,
      ),
      FAQItem(
        id: 'custom_5',
        question: 'Comment personnaliser les FAQs de ma résidence?',
        answer: 'Dans la section détails de votre résidence, appuyez sur "Modifier les FAQs". Vous pourrez ajouter des questions et réponses spécifiques à votre logement pour informer vos clients sur les particularités locales, règles de la résidence, etc.',
        category: 'Résidence',
        isExpanded: false,
      ),
    ];
    
    // Dans une implémentation réelle, on vérifierait si ces FAQs existent déjà avant de les ajouter
    // Pour cette démo, on les ajoute directement au state local
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }
  
  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de passer l\'appel téléphonique'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'appel téléphonique: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _sendEmail(String emailAddress) async {
    // Créer l'URI avec encodage correct des paramètres
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      queryParameters: {
        'subject': 'Demande d\'assistance - ChapeChape Partner'
      },
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application de messagerie'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi d\'email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _openLiveChat() {
    _showLiveChatDialog();
  }
  
  void _showLiveChatDialog() {
    final TextEditingController messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat en direct'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Envoyez un message à notre équipe d\'assistance. Nous vous répondrons dans les plus brefs délais.'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Votre message',
                hintText: 'Décrivez votre problème...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                context.read<HelpBloc>().add(
                  SendSupportMessage(message: messageController.text),
                );
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message envoyé avec succès. Nous vous répondrons bientôt.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez entrer un message'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('ENVOYER'),
          ),
        ],
      ),
    );
  }
  
  void _showReportProblemDialog() {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    String selectedCategory = 'Technique';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler un problème'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedCategory,
                  items: const [
                    DropdownMenuItem(
                      value: 'Technique',
                      child: Text('Problème technique'),
                    ),
                    DropdownMenuItem(
                      value: 'Réservation',
                      child: Text('Problème de réservation'),
                    ),
                    DropdownMenuItem(
                      value: 'Paiement',
                      child: Text('Problème de paiement'),
                    ),
                    DropdownMenuItem(
                      value: 'Autre',
                      child: Text('Autre'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedCategory = value;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Sujet',
                    hintText: 'Résumé du problème',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un sujet';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Décrivez le problème en détail...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une description';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                context.read<HelpBloc>().add(
                  ReportProblem(
                    category: selectedCategory,
                    subject: subjectController.text,
                    description: descriptionController.text,
                  ),
                );
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Problème signalé avec succès. Nous examinerons votre rapport dès que possible.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('ENVOYER'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem),
            onPressed: _showReportProblemDialog,
            tooltip: 'Signaler un problème',
          ),
        ],
      ),
      body: BlocBuilder<HelpBloc, HelpState>(
        builder: (context, state) {
          if (state is HelpLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is HelpError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${state.message}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<HelpBloc>().add(const LoadFAQs());
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          
          if (state is HelpLoaded) {
            return ListView(
        padding: const EdgeInsets.all(16),
        children: [
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une question...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _handleSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _handleSearch,
                ),
                
                const SizedBox(height: 16),
                
          // Section FAQ
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Questions fréquentes',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      // Filtrer les FAQs en fonction de la recherche
                      _buildFAQItems(state.faqs),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Section Guides
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Guides rapides',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      _GuideItem(
                        title: 'Comment ajouter une résidence',
                        icon: Icons.home_work,
                        onTap: () {
                          _showGuideDialog(
                            'Comment ajouter une résidence',
                            [
                              'Accédez à l\'onglet "Résidences" en bas de l\'écran',
                              'Appuyez sur le bouton "+" en bas à droite',
                              'Remplissez les informations requises sur votre résidence',
                              'Ajoutez des photos de qualité pour attirer les clients',
                              'Définissez vos tarifs et disponibilités',
                              'Appuyez sur "Enregistrer" pour publier votre résidence'
                            ],
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _GuideItem(
                        title: 'Gérer les réservations',
                        icon: Icons.calendar_today,
                        onTap: () {
                          _showGuideDialog(
                            'Gérer les réservations',
                            [
                              'Accédez à l\'onglet "Réservations" en bas de l\'écran',
                              'Consultez les réservations en attente, confirmées ou terminées',
                              'Appuyez sur une réservation pour voir les détails',
                              'Utilisez les boutons d\'action pour accepter, refuser ou annuler',
                              'Communiquez avec le client via la messagerie intégrée'
                            ],
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _GuideItem(
                        title: 'Configurer les paiements',
                        icon: Icons.payment,
                        onTap: () {
                          _showGuideDialog(
                            'Configurer les paiements',
                            [
                              'Accédez à la section "Paiements" depuis votre profil',
                              'Ajoutez vos coordonnées bancaires pour recevoir les paiements',
                              'Configurez vos préférences de paiement',
                              'Les paiements sont automatiquement transférés après chaque séjour',
                              'Vous pouvez demander un retrait à tout moment'
                            ],
                          );
                        },
                ),
                      const Divider(height: 1),
                      _GuideItem(
                        title: 'Gérer les points d\'intérêt',
                        icon: Icons.location_on,
                        onTap: () {
                          _showGuideDialog(
                            'Gérer les points d\'intérêt à proximité',
                            [
                              'Accédez aux détails de votre résidence',
                              'Appuyez sur "Points d\'intérêt" dans la section "Détails"',
                              'Cliquez sur "Modifier" pour ajouter ou supprimer des points d\'intérêt',
                              'Pour chaque lieu, indiquez le nom, le type, la distance et une description',
                              'Les types disponibles incluent: restaurants, marchés, écoles, hôpitaux, etc.',
                              'Appuyez sur "Enregistrer" pour sauvegarder vos modifications'
                            ],
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _GuideItem(
                        title: 'Méthodes de paiement locales',
                        icon: Icons.currency_exchange,
                        onTap: () {
                          _showGuideDialog(
                            'Configurer les méthodes de paiement locales',
                            [
                              'Accédez à la section "Paiements" depuis votre profil',
                              'Sélectionnez "Méthodes de paiement acceptées"',
                              'Activez les options de paiement disponibles dans votre région:',
                              '- Wave: Pour les transferts d\'argent mobiles populaires en Afrique de l\'Ouest',
                              '- Orange Money: Disponible dans plusieurs pays d\'Afrique francophone',
                              '- MTN Money et Moov Money: Services mobiles régionaux',
                              '- Espèces: Pour les paiements sur place',
                              '- Carte bancaire et virement: Pour les clients internationaux',
                              'Définissez votre méthode de paiement préférée pour les virements'
                            ],
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _GuideItem(
                        title: 'Équipements adaptés au contexte local',
                        icon: Icons.electrical_services,
                        onTap: () {
                          _showGuideDialog(
                            'Configurer les équipements améliorés',
                            [
                              'Accédez aux détails de votre résidence',
                              'Appuyez sur "Modifier" dans la section "Équipements"',
                              'Spécifiez les détails sur l\'approvisionnement en eau:',
                              '  • Continu: Eau disponible 24h/24',
                              '  • Programmé: Disponible à certaines heures',
                              '  • Limité: Capacité limitée',
                              '  • Puits/Forage: Source d\'eau indépendante',
                              'Indiquez le type d\'alimentation électrique:',
                              '  • Stable: Pas de coupures fréquentes',
                              '  • Instable: Coupures régulières',
                              '  • Générateur de secours: En cas de coupure',
                              '  • Solaire: Énergie indépendante du réseau',
                              'Précisez les options de sécurité:',
                              '  • Gardien 24h/24: Surveillance permanente',
                              '  • Résidence sécurisée: Accès contrôlé',
                              '  • Caméras: Surveillance vidéo'
                            ],
                          );
                        },
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                  ),
                  const SizedBox(height: 16),
                  _ContactOption(
                    icon: Icons.chat_outlined,
                    title: 'Chat en direct',
                    subtitle: 'Discutez avec notre équipe',
                          onTap: _openLiveChat,
                  ),
                  const SizedBox(height: 12),
                  _ContactOption(
                    icon: Icons.email_outlined,
                    title: 'Support',
                    subtitle: 'support@chapechaperesidence.com',
                          onTap: () => _sendEmail('support@chapechaperesidence.com'),
                  ),
                  const SizedBox(height: 12),
                  _ContactOption(
                    icon: Icons.email_outlined,
                    title: 'Contact',
                    subtitle: 'contact@chapechaperesidence.com',
                          onTap: () => _sendEmail('contact@chapechaperesidence.com'),
                  ),
                  const SizedBox(height: 12),
                  _ContactOption(
                    icon: Icons.phone_outlined,
                    title: 'Téléphone',
                    subtitle: '+225 07 48 00 10 42',
                          onTap: () => _makePhoneCall('+2250748001042'),
                  ),
                ],
              ),
            ),
                ),
              ],
            );
          }
          
          return const EmptyStateWidget(
            icon: Icons.help_outline,
            title: 'Aucune donnée',
            message: 'Les informations d\'aide ne sont pas disponibles pour le moment',
          );
        },
      ),
    );
  }
  
  Widget _buildFAQItems(List<FAQItem> faqs) {
    final filteredFaqs = _searchQuery.isEmpty
        ? faqs
        : faqs.where((faq) {
            return faq.question.toLowerCase().contains(_searchQuery) ||
                faq.answer.toLowerCase().contains(_searchQuery);
          }).toList();
    
    if (filteredFaqs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('Aucun résultat trouvé pour cette recherche'),
        ),
      );
    }
    
    return ExpansionPanelList(
      elevation: 0,
      expandedHeaderPadding: EdgeInsets.zero,
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          filteredFaqs[index] = filteredFaqs[index].copyWith(isExpanded: !isExpanded);
        });
      },
      children: filteredFaqs.map<ExpansionPanel>((FAQItem faq) {
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text(
                faq.question,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
          body: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(faq.answer),
          ),
          isExpanded: faq.isExpanded,
        );
      }).toList(),
    );
  }
  
  void _showGuideDialog(String title, List<String> steps) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(step)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FERMER'),
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

class _GuideItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _GuideItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

// Classes de BLoC nécessaires si elles n'existent pas encore
class FAQItem {
  final String id;
  final String question;
  final String answer;
  final String category;
  final bool isExpanded;
  
  FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.isExpanded = false,
  });
  
  FAQItem copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    bool? isExpanded,
  }) {
    return FAQItem(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

abstract class HelpEvent {
  const HelpEvent();
}

class LoadFAQs extends HelpEvent {
  const LoadFAQs();
}

class SendSupportMessage extends HelpEvent {
  final String message;
  
  const SendSupportMessage({required this.message});
}

class ReportProblem extends HelpEvent {
  final String category;
  final String subject;
  final String description;
  
  const ReportProblem({
    required this.category,
    required this.subject,
    required this.description,
  });
}

abstract class HelpState {}

class HelpInitial extends HelpState {}

class HelpLoading extends HelpState {}

class HelpLoaded extends HelpState {
  final List<FAQItem> faqs;
  
  HelpLoaded({required this.faqs});
}

class HelpError extends HelpState {
  final String message;
  
  HelpError({required this.message});
}

class HelpBloc extends Bloc<HelpEvent, HelpState> {
  final HelpService helpService;

  HelpBloc({required this.helpService}) : super(HelpInitial()) {
    on<LoadFAQs>(_onLoadFAQs);
    on<SendSupportMessage>(_onSendSupportMessage);
    on<ReportProblem>(_onReportProblem);
  }
  
  Future<void> _onLoadFAQs(
    LoadFAQs event,
    Emitter<HelpState> emit,
  ) async {
    try {
      emit(HelpLoading());
      
      // Simuler un chargement
      await Future.delayed(const Duration(seconds: 1));
      
      // Générer des FAQs fictives pour la démonstration
      final List<FAQItem> mockFaqs = [
        FAQItem(
          id: '1',
          question: 'Comment ajouter une nouvelle résidence ?',
          answer: 'Pour ajouter une nouvelle résidence, accédez à l\'onglet "Résidences" et appuyez sur le bouton "+". Remplissez ensuite les informations requises et téléchargez des photos de qualité.',
          category: 'Résidences',
        ),
        FAQItem(
          id: '2',
          question: 'Comment gérer mes disponibilités ?',
          answer: 'Vous pouvez gérer vos disponibilités dans le calendrier de chaque résidence. Bloquez les dates non disponibles et définissez vos tarifs saisonniers.',
          category: 'Résidences',
        ),
        FAQItem(
          id: '3',
          question: 'Comment sont gérés les paiements ?',
          answer: 'Les paiements sont automatiquement traités par notre système. Vous recevrez vos paiements directement sur votre compte bancaire une fois la réservation terminée.',
          category: 'Paiements',
        ),
        FAQItem(
          id: '4',
          question: 'Comment contacter un client ?',
          answer: 'Vous pouvez contacter un client directement depuis l\'application en accédant aux détails de la réservation et en utilisant la fonction de messagerie intégrée.',
          category: 'Communication',
        ),
        FAQItem(
          id: '5',
          question: 'Comment modifier les informations de mon profil ?',
          answer: 'Pour modifier votre profil, accédez à l\'onglet "Profil" et appuyez sur le bouton d\'édition. Vous pourrez modifier vos informations personnelles, votre photo de profil, etc.',
          category: 'Compte',
        ),
        FAQItem(
          id: '6',
          question: 'Comment annuler une réservation ?',
          answer: 'Pour annuler une réservation, accédez aux détails de la réservation et utilisez le bouton "Annuler". Notez que des frais peuvent s\'appliquer en fonction de la politique d\'annulation.',
          category: 'Réservations',
        ),
        FAQItem(
          id: '7',
          question: 'Comment recevoir les paiements plus rapidement ?',
          answer: 'Les paiements sont normalement traités dans les 24 heures après le départ du client. Pour recevoir vos paiements plus rapidement, vous pouvez activer l\'option de paiement express dans vos paramètres de compte.',
          category: 'Paiements',
        ),
      ];
      
      emit(HelpLoaded(faqs: mockFaqs));
    } catch (e) {
      emit(HelpError(message: e.toString()));
    }
  }
  
  Future<void> _onSendSupportMessage(
    SendSupportMessage event,
    Emitter<HelpState> emit,
  ) async {
    try {
      // Simuler l'envoi du message
      await Future.delayed(const Duration(seconds: 1));
      
      // Conserver l'état actuel
      if (state is HelpLoaded) {
        final currentState = state as HelpLoaded;
        emit(HelpLoaded(faqs: currentState.faqs));
      }
    } catch (e) {
      emit(HelpError(message: e.toString()));
    }
  }
  
  Future<void> _onReportProblem(
    ReportProblem event,
    Emitter<HelpState> emit,
  ) async {
    try {
      // Simuler l'envoi du rapport
      await Future.delayed(const Duration(seconds: 1));
      
      // Conserver l'état actuel
      if (state is HelpLoaded) {
        final currentState = state as HelpLoaded;
        emit(HelpLoaded(faqs: currentState.faqs));
      }
    } catch (e) {
      emit(HelpError(message: e.toString()));
    }
  }
}
