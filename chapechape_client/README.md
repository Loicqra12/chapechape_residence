# chapechape_client

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Structure du Projet

### Core

- `core/config/` : Configuration centralisée de l'application
  - `app_config.dart` : Source unique de vérité pour la configuration
  
- `core/exceptions/` : Gestion des exceptions
  - `api_exceptions.dart` : Exceptions de base pour l'API
  - `domain_exceptions.dart` : Exceptions spécifiques au domaine

- `core/services/` : Services de l'application
  - `api_service.dart` : Service API unifié utilisant Dio

### Présentation

- `presentation/widgets/common/` : Widgets réutilisables
  - `custom_text_field.dart` : TextField personnalisé à utiliser dans toute l'application
  
- `presentation/widgets/residence/` : Widgets spécifiques aux résidences
  - `residence_card.dart` : Carte de résidence à utiliser dans toute l'application

## Conventions de Code

1. **Widgets**
   - Utiliser les widgets de `common/` pour la cohérence
   - Éviter de dupliquer les widgets existants
   
2. **Exceptions**
   - Utiliser les exceptions de `domain_exceptions.dart`
   - Hériter de `ApiException` pour les nouvelles exceptions
   
3. **Configuration**
   - Centraliser la configuration dans `app_config.dart`
   - Ne pas créer de nouveaux fichiers de configuration

4. **Services**
   - Utiliser `api_service.dart` pour les appels API
   - Utiliser Dio comme client HTTP
