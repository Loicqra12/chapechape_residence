import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/blog_post_model.dart';

/// Service pour gérer les articles de blog et conseils
class BlogService {
  static BlogService? _instance;
  
  // Clé pour le cache
  static const String _cacheKey = 'blog_posts_cache';
  static const String _userInterestsKey = 'user_blog_interests';
  
  // Délai d'expiration du cache (24 heures)
  static const Duration _cacheExpiration = Duration(hours: 24);
  
  // Stockage en mémoire des articles
  final List<BlogPost> _blogPosts = [];
  
  // Date de dernière mise à jour du cache
  DateTime? _lastCacheUpdate;
  
  // Singleton pattern
  factory BlogService() {
    _instance ??= BlogService._internal();
    return _instance!;
  }
  
  BlogService._internal();
  
  /// Initialise le service de blog
  Future<BlogService> initialize() async {
    // Vérifier si les données en cache sont valides
    if (_blogPosts.isEmpty || _isCacheExpired()) {
      try {
        // Essayer de charger depuis le cache local
        final cachedPosts = await _loadFromCache();
        
        if (cachedPosts.isNotEmpty) {
          _blogPosts.clear();
          _blogPosts.addAll(cachedPosts);
          return this;
        }
        
        // Si aucun cache ou cache vide, charger les données fictives
        _blogPosts.clear();
        _blogPosts.addAll(_generateDummyBlogPosts());
        
        // Mettre à jour le cache
        await _saveToCache(_blogPosts);
      } catch (e) {
        print('Erreur lors de l\'initialisation du service blog: $e');
        // En cas d'erreur, utiliser des données fictives
        _blogPosts.clear();
        _blogPosts.addAll(_generateDummyBlogPosts());
      }
    }
    
    return this;
  }
  
  /// Vérifie si le cache est expiré
  bool _isCacheExpired() {
    if (_lastCacheUpdate == null) return true;
    
    final now = DateTime.now();
    return now.difference(_lastCacheUpdate!) > _cacheExpiration;
  }
  
  /// Charge les articles depuis le cache
  Future<List<BlogPost>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      // Mettre à jour la date de dernière mise à jour
      final lastUpdateStr = prefs.getString('${_cacheKey}_last_update');
      if (lastUpdateStr != null) {
        _lastCacheUpdate = DateTime.parse(lastUpdateStr);
      }
      
