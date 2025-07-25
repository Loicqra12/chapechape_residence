import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/residence_model.dart';
import 'custom_marker_generator.dart';
import '../extensions/residence_marker_extension.dart';

/// Service de clustering qui fonctionne comme un wrapper autour des marqueurs existants,
/// sans dépendance à google_maps_cluster_manager

/// Utilitaire pour faciliter le clustering des résidences sur la carte
class SimpleClusterUtility {
  /// Regroupe les résidences qui sont trop proches les unes des autres à un zoom donné
  /// et génère un marqueur de cluster pour chaque groupe
  static Future<Set<Marker>> createClusteredMarkers({
    required List<Residence> residences,
    required double zoom,
    required Function(Residence) onMarkerTap,
  }) async {
    // Si le zoom est suffisamment grand, on n'applique pas de clustering
    if (zoom >= 15.0) {
      return _createIndividualMarkers(residences, onMarkerTap);
    }
    
    // Sinon, on applique un clustering simple basé sur la distance
    return _createClusteredMarkers(residences, zoom, onMarkerTap);
  }
  
  /// Crée des marqueurs individuels pour chaque résidence
  static Future<Set<Marker>> _createIndividualMarkers(
    List<Residence> residences,
    Function(Residence) onMarkerTap,
  ) async {
    final Set<Marker> markers = <Marker>{};
    
    for (final residence in residences) {
      final lat = residence.latitude;
      final lng = residence.longitude;
      
      if (lat == null || lng == null) continue;
      
      // Générer le marqueur avec prix
      final icon = await ResidenceMarkerExtension.generateMarkerForResidence(residence);
      
      markers.add(
        Marker(
          markerId: MarkerId('residence_${residence.id}'),
          position: LatLng(lat, lng),
          icon: icon,
          consumeTapEvents: true,
          onTap: () => onMarkerTap(residence),
        ),
      );
    }
    
    return markers;
  }

  /// Crée des marqueurs clusterés en fonction du niveau de zoom
  static Future<Set<Marker>> _createClusteredMarkers(
    List<Residence> residences,
    double zoom,
    Function(Residence) onMarkerTap,
  ) async {
    final Set<Marker> markers = <Marker>{};
    final Map<String, List<Residence>> clusters = {};
    
    // Définir une distance de clustering qui dépend du zoom
    // Plus le zoom est petit, plus les points doivent être éloignés pour former des clusters distincts
    final double clusterDistance = zoom < 10 ? 0.05 : (zoom < 12 ? 0.02 : 0.01);
    
    // Algorithme simple de clustering par grille
    for (final residence in residences) {
      final lat = residence.latitude;
      final lng = residence.longitude;
      
      if (lat == null || lng == null) continue;
      
      // Arrondir les coordonnées pour créer une "case" de grille
      final String gridKey = '${(lat / clusterDistance).round()}_${(lng / clusterDistance).round()}';
      
      if (!clusters.containsKey(gridKey)) {
        clusters[gridKey] = [];
      }
      
      clusters[gridKey]!.add(residence);
    }
    
    // Pour chaque cluster, créer un marqueur
    for (final entry in clusters.entries) {
      final List<Residence> clusterResidences = entry.value;
      
      // Position moyenne du cluster
      double sumLat = 0, sumLng = 0;
      for (final r in clusterResidences) {
        sumLat += r.latitude ?? 0;
        sumLng += r.longitude ?? 0;
      }
      final LatLng position = LatLng(sumLat / clusterResidences.length, sumLng / clusterResidences.length);
      
      // Si le cluster ne contient qu'une seule résidence, afficher un marqueur normal
      if (clusterResidences.length == 1) {
        final residence = clusterResidences.first;
        final icon = await ResidenceMarkerExtension.generateMarkerForResidence(residence);
        
        markers.add(
          Marker(
            markerId: MarkerId('residence_${residence.id}'),
            position: position,
            icon: icon,
            consumeTapEvents: true,
            onTap: () => onMarkerTap(residence),
          ),
        );
      } else {
        // Sinon, créer un marqueur de cluster
        final count = clusterResidences.length;
        final icon = await CustomMarkerGenerator.createClusterMarker(count: count);
        
        markers.add(
          Marker(
            markerId: MarkerId('cluster_${entry.key}'),
            position: position,
            icon: icon,
            consumeTapEvents: true,
            onTap: () {
              // Au clic sur un cluster, on pourrait zoomer sur la zone ou afficher une liste des résidences
              debugPrint('Cluster de $count résidences cliqué');
              // L'action particulière à implémenter dépendra de l'UX souhaitée
            },
          ),
        );
      }
    }
    
    return markers;
  }
  

}
