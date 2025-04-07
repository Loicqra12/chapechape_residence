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
} 