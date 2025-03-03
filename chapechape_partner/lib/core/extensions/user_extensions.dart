import 'package:flutter/material.dart';
import '../models/user/user.dart';
import 'package:timeago/timeago.dart' as timeago;

extension UserProperties on User {
  String get displayName => fullName.isNotEmpty ? fullName : email;
  
  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    return email.substring(0, 2).toUpperCase();
  }

  String get statusText {
    if (isOnline) return 'En ligne';
    if (lastSeen != null) {
      return 'Vu ${timeago.format(lastSeen!, locale: 'fr')}';
    }
    return '';
  }

  Color get statusColor {
    if (isOnline) return Colors.green;
    return Colors.grey;
  }

  IconData get roleIcon {
    switch (role) {
      case 'support':
        return Icons.support_agent;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'partner':
        return Icons.business_center;
      case 'client':
      default:
        return Icons.person;
    }
  }

  String get roleText {
    switch (role) {
      case 'support':
        return 'Support';
      case 'admin':
        return 'Administrateur';
      case 'partner':
        return 'Partenaire';
      case 'client':
        return 'Client';
      default:
        return 'Utilisateur';
    }
  }
}
