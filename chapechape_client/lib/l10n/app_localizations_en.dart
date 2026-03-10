// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ChapeChape Residence';

  @override
  String get home => 'Home';

  @override
  String get favorites => 'Favorites';

  @override
  String get notifications => 'Notifications';

  @override
  String get messages => 'Messages';

  @override
  String get profile => 'Profile';

  @override
  String get search => 'Search';

  @override
  String get login => 'Login';

  @override
  String get register => 'Sign Up';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get myProfile => 'My Profile';

  @override
  String get language => 'Language';

  @override
  String get location => 'Location';

  @override
  String get menu => 'Menu';

  @override
  String get wallet => 'Wallet';

  @override
  String get balance => 'Balance';

  @override
  String get rewards => 'Rewards';

  @override
  String get loyaltyPoints => 'Loyalty Points';

  @override
  String get howToEarnPoints => 'How to earn points';

  @override
  String get bookResidence => 'Book a residence';

  @override
  String get earnPointsBooking => 'Earn 100 points for each new booking';

  @override
  String get leaveReview => 'Leave a review';

  @override
  String get earnPointsReview => 'Earn 50 points by leaving a detailed review';

  @override
  String get referFriend => 'Refer a friend';

  @override
  String get earnPointsRefer =>
      'Earn 200 points when a friend signs up with your code';

  @override
  String get longStays => 'Long stays';

  @override
  String get earnPointsLongStay =>
      'Earn 10 extra points per day for stays longer than 7 days';

  @override
  String get pointsValue => '1 point = 10 FCFA discount';

  @override
  String currentLocation(String city) {
    return 'Current location: $city';
  }

  @override
  String locationUpdated(String city) {
    return 'Location updated: $city';
  }

  @override
  String points(int count) {
    return '$count points';
  }
}
