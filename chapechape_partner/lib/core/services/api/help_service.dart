import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../../models/help/faq_model.dart';
import 'api_service.dart';

class HelpService {
  final ApiService _apiService;
  
  HelpService(Dio dio) : _apiService = ApiService(authBloc: null);
  
  // Alternative constructor
  HelpService.withApiService({required ApiService apiService}) : _apiService = apiService;
  
  /// Récupère la liste des FAQs
  Future<List<FAQItem>> getFAQs({String? category}) async {
    try {
      final queryParams = category != null ? {'category': category} : null;
      
      final response = await _apiService.get(
        '/api/faqs',
        queryParameters: queryParams,
      );
      
      final List<dynamic> faqList = response.data['faqs'];
      return faqList
          .map((faq) => FAQItem.fromJson(faq))
          .toList();
    } catch (e) {
      throw Exception('Impossible de récupérer les FAQs: $e');
    }
  }
  
  /// Envoie un message de support
  Future<void> sendSupportMessage({required String message}) async {
    try {
      await _apiService.post(
        '/api/support/messages',
        data: {'message': message},
      );
    } catch (e) {
      throw Exception('Impossible d\'envoyer le message: $e');
    }
  }
  
  /// Signale un problème
  Future<void> reportProblem({
    required String category,
    required String subject,
    required String description,
  }) async {
    try {
      await _apiService.post(
        '/api/support/issues',
        data: {
          'category': category,
          'subject': subject,
          'description': description,
        },
      );
    } catch (e) {
      throw Exception('Impossible de signaler le problème: $e');
    }
  }
  
  /// Récupère les catégories de FAQ
  Future<List<FAQCategory>> getFAQCategories() async {
    try {
      final response = await _apiService.get('/api/faqs/categories');
      
      final List<dynamic> categoryList = response.data['categories'];
      return categoryList
          .map((category) => FAQCategory.fromJson(category))
          .toList();
    } catch (e) {
      throw Exception('Impossible de récupérer les catégories: $e');
    }
  }
  
  // Méthode simulée pour la démo
  Future<List<FAQItem>> _mockGetFAQs({String? category}) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));
    
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
    
    if (category != null) {
      return mockFaqs.where((faq) => faq.category == category).toList();
    }
    
    return mockFaqs;
  }
} 