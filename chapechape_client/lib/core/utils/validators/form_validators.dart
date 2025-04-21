import 'package:flutter/material.dart';

/// Classe utilitaire pour la validation des formulaires
class FormValidators {
  /// Valide un email
  /// 
  /// Vérifie que l'email est conforme à la norme RFC 5322
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    
    // Expression régulière pour la validation d'emails
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }
    
    return null;
  }
  
  /// Valide un numéro de téléphone
  /// 
  /// Accepte les formats: +XX XXX XXX XXX ou 0X XX XX XX XX
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    
    // Supprimer les espaces, tirets et parenthèses pour normaliser
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-()]'), '');
    
    // Vérifier le format international (+XXX) ou français (commençant par 0)
    final phoneRegex = RegExp(r'^(\+[0-9]{1,3}|0)[0-9]{9,12}$');
    
    if (!phoneRegex.hasMatch(cleanedValue)) {
      return 'Numéro de téléphone invalide';
    }
    
    return null;
  }
  
  /// Valide un mot de passe
  /// 
  /// Règles:
  /// - Au moins 8 caractères
  /// - Au moins une lettre majuscule
  /// - Au moins une lettre minuscule
  /// - Au moins un chiffre
  /// - Au moins un caractère spécial
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Le mot de passe doit contenir au moins une minuscule';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Le mot de passe doit contenir au moins un caractère spécial';
    }
    
    return null;
  }
  
  /// Valide la confirmation du mot de passe
  static String? validatePasswordConfirmation(
    String? value,
    String password,
  ) {
    if (value == null || value.isEmpty) {
      return 'La confirmation du mot de passe est requise';
    }
    
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    
    return null;
  }
  
  /// Valide un nom (prénom, nom de famille, etc.)
  static String? validateName(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    
    if (value.length < 2) {
      return '$fieldName doit contenir au moins 2 caractères';
    }
    
    // Vérifier qu'il ne contient que des lettres et des espaces
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s\-]+$').hasMatch(value)) {
      return '$fieldName ne doit contenir que des lettres';
    }
    
    return null;
  }
  
  /// Validation générique de champ requis
  static String? validateRequired(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }
  
  /// Valide une date de visite pour une réservation
  static String? validateVisitDate(DateTime? value) {
    if (value == null) {
      return 'La date de visite est requise';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final visitDate = DateTime(value.year, value.month, value.day);
    
    if (visitDate.isBefore(today)) {
      return 'La date de visite ne peut pas être dans le passé';
    }
    
    // Limite à 3 mois dans le futur
    final maxDate = today.add(const Duration(days: 90));
    if (visitDate.isAfter(maxDate)) {
      return 'La date de visite doit être dans les 3 prochains mois';
    }
    
    return null;
  }
  
  /// Valide une heure de visite pour une réservation
  static String? validateVisitTime(TimeOfDay? value) {
    if (value == null) {
      return 'L\'heure de visite est requise';
    }
    
    // Vérifier que l'heure est dans la plage de travail (9h-18h)
    if (value.hour < 9 || value.hour >= 18) {
      return 'L\'heure de visite doit être entre 9h et 18h';
    }
    
    return null;
  }
  
  /// Valide le nombre de personnes pour une réservation
  static String? validateGuestCount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nombre de personnes est requis';
    }
    
    final guestCount = int.tryParse(value);
    if (guestCount == null) {
      return 'Veuillez entrer un nombre valide';
    }
    
    if (guestCount < 1) {
      return 'Il doit y avoir au moins 1 personne';
    }
    
    if (guestCount > 20) {
      return 'Le nombre maximum de personnes est de 20';
    }
    
    return null;
  }
  
  /// Valide une adresse pour une résidence
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse est requise';
    }
    
    if (value.length < 5) {
      return 'L\'adresse doit contenir au moins 5 caractères';
    }
    
    return null;
  }
}