      // Convertir JSON en objets BlogPost
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList.map((json) => BlogPost.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors du chargement du cache blog: $e');
      return [];
    }
  }
  
  /// Parse une liste JSON (exécuté sur un thread isolé)
  static List<dynamic> _parseJsonList(String jsonString) {
    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      print('Erreur de parsing JSON: $e');
      return [];
    }
  }
  
  /// Sauvegarde les articles dans le cache
  Future<void> _saveToCache(List<BlogPost> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir les objets en JSON
      final jsonList = posts.map((post) => post.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      // Sauvegarder le JSON et la date de mise à jour
      await prefs.setString(_cacheKey, jsonString);
      _lastCacheUpdate = DateTime.now();
      await prefs.setString('${_cacheKey}_last_update', _lastCacheUpdate!.toIso8601String());
    } catch (e) {
      print('Erreur lors de la sauvegarde du cache blog: $e');
    }
  }
  
  /// Obtenir tous les articles de blog
  Future<List<BlogPost>> getAllBlogPosts() async {
    await initialize();
    return List.unmodifiable(_blogPosts);
  }
  
  /// Obtenir les articles de blog en vedette
  Future<List<BlogPost>> getFeaturedBlogPosts() async {
    await initialize();
    return _blogPosts.where((post) => post.isFeatured).toList();
  }
  
  /// Obtenir les articles de blog récents
  Future<List<BlogPost>> getRecentBlogPosts({int limit = 5}) async {
    await initialize();
    
    // Trier par date de publication (plus récent d'abord)
    final sortedPosts = List<BlogPost>.from(_blogPosts);
    sortedPosts.sort((a, b) {
      if (a.publishedDate == null && b.publishedDate == null) return 0;
      if (a.publishedDate == null) return 1;
      if (b.publishedDate == null) return -1;
      return b.publishedDate!.compareTo(a.publishedDate!);
    });
    
    // Limiter le nombre d'articles
    return sortedPosts.take(limit).toList();
  }
  
  /// Obtenir les articles de blog par catégorie
  Future<List<BlogPost>> getBlogPostsByCategory(String category) async {
    await initialize();
    return _blogPosts.where((post) => post.category == category).toList();
  }
  
  /// Obtenir un article de blog par son ID
  Future<BlogPost?> getBlogPostById(String id) async {
    await initialize();
    try {
      return _blogPosts.firstWhere((post) => post.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Rechercher des articles de blog
  Future<List<BlogPost>> searchBlogPosts(String query) async {
    await initialize();
    
    final normalizedQuery = query.toLowerCase().trim();
    
    return _blogPosts.where((post) {
      return post.title.toLowerCase().contains(normalizedQuery) ||
             (post.summary?.toLowerCase() ?? '').contains(normalizedQuery) ||
             (post.content?.toLowerCase() ?? '').contains(normalizedQuery) ||
             (post.tags?.any((tag) => tag.toLowerCase().contains(normalizedQuery)) ?? false);
    }).toList();
  }
  
  /// Enregistre les intérêts de l'utilisateur
  Future<void> saveUserInterests(List<String> interests) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_userInterestsKey, interests);
    } catch (e) {
      print('Erreur lors de la sauvegarde des intérêts utilisateur: $e');
    }
  }
  
  /// Récupère les intérêts de l'utilisateur
  Future<List<String>> getUserInterests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_userInterestsKey) ?? [];
    } catch (e) {
      print('Erreur lors de la récupération des intérêts utilisateur: $e');
      return [];
    }
  }
  
  /// Recommande des articles basés sur les intérêts de l'utilisateur
  Future<List<BlogPost>> getRecommendedBlogPosts({int limit = 3}) async {
    await initialize();
    
    // Récupérer les intérêts de l'utilisateur
    final interests = await getUserInterests();
    
    if (interests.isEmpty) {
      // Si aucun intérêt, retourner les articles en vedette
      return getFeaturedBlogPosts();
    }
    
    // Trier les articles en fonction de leur pertinence avec les intérêts
    final scoredPosts = _blogPosts.map((post) {
      int score = 0;
      
      // Score basé sur les correspondances de tags
      if (post.tags != null) {
        for (final tag in post.tags!) {
          if (interests.contains(tag.toLowerCase())) {
            score += 3; // Score élevé pour une correspondance exacte
          }
          
          // Correspondance partielle
          for (final interest in interests) {
            if (tag.toLowerCase().contains(interest) || 
                interest.contains(tag.toLowerCase())) {
              score += 1;
            }
          }
        }
      }
      
      // Score basé sur la catégorie
      if (post.category != null && 
          interests.contains(post.category!.toLowerCase())) {
        score += 2;
      }
      
      return MapEntry(post, score);
    }).toList();
    
    // Trier par score (descendant)
    scoredPosts.sort((a, b) => b.value.compareTo(a.value));
    
    // Obtenir les articles avec les scores les plus élevés
    final recommendedPosts = scoredPosts
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .take(limit)
        .toList();
    
    // Si pas assez d'articles pertinents, ajouter des articles récents
    if (recommendedPosts.length < limit) {
      final recentPosts = await getRecentBlogPosts(limit: limit * 2);
      
      for (final post in recentPosts) {
        if (recommendedPosts.length >= limit) break;
        if (!recommendedPosts.contains(post)) {
          recommendedPosts.add(post);
        }
      }
    }
    
    return recommendedPosts;
  }
  
  /// Génère des articles de blog fictifs pour la démonstration
  List<BlogPost> _generateDummyBlogPosts() {
    return [
      BlogPost(
        id: '1',
        title: 'Comment choisir la résidence idéale pour vos études',
        summary: 'Guide complet pour les étudiants à la recherche d\'un logement confortable et abordable près de leur campus.',
        content: 'Trouver le logement parfait pendant vos études est crucial pour votre réussite académique et votre bien-être. Dans cet article, nous explorons les critères essentiels à considérer : proximité du campus, budget, commodités, et possibilités de colocations. Nous analysons également les avantages et inconvénients des résidences universitaires par rapport aux logements privés.',
        imageUrl: 'https://images.unsplash.com/photo-1576495199011-eb94736d05d6?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        publishedDate: DateTime.now().subtract(const Duration(days: 5)),
        authorName: 'Sophie Kouamé',
        authorImageUrl: 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
        category: 'Conseils',
        readTimeMinutes: 8,
        tags: ['étudiant', 'logement', 'budget', 'colocation'],
        isFeatured: true,
      ),
      BlogPost(
        id: '2',
        title: 'Les tendances immobilières en Côte d\'Ivoire pour 2025',
        summary: 'Découvrez les quartiers émergents et les nouvelles tendances du marché immobilier ivoirien.',
        content: 'Le marché immobilier ivoirien connaît une transformation rapide avec l\'émergence de nouveaux quartiers prisés comme Angré, Cocody et Bingerville. Les constructions modernes intégrant des technologies intelligentes et respectueuses de l\'environnement gagnent en popularité. Cet article analyse les prévisions de prix, les opportunités d\'investissement et les défis du secteur pour l\'année à venir.',
        imageUrl: 'https://images.unsplash.com/photo-1516455590571-18256e5bb9ff?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        publishedDate: DateTime.now().subtract(const Duration(days: 12)),
        authorName: 'Jean-Marc Koné',
        authorImageUrl: 'https://images.unsplash.com/photo-1566492031773-4f4e44671857?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
        category: 'Tendances',
        readTimeMinutes: 10,
        tags: ['immobilier', 'investissement', 'marché', 'Abidjan'],
        isFeatured: true,
      ),
      BlogPost(
        id: '3',
        title: 'Aménagement intérieur : maximiser l\'espace dans un petit appartement',
        summary: 'Astuces et conseils pour optimiser chaque mètre carré de votre petit logement.',
        content: 'Vivre dans un espace restreint ne signifie pas renoncer au confort ou à l\'esthétique. Grâce à des solutions de rangement astucieuses, des meubles multifonctionnels et une réflexion intelligente sur l\'agencement, vous pouvez transformer votre petit appartement en un espace à la fois pratique et agréable à vivre. Découvrez nos idées d\'aménagement pour chaque pièce.',
        imageUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        publishedDate: DateTime.now().subtract(const Duration(days: 25)),
        authorName: 'Aminata Diallo',
        authorImageUrl: 'https://images.unsplash.com/photo-1581992652564-44c42f5ad3ad?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
        category: 'Décoration',
        readTimeMinutes: 6,
        tags: ['décoration', 'espace', 'aménagement', 'studio'],
        isFeatured: false,
      ),
      BlogPost(
        id: '4',
        title: 'Guide complet des procédures d\'achat immobilier en Côte d\'Ivoire',
        summary: 'Tout ce que vous devez savoir sur les démarches légales et administratives pour acheter un bien immobilier.',
        content: 'L\'achat d\'un bien immobilier représente un investissement majeur qui nécessite une connaissance approfondie des procédures légales. Ce guide détaille chaque étape, depuis la recherche initiale jusqu\'à la signature de l\'acte final, en passant par les vérifications nécessaires, les différents professionnels à consulter, et les taxes à prévoir. Un outil indispensable pour sécuriser votre acquisition.',
        imageUrl: 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        publishedDate: DateTime.now().subtract(const Duration(days: 40)),
        authorName: 'Pascal Okouma',
        authorImageUrl: 'https://images.unsplash.com/photo-1531384441138-2736e62e0919?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
        category: 'Juridique',
        readTimeMinutes: 15,
        tags: ['achat', 'légal', 'administration', 'procédures'],
        isFeatured: false,
      ),
      BlogPost(
        id: '5',
        title: 'Comment économiser pour financer votre premier logement',
        summary: 'Stratégies financières efficaces pour constituer un apport personnel solide.',
        content: 'Le rêve de devenir propriétaire commence par une étape cruciale : l\'épargne. Cet article présente diverses stratégies d\'économie adaptées aux jeunes actifs, des conseils pour optimiser votre capacité d\'épargne mensuelle, et des informations sur les dispositifs d\'aide à l\'accession à la propriété. Des témoignages d\'acheteurs complètent cette boîte à outils financière pour vous aider à franchir le pas.',
        imageUrl: 'https://images.unsplash.com/photo-1579621970795-87facc2f976d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        publishedDate: DateTime.now().subtract(const Duration(days: 18)),
        authorName: 'Fatou Bamba',
        authorImageUrl: 'https://images.unsplash.com/photo-1580894894513-541e068a3e2b?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
        category: 'Finance',
        readTimeMinutes: 9,
        tags: ['épargne', 'finance', 'premier achat', 'budget'],
        isFeatured: true,
      ),
      BlogPost(
        id: '6',
        title: 'Résidences écologiques : l\'avenir de l\'habitat durable en Afrique',
        summary: 'Découvrez comment les constructions vertes transforment le paysage immobilier africain.',
        content: 'Face aux défis climatiques, l\'habitat écologique s\'impose comme une nécessité en Afrique. Cet article explore les innovations en matière de construction durable, les matériaux locaux et écologiques, ainsi que les solutions énergétiques adaptées au climat africain. Nous présentons également des projets pionniers de résidences vertes à travers le continent et leur impact positif sur l\'environnement et la qualité de vie.',
        imageUrl: 'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        publishedDate: DateTime.now().subtract(const Duration(days: 30)),
        authorName: 'Ibrahim Touré',
        authorImageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
        category: 'Écologie',
        readTimeMinutes: 12,
        tags: ['écologie', 'développement durable', 'construction verte', 'énergie solaire'],
        isFeatured: false,
      ),
      BlogPost(
        id: '7',
        title: 'Les avantages fiscaux liés à l\'investissement immobilier locatif',
        summary: 'Optimisez votre fiscalité grâce à l\'immobilier locatif.',
        content: 'L\'immobilier locatif offre de nombreux avantages fiscaux souvent méconnus des investisseurs débutants. Ce guide détaille les différentes réductions d\'impôts possibles, les conditions d\'éligibilité, et les stratégies d\'optimisation fiscale, notamment la création de SCI ou l\'amortissement des biens. Des conseils pratiques pour transformer votre investissement immobilier en levier fiscal efficace.',
        imageUrl: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        publishedDate: DateTime.now().subtract(const Duration(days: 22)),
        authorName: 'Robert Koffi',
        authorImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
        category: 'Finance',
        readTimeMinutes: 11,
        tags: ['fiscalité', 'investissement', 'location', 'impôts'],
        isFeatured: false,
      ),
      BlogPost(
        id: '8',
        title: 'Sécurité résidentielle : protégez efficacement votre logement',
        summary: 'Solutions modernes pour sécuriser votre domicile contre les cambriolages et intrusions.',
        content: 'La sécurité de votre domicile est une priorité absolue. Cet article présente les différentes technologies de sécurité résidentielle disponibles sur le marché, des serrures connectées aux systèmes de vidéosurveillance, en passant par les alarmes intelligentes. Nous abordons également les mesures de sécurité passive à mettre en place et les comportements à adopter pour dissuader les intrusions.',
        imageUrl: 'https://images.unsplash.com/photo-1558002038-1055e2e40e52?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
        publishedDate: DateTime.now().subtract(const Duration(days: 15)),
        authorName: 'Sylvie N\'Guessan',
        authorImageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
        category: 'Sécurité',
        readTimeMinutes: 7,
        tags: ['sécurité', 'alarme', 'vidéosurveillance', 'protection'],
        isFeatured: false,
      ),
    ];
  }
  
  // Outil utilitaire pour transformer une chaîne JSON en Map
  static Map<String, dynamic> jsonDecode(String jsonString) {
    return json.decode(jsonString) as Map<String, dynamic>;
  }
  
  // Outil utilitaire pour transformer une Map en chaîne JSON
  static String jsonEncode(List<Map<String, dynamic>> jsonList) {
    return json.encode(jsonList);
  }
  
  // Fonction utilitaire pour exécuter une tâche sur un thread isolé
  static Future<T> compute<T, U>(T Function(U) callback, U message) async {
    // Dans une implémentation réelle, cela utiliserait dart:isolate
    // Pour cet exemple, on exécute simplement la méthode
    return callback(message);
  }
}
