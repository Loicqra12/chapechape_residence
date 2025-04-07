import 'dart:async';
import 'package:flutter/foundation.dart';

// Types d'événements liés aux résidences
enum ResidenceEventType { created, updated, deleted, refreshNeeded }

/// Bus d'événements pour les opérations liées aux résidences
/// 
/// Permet la communication entre différentes parties de l'application
/// sans créer de dépendances cycliques
class ResidenceEventBus {
  // Singleton pour garantir une seule instance
  static final ResidenceEventBus _instance = ResidenceEventBus._internal();
  factory ResidenceEventBus() => _instance;
  
  // Constructeur privé
  ResidenceEventBus._internal();
  
  // Contrôleur de flux d'événements en mode broadcast pour permettre plusieurs écouteurs
  final _controller = StreamController<ResidenceEventType>.broadcast();
  
  // Stream accessible aux écouteurs
  Stream<ResidenceEventType> get stream => _controller.stream;
  
  // Méthode pour émettre un événement
  void emit(ResidenceEventType event) {
    debugPrint('🔔 ResidenceEventBus: émission d\'un événement ${event.toString()}');
    _controller.add(event);
  }
  
  // Méthode pour libérer les ressources
  void dispose() {
    _controller.close();
  }
} 