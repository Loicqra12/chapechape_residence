/// Configuration des fonctionnalités activables/désactivables
/// 
/// Ce fichier permet de gérer les fonctionnalités en cours de développement
/// ou de test, pour faciliter le déploiement progressif et les tests A/B.
class FeatureFlags {
  /// Active l'utilisation de Cloudinary pour la gestion des images
  /// 
  /// Quand activé (true):
  /// - Les images sont uploadées directement vers Cloudinary
  /// - Les URLs Cloudinary sont envoyées au backend
  /// - L'affichage utilise les transformations Cloudinary
  /// 
  /// Quand désactivé (false):
  /// - Le système d'upload classique est utilisé
  /// - Les images sont envoyées directement au backend
  static const bool useCloudinary = true;
  
  /// Active l'adaptation automatique de la qualité des images selon le réseau
  /// 
  /// Particulièrement utile dans le contexte africain avec des connexions variables
  static const bool adaptiveImageQuality = true;
  
  /// Active le mode économie de données pour les réseaux mobiles
  /// 
  /// Réduit la qualité des images et désactive le préchargement
  static const bool dataSavingMode = true;
  
  /// Active le cache agressif des images pour le mode hors ligne
  /// 
  /// Stocke plus d'images en local et prolonge leur durée de validité
  static const bool aggressiveImageCaching = true;

  /// Active la section Vidéo dans l'onglet Médias (upload + preview).
  /// Passer à true une fois le backend en prod et la modération opérationnelle.
  static const bool enableResidenceVideo = true;
}
