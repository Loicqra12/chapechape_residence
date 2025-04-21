import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/utils/responsive_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _disputeSubjectController = TextEditingController();
  final TextEditingController _disputeDetailsController = TextEditingController();
  String? _selectedCategory;
  String? _selectedDisputeType;
  
  final List<Map<String, dynamic>> _faqCategories = [
    {
      'title': 'Réservations',
      'icon': Icons.calendar_today,
      'questions': [
        {
          'question': 'Comment modifier une réservation ?',
          'answer': 'Pour modifier une réservation, rendez-vous dans la section "Réservations" de votre profil. Sélectionnez la réservation concernée et cliquez sur "Modifier". Les modifications sont soumises aux conditions de la politique d\'annulation.'
        },
        {
          'question': 'Quels sont les délais d\'annulation ?',
          'answer': 'Les délais d\'annulation varient selon la résidence. Généralement, vous pouvez annuler gratuitement jusqu\'à 48h avant l\'arrivée. Consultez les conditions spécifiques sur la page de la résidence avant de réserver.'
        },
      ]
    },
    {
      'title': 'Paiements',
      'icon': Icons.payment,
      'questions': [
        {
          'question': 'Quels moyens de paiement acceptez-vous ?',
          'answer': 'Nous acceptons les cartes Visa et Mastercard, ainsi que les paiements par Mobile Money (Orange Money, MTN Mobile Money, Moov Money et Wave). Le paiement par PayPal sera bientôt disponible.'
        },
        {
          'question': 'Comment demander un remboursement ?',
          'answer': 'Pour demander un remboursement, contactez notre service client via l\'onglet "Contact" ou par email à support@chapechape.com. Précisez le numéro de réservation et la raison de votre demande.'
        },
      ]
    },
    {
      'title': 'Compte',
      'icon': Icons.person,
      'questions': [
        {
          'question': 'Comment réinitialiser mon mot de passe ?',
          'answer': 'Sur l\'écran de connexion, cliquez sur "Mot de passe oublié" et suivez les instructions. Un lien de réinitialisation sera envoyé à votre adresse email.'
        },
        {
          'question': 'Comment supprimer mon compte ?',
          'answer': 'Pour supprimer votre compte, contactez notre service client. Notez que cette action est irréversible et entraînera la perte de toutes vos données et récompenses.'
        },
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _disputeSubjectController.dispose();
    _disputeDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Aide et Support'),
        backgroundColor: const Color(0xFFFFD700),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Contact'),
            Tab(text: 'Litiges'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFaqTab(),
          _buildContactTab(),
          _buildDisputeTab(),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Questions fréquentes',
            style: TextStyle(
              fontSize: context.responsiveFontSize(22),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trouvez rapidement des réponses aux questions les plus courantes',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Liste des catégories de FAQ
          ...List.generate(_faqCategories.length, (index) {
            final category = _faqCategories[index];
            return _buildFaqCategory(
              title: category['title'],
              icon: category['icon'],
              questions: category['questions'],
            );
          }),
          
          const SizedBox(height: 24),
          
          // Pas trouvé votre réponse ?
          Card(
            elevation: 2,
            color: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vous n\'avez pas trouvé votre réponse ?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      _tabController.animateTo(1); // Aller à l'onglet Contact
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    child: const Text('Contactez-nous'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCategory({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> questions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(questions.length, (index) {
          return _buildFaqItem(
            question: questions[index]['question'],
            answer: questions[index]['answer'],
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contactez-nous',
            style: TextStyle(
              fontSize: context.responsiveFontSize(22),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notre équipe est à votre disposition pour vous aider',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Moyens de contact directs
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact direct',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactMethod(
                    icon: Icons.phone,
                    title: 'Par téléphone',
                    subtitle: '+225 XX XX XX XX',
                    action: () => _launchUrl('tel:+22520202020'),
                  ),
                  const Divider(),
                  _buildContactMethod(
                    icon: Icons.email,
                    title: 'Par email',
                    subtitle: 'support@chapechape.com',
                    action: () => _launchUrl('mailto:support@chapechape.com'),
                  ),
                  const Divider(),
                  _buildContactMethod(
                    icon: Icons.message,
                    title: 'Par WhatsApp',
                    subtitle: '+225 XX XX XX XX',
                    action: () => _launchUrl('https://wa.me/2250000000000'),
                  ),
                ],
              ),
            ),
          ),
          
          // Formulaire de contact
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Formulaire de contact',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Catégorie
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCategory,
                    hint: const Text('Sélectionnez une catégorie'),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    items: [
                      'Réservation',
                      'Paiement',
                      'Problème technique',
                      'Suggestion',
                      'Autre',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sujet
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Sujet',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Message
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      hintText: 'Décrivez votre problème ou question...',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  
                  // Bouton d'envoi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedCategory != null &&
                            _subjectController.text.isNotEmpty &&
                            _messageController.text.isNotEmpty) {
                          _showContactSuccessDialog();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Envoyer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeTab() {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résolution des litiges',
            style: TextStyle(
              fontSize: context.responsiveFontSize(22),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Signalez un problème avec une réservation ou un paiement',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Formulaire de litige
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nouveau litige',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Type de litige
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Type de litige',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedDisputeType,
                    hint: const Text('Sélectionnez le type de litige'),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDisputeType = newValue;
                      });
                    },
                    items: [
                      'Problème avec la résidence',
                      'Erreur de facturation',
                      'Remboursement non reçu',
                      'Services non fournis',
                      'Autre',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sujet
                  TextFormField(
                    controller: _disputeSubjectController,
                    decoration: const InputDecoration(
                      labelText: 'Sujet',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Détails
                  TextFormField(
                    controller: _disputeDetailsController,
                    decoration: const InputDecoration(
                      labelText: 'Détails du litige',
                      border: OutlineInputBorder(),
                      hintText: 'Décrivez en détail votre problème...',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  
                  // Bouton d'envoi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedDisputeType != null &&
                            _disputeSubjectController.text.isNotEmpty &&
                            _disputeDetailsController.text.isNotEmpty) {
                          _showDisputeSuccessDialog();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Soumettre'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Informations sur le processus
          Card(
            elevation: 1,
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Processus de résolution',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Soumettez votre litige via ce formulaire\n'
                    '2. Notre équipe examinera votre cas sous 48h\n'
                    '3. Vous recevrez une réponse par email\n'
                    '4. Si nécessaire, une médiation sera proposée',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback action,
  }) {
    return InkWell(
      onTap: action,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _showContactSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Message envoyé'),
          content: const Text(
            'Votre message a été envoyé avec succès. Notre équipe vous répondra dans les meilleurs délais.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedCategory = null;
                  _subjectController.clear();
                  _messageController.clear();
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showDisputeSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Litige soumis'),
          content: const Text(
            'Votre litige a été soumis avec succès. Notre équipe l\'examinera sous 48h et vous contactera par email.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _selectedDisputeType = null;
                  _disputeSubjectController.clear();
                  _disputeDetailsController.clear();
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      // Gérer l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
        );
      }
    }
  }
}