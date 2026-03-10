// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'ChapeChape Residence';

  @override
  String get home => 'Accueil';

  @override
  String get favorites => 'Favoris';

  @override
  String get notifications => 'Notifications';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profil';

  @override
  String get search => 'Recherche';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'S\'inscrire';

  @override
  String get logout => 'Déconnexion';

  @override
  String get settings => 'Paramètres';

  @override
  String get myProfile => 'Mon profil';

  @override
  String get language => 'Langue';

  @override
  String get location => 'Localisation';

  @override
  String get menu => 'Menu';

  @override
  String get wallet => 'Portefeuille';

  @override
  String get balance => 'Solde';

  @override
  String get rewards => 'Récompenses';

  @override
  String get loyaltyPoints => 'Points de fidélité';

  @override
  String get howToEarnPoints => 'Comment gagner des points';

  @override
  String get bookResidence => 'Réserver une résidence';

  @override
  String get earnPointsBooking =>
      'Gagnez 100 points pour chaque nouvelle réservation';

  @override
  String get leaveReview => 'Laisser un avis';

  @override
  String get earnPointsReview =>
      'Gagnez 50 points en laissant un avis détaillé';

  @override
  String get referFriend => 'Parrainer un ami';

  @override
  String get earnPointsRefer =>
      'Gagnez 200 points lorsqu\'un ami s\'inscrit avec votre code';

  @override
  String get longStays => 'Séjours longue durée';

  @override
  String get earnPointsLongStay =>
      'Gagnez 10 points supplémentaires par jour pour les séjours de plus de 7 jours';

  @override
  String get pointsValue => '1 point = 10 FCFA de réduction';

  @override
  String currentLocation(String city) {
    return 'Localisation actuelle: $city';
  }

  @override
  String locationUpdated(String city) {
    return 'Localisation mise à jour : $city';
  }

  @override
  String points(int count) {
    return '$count points';
  }
}
