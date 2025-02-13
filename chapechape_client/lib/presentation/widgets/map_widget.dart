// lib/presentation/widgets/map_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  final LatLng initialPosition;
  final double zoom;
  final Set<Marker>? markers;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(LatLng)? onTap;

  const MapWidget({
    super.key,
    required this.initialPosition,
    this.zoom = 14.0,
    this.markers,
    this.onMapCreated,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialPosition,
          zoom: zoom,
        ),
        markers: markers ?? {},
        onMapCreated: onMapCreated,
        onTap: onTap,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
      ),
    );
  }
}