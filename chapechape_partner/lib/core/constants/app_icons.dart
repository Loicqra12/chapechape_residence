/// Classe utilitaire pour centraliser tous les chemins d'icônes de l'application
class AppIcons {
  AppIcons._();

  // Base paths
  static const String _basePath = 'assets/icons';
  static const String _navigationPath = '$_basePath/navigation';
  static const String _actionsPath = '$_basePath/actions';
  static const String _featuresPath = '$_basePath/features';
  static const String _statusPath = '$_basePath/status';
  static const String _amenitiesPath = '$_basePath/amenities';
  static const String _profilePath = '$_basePath/profile';
  static const String _residencePath = '$_basePath/residence';
  static const String _messagePath = '$_basePath/message';
  static const String _reservationPath = '$_basePath/reservation';

  // Navigation Icons
  static const String home = '$_navigationPath/home.svg';
  static const String profile = '$_navigationPath/profile.svg';
  static const String settings = '$_navigationPath/settings.svg';
  static const String messages = '$_navigationPath/messages.svg';
  static const String notifications = '$_navigationPath/notifications.svg';
  static const String calendar = '$_navigationPath/calendar.svg';
  static const String residences = '$_navigationPath/residences.svg';
  static const String statistics = '$_navigationPath/statistics.svg';
  static const String dashboard = '$_navigationPath/dashboard.svg';
  static const String chart = '$_navigationPath/chart.svg';
  static const String revenue = '$_navigationPath/revenue.svg';
  static const String trendUp = '$_navigationPath/trend_up.svg';
  static const String trendDown = '$_navigationPath/trend_down.svg';

  // Profile Icons
  static const String account = '$_profilePath/account.svg';
  static const String badgeVerified = '$_profilePath/badge_verified.svg';
  static const String editProfile = '$_profilePath/edit_profile.svg';
  static const String partner = '$_profilePath/partner.svg';
  static const String logout = '$_profilePath/logout.svg';

  // Residence Icons
  static const String residenceAdd = '$_residencePath/residence_add.svg';
  static const String residenceEdit = '$_residencePath/residence_edit.svg';
  static const String residenceDelete = '$_residencePath/residence_delete.svg';
  static const String residenceStatus = '$_residencePath/residence_status.svg';
  static const String gallery = '$_residencePath/gallery.svg';
  static const String feature = '$_residencePath/feature.svg';

  // Message Icons
  static const String chat = '$_messagePath/chat.svg';
  static const String support = '$_messagePath/support.svg';
  static const String client = '$_messagePath/client.svg';
  static const String unread = '$_messagePath/unread.svg';
  static const String send = '$_messagePath/send.svg';
  static const String attach = '$_messagePath/attach.svg';

  // Reservation Icons
  static const String booking = '$_reservationPath/booking.svg';
  static const String checkIn = '$_reservationPath/check_in.svg';
  static const String checkOut = '$_reservationPath/check_out.svg';
  static const String duration = '$_reservationPath/duration.svg';
  static const String paymentStatus = '$_reservationPath/payment_status.svg';
  static const String cancel = '$_reservationPath/cancel.svg';

  // Action Icons
  static const String add = '$_actionsPath/add.svg';
  static const String edit = '$_actionsPath/edit.svg';
  static const String delete = '$_actionsPath/delete.svg';
  static const String search = '$_actionsPath/search.svg';
  static const String filter = '$_actionsPath/filter.svg';
  static const String share = '$_actionsPath/share.svg';
  static const String upload = '$_actionsPath/upload.svg';
  static const String download = '$_actionsPath/download.svg';
  static const String close = '$_actionsPath/close.svg';
  static const String back = '$_actionsPath/back.svg';
  static const String refresh = '$_actionsPath/refresh.svg';
  static const String sort = '$_actionsPath/sort.svg';
  static const String filterActive = '$_actionsPath/filter_active.svg';
  static const String searchActive = '$_actionsPath/search_active.svg';
  static const String moreVertical = '$_actionsPath/more_vertical.svg';
  static const String moreHorizontal = '$_actionsPath/more_horizontal.svg';
  static const String closeCircle = '$_actionsPath/close_circle.svg';

  // Status Icons
  static const String available = '$_statusPath/available.svg';
  static const String unavailable = '$_statusPath/unavailable.svg';
  static const String maintenance = '$_statusPath/maintenance.svg';
  static const String pending = '$_statusPath/pending.svg';
  static const String verified = '$_statusPath/verified.svg';
  static const String error = '$_statusPath/error.svg';
  static const String success = '$_statusPath/success.svg';
  static const String warning = '$_statusPath/warning.svg';
  static const String info = '$_statusPath/info.svg';
  static const String loading = '$_statusPath/loading.svg';

  // Feature Icons
  static const String bedroom = '$_featuresPath/bedroom.svg';
  static const String bathroom = '$_featuresPath/bathroom.svg';
  static const String area = '$_featuresPath/area.svg';
  static const String price = '$_featuresPath/price.svg';
  static const String location = '$_featuresPath/location.svg';
  static const String type = '$_featuresPath/type.svg';

  // Amenity Icons
  static const String wifi = '$_amenitiesPath/wifi.svg';
  static const String pool = '$_amenitiesPath/pool.svg';
  static const String parking = '$_amenitiesPath/parking.svg';
  static const String gym = '$_amenitiesPath/gym.svg';
  static const String security = '$_amenitiesPath/security.svg';
  static const String airConditioning = '$_amenitiesPath/air_conditioning.svg';
  static const String heating = '$_amenitiesPath/heating.svg';
  static const String kitchen = '$_amenitiesPath/kitchen.svg';
  static const String tv = '$_amenitiesPath/tv.svg';
  static const String washingMachine = '$_amenitiesPath/washing_machine.svg';
  static const String dryer = '$_amenitiesPath/dryer.svg';

  /// Retourne l'icône de statut approprié en fonction du statut de la résidence
  static String getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return available;
      case 'unavailable':
        return unavailable;
      case 'maintenance':
        return maintenance;
      case 'pending':
        return pending;
      case 'verified':
        return verified;
      default:
        return error;
    }
  }
}
