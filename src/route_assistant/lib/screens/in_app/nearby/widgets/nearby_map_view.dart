import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../nearby_controller.dart';
import '../nearby_state.dart';
import '../nearby_models.dart';

class NearbyMapView extends StatelessWidget {
  final NearbyController controller;
  final NearbyState state;
  final VoidCallback onMapTap;

  const NearbyMapView({
    super.key,
    required this.controller,
    required this.state,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final me = state.me!;
    final markers = _buildMarkers();

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: me, zoom: 6),
      markers: markers,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      onTap: (_) => onMapTap(),
    );
  }

  Set<Marker> _buildMarkers() {
    final me = state.me;
    if (me == null) return {};

    final Set<Marker> out = {};

    out.add(
      Marker(
        markerId: const MarkerId('me'),
        position: me,
        icon: controller.meIcon(),
        infoWindow: const InfoWindow(title: '', snippet: ''),
        onTap: controller.clearSelection,
      ),
    );

    for (final NearbyRoute r in state.routes) {
      final selected = (state.selectedRouteId == r.id);

      out.add(
        Marker(
          markerId: MarkerId(r.id),
          position: r.start,
          icon: controller.routeIcon(selected: selected),
          infoWindow: const InfoWindow(title: '', snippet: ''),
          onTap: () => controller.selectRoute(r),
        ),
      );
    }

    return out;
  }
}
