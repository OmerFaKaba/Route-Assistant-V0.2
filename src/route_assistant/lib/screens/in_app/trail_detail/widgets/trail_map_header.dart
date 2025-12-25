import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrailMapHeader extends StatelessWidget {
  final List<LatLng> points;
  final void Function(GoogleMapController c) onMapCreated;

  const TrailMapHeader({
    super.key,
    required this.points,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: points.isNotEmpty ? points.first : const LatLng(39.9, 32.8),
          zoom: 13,
        ),
        onMapCreated: onMapCreated,
        polylines: {
          if (points.isNotEmpty)
            Polyline(
              polylineId: const PolylineId('route'),
              width: 5,
              points: points,
            ),
        },
      ),
    );
  }
}
