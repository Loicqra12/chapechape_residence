import 'package:url_launcher/url_launcher.dart';

/// Fiche Google Play de l'application Partenaire ChapeChape.
abstract final class PartnerStoreLaunch {
  static const String androidPackageId = 'com.chapechape.chapechape_partner';

  static Uri get marketUri => Uri.parse('market://details?id=$androidPackageId');

  static Uri get playStoreWebUri =>
      Uri.parse('https://play.google.com/store/apps/details?id=$androidPackageId');

  /// Ouvre le Play Store (app si dispo, sinon navigateur).
  static Future<bool> openPlayStoreListing() async {
    try {
      if (await canLaunchUrl(marketUri)) {
        return launchUrl(marketUri, mode: LaunchMode.externalApplication);
      }
      if (await canLaunchUrl(playStoreWebUri)) {
        return launchUrl(playStoreWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
