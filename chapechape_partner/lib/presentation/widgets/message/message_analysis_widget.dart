import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/message/message.dart';

class MessageAnalysisWidget extends StatelessWidget {
  final List<Message> messages;

  const MessageAnalysisWidget({
    super.key,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    // Données d'analyse calculées à partir des messages
    final analyseData = _analyzeMessages(messages);
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analyse de la conversation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  final analysisText = _getAnalysisSummaryText(analyseData);
                  Clipboard.setData(ClipboardData(text: analysisText));
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Analyse copiée dans le presse-papier'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Copier l\'analyse',
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Statistiques clés
          _buildStatsSection(context, analyseData),
          
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          
          // Sujets identifiés
          _buildTopicsSection(context, analyseData),
          
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          
          // Sentiment de la conversation
          _buildSentimentSection(context, analyseData),
        ],
      ),
    );
  }
  
  Widget _buildStatsSection(BuildContext context, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                'Messages',
                '${data['totalMessages']}',
                Icons.chat_bubble_outline,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                'Temps de réponse',
                data['avgResponseTime'],
                Icons.timer_outlined,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                'Longueur',
                data['avgMessageLength'],
                Icons.text_fields,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTopicsSection(BuildContext context, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sujets identifiés',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (data['topics'] as List<Map<String, dynamic>>).map((topic) {
            return Chip(
              label: Text(topic['label']),
              backgroundColor: _getTopicColor(topic['category'], context),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSentimentSection(BuildContext context, Map<String, dynamic> data) {
    final sentiment = data['sentiment'];
    final sentimentColor = _getSentimentColor(sentiment['score'], context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sentiment de la conversation',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (sentiment['score'] + 1) / 2, // Convertir de [-1,1] à [0,1]
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(sentimentColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Négatif', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text('Neutre', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text('Positif', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          sentiment['label'],
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: sentimentColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getTopicColor(String category, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (category) {
      case 'question':
        return colorScheme.primary.withOpacity(0.8);
      case 'request':
        return colorScheme.tertiary.withOpacity(0.8);
      case 'complaint':
        return colorScheme.error.withOpacity(0.8);
      case 'information':
        return colorScheme.secondary.withOpacity(0.8);
      default:
        return colorScheme.surfaceVariant;
    }
  }
  
  Color _getSentimentColor(double score, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (score > 0.3) {
      return Colors.green;
    } else if (score < -0.3) {
      return colorScheme.error;
    } else {
      return Colors.amber;
    }
  }
  
  // Méthode d'analyse des messages
  Map<String, dynamic> _analyzeMessages(List<Message> messages) {
    if (messages.isEmpty) {
      return {
        'totalMessages': 0,
        'avgResponseTime': 'N/A',
        'avgMessageLength': '0 mots',
        'topics': <Map<String, dynamic>>[],
        'sentiment': {
          'score': 0.0,
          'label': 'Pas assez de données pour l\'analyse',
        },
      };
    }
    
    // Calcul du nombre total de messages
    final totalMessages = messages.length;
    
    // Calcul du temps de réponse moyen (en minutes)
    double avgResponseTimeMinutes = 0;
    int responseCount = 0;
    
    for (int i = 1; i < messages.length; i++) {
      final currentMsg = messages[i];
      final prevMsg = messages[i - 1];
      
      // Ne calculer que si les expéditeurs sont différents
      if (currentMsg.senderId != prevMsg.senderId) {
        final difference = currentMsg.timestamp.difference(prevMsg.timestamp).inMinutes;
        avgResponseTimeMinutes += difference;
        responseCount++;
      }
    }
    
    final avgResponseTime = responseCount > 0
        ? '${(avgResponseTimeMinutes / responseCount).toStringAsFixed(1)} min'
        : 'N/A';
    
    // Calcul de la longueur moyenne des messages
    int totalWords = 0;
    for (final message in messages) {
      totalWords += message.content.split(' ').length;
    }
    final avgMessageLength = '${(totalWords / totalMessages).toStringAsFixed(1)} mots';
    
    // Analyse des sujets (simulée)
    final topics = _extractTopics(messages);
    
    // Analyse du sentiment (simulée)
    final sentiment = _analyzeSentiment(messages);
    
    return {
      'totalMessages': totalMessages,
      'avgResponseTime': avgResponseTime,
      'avgMessageLength': avgMessageLength,
      'topics': topics,
      'sentiment': sentiment,
    };
  }
  
  List<Map<String, dynamic>> _extractTopics(List<Message> messages) {
    // Simulation d'extraction de sujets basée sur des mots-clés
    final allText = messages.map((m) => m.content.toLowerCase()).join(' ');
    final List<Map<String, dynamic>> topics = [];
    
    // Keywords pour les prix
    if (allText.contains('prix') || 
        allText.contains('tarif') || 
        allText.contains('coût') ||
        allText.contains('fcfa') ||
        allText.contains('euro')) {
      topics.add({
        'label': 'Prix & Tarifs',
        'category': 'information',
      });
    }
    
    // Keywords pour les disponibilités
    if (allText.contains('disponible') || 
        allText.contains('réserver') || 
        allText.contains('date') ||
        allText.contains('quand')) {
      topics.add({
        'label': 'Disponibilités',
        'category': 'information',
      });
    }
    
    // Keywords pour les équipements
    if (allText.contains('équipement') || 
        allText.contains('meublé') || 
        allText.contains('cuisine') ||
        allText.contains('chambre') ||
        allText.contains('salle de bain') ||
        allText.contains('wifi')) {
      topics.add({
        'label': 'Équipements',
        'category': 'information',
      });
    }
    
    // Keywords pour les demandes
    if (allText.contains('demande') || 
        allText.contains('pouvez-vous') || 
        allText.contains('est-ce que') ||
        allText.contains('possible')) {
      topics.add({
        'label': 'Demandes client',
        'category': 'request',
      });
    }
    
    // Keywords pour les problèmes
    if (allText.contains('problème') || 
        allText.contains('panne') || 
        allText.contains('ne fonctionne pas') ||
        allText.contains('plainte')) {
      topics.add({
        'label': 'Problèmes',
        'category': 'complaint',
      });
    }
    
    // Si aucun sujet n'est identifié, ajouter un sujet générique
    if (topics.isEmpty) {
      topics.add({
        'label': 'Discussion générale',
        'category': 'information',
      });
    }
    
    return topics;
  }
  
  Map<String, dynamic> _analyzeSentiment(List<Message> messages) {
    // Simulation d'analyse de sentiment basée sur des mots-clés
    double sentimentScore = 0;
    
    // Liste de mots positifs et négatifs pour une analyse basique
    final positiveWords = [
      'merci', 'super', 'génial', 'excellent', 'bien', 'bon', 'content',
      'heureux', 'parfait', 'intéressé', 'disponible', 'oui', 'd\'accord'
    ];
    
    final negativeWords = [
      'problème', 'mauvais', 'horrible', 'décevant', 'non', 'impossible',
      'difficile', 'plainte', 'erreur', 'retard', 'cher', 'trop'
    ];
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    // Compter les occurrences de mots positifs et négatifs
    for (final message in messages) {
      final content = message.content.toLowerCase();
      
      for (final word in positiveWords) {
        if (content.contains(word)) {
          positiveCount++;
        }
      }
      
      for (final word in negativeWords) {
        if (content.contains(word)) {
          negativeCount++;
        }
      }
    }
    
    // Calculer le score entre -1 et 1
    final totalWords = positiveCount + negativeCount;
    if (totalWords > 0) {
      sentimentScore = (positiveCount - negativeCount) / totalWords;
    }
    
    // Déterminer le label en fonction du score
    String sentimentLabel;
    if (sentimentScore > 0.5) {
      sentimentLabel = 'Très positif';
    } else if (sentimentScore > 0.1) {
      sentimentLabel = 'Plutôt positif';
    } else if (sentimentScore < -0.5) {
      sentimentLabel = 'Très négatif';
    } else if (sentimentScore < -0.1) {
      sentimentLabel = 'Plutôt négatif';
    } else {
      sentimentLabel = 'Neutre';
    }
    
    return {
      'score': sentimentScore,
      'label': sentimentLabel,
    };
  }
  
  String _getAnalysisSummaryText(Map<String, dynamic> data) {
    final topics = (data['topics'] as List<Map<String, dynamic>>)
        .map((t) => t['label'])
        .join(', ');
    
    return '''
ANALYSE DE CONVERSATION
-----------------------
Messages: ${data['totalMessages']}
Temps de réponse moyen: ${data['avgResponseTime']}
Longueur moyenne: ${data['avgMessageLength']}

Sujets identifiés: $topics

Sentiment: ${data['sentiment']['label']} (Score: ${data['sentiment']['score'].toStringAsFixed(2)})
''';
  }
}
